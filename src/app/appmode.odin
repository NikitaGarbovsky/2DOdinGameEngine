package app 

import "../engine/editorimgui"
import "../engine/tilemap"
import "core:fmt"

///
/// User can swap on the fly from editor -> play mode and back.
/// This manages that functionality and state changes, loads/unloads, initialzation
/// for that to occur
///

ToggleAppMode :: proc(_app : ^AppState) {
    switch _app.mode {
        case .Editor: 
            EnterPlaymode(_app)
        case .Playmode: 
            EnterEditormode(_app)
    }
}

EnterPlaymode :: proc(_app : ^AppState) {
    fmt.println("Entering playmode...")
    
    tilemap.ShutdownLevelEditorState(&_app.level)
    editorimgui.ShutdownEditorImgui()

    _app.mode = .Playmode
}

EnterEditormode :: proc(_app : ^AppState) {
    fmt.println("Entering editormode...")

	editorimgui.InitEditorImgui(_app.platform.window, _app.renderer.gpu, _app.renderer.swapchain_color_format, ._1)
	
    tilemap.InitLevelEditorState(&_app.level, &_app.renderer)
	InitFrameStats(&_app.stats)

    _app.mode = .Editor
}
