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
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Convenience for building this repo standalone. Wyldfire is
        # unfree, so this needs the caller's own consent the normal nix
        # way - NIXPKGS_ALLOW_UNFREE=1, `nixpkgs.config.allowUnfree` in a
        # NixOS/home-manager config, etc. We don't set it for them here.
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
