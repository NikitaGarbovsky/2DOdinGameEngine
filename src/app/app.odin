package app

import "../platform"
import "../engine/ecs"
import "../engine/renderer"
import "../engine/systems"
import "../engine/components"
import "../engine/assets"
import math "core:math/linalg"
import "core:math/rand"

// Temp shader loading
shader_frag_batch := #load("../../Resources/Shaders/sprite_batch.frag.spv")
shader_vert_batch := #load("../../Resources/Shaders/sprite_batch.vert.spv")

Init :: proc(_app : ^AppState) {
	platform.Init(&_app.platform)
	ecs.Init(&_app.world)
	renderer.Init(&_app.renderer, &_app.platform, shader_vert_batch, shader_frag_batch)
	InitFrameStats(&_app.stats)

	// checkerTexture, ok := renderer.CreateCheckerTexture2x2(&_app.renderer); assert(ok)

	sprite_path := "Resources/Sprites/tileset_cave_1.png"
	image, ok := assets.LoadImageFile(sprite_path); assert(ok)
	defer assets.DestroyImage(&image)

	sprite_texture, ok2 := renderer.CreateTextureFromImage(&_app.renderer, image); assert(ok2)

	xoffset, yoffset : f32
	// testing code for spawning a bunch of entities
	for i : f32; i < 100; i += 1 {
		e := ecs.CreateEntity(&_app.world)
		ecs.AddComponentToEntityWorld(&_app.world, &_app.world.transforms, e, components.Transform{{0 + xoffset, 30 + yoffset}, 0}, .Transform)
		ecs.AddComponentToEntityWorld(&_app.world, 
			&_app.world.sprites, 
			e, 
			components.Sprite{
				texture = sprite_texture,
				uv_min = {0, 0.03125},
				uv_max = {0.0625,0.0625},
				size = {64, 32},
				color = {1,1, 1, 1},
				origin = {0.5, 0.5},
				layer = 0,
			},
			.Sprite)
		if xoffset >= 1920 {
			yoffset += 32
			xoffset = 0
		}
		xoffset += 64

		ecs.AddComponentToEntityWorld(&_app.world, &_app.world.names, e, components.Name{"default name"}, .Name)
	}

	// Temp setting for camera testing, #TODO: remove when input is 
	_app.renderer.camera.position = {960, 540}
	_app.renderer.camera.zoom = 1
}

Run :: proc(_app : ^AppState) {
	for _app.platform.running {
		platform.ExecuteSDLEvents(&_app.platform)

		viewport_size : math.Vector2f32
		viewport_size.x = f32(_app.platform.width)
		viewport_size.y = f32(_app.platform.height)

		// Testing movement, #TODO: probably just remove at some stage.
		// for v in _app.world.alive {
		// 	transform, ok := ecs.GetComponent(&_app.world.transforms, v)
		// 	if ok {
				
		// 		transform.pos[0] += 1
		// 		if transform.pos[0] >= 1920 {
		// 			transform.pos[0] = 0
		// 		}
		// 		transform.rot += 0.01
		// 	}
		// }

		if renderer.BeginFrame(&_app.renderer, viewport_size) {
			systems.RenderWorld(&_app.world, &_app.renderer)
			renderer.EndFrame(&_app.renderer)
		}

		TickFrameStats(&_app.stats)
	}
}

Shutdown :: proc(app : ^AppState) {
	renderer.Shutdown(&app.renderer)
	platform.Shutdown(&app.platform)
}
