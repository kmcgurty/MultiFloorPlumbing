local log = require("MultiFloorPlumbing/log")
local isWaterPiped = require("MultiFloorPlumbing/isWaterPiped")
local findExternalWaterSource = require("MultiFloorPlumbing/findExternalWaterSource")

-- Returned function will restore the state of the external source
---@param object    IsoObject
---@param iteration number?
---@return fun() | nil
local function overrideExternalWaterSource(object, iteration)
	if object == nil then return end
	if iteration == nil then iteration = 0 end

	if not isWaterPiped(object) then return end

	log(iteration, "Searching", object, " for an external source")

	local externalSource = findExternalWaterSource(object)
	if externalSource == nil then
		log(iteration, "Unable to find a valid external water source")
		return
	end

	log(iteration, "Found an external source. ", externalSource)

	local externalUsesExternal = externalSource:getUsesExternalWaterSource()
	---@type function?
	local externalRestore = nil

	if externalUsesExternal then
		log(iteration, "External source uses an external source. Iterating...")
		externalRestore = overrideExternalWaterSource(externalSource, iteration + 1)
	else
		log(iteration, "External source does not use an external source")
		return
	end

	log(iteration, "Overriding external water source state", externalSource)
	externalSource:setUsesExternalWaterSource(false)

	if object:getUsesExternalWaterSource() then
		-- Object is currently plumbed. Cache this object's external
		-- water source in Java while we're in this temporary state.
		log(iteration, "Caching external source for object ", object)
		object:doFindExternalWaterSource()
	end

	return function ()
		log(iteration, "Restoring external water source state", externalSource)
		externalSource:setUsesExternalWaterSource(externalUsesExternal)
		if externalRestore then externalRestore() end
	end
end

return overrideExternalWaterSource
