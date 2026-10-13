// Menu-bar-only mode for the exported macOS app.
//
// Godot forces a regular activation policy at startup (Dock icon + Cmd-Tab entry),
// overriding LSUIElement. This minimal GDExtension switches the app to an "accessory"
// app once Godot has finished starting. It does nothing outside the exported bundle,
// so the Godot editor and `godot --path .` runs are unaffected.
//
// Build: native/macos_agent/build.sh (universal arm64 + x86_64 dylib).

#import <Cocoa/Cocoa.h>
#include <stdint.h>

// Mirrors GDExtensionInitialization from godot's gdextension_interface.h.
typedef enum { LEVEL_CORE, LEVEL_SERVERS, LEVEL_SCENE, LEVEL_EDITOR } InitLevel;
typedef struct {
	InitLevel minimum_initialization_level;
	void *userdata;
	void (*initialize)(void *userdata, InitLevel level);
	void (*deinitialize)(void *userdata, InitLevel level);
} Initialization;

static NSString *const kBundleId = @"dev.fishtank.app";  // keep in sync with export_presets.cfg

static void initialize(void *userdata, InitLevel level) {
	if (level != LEVEL_SCENE) {
		return;
	}
	if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:kBundleId]) {
		return;
	}
	// Queue it, so it runs after Godot has set its own policy and created the window.
	dispatch_async(dispatch_get_main_queue(), ^{
		[NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
	});
}

static void deinitialize(void *userdata, InitLevel level) {}

__attribute__((visibility("default")))
uint8_t fishtank_agent_init(void *get_proc_address, void *library, Initialization *init) {
	init->minimum_initialization_level = LEVEL_SCENE;
	init->initialize = initialize;
	init->deinitialize = deinitialize;
	return 1;
}
