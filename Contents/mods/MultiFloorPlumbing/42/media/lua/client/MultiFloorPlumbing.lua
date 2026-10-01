require "MultiFloorPlumbing/initialize"
local log = require("MultiFloorPlumbing/log")
local each = require("MultiFloorPlumbing/each")
local overrideExternalWaterSource = require("MultiFloorPlumbing/overrideExternalWaterSource")

-- Overriding fetch on the client is required for plumbing
function ISWorldObjectContextMenuLogic.fetch(fetch, v, ...)
	local square = v:getSquare()
	if square == nil then
		return MultiFloorPlumbing.ISWorldObjectContextMenuLogic_fetch(fetch, v, ...)
	end

	---@type function[]
	local restores = {}

	each(square:getObjects(), function (object)
		local restore = overrideExternalWaterSource(object)
		if restore == nil then return end

		if object:getUsesExternalWaterSource() then
			-- Object is plumbed, so we can restore the external source state
			-- immediately
			restore()
		else
			-- Object is unplumbed, so we restore the external source state
			-- after calling the original fetch.
			-- This is needed for the "plumb" context option to work.
			table.insert(restores, restore)
		end
	end)

	MultiFloorPlumbing.ISWorldObjectContextMenuLogic_fetch(fetch, v, ...)

	each(restores, function (restore)
		restore()
	end)
end

function ISMoveableSpriteProps:getInfoPanelFlagsPerTile(square, object, player, mode)
	local result = MultiFloorPlumbing.ISMoveableSpriteProps_getInfoPanelFlagsPerTile(self, square, object, player, mode)
	if mode == "pickup" and self.isWaterCollector and object:getUsesExternalWaterSource() then
		InfoPanelFlags.hasWater = false
	end
	return result
end

function ISMoveableSpriteProps:canPickUpMoveableInternal(character, square, object, isMulti)
	local result = MultiFloorPlumbing.ISMoveableSpriteProps_canPickUpMoveableInternal(
		self, character, square, object, isMulti
	)
	if object and self.isWaterCollector and object:getUsesExternalWaterSource() then
		return true
	end
	return result
end

log("Mod loaded.")
