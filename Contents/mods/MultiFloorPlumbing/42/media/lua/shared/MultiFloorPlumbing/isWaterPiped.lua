local log = require("MultiFloorPlumbing/log")

--- Returns true if the object's sprite has the waterPiped property.
--- waterPiped is used to indicate if the player can plumb that object
---@param object IsoObject
---@return boolean
local function isWaterPiped(object)
	local sprite = object:getSprite()
	if sprite == nil then return false end
	local props = sprite:getProperties()
	return props:has(IsoFlagType.waterPiped)
end

return isWaterPiped
