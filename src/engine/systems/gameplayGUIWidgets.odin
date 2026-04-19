#+vet explicit-allocators
package systems

import "../input"
import "../renderdata"
import gui "../gameplayGUI"
import clay "Dependencies:clay/clay-odin"
import "../ecs"
import "core:fmt"

///
/// This file contains the immediate mode decleration for gameplaygui widgets.
/// Each procedure represents a single widget which is displayed based on gameplay 
/// conditions.
///

// Builds all the immediate mode gameplay gui per frame
BuildGameplayGUI :: proc(
    _ui : ^gui.Clay_UI,
    _world : ^ecs.EntityWorld,
    _player_entity : ecs.Entity,
    _interaction : ^Interaction_State,
    _input : ^input.InputState,
    _camera : ^renderdata.Camera2D,
    _screen_size : [2]f32,
) -> clay.ClayArray(clay.RenderCommand) {
    {
    clay.SetCurrentContext(_ui.clay_ctx)
    clay.SetLayoutDimensions(clay.Dimensions{
        _screen_size.x,
        _screen_size.y,
    })

    clay.SetPointerState(
        clay.Vector2{_input.mouse_x, _input.mouse_y},
        _input.left_down,
    )

    clay.UpdateScrollContainers(false, clay.Vector2{0, 0}, 0)
    clay.BeginLayout()

    if clay.UI()(clay.ElementDeclaration{
        id = clay.ID("GameplayHudRoot"),
        layout = clay.LayoutConfig{
            sizing = clay.Sizing{
                width = clay.SizingGrow({0, 0}),
                height = clay.SizingGrow({0, 0}),
            },
        },
    }) {
        BuildGoldInventoryHUD(_world, _player_entity)

        BuildHoverTooltipContents(
            _interaction,
            _camera,
            _screen_size,
        )
    }

    return clay.EndLayout()
}
}

// Builds the HoverTooltip layout and creates a render command for it per frame.
BuildHoverTooltipContents :: proc(
    _interaction : ^Interaction_State,
    _camera : ^renderdata.Camera2D,
    _screen_size : [2]f32,
) {
    if _interaction.has_hovered {
        screen_pos := renderdata.WorldToScreenPos(
            _camera,
            _screen_size,
            _interaction.hovered_world_pos,
        )

        tooltip_x := screen_pos.x - 40
        tooltip_y := screen_pos.y - 48

        if clay.UI()(clay.ElementDeclaration{
            id = clay.ID("InteractableHoverTooltip"),
            layout = clay.LayoutConfig{
                layoutDirection = .TopToBottom,
                padding = clay.PaddingAll(5),
                childGap = 10,
                sizing = clay.Sizing{
                    width = clay.SizingFit({0, 0}),
                    height = clay.SizingFit({0, 0}),
                },
            },
            backgroundColor = clay.Color{18, 18, 22, 150},
            cornerRadius = clay.CornerRadiusAll(6),
            floating = clay.FloatingElementConfig{
                offset = clay.Vector2{tooltip_x, tooltip_y},
                zIndex = 100,
                attachment = clay.FloatingAttachPoints{
                    element = .LeftTop,
                    parent = .LeftTop,
                },
                pointerCaptureMode = .Passthrough,
                attachTo = .Parent,
                clipTo = .None,
            },
        }) {
            clay.TextDynamic(
                _interaction.hovered_text,
                clay.TextConfig(clay.TextElementConfig{
                    fontSize = 14,
                    textColor = clay.Color{255, 255, 255, 255},
                    textAlignment = .Center,
                }),
            )

            if _interaction.can_interact {
                clay.Text(
                    "Interact",
                    clay.TextConfig(clay.TextElementConfig{
                        fontSize = 14,
                        textColor = clay.Color{0, 139, 41, 255},
                        textAlignment = .Center,
                    }),
                )
            }
        }
    }
}

// The gold inventory at the top left-hand side of the screen.
BuildGoldInventoryHUD :: proc(
    _world : ^ecs.EntityWorld,
    _player_entity : ecs.Entity,
) {
    gold_amount : i32 = 0

    if inventory, ok := ecs.GetComponent(&_world.inventory, _player_entity); ok {
        gold_amount = inventory.gold
    }

    gold_text := fmt.tprintf("{}", gold_amount)

    if clay.UI()(clay.ElementDeclaration{
        id = clay.ID("GoldInventoryHUD"),
        layout = clay.LayoutConfig{
            layoutDirection = .TopToBottom,
            padding = clay.PaddingAll(8),
            childGap = 4,
            sizing = clay.Sizing{
                width = clay.SizingFit({0, 0}),
                height = clay.SizingFit({0, 0}),
            },
        },
        backgroundColor = clay.Color{18, 18, 22, 180},
        cornerRadius = clay.CornerRadiusAll(6),
        floating = clay.FloatingElementConfig{
            offset = clay.Vector2{16, 16},
            zIndex = 50,
            attachment = clay.FloatingAttachPoints{
                element = .LeftTop,
                parent = .LeftTop,
            },
            pointerCaptureMode = .Passthrough,
            attachTo = .Parent,
            clipTo = .None,
        },
    }) {
        clay.Text(
            "Gold Ingots:",
            clay.TextConfig(clay.TextElementConfig{
                fontSize = 16,
                textColor = clay.Color{255, 255, 255, 255},
            }),
        )

        clay.TextDynamic(
            gold_text,
            clay.TextConfig(clay.TextElementConfig{
                fontSize = 16,
                textColor = clay.Color{255, 215, 0, 255},
            }),
        )
    }
}