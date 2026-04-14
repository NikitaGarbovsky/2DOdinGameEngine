package gameplaygui

import clay "Dependencies:clay/clay-odin"

Clay_UI :: struct {
    initialized : bool,
    clay_ctx: ^clay.Context,
    arena_mem : []u8
}