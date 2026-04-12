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

---Flag this entity for destruction
---@param _entity integer
function DestroyEntity(_entity) end

---Give this entity this much gold.
---@param _entity integer
---@param _amount integer
function AddGold(_entity, _amount) end

---Attempt to take gold from the interactors inventory component 
---@param _interactor integer
---@param _amount integer
function TryRemoveGold(_interactor, _amount) end

---Returns the current gold count within the given entity's inventory component.
---@param _entity integer
---@return integer
function GetGold(_entity) end

-- Main api callbacks
---@class EngineScriptModule
local M = {}

---Runs once when the entity is created.
---@param _entity integer
function M.OnStart(_entity) end

---Runs as fast as it can every update loop of the main application
---After input, before physics & animation updates
---@param _entity integer
---@param _dt number
function M.OnUpdate(_entity, _dt) end

---Called when an entity is flagged for destruction
function M.OnDestroy() end

---Is called when an entity is interacted with. (Physics point to collider)
---@param _entity integer
---@param _interactor integer
function M.OnInteract(_entity, _interactor) end



return M