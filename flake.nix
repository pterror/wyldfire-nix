{
  description = "wyldfire-nix - Nix packaging for Wyldfire, WyChatTeam's offline AI roleplay/chat companion for Wyvern Chat";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Wyldfire being unfree isn't optional - it's the whole point of
        # this flake, so `allowUnfree` is baked into our own pkgs instance
        # here rather than left to the ambient config. `legacyPackages`
        # is a separate nixpkgs instantiation with `allowUnfree = false`
        # hardcoded, so a downstream `nixConfig`/`allowUnfreePredicate`
        # can never reach it no matter how `nixpkgs` is `follows`-ed.
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Pinned to a specific upstream release deliberately, not
        # fetch-latest, so builds stay reproducible. Bump both `version`
        # and `hash` together when tracking a new upstream release.
        version = "0.3.92";
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "wyldfire";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/WyChatTeam/Wyldfire-releases/releases/download/v${version}/Wyldfire_${version}_amd64.deb";
            hash = "sha256-wfrE2RWi4yeAaS1PEZBXoF8/sx9AutzoagsZdlEMnjw=";
          };

          nativeBuildInputs = with pkgs; [
            dpkg
            autoPatchelfHook
            makeWrapper
          ];

          # webkitgtk_4_1 covers libwebkit2gtk-4.1 + libjavascriptcoregtk-4.1 +
          # libsoup-3.0 (all transitively NEEDED by the binary); gtk3 covers
          # libgtk-3 + libgdk-3 + cairo/glib/gobject/gio. autoPatchelfHook
          # resolves the rest of the binary's NEEDED entries against these.
          buildInputs = with pkgs; [
            gtk3
            webkitgtk_4_1
          ];

          dontUnpack = true;
          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            dpkg-deb -x $src .

            mkdir -p $out
            cp -r usr/bin $out/bin
            cp -r usr/lib $out/lib
            cp -r usr/share $out/share

            runHook postInstall
          '';

          # The tray icon (libappindicator-sys) is dlopen()'d at runtime, not
          # a linked NEEDED entry, so autoPatchelfHook's rpath scan never
          # sees it - it has to be handed to the process via
          # LD_LIBRARY_PATH instead. GIO_EXTRA_MODULES pulls in
          # glib-networking's TLS backend for libsoup (used by the
          # webkitgtk webview for any https:// requests it makes).
          postFixup = ''
            wrapProgram $out/bin/wyldfire \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.libayatana-appindicator ]} \
              --prefix GIO_EXTRA_MODULES : ${pkgs.glib-networking}/lib/gio/modules
          '';

          meta = with pkgs.lib; {
            description = "Offline AI roleplay/chat companion for Wyvern Chat (closed source, prebuilt binary repackaged for Nix)";
            homepage = "https://github.com/WyChatTeam/Wyldfire-releases";
            license = licenses.unfree;
            platforms = [ "x86_64-linux" ];
            mainProgram = "wyldfire";
          };
        };

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
