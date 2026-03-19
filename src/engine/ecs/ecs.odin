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
    _world.componentSignatures[newEntity] = 0

    return newEntity
}

DeleteEntity :: proc(_world : ^EntityWorld, _entityToDelete : Entity) {
    if !_world.alive[_entityToDelete] do return;

    // Remove from every component store in the world
    RemoveComponent(&_world.transforms, _entityToDelete)
    // #TODO: Add other component stores when implemented.(sprite, colliders etc)

    delete_key(&_world.alive, _entityToDelete)
    delete_key(&_world.componentSignatures, _entityToDelete)
}

@private 
AddComponent :: proc(_compStore : ^Component_Store($T), _entity : Entity, _value: T) {
    if idx, exists := _compStore.index_of[_entity]; exists {
        _compStore.data[idx] = _value
        return
    }

    idx := len(_compStore.data)
    append(&_compStore.data, _value)
    append(&_compStore.entities, _entity)
    _compStore.index_of[_entity] = idx
}

AddComponentToEntityWorld :: proc(_world : ^EntityWorld, _compStore : ^Component_Store($T), _entity : Entity, _value : T, _flag : components.Component_Flag) {
    AddComponent(_compStore, _entity, _value)
    _world.componentSignatures[_entity] |= components.ComponentMask(_flag)
}

@private
RemoveComponent :: proc(_compStore : ^Component_Store($T), _entity : Entity) {
    idx, exists := _compStore.index_of[_entity]

    if !exists do return

    last_index := len(_compStore.data) - 1
    last_entity := _compStore.entities[last_index]

    // Swaps the last component to the removed index spot, 
    _compStore.data[idx] = _compStore.data[last_index]
    _compStore.entities[idx] = _compStore.entities[last_index]
    _compStore.index_of[last_entity] = idx

    // then removes last index.
    pop(&_compStore.data)
    pop(&_compStore.entities)
    delete_key(&_compStore.index_of, _entity)
}

RemoveComponentFromEntityWorld :: proc(_world : ^EntityWorld, _compStore : ^Component_Store($T), _entity : Entity, _flag : components.Component_Flag) {
    RemoveComponent(_compStore, _entity)
    _world.componentSignatures[e] &= ~components.ComponentMask(_flag)
}

HasComponent :: proc(_compStore : ^Component_Store($T), _entity : Entity)  -> bool {
    _, exists := _compStore.index_of[_entity]
    return exists
}

GetComponent :: proc(_compStore : ^Component_Store($T), _entity : Entity)  -> (^T, bool) {
    idx, exists := _compStore.index_of[Entity]
    if !exists do return nil, false

    return &store.data[idx], true
}