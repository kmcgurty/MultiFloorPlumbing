local isWaterPiped = require("MultiFloorPlumbing/isWaterPiped")

---@param square IsoGridSquare
---@return IsoObject | nil
local function findWaterSourceOnSquare(square)
	if not square then return nil end

	local objectsOnSquare = square:getObjects()

	for i = 0, objectsOnSquare:size() - 1 do
		local object = objectsOnSquare:get(i)
		local sprite = object:getSprite()

		if not sprite or not sprite.solidfloor then
			if isWaterPiped(object) and instanceof(object, "IsoThumpable") then
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

return findExternalWaterSource
