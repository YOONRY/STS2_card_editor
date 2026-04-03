# Slay the Spire 2 Card Art Editor Transfer

This workspace can be copied to another PC and continued there.

Copy these folders:
- `Slay the Spire 2/`
- `tools/`
- `build/`
- `card_art_editor_sandbox/`

Optional to skip:
- `tmp_appdata/`
- `*.log`
- bundled Godot editor binaries

Setup on the new PC:
1. Copy the `sts-2-mod` folder to any location.
2. Install Slay the Spire 2.
3. If the game is not in the default Steam path, set `SLAY_THE_SPIRE_2_DIR` to the game install folder.
4. Install Godot 4.6.x Mono if you want to rebuild tools or PCK files.

Notes:
- `tools/pck_builder/pack_card_art_editor.gd` now uses workspace-relative paths.
- `tools/CardArtEditorBootstrap/CardArtEditorBootstrap.csproj` uses the default Steam install path and can be overridden with `SLAY_THE_SPIRE_2_DIR`.
- `tools/inspect_il.ps1` also supports `SLAY_THE_SPIRE_2_DIR`.

Deployment:
- To continue development, copy the whole workspace.
- To install only the mod, copy `build/card_art_editor_mod/manifest.json`, `build/card_art_editor_mod/card_art_editor.dll`, and `build/card_art_editor_mod/card_art_editor.pck` into the game's `mods/card_art_editor/` folder.
