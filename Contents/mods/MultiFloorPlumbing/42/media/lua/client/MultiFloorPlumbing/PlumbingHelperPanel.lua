require "ISUI/ISPanel"
require "MultiFloorPlumbing/initialize"

---@class PlumbingHelperPanel: ISPanel
local PlumbingHelperPanel = ISPanel:derive("PlumbingHelperPanel")

local labelHeight = 20
local buttonWidth = 75
local buttonHeight = 25
local margin = 10

function PlumbingHelperPanel:initialise()
	ISPanel.initialise(self)

	local x = margin
	local y = margin
	self.label = ISLabel:new(x, y, labelHeight, "Testing", 1, 1, 1, 1, UIFont.Small, true)
	self.label:initialise()
	self:addChild(self.label)

	local x = self.width - buttonWidth - margin
	local y = self.height - buttonHeight - margin
	self.doneButton = ISButton:new(x, y, buttonWidth, buttonHeight, "Done", self, PlumbingHelperPanel.close)
	self.doneButton:initialise()
	self:addChild(self.doneButton)
end

function PlumbingHelperPanel:prerender()
	ISPanel.prerender(self)

	local player = getPlayer()
	if not player then return end

	local square = player:getSquare()
	if not square then return end

	local x = square:getX()
	local y = square:getY()
	local z = square:getZ()

	addAreaHighlightForPlayer(player:getIndex(), x, y, x + 1, y + 1, z, 0, 1, 0, 0.4)
end

function PlumbingHelperPanel:close()
	self:removeFromUIManager()
	MultiFloorPlumbing.activePlumbingHelperPanel = nil
end

function PlumbingHelperPanel.open()
	if MultiFloorPlumbing.activePlumbingHelperPanel then
		MultiFloorPlumbing.activePlumbingHelperPanel:close()
	end

	local panel = PlumbingHelperPanel:new(100, 100, 300, 160)
	panel:initialise()
	panel:addToUIManager()

	MultiFloorPlumbing.activePlumbingHelperPanel = panel
	return panel
end

function PlumbingHelperPanel:new(x, y, width, height)
	local o = ISPanel.new(self, x, y, width, height)
	o.background = true
	o.moveWithMouse = true
	return o
end

return PlumbingHelperPanel
