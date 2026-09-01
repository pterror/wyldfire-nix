{
  description = "wyldfire-nix - Nix packaging for Wyldfire, WyChatTeam's offline AI roleplay/chat companion for Wyvern Chat";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      # Lets a consumer fold `wyldfire` into their own pkgs instantiation
      # (e.g. `nixpkgs.overlays = [ wyldfire-nix.overlays.default ];`) so
      # it's built with THEIR config - their allowUnfreePredicate governs
      # it, same as any other unfree package in nixpkgs (google-chrome,
      # steam, etc). package.nix itself never touches `config` at all.
      overlays.default = final: prev: {
        wyldfire = final.callPackage ./package.nix { };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system:
      let
        # Scoped to just wyldfire's own pname, not a blanket allowUnfree -
        # so bare `nix build`/`nix run` on this flake works standalone
        # with zero consumer setup, without waving through anything else
        # built off this pkgs (gtk3, webkitgtk_4_1, ...). Matches how
        # spicetify-nix/claude-desktop-debian/wispr-flow-linux do it.
        # `overlays.default` below stays unscoped-config entirely, so a
        # consumer applying it to their own pkgs keeps full say over
        # their own allowUnfree/allowUnfreePredicate.
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: (nixpkgs.lib.getName pkg) == "wyldfire";
        };
      in
      {
        packages.default = pkgs.callPackage ./package.nix { };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
          name = "wyldfire";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ dpkg ];
        };
      }
    );
}
