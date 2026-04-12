
---@type EngineScriptModule --- for lsp comments
local M = {}

function M.OnInteract(_thisEntity, _interactor)
    AddGold(_interactor, 1)
    DestroyEntity(_thisEntity)
end

return M