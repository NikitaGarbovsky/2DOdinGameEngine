package app

import "../platform"
import "../engine/ecs"
import "../engine/renderer"
import "../engine/systems"
import "../engine/components"

Init :: proc(_app : ^AppState) {
	platform.Init(&_app.platform)
	ecs.Init(&_app.world)
	renderer.Init(&_app.renderer, &_app.platform)

	// testing code for spawning a bunch of entities
	for i : f32; i < 10; i += 1 {
		e := ecs.CreateEntity(&_app.world)
		ecs.AddComponentToEntityWorld(&_app.world, &_app.world.transforms, e, components.Transform{{100 + i * 40, 100}, 0}, .Transform)
	}
}

Run :: proc(app : ^AppState) {
	for app.platform.running {
		platform.ExecuteSDLEvents(&app.platform)

		if renderer.BeginFrame(&app.renderer) {
			systems.RenderWorld(&app.world, &app.renderer)
			renderer.EndFrame(&app.renderer)
		}
	}
}

Shutdown :: proc(app : ^AppState) {
	platform.Shutdown(&app.platform)
}
