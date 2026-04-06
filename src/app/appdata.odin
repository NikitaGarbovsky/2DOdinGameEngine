package app

import "core:fmt"
import sdl "vendor:sdl3"
import "base:runtime"
import "../engine/ecs"
import "../engine/renderer"
import "../platform"
import "../engine/tilemap"
import "../engine/input"
import "../engine/systems"
import "../engine/physics"

default_context : runtime.Context // #TODO: hook this up with sdl platform

// Maintains state of the whole application
AppState :: struct {
	platform : platform.Platform,
    input : input.InputState,
	world : ecs.EntityWorld,
	renderer : renderer.Renderer, 
	stats : systems.Frame_Stats,
    level : tilemap.Level_State,

    mode : App_Mode,
    play_state : Play_State,
    physics_world : physics.PhysicsWorld,
}
appState : AppState

App_Mode :: enum u8 {
    Editor,
    Playmode,
}

editorContext : systems.Editor_Mode_Context

Play_State :: struct {
    player_entity : ecs.Entity,
    has_player : bool,
    move_speed : f32
}

InitFrameStats :: proc(_stats : ^systems.Frame_Stats) {
    _stats.freq = sdl.GetPerformanceFrequency()
    _stats.last_counter = sdl.GetPerformanceCounter()
    _stats.accum_seconds = 0
    _stats.frame_count = 0
    _stats.fps = 0
    _stats.ms_per_frame = 0
    _stats.deleta_seconds = 0
}

TickFrameStats :: proc(_stats : ^systems.Frame_Stats) {
    now := sdl.GetPerformanceCounter()
    delta_counts := now - _stats.last_counter
    _stats.last_counter = now

    dt := f64(delta_counts) / f64(_stats.freq)
    _stats.deleta_seconds = f32(dt)

    _stats.accum_seconds += dt
    _stats.frame_count += 1

    if _stats.accum_seconds >= 0.5 {
        _stats.fps = f64(_stats.frame_count) / _stats.accum_seconds
        _stats.ms_per_frame = 1000.0 / _stats.fps

        // print once per second
        //fmt.println("FPS:", stats.fps, "  MS:", stats.ms_per_frame)

        _stats.accum_seconds = 0
        _stats.frame_count = 0
    }
}