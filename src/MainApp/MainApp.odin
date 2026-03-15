package mainapp

import sdl "vendor:sdl3"

StartProgram :: proc() {

	ok := sdl.Init({.VIDEO, .EVENTS}); assert(ok)

	MainWindow = sdl.CreateWindow(
		"2DOdinGameEngine",
		1280, 
		780, 
		sdl.WINDOW_RESIZABLE); 
	assert(MainWindow != nil)

	sdlRenderer = sdl.CreateRenderer(MainWindow, nil); assert(sdlRenderer != nil)

	// =========== Program initialized, run main loop ===========
	MainLoop()
}

@private
MainLoop :: proc() {
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
	

		sdl.SetRenderDrawColor(sdlRenderer, 20, 20, 20, 255)
		sdl.RenderClear(sdlRenderer)

		sdl.RenderPresent(sdlRenderer)

		// ======================== Render Loop ========================
	}	

	
	CleanUpProgram()
}

CleanUpProgram :: proc() {
	sdl.DestroyWindow(MainWindow)
	sdl.Quit()
}