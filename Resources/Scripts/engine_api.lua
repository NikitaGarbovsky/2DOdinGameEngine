---@meta

-- This file just provides lua LSP info for engine api code, autocomplete,
-- comments, function headers etc..


---Sets an entity's velocity in world space.
---@param _entity integer
---@param _x number
---@param _y number
function SetVelocity(_entity, _x, _y) end

---Requests an animation state change for an entity.
---@param _entity integer
---@param _state string
function SetAnimationClip(_entity, _state) end

---Sets the animation facing direction using a 2D direction vector.
---@param _entity integer
---@param _x number
---@param _y number
function SetAnimationDirection(_entity, _x, _y) end

---Returns horizontal movement input in the range [-1, 1].
---@return number
function GetInputMoveX() end

---Returns vertical movement input in the range [-1, 1].
---@return number
function GetInputMoveY() end