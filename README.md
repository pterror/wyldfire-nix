# wyldfire-nix

Nix packaging for [Wyldfire](https://github.com/WyChatTeam/Wyldfire-releases), WyChatTeam's Tauri desktop companion app for [Wyvern Chat](https://wyvern.chat/) - chat with AI characters offline.

## About

Wyldfire is closed source and distributed only as prebuilt binaries via GitHub Releases at `WyChatTeam/Wyldfire-releases`. This repo is an unofficial, third-party Nix flake that fetches the pinned upstream `.deb`, extracts it, and patches the binary with `autoPatchelfHook` so it runs as a normal Nix derivation - no `appimage-run`, no FHS wrapper. It is not produced or endorsed by WyChatTeam. All credit for Wyldfire itself goes to WyChatTeam.

The flake pins to a specific upstream release (currently `v0.3.92`) rather than fetching latest, for reproducibility. Bumping to a new release means updating `version` and `hash` in `flake.nix` together.

## Usage

```bash
nix run github:pterror/wyldfire-nix
```

or, from a checkout:

```bash
nix run .
```

## Contributing

Corrections and additions are welcome. Open an issue or pull request at https://github.com/pterror/wyldfire-nix.
