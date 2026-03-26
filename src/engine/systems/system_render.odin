package systems

import "../ecs"
import "../renderer"
import "core:log"

// Renders all renderable entities that are held in the entity world
RenderWorld :: proc(_world : ^ecs.EntityWorld, _renderer : ^renderer.Renderer) {
    ExtractRenderItems(_world, _renderer ,&_renderer.sprite_batcher.items)
    renderer.SortRenderItems(_renderer.sprite_batcher.items[:])

    renderer.BuildBatches(
        _renderer.sprite_batcher.items[:],
        &_renderer.sprite_batcher.instances,
        &_renderer.sprite_batcher.batches,
    )

    renderer.UploadInstancedata(_renderer, _renderer.sprite_batcher.instances[:])

    if !renderer.BeginWorldPass(_renderer) do return
    renderer.SubmitSpriteBatches(_renderer, _renderer.sprite_batcher.batches[:])
}

// Store all the renderable items that qualify to be rendered into an array
ExtractRenderItems :: proc(_world : ^ecs.EntityWorld, _renderer : ^renderer.Renderer ,_out_items : ^[dynamic]renderer.Render_Item) {
    clear(_out_items)

    // #TODO: add renderable tilemap stuff here when implemented

    for i := 0; i < len(_world.sprites.entities); i += 1 {
        e := _world.sprites.entities[i]
        sprite := _world.sprites.data[i]

        // Don't extract any entities that dont have a transform, this is an error
        transform, ok := ecs.GetComponent(&_world.transforms, e)
        if !ok {
            nameComponent, ok := ecs.GetComponent(&_world.names, e); assert(ok)
            log.errorf("ERROR: Attempted to render an entity without a transform, Entity: {}", nameComponent.entityName) // #TODO: maybe put more info about the entity
            continue 
        }

        // Don't extract renderables that aren't visibel (culling)
        // #TODO: Put this into a debug window for imgui
        if !IsSpriteVisible(&_renderer.camera, transform^, sprite) do continue

        item := renderer.Render_Item{
            pass = .World,
            sort_layer = sprite.layer,
            y_sort = transform.pos.y,

            material = renderer.Material_Key{
                pipeline = .Sprite,
                texture = sprite.texture,
                sampler = renderer.Default_Sampler_Handle,
                blend = .Alpha
            },

            instance = renderer.Sprite_Instance{
                model = renderer.MakeSpriteModelMatrix(
                    {transform.pos.x, transform.pos.y},
                    {sprite.size.x, sprite.size.y},
                    {sprite.origin.x, sprite.origin.y},
                    transform.rot,
                    f32(sprite.layer)
                ),
                uv_min = sprite.uv_min,
                uv_max = sprite.uv_max,
                color = sprite.color,
            },
        }

        append(_out_items, item)
    }
}