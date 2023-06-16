---
--- Created by Max
--- DateTime: 16/06/2023 21:16
---

---@class MapContextControl
MapContextControl = {}

-- Mod info
MapContextControl.modName = "MapContextControl"
MapContextControl.modVersion = "1.0.0"
MapContextControl.modAuthor = "Max"
MapContextControl.modDescription = "Allows you to control which access levels can use which map contexts."


---@class AccessLevelEnum
---Enums representing different access levels.
---admin, moderator, overseer, gm, observer, none
AccessLevelEnum = {
	none = 1,
	observer = 2,
	gm = 3,
	overseer = 4,
	moderator = 5,
	admin = 6
}

---@return number
---@param access_level string
local function stringToEnumVal(access_level)
	for i, v in pairs(AccessLevelEnum) do
		if i == access_level:lower() then
			return v
		end
	end
	-- Default to none
	return 1
end

---@return boolean
---@param sandbox_value number
local function hasAccess(sandbox_value)
	local access_level = getAccessLevel()
	if access_level == "admin" then
		return true
	end
	local required_access = sandbox_value
	if required_access == nil then
		return false
	end
	-- Convert the access level to a number using the enum
	access_level_val = stringToEnumVal(access_level)
	-- Check if the player has the required access level or higher
	if access_level_val >= required_access then
		return true
	end
	return false
end

---Taken & modified from ISWorldMap.lua
function ISWorldMap:onRightMouseUp(x, y)
	if self.symbolsUI:onRightMouseUpMap(x, y) then
		return true
	end
	if not getDebug() and not isClient() then
		return false
	end

	local playerNum = 0
	local playerObj = getSpecificPlayer(0)
	if not playerObj then return end -- Debug in main menu
	local context = ISContextMenu.get(playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())

	local option

	if hasAccess(SandboxVars.MapContextControl.ShowCellGrid) then
		option = context:addOption(getText("UI_MapContextControl_ShowCellGrid"), self, function(self) self:setShowCellGrid(not self.showCellGrid) end)
		context:setOptionChecked(option, self.showCellGrid)
	end

	if hasAccess(SandboxVars.MapContextControl.ShowTileGrid) then
		option = context:addOption(getText("UI_MapContextControl_ShowTileGrid"), self, function(self) self:setShowTileGrid(not self.showTileGrid) end)
		context:setOptionChecked(option, self.showTileGrid)
	end

	if hasAccess(SandboxVars.MapContextControl.HideUnvisitedAreas) then
		self.hideUnvisitedAreas = self.mapAPI:getBoolean("HideUnvisited")
		option = context:addOption(getText("UI_MapContextControl_HideUnvisitedAreas"), self, function(self) self:setHideUnvisitedAreas(not self.hideUnvisitedAreas) end)
		context:setOptionChecked(option, self.hideUnvisitedAreas)
	end

	if hasAccess(SandboxVars.MapContextControl.Isometric) then
		option = context:addOption(getText("UI_MapContextControl_Isometric"), self, function(self) self:setIsometric(not self.isometric) end)
		context:setOptionChecked(option, self.isometric)
	end

	if hasAccess(SandboxVars.MapContextControl.ReapplyStyle) then
		-- DEV: Apply the style again after reloading ISMapDefinitions.lua
		option = context:addOption(getText("UI_MapContextControl_ReapplyStyle"), self,
				function(self)
					MapUtils.initDefaultStyleV1(self)
					MapUtils.overlayPaper(self)
				end)
	end

	if hasAccess(SandboxVars.MapContextControl.TeleportHere) then
		local worldX = self.mapAPI:uiToWorldX(x, y)
		local worldY = self.mapAPI:uiToWorldY(x, y)
		if getWorld():getMetaGrid():isValidChunk(worldX / 10, worldY / 10) then
			option = context:addOption(getText("UI_MapContextControl_TeleportHere"), self, self.onTeleport, worldX, worldY)
		end
	end

	return true
end

---Taken & modified from ISMiniMapInner.lua
function ISMiniMapInner:onRightMouseUp(x, y)
	if not self.rightMouseDown then return end
	self.rightMouseDown = false

	if not hasAccess(SandboxVars.MapContextControl.TeleportHere) then
		return
	end

	local playerNum = 0
	local playerObj = getSpecificPlayer(0)
	if not playerObj then return end
	local context = ISContextMenu.get(playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())

	local worldX = self.mapAPI:uiToWorldX(x, y)
	local worldY = self.mapAPI:uiToWorldY(x, y)
	if getDebug() and getWorld():getMetaGrid():isValidChunk(worldX / 10, worldY / 10) then
		option = context:addOption(getText("UI_MapContextControl_TeleportHere"), self, self.onTeleport, worldX, worldY)
	end

	if context.numOptions == 1 then
		context:setVisible(false)
	end
end