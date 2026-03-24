package systems

import "../ecs"
import "../renderer"

RenderWorld :: proc(_world : ^ecs.EntityWorld, _renderer : ^renderer.Renderer) {
    ExtractRenderItems(_world, &_renderer.sprite_batcher.items)
    renderer.SortRenderItems(_renderer.sprite_batcher.items[:])

    renderer.Build_Batches(
        _renderer.sprite_batcher.items[:],
        &_renderer.sprite_batcher.instances,
        &_renderer.sprite_batcher.batches,
    )

    renderer.UploadInstancedata(_renderer, _renderer.sprite_batcher.instances[:])

    if !renderer.BeginWorldPass(_renderer) do return
    renderer.SubmitSpriteBatches(_renderer, _renderer.sprite_batcher.batches[:])
}

ExtractRenderItems :: proc(_world : ^ecs.EntityWorld, _out_items : ^[dynamic]renderer.Render_Item) {
    clear(_out_items)

    for i := 0; i < len(_world.sprites.entities); i += 1 {
        e := _world.sprites.entities[i]
        sprite := _world.sprites.data[i]

        // Don't extract any render items that dont have a transform (they're static)
        transform, ok := ecs.GetComponent(&_world.transforms, e)
        if !ok do continue

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

                color = sprite.color,
            },
        }

        append(_out_items, item)
    }
}