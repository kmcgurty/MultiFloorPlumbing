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
					---@diagnostic disable-next-line: undefined-field
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

return findExternalWaterSource
