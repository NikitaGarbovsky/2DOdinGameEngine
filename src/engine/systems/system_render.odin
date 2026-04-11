package systems

import "../ecs"
import "../renderer"
import "core:log"
import renderdata "../renderdata"
import "../tilemap"

/// A system is a smaller alotment of functionality that is run by main application within it's main loop.

///
/// This system runs the main rendering of the renderables. Primarily the batching, sorting & rendering of them.
///



// Renders all renderable entities & tiles on the tilemap
RenderWorld :: proc(_world : ^ecs.EntityWorld, _level : ^tilemap.Level_State ,_renderer : ^renderer.Renderer) {
    // 1. Clear last frame's render-item list before rebuilding it for this frame.
    clear(&_renderer.sprite_batcher.items)    

    // 2. Extract the renderable tilemap & entity data
    ExtractTilemapRenderItems(_level, _renderer, _level.resources.tile_w, 
        _level.resources.tile_h, &_renderer.sprite_batcher.items)
    ExtractEntityRenderItems(_world, _renderer ,&_renderer.sprite_batcher.items)

    if _level.editor.palette_open {
        // (EDITOR DEBUG) Adds the tilemap grid overlay
        tilemap.ExtractTilemapGridOverlay(
        _level,
        &_renderer.camera,
        &_renderer.sprite_batcher.items,
    )}
    
    // 3. Sort all render items to prepare for batching
    renderer.SortRenderItems(_renderer.sprite_batcher.items[:])

    // 4. Build the batches
    renderer.BuildBatches(_renderer,
        _renderer.sprite_batcher.items[:],
        &_renderer.sprite_batcher.instances,
        &_renderer.sprite_batcher.batches,
    )

    // 5. Ready for rendering, upload batched data.
    renderer.UploadInstancedata(_renderer, _renderer.sprite_batcher.instances[:])

    // 6. Begin Rendering the world
    if !renderer.BeginWorldPass(_renderer) do return

    // 7. Finally, submit the render batches to the gpu
    renderer.SubmitRenderBatches(_renderer, _renderer.sprite_batcher.batches[:])
}

// Store all the postential renderable entitys that qualify to be rendered into the out array
ExtractEntityRenderItems :: proc(
    _entityWorld : ^ecs.EntityWorld, 
    _renderer : ^renderer.Renderer,
    _out_items : ^[dynamic]renderdata.Render_Item) 
{
    cullcount : int
    for i := 0; i < len(_entityWorld.sprites.entities); i += 1 {
        e := _entityWorld.sprites.entities[i]
        sprite := _entityWorld.sprites.data[i]
        // Don't extract any entities that dont have a transform, this is an error
        transform, ok := ecs.GetComponent(&_entityWorld.transforms, e)
        if !ok {
            nameComponent, ok := ecs.GetComponent(&_entityWorld.names, e); assert(ok)
            log.errorf("ERROR: Attempted to render an entity without a transform, Entity: {}", 
            nameComponent.entityName) // #TODO: maybe put more info about the entity
            continue 
        }

        // Don't extract entity sprites that aren't visible (culling)
        if !IsEntitySpriteVisible(&_renderer.camera, transform^, sprite, &cullcount) do continue

        item := renderdata.Render_Item{
            pass = .World,
            sort_layer = sprite.layer,
            y_sort = transform.pos.y,

            material = renderdata.Material_Key{
                pipeline = .Sprite,
                texture = sprite.texture,
                sampler = renderdata.Default_Sampler_Handle,
                blend = .Alpha
            },

            instance = renderdata.Sprite_Instance{
                model = renderdata.MakeSpriteModelMatrix(
                    {transform.pos.x, transform.pos.y},
                    {sprite.size.x, sprite.size.y},
                    {sprite.origin.x, sprite.origin.y},
                    transform.rot,
                    0
                ),
                uv_min = sprite.uv_min,
                uv_max = sprite.uv_max,
                color = sprite.color,
            },
        }

        append(_out_items, item)
    }

    _renderer.culledEntityElementsThisFrame = cullcount
}

// Gets all the tiles from the tilemap & their layers, convert tilemap coordinate to world pos, 
// checks if their visible, if they are, create a new render item and append it to the render list for this frame.
ExtractTilemapRenderItems :: proc(
    _level : ^tilemap.Level_State,
    _renderer: ^renderer.Renderer,
    _cell_w : f32,
    _cell_h : f32,
    _out_items: ^[dynamic]renderdata.Render_Item,
) {
    tilemapLayers := [3]tilemap.Tilemap_Layer{
        .Ground,
        .Walls,
        .Decoration,
    }

    cullcount : int
    
    for layer in tilemapLayers {
        tmap := tilemap.GetTilemapForLayer(_level, layer)

        for cell, placed in tmap.tiles {
            tiledef, ok := tilemap.GetTileDef(&_level.defsLibrary, placed.def_id)
            if !ok do continue
            world_pos := tilemap.IsoGridCoordinateToWorldPos(cell, _cell_w, _cell_h)

            // Don't extract tilemap sprites that aren't visible (culling)
            if !IsTileVisible(&_renderer.camera, world_pos, tiledef, &cullcount) do continue

            sort_layer := renderdata.GROUND_SORT_LAYER

            switch layer {
                case .Ground:
                    sort_layer = renderdata.GROUND_SORT_LAYER
                case .Walls:
                    sort_layer = renderdata.DEPTH_SORT_LAYER
                case .Decoration:
                    sort_layer = renderdata.DEPTH_SORT_LAYER 
                }

            item := renderdata.Render_Item{
                pass = .World,
                sort_layer = sort_layer,
                y_sort = world_pos.y,

                material = renderdata.Material_Key{
                    pipeline = .Sprite,
                    texture  = tiledef.texture,
                    sampler  = tiledef.sampler,
                    blend    = .Alpha,
                },

                instance = renderdata.Sprite_Instance{
                    model = renderdata.MakeSpriteModelMatrix(
                        world_pos,
                        tiledef.size,
                        tiledef.origin,
                        0,
                        f32(tiledef.layer), 
                    ),
                    uv_min = tiledef.uv_min,
                    uv_max = tiledef.uv_max,
                    color  = {1, 1, 1, 1},
                },
            }

            append(_out_items, item)
        }
    }

    _renderer.culledTilemapElementsThisFrame = cullcount
}