package app

import "../platform"
import "../engine/ecs"
import "../engine/renderer"
import "../engine/systems"
import "../engine/assets"
import math "core:math/linalg"
import "../engine/tilemap"
import "../engine/renderdata"

// Temp shader loading
shader_frag_batch := #load("../../Resources/Shaders/sprite_batch.frag.spv")
shader_vert_batch := #load("../../Resources/Shaders/sprite_batch.vert.spv")

Init :: proc(_app : ^AppState) {

	// Initialize all the systems of the application
	platform.Init(&_app.platform)
	ecs.Init(&_app.world)
	renderer.Init(&_app.renderer, &_app.platform, shader_vert_batch, shader_frag_batch)
	tilemap.InitLevelState(&_app.level,64,32)
	InitFrameStats(&_app.stats)

	sprite_path := "Resources/Sprites/tileset_cave_1.png"
	image, ok := assets.LoadImageFile(sprite_path); assert(ok)
	defer assets.DestroyImage(&image)

	sprite_texture, ok2 := renderer.CreateTextureFromImage(&_app.renderer, image); assert(ok2)

	// ================== TEMP TILE TESTING ==================
	tilemap.RegisterTileDef(&_app.level.defs, &tilemap.Tile_Definition{
		key = "ground",
		texture = sprite_texture,
		sampler = renderdata.Default_Sampler_Handle,
		uv_min = {0, 0.03125},
		uv_max = {0.0625,0.0625},
		size = {64, 32},
		origin = {0.5, 0.5},
		layer = 0,
		collision = .None,
	})

	ground_id, _ := tilemap.FindTileDefByKey(&_app.level.defs, "ground")

	tilemap.PlaceTile(&_app.level.tmap, tilemap.Tile_Coord{30, 0}, ground_id)
	tilemap.PlaceTile(&_app.level.tmap, tilemap.Tile_Coord{31, 0}, ground_id)
	tilemap.PlaceTile(&_app.level.tmap, tilemap.Tile_Coord{30, 1}, ground_id)
	tilemap.PlaceTile(&_app.level.tmap, tilemap.Tile_Coord{31, 1}, ground_id)
	tilemap.PlaceTile(&_app.level.tmap, tilemap.Tile_Coord{32, 1}, ground_id)

	// Temp setting for camera testing, #TODO: remove when input(mouse scroll/camera zoom) is implemented
	_app.renderer.camera.position = {960, 540}
	_app.renderer.camera.zoom = 2
}

Run :: proc(_app : ^AppState) {
	for _app.platform.running {
		platform.ExecuteSDLEvents(&_app.platform)

		viewport_size : math.Vector2f32
		viewport_size.x = f32(_app.platform.width)
		viewport_size.y = f32(_app.platform.height)

		if renderer.BeginFrame(&_app.renderer, viewport_size) {
			systems.RenderWorld(&_app.world, &_app.level ,&_app.renderer)
			renderer.EndFrame(&_app.renderer)
		}

		TickFrameStats(&_app.stats)
	}
}

Shutdown :: proc(app : ^AppState) {
	renderer.Shutdown(&app.renderer)
	platform.Shutdown(&app.platform)
}
