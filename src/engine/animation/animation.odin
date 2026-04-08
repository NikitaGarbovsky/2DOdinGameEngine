package animation
import "../assets"
import "../renderer"
import "../renderdata"
import "core:fmt"
import "core:strings"

// #TODO: comment all this.


LoadEntityAnimations :: proc(_renderer : ^renderer.Renderer) {

    sprite_death_sheets := [8]string {
    "Resources/Sprites/PlayerCharacter/Death/villager_death_00000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_10000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_20000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_30000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_40000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_50000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_60000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_70000_Sheet.png"}
    
    LoadSpriteSheets(_renderer, sprite_death_sheets[:], "PlayerDeath", {3600,198}, 16)

    sprite_walk_sheets := [8]string {
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_00000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_10000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_20000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_30000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_40000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_50000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_60000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_70000-Sheet.png"}

    LoadSpriteSheets(_renderer, sprite_walk_sheets[:], "PlayerWalk", {1365, 163}, 15)

    sprite_idle_sheets := [8]string {
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_00000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_10000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_20000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_30000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_40000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_50000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_60000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_70000.png"}

    LoadSpriteSheets(_renderer, sprite_idle_sheets[:], "PlayerIdle", {225, 198}, 15)
}

// Loads given sprite sheet into the Animation_Bank for use in the application.
@private
LoadSpriteSheets :: proc(
    _renderer : ^renderer.Renderer, 
    _spriteSheet : []string, 
    _animationLabel : string,
    _size : [2]f32,
    _frameCount : int)
    {
    length := len(_spriteSheet)

    for death_sheet_path, i in _spriteSheet {
        image, ok := assets.LoadImageFile(death_sheet_path); assert(ok)
        defer assets.DestroyImage(&image)

        tex, ok2 := renderer.CreateTextureFromImage(_renderer, image); assert(ok2)
        
        animclip : Animation_Clip
        
        animclip.texture = tex

        animclip.looping = false

        parts := strings.split(death_sheet_path, "/")
        defer delete(parts)
        endpart := parts[len(parts) - 1]

        index := strings.index(endpart, ".")
        endpart = endpart[:index]

        animclip.name = endpart

        animclip.source_path = death_sheet_path

        animclip.frames = make([]Animation_Frame, _frameCount)
        for k := 0; k < _frameCount; k += 1 {
            anim_frame : Animation_Frame
            anim_frame.duration = 0.1
            anim_frame.origin = {0.5,0.5}

            frame_w := _size[0] / f32(_frameCount)

            anim_frame.size = {frame_w, _size[1]}
            anim_frame.uv_min[0] = f32(k) / f32(_frameCount) 
            anim_frame.uv_min[1] = 0
            anim_frame.uv_max[0] = f32(k + 1) / f32(_frameCount) 
            anim_frame.uv_max[1] = 1.0

            animclip.frames[k] = anim_frame
        }
        
        // Add the clip to the animation bank.
        append(&player_anim_bank.animation_clips, animclip)

        // Debugging
        // for clip, i in player_anim_bank.animation_clips {
        //     fmt.printfln("Animation Clip: {}", clip.name)
        //     fmt.printfln("Amount of frames in clip: {}", len(clip.frames))
        //     for frame, k in clip.frames {
        //         fmt.printfln("Frame Size {}",frame.size)
        //         fmt.printfln("Frame uv_min {}",frame.uv_min)
        //         fmt.printfln("Frame uv_max {}",frame.uv_max)
        //     }
        // }

    }
}
