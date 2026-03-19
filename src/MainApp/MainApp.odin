package mainapp

import "base:runtime"
import "core:log"
import sdl "vendor:sdl3"
import ecs "../engine/ecs"
import component "../engine/components"

default_context : runtime.Context

StartProgram :: proc() {
	context.logger = log.create_console_logger()
	default_context = context

	sdl.SetLogPriorities(.VERBOSE)
	sdl.SetLogOutputFunction(proc "c" (userdata : rawptr, category : sdl.LogCategory, priority: sdl.LogPriority, message: cstring){
		context = default_context
		log.debugf("SDL {} [{}]: {}", category, priority, message)
	}, nil)

	ok := sdl.Init({.VIDEO, .EVENTS}); assert(ok)

	MainWindow = sdl.CreateWindow(
		"2DOdinGameEngine",
		1920, 
		1080, 
		sdl.WINDOW_RESIZABLE); 
	assert(MainWindow != nil)

	sdlGpu = sdl.CreateGPUDevice({.SPIRV}, true, nil); assert(sdlGpu != nil)
	
	ok = sdl.ClaimWindowForGPUDevice(sdlGpu, MainWindow); assert(ok)

	// =========== Program initialized, run main loop ===========
	MainLoop()
}

@private
MainLoop :: proc() {
	entityWorld : ecs.EntityWorld
	entitys : [dynamic]ecs.Entity
	// Dumby code for testing ecs implementation
	for i : f32 = 0; i < 10; i += 1 {
		e := ecs.CreateEntity(&entityWorld)
		ecs.AddComponentToEntityWorld(&entityWorld, &entityWorld.transforms, e, component.Transform{100 + i, 200 + i}, .Transform)
		append(&entitys, e)
	}
	
	for i := 0; i < len(entityWorld.alive); i += 1{
		hasTransformComponent := ecs.HasComponent(&entityWorld.transforms, entitys[i])
		log.debugf("Entity number: {}, Has transform? {} , and their transform data: {}", i, hasTransformComponent, entityWorld.transforms.data[i])
		
	}

	main_loop: for {
		// process events
		ev: sdl.Event
		for sdl.PollEvent(&ev){

			#partial switch ev.type {
				case .QUIT:
					break main_loop
			}
		}
		// ======================== Render Loop ========================
		cmd_buf := sdl.AcquireGPUCommandBuffer(sdlGpu)
		swapchain_tex : ^sdl.GPUTexture
		ok := sdl.WaitAndAcquireGPUSwapchainTexture(cmd_buf, MainWindow, &swapchain_tex, nil, nil); assert(ok)
		
		color_target := sdl.GPUColorTargetInfo{
			texture = swapchain_tex,
			load_op = .CLEAR,
			clear_color = {0,0.2, 0.4,1},
			store_op = .STORE
		}
		render_pass := sdl.BeginGPURenderPass(cmd_buf, &color_target, 1, nil)
		
		
		sdl.EndGPURenderPass(render_pass)
		ok = sdl.SubmitGPUCommandBuffer(cmd_buf); assert(ok)
		// ======================== Render Loop ========================
	}	

	
	
	CleanUpProgram()
}

CleanUpProgram :: proc() {
	sdl.DestroyWindow(MainWindow)
	sdl.Quit()
}