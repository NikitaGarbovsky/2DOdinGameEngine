
-- Gameplay script for player interaction (click)

local M = {}

function M.OnInteract(_entity, _interactor)
    print("Interaction occured between: ", _entity," and ", _interactor)
end

return M