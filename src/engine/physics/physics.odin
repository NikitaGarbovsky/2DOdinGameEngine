package physics

import b2 "vendor:box2d"
import "../ecs"
import "../components"
import "../tilemap"
import math "core:math/linalg"
import "core:fmt"

///
/// Physics module managing the logic of 2D physics for the engine using Box2D.
///


// Initializes the box2D physics world and relavent physics data
Init :: proc (_pw : ^PhysicsWorld) {
    if _pw.initialized do return

    // Create world
    world_def := b2.DefaultWorldDef()
    world_def.gravity = {0,0}
    _pw.world_id = b2.CreateWorld(world_def)

    _pw.tilemap_wall_body = b2.nullBodyId
    _pw.body_by_entity = make(map[ecs.Entity]b2.BodyId)

    // Set starting values, 60 physics steps per second
    _pw.frametime_accumulator = 0
    _pw.fixed_dt = 1.0 / 60.0
    _pw.substeps = 4

    _pw.initialized = true

    fmt.printfln("--- Physics Intialized Successfully.")
}

// Cleans up physics world
Shutdown :: proc(_pw : ^PhysicsWorld) {
    for _, body_id in _pw.body_by_entity {
        if body_id != b2.nullBodyId {
            b2.DestroyBody(body_id)
        }
    }

    if _pw.tilemap_wall_body != b2.nullBodyId {
        b2.DestroyBody(_pw.tilemap_wall_body)
        _pw.tilemap_wall_body = b2.nullBodyId
    }

    if _pw.world_id != b2.nullWorldId {
        b2.DestroyWorld(_pw.world_id)
        _pw.world_id = b2.nullWorldId
    }

    if len(_pw.body_by_entity) > 0 {
        delete(_pw.body_by_entity)
    }

    _pw.frametime_accumulator = 0
    _pw.initialized = false
}

// Progress (step) through the physicsworld per fixed time step
Step :: proc(_pw : ^PhysicsWorld, _dt : f32) {
    _pw.frametime_accumulator += _dt

    max_steps := 4
    step_count := 0
 
    // If we surpass the fixed_dt rate, and we have not exceeded max_steps, 
    for _pw.frametime_accumulator >= _pw.fixed_dt && step_count < max_steps {
        // Step the physics_world
        b2.World_Step(_pw.world_id, _pw.fixed_dt, _pw.substeps)
        _pw.frametime_accumulator -= _pw.fixed_dt
        step_count += 1
    }
}

// Creates a Box2D body for an Entity, the type of body and collision 
// configuration is created depending on the Rigid_Body & Collider component
// values pre-created for that entity. 
CreateBodyForEntity :: proc(
    _pw : ^PhysicsWorld,
    _entity : ecs.Entity,
    _transform : ^components.Transform,
    _rb : ^components.Rigid_Body,
    _col : ^components.Collider,
) -> bool {
    DestroyBodyForEntity(_pw, _entity)

    // Create default and assign values
    body_def := b2.DefaultBodyDef()
    body_def.type = ToB2BodyType(_rb.body_type)
    body_def.position = ToB2Vec2(_transform.pos)
    body_def.rotation = b2.MakeRot(_transform.rot)
    body_def.linearDamping = _rb.linear_damping
    body_def.gravityScale = _rb.gravity_scale
    body_def.fixedRotation = _rb.fixed_rotation

    // Create the body and assign configured body definition
    body_id := b2.CreateBody(_pw.world_id, body_def)

    shape_def := b2.DefaultShapeDef()
    shape_def.isSensor = _col.is_trigger

    if _rb.body_type == .Dynamic {
        shape_def.density = 1.0
    } else {
        shape_def.density = 0.0
    }

    switch _col.shape {
        case .Box : 
        poly := b2.MakeBox(_col.half_extends[0], _col.half_extends[1])
        _ = b2.CreatePolygonShape(body_id, shape_def, poly)

        case .Circle : {
            // #TODO: nothing is a circle right now, but it might be in
            // the future. 
            b2.DestroyBody(body_id)
            return false
        }
    }

    // Assign the newly created body to the entity <-> body map
    _pw.body_by_entity[_entity] = body_id
    return true
}

// Destroys a B2Body the entity has mapped to it.
DestroyBodyForEntity :: proc(_pw : ^PhysicsWorld, _entity : ecs.Entity) {
    body_id, ok := _pw.body_by_entity[_entity]
    if !ok do return 

    if body_id != b2.nullBodyId {
        b2.DestroyBody(body_id)
    }

    delete_key(&_pw.body_by_entity, _entity)
}

// Sets linear velocity of the entity (called in an update loop for movement)
SetLinearVelocity :: proc(_pw : ^PhysicsWorld, _entity : ecs.Entity, _vel : math.Vector2f32) {
    body_id, ok := _pw.body_by_entity[_entity]
    if !ok do return 

    b2.Body_SetLinearVelocity(body_id, ToB2Vec2(_vel))
}

// After stepping in update, this syncs all entities transform component to the physics transform
SyncTransformsFromPhysics :: proc(_pw : ^PhysicsWorld, _world : ^ecs.EntityWorld) {
    for entity, body_id in _pw.body_by_entity {
        transform, ok := ecs.GetComponent(&_world.transforms, entity)
        if !ok do continue

        pos := b2.Body_GetPosition(body_id)
        transform.pos = {pos[0], pos[1]}

        rot := b2.Body_GetRotation(body_id)
        transform.rot = b2.Rot_GetAngle(rot)
    }
}

// Loops through all the walls on the tilemap, generates their collision bodys and attached all 
// of them it to one giant static wall body. 
BuildTilemapWallCollision :: proc(_pw : ^PhysicsWorld, _level :^tilemap.Level_State) -> bool {
    DestroyTilemapWallCollision(_pw)

    // Default initialization
    body_def := b2.DefaultBodyDef()
    body_def.type = .staticBody
    body_def.position = {0,0}

    // Creates the wall
    wall_body := b2.CreateBody(_pw.world_id, body_def)
    half_w := _level.resources.tile_w * 0.5
    half_h := _level.resources.tile_h * 0.5

    // Dimension of each tile diamond collision shape.
    local_points := [4][2]f32{
        {0, -half_h},
        {half_w, 0},
        {0, half_h},
        {-half_w, 0},
    }

    // Create a hull, a template for creating each collision shape
    hull := b2.ComputeHull(local_points[:])
    if hull.count < 3 {
        b2.DestroyBody(wall_body)
        return false
    }

    shape_def := b2.DefaultShapeDef()
    shape_def.isSensor = false
    shape_def.density = 0.0

    // Grab reference to the tilemap wall layer
    tmap := tilemap.GetTilemapForLayer(_level, .Walls)

    // Flags when creating them
    created_any := false
    amount_created := 0

    // Loop through every wall tile in the tilemap, 
    for cell, inst in tmap.tiles {

        // Validate,
        def, ok := tilemap.GetTileDef(&_level.defsLibrary, inst.def_id)
        if !ok do continue 
        if def.collision != .Full_Diamond do continue

        // Get the tiles world position,
        center := tilemap.IsoGridCoordinateToWorldPos(
            cell,
            _level.resources.tile_w,
            _level.resources.tile_h
        )
        // Create a polygon physics shape based off the tiles position,
        poly := b2.MakeOffsetPolygon(hull, center, b2.Rot_identity)

        // Add it to the woll body.
        _ = b2.CreatePolygonShape(wall_body, shape_def, poly)

        created_any = true
        amount_created += 1 // #TODO: show this in editor
    }

    if !created_any {
        b2.DestroyBody(wall_body)
        return false
    }

    _pw.tilemap_wall_body = wall_body
    return true
}

DestroyTilemapWallCollision :: proc(_pw : ^PhysicsWorld) {
    if _pw.tilemap_wall_body != b2.nullBodyId {
        b2.DestroyBody(_pw.tilemap_wall_body)
        _pw.tilemap_wall_body = b2.nullBodyId
    }
}