package tilemap 

import sdl "vendor:sdl3"
import "../renderer"
import "../assets"
import "../renderdata"

///
/// Initializes the tilemap editor, primarily the palette.
///


// Loads the spritesheet and creates gpu resources for the renderer to reference it.
InitEditorPallete_Cave :: proc(
    _level : ^Level_State,
    _renderer : ^renderer.Renderer,
) {
    sprite_path := "Resources/Sprites/tileset_cave_1.png"

    image, ok := assets.LoadImageFile(sprite_path); assert(ok)
    defer assets.DestroyImage(&image)
    
    tex, ok2 := renderer.CreateTextureFromImage(_renderer, image); assert(ok2)

    _level.editor.palette_texture = tex

    tex_index := int(tex)
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

    _level.editor.palette_open = false
    _level.editor.selected_group = .Ground
    _level.editor.palette_thumb_size = 72
    _level.editor.palette_window_size = {480, 360}
    _level.editor.palette_items = _level.editor.palette_items

    // Creates a meta data file which will help configure parts of the loaded sprite sheet 
    // (currently only the origin points of each sprite)
    _level.editor.tileset_meta_path = "Resources/Sprites/tileset_cave_1.origins.json"

    RegisterHardcodedCavePalette(_level, image.width, image.height, tex)
    LoadTileOriginOverrides(_level)

    if len(_level.editor.palette_items) > 0 {
        SelectTileForPainting(_level, _level.editor.palette_items[0].def_id)
    }
}

// Loops through all the sprites in the spritesheet to register them as usable tiles for the tilemap editor.
RegisterHardcodedCavePalette :: proc(
    _level       : ^Level_State,
    _image_width : u32,
    _image_height: u32,
    _tex         : renderdata.Texture_Handle,
) {
    for i := 0; i < len(cave_tiles); i += 1 {
        RegisterPaletteTile(_level, _image_width, _image_height, _tex, cave_tiles[i])
    }
}

// Registers a sprite that will be on the tilemap into the tilemap tile library
RegisterPaletteTile :: proc(
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

    def_id := RegisterTileDef(&_level.defsLibrary, &Tile_Definition{
        key = _entry.key,
        texture = _texture,
        sampler = renderdata.Default_Sampler_Handle,
        uv_min = uv_min,
        uv_max = uv_max,
        size = _entry.world_size,
        origin = _entry.origin,
        layer = 0,
        collision = .None,
    })

    append(&_level.editor.palette_items, Palette_Item{
        def_id = def_id,
        label = _entry.label,
        group = _entry.group,
        src_px = _entry.src_px,
        preview_px = {f32(_entry.src_px.w), f32(_entry.src_px.h)},
    })

    return def_id
}