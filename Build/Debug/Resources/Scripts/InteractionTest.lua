
-- Gameplay script for player interaction (click)

---@type EngineScriptModule --- for lsp comments
local M = {}

-- function M.OnStart(_entity) #Testing
--     print("Entity Start")
-- end 
function M.OnInteract(_entity, _interactor)
    print("Interaction occured between: ", _entity," and ", _interactor)
end

return M