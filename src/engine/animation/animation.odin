package animation
import "../assets"
import "../renderer"
import "../renderdata"
import glm "core:math/linalg"
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
    
    LoadSpriteSheets(_renderer, sprite_death_sheets[:], "PlayerDeath", {3600,198}, 16, {0.5, 0.7})

    sprite_walk_sheets := [8]string {
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_00000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_10000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_20000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_30000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_40000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_50000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_60000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_70000-Sheet.png"}

    LoadSpriteSheets(_renderer, sprite_walk_sheets[:], "PlayerWalk", {1365, 163}, 15, {0.5, 0.9})

    sprite_idle_sheets := [8]string {
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_00000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_10000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_20000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_30000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_40000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_50000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_60000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_70000.png"}

    LoadSpriteSheets(_renderer, sprite_idle_sheets[:], "PlayerIdle", {225, 198}, 1, {0.5, 0.7})
}

// Loads given sprite sheet into the Animation_Bank for use in the application.
@private
LoadSpriteSheets :: proc(
    _renderer : ^renderer.Renderer, 
    _spriteSheet : []string, 
    _animationLabel : string,
    _size : [2]f32,
    _frameCount : int,
    _origin : [2]f32)
    {
    length := len(_spriteSheet)

    for sprite_sheet_path, i in _spriteSheet {
        image, ok := assets.LoadImageFile(sprite_sheet_path); assert(ok)
        defer assets.DestroyImage(&image)

        tex, ok2 := renderer.CreateTextureFromImage(_renderer, image); assert(ok2)
        
        animclip : Animation_Clip
        animclip.texture = tex

        animclip.looping = false

        parts := strings.split(sprite_sheet_path, "/")
        defer delete(parts)
        endpart := parts[len(parts) - 1]

        index := strings.index(endpart, ".")
        endpart = endpart[:index]

        animclip.name = endpart

        animclip.source_path = sprite_sheet_path

        animclip.frames = make([]Animation_Frame, _frameCount)
        for k := 0; k < _frameCount; k += 1 {
            anim_frame : Animation_Frame
            anim_frame.duration = 0.1
            anim_frame.origin = _origin

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

SetAnimationDirectionFromMovementVelocity :: proc(_movementDirection : glm.Vector2f32, _animationPlayer : ^Animation_Player) {
    switch _movementDirection {
        case {0, 0}: // No movement, default to the current direction
            _animationPlayer.current_direction = _animationPlayer.current_direction
        case {0, 1}: // down (south) 
            _animationPlayer.current_direction = .South
        case {0.70710677, 0.70710677}: // down right (south-east) 
            _animationPlayer.current_direction = .SouthEast
        case {1, 0}: // right (east) 
            _animationPlayer.current_direction = .East
        case {0.70710677, -0.70710677}: // right up (north-east) 
            _animationPlayer.current_direction = .NorthEast
        case {0, -1}: // up (north) 
            _animationPlayer.current_direction = .North
        case {-0.70710677, -0.70710677}: // left up (north-west) 
            _animationPlayer.current_direction = .NorthWest
        case {-1,0}:// left(west)
            _animationPlayer.current_direction = .West
        case {-0.70710677, 0.70710677}: // left down (south-west) 
            _animationPlayer.current_direction = .SouthWest
    }
}

SetAnimationClipBasedOfCurrentDirection :: proc(_animDirection : Animation_Direction, _clip : string) -> Animation_Clip {
    animationClipRange : [8]Animation_Clip
    offsetIndex := 0
    for clip, i in player_anim_bank.animation_clips {
        if strings.contains(clip.name, _clip) {
            animationClipRange[i - offsetIndex] = clip
        } else {
            offsetIndex += 1
        }
    }

    switch _animDirection {
        case .South: // down (south) 
            return animationClipRange[0]
        case .SouthEast: // down right (south-east) 
            return animationClipRange[1]
        case .East: // right (east) 
            return animationClipRange[2]
        case .NorthEast: // right up (north-east) 
            return animationClipRange[3]
        case .North: // up (north) 
            return animationClipRange[4]
        case .NorthWest: // left up (north-west) 
            return animationClipRange[5]
        case .West:// left(west)
            return animationClipRange[6]
        case .SouthWest: // left down (south-west) 
            return animationClipRange[7]
    }

    return animationClipRange[0]
    //fmt.printfln("Found {} clips with {} tag", len(animationClipRange), _clip)
}