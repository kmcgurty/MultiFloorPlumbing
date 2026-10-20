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

function ISMoveableSpriteProps:canPickUpMoveableInternal(character, square, object, isMulti)
	local result = MultiFloorPlumbing.ISMoveableSpriteProps_canPickUpMoveableInternal(
		self, character, square, object, isMulti
	)
	if self.isWaterCollector and object and object:getUsesExternalWaterSource() then
		return true
	end
	return result
end

---@param spriteManager IsoSpriteManager
local function OnLoadedTileDefinitions(spriteManager)
	local spriteIds = {
		"carpentry_02_54",  -- RainCollector
		"carpentry_02_122", -- RainCollectorRound
		"carpentry_02_120", -- RainCollector_Tarp
		"carpentry_02_124"  -- RainCollectorRound_Tarp
	}

	-- Set waterPiped on sprites that normally don't have it (RainCollector)
	for _, spriteId in ipairs(spriteIds) do
		local sprite = spriteManager:getSprite(spriteId)
		local props = sprite:getProperties()
		props:set(IsoFlagType.waterPiped)
	end
end

Events.OnLoadedTileDefinitions.Add(OnLoadedTileDefinitions)

log("Mod loaded.")
