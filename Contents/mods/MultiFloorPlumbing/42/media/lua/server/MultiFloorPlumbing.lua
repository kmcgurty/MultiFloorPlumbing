require "MultiFloorPlumbing/initialize"
local log = require("MultiFloorPlumbing/log")
local overrideExternalWaterSource = require("MultiFloorPlumbing/overrideExternalWaterSource")

function ISTakeWaterAction:new(character, item, waterObject, waterTaintedCL)
	local restore = overrideExternalWaterSource(waterObject)
	if restore ~= nil then restore() end
	return MultiFloorPlumbing.ISTakeWaterAction_new(self, character, item, waterObject, waterTaintedCL)
end

function ISWashClothing:new(character, sink, item, bloodAmount, dirtAmount, noSoap)
	local restore = overrideExternalWaterSource(sink)
	if restore ~= nil then restore() end
	return MultiFloorPlumbing.ISWashClothing_new(self, character, sink, item, bloodAmount, dirtAmount, noSoap)
end

function ISWashYourself:new(character, sink)
	local restore = overrideExternalWaterSource(sink)
	if restore ~= nil then restore() end
	return MultiFloorPlumbing.ISWashYourself_new(self, character, sink)
end

function ISCleanBandage:new(character, item, waterObject, recipe)
	local restore = overrideExternalWaterSource(waterObject)
	if restore ~= nil then restore() end
	return MultiFloorPlumbing.ISCleanBandage_new(self, character, item, waterObject, recipe)
end

function ISToggleClothingWasher:complete()
	local result = MultiFloorPlumbing.ISToggleClothingWasher_complete(self)
	if self.object:isActivated() then
		local restore = overrideExternalWaterSource(self.object)
		if restore ~= nil then restore() end
	end
	return result
end

function ISToggleComboWasherDryer:complete()
	local result = MultiFloorPlumbing.ISToggleComboWasherDryer_complete(self)
	if self.object:isModeWasher() and self.object:isActivated() then
		local restore = overrideExternalWaterSource(self.object)
		if restore ~= nil then restore() end
	end
	return result
end

log("Mod loaded.")
