package assets

import "core:log"
import "core:strings"
import stbi "vendor:stb/image"

Image_Pixel_Format :: enum u8 {
    RGBA8,
}

Image_Data :: struct {
    pixels : [dynamic]u8,
    width : u32,
    height : u32,
    source_channels : u8, // channels in the source file
    bytes_per_pixel : u8, // bytes per output pixel; default always 4
    format : Image_Pixel_Format,
}

ImageByteCount :: proc(_image : Image_Data) -> int {
    return int(_image.width) * int(_image.height) * int(_image.bytes_per_pixel)
}

LoadImageFile :: proc(_path : string, _flip_vertical := false) -> (Image_Data, bool) {
    if len(_path) == 0 {
        log.error("LoadImageFile called without path")
        return Image_Data{}, false
    }

    if _flip_vertical {
        stbi.set_flip_vertically_on_load(1)
    } else {
        stbi.set_flip_vertically_on_load(0)
    }
    defer stbi.set_flip_vertically_on_load(0)

    c_path := strings.clone_to_cstring(_path, context.allocator)

    width, height, source_channels : i32 
    pixels_raw := stbi.load(c_path, &width, &height, &source_channels, 4)

    if pixels_raw == nil {
        reason_str := "unknown stb_image error"
        reason := stbi.failure_reason()
        if reason != nil {
            reason_str = string (reason)
        }

        log.errorf("LoadImageFile failed for: '{}': {}", _path, reason_str)
        return Image_Data{}, false
    }

    defer stbi.image_free(pixels_raw)

    if width <= 0 || height <= 0 {
        log.errorf("LoadImageFile invalid dimensions for '{}': {} x {}", _path, width, height)
        return Image_Data{}, false
    }

    byte_count := int(width) * int(height) * 4
    pixels := make([dynamic]u8, byte_count)
    copy(pixels[:], pixels_raw[:byte_count])

    image := Image_Data{
        pixels = pixels,
        width = u32(width),
        height = u32(height),
        source_channels = u8(source_channels),
        bytes_per_pixel = 4,
        format = .RGBA8,
    }

    return image, true
}

DestroyImage :: proc(_image : ^Image_Data) {
    if _image == nil do return

    if len(_image.pixels) > 0 {
        delete(_image.pixels)
    }

    _image^ = Image_Data{}
}
