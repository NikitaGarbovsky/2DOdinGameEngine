package systems  

import "../gameplayGUI"
import "../renderer"
import "core:log"
import clay "Dependencies:clay/clay-odin"

// Sends all the batched (clay) gameplay gui render items to the gpu. 
RenderGameplayGUI :: proc(
    _renderer : ^renderer.Renderer,
    _commands : ^clay.ClayArray(clay.RenderCommand),
) {
    clear(&_renderer.sprite_batcher.items)

    // Loop through the clay render commands and add each as a render item
    // to the batced render item list
    for i : i32 = 0; i < _commands.length; i += 1 {
        cmd_ptr := clay.RenderCommandArray_Get(_commands, i)
        if cmd_ptr == nil do continue

        cmd := cmd_ptr^

        if cmd.commandType != .Rectangle do continue

        item := gameplayGUI.CreateGamplayGUIRenderItem(
            cmd.boundingBox,
            cmd.renderData.rectangle.backgroundColor,
        )
        append(&_renderer.sprite_batcher.items, item)
    }

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