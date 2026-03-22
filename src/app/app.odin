package app

import "../platform"
import "../engine/ecs"
import "../engine/renderer"
import "../engine/systems"
import "../engine/components"
import math "core:math/linalg"

shader_frag := #load("../../Resources/Shaders/quad.frag.spv")
shader_vert := #load("../../Resources/Shaders/quad.vert.spv")

Init :: proc(_app : ^AppState) {
	platform.Init(&_app.platform)
	ecs.Init(&_app.world)
	renderer.Init(&_app.renderer, &_app.platform, shader_vert, shader_frag)

	// testing code for spawning a bunch of entities
	for i : f32; i < 10; i += 1 {
		e := ecs.CreateEntity(&_app.world)
		ecs.AddComponentToEntityWorld(&_app.world, &_app.world.transforms, e, components.Transform{{100 + i * 100, 100}, 1.1}, .Transform)
		ecs.AddComponentToEntityWorld(&_app.world, &_app.world.sprites, e, components.Sprite{size = {100, 100}, color = {1, 0.2 + i * 0.05, 0.3, 1},}, .Sprite)
	}
}

Run :: proc(app : ^AppState) {
	for app.platform.running {
		platform.ExecuteSDLEvents(&app.platform)

		viewport_size : math.Vector2f32
		viewport_size.x = f32(app.platform.width)
		viewport_size.y = f32(app.platform.height)

		if renderer.BeginFrame(&app.renderer, viewport_size) {
			systems.RenderWorld(&app.world, &app.renderer)
			renderer.EndFrame(&app.renderer)
		}
	}
}

Shutdown :: proc(app : ^AppState) {
	platform.Shutdown(&app.platform)
}
