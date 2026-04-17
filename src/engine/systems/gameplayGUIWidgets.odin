package systems

import "../input"
import "../renderdata"
import gui "../gameplayGUI"
import clay "Dependencies:clay/clay-odin"

///
/// This file contains the immediate mode decleration for gameplaygui widgets.
/// Each procedure represents a sigle widget which is displayed based on gameplay 
/// conditions.
///

// #TODO: restructure this when finishing building more gameplay hud
// Builds all the immediate mode gameplay gui per frame
BuildGameplayGUI :: proc(_ui : ^gui.Clay_UI,
    _interaction : ^Interaction_State,
    _input : ^input.InputState,
    _camera : ^renderdata.Camera2D,
    _screen_size : [2]f32,
) -> clay.ClayArray(clay.RenderCommand)
{
    return BuildHoverTooltip(
    _ui,
    _interaction,
    _input,
    _camera,
    _screen_size)
}

// Builds the HoverTooltip layout and creates a render command for it per frame.
BuildHoverTooltip :: proc(
    _ui : ^gui.Clay_UI,
    _interaction : ^Interaction_State,
    _input : ^input.InputState,
    _camera : ^renderdata.Camera2D,
    _screen_size : [2]f32,
) -> clay.ClayArray(clay.RenderCommand) {
    clay.SetCurrentContext(_ui.clay_ctx)
    clay.SetLayoutDimensions(clay.Dimensions{
        _screen_size.x,
        _screen_size.y,
    })

    clay.SetPointerState(
        clay.Vector2{
            _input.mouse_x,
            _input.mouse_y,
        },
        _input.left_down,
    )

    clay.UpdateScrollContainers(
        false,
        clay.Vector2{0, 0},
        0,
    )

    clay.BeginLayout()

    // The main full screen space hud #TODO: move this out of this hudtool tip
    if clay.UI()(clay.ElementDeclaration{
        id = clay.ID("GameplayHudRoot"),
        layout = clay.LayoutConfig{
            sizing = clay.Sizing{
                width = clay.SizingGrow({0, 0}),
                height = clay.SizingGrow({0, 0}),
            },
        },
    }) {
        if _interaction.has_hovered {
            screen_pos := renderdata.WorldToScreenPos(
                _camera,
                _screen_size,
                _interaction.hovered_world_pos,
            )

            tooltip_x := screen_pos.x - 40
            tooltip_y := screen_pos.y - 48

            // Interactable OnHover tooltip element
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
                clay.TextDynamic( // Interactable Item Name
                    _interaction.hovered_text,
                    clay.TextConfig(clay.TextElementConfig{
                        fontSize = 14,
                        textColor = clay.Color{255, 255, 255, 255},
                        textAlignment = .Center
                    }),
                )

                if _interaction.can_interact { // Interaction popup
                    clay.Text( 
                        "Interact",
                        clay.TextConfig(clay.TextElementConfig{
                            fontSize = 14,
                            textColor = clay.Color{0, 139, 41, 255},
                            textAlignment = .Center // #TODO: this doesn't work
                        }),
                    )
                }
            }
        }
    }

    return clay.EndLayout()
}