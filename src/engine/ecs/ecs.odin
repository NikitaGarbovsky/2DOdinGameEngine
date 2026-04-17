package ecs

import components "../components"
import "core:fmt"

// #TODO: do commenting for this file

// Initializes all component maps, allocates memory for them.
Init :: proc(_world : ^EntityWorld) {
    _world.next_entity = 0
    _world.alive = make(map[Entity]bool)
    _world.componentSignatures = make(map[Entity]u16)

    _world.transforms.index_of = make(map[Entity]int)
    _world.sprites.index_of = make(map[Entity]int) 
    _world.names.index_of = make(map[Entity]int)
    _world.colliders.index_of = make(map[Entity]int)
    _world.rigid_bodies.index_of = make(map[Entity]int) 
    _world.scripts.index_of = make(map[Entity]int)
    _world.animators.index_of = make(map[Entity]int)
    _world.interactables.index_of = make(map[Entity]int)
    _world.inventory.index_of = make(map[Entity]int)

    fmt.printfln("--- ECS Initialized Successfully.")
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
    RemoveComponent(&_world.sprites, _entityToDelete)
    RemoveComponent(&_world.names, _entityToDelete)
    RemoveComponent(&_world.colliders, _entityToDelete)
    RemoveComponent(&_world.rigid_bodies, _entityToDelete)
    RemoveComponent(&_world.scripts, _entityToDelete)
    RemoveComponent(&_world.animators, _entityToDelete)
    RemoveComponent(&_world.interactables, _entityToDelete)
    RemoveComponent(&_world.inventory, _entityToDelete)

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
    _world.componentSignatures[_entity] &= ~components.ComponentMask(_flag)
}

HasComponent :: proc(_compStore : ^Component_Store($T), _entity : Entity)  -> bool {
    _, exists := _compStore.index_of[_entity]
    return exists
}

GetComponent :: proc(_compStore : ^Component_Store($T), _entity : Entity) -> (^T, bool) {
    idx, exists := _compStore.index_of[_entity]
    if !exists do return nil, false

    return &_compStore.data[idx], true
}

