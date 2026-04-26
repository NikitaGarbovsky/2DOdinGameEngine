#+vet explicit-allocators
package tilemap 

import sdl "vendor:sdl3"
import "../renderer"
import "../assets"
import "../renderdata"
import "core:strings"
import "core:fmt"

///
/// Initializes the tilemap editor, primarily the palette.
///


// Initializes the editor palette.
InitEditorPallete_Cave :: proc(
    _level : ^Level_State,
    _renderer : ^renderer.Renderer,
) {
    _level.editor.palette_open = false
    _level.editor.selected_group = .Ground
    _level.editor.palette_thumb_size = 72
    _level.editor.palette_window_size = {480, 600}

    if _level.editor.palette_items == nil {
        _level.editor.palette_items = make([dynamic]Palette_Item, 0, 128, context.allocator)
    } else {
        clear(&_level.editor.palette_items)
    }

    tex_index := int(_level.resources.tileset_texture)
    samp_index := int(renderdata.Default_Sampler_Handle)

    assert(tex_index >= 0)
    assert(tex_index < len(_renderer.textures))
    assert(samp_index >= 0)
    assert(samp_index < len(_renderer.samplers))

    _level.editor.palette_texture_binding = sdl.GPUTextureSamplerBinding{
        texture = _renderer.textures[tex_index].gpu,
        sampler = _renderer.samplers[samp_index].gpu,
    }

    _level.editor.palette_texture_imgui_id = cast(rawptr)(&_level.editor.palette_texture_binding)
    assert(_level.editor.palette_texture_imgui_id != nil)

    BuildEditorPaletteItems_Cave(_level)
    _level.editor.palette_items = _level.editor.palette_items

    if len(_level.editor.palette_items) > 0 {
        SelectTileForPainting(_level, _level.editor.palette_items[0].def_id)
    }
}

// Loads the cave spritesheet and creates gpu resources for rendering.
InitCaveTileResources :: proc(
    _level : ^Level_State,
    _renderer : ^renderer.Renderer,
) {
    sprite_path := "Resources/Sprites/tileset_cave_1.png"

    image, ok := assets.LoadImageFile(sprite_path); assert(ok)
    defer assets.DestroyImage(&image)

    tex, ok2 := renderer.CreateTextureFromImage(_renderer, image); assert(ok2)

    _level.resources.tileset_texture = tex
    _level.resources.tileset_meta_path = "Resources/Sprites/tileset_cave_1.origins.json"

    RegisterHardcodedCaveTileDefs(_level, image.width, image.height, tex)
    LoadTileOriginOverrides(_level)

    fmt.printfln("--- Cave Tileset Initialized Successfully.")
}

// Loops through all the sprites in the spritesheet to register them as usable tiles for the tilemap editor.
RegisterHardcodedCaveTileDefs :: proc(
    _level       : ^Level_State,
    _image_width : u32,
    _image_height: u32,
    _tex         : renderdata.Texture_Handle,
) {
    for i := 0; i < len(cave_tiles); i += 1 {
        RegisterTileDefFromPaletteEntry(_level, _image_width, _image_height, _tex, cave_tiles[i])
    }
}

// Registers a sprite that will be on the tilemap into the tilemap tile library
RegisterTileDefFromPaletteEntry :: proc(
    _level : ^Level_State,
    _texture_w : u32,
    _texture_h : u32,
    _texture : renderdata.Texture_Handle,
    _entry : Hardcoded_Palette_Tile,
) -> Tile_Def_ID {
    uv_min := [2]f32{
        f32(_entry.src_px.x) / f32(_texture_w),
        f32(_entry.src_px.y) / f32(_texture_h),
    }

    uv_max := [2]f32{
        f32(_entry.src_px.x + _entry.src_px.w) / f32(_texture_w),
        f32(_entry.src_px.y + _entry.src_px.h) / f32(_texture_h),
    }

    // Assign correct collision type to walls based off its label
    // #TODO: this string lit comparison is kind of bad, but it'll do for now
    collisionkind : Collision_Kind
    name := _entry.label
    if strings.contains(name, "Wall") {collisionkind = .Full_Diamond}
    else {collisionkind = .None}

    def_id := RegisterTileDef(&_level.defsLibrary, &Tile_Definition{
        key = _entry.key,
        texture = _texture,
        sampler = renderdata.Default_Sampler_Handle,
        uv_min = uv_min,
        uv_max = uv_max,
        size = _entry.world_size,
        origin = _entry.origin,
        layer = 0,
        collision = collisionkind,
    })

    return def_id
}

// Loader for the palette tiles from the cave set.
BuildEditorPaletteItems_Cave :: proc(_level : ^Level_State) {
    clear(&_level.editor.palette_items)

    for i := 0; i < len(cave_tiles); i += 1 {
        entry := cave_tiles[i]

        def_id, ok := FindTileDefByKey(&_level.defsLibrary, entry.key)
        if !ok do continue

        append(&_level.editor.palette_items, Palette_Item{
            def_id = def_id,
            label = entry.label,
            group = entry.group,
            src_px = entry.src_px,
            preview_px = {f32(entry.src_px.w), f32(entry.src_px.h)},
        })
    }
}