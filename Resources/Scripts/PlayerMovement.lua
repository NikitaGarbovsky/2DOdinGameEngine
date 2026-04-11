
--- Gameplay script that runs player movement entity. 
--- Hot-Reloadable during runtime

local M = {}

local move_speed = 100.0

function M.Update(_entity, _dt)
    -- Get player input (WASD)
    local x = GetInputMoveX()
    local y = GetInputMoveY()

    -- Calculate vector length
    local len = math.sqrt(x * x + y * y)
    -- print("Len:", len)
    if len > 0 then
        -- Normalize so diagonal movement isn't faster
        x = x / len
        y = y / len
        -- print("X after: ", x)
        -- print("Y after: ", y)

        SetVelocity(_entity, x * move_speed, y * move_speed)
        SetAnimationDirection(_entity, x, y)
        SetAnimationClip(_entity, "PlayerWalk")
    else
        -- No movement input detected, set player to idle
        SetVelocity(_entity, 0, 0)
        SetAnimationClip(_entity, "PlayerIdle")
    end
end

return M