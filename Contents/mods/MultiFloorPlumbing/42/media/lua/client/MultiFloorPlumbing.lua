require "MultiFloorPlumbing/initialize"
local log = require("MultiFloorPlumbing/log")
local updateFluidMenu = require("MultiFloorPlumbing/updateFluidMenu")
local each = require("MultiFloorPlumbing/each")
local isWaterPiped = require("MultiFloorPlumbing/isWaterPiped")
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

---@param playerId     integer
---@param menu         ISContextMenu
---@param worldObjects IsoObject[]
---@param test         boolean
local function OnFillWorldObjectContextMenu(playerId, menu, worldObjects, test)
	if not worldObjects or (#worldObjects < 1) then
		return
	end

	-- https://pzwiki.net/wiki/OnFillWorldObjectContextMenu
	-- TODO: change this so it uses worldObjects directly
	-- Will likely need to deduplicate it first
	local firstObject = worldObjects[1]
	if not firstObject then return end

	local square = firstObject:getSquare()
	if not square then return end

	each(square:getObjects(), function (object)
		if not isWaterPiped(object) then return end
		updateFluidMenu(menu, object)
	end)
end

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)

log("Mod loaded.")
