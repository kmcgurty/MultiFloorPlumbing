local log = require("MultiFloorPlumbing/log")

-- Java algorithm ported to Lua
-- This version ignores the check for "getUsesExternalWaterSource"
---@param object IsoObject
---@return IsoObject | nil
local function findExternalWaterSource(object)
	---@param square IsoGridSquare
	---@return IsoObject | nil
	local function findWaterSourceOnSquare(square)
		if not square then return nil end

		local objectsOnSquare = square:getObjects()

		for i = 0, objectsOnSquare:size() - 1 do
			local objectOnSquare = objectsOnSquare:get(i)

			-- Note: I'm unsure if this check is actually needed. It's
			-- probably for some really weird edge case. Rain collectors
			-- aren't "thumpable" by default, so this check is removed.
			-- if instanceof(objectOnSquare, "IsoThumpable") then
			local sprite = objectOnSquare:getSprite()

			---@diagnostic disable-next-line: undefined-field
			-- Note: intentionally removes !object.getUsesExternalWaterSource()
			if (not sprite or not sprite.solidfloor) and objectOnSquare:getFluidCapacity() > 0 then
				return objectOnSquare
			end
			-- end
		end

		return nil
	end

	local square = object:getSquare()
	if not square then return nil end

	local cell = getCell()

	local x = square:getX()
	local y = square:getY()
	local z = square:getZ()

	local empty = nil

	local sourceSquare = cell:getGridSquare(x, y, z + 1)
	local source = findWaterSourceOnSquare(sourceSquare)

	if source then
		---@diagnostic disable-next-line: undefined-field
		if source:hasFluid() then
			return source
		end

		empty = source
	end

	for dy = -1, 1 do
		for dx = -1, 1 do
			if dx ~= 0 or dy ~= 0 then
				sourceSquare = cell:getGridSquare(x + dx, y + dy, z + 1)
				source = findWaterSourceOnSquare(sourceSquare)

				if source then
					if source:hasFluid() then
						return source
					end

					if not empty then
						empty = source
					end
				end
			end
		end
	end

	return empty
end

-- Returned function will restore the state of the external source
---@param object IsoObject
---@return fun() | nil
local function overrideExternalWaterSource(object)
	if object == nil then return end

	if object:getUsesExternalWaterSource() and object:hasExternalWaterSource() then
		-- Found a vanilla external water source - returning.
		return
	end

	local sprite = object:getSprite()
	if sprite == nil then return end

	local props = sprite:getProperties()
	local objectName = object:getName()

	-- Set waterPiped on sprites that normally don't have it set (RainCollector)
	if not props:has(IsoFlagType.waterPiped) then
		for _, plumbableName in ipairs(MultiFloorPlumbing.plumbables) do
			if objectName == plumbableName then
				log("Marking", objectName, "as plumbable")
				props:set(IsoFlagType.waterPiped)
				break
			end
		end
	end

	if not props:has(IsoFlagType.waterPiped) then return end

	local externalSource = findExternalWaterSource(object)
	if externalSource == nil then
		log("Unable to find a valid water source")
		return
	end

	-- If externalSource doesn't use an externalSource itself,
	-- use vanilla code path
	-- This shouldn't be possible, but just in case.
	if not externalSource:getUsesExternalWaterSource() then
		log(externalSource, "External source does not use an external source - returning.")
		return
	end

	log("Overriding external water source state", externalSource)
	externalSource:setUsesExternalWaterSource(false)

	if object:getUsesExternalWaterSource() then
		-- Object is currently plumbed. Cache this object's external
		-- water source in Java while we're in this temporary state.
		log("Caching external source for object ", object)
		object:doFindExternalWaterSource()
	end

	return function ()
		log("Restoring external water source state", externalSource)
		externalSource:setUsesExternalWaterSource(true)
	end
end

return overrideExternalWaterSource
