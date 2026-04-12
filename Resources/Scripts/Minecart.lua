
--- This just manages the basic minecart entity interactable.
--- Takes the gold from the interactable and put it in the minecart

---@type EngineScriptModule
local M = {}

local amount = 1

function M.OnInteract(_entity, _interactor)
   local removed = TryRemoveGold(_interactor, amount)
   if not removed then
        print("Failed to remove", amount, "gold")
        return 
   else 
        print("Removed", amount, "gold")
   end

   local added = AddGold(_entity, amount)
   if added <= 0 then
        AddGold(_interactor, amount)
        return
   end

   local current = GetGold(_entity)
   if current >= 10 then
        print("Minecart Full")
        --- #TODO: Trigger minecart go
   end
end

return M