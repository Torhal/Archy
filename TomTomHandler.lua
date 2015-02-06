-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LibStub = _G.LibStub

local Archy = LibStub("AceAddon-3.0"):GetAddon("Archy")
local Dialog = LibStub("LibDialog-1.0")

-----------------------------------------------------------------------
-- Handler.
-----------------------------------------------------------------------
local TomTomHandler = {
	-----------------------------------------------------------------------
	-- Data.
	-----------------------------------------------------------------------
	hasDisplayedError = false,
	hasPOIIntegration = false,
	hasTomTom = false,
	isActive = false,
	waypoint = nil,
	-----------------------------------------------------------------------
	-- Methods.
	-----------------------------------------------------------------------
	ClearWaypoint = function(self)
		if self.waypoint then
			 _G.TomTom:RemoveWaypoint(self.waypoint)
			self.waypoint = nil
		end
	end,
	DisplayConflictError = function(self)
		if not self.hasDisplayedError then
			self.hasDisplayedError = true
			Dialog:Spawn("ArchyTomTomError")
		end
	end,
	Refresh = function(self, targetDigsite)
		if not self.hasTomTom then
			return
		end

		if not targetDigsite or not private.db.tomtom.enabled or not private.db.general.show or not self.isActive then
			self:ClearWaypoint()
			return
		end
		local digsite = targetDigsite

		local waypointExists
		if _G.TomTom.WaypointExists then
			waypointExists = _G.TomTom:WaypointExists(private.MAP_ID_TO_CONTINENT_ID[digsite.continent], digsite.zoneId, digsite.x * 100, digsite.y * 100, digsite.name .. "\n" .. digsite.zoneName)
		end

		-- Waypoint doesn't exist or we have an imperfect TomTom emulator
		if not waypointExists then
			self:ClearWaypoint()
			self.waypoint = _G.TomTom:AddMFWaypoint(digsite.map, nil, digsite.x, digsite.y, { title = digsite.name .. "\n" .. digsite.zoneName })
		end
	end
}

private.TomTomHandler = TomTomHandler

Dialog:Register("ArchyTomTomError", {
	text = "",
	on_show = function(self, data)
		self.text:SetFormattedText("%s%s|r\nIncompatible TomTom setting detected. \"%s%s|r\".\nDo you want to reset it?", "|cFFFFCC00", ADDON_NAME, "|cFFFFCC00", _G.TomTomLocals and _G.TomTomLocals["Enable automatic quest objective waypoints"] or "")
	end,
	buttons = {
		{
			text = ("%s %s"):format(_G.YES, _G.PARENS_TEMPLATE:format(_G.REQUIRES_RELOAD)),
			on_click = function(self, data)
				_G.TomTom.profile.poi.setClosest = false
				_G.TomTom:EnableDisablePOIIntegration()
				_G.ReloadUI()
			end,
		},
		{
			text = _G.NO,
		},
	},
	hide_on_escape = true,
	show_while_dead = true,
	text_justify_h = "LEFT",
	width = 350,
})

