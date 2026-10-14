# Decisions

Why Pocket Reef is built the way it is. Each entry gives the context, the decision, and its consequences. Newest decisions go at the bottom. **Don't undo a decision without reading its entry first.** Several of these were learned the hard way.

---

### 1. Godot 4 + GDScript, Compatibility renderer
- **Context:** we needed a transparent, borderless, always-on-top window with a tray icon on macOS and Windows, plus pixel art or simple 3D.
- **Decision:** Godot 4.7, GDScript, the `gl_compatibility` renderer.
- **Why:** transparency, mouse passthrough, `StatusIndicator` and native windows are built in. In testing, the Metal-based Mobile renderer was worse: +2 percentage points of CPU, +95 MB of memory and 4× the graphics memory.
- **Consequences:** a single codebase. macOS-only behaviour goes in a small native plugin (#7).

### 2. 2D pixel art from code, ENDESGA 32 palette
- **Decision:** sprites are ASCII silhouettes plus colour ramps, rendered by `tools/spritegen` using shared lighting and outline rules. Only the 32 ENDESGA colours are allowed.
- **Why:** pixel art reads well at small overlay sizes. Code-generated art keeps every species consistent and makes colour variants almost free (there are 32).
- **Consequences:** hand-edited PNGs are overwritten when sprites are regenerated (see INSTRUCTIONS). It's less charming than hand-placed pixels; hero sprites could later be polished in Aseprite.

### 3. One sprite per fish, animated by a shader
- **Decision:** `swim.gdshader` bobs pixel columns, more toward the tail; plants sway the same way.
- **Why:** this cuts the art workload by roughly 10×.

### 4. Fish never die
- **Decision:** hunger only makes fish sluggish.
- **Why:** it's a cozy desktop toy, and being punished for forgetting it over a weekend is bad UX.

### 5. Stocking and capacity
- **Decision:** a standard 192×120 tank holds 24 "spaces", scaled by tank area (a nano tank holds 7). Each species has a bioload and a per-tank maximum (only 1 betta).
- **Why:** gentle realism that also limits clutter.

### 6. "Hide" means invisible and click-through, not a hidden window
- **Context:** Godot refuses to hide its main window.
- **Decision:** hiding sets `visible = false` and `mouse_passthrough`, and stops the tank stepping.
- **Consequences:** a hidden tank costs about 2% CPU, and the bubbling sound continues.

### 7. Native GDExtension for macOS behaviour
- **Context:** Godot forces a Dock icon and ignores `LSUIElement`.
- **Decision:** a tiny Objective-C plugin written against the raw C API, with no godot-cpp. It sets the accessory activation policy (exported bundle only), reports occlusion (#12) and opts out of App Nap (#11).
- **Consequences:** the universal dylib is committed. Rebuild it with `native/macos_agent/build.sh` when `agent.m` changes.

### 8. Open at login: the OS is the source of truth
- **Decision:** a per-user LaunchAgent on macOS and the `HKCU\…\Run` key on Windows. It isn't stored in the save file, and it's only available in the installed app.
- **Why:** the checkbox can never drift out of sync with System Settings.

### 9. Ad-hoc signing for now
- **Decision:** builds are ad-hoc signed with Godot's built-in signer.
- **Consequences:** they run on the developer's Mac, but other Macs warn about an unidentified developer. Developer ID signing and notarization are needed before distributing.

### 10. Timing: low-processor mode plus the tank's own clock. Never a frame cap.
This is the most important decision. History:
- **v0.2.1** lowered `Engine.max_fps` to save power.
- **v0.2.2** idled at 1 fps. On macOS, Godot's frame cap **sleeps the main thread** (it only uses an event-friendly timer when accessibility is active), and the main loop also runs during menu tracking. Clicking the menu-bar icon froze the user's whole menu bar (one request took 19 s).
- **v0.2.3** put a floor of 10 fps on idling. The UI still felt sluggish, because one loop renders every window, so the settings window was capped at the tank's frame rate.
- **Forcing accessibility "always"** (which uses the event-friendly timer) was tried and rejected: the frame cap stopped holding (75 fps, +50% CPU).

**Decision (v0.4):** `low_processor_usage_mode = true` and `max_fps = 0`. The tank animates on `main.gd _tick()` at the Performance setting. The UI redraws when it changes (measured at ~116 fps while the tank ran at 12). Hidden or covered, nothing steps, so 0 frames are drawn.

**Consequences:**
- About 1 percentage point more CPU than a capped loop.
- No animation in `_process`, and no `TIME` in shaders.
- `tests/responsiveness.sh` guards against regressions.

### 11. Opt out of App Nap and timer coalescing
- **Context:** with nothing of ours on screen, macOS "naps" the app and stretches its sleeps, so menu clicks waited 400–600 ms.
- **Decision:** `NSProcessInfo beginActivity(UserInitiatedAllowingIdleSystemSleep | LatencyCritical)`. Without the latency-critical flag, the spikes remained.
- **Consequences:** the Mac still sleeps normally. This is skipped inside the Godot editor.

### 12. Occlusion via an environment variable
- **Decision:** the native plugin sets `POCKETREEF_OCCLUDED` ("1" or "0") from AppKit's window-visibility notifications, and `main.gd` polls it 4× a second. Only `GodotWindow`s count, because the menu-bar icon's window is always visible.
- **Why:** it avoids registering a GDExtension class through the raw C API just to pass one boolean.

### 13. Water, floor and glass are drawn at runtime
- **Decision:** `tank_renderer.gd` draws them for any size, using per-pixel hashes so resizing never reshuffles the gravel.
- **Why:** this enables the resizable tank (96×72 to 256×144) and the 7 floors.

### 14. Settings window HiDPI: canvas_items scaling
- **Context:** the window first rendered at half size on Retina screens. On macOS, Godot window sizes are in **pixels**, not points.
- **Decision:** size the window as logical size × `screen_get_scale()`, with `CONTENT_SCALE_MODE_CANVAS_ITEMS`. On resize, set `content_scale_size = size / scale`, so the layout reflows instead of zooming.

### 15. Versioned save file with migrations
- **Decision:** `format` in `tank.json`. Migrations live in `TankState.load_state` (format 1 → starter decor) and `migrate_legacy_save` (the "Fishtank" folder → "Pocket Reef"). Bump `SAVE_FORMAT` and add a migration for any breaking change.

### 16. The name: Pocket Reef
- **Decision:** renamed from "Fishtank" in v0.5. Names containing "Desk" or "Aquarium" were avoided because *DeskFins* (an upcoming Steam game), *Deskquarium* and several "Desktop Aquarium" apps exist.
- **Consequences:** the bundle id `com.pocketreef.app` is a placeholder until a domain is owned. The save and login item migrate automatically. Do a trademark check before a public launch.

### 17. Tests drive the real app
- **Decision:**
  - The smoke test instantiates `main.tscn` and checks behaviour, including frames actually drawn and real screen captures (it subtracts whatever is behind the window).
  - The perf probe measures CPU from `ps`.
  - The responsiveness script times Apple Event replies.
- **Why:** internal-state-only tests missed the "frozen tank when hidden" bug (v0.2.3).

### 18. Outside "quit" requests during tests
- **Context:** a third-party utility on the developer's Mac (Vorssaint) quits regular apps a few seconds after their last window closes. Test runs appear as a regular "Godot" app, so it quit them. The packaged menu-bar app is unaffected.
- **Decision:** the smoke test disconnects the window's close handler and logs a note instead of quitting.

### 19. A responsive settings window, not a fixed layout
- **Context:** shrinking the window cut off content on the right (fixed 4- and 5-column grids, wide rows), and it couldn't go below 640×520.
- **Decision:**
  - The window can shrink to 420×400 (logical).
  - `_reflow()` sets each grid's column count from the available width.
  - Below 600 logical px, label/control rows stack vertically.
  - The "Add fish" row and the decor header wrap (they use `HFlowContainer`).
  - Long captions shorten with "…".
  - Zoom = window width ÷ design width, clamped to **0.9–1.35**: bigger windows get bigger text, but small ones never drop below 90% (about 13.5 px), so text stays readable.
- **Consequences:** `tests/settings_layout.tscn` must pass. A new wide control needs either a reflow rule or a minimum width under about 300 px.

### 20. A bigger roster from photo-checked colours, kept in the palette
- **Context (v0.6):** the tank had 11 species and 29 morphs. We wanted a much larger, recognisable collection, including reef fish and oddballs.
- **Decision:**
  - Add 18 species in four groups, chosen because they look distinct and are popular:
    - **Community:** platy, molly, zebra danio, cherry barb, cardinal and rummynose tetras.
    - **Showpieces:** discus, dwarf gourami, bristlenose pleco, German blue ram.
    - **Reef:** blue tang, yellow tang, royal gramma, mandarin dragonet.
    - **Oddballs:** pea puffer, kuhli loach, axolotl, ghost shrimp.
  - Give every species at least 3 morphs (2 where the real fish has no well-known colour forms). That makes 29 species and 94 morphs.
  - Check each morph against photos and descriptions of the real fish, then map it to the nearest ENDESGA 32 ramp. No new colours (#2).
  - Reuse habits instead of inventing new ones: the pleco is a `glass` fish, kuhlis and mandarins are `bottom` fish that don't gulp air (`"air": false`), and the royal gramma has a `host` (the rock arch), as the clownfish has the anemone.
  - The renderer gained two small options: a morph may bring its own `shape` (markings), and a `tail` ramp may differ from the other fins.
- **Why:** distinct silhouettes and true-to-life markings matter more than exact hues at this size, and the palette keeps the tank cohesive. A cousin with the same outline (green neon, powder blue tang, purple tang) costs one morph instead of one species.
- **Consequences:**
  - Freshwater and reef fish can share a tank. It's a cozy toy (#4), so realism stops at habits and colours.
  - See-through animals are an exception to the transparency rule (see the style guide).
  - The smoke test now checks that every species spawns and every morph has a sprite, so a missing PNG or import fails the build.
