# Card Art Editor Session Handoff

This file is a handoff note for the next Codex session.

## Project

- Workspace: `C:\Users\Administrator\Documents\s_2_mod`
- Main mod: `card_art_editor`
- Target game path:
  `C:\Program Files (x86)\Steam\steamapps\common\Slay the Spire 2`

## Main Files

- Mod logic:
  [card_art_override_manager.gd](C:/Users/Administrator/Documents/s_2_mod/source/mods/card_art_editor/card_art_override_manager.gd)
- UI logic:
  [inspect_card_art_editor.gd](C:/Users/Administrator/Documents/s_2_mod/source/mods/card_art_editor/inspect_card_art_editor.gd)
- UI scene:
  [inspect_card_art_editor.tscn](C:/Users/Administrator/Documents/s_2_mod/source/mods/card_art_editor/inspect_card_art_editor.tscn)
- PCK packer:
  [pack_card_art_editor.gd](C:/Users/Administrator/Documents/s_2_mod/tools/pck_builder/pack_card_art_editor.gd)

## Current Feature Set

- In-game `Edit Card Art` button on card inspect screen
- PNG / JPG / JPEG / WebP upload
- GIF upload and animated playback
- Image adjust UI
- Art pack export / import
- Korean / English UI toggle
- Restore current card / restore all
- Experimental full-art mode for normal cards

## Current Stable Areas

- Basic image replacement works
- GIF upload works
- Art pack import/export works
- Popup/button behavior is mostly stable
- Ancient-style card image replacement mostly works again

## Current Known Problem

The main unresolved issue is **full-art rendering quality/stability**.

Most recent state:
- Full-art basically works
- Main remaining visible problem is **image overlap / duplicated-looking rendering inside full-art cards**
- User said this is the last major issue they want solved in that area

Recent symptom examples:
- Full-art image can appear as if one image is drawn more than once
- Sometimes there is still rendering interference inside the card
- We were trying to eliminate the extra horizontal/center duplicate-looking layer

## Important Context About Full-Art Work

Recent work changed full-art several times:

- We moved away from trying to reuse the normal portrait only
- We tried custom full-art layers
- We later adjusted how those layers are attached and cleaned up
- We also split static vs GIF full-art handling
- GIF full-art now trims transparent margins before scaling

Current tuning values and logic are in:
- [card_art_override_manager.gd](C:/Users/Administrator/Documents/s_2_mod/source/mods/card_art_editor/card_art_override_manager.gd)

Look for constants and helpers related to:
- `FULL_ART_*`
- `build_full_art_preview(...)`
- GIF frame trimming / animated full-art frame generation
- custom full-art layer creation / cleanup

## Latest User-Reported State Before This Handoff

User said:
- Session is laggy, so they want a fresh session
- Most things are now working
- The remaining work is mainly around full-art rendering polish

The very latest specific complaint before handoff:
- Full-art still shows image overlap / duplicate-looking rendering inside the card

## Build / Deploy Workflow

Common build command:

```powershell
& "C:\Users\Administrator\Documents\s_2_mod\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe" --headless --path "C:\Users\Administrator\Documents\s_2_mod\tools\pck_builder" -s res://pack_card_art_editor.gd
```

Built PCK output:
- `C:\Users\Administrator\Documents\s_2_mod\build\card_art_editor_mod\card_art_editor.pck`

Game mod PCK path:
- `C:\Program Files (x86)\Steam\steamapps\common\Slay the Spire 2\mods\card_art_editor\card_art_editor.pck`

## Latest Release Zip

Latest packaged release at time of handoff:
- `C:\Users\Administrator\Documents\s_2_mod\release\card_art_editor_release_2026-03-29.zip`

## Notes For Next Session

Recommended next step:
1. Reproduce the full-art overlap issue
2. Inspect the full-art render path only
3. Avoid destabilizing the already-working normal image replacement flow

If full-art work becomes too risky, discuss with the user whether to:
- keep full-art as experimental, or
- temporarily reduce scope and preserve the otherwise stable release

