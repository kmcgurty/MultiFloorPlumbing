require "Moveables/ISMoveableSpriteProps"
require "TimedActions/ISTakeWaterAction"
require "TimedActions/ISWashClothing"
require "TimedActions/ISWashYourself"
require "TimedActions/ISCleanBandage"
require "TimedActions/ISToggleClothingWasher"
require "TimedActions/ISToggleComboWasherDryer"

MultiFloorPlumbing = MultiFloorPlumbing
	or {
		plumbables = {
			"RainCollector",
			"RainCollector_Tarp",
			"RainCollectorRound",
			"RainCollectorRound_Tarp"
		},
		ISWorldObjectContextMenuLogic_fetch = ISWorldObjectContextMenuLogic.fetch,
		ISMoveableSpriteProps_getInfoPanelFlagsPerTile = ISMoveableSpriteProps.getInfoPanelFlagsPerTile,
		ISMoveableSpriteProps_canPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal,
		ISTakeWaterAction_new = ISTakeWaterAction.new,
		ISWashClothing_new = ISWashClothing.new,
		ISWashYourself_new = ISWashYourself.new,
		ISCleanBandage_new = ISCleanBandage.new,
		ISToggleClothingWasher_complete = ISToggleClothingWasher.complete,
		ISToggleComboWasherDryer_complete = ISToggleComboWasherDryer.complete
	}
