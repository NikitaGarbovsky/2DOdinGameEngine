package systems

import "../ecs"
import "../renderer"

RenderWorld :: proc(_world : ^ecs.EntityWorld, _renderer : ^renderer.Renderer) {
    renderer.BindTestingPipeline(_renderer)

    for i := 0; i < len(_world.sprites.entities); i += 1 {
        e := _world.sprites.entities[i]
        sprite := _world.sprites.data[i]

        transform, ok := ecs.GetComponent(&_world.transforms, e)
        if !ok do continue

        renderer.DrawQuad(_renderer, transform.pos, sprite.size, transform.rot, sprite.color)
    }
}