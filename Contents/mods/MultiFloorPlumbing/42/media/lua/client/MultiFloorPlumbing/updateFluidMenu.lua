local log = require("MultiFloorPlumbing/log")
local PlumbingHelperPanel = require("MultiFloorPlumbing/PlumbingHelperPanel")

---@type PlumbingHelperPanel?
MultiFloorPlumbing.activePlumbingHelperPanel = nil

---@param menu   ISContextMenu
---@param object IsoObject
local function removePlumbOption(menu, object)
	local objectName = Translator.getMoveableDisplayName(object)
	if objectName == nil then return nil end

	local plumbText = Translator.getText("ContextMenu_PlumbItem", objectName)
	local option = menu:getOptionFromName(plumbText)
	if option == nil then return nil end

	local removedOption = {
		onSelect = option.onSelect,
		notAvailable = option.notAvailable,
		tooltip = option.toolTip,
		target = option.target,
		param1 = option.param1,
		param2 = option.param2,
		param3 = option.param3,
		param4 = option.param4
	}
	menu:removeOptionByName(plumbText)
	return removedOption
end

---@param menu ISContextMenu
local function removeContainerInfoOption(menu)
	local containerInfoText = Translator.getText("Fluid_Show_Info")
	local option = menu:getOptionFromName(containerInfoText)
	if not option then return nil end

	local removedOption = { onSelect = option.onSelect, target = option.target, param1 = option.param1 }
	menu:removeOptionByName(containerInfoText)
	return removedOption
end

---@param menu   ISContextMenu
---@param object IsoObject
local function updateFluidMenu(menu, object)
	local root = getPlayerContextMenu(menu.player)
	if not root or not root.instanceMap then return end

	local objectName = Translator.getMoveableDisplayName(object)
	local parentOption = menu:getOptionFromName(objectName)

	-- Create item option for sinks and containers that don't already have it
	if not parentOption then
		parentOption = menu:insertOptionBefore(getText("ContextMenu_Disassemble"), objectName)
		if not parentOption then return end

		local texture = getTexture(object:getSpriteName())
		if texture ~= nil then
			parentOption.iconTexture = texture:splitIcon()
		end
	end

	---@type ISContextMenu | nil
	local subMenu = nil
	if parentOption.subOption then
		subMenu = root.instanceMap[parentOption.subOption]
	end

	if not subMenu then
		subMenu = menu:getNew(menu)
		menu:addSubMenu(parentOption, subMenu)
	end

	-- Plumbing helper button when a wrench is equipped
	local player = getSpecificPlayer(menu.player)
	local inventory = player:getInventory()
	local wrenchInInventory = inventory:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, function (item)
		return not item:isBroken()
	end)

	if wrenchInInventory ~= nil or MultiFloorPlumbing.activePlumbingHelperPanel ~= nil then
		local plumbingHelperOption = subMenu:addOptionOnTop(
			"Open plumbing helper", menu.player, PlumbingHelperPanel.open, object
		)
		plumbingHelperOption.iconTexture = getTexture("media/ui/emotes/back_green.png")
		plumbingHelperOption.isDisabled = (MultiFloorPlumbing.activePlumbingHelperPanel ~= nil)
	end

	-- Move plumb to submenu
	local plumbText = getText("ContextMenu_PlumbItem", "")
	local removedPlumbOption = removePlumbOption(menu, object)
	if removedPlumbOption then
		local plumbOption = subMenu:addOptionOnTop(plumbText)
		plumbOption.target = removedPlumbOption.target
		plumbOption.onSelect = removedPlumbOption.onSelect
		plumbOption.param1 = removedPlumbOption.param1
		plumbOption.param2 = removedPlumbOption.param2
		plumbOption.param3 = removedPlumbOption.param3
		plumbOption.param4 = removedPlumbOption.param4
		plumbOption.iconTexture = Texture.getSharedTexture("Item_PipeWrench")
		plumbOption.notAvailable = removedPlumbOption.notAvailable
		plumbOption.toolTip = removedPlumbOption.tooltip
	end

	-- Info tooltip
	local infoTooltip = ISWorldObjectContextMenu.addToolTip()
	infoTooltip:setName(objectName .. " " .. getText("ContextMenu_Info"))

	-- TODO: inform player to equip a pipe wrench to view the plumbing helper
	infoTooltip.description = "WIP"

	if not wrenchInInventory then
		infoTooltip.description = infoTooltip.description .. "<LINE>Equip a pipe wrench to access the Plumbing Helper"
	end

	-- Move the container info to the top, and attach the tooltip
	local infoOption
	if #subMenu.options >= 1 then
		-- Add on top fails when menu is empty
		infoOption = subMenu:addOptionOnTop(getText("ContextMenu_Info"))
	else
		infoOption = subMenu:addOption(getText("ContextMenu_Info"))
	end

	infoOption.isDisabled = true
	infoOption.toolTip = infoTooltip

	local removedInfoOption = removeContainerInfoOption(subMenu)
	if removedInfoOption then
		infoOption.isDisabled = false
		infoOption.target = removedInfoOption.target
		infoOption.param1 = removedInfoOption.param1
		infoOption.onSelect = removedInfoOption.onSelect
	end
end

return updateFluidMenu
