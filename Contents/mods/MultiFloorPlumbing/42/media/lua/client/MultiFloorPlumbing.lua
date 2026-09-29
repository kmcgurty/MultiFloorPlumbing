require "TimedActions/ISPlumbItem"
local findExternalWaterSource = require("MultiFloorPlumbing/findExternalWaterSource")
local each = require("MultiFloorPlumbing/each")
local log = require("MultiFloorPlumbing/log")

MultiFloorPlumbing = MultiFloorPlumbing
	or {
		ISWorldObjectContextMenuLogic_fetch = ISWorldObjectContextMenuLogic.fetch,
		plumbables = { "RainCollectorRound" } -- TODO: add more
	}

function ISWorldObjectContextMenuLogic.fetch(fetch, v, ...)
	local square = v:getSquare()
	if square == nil then
		return MultiFloorPlumbing.ISWorldObjectContextMenuLogic_fetch(fetch, v, ...)
	end

	---@type IsoObject[]
	local overriddenWaterSources = {}

	each(square:getObjects(), function (object)
		if object == nil then return end

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

		-- Object does not have waterPiped, so we don't process it
		if not props:has(IsoFlagType.waterPiped) then return end

		local externalSource = findExternalWaterSource(object)
		if externalSource == nil then return end
		-- If externalSource doesn't use an externalSource itself,
		-- use vanilla code path
		if not externalSource:getUsesExternalWaterSource() then return end

		-- Temporarily set usesExternalWaterSource to false
		externalSource:setUsesExternalWaterSource(false)

		if object:getUsesExternalWaterSource() then
			-- Object is currently plumbed. Cache this object's external
			-- water source in Java while we're in this temporary state.
			object:doFindExternalWaterSource()
			externalSource:setUsesExternalWaterSource(true)
		else
			-- Object is currently unplumbed, so we restore its state
			-- after calling the original fetch.
			-- This is needed for the "plumb" context option to work.
			table.insert(overriddenWaterSources, externalSource)
		end
	end)

	MultiFloorPlumbing.ISWorldObjectContextMenuLogic_fetch(fetch, v, ...)

	each(overriddenWaterSources, function (externalSource)
		externalSource:setUsesExternalWaterSource(true)
	end)
end

log("[MultiFloorPlumbing] Mod loaded.")
