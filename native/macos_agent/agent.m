// macOS helpers for Fishtank, loaded as a minimal GDExtension.
//
// 1. Menu-bar-only mode. Godot forces a regular activation policy at startup (Dock icon +
//    Cmd-Tab entry), overriding LSUIElement. We switch the app to an "accessory" app once Godot
//    has finished starting. Only inside the exported bundle, so the editor keeps its Dock icon.
//
// 2. Occlusion. macOS tells apps when their windows can't be seen (covered, on another Space,
//    behind a fullscreen app, screen locked or asleep). We publish that as the environment
//    variable FISHTANK_OCCLUDED ("1" = no Fishtank window is visible, "0" = at least one is),
//    which main.gd polls; that avoids registering classes through the GDExtension API for one bool.
//    Only Godot's own windows count: the menu-bar icon lives in a status-bar window that is always
//    visible.
//
// Build: native/macos_agent/build.sh (universal arm64 + x86_64 dylib).

#import <Cocoa/Cocoa.h>
#include <stdint.h>
#include <stdlib.h>

// Mirrors GDExtensionInitialization from godot's gdextension_interface.h.
typedef enum { LEVEL_CORE, LEVEL_SERVERS, LEVEL_SCENE, LEVEL_EDITOR } InitLevel;
typedef struct {
	InitLevel minimum_initialization_level;
	void *userdata;
	void (*initialize)(void *userdata, InitLevel level);
	void (*deinitialize)(void *userdata, InitLevel level);
} Initialization;

static NSString *const kBundleId = @"dev.fishtank.app";  // keep in sync with export_presets.cfg
static NSMutableArray *observers;

static void publish_occlusion(void) {
	Class godot_window = NSClassFromString(@"GodotWindow");
	BOOL any_visible = NO;
	for (NSWindow *window in [NSApp windows]) {
		if (godot_window && ![window isKindOfClass:godot_window]) {
			continue;
		}
		if (window.isVisible && (window.occlusionState & NSWindowOcclusionStateVisible)) {
			any_visible = YES;
			break;
		}
	}
	setenv("FISHTANK_OCCLUDED", any_visible ? "0" : "1", 1);
}

static void watch_occlusion(void) {
	observers = [NSMutableArray array];
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	for (NSNotificationName name in @[
			 NSWindowDidChangeOcclusionStateNotification,
			 NSApplicationDidChangeOcclusionStateNotification,
			 NSWindowDidMiniaturizeNotification,
			 NSWindowDidDeminiaturizeNotification,
		 ]) {
		[observers addObject:[center addObserverForName:name
												 object:nil
												  queue:[NSOperationQueue mainQueue]
											 usingBlock:^(NSNotification *note) {
												 publish_occlusion();
											 }]];
	}
	publish_occlusion();
}

static void initialize(void *userdata, InitLevel level) {
	if (level != LEVEL_SCENE) {
		return;
	}
	// Queued, so both run after Godot has set its own policy and created its windows.
	dispatch_async(dispatch_get_main_queue(), ^{
		watch_occlusion();
		if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:kBundleId]) {
			[NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
		}
	});
}

static void deinitialize(void *userdata, InitLevel level) {
	if (level != LEVEL_SCENE || observers == nil) {
		return;
	}
	for (id observer in observers) {
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
	}
	observers = nil;
}

__attribute__((visibility("default")))
uint8_t fishtank_agent_init(void *get_proc_address, void *library, Initialization *init) {
	init->minimum_initialization_level = LEVEL_SCENE;
	init->initialize = initialize;
	init->deinitialize = deinitialize;
	return 1;
}
