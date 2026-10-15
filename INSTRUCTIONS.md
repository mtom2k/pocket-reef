# Instructions

How to work on Pocket Reef, for people and LLM agents. Read [ARCHITECTURE.md](ARCHITECTURE.md) and [DECISIONS.md](DECISIONS.md) first.

## Setup (macOS)

```bash
brew install --cask godot        # Godot 4.7.x (CLI: `godot`)
brew install uv                  # runs the Python art tools with Pillow
xcode-select --install           # clang, for the native plugin (a prebuilt dylib is committed)
godot --headless --path . --import   # first run: import assets and register classes
```

To package, install the **Godot 4.7.2 export templates**: Editor → Manage Export Templates, or put the `macos.zip` from the release `.tpz` into `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.

## Setup (Windows)

- **Godot 4.7.2:** put `godot.exe` on your PATH (or set `GODOT`). The commands below work in PowerShell or Git Bash.
- **uv:** runs the Python art tools, and makes the installer's icon.
- **Inno Setup 6:** builds the installer. A per-user install is enough: `innosetup-6.x.exe /CURRENTUSER`.
- **Export templates:** Editor → Manage Export Templates, or copy the `windows_*.exe` files and `version.txt` from the release `.tpz` into `%APPDATA%\Godot\export_templates\4.7.2.stable\`.
- On first run, import the assets: `godot --headless --path . --import`.
- The macOS plugin is skipped on Windows. Godot logs three "GDExtension" errors at startup when run from the project; ignore them.

## Everyday commands

| Task | Command |
|---|---|
| Run | `godot --path .` |
| Run without touching your real tank | `godot --path . -- --save-file=user://dev.json` |
| Smoke test (must pass) | `godot --path . res://tests/smoke_test.tscn -- --save-file=user://smoke_test.json` |
| Settings layout (must pass) | `godot --path . res://tests/settings_layout.tscn -- --save-file=user://layout.json` |
| Responsiveness (macOS, must pass) | `tests/responsiveness.sh` |
| Windows by hand (must pass) | Run the app and check the tray icon, right-click menu, feeding, dragging, resizing, hiding and restoring from the tray |
| Performance | `godot --path . res://tests/perf_probe.tscn -- --save-file=user://perf.json --scenario=busy` |
| Regenerate all art | `uv run --with pillow tools/spritegen/export_godot.py` |
| Regenerate sounds | `python3 tools/audiogen/bubbles.py` |
| Rebuild the native plugin | `native/macos_agent/build.sh` |
| Build the DMG | `tools/release/build_macos.sh` → `build/PocketReef-<version>.dmg` |
| Build the Windows downloads | `powershell -ExecutionPolicy Bypass -File tools/release/build_windows.ps1` → `build/PocketReef-<version>-windows-setup.exe` and `-windows-portable.exe` |

**Debug flags** (put them after `--`):
- `--screenshot=PATH` saves a frame after 3 s (change the delay with `--screenshot-delay=S`).
- `--debug-feed` drops food.
- `--debug-settings[=TAB]` opens the settings window; `--debug-close-settings-after=S` closes it.
- `--save-file=user://x.json` uses a different save file.

## Rules

1. **Animate on the tank's clock, not in `_process`.** Add a `step(dt)` and call it from `main.gd _tick()`. Don't use `TIME` in shaders; pass a uniform from the clock. (DECISIONS #10)
2. **Never use `Engine.max_fps` or `render_loop_enabled` to save power.** It freezes the macOS menu bar. (#10)
3. **Keep `_process` cheap.** It runs about 145 times a second.
4. **Art only through the generator, in the palette only.** Edit `tools/spritegen/*.py` and regenerate. A PNG edited by hand gets overwritten.
5. **Breaking save change:** bump `TankState.SAVE_FORMAT` and add a migration in `load_state`, with a smoke check.
6. **Never test against the real save.** Always pass `--save-file`. The smoke test refuses to run otherwise.
7. **Keep the docs current in the same commit:** README (features, counts, version), ARCHITECTURE (structure), DECISIONS (append, don't rewrite history), INSTRUCTIONS (workflow).
8. **Bump `application/config/version`** in `project.godot` for user-visible changes. The app, the DMG name and the save file all read it.
9. **Code style:** GDScript with static types, `##` doc comments on scripts and non-obvious functions, comments that explain *why*, and tabs for indentation.
10. **The settings UI must fit at 420×400.** Give wide controls a reflow rule (add them to `_grids` or `_setting_rows`, or use an `HFlowContainer`) and run the layout test. (DECISIONS #19)
11. **Verify visually.** Render a screenshot (`--screenshot`) or a preview sheet and look at it, rather than trusting state checks alone.

## Checklists

**Add a species**
1. In `tools/spritegen/species.py`, add the ASCII silhouette, `fin_roots` and variant ramps. The legend is in `render.py`. Look at photos of the real fish first and map each colour to the nearest palette ramp.
   - A morph with different markings gets its own `shape` (paint them onto the base silhouette with `_mark`).
   - A tail that differs from the other fins gets a `tail` ramp.
   - Pattern pixels (`1`, `2`) directly above or below a fin are drawn as outline, so use fin-accent pixels (`F`) for spots on a see-through body.
2. Regenerate the art, check `art/previews/fish_sheet.png`, then run `godot --headless --path . --import`.
3. In `scripts/species_db.gd`, add the name, variants, habit (`swim`, `bottom`, `crawl` or `glass`), speed, bioload, max, depth, wobble and blurb. Optional fields: `host`, `food_sight`, `air`. Its position in `SPECIES` is its position in the "Add fish" menu.
4. If it needs new behaviour, add a habit in `fish.gd` (`_steer_*`).
5. The smoke test already checks that every species spawns and every morph has a sprite. Add checks for any new behaviour, update the README counts, and add a DECISIONS entry if it's notable.

**Add a decoration**
1. In `tools/spritegen/decor.py`, add an ASCII shape or a procedural function to `build()`.
2. Regenerate the art and run the import.
3. In `scripts/decor_db.gd`, add a `DECOR` entry (name, sink, optional sway and bubbles) and put it in a `CATEGORIES` group.
4. The smoke test already checks that every decoration spawns.

**Add a floor:** add an entry to `TankRenderer.SUBSTRATES` (style: `speckle`, `sand` or `pebbles`, plus tones). It appears in the UI automatically.

**Release (macOS)**
1. Bump the version.
2. Run all three tests.
3. Run `tools/release/build_macos.sh`.
4. Install from the DMG and check it by hand: the tray menu, settings and feeding.
5. Commit and tag `vX.Y.Z`.

**Release (Windows)**
1. Run the smoke and layout tests on Windows.
2. Run `tools/release/build_windows.ps1`.
3. Install with the setup, then check by hand: the tray icon, right-click menu, settings, feeding, and "Open at login" (it should add, then remove, `Pocket Reef` under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`).
4. Uninstall while the tank is running: it should quit, and the install folder should go.
5. Upload both `.exe` files to the GitHub release with their SHA-256 hashes (the script prints them).

## Gotchas

- **macOS window sizes in Godot are pixels:** multiply logical sizes by `DisplayServer.screen_get_scale()`.
- **Godot can't hide its main window,** so "hidden" means invisible and click-through.
- **Test runs show up as "Godot",** a regular app. Auto-quit utilities may send it a quit; the smoke test ignores those.
- **Screen-capture checks** need Screen Recording permission for the terminal running the tests. Without it, those checks are skipped.
- **New `class_name` scripts and assets** need `godot --headless --path . --import` before CLI runs.
- **In shell scripts, never `rm` a path built from unchecked variables.** Use `"${VAR:?}"`.
- **The bundle id** `com.pocketreef.app` appears in three places: `export_presets.cfg`, `login_item.gd` and `agent.m`.
- **Windows: PowerShell doesn't wait for `godot.exe`,** because it's a GUI program. Pipe its output (`| Out-Host`) when a script needs it to finish first.
- **Windows: `OS.execute` wraps arguments that contain spaces in quotes, but doesn't escape quotes inside them.** To pass a literal quote (for example to `reg`), write `\"`. See `login_item.gd`.
- **Windows "Open at login"** writes the exe's path, so a moved portable `.exe` registers again the next time it starts (`LoginItem.refresh`).

## Commits

Write a short imperative subject and a body that explains *why*. Version bumps go in the subject, e.g. `v0.5.0: …`. Run all three tests before committing.
