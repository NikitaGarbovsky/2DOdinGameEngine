package ecs

import components "../components"

Entity :: struct {
    id : u32
    // #TODO: might want to add other information about entities when they're created, generation, reason for creation etc.
}

 // Manages all the entities and their associated components for the ECS system.
EntityWorld :: struct {
    next_entity: u32, // Increments when creating new entities
    alive: map[Entity]bool, // Is this Entity alive in world
    componentSignatures : map[Entity]u16, // Bitset mapped to each entitys components 

    // ========= Component stores =========
    transforms : Component_Store(components.Transform),
    sprites : Component_Store(components.Sprite),
}

// Holds references to the components and their associated entities for the ECS system.
Component_Store :: struct($T : typeid) {
    data : [dynamic]T, // dense array of component data
    entities : [dynamic]Entity, // paralell array of owning entities 
    index_of : map[Entity]int // Lookup from entity to index
}