#!/usr/bin/env bash
# Builds the universal (arm64 + x86_64) menu-bar-agent GDExtension dylib.
set -euo pipefail
cd "$(dirname "$0")"
clang -dynamiclib -fobjc-arc -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=10.13 \
	-framework Cocoa -o libfishtank_agent.dylib agent.m
codesign --force --sign - libfishtank_agent.dylib
lipo -archs libfishtank_agent.dylib
