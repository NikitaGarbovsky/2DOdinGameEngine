package platform

import sdl "vendor:sdl3"
import "base:runtime"
import "core:log"

Platform :: struct {
    window : ^sdl.Window,
    gpu : ^sdl.GPUDevice,
    running : bool,
    width : i32,
    height : i32,
}

Init :: proc(_p : ^Platform) {
    ok := sdl.Init({.VIDEO, .EVENTS}); assert(ok)

    _p.window = sdl.CreateWindow("2DOdinGameEngine", 1920, 1080, sdl.WINDOW_RESIZABLE); assert(_p.window != nil)

    _p.gpu = sdl.CreateGPUDevice({.SPIRV}, true, nil); assert(_p.gpu != nil)

    ok = sdl.ClaimWindowForGPUDevice(_p.gpu, _p.window); assert(ok)

    _p.running = true
    _p.width = 1920
    _p.height = 1080


    // #TODO: set this logging info back up make up
    // sdl.SetLogPriorities(.VERBOSE)
	// sdl.SetLogOutputFunction(proc "c" (userdata : rawptr, category : sdl.LogCategory, priority: sdl.LogPriority, message: cstring){
	// 	context = default_context
	// 	log.debugf("SDL {} [{}]: {}", category, priority, message)
	// }, nil)
}

ExecuteSDLEvents :: proc(_p : ^Platform) {

    // Process events
    ev: sdl.Event
    for sdl.PollEvent(&ev) {
        #partial switch ev.type {
            case .QUIT:
                _p.running = false
        }
    }
}

Shutdown :: proc(_p : ^Platform) {
    if _p.window != nil {
        sdl.DestroyWindow(_p.window)
        _p.window = nil
    }
    sdl.Quit()
}