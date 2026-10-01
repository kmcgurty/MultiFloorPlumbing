local log = require("MultiFloorPlumbing/log")
local each = require("MultiFloorPlumbing/each")

local function setWaterPiped(object)
	local sprite = object:getSprite()
	if sprite == nil then return false end

	local props = sprite:getProperties()
	local objectName = object:getName()

	-- Set waterPiped on sprites that normally don't have it set (RainCollector)
	if not props:has(IsoFlagType.waterPiped) then
		for _, plumbableName in ipairs(MultiFloorPlumbing.plumbables) do
			if objectName == plumbableName then
				log("Marking", objectName, "as plumbable")
				props:set(IsoFlagType.waterPiped)
				return true
			end
		end
	end

	return props:has(IsoFlagType.waterPiped)
end

---@param square IsoGridSquare
---@return IsoObject | nil
local function findWaterSourceOnSquare(square)
	if not square then return nil end

	local objectsOnSquare = square:getObjects()

	for i = 0, objectsOnSquare:size() - 1 do
		local object = objectsOnSquare:get(i)
		local sprite = object:getSprite()

		local isWaterPiped = setWaterPiped(object)
		---@diagnostic disable-next-line: undefined-field
		if not sprite or not sprite.solidfloor then
			if isWaterPiped then
				return object
			end
		end
	end

	return nil
end

---@param object IsoObject
---@return IsoObject | nil
local function findExternalWaterSource(object)
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
---@param object    IsoObject
---@param iteration number?
---@return fun() | nil
local function overrideExternalWaterSource(object, iteration)
	if object == nil then return end

	if iteration == nil then iteration = 0 end

	local sprite = object:getSprite()
	if sprite == nil then return end

	local isWaterPiped = setWaterPiped(object)
	if not isWaterPiped then return end

	log(iteration, "Searching", object, " for an external source")

	local externalSource = findExternalWaterSource(object)
	if externalSource == nil then
		log(iteration, "Unable to find a valid external water source")
		return
	end

	log(iteration, "Found an external source. ", externalSource)

	---@type function?
	local restore = nil

	if externalSource:getUsesExternalWaterSource() then
		log(iteration, "External source uses an external source. Iterating...")
		restore = overrideExternalWaterSource(externalSource, iteration + 1)
	else
		log(iteration, "External source does not use an external source")
		return restore
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
		externalSource:setUsesExternalWaterSource(true)
		if restore then restore() end
	end
end

return overrideExternalWaterSource
