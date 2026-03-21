package systems

import "../ecs"
import "../renderer"

RenderWorld :: proc(_world : ^ecs.EntityWorld, _renderer : ^renderer.Renderer) {
    for i := 0; i < len(_world.sprites.entities); i += 1 {
        e := _world.sprites.entities[i]
        sprite := _world.sprites.data[i]

        transform, ok := ecs.GetComponent(&_world.transforms, e)
        if !ok do continue

        // #TODO: Render entities within the world here
    }
}