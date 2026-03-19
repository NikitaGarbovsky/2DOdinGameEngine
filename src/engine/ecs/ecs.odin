package ecs

import comp "../components"

Entity :: struct {
    id : u32
    // #TODO: might want to add other information about entities when they're created, generation, reason for creation etc.
}

 // Manages all the entities and their associated components for the ECS system.
EntityWorld :: struct {
    next_entity: u32, // Increments when creating new entities
    alive: map[Entity]bool, // Is this Entity alive in world
    signatures : map[Entity]u64, // Tracks which entitys contains which components #TODO: add standardized signature bitsets

    // ========= Component stores =========
    transforms : Component_Store(comp.Transform),
}

// Holds references to the components and their associated entities for the ECS system.
Component_Store :: struct($T : typeid) {
    data : [dynamic]T, // dense array of component data
    entities : [dynamic]Entity, // paralell array of owning entities 
    index_of : map[Entity]int // Lookup from entity to index
}

CreateEntity :: proc (_world : ^EntityWorld) -> Entity {
    newEntity : Entity
    newEntity.id = _world.next_entity
    _world.next_entity += 1

    _world.alive[newEntity] = true
    _world.signatures[newEntity] = 0

    return newEntity
}

DeleteEntity :: proc(_entityToDelete : Entity ,_world : ^EntityWorld) {
    // Mark dead
    // Clear signature
    // Remove this entities components from component stores
}

AddComponent :: proc(_entity : Entity) {

}

RemoveComponent :: proc(_entity : Entity) {

}

HasComponent :: proc(_entity : Entity) {

}

GetComponent :: proc() {

}