package systems  

import "../gameplayGUI"
import "../renderer"
import "core:log"
import clay "Dependencies:clay/clay-odin"

/// A system is a smaller alotment of functionality that is run by main application within it's main loop.

///
/// This system runs the rendering of gameplay gui which is primarily handled by clay. 
/// It grabs the necessary clay layout data from the preconfigured layout that occured earlier this 
/// update loop, then appends all those elements to the batched sprite renderer under the ui pass.
/// 


// Sends all the batched (clay) gameplay gui render items to the gpu. 
RenderGameplayGUI :: proc(
    _renderer : ^renderer.Renderer,
    _ui : ^gameplayGUI.Clay_UI,
    _commands : ^clay.ClayArray(clay.RenderCommand),
) {
    clear(&_renderer.sprite_batcher.items)

    // Loop through the clay render commands and add each as a render item
    // to the batced render item list. Current Panels & Text
    for i : i32 = 0; i < _commands.length; i += 1 {
        cmd_ptr := clay.RenderCommandArray_Get(_commands, i)
        if cmd_ptr == nil do continue

        cmd := cmd_ptr^

        #partial switch cmd.commandType {
        case .Rectangle: // Simple sprite quad (a gui panel)
            item := gameplayGUI.CreateGamplayGUIRenderItem(
                cmd.boundingBox,
                cmd.renderData.rectangle.backgroundColor,
            )
            append(&_renderer.sprite_batcher.items, item)

        case .Text: // Rendered text
            text_data := cmd.renderData.text
            str := string(text_data.stringContents.chars[:text_data.stringContents.length])

            color := [4]f32{
                f32(text_data.textColor[0]) / 255.0,
                f32(text_data.textColor[1]) / 255.0,
                f32(text_data.textColor[2]) / 255.0,
                f32(text_data.textColor[3]) / 255.0,
            }

            // Send the renderable text block to the renderer
            gameplayGUI.AppendTextRenderItems(
                &_ui.gameplay_font,
                str,
                f32(cmd.boundingBox.x),
                f32(cmd.boundingBox.y),
                color,
                &_renderer.sprite_batcher.items,
            )
        }
    }

    // Checks if the font atlas has changed(dirty), then reloads it. #TODO: Use when implementing runtime changes of font data 
    if !gameplayGUI.UploadFontAtlasIfDirty(_renderer, &_ui.gameplay_font) do return
    if len(_renderer.sprite_batcher.items) == 0 do return

    // Sort the items
    renderer.SortRenderItems(_renderer.sprite_batcher.items[:])

    // Build the batches 
    renderer.BuildBatches(
        _renderer,
        _renderer.sprite_batcher.items[:],
        &_renderer.sprite_batcher.instances,
        &_renderer.sprite_batcher.batches,
    )

    renderer.UploadInstancedata(_renderer, _renderer.sprite_batcher.instances[:])

    // Use the same ui pass as the editor
    pass := renderer.BeginUIPass(_renderer)
    if pass == nil do return

    ui_proj := renderer.MakeOrthoProjection(
        _renderer.viewport_size.x,
        _renderer.viewport_size.y,
    )

    // Using same quad based render pipeline as the rest of the engine.
    renderer.SubmitRenderBatches(
        _renderer,
        _renderer.sprite_batcher.batches[:],
        ui_proj,
    )
}

// Debug helper to see if there are enough correct clay render commands being sent
DebugClayCommandCounts :: proc(_commands : ^clay.ClayArray(clay.RenderCommand)) {
    total_count := 0
    rect_count := 0
    text_count := 0

    for i : i32 = 0; i < _commands.length; i += 1 {
        cmd_ptr := clay.RenderCommandArray_Get(_commands, i)
        if cmd_ptr == nil do continue

        cmd := cmd_ptr^
        total_count += 1

        #partial switch cmd.commandType {
        case .Rectangle:
            rect_count += 1
        case .Text:
            text_count += 1
        }
    }

    log.infof(
        "Clay cmds -> total: {}, rects: {}, text: {}",
        total_count,
        rect_count,
        text_count,
    )
}