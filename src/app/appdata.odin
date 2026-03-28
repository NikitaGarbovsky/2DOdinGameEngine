package app

import "core:fmt"
import sdl "vendor:sdl3"
import "base:runtime"
import "../engine/ecs"
import "../engine/renderer"
import "../platform"
import "../engine/tilemap"

default_context : runtime.Context // #TODO: hook this up with sdl platform

// Maintains state of the whole application
AppState :: struct {
	platform : platform.Platform,
	world : ecs.EntityWorld,
	renderer : renderer.Renderer, 
	stats    : Frame_Stats,
    level : tilemap.Level_State
}
appState : AppState

Frame_Stats :: struct {
    freq              : u64,
    last_counter      : u64,
    accum_seconds     : f64,
    frame_count       : i32,
    fps               : f64,
    ms_per_frame      : f64,
}

InitFrameStats :: proc(stats : ^Frame_Stats) {
    stats.freq = sdl.GetPerformanceFrequency()
    stats.last_counter = sdl.GetPerformanceCounter()
    stats.accum_seconds = 0
    stats.frame_count = 0
    stats.fps = 0
    stats.ms_per_frame = 0
}

TickFrameStats :: proc(stats : ^Frame_Stats) {
    now := sdl.GetPerformanceCounter()
    delta_counts := now - stats.last_counter
    stats.last_counter = now

    dt := f64(delta_counts) / f64(stats.freq)

    stats.accum_seconds += dt
    stats.frame_count += 1

    if stats.accum_seconds >= 1.0 {
        stats.fps = f64(stats.frame_count) / stats.accum_seconds
        stats.ms_per_frame = 1000.0 / stats.fps

        // print once per second
        fmt.println("FPS:", stats.fps, "  MS:", stats.ms_per_frame)

        stats.accum_seconds = 0
        stats.frame_count = 0
    }
}