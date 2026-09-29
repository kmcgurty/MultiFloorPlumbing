require "MultiFloorPlumbing/initialize"
local overrideExternalWaterSource = require("MultiFloorPlumbing/overrideExternalWaterSource")
local log = require("MultiFloorPlumbing/log")

-- Overriding fetch on the client is required for plumbing
function ISWorldObjectContextMenuLogic.fetch(fetch, v, ...)
	local square = v:getSquare()
	if square == nil then
		return MultiFloorPlumbing.ISWorldObjectContextMenuLogic_fetch(fetch, v, ...)
	end

	---@type function[]
	local restores = {}

	local objects = square:getObjects()
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)

		local restore = overrideExternalWaterSource(object)
		if restore ~= nil then
			if object:getUsesExternalWaterSource() then
				-- Object is plumbed, so we can restore it immediately
				restore()
			else
				-- Object is unplumbed, so we restore its state
				-- after calling the original fetch.
				-- This is needed for the "plumb" context option to work.
				table.insert(restores, restore)
			end
		end
	end

	MultiFloorPlumbing.ISWorldObjectContextMenuLogic_fetch(fetch, v, ...)

	for _, restore in ipairs(restores) do
		restore()
	end
end

log("Mod loaded.")
