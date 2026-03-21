package app

import sdl "vendor:sdl3"
import "base:runtime"
import "../engine/ecs"
import "../engine/renderer"
import "../platform"

default_context : runtime.Context // #TODO: hook this up with sdl platform

// Maintains state of the whole application
AppState :: struct {
	platform : platform.Platform,
	world : ecs.EntityWorld,
	renderer : renderer.Renderer,
}
appState : AppState