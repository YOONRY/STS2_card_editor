# Codex Handoff: Slay the Spire 2 Card Art Editor

Last updated: 2026-03-25 (Asia/Seoul)

## Goal

Build a Slay the Spire 2 mod that lets the player edit card art from the compendium / inspect-card screen.

Requested user flow:
1. Open encyclopedia.
2. Open card compendium.
3. Click a card.
4. Show a button that opens card art editing options.
5. Offer two paths:
   - AI generation based on the current card art.
   - Upload a local image and normalize it to the required format.

## Current architecture

This project does not rely on the unpacked game's placeholder `.cs` files.
The current implementation is split across:

- `tools/CardArtEditorBootstrap/Bootstrap.cs`
  - Custom DLL loaded by the game's mod loader.
  - Uses Harmony.
  - Patches `MegaCrit.Sts2.Core.Nodes.Screens.NInspectCardScreen._Ready()`.
  - Ensures a manager node exists at `/root/CardArtOverrideManager`.
  - Attaches `res://mods/card_art_editor/inspect_card_art_editor.tscn`.

- `Slay the Spire 2/mods/card_art_editor/card_art_override_manager.gd`
  - Tracks card portrait textures.
  - Stores user overrides under `user://card_art_editor/`.
  - Normalizes uploaded images with crop + resize.

- `Slay the Spire 2/mods/card_art_editor/inspect_card_art_editor.gd`
  - Overlay UI for:
    - AI image generation
    - local upload
    - restore original

- `Slay the Spire 2/mods/card_art_editor/inspect_card_art_editor.tscn`
  - Overlay scene instantiated on the inspect card screen.

## Build outputs

Current built mod files are in:

- `build/card_art_editor_mod/manifest.json`
- `build/card_art_editor_mod/card_art_editor.dll`
- `build/card_art_editor_mod/card_art_editor.pck`

These are the files that need to end up in:

- `<game_install_dir>/mods/card_art_editor/`

## Build caveat for the DLL

The current `card_art_editor.dll` was not produced by a simple successful `dotnet build` flow.

Reason:

- the game ships with assemblies that expect newer runtime references than the local .NET 8 setup handled cleanly
- the workspace also ran into NuGet / AppData friction

Practical consequence:

- use the already built DLL first for testing
- if a rebuild is required, expect either:
  - a .NET 9-capable build environment, or
  - direct Roslyn compilation against the game's shipped managed DLLs

Do not assume the `.csproj` alone is enough for a clean rebuild on a fresh machine.

## Important confirmed findings

### 1. The mod list is not proof that the mod is actually running

The game can show a mod in the mod list even when the DLL or PCK failed to load.

### 2. The mod manifest uses snake_case JSON keys

Confirmed on 2026-03-25 by inspecting:

- `MegaCrit.Sts2.Core.Saves.MegaCritSerializerContext::ModManifestPropInit`

Important JSON keys:

- `has_pck`
- `has_dll`
- `affects_gameplay`

Using camelCase (`hasPck`, `hasDll`, `affectsGameplay`) causes the loader to treat those fields as missing.

### 3. The game runtime is based on Godot / MegaDot 4.5.1

Confirmed from the live game log on 2026-03-25:

- `MegaDot v4.5.1.m.8.mono.custom_build`

### 4. A PCK built with Godot 4.6.1 fails to load

Confirmed from the live game log on 2026-03-25:

- `Loading Godot PCK ...`
- `ERROR: Pack created with a newer version of the engine: 4.6.1.`
- `Error loading mod card_art_editor: System.InvalidOperationException: Godot errored while loading PCK file card_art_editor!`

This was the clearest reason the overlay button did not appear during testing.

### 5. The PCK builder was updated to force a 4.5.1-compatible header

See:

- `tools/pck_builder/pack_card_art_editor.gd`

It now:
- uses workspace-relative paths
- rewrites the PCK engine version fields to `4.5.1`

## Current status at handoff

What is known:

- The mod appears in the in-game mod list.
- The manifest was fixed to use snake_case keys.
- The built PCK was patched to a 4.5.1-compatible header.
- The fixed PCK was copied into the game mod folder.

What is not yet confirmed:

- The user has not yet confirmed that the button appears after the 4.5.1 PCK fix.
- There is no confirmed successful in-game overlay attachment yet.

This means the next Codex session should treat the project as:

- loader issue likely fixed
- runtime retest still pending

## Likely next step

1. Launch the game again with the updated mod files.
2. Reopen the card compendium inspect screen.
3. Check whether the button now appears near the bottom-right area of the inspect card UI.

If it still does not appear:

1. Read `%APPDATA%/SlayTheSpire2/logs/godot.log`.
2. Search for:
   - `card_art_editor`
   - `Error loading mod`
   - `bootstrap`
   - `Harmony`
3. Check whether `bootstrap.log` exists under:
   - `%APPDATA%/SlayTheSpire2/card_art_editor/bootstrap.log`
4. If the PCK now loads cleanly but the button is still missing, the next likely issue is that the Harmony patch target or screen attachment timing is wrong.

## Useful local files

- Main handoff doc:
  - `CODEX_HANDOFF.md`

- Mod source:
  - `Slay the Spire 2/mods/card_art_editor/card_art_override_manager.gd`
  - `Slay the Spire 2/mods/card_art_editor/inspect_card_art_editor.gd`
  - `Slay the Spire 2/mods/card_art_editor/inspect_card_art_editor.tscn`

- Bootstrap:
  - `tools/CardArtEditorBootstrap/Bootstrap.cs`
  - `tools/CardArtEditorBootstrap/CardArtEditorBootstrap.csproj`

- PCK builder:
  - `tools/pck_builder/pack_card_art_editor.gd`
  - `tools/pck_builder/project.godot`

- IL / reverse engineering helper:
  - `tools/inspect_il.ps1`
  - `tools/AsmInspect/Program.cs`

- Sandbox verification:
  - `card_art_editor_sandbox/project.godot`
  - `card_art_editor_sandbox/main.tscn`
  - `card_art_editor_sandbox/verify.gd`

## Environment assumptions

- Default game install path:
  - `C:\Program Files (x86)\Steam\steamapps\common\Slay the Spire 2`

- If the game is installed somewhere else, set:
  - `SLAY_THE_SPIRE_2_DIR`

The following tooling now supports that env var:

- `tools/CardArtEditorBootstrap/CardArtEditorBootstrap.csproj`
- `tools/inspect_il.ps1`

## Cautions

- Do not assume the unpacked game's C# files are complete or authoritative.
- Do not assume mod-list visibility means runtime success.
- Do not rebuild the PCK without keeping the final header compatible with Godot 4.5.1.
- The `card_art_editor_sandbox` project only validates scripts and resources in isolation; it does not prove in-game integration works.

## Short summary

The strongest confirmed failure before handoff was a PCK version mismatch.
That mismatch has been fixed in the current build.
The most important next action is an in-game retest plus log inspection if the button still does not appear.
