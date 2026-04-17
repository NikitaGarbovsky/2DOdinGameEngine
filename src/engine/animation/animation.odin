package animation

import "../assets"
import "../renderer"
import "../renderdata"
import glm "core:math/linalg"
import "core:fmt"

///
/// This horrendous hardcoded module contains the means of loading and using animation in the engine.
/// #TODO: Remove hardcoded stuff and dynamically load this data through editor initialization.
///


LoadEntityAnimations :: proc(_renderer : ^renderer.Renderer) {
    player_anim_bank.directional_sets = make(map[string][8]Animation_Clip)
    minecart_anim_bank.directional_sets = make(map[string][8]Animation_Clip)
    goldingot_anim_bank.directional_sets = make(map[string][8]Animation_Clip)

    sprite_death_sheets := [8]string {
    "Resources/Sprites/PlayerCharacter/Death/villager_death_00000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_10000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_20000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_30000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_40000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_50000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_60000_Sheet.png",
     "Resources/Sprites/PlayerCharacter/Death/villager_death_70000_Sheet.png"}
    
    LoadSpriteSheets(_renderer,&player_anim_bank ,sprite_death_sheets[:], "PlayerDeath", {3600,198}, 16, {0.5, 0.7})

    sprite_walk_sheets := [8]string {
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_00000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_10000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_20000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_30000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_40000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_50000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_60000-Sheet.png",
     "Resources/Sprites/PlayerCharacter/Walk/villager_walk_70000-Sheet.png"}

    LoadSpriteSheets(_renderer,&player_anim_bank ,sprite_walk_sheets[:], "PlayerWalk", {1365, 163}, 15, {0.5, 0.9})

    sprite_idle_sheets := [8]string {
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_00000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_10000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_20000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_30000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_40000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_50000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_60000.png",
     "Resources/Sprites/PlayerCharacter/Idle/villager_idle_70000.png"}

    LoadSpriteSheets(_renderer,&player_anim_bank, sprite_idle_sheets[:], "PlayerIdle", {225, 198}, 1, {0.5, 0.7})

    sprite_idle_sheetsMinecart := [8]string {
        "Resources/Sprites/Minecart/mine_cart_spritesheet0.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet1.png",
        "Resources/Sprites/Minecart/mine_cart_spritesheet2.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet3.png",
        "Resources/Sprites/Minecart/mine_cart_spritesheet4.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet5.png",
        "Resources/Sprites/Minecart/mine_cart_spritesheet6.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet7.png",
        "Resources/Sprites/Minecart/mine_cart_spritesheet8.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet9.png",
        "Resources/Sprites/Minecart/mine_cart_spritesheet10.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet11.png",
        "Resources/Sprites/Minecart/mine_cart_spritesheet12.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet13.png",
        "Resources/Sprites/Minecart/mine_cart_spritesheet14.png",
        //"Resources/Sprites/Minecart/mine_cart_spritesheet15.png",
    }

    LoadSpriteSheets(_renderer, &minecart_anim_bank, sprite_idle_sheetsMinecart[:], "MinecartIdle", {124, 124}, 1, {0.5, 0.7})

    sprite_idle_sheetsGoldBar := [8]string {
        "Resources/Sprites/GoldIngot/goldingot_export_dir1.png",
        "Resources/Sprites/GoldIngot/goldingot_export_dir2.png",
        "Resources/Sprites/GoldIngot/goldingot_export_dir3.png",
        "Resources/Sprites/GoldIngot/goldingot_export_dir4.png",
        "Resources/Sprites/GoldIngot/goldingot_export_dir5.png",
        "Resources/Sprites/GoldIngot/goldingot_export_dir6.png",
        "Resources/Sprites/GoldIngot/goldingot_export_dir7.png",
        "Resources/Sprites/GoldIngot/goldingot_export_dir8.png",
    }

    LoadSpriteSheets(_renderer, &goldingot_anim_bank, sprite_idle_sheetsGoldBar[:], "GoldIngotIdle", {350, 350}, 1, {0.5, 0.5})

    fmt.printfln("--- Animation Sprites Initialized Successfully.")
}

// Loads given sprite sheet into the Animation_Bank for use in the application.
@private
LoadSpriteSheets :: proc(
    _renderer : ^renderer.Renderer, 
    _animation_bank : ^Animation_Bank,
    _spriteSheet : []string, 
    _animationLabel : string,
    _size : [2]f32,
    _frameCount : int,
    _origin : [2]f32)
    {
    directional_clips : [8]Animation_Clip

    for sprite_sheet_path, i in _spriteSheet {
        image, ok := assets.LoadImageFile(sprite_sheet_path); assert(ok)
        defer assets.DestroyImage(&image)

        tex, ok2 := renderer.CreateTextureFromImage(_renderer, image); assert(ok2)
        
        animclip : Animation_Clip
        animclip.texture = tex
        animclip.looping = false
        animclip.name = _animationLabel
        animclip.source_path = sprite_sheet_path
        animclip.frames = make([]Animation_Frame, _frameCount)

        for k := 0; k < _frameCount; k += 1 {
            anim_frame : Animation_Frame
            anim_frame.duration = 0.1
            anim_frame.origin = _origin

            frame_w := _size[0] / f32(_frameCount)
            anim_frame.size = {frame_w, _size[1]}
            anim_frame.uv_min = {f32(k) / f32(_frameCount), 0}
            anim_frame.uv_max = {f32(k + 1) / f32(_frameCount), 1} 
            animclip.frames[k] = anim_frame
        }

        directional_clips[i] = animclip

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
    _animation_bank.directional_sets[_animationLabel] = directional_clips
}

// Movement is velocity based, so we use that velocity to dictate the correct sprite direction to load.
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

// Returns the animation clip based off direction
GetDirectionalClip :: proc(_bank : ^Animation_Bank, _state : string, _animDirection : Animation_Direction) -> (Animation_Clip, bool) {
    clips, ok := _bank.directional_sets[_state]
    if !ok do return {}, false
        
    return clips[int(_animDirection)], true
}

// Plays the animation clip for this animation player
PlayClip :: proc(
    _anim_player : ^Animation_Player,
    _clip : Animation_Clip,
    _looping : bool = true,
    _force_restart : bool = false,
) {
    same_group := _anim_player.current_clip.name == _clip.name
    same_exact_clip := _anim_player.current_clip.source_path == _clip.source_path

    // Already on this exact clip, just update looping 
    if same_exact_clip && !_force_restart {
        _anim_player.current_clip.looping = _looping
        return
    }

    // Switching direction within the same state group (e.g. PlayerWalk -> PlayerWalk)
    // Keeps frame progress instead of restarting from frame 0, makes animation look smooth and continuous :).
    if same_group && !_force_restart {
        preserved_frame := _anim_player.current_frame
        preserved_timer := _anim_player.frame_timer

        _anim_player.current_clip = _clip
        _anim_player.current_clip.looping = _looping

        if len(_anim_player.current_clip.frames) == 0 {
            _anim_player.current_frame = 0
            _anim_player.frame_timer = 0
        } else {
            if preserved_frame >= len(_anim_player.current_clip.frames) {
                preserved_frame = len(_anim_player.current_clip.frames) - 1
            }
            if preserved_frame < 0 {
                preserved_frame = 0
            }

            _anim_player.current_frame = preserved_frame
            _anim_player.frame_timer = preserved_timer
        }

        _anim_player.playing = true
        _anim_player.just_finished = false

        return
    }

    // Full state change, restart animation
    _anim_player.current_clip = _clip
    _anim_player.current_clip.looping = _looping
    _anim_player.current_frame = 0
    _anim_player.frame_timer = 0
    _anim_player.playing = true
    _anim_player.just_finished = false
}

// Progresses through the current animation (clip) located on the animation player
StepAnimationPlayer :: proc(
    _player : ^Animation_Player,
    _dt : f32,
) -> (advanced : bool, frame : Animation_Frame) {
    if !_player.playing do return false, {}
    if len(_player.current_clip.frames) == 0 do return false, {}

    _player.frame_timer += _dt * _player.speed
    _player.just_finished = false

    if _player.frame_timer < _player.per_frame_time {
        return false, _player.current_clip.frames[_player.current_frame]
    }

    _player.frame_timer -= _player.per_frame_time
    _player.current_frame += 1
    advanced = true

    if _player.current_frame >= len(_player.current_clip.frames) {
        if _player.current_clip.looping {
            _player.current_frame = 0
        } else {
            _player.current_frame = len(_player.current_clip.frames) - 1
            _player.playing = false
            _player.just_finished = true
        }
    }

    return true, _player.current_clip.frames[_player.current_frame]
}