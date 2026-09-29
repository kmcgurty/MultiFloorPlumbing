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

log("Mod loaded.")
