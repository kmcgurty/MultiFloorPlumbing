local log = require("MultiFloorPlumbing/log")

local plumbables = { "RainCollector", "RainCollector_Tarp", "RainCollectorRound", "RainCollectorRound_Tarp" }

--- Returns true if the object's sprite has the waterPiped property.
--- waterPiped is used to indicate if the player can plumb that object
---@return boolean
local function isWaterPiped(object)
	local sprite = object:getSprite()
	if sprite == nil then return false end

	local props = sprite:getProperties()
	local objectName = object:getName()

	-- Set waterPiped on sprites that normally don't have it (RainCollector)
	if not props:has(IsoFlagType.waterPiped) then
		for _, plumbableName in ipairs(plumbables) do
			if objectName == plumbableName then
				log("Marking", objectName, "as plumbable")
				props:set(IsoFlagType.waterPiped)
				return true
			end
		end
	end

	return props:has(IsoFlagType.waterPiped)
end

return isWaterPiped
