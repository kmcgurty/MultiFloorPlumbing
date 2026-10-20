require "ISUI/ISPanel"
require "MultiFloorPlumbing/initialize"
local log = require("MultiFloorPlumbing/log")
local isWaterPiped = require("MultiFloorPlumbing/isWaterPiped")
local findExternalWaterSource = require("MultiFloorPlumbing/findExternalWaterSource")

---@enum SquareStatus
local SquareStatus = {
	NO_OBJECTS = "NO_OBJECTS",
	NO_FLOOR = "NO_FLOOR",
	INVALID_OBJECT = "INVALID_OBJECT",
	UNPLUMBED = "UNPLUMBED",
	UNPLUMBED_NO_SOURCE = "UNPLUMBED_NO_SOURCE",
	VALID_SOURCE = "VALID_SOURCE",
	PLUMBED = "PLUMBED"
}

-- RGBA 0-1
local ColorMap = {
	[SquareStatus.NO_FLOOR] = { 0.5, 0.5, 0.5, 0.1 },
	[SquareStatus.INVALID_OBJECT] = { 0.84, 0.37, 0, 0.1 },
	[SquareStatus.UNPLUMBED] = { 0.8, 0.47, 0.65, 0.1 },
	[SquareStatus.UNPLUMBED_NO_SOURCE] = { 0.95, 0.85, 0.2, 0.1 },
	[SquareStatus.VALID_SOURCE] = { 0, 0.45, 0.7, 0.1 },
	[SquareStatus.PLUMBED] = { 0, 0.62, 0.45, 0.1 }
}

local StatusLegend = {
	{ status = SquareStatus.INVALID_OBJECT, desc = "Item on tile cannot be used for plumbing" },
	{ status = SquareStatus.UNPLUMBED, desc = "Item needs to be plumbed (right click > plumb)" },
	{ status = SquareStatus.UNPLUMBED_NO_SOURCE, desc = "Item cannot be plumbed, as there are no valid sources above" },
	{ status = SquareStatus.VALID_SOURCE, desc = "Item can be plumbed from underneath" },
	{ status = SquareStatus.PLUMBED, desc = "Item is correctly plumbed" }
}

-- RGBA 0-1
local AreaColor = { 0.70, 0.65, 0.85, 0.01 }

---@class PlumbingSquare
---@field x      integer
---@field y      integer
---@field z      integer
---@field status SquareStatus

---@class RenderData
---@field squares    PlumbingSquare[]
---@field z          integer
---@field lastUpdate integer

---@class PlumbingHelperPanel: ISPanel
---@field renderData RenderData
local PlumbingHelperPanel = ISPanel:derive("PlumbingHelperPanel")

local PanelWidth = 500
local PanelHeight = 220

local ButtonWidth = 75
local ButtonHeight = 25

local Margin = 10

local SmallLineHeight = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()

function PlumbingHelperPanel:initialise()
	ISPanel.initialise(self)

	local x = self.width - ButtonWidth - Margin
	local y = self.height - ButtonHeight - Margin
	self.doneButton = ISButton:new(x, y, ButtonWidth, ButtonHeight, "Done", self, PlumbingHelperPanel.close)
	self.doneButton:initialise()
	self:addChild(self.doneButton)
end

---@param x integer
---@param y integer
---@param z integer
---@return SquareStatus
function PlumbingHelperPanel:getSquareState(x, y, z)
	local square = self.cell:getGridSquare(x, y, z)

	if not square or not square:getFloor() then
		return SquareStatus.NO_FLOOR
	end

	---@type IsoObject?
	local validObject = nil
	local objectsOnSquare = square:getObjects()
	for i = 0, objectsOnSquare:size() - 1 do
		local object = objectsOnSquare:get(i)

		if isWaterPiped(object) then
			if object:getUsesExternalWaterSource() then
				return SquareStatus.PLUMBED
			elseif instanceof(object, "IsoThumpable") and not square:isInARoom() then
				if object:getFluidContainer():getAmount() > 0 then
					return SquareStatus.VALID_SOURCE
				else
					-- TODO: indicate when there is no water?
					return SquareStatus.VALID_SOURCE
				end
			end

			if findExternalWaterSource(object) then
				return SquareStatus.UNPLUMBED
			else
				return SquareStatus.UNPLUMBED_NO_SOURCE
			end
		end
	end

	if square:has("BlocksPlacement") then
		return SquareStatus.INVALID_OBJECT
	end

	return SquareStatus.NO_OBJECTS
end

function PlumbingHelperPanel:updateRenderData()
	---@type PlumbingSquare[]
	local squares = {}
	local playerZ = math.floor(self.player:getZ())

	for dy = -1, 1 do
		for dx = -1, 1 do
			local x = self.originX + dx
			local y = self.originY + dy
			local state = PlumbingHelperPanel:getSquareState(x, y, playerZ)
			squares[#squares + 1] = { x = x, y = y, z = playerZ, status = state }
		end
	end

	self.renderData.z = playerZ
	self.renderData.squares = squares
	self.renderData.lastUpdate = getTimestampMs()
end

function PlumbingHelperPanel:render()
	ISPanel.render(self)

	self:drawTextCentre("Plumbing Helper", self.width / 2, 10, 1, 1, 1, 1, UIFont.Medium)

	local x = 10
	local y = 45
	self:drawText("Legend:", x, y, 1, 1, 1, 1, UIFont.Small)
	y = y + SmallLineHeight

	self:drawRect(x, y + 3, 10, 10, 1, AreaColor[1], AreaColor[2], AreaColor[3])
	local areaText = "3x3 area that can be used for plumbing"
	self:drawText(areaText, x + 16, y, 1, 1, 1, 1, UIFont.Small)
	y = y + SmallLineHeight

	for _, line in ipairs(StatusLegend) do
		local color = ColorMap[line.status]
		if color ~= nil then
			self:drawRect(x, y + 3, 10, 10, 1, color[1], color[2], color[3])
			self:drawText(line.desc, x + 16, y, 1, 1, 1, 1, UIFont.Small)
			y = y + SmallLineHeight
		end
	end
end

function PlumbingHelperPanel:prerender()
	ISPanel.prerender(self)

	-- UI
	self:drawRect(
		0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g,
		self.backgroundColor.b
	)
	self:drawRectBorder(
		0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b
	)

	-- Square highlights
	local now = getTimestampMs()
	if now - self.renderData.lastUpdate >= 250 then
		self:updateRenderData()
	end

	local playerZ = math.floor(self.player:getZ())
	if playerZ ~= self.renderData.z then return end

	local x = self.originX
	local y = self.originY

	-- 3x3 area
	addAreaHighlightForPlayer(
		self.playerId, x - 1, y - 1, x + 2, y + 2, playerZ, AreaColor[1], AreaColor[2], AreaColor[3], AreaColor[4]
	)

	for i, square in pairs(self.renderData.squares) do
		if ColorMap[square.status] ~= nil then
			local x = square.x
			local y = square.y
			local z = square.z
			local r = ColorMap[square.status][1]
			local g = ColorMap[square.status][2]
			local b = ColorMap[square.status][3]
			local a = ColorMap[square.status][4]
			addAreaHighlightForPlayer(self.playerId, x, y, x + 1, y + 1, z, r, g, b, a)
		end
	end
end

function PlumbingHelperPanel:close()
	self:removeFromUIManager()
	MultiFloorPlumbing.activePlumbingHelperPanel = nil
end

---@param playerId     integer
---@param originSquare IsoGridSquare
---@return PlumbingHelperPanel
function PlumbingHelperPanel:new(x, y, width, height, playerId, originSquare)
	self.cell = getCell()

	self.renderData = { z = 0, squares = {}, lastUpdate = -1 }
	self.playerId = playerId
	self.player = getSpecificPlayer(playerId)

	self.originX = originSquare:getX()
	self.originY = originSquare:getY()
	self.originZ = originSquare:getZ()

	local o = ISPanel.new(self, x, y, width, height)
	o.background = true
	o.moveWithMouse = true
	return o
end

---@param playerId integer
---@param object   IsoObject
function PlumbingHelperPanel.open(playerId, object)
	if MultiFloorPlumbing.activePlumbingHelperPanel ~= nil then
		---@diagnostic disable-next-line: undefined-field
		MultiFloorPlumbing.activePlumbingHelperPanel:close()
	end

	local originSquare = object:getSquare()
	local panel = PlumbingHelperPanel:new(100, 100, PanelWidth, PanelHeight, playerId, originSquare)
	panel:initialise()
	panel:addToUIManager()
	panel:updateRenderData()

	MultiFloorPlumbing.activePlumbingHelperPanel = panel
	return panel
end

return PlumbingHelperPanel
