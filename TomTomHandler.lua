-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LibStub = _G.LibStub

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
	Refresh = function(self, digsite)
		if not self.hasTomTom then
			return
		end

		if not digsite or not private.db.tomtom.enabled or not private.db.general.show or not self.isActive then
			self:ClearWaypoint()
			return
		end

		local waypointExists
		if _G.TomTom.WaypointExists then
			waypointExists = _G.TomTom:WaypointExists(private.MAP_ID_TO_CONTINENT_ID[digsite.continentID], digsite.zoneID, digsite.coordX * 100, digsite.coordY * 100, digsite.name .. "\n" .. digsite.zoneName)
		end

		-- Waypoint doesn't exist or we have an imperfect TomTom emulator
		if not waypointExists then
			self:ClearWaypoint()

			local waypointData = {
				crazy = private.db.tomtom.crazyArrowEnabled,
				title = ("%s %s\n%s"):format(digsite.name, _G.PARENS_TEMPLATE:format(digsite.race.name), digsite.zoneName),
			}

			self.waypoint = _G.TomTom:AddMFWaypoint(digsite.mapID, nil, digsite.coordX, digsite.coordY, waypointData)
		end
	end
}

private.TomTomHandler = TomTomHandler

Dialog:Register("ArchyTomTomError", {
	text = "",
	on_show = function(self, data)
		self.text:SetFormattedText("An incompatible TomTom setting was detected.\n\nThe \"%s%s|r\" setting will cause %s to lose control of TomTom when approaching quest POIs.\n\nDo you want to reset it?",
			"|cFFFFCC00", _G.TomTomLocals and _G.TomTomLocals["Enable automatic quest objective waypoints"] or "", ADDON_NAME)
	end,
	buttons = {
		{
			text = _G.YES,
			on_click = function(self, data)
				_G.TomTom.profile.poi.setClosest = false
				_G.TomTom:EnableDisablePOIIntegration()
			end,
		},
		{
			text = _G.NO,
		},
	},
	hide_on_escape = true,
	show_while_dead = true,
	width = 450,
})
