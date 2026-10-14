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

## Everyday commands

| Task | Command |
|---|---|
| Run | `godot --path .` |
| Run without touching your real tank | `godot --path . -- --save-file=user://dev.json` |
| Smoke test (must pass) | `godot --path . res://tests/smoke_test.tscn -- --save-file=user://smoke_test.json` |
| Settings layout (must pass) | `godot --path . res://tests/settings_layout.tscn -- --save-file=user://layout.json` |
| Responsiveness (macOS, must pass) | `tests/responsiveness.sh` |
| Performance | `godot --path . res://tests/perf_probe.tscn -- --save-file=user://perf.json --scenario=busy` |
| Regenerate all art | `uv run --with pillow tools/spritegen/export_godot.py` |
| Regenerate sounds | `python3 tools/audiogen/bubbles.py` |
| Rebuild the native plugin | `native/macos_agent/build.sh` |
| Build the DMG | `tools/release/build_macos.sh` → `build/PocketReef-<version>.dmg` |

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
1. In `tools/spritegen/species.py`, add the ASCII silhouette, `fin_roots` and variant ramps. The legend is in `render.py`.
2. Regenerate the art, check `art/previews/fish_sheet.png`, then run `godot --headless --path . --import`.
3. In `scripts/species_db.gd`, add the name, variants, habit (`swim`, `bottom`, `crawl` or `glass`), speed, bioload, max, depth, wobble and blurb. Optional fields: `host`, `food_sight`.
4. If it needs new behaviour, add a habit in `fish.gd` (`_steer_*`).
5. Add smoke checks, update the README counts, and add a DECISIONS entry if it's notable.

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

## Gotchas

- **macOS window sizes in Godot are pixels:** multiply logical sizes by `DisplayServer.screen_get_scale()`.
- **Godot can't hide its main window,** so "hidden" means invisible and click-through.
- **Test runs show up as "Godot",** a regular app. Auto-quit utilities may send it a quit; the smoke test ignores those.
- **Screen-capture checks** need Screen Recording permission for the terminal running the tests. Without it, those checks are skipped.
- **New `class_name` scripts and assets** need `godot --headless --path . --import` before CLI runs.
- **In shell scripts, never `rm` a path built from unchecked variables.** Use `"${VAR:?}"`.
- **The bundle id** `com.pocketreef.app` appears in three places: `export_presets.cfg`, `login_item.gd` and `agent.m`.

## Commits

Write a short imperative subject and a body that explains *why*. Version bumps go in the subject, e.g. `v0.5.0: …`. Run all three tests before committing.
