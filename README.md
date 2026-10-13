# Fishtank (working title)

A tiny pixel-art aquarium that lives on your desktop. It floats above your windows, bubbles quietly in the background, and lives in the menu bar (macOS) or system tray (Windows).

![Tank](docs/screenshots/tank.png)

**Version:** 0.2.0 (prototype), set in `project.godot` → `application/config/version`.

## Installing (macOS)

Open `build/Fishtank-<version>.dmg` and drag **Fishtank** to **Applications**. It lives in the menu bar and has no Dock icon. Quit it from the menu.

## Running from source

You need [Godot 4.7](https://godotengine.org/) (`brew install --cask godot` on macOS).

```bash
godot --path .
```

You can also open the folder in the Godot editor and press **Play**.

| Do this | What happens |
|---|---|
| Click the water | Drops food; hungry fish race for it |
| Drag the tank | Moves it anywhere on screen (the position is remembered) |
| Drag the bottom-right corner | Resizes the tank (smallest 96×72, largest 256×144 tank pixels) |
| **Decorate mode** (menu or Settings → Decor) | The glass turns gold. Drag decorations to move them, double-click to flip, right-click to remove, Esc to finish |
| Right-click the tank | Opens the menu |
| Menu bar / tray icon | The same menu: version, show/hide tank, feed, decorate mode, mute, always on top, settings, quit |

**Settings** has four tabs:
- **Fish:** add or remove fish, rename them, and see how full each one is, plus stocking against the tank's capacity.
- **Decor:** add from the catalogue, flip or remove placed pieces, reset to the starter layout, and toggle decorate mode.
- **Tank:** size (presets or width × height), zoom 2×–5×, bubble volume, mute, always on top, open at login, recentre, and start a new tank.
- **About:** version and where the save data lives.

**Species (7):** neon tetra, goldfish, betta, guppy, corydoras, angelfish and cherry shrimp, with 15 colour variants in all. Corydoras forage on the bottom and dart up for air. Shrimp walk the gravel.

**Decorations (14):** three ribbon plants, Amazon sword, moss ball, boulder, pebbles, rock arch, driftwood, castle, treasure chest and diver (both release bursts of bubbles), conch shell, and an air stone (a constant stream of bubbles).

## Layout

```
project.godot          window: borderless, transparent, always-on-top, 192x120 scaled by whole numbers
scenes/main.tscn       entry point
scripts/
  main.gd              the tank: layers, input (feed/drag/resize/decorate/menu), window management
  tank_renderer.gd     draws water, gravel and glass for any tank size
  decor_layer.gd       decorations on the gravel: placement, hit-testing, bubble emitters
  decor_db.gd          decoration catalogue + starter layout
  fish.gd              fish behaviour: wander, school, avoid crowding, chase food
  food.gd              sinking food flakes
  tank_state.gd        autoload: settings, fish, decor, tank size; saves to user://tank.json
  species_db.gd        species data (speed, depth, stocking, variants)
  tray.gd              menu bar / tray icon + right-click menu
  settings_window.gd   native settings window
  tank_audio.gd        bubbler loop + pops
  login_item.gd        open at login (macOS LaunchAgent / Windows Run key)
native/macos_agent/    tiny GDExtension: menu-bar-only mode for the exported Mac app
tools/release/         build_macos.sh -> DMG
shaders/               swim wobble, plant sway
art/                   generated sprites (see docs/style-guide.md)
assets/audio/          generated bubble sounds
tools/spritegen/       sprite generator (Python + Pillow)
tools/audiogen/        bubble sound synthesiser (Python, standard library only)
tests/                 smoke test
```

## Packaging

```bash
tools/release/build_macos.sh    # -> build/Fishtank-<version>.dmg
```

This needs the Godot 4.7.2 export templates (Editor → Manage Export Templates, or the `.tpz` from the Godot releases page) and Xcode command-line tools. The script:
1. Builds the small native plugin in `native/macos_agent/`. Godot forces a Dock icon, and this plugin turns the app into a menu-bar-only app, but only inside the exported bundle.
2. Exports a universal (Apple Silicon + Intel), ad-hoc signed `.app`.
3. Wraps it in a drag-to-Applications DMG.

**Signing:** the build is only ad-hoc signed. It runs on the Mac that built it, but other Macs will warn about an "unidentified developer" until it's signed with an Apple Developer ID and notarized.

**Version** comes from `project.godot`, and the bundle id is `dev.fishtank.app` (a placeholder until the app has a name).

## Regenerating assets

```bash
uv run --with pillow tools/spritegen/export_godot.py   # fish, decorations, bubbles, icons
python3 tools/audiogen/bubbles.py                      # bubble sounds
```

## Tests

```bash
godot --path . res://tests/smoke_test.tscn -- --save-file=user://smoke_test.json
```

This boots the real tank and drives every setting and menu path: resize, hide/show, always on top, mute, stocking rules, adding/removing fish, feeding from the menu, the settings window, and saving. It refuses to run against your real save file.

**Debug flags** (after `--`):
- `--screenshot=PATH` saves a frame after 3 s and quits.
- `--debug-feed` drops food.
- `--debug-settings[=TAB]` opens the settings window on that tab.

## Design notes

- **Fish never die.** Hunger rises over about 4 hours, including while the app is closed. Starving fish only get sluggish.
- **New tanks** start with one goldfish and a starter layout (two ribbon plants, hairgrass, a boulder and an air stone).
- **Stocking:** a standard tank holds 24 points, and capacity scales with tank area (a nano tank holds 7). Points per fish: shrimp 0; tetra, guppy and corydoras 1; betta 3; angelfish 5; goldfish 6. Only one betta per tank, because they fight. Shrinking an already-full tank is allowed; it just shows "overstocked" and blocks new fish.
- **Small tanks:** tall plants are trimmed so they just reach the surface.
- **Save format 2** (v0.2) adds decor and tank size. v0.1 saves are migrated automatically: your fish are kept and the starter decor is added.
- **Hiding the tank** makes it invisible and click-through, and drops it to 5 fps. Godot can't hide its main window, and this way the bubbling carries on in the background.
- Runs at 30 fps on the lightweight Compatibility renderer, to be kind to battery life.

## Platform status

| | macOS | Windows |
|---|---|---|
| Transparent overlay + drag | ✅ tested | ⚠️ not tested yet |
| Menu bar / tray icon | ✅ tested | ⚠️ not tested yet (Godot supports it) |
| HiDPI scaling | ✅ Retina | ⚠️ uses monitor DPI ÷ 96, needs checking on 125%/150% displays |
| Open at login | ✅ LaunchAgent (create/validate/remove tested) | ⚠️ Run registry key, not tested yet |
| Packaged app | ✅ DMG, menu-bar only, ad-hoc signed | ❌ no installer yet |

## Next up

- Windows `.exe` and installer; Developer ID signing and notarization for macOS.
- Placing decorations, more species, eating animation, tapping the glass.
