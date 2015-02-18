-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-- Libraries
local math = _G.math
local table = _G.table
local string = _G.string

-- Functions
local date = _G.date
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local select = _G.select
local setmetatable = _G.setmetatable
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local unpack = _G.unpack

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local LibStub = _G.LibStub

local ADDON_NAME, private = ...
local Archy = LibStub("AceAddon-3.0"):NewAddon("Archy", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceBucket-3.0", "AceTimer-3.0", "LibSink-2.0", "LibToast-1.0")
Archy.version = _G.GetAddOnMetadata(ADDON_NAME, "Version")
_G["Archy"] = Archy

local Astrolabe = _G.DongleStub("Astrolabe-1.0")
local Dialog = LibStub("LibDialog-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Archy", false)
local LDBI = LibStub("LibDBIcon-1.0")
local Toast = LibStub("LibToast-1.0")

local debugger -- Only defined if needed.

local DatamineTooltip = _G.CreateFrame("GameTooltip", "ArchyScanTip", nil, "GameTooltipTemplate")
DatamineTooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")

-----------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------
local DIGSITE_TEMPLATES = private.DIGSITE_TEMPLATES
local MAX_PROFESSION_RANK = _G.GetExpansionLevel() + 4 -- Skip the 4 ranks of vanilla
local MAX_ARCHAEOLOGY_RANK = _G.PROFESSION_RANKS[MAX_PROFESSION_RANK][1]
private.MAX_ARCHAEOLOGY_RANK = MAX_ARCHAEOLOGY_RANK

local MAP_ID_TO_ZONE_ID = {} -- Popupated in Archy:OnInitialize()
local MAP_ID_TO_ZONE_NAME = {} -- Popupated in Archy:OnInitialize()

local PROFILE_DEFAULTS = {
	profile = {
		general = {
			enabled = true,
			show = true,
			stealthMode = false,
			combathide = false,
			icon = {
				hide = false
			},
			locked = false,
			confirmSolve = true,
			showSkillBar = true,
			sinkOptions = {
				sink20OutputSink = "LibToast-1.0",
			},
			easyCast = false,
			autoLoot = true,
			theme = "Graphical",
			manualTrack = false,
		},
		artifact = {
			show = true,
			position = {
				"TOPRIGHT",
				"TOPRIGHT",
				-400,
				-425
			},
			anchor = "TOPRIGHT",
			positionX = 100,
			positionY = -300,
			scale = 0.75,
			alpha = 1,
			filter = true,
			announce = true,
			keystoneAnnounce = true,
			ping = true,
			keystonePing = true,
			blacklist = {},
			autofill = {},
			style = "Compact",
			borderAlpha = 1,
			bgAlpha = 0.5,
			font = {
				name = "Friz Quadrata TT",
				size = 14,
				shadow = true,
				outline = "",
				color = {
					r = 1,
					g = 1,
					b = 1,
					a = 1
				}
			},
			fragmentFont = {
				name = "Friz Quadrata TT",
				size = 14,
				shadow = true,
				outline = "",
				color = {
					r = 1,
					g = 1,
					b = 1,
					a = 1
				}
			},
			keystoneFont = {
				name = "Friz Quadrata TT",
				size = 12,
				shadow = true,
				outline = "",
				color = {
					r = 1,
					g = 1,
					b = 1,
					a = 1
				}
			},
			fragmentBarColors = {
				["Normal"] = {
					r = 1,
					g = 0.5,
					b = 0
				},
				["Solvable"] = {
					r = 0,
					g = 1,
					b = 0
				},
				["Rare"] = {
					r = 0,
					g = 0.4,
					b = 0.8
				},
				["AttachToSolve"] = {
					r = 1,
					g = 1,
					b = 0
				},
				["FirstTime"] = {
					r = 1,
					g = 1,
					b = 1
				},
			},
			fragmentBarTexture = "Blizzard Parchment",
			borderTexture = "Blizzard Dialog Gold",
			backgroundTexture = "Blizzard Parchment",
		},
		digsite = {
			show = true,
			position = {
				"TOPRIGHT", "TOPRIGHT", -400, -200
			},
			anchor = "TOPRIGHT",
			positionX = 400,
			positionY = -300,
			scale = 0.75,
			alpha = 1,
			style = "Extended",
			sortByDistance = true,
			announceNearest = true,
			distanceIndicator = {
				enabled = true,
				green = 40,
				yellow = 80,
				position = {
					"CENTER",
					"CENTER",
					0,
					0
				},
				anchor = "TOPLEFT",
				undocked = false,
				showSurveyButton = true,
				showCrateButton = true,
				showLorItemButton = true,
				font = {
					name = "Friz Quadrata TT",
					size = 16,
					shadow = false,
					outline = "OUTLINE",
					color = {
						r = 1,
						g = 1,
						b = 1,
						a = 1
					}
				},
			},
			borderAlpha = 1,
			bgAlpha = 0.5,
			font = {
				name = "Friz Quadrata TT",
				size = 18,
				shadow = true,
				outline = "",
				color = {
					r = 1,
					g = 1,
					b = 1,
					a = 1
				}
			},
			zoneFont = {
				name = "Friz Quadrata TT",
				size = 14,
				shadow = true,
				outline = "",
				color = {
					r = 1,
					g = 0.82,
					b = 0,
					a = 1
				}
			},
			minimal = {
				showDistance = false,
				showZone = false,
				showDigCounter = true,
			},
			borderTexture = "Blizzard Dialog Gold",
			backgroundTexture = "Blizzard Parchment",
		},
		minimap = {
			show = true,
			nearest = true,
			fragmentNodes = true,
			fragmentIcon = "CyanDot",
			fragmentColorBySurveyDistance = true,
			useBlobDistance = true,
		},
		tooltip = {
			filter_continent = true,
			hideDelay = 0.1,
			scale = 1,
		},
		tomtom = {
			crazyArrowEnabled = true,
			distance = 125,
			enabled = true,
			ping = true,
		},
	},
}

local GLOBAL_COOLDOWN_TIME = 1.5
local SECURE_ACTION_BUTTON -- Populated in Archy:OnInitialize()
local SURVEY_SPELL_ID = 80451
local CRATE_USE_STRING -- Populate in Archy:OnEnable()
local DIG_LOCATION_TEXTURE_INDEX = 177

local ZONE_DATA = {}
private.ZONE_DATA = ZONE_DATA

local MAP_CONTINENTS = {} -- Popupated in Archy:OnEnable()

local LOREWALKER_ITEMS = {
	MAP = { id = 87549, spell = 126957 },
	LODESTONE = { id = 87548, spell = 126956 },
}

local FISHING_POLE_NAME
do
	--  If this stops working, check for the index of "Weapon" via GetAuctionItemClasses(), then find the index of "Fishing Poles" via GetAuctionItemSubClasses().
	local auctionItemSubClassNames = { _G.GetAuctionItemSubClasses(1) }
	FISHING_POLE_NAME = auctionItemSubClassNames[#auctionItemSubClassNames]
end

_G.BINDING_HEADER_ARCHY = "Archy"
_G.BINDING_NAME_OPTIONSARCHY = L["BINDING_NAME_OPTIONS"]
_G.BINDING_NAME_TOGGLEARCHY = L["BINDING_NAME_TOGGLE"]
_G.BINDING_NAME_SOLVEARCHY = L["BINDING_NAME_SOLVE"]
_G.BINDING_NAME_SOLVE_WITH_KEYSTONESARCHY = L["BINDING_NAME_SOLVESTONE"]
_G.BINDING_NAME_ARTIFACTSARCHY = L["BINDING_NAME_ARTIFACTS"]
_G.BINDING_NAME_DIGSITESARCHY = L["BINDING_NAME_DIGSITES"]

-----------------------------------------------------------------------
-- Variables
-----------------------------------------------------------------------
local continent_digsites = {}
private.continent_digsites = continent_digsites

local keystoneIDToRaceID = {}
local keystoneLootRaceID -- this is to force a refresh after the BAG_UPDATE event
local digsitesTrackingID -- set in Archy:OnEnable()

local lastSite
local nearestSite

local player_position = {
	map = 0,
	level = 0,
	x = 0,
	y = 0
}

local survey_location = {
	map = 0,
	level = 0,
	x = 0,
	y = 0
}

local prevTheme

-------------------------------------------------------------------------------
-- Debugger.
-------------------------------------------------------------------------------
local function CreateDebugFrame()
	if debugger then
		return
	end
	debugger = LibStub("LibTextDump-1.0"):New(("%s Debug Output"):format(ADDON_NAME), 640, 480)
end

local function Debug(...)
	if not debugger then
		CreateDebugFrame()
	end
	local message = ("[%s] %s"):format(date("%X"), string.format(...))

	debugger:AddLine(message)
	return message
end

local function DebugPour(...)
	Archy:Pour(Debug(...), 1, 1, 1)
end

private.Debug = Debug
private.DebugPour = DebugPour

-----------------------------------------------------------------------
-- Function upvalues
-----------------------------------------------------------------------
local Blizzard_SolveArtifact
local UpdateMinimapIcons
local UpdateAllSites

-----------------------------------------------------------------------
-- External objects. Assigned in Archy:OnEnable()
-----------------------------------------------------------------------
local ArtifactFrame
local DigSiteFrame
local DistanceIndicatorFrame
local TomTomHandler

-----------------------------------------------------------------------
-- Initialization.
-----------------------------------------------------------------------
local BattlefieldMinimapDigsites

local function InitializeBattlefieldDigsites()
	_G.BattlefieldMinimap:HookScript("OnShow", Archy.UpdateTracking)

	BattlefieldMinimapDigsites = _G.CreateFrame("ArchaeologyDigSiteFrame", "ArchyBattleFieldDigsites", _G.BattlefieldMinimap)
	BattlefieldMinimapDigsites:SetSize(225, 150)
	BattlefieldMinimapDigsites:SetPoint("TOPLEFT", _G.BattlefieldMinimap)
	BattlefieldMinimapDigsites:SetPoint("BOTTOMRIGHT", _G.BattlefieldMinimap)
	BattlefieldMinimapDigsites:SetFillAlpha(128)
	BattlefieldMinimapDigsites:SetFillTexture("Interface\\WorldMap\\UI-ArchaeologyBlob-Inside")
	BattlefieldMinimapDigsites:SetBorderTexture("Interface\\WorldMap\\UI-ArchaeologyBlob-Outside")
	BattlefieldMinimapDigsites:EnableSmoothing(true)
	BattlefieldMinimapDigsites:SetBorderScalar(0.1)
	BattlefieldMinimapDigsites.lastUpdate = 0

	local texture = BattlefieldMinimapDigsites:CreateTexture("ArchyBattleFieldDigsitesTexture", "OVERLAY")
	texture:SetAllPoints()

	BattlefieldMinimapDigsites:SetScript("OnUpdate", function(self, elapsed)
		self.lastUpdate = self.lastUpdate + elapsed

		if self.lastUpdate < _G.TOOLTIP_UPDATE_TIME then
			return
		end

		self.lastUpdate = 0
		self:DrawNone()

		local numEntries = _G.ArchaeologyMapUpdateAll()
		for index = 1, numEntries do
			self:DrawBlob(_G.ArcheologyGetVisibleBlobID(index), true)
		end
	end)
end

-----------------------------------------------------------------------
-- Local helper functions
-----------------------------------------------------------------------
local function ToggleDigsiteVisibility(show)
	if show then
		_G.WorldMapArchaeologyDigSites:Show()
	else
		_G.WorldMapArchaeologyDigSites:Hide()
	end

	if BattlefieldMinimapDigsites then
		if show then
			BattlefieldMinimapDigsites:Show()
		else
			BattlefieldMinimapDigsites:Hide()
		end
	end
end

-- Returns true if the player has the archaeology secondary skill
local function HasArchaeology()
	local _, _, archaeologyIndex = _G.GetProfessions()
	return archaeologyIndex and true or false
end

private.HasArchaeology = HasArchaeology

local function HideFrames()
	DigSiteFrame:Hide()
	ArtifactFrame:Hide()
end

local function ShowFrames()
	if private.in_combat or private.FramesShouldBeHidden() then
		return
	end
	DigSiteFrame:Show()
	ArtifactFrame:Show()
	Archy:ConfigUpdated()
end

local SuspendClickToMove
do
	local click_to_move

	function SuspendClickToMove()
		-- we're not using easy cast, no need to mess with click to move
		if not private.db.general.easyCast or _G.IsEquippedItemType(FISHING_POLE_NAME) then
			return
		end

		if private.db.general.show then
			if _G.GetCVarBool("autointeract") then
				_G.SetCVar("autointeract", "0")
				click_to_move = "1"
			end
		else
			if click_to_move and click_to_move == "1" then
				_G.SetCVar("autointeract", "1")
				click_to_move = nil
			end
		end
	end
end -- do-block

local function AnnounceNearestSite()
	if not nearestSite or not nearestSite.distance then
		return
	end
	local site_name = ("%s%s|r"):format(_G.GREEN_FONT_COLOR_CODE, nearestSite.name)
	local site_zone = ("%s%s|r"):format(_G.GREEN_FONT_COLOR_CODE, nearestSite.zoneName)

	Archy:Pour(L["Nearest Dig Site is: %s in %s (%.1f yards away)"]:format(site_name, site_zone, nearestSite.distance), 1, 1, 1)
end

-- returns the rank and max rank for the players archaeology skill
local function GetArchaeologyRank()
	local _, _, archaeology_index = _G.GetProfessions()

	if not archaeology_index then
		return
	end
	local _, _, rank, maxRank = _G.GetProfessionInfo(archaeology_index)
	return rank, maxRank
end

private.GetArchaeologyRank = GetArchaeologyRank

local function IsTaintable()
	return (private.in_combat or _G.InCombatLockdown() or (_G.UnitAffectingCombat("player") or _G.UnitAffectingCombat("pet")))
end

private.IsTaintable = IsTaintable

function private:ResetPositions()
	self.db.digsite.distanceIndicator.position = { unpack(PROFILE_DEFAULTS.profile.digsite.distanceIndicator.position) }
	self.db.digsite.distanceIndicator.anchor = PROFILE_DEFAULTS.profile.digsite.distanceIndicator.anchor
	self.db.digsite.distanceIndicator.undocked = PROFILE_DEFAULTS.profile.digsite.distanceIndicator.undocked
	self.db.digsite.position = { unpack(PROFILE_DEFAULTS.profile.digsite.position) }
	self.db.digsite.anchor = PROFILE_DEFAULTS.profile.digsite.anchor
	self.db.artifact.position = { unpack(PROFILE_DEFAULTS.profile.artifact.position) }
	self.db.artifact.anchor = PROFILE_DEFAULTS.profile.artifact.anchor
	Archy:ConfigUpdated()
	Archy:UpdateFramePositions()
end

local function SolveRaceArtifact(raceID, useStones)
	-- The check for raceID exists because its absence means we're calling this function from the default UI and should NOT perform any of the actions within the block.
	if raceID then
		local race = private.Races[raceID]
		local artifact = race.currentProject

		_G.SetSelectedArtifact(raceID)
		keystoneLootRaceID = raceID

		if _G.type(useStones) == "boolean" then
			if useStones then
				artifact.keystones_added = math.min(race.keystone.inventory, artifact.sockets)
			else
				artifact.keystones_added = 0
			end
		end

		if artifact.keystones_added > 0 then
			for index = 1, artifact.keystones_added do
				_G.SocketItemToArtifact()

				if not _G.ItemAddedToArtifact(index) then
					break
				end
			end
		elseif artifact.sockets > 0 then
			for index = 1, artifact.sockets do
				_G.RemoveItemFromArtifact()
			end
		end
	end
	Blizzard_SolveArtifact()
end

Dialog:Register("ArchyConfirmSolve", {
	text = "",
	on_show = function(self, data)
		self.text:SetFormattedText(L["Your Archaeology skill is at %d of %d.  Are you sure you would like to solve this artifact before visiting a trainer?"], data.rank, data.max_rank)
	end,
	buttons = {
		{
			text = _G.YES,
			on_click = function(self, data)
				if data.race_index then
					SolveRaceArtifact(data.race_index, data.use_stones)
				else
					Blizzard_SolveArtifact()
				end
			end,
		},
		{
			text = _G.NO,
		},
	},
	sound = "levelup2",
	show_while_dead = false,
	hide_on_escape = true,
})

-----------------------------------------------------------------------
-- AddOn methods
-----------------------------------------------------------------------
function Archy:ShowArchaeology()
	if _G.IsAddOnLoaded("Blizzard_ArchaeologyUI") then
		if _G.ArchaeologyFrame:IsShown() then
			_G.HideUIPanel(_G.ArchaeologyFrame)
		else
			_G.ShowUIPanel(_G.ArchaeologyFrame)
		end
		return true
	end
	local loaded, reason = _G.LoadAddOn("Blizzard_ArchaeologyUI")

	if loaded then
		if _G.ArchaeologyFrame:IsShown() then
			_G.HideUIPanel(_G.ArchaeologyFrame)
		else
			_G.ShowUIPanel(_G.ArchaeologyFrame)
		end
		return true
	else
		Archy:Print(L["ArchaeologyUI not loaded: %s Try opening manually."]:format(_G["ADDON_" .. reason]))
		return false
	end
end

-- extract the itemid from the itemlink
local function GetIDFromLink(link)
	if not link then
		return
	end
	local found, _, str = link:find("^|c%x+|H(.+)|h%[.+%]")

	if not found then
		return
	end

	local _, id = (":"):split(str)
	return tonumber(id)
end

local CONFIG_UPDATE_FUNCTIONS = {
	artifact = function(option)
		if option == "autofill" then
			for raceID, race in pairs(private.Races) do
				race:UpdateCurrentProject()
			end
		elseif option == "color" then
			ArtifactFrame:RefreshDisplay()
		else
			ArtifactFrame:UpdateChrome()
			ArtifactFrame:RefreshDisplay()
			Archy:SetFramePosition(ArtifactFrame)
		end
	end,
	digsite = function(option)
		if option == "tooltip" then
			UpdateAllSites()
		end
		Archy:UpdateSiteDistances()
		DigSiteFrame:UpdateChrome()

		if option == "font" then
			Archy:ResizeDigSiteDisplay()
		else
			Archy:RefreshDigSiteDisplay()
		end
		Archy:SetFramePosition(DigSiteFrame)
		Archy:SetFramePosition(DistanceIndicatorFrame)
		DistanceIndicatorFrame:Toggle()
	end,
	minimap = function(option)
		UpdateMinimapIcons(true)
	end,
	tomtom = function(option)
		local db = private.db
		TomTomHandler.hasTomTom = (_G.TomTom and _G.TomTom.AddZWaypoint and _G.TomTom.RemoveWaypoint) and true or false

		if TomTomHandler.hasTomTom and db.tomtom.enabled then
			if _G.TomTom.profile then
				_G.TomTom.profile.arrow.arrival = db.tomtom.distance
				_G.TomTom.profile.arrow.enablePing = db.tomtom.ping
			end
		end
		TomTomHandler:Refresh(nearestSite)
	end,
}

function Archy:ConfigUpdated(namespace, option)
	if namespace then
		CONFIG_UPDATE_FUNCTIONS[namespace](option)
	else
		ArtifactFrame:UpdateChrome()
		ArtifactFrame:RefreshDisplay()

		DigSiteFrame:UpdateChrome()
		self:RefreshDigSiteDisplay()

		self:UpdateTracking()

		DistanceIndicatorFrame:Toggle()
		UpdateMinimapIcons(true)
		SuspendClickToMove()

		TomTomHandler:Refresh(nearestSite)
	end
end

function Archy:SolveAnyArtifact(use_stones)
	local found = false
	for raceID, race in pairs(private.Races) do
		local artifact = race.currentProject
		if not race:IsOnArtifactBlacklist() and (artifact.canSolve or (use_stones and artifact.canSolveInventory)) then
			SolveRaceArtifact(raceID, use_stones)
			found = true
			break
		end
	end

	if not found then
		self:Print(L["No artifacts were solvable"])
	end
end

function Archy:SocketClicked(keystone_button, mouseButtonName, down)
	local raceID = keystone_button:GetParent():GetParent():GetID()
	private.Races[raceID]:KeystoneSocketOnClick(mouseButtonName)
	ArtifactFrame:RefreshDisplay()
end

--[[ Dig Site List Functions ]] --
local function CompareAndResetDigCounters(a, b)
	if not a or not b or (#a == 0) or (#b == 0) then
		return
	end

	for _, siteA in pairs(a) do
		local exists = false
		for _, siteB in pairs(b) do
			if siteA == siteB then
				exists = true
				break
			end
		end

		if not exists then
			siteA.stats.counter = 0
			siteA:DisableMapIcon()
			siteA:DisableSurveyNodes()
		end
	end
end

function UpdateAllSites()
	-- Set this for restoration at the end of the loop, since it's changed every iteration.
	local originalMapID = _G.GetCurrentMapAreaID()

	for continentID, continentName in pairs(MAP_CONTINENTS) do
		_G.SetMapZoom(continentID)

		-- Function fails to populate continent_digsites if showing digsites on the worldmap has been toggled off by the user.
		-- So make sure we enable and show blobs and restore the setting at the end.
		local showDig = _G.GetCVarBool("digSites")
		if not showDig then
			_G.SetCVar("digSites", "1")
			ToggleDigsiteVisibility(true)
			_G.RefreshWorldMap()

			showDig = "0"
		end

		local sites = {}

		for landmarkIndex = 1, _G.GetNumMapLandmarks() do
			local landmarkName, _, textureIndex, mapPositionX, mapPositionY = _G.GetMapLandmarkInfo(landmarkIndex)

			if textureIndex == DIG_LOCATION_TEXTURE_INDEX then
				local siteKey = ("%d:%.6f:%.6f"):format(continentID, mapPositionX, mapPositionY)
				local mc, fc = Astrolabe:GetMapID(continentID, 0)

				-- TODO: Remove landmarkName check once LibBabble-Digsites-3.0 is gone.
				local digsiteTemplate = DIGSITE_TEMPLATES[siteKey] or DIGSITE_TEMPLATES[landmarkName]
				if digsiteTemplate then
					local digsite = private.Digsites[digsiteTemplate.blobID]
					if not digsite then
						local mapID = digsiteTemplate.mapID
						local x, y = Astrolabe:TranslateWorldMapPosition(mc, fc, mapPositionX, mapPositionY, mapID, 0)

						digsite = private.AddDigsite(digsiteTemplate, landmarkName, continentID, MAP_ID_TO_ZONE_ID[mapID], MAP_ID_TO_ZONE_NAME[mapID], x, y)
					end

					table.insert(sites, digsite)
				else
					local blobID = _G.ArcheologyGetVisibleBlobID(landmarkIndex)
					local message = "Archy is missing data for dig site %s (key: %s blobID: %d)"
					Archy:Printf(message, landmarkName, siteKey, blobID)
					DebugPour(message, landmarkName, siteKey, blobID)
				end
			end
		end

		-- restore initial setting
		if showDig == "0" then
			_G.SetCVar("digSites", showDig)
			ToggleDigsiteVisibility(false)
			_G.RefreshWorldMap()
		end

		if #sites > 0 then
			if continent_digsites[continentID] then
				CompareAndResetDigCounters(continent_digsites[continentID], sites)
				CompareAndResetDigCounters(sites, continent_digsites[continentID])
			end
			continent_digsites[continentID] = sites
		end
	end

	_G.SetMapByID(originalMapID)
end

local function SortSitesByDistance(digsiteA, digsiteB)
	if digsiteA:IsBlacklisted() and not digsiteB:IsBlacklisted() then
		return 1 < 0
	elseif not digsiteA:IsBlacklisted() and digsiteB:IsBlacklisted() then
		return 0 < 1
	end

	if (digsiteA.distance == -1 and digsiteB.distance == -1) or (not digsiteA.distance and not digsiteB.distance) then
		return digsiteA.zoneName .. ":" .. digsiteA.name < digsiteB.zoneName .. ":" .. digsiteB.name
	else
		return (digsiteA.distance or 0) < (digsiteB.distance or 0)
	end
end

local function SortSitesByZoneNameAndName(a, b)
	return a.zoneName .. ":" .. a.name < b.zoneName .. ":" .. b.name
end

function Archy:UpdateSiteDistances()
	local continentDigsites = continent_digsites[private.current_continent]
	if not continentDigsites or #continentDigsites == 0 then
		nearestSite = nil
		return
	end
	local distance, nearest

	for index = 1, #continentDigsites do
		local digsite = continentDigsites[index]

		if digsite.mapIconFrame:IsShown() then
			digsite.distance = Astrolabe:GetDistanceToIcon(digsite.mapIconFrame)
		else
			digsite.distance = Astrolabe:ComputeDistance(player_position.map, player_position.level, player_position.x, player_position.y, digsite.mapID, digsite.level, digsite.coordX, digsite.coordY)
		end

		if digsite.coordX and digsite.distance and not digsite:IsBlacklisted() and (not distance or digsite.distance < distance) then
			distance = digsite.distance
			nearest = digsite
		end
	end

	if nearest and nearestSite ~= nearest then
		nearestSite = nearest
		TomTomHandler.isActive = true
		TomTomHandler:Refresh(nearestSite)
		UpdateMinimapIcons()

		if private.db.digsite.announceNearest and private.db.general.show then
			AnnounceNearestSite()
		end
	end

	table.sort(continentDigsites, private.db.digsite.sortByDistance and SortSitesByDistance or SortSitesByZoneNameAndName)
end

--[[ Minimap Functions ]] --
local lastNearestSite

function UpdateMinimapIcons(isForced)
	if not HasArchaeology() or _G.WorldMapButton:IsVisible() or (lastNearestSite == nearestSite and not isForced) then
		return
	end

	lastNearestSite = nearestSite

	if not player_position.x and not player_position.y then
		return
	end

	local continentDigsites = continent_digsites[private.current_continent]
	if not continentDigsites then
		return
	end

	local canShow = private.db.general.show and private.db.minimap.show

	for _, digsite in pairs(continentDigsites) do
		if canShow then
			if nearestSite == digsite or not private.db.minimap.nearest then
				digsite:EnableMapIcon()
			else
				digsite:DisableMapIcon()
			end

			if nearestSite == digsite and private.db.minimap.fragmentNodes then
				digsite:EnableSurveyNodes()
			else
				digsite:DisableSurveyNodes()
			end
		else
			digsite:DisableMapIcon()
			digsite:DisableSurveyNodes()
		end
	end
end

function Archy:OnInitialize()
	private.isLoading = true

	self.db = LibStub("AceDB-3.0"):New("ArchyDB", PROFILE_DEFAULTS, 'Default')
	self.db.RegisterCallback(self, "OnNewProfile", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdate")

	local about_panel = LibStub:GetLibrary("LibAboutPanel", true)

	if about_panel then
		self.optionsFrame = about_panel.new(nil, "Archy")
	end
	self:DefineSinkToast(ADDON_NAME, [[Interface\Archeology\Arch-Icon-Marker]])
	self:SetSinkStorage(self.db.profile.general.sinkOptions)
	self:SetupOptions()

	self.db.global.surveyNodes = self.db.global.surveyNodes or {}

	self.db.char.digsites = self.db.char.digsites or {
		stats = {},
		blacklist = {}
	}

	setmetatable(self.db.char.digsites.stats, {
		__index = function(t, k)
			if k then
				t[k] = {
					surveys = 0,
					fragments = 0,
					looted = 0,
					keystones = 0,
					counter = 0
				}
				return t[k]
			end
		end
	})

	self.db.char.digsites.blacklist = self.db.char.digsites.blacklist or {}

	private.db = self.db.profile
	prevTheme = private.db and private.db.general and private.db.general.theme or PROFILE_DEFAULTS.profile.general.theme

	LDBI:Register("Archy", private.LDB_object, private.db.general.icon)

	if not SECURE_ACTION_BUTTON then
		local button_name = "Archy_SurveyButton"
		local button = _G.CreateFrame("Button", button_name, _G.UIParent, "SecureActionButtonTemplate")
		button:SetPoint("LEFT", _G.UIParent, "RIGHT", 10000, 0)
		button:Hide()
		button:SetFrameStrata("LOW")
		button:EnableMouse(true)
		button:RegisterForClicks("RightButtonUp")
		button.name = button_name
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", SURVEY_SPELL_ID)
		button:SetAttribute("action", nil)

		button:SetScript("PostClick", function(self, mouse_button, is_down)
			if private.override_binding_on and not IsTaintable() then
				_G.ClearOverrideBindings(self)
				private.override_binding_on = nil
			else
				private.regen_clear_override = true
			end
		end)

		SECURE_ACTION_BUTTON = button
	end

	do
		local clicked_time
		local ACTION_DOUBLE_WAIT = 0.4
		local MIN_ACTION_DOUBLECLICK = 0.05

		_G.WorldFrame:HookScript("OnMouseDown", function(frame, button, down)
			if button == "RightButton" and private.db.general.easyCast and _G.ArchaeologyMapUpdateAll() > 0 and not IsTaintable() and not _G.IsEquippedItemType(FISHING_POLE_NAME) then
				local perform_survey = false
				local num_loot_items = _G.GetNumLootItems()

				if (num_loot_items == 0 or not num_loot_items) and clicked_time then
					local pressTime = _G.GetTime()
					local doubleTime = pressTime - clicked_time

					if doubleTime < ACTION_DOUBLE_WAIT and doubleTime > MIN_ACTION_DOUBLECLICK then
						clicked_time = nil
						perform_survey = true
					end
				end
				clicked_time = _G.GetTime()

				if perform_survey and not IsTaintable() then
					-- We're stealing the mouse-up event, make sure we exit MouseLook
					if _G.IsMouselooking() then
						_G.MouselookStop()
					end
					_G.SetOverrideBindingClick(SECURE_ACTION_BUTTON, true, "BUTTON2", SECURE_ACTION_BUTTON.name)
					private.override_binding_on = true
				end
			end
		end)
	end

	-----------------------------------------------------------------------
	-- DB cleanups.
	-----------------------------------------------------------------------
	for digsiteName, value in pairs(self.db.char.digsites.blacklist) do
		if value == false then
			self.db.char.digsites.blacklist[digsiteName] = nil
		end
	end

	private.db.data = nil
end

function Archy:UpdateFramePositions()
	self:SetFramePosition(DistanceIndicatorFrame)
	self:SetFramePosition(DigSiteFrame)
	self:SetFramePosition(ArtifactFrame)
end

local PositionUpdateTimerHandle

function Archy:OnEnable()
	-- Ignore this event for now as it's can break other Archaeology UIs
	-- Would have been nice if Blizzard passed the race index or artifact name with the event
	--    self:RegisterEvent("ARTIFACT_UPDATE")
	self:RegisterEvent("ARCHAEOLOGY_FIND_COMPLETE")
	self:RegisterEvent("ARCHAEOLOGY_SURVEY_CAST")
	self:RegisterEvent("ARTIFACT_COMPLETE")
	self:RegisterEvent("ARTIFACT_DIG_SITE_UPDATED")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:RegisterEvent("LOOT_OPENED")
	self:RegisterEvent("PET_BATTLE_CLOSE")
	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_CONTROL_GAINED")
	self:RegisterEvent("PLAYER_CONTROL_LOST")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_STARTED_MOVING")
	self:RegisterEvent("PLAYER_STOPPED_MOVING")
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:RegisterEvent("SKILL_LINES_CHANGED", "UpdateSkillBar")
	self:RegisterEvent("TAXIMAP_CLOSED")
	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")

	self:RegisterBucketEvent("ARTIFACT_HISTORY_READY", 0.2)

	private.InitializeFrames()
	ArtifactFrame = private.ArtifactFrame
	DigSiteFrame = private.DigSiteFrame
	DistanceIndicatorFrame = private.DistanceIndicatorFrame

	Archy:UpdateFramePositions()
	DigSiteFrame:UpdateChrome()
	ArtifactFrame:UpdateChrome()

	DatamineTooltip:ClearLines()
	DatamineTooltip:SetSpellByID(private.CRATE_SPELL_ID)
	CRATE_USE_STRING = ("%s %s"):format(_G.ITEM_SPELL_TRIGGER_ONUSE, _G["ArchyScanTipTextLeft" .. DatamineTooltip:NumLines()]:GetText())

	for trackingTypeIndex = 1, _G.GetNumTrackingTypes() do
		if (_G.GetTrackingInfo(trackingTypeIndex)) == _G.MINIMAP_TRACKING_DIGSITES then
			digsitesTrackingID = trackingTypeIndex
			break
		end
	end
	self:UpdateTracking()

	TomTomHandler = private.TomTomHandler
	TomTomHandler.isActive = true
	TomTomHandler.hasTomTom = (_G.TomTom and _G.TomTom.AddZWaypoint and _G.TomTom.RemoveWaypoint) and true or false
	TomTomHandler.hasPOIIntegration = TomTomHandler.hasTomTom and (_G.TomTom.profile and _G.TomTom.profile.poi and _G.TomTom.EnableDisablePOIIntegration) and true or false

	-----------------------------------------------------------------------
	-- Initialize Races
	-----------------------------------------------------------------------
	_G.RequestArtifactCompletionHistory()

	for raceID = 1, _G.GetNumArchaeologyRaces() do
		local race = private.AddRace(raceID)
		keystoneIDToRaceID[race.keystone.id] = raceID
	end

	-----------------------------------------------------------------------
	-- Map stuff.
	-----------------------------------------------------------------------
	if _G.BattlefieldMinimap then
		InitializeBattlefieldDigsites()
	else
		Archy:RegisterEvent("ADDON_LOADED")
	end

	local continentData = { _G.GetMapContinents() }
	for continentDataIndex = 1, #continentData do
		-- Odd indices are IDs, even are names.
		if continentDataIndex % 2 == 0 then
			local continentID = continentDataIndex / 2
			local continentName = continentData[continentDataIndex]

			_G.SetMapZoom(continentID)

			local mapID = _G.GetCurrentMapAreaID()

			MAP_CONTINENTS[continentID] = continentName
			MAP_ID_TO_ZONE_NAME[mapID] = continentName

			ZONE_DATA[mapID] = {
				continent = continentID,
				id = 0,
				level = 0,
				map = mapID,
				name = continentName
			}

			local zoneData = { _G.GetMapZones(continentID) }
			for zoneDataIndex = 1, #zoneData do
				-- Odd indices are IDs, even are names.
				if zoneDataIndex % 2 == 0 then
					_G.SetMapByID(mapID)

					local zoneID = _G.GetCurrentMapZone()
					local zoneName = zoneData[zoneDataIndex]

					MAP_ID_TO_ZONE_ID[mapID] = zoneID
					MAP_ID_TO_ZONE_NAME[mapID] = zoneName
					ZONE_DATA[mapID] = {
						continent = continentID,
						id = zoneID,
						level = _G.GetCurrentMapDungeonLevel(),
						map = mapID,
						name = zoneName
					}
				else
					mapID = zoneData[zoneDataIndex]
				end
			end
		end
	end

	_G.SetMapToCurrentZone()
	private.current_continent = _G.GetCurrentMapContinent()
	UpdateAllSites()

	player_position.map, player_position.level, player_position.x, player_position.y = Astrolabe:GetCurrentPlayerPosition()

	self:ScheduleTimer("UpdatePlayerPosition", 2, true)
	private.isLoading = false
end

function Archy:OnProfileUpdate(event, database, ProfileKey)
	local newTheme
	if database then
		if event == "OnProfileChanged" or event == "OnProfileCopied" then
			newTheme = database.profile and database.profile.general and database.profile.general.theme or PROFILE_DEFAULTS.profile.general.theme
		elseif event == "OnProfileReset" or event == "OnNewProfile" then
			newTheme = database.defaults and database.defaults.profile and database.defaults.profile.general and database.defaults.profile.general.theme
		end
	end
	private.db = database and database.profile or self.db.profile

	if newTheme and prevTheme and (newTheme ~= prevTheme) then
		_G.ReloadUI()
	end

	self:ConfigUpdated()
	self:UpdateFramePositions()
end

-----------------------------------------------------------------------
-- Slash command handler
-----------------------------------------------------------------------
local SUBCOMMAND_FUNCS = {
	[L["config"]:lower()] = function()
		_G.InterfaceOptionsFrame_OpenToCategory(Archy.optionsFrame)
	end,
	[L["stealth"]:lower()] = function()
		private.db.general.stealthMode = not private.db.general.stealthMode
		Archy:ConfigUpdated()
	end,
	[L["dig sites"]:lower()] = function()
		private.db.digsite.show = not private.db.digsite.show
		Archy:ConfigUpdated('digsite')
	end,
	[L["artifacts"]:lower()] = function()
		private.db.artifact.show = not private.db.artifact.show
		Archy:ConfigUpdated('artifact')
	end,
	[_G.SOLVE:lower()] = function()
		Archy:SolveAnyArtifact()
	end,
	[L["solve stone"]:lower()] = function()
		Archy:SolveAnyArtifact(true)
	end,
	[L["nearest"]:lower()] = AnnounceNearestSite,
	[L["closest"]:lower()] = AnnounceNearestSite,
	[L["reset"]:lower()] = function()
		private:ResetPositions()
	end,
	[_G.MINIMAP_LABEL:lower()] = function()
		private.db.minimap.show = not private.db.minimap.show
		Archy:ConfigUpdated('minimap')
	end,
	tomtom = function()
		private.db.tomtom.enabled = not private.db.tomtom.enabled
		TomTomHandler:Refresh(nearestSite)
	end,
	test = function()
		ArtifactFrame:SetBackdropBorderColor(1, 1, 1, 0.5)
	end,
	debug = function()
		if not debugger then
			CreateDebugFrame()
		end

		if debugger:Lines() == 0 then
			debugger:AddLine("Nothing to report.")
			debugger:Display()
			debugger:Clear()
			return
		end
		debugger:Display()
	end,
	-- @alpha@
	scan = function()
		local sites = {}
		local found = 0
		local currentMapID = _G.GetCurrentMapAreaID()

		Debug("Scanning digsites:\n")

		for continentIndex, continentID in pairs({ 1, 2, 3, 4, 6, 7 }) do
			_G.SetMapZoom(continentID)

			for landmarkIndex = 1, _G.GetNumMapLandmarks() do
				local landmarkName, _, textureIndex, mapPositionX, mapPositionY = _G.GetMapLandmarkInfo(landmarkIndex)

				if textureIndex == DIG_LOCATION_TEXTURE_INDEX then
					local siteKey = ("%d:%.6f:%.6f"):format(_G.GetCurrentMapContinent(), mapPositionX, mapPositionY)

					if not DIGSITE_TEMPLATES[siteKey] and not sites[siteKey] then
						Debug(("[\"%s\"] = { blobID = %d, mapID = 0, typeID = DigsiteType.Unknown } -- \"%s\""):format(siteKey, _G.ArcheologyGetVisibleBlobID(landmarkIndex), landmarkName))
						sites[siteKey] = true
						found = found + 1
					end
				end
			end
		end
		Debug(("%d found"):format(found))

		_G.SetMapByID(currentMapID)
		debugger:Display()
	end,
	-- @end-alpha@
}

_G["SLASH_ARCHY1"] = "/archy"
_G.SlashCmdList["ARCHY"] = function(msg, editbox)
	local command = msg:lower()

	local func = SUBCOMMAND_FUNCS[command]
	if func then
		func()
	else
		Archy:Print(L["Available commands are:"])
		Archy:Print("|cFF00FF00" .. L["config"] .. "|r - " .. L["Shows the Options"])
		Archy:Print("|cFF00FF00" .. L["stealth"] .. "|r - " .. L["Toggles the display of the Artifacts and Dig Sites lists"])
		Archy:Print("|cFF00FF00" .. L["dig sites"] .. "|r - " .. L["Toggles the display of the Dig Sites list"])
		Archy:Print("|cFF00FF00" .. L["artifacts"] .. "|r - " .. L["Toggles the display of the Artifacts list"])
		Archy:Print("|cFF00FF00" .. _G.SOLVE .. "|r - " .. L["Solves the first artifact it finds that it can solve"])
		Archy:Print("|cFF00FF00" .. L["solve stone"] .. "|r - " .. L["Solves the first artifact it finds that it can solve (including key stones)"])
		Archy:Print("|cFF00FF00" .. L["nearest"] .. "|r or |cFF00FF00" .. L["closest"] .. "|r - " .. L["Announces the nearest dig site to you"])
		Archy:Print("|cFF00FF00" .. L["reset"] .. "|r - " .. L["Reset the window positions to defaults"])
		Archy:Print("|cFF00FF00" .. "tomtom" .. "|r - " .. L["Toggles TomTom Integration"])
		Archy:Print("|cFF00FF00" .. _G.MINIMAP_LABEL .. "|r - " .. L["Toggles the dig site icons on the minimap"])
	end
end

do
	local CRATE_OF_FRAGMENTS = {
		[87534] = true, -- Draenei
		[87533] = true, -- Dwarven
		[87535] = true, -- Fossil
		[117388] = true, -- Mantid
		[117387] = true, -- Mogu
		[87537] = true, -- Nerubian
		[87536] = true, -- Night Elf
		[87538] = true, -- Orc
		[117386] = true, -- Pandaren
		[87539] = true, -- Tol'vir
		[87540] = true, -- Troll
		[87541] = true, -- Vrykul
	}

	local function FindCrateable(bag, slot)
		if not HasArchaeology() then
			return
		end

		if IsTaintable() then
			private.regen_scan_bags = true
			return
		end
		local item_id = _G.GetContainerItemID(bag, slot)

		if item_id then
			-- 86068,73410 for debug or any book-type item
			if CRATE_OF_FRAGMENTS[item_id] then
				private.crate_item_id = item_id
				return true
			end
			DatamineTooltip:SetBagItem(bag, slot)

			for line_num = 1, DatamineTooltip:NumLines() do
				local linetext = (_G["ArchyScanTipTextLeft" .. line_num]:GetText())

				if linetext == CRATE_USE_STRING then
					private.crate_item_id = item_id
					return true
				end
			end
		end
		return false
	end

	function Archy:ScanBags()
		if IsTaintable() then
			private.regen_scan_bags = true
			return
		end
		private.crate_bag_id, private.crate_bag_slot_id, private.crate_item_id = nil, nil, nil

		for bag = _G.BACKPACK_CONTAINER, _G.NUM_BAG_SLOTS, 1 do
			for slot = 1, _G.GetContainerNumSlots(bag), 1 do
				if not private.crate_bag_id and FindCrateable(bag, slot) then
					private.crate_bag_id = bag
					private.crate_bag_slot_id = slot
					break
				end
			end

			if private.crate_bag_id then
				break
			end
		end
		local crateButton = DistanceIndicatorFrame.crateButton

		if private.crate_bag_id then
			crateButton:SetAttribute("type1", "macro")
			crateButton:SetAttribute("macrotext1", "/run _G.ClearCursor() if _G.MerchantFrame:IsShown() then HideUIPanel(_G.MerchantFrame) end\n/use " .. private.crate_bag_id .. " " .. private.crate_bag_slot_id)
			crateButton:Enable()
			crateButton.icon:SetDesaturated(false)
			crateButton.tooltip = private.crate_item_id
			crateButton.shine:Show()
			_G.AutoCastShine_AutoCastStart(crateButton.shine)
			crateButton.shining = true
		else
			crateButton:Disable()
			crateButton.icon:SetDesaturated(true)
			crateButton.tooltip = _G.BROWSE_NO_RESULTS
			crateButton.shine:Hide()

			if crateButton.shining then
				_G.AutoCastShine_AutoCastStop(crateButton.shine)
				crateButton.shining = nil
			end
		end

		local lorewalkerMapCount = _G.GetItemCount(LOREWALKER_ITEMS.MAP.id, false, false)
		local lorewalkerLodeCount = _G.GetItemCount(LOREWALKER_ITEMS.LODESTONE.id, false, false)
		local loreItemButton = DistanceIndicatorFrame.loritemButton

		-- Prioritize map, since it affects Archy's lists. (randomize digsites)
		if lorewalkerMapCount > 0 then
			local itemName = (_G.GetItemInfo(LOREWALKER_ITEMS.MAP.id))
			loreItemButton:SetAttribute("type1", "item")
			loreItemButton:SetAttribute("item1", itemName)
			loreItemButton:Enable()
			loreItemButton.icon:SetDesaturated(false)
			loreItemButton.tooltip = LOREWALKER_ITEMS.MAP.id

			local start, duration, enable = _G.GetItemCooldown(LOREWALKER_ITEMS.MAP.id)
			if start > 0 and duration > 0 then
				_G.CooldownFrame_SetTimer(loreItemButton.cooldown, start, duration, enable)
			end
		end

		if lorewalkerLodeCount > 0 then
			local itemName = (_G.GetItemInfo(LOREWALKER_ITEMS.LODESTONE.id))
			loreItemButton:SetAttribute("type2", "item")
			loreItemButton:SetAttribute("item2", itemName)
			loreItemButton:Enable()
			loreItemButton.icon:SetDesaturated(false)

			if lorewalkerMapCount > 0 then
				loreItemButton.tooltip = { LOREWALKER_ITEMS.MAP.id, itemName }
			else
				loreItemButton.tooltip = { LOREWALKER_ITEMS.LODESTONE.id, _G.USE }
			end
		end

		if lorewalkerMapCount == 0 and lorewalkerLodeCount == 0 then
			loreItemButton:Disable()
			loreItemButton.icon:SetDesaturated(true)
			loreItemButton.tooltip = _G.BROWSE_NO_RESULTS
		end
	end
end -- do-block

function Archy:UpdateSkillBar()
	if not ArtifactFrame.skillBar or not private.current_continent or not HasArchaeology() then
		return
	end

	local rank, maxRank = GetArchaeologyRank()

	ArtifactFrame.skillBar:SetMinMaxValues(0, maxRank)
	ArtifactFrame.skillBar:SetValue(rank)
	ArtifactFrame.skillBar.text:SetFormattedText("%s : %d/%d", _G.GetArchaeologyInfo(), rank, maxRank)
end

--[[ Positional functions ]] --
function Archy:UpdatePlayerPosition(force)
	if not HasArchaeology() or _G.IsInInstance() or _G.UnitIsGhost("player") or (not force and not private.db.general.show) then
		return
	end

	if _G.GetCurrentMapAreaID() == -1 then
		self:UpdateSiteDistances()
		DigSiteFrame:UpdateChrome()
		self:RefreshDigSiteDisplay()
		return
	end
	local mapID, mapLevel, mapX, mapY = Astrolabe:GetCurrentPlayerPosition()

	if not mapID or not mapLevel or (mapX == 0 and mapY == 0) then
		return
	end

	if force or player_position.x ~= mapX or player_position.y ~= mapY or player_position.map ~= mapID or player_position.level ~= mapLevel then
		player_position.x, player_position.y, player_position.map, player_position.level = mapX, mapY, mapID, mapLevel

		self:UpdateSiteDistances()

		DistanceIndicatorFrame:Update(mapID, mapLevel, mapX, mapY, survey_location.map, survey_location.level, survey_location.x, survey_location.y)
		UpdateMinimapIcons()
		self:RefreshDigSiteDisplay()
	end
	local continentID = _G.GetCurrentMapContinent()

	if private.current_continent == continentID then
		if force then
			if private.current_continent then
				UpdateAllSites()
				DistanceIndicatorFrame:Toggle()
			elseif not continentID then
				-- Edge case where continent and private.current_continent are both nil
				self:ScheduleTimer("UpdatePlayerPosition", 1, true)
			end
		end
		return
	end
	private.current_continent = continentID

	if force then
		DistanceIndicatorFrame:Toggle()
	end

	TomTomHandler:ClearWaypoint()
	TomTomHandler:Refresh(nearestSite)

	UpdateAllSites()

	for raceID, race in pairs(private.Races) do
		race:UpdateCurrentProject()
	end
	ArtifactFrame:UpdateChrome()
	ArtifactFrame:RefreshDisplay()

	if force then
		self:UpdateSiteDistances()
	end
	DigSiteFrame:UpdateChrome()
	self:RefreshDigSiteDisplay()
	self:UpdateFramePositions()
end

--[[ UI functions ]] --
function Archy:UpdateTracking()
	if not HasArchaeology() or private.db.general.manualTrack then
		return
	end

	if IsTaintable() then
		private.regen_update_tracking = true
		return
	end

	if digsitesTrackingID then
		_G.SetTracking(digsitesTrackingID, private.db.general.show)
	end

	_G.SetCVar("digSites", private.db.general.show and "1" or "0")

	ToggleDigsiteVisibility(_G.GetCVarBool("digSites"))

	_G.RefreshWorldMap()
end

-------------------------------------------------------------------------------
-- Event handlers.
-------------------------------------------------------------------------------
function Archy:ADDON_LOADED(event, addonName)
	if addonName == "Blizzard_BattlefieldMinimap" then
		InitializeBattlefieldDigsites()
		self:UnregisterEvent("ADDON_LOADED")
	end
end

do
	local function DisableProgressBar()
		local bar = _G.ArcheologyDigsiteProgressBar
		bar:UnregisterEvent("ARCHAEOLOGY_SURVEY_CAST")
		bar:UnregisterEvent("ARCHAEOLOGY_FIND_COMPLETE")
		bar:UnregisterEvent("ARTIFACT_DIGSITE_COMPLETE")
		bar:SetScript("OnEvent", nil)
		bar:SetScript("OnHide", nil)
		bar:SetScript("OnShow", nil)
		bar:SetScript("OnUpdate", nil)
		bar:Hide()
	end

	function Archy:ARCHAEOLOGY_FIND_COMPLETE(eventName, numFindsCompleted, totalFinds)
		DistanceIndicatorFrame.isActive = false
		DistanceIndicatorFrame:Toggle()
		lastSite.stats.counter = numFindsCompleted
	end

	local function SetSurveyCooldown(time)
		_G.CooldownFrame_SetTimer(DistanceIndicatorFrame.surveyButton.cooldown, _G.GetSpellCooldown(SURVEY_SPELL_ID))
	end

	function Archy:ARCHAEOLOGY_SURVEY_CAST(eventName, numFindsCompleted, totalFinds)
		if DisableProgressBar then
			DisableProgressBar()
			DisableProgressBar = nil
		end

		if not nearestSite then
			survey_location.map = 0
			survey_location.level = 0
			survey_location.x = 0
			survey_location.y = 0
			return
		end
		survey_location.level = player_position.level
		survey_location.map = player_position.map
		survey_location.x = player_position.x
		survey_location.y = player_position.y

		lastSite = nearestSite
		lastSite.stats.surveys = lastSite.stats.surveys + 1
		lastSite.stats.counter = numFindsCompleted

		DistanceIndicatorFrame.isActive = true
		DistanceIndicatorFrame:Toggle()
		DistanceIndicatorFrame:Reset()

		if DistanceIndicatorFrame.surveyButton and DistanceIndicatorFrame.surveyButton:IsShown() then
			local now = _G.GetTime()
			local start, duration, enable = _G.GetSpellCooldown(SURVEY_SPELL_ID)

			if start > 0 and duration > 0 and now < (start + duration) then
				if duration <= GLOBAL_COOLDOWN_TIME then
					self:ScheduleTimer(SetSurveyCooldown, (start + duration) - now)
				elseif duration > GLOBAL_COOLDOWN_TIME then
					_G.CooldownFrame_SetTimer(DistanceIndicatorFrame.surveyButton.cooldown, start, duration, enable)
				end
			end
		end

		lastSite:UpdateSurveyNodeDistanceColors()

		TomTomHandler.isActive = false
		TomTomHandler:ClearWaypoint()

		self:RefreshDigSiteDisplay()
	end
end

do
	local function UpdateAndRefresh(race)
		race:UpdateCurrentProject()
		ArtifactFrame:RefreshDisplay()
	end

	function Archy:ARTIFACT_COMPLETE(event, artifactName)
		-- TODO: If this is fired from Blizzard's UI, do NOT immediately update projects.
		-- This is the cause of ticket 461: Race:UpdateCurrentProject() calls SetSelectedArtifact(), which affects the Blizzard UI.
		-- Instead, possibly warn the user that changes to Archy's UI will not be available until Blizzard's UI is closed, then register some events/whatever so we can update
		-- Archy when the Blizzard UI is closed.
		for raceID, race in pairs(private.Races) do
			local artifact = race.currentProject

			if artifact and artifact.name == artifactName then
				race:UpdateCurrentProject()
				self:ScheduleTimer(UpdateAndRefresh, 2, race)
				break
			end
		end
	end
end

function Archy:ARTIFACT_DIG_SITE_UPDATED()
	if not private.current_continent then
		return
	end
	UpdateAllSites()
	self:UpdateSiteDistances()
	self:RefreshDigSiteDisplay()
end

function Archy:ARTIFACT_HISTORY_READY()
	if not private.initialAnnouncementCheck then
		private.initialAnnouncementCheck = self:ScheduleTimer(function()
			for raceID, race in pairs(private.Races) do
				race:UpdateCurrentProject()
			end
		end, 5)
	end

	for raceID, race in pairs(private.Races) do
		local artifact = race.currentProject

		local _, _, completionCount = race:GetArtifactCompletionDataByName(artifact.name)
		if completionCount then
			artifact.completionCount = completionCount
		end
	end
	ArtifactFrame:RefreshDisplay()
end

function Archy:BAG_UPDATE_DELAYED()
	self:ScanBags()

	if not private.current_continent or not keystoneLootRaceID then
		return
	end
	private.Races[keystoneLootRaceID]:UpdateCurrentProject()
	ArtifactFrame:RefreshDisplay()
	keystoneLootRaceID = nil
end

do
	local function MatchFormat(msg, pattern)
		return msg:match(pattern:gsub("(%%s)", "(.+)"):gsub("(%%d)", "(.+)"))
	end

	local function ParseLootMessage(msg)
		local player = _G.UnitName("player")
		local itemLink, quantity = MatchFormat(msg, _G.LOOT_ITEM_SELF_MULTIPLE)

		if itemLink and quantity then
			return player, itemLink, tonumber(quantity)
		end
		quantity = 1
		itemLink = MatchFormat(msg, _G.LOOT_ITEM_SELF)

		if itemLink then
			return player, itemLink, tonumber(quantity)
		end
		player, itemLink, quantity = MatchFormat(msg, _G.LOOT_ITEM_MULTIPLE)

		if player and itemLink and quantity then
			return player, itemLink, tonumber(quantity)
		end
		quantity = 1
		player, itemLink = MatchFormat(msg, _G.LOOT_ITEM)

		return player, itemLink, tonumber(quantity)
	end

	function Archy:CHAT_MSG_LOOT(event, msg)
		local _, itemLink, amount = ParseLootMessage(msg)

		if not itemLink then
			return
		end
		local itemID = GetIDFromLink(itemLink)
		local raceID = keystoneIDToRaceID[itemID]

		if raceID then
			lastSite.stats.keystones = lastSite.stats.keystones + 1
			keystoneLootRaceID = raceID
		end
	end
end -- do-block

function Archy:CURRENCY_DISPLAY_UPDATE()
	if not private.current_continent then
		return
	end

	for raceID, race in pairs(private.Races) do
		local _, _, _, currency_amount = _G.GetArchaeologyRaceInfo(raceID)
		local diff = currency_amount - (race.currency or 0)

		race.currency = currency_amount
		race:UpdateCurrentProject()

		if diff < 0 then
			-- we've spent fragments, aka. Solved an artifact
			race.currentProject.keystones_added = 0
		elseif diff > 0 then
			-- we've gained fragments, aka. Successfully dug at a dig site
			if lastSite then
				lastSite.stats.looted = lastSite.stats.looted + 1
				lastSite.stats.fragments = lastSite.stats.fragments + diff

				lastSite:AddSurveyNode(player_position.map, player_position.level, player_position.x, player_position.y)
			end

			survey_location.map = 0
			survey_location.level = 0
			survey_location.x = 0
			survey_location.y = 0

			UpdateMinimapIcons(true)
			self:RefreshDigSiteDisplay()
		end
	end

	ArtifactFrame:RefreshDisplay()
end

function Archy:GET_ITEM_INFO_RECEIVED(event)
	for race, keystoneItemID in next, private.RaceKeystoneProcessingQueue, nil do
		local keystoneName, _, _, _, _, _, _, _, _, keystoneTexture, _ = _G.GetItemInfo(keystoneItemID)
		if keystoneName and keystoneTexture then
			race.keystone.name = keystoneName
			race.keystone.texture = keystoneTexture
			private.RaceKeystoneProcessingQueue[race] = nil
		end
	end

	for data, race in next, private.RaceArtifactProcessingQueue, nil do
		local artifactName = _G.GetItemInfo(data.itemID)
		if artifactName then
			race.ArtifactItemIDs[artifactName] = data.itemID
			race.ArtifactSpellIDs[artifactName] = data.spellID
			private.RaceArtifactProcessingQueue[data] = nil
		end
	end

	if not next(private.RaceKeystoneProcessingQueue) and not next(private.RaceArtifactProcessingQueue) then
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
	end
end

do
	local QUEST_ITEM_IDS = {
		[79049] = true, -- Serpentrider Relic
		[97986] = true, -- Digmaster's Earthblade
		[114212] = true, -- Pristine Rylak Riding Harness
	}

	function Archy:LOOT_OPENED(event, ...)
		local auto_loot_enabled = ...

		if not private.db.general.autoLoot or auto_loot_enabled == 1 then
			return
		end

		for slotID = 1, _G.GetNumLootItems() do
			local slotType = _G.GetLootSlotType(slotID)

			if slotType == _G.LOOT_SLOT_CURRENCY then
				_G.LootSlot(slotID)
			elseif slotType == _G.LOOT_SLOT_ITEM then
				local itemLink = _G.GetLootSlotLink(slotID)

				if itemLink then
					local itemID = GetIDFromLink(itemLink)

					if itemID and (keystoneIDToRaceID[itemID] or QUEST_ITEM_IDS[itemID]) then
						_G.LootSlot(slotID)
					end
				end
			end
		end
	end
end -- do-block

function Archy:PET_BATTLE_CLOSE()
	if private.pet_battle_shown then
		private.pet_battle_shown = nil
		private.db.general.show = true

		-- API doesn't return correct values in this event
		if _G.C_PetBattles.IsInBattle() then
			-- so let's schedule our re-show in a sec
			self:ScheduleTimer("ConfigUpdated", 1.5)
		else
			self:ConfigUpdated()
		end
	end
end

function Archy:PET_BATTLE_OPENING_START()
	if not private.db.general.show or private.db.general.stealthMode then
		return
	end

	-- store our visible state to restore after pet battle
	private.pet_battle_shown = true
	private.db.general.show = false
	self:ConfigUpdated()
end

function Archy:PLAYER_CONTROL_GAINED()
	if PositionUpdateTimerHandle then
		self:UpdatePlayerPosition()
		PositionUpdateTimerHandle = self:CancelTimer(PositionUpdateTimerHandle)
	end
end

function Archy:PLAYER_CONTROL_LOST()
	if private.isTaxiMapOpen then
		self:UpdatePlayerPosition()
		PositionUpdateTimerHandle = self:ScheduleRepeatingTimer("UpdatePlayerPosition", 0.1)
	end
end

function Archy:PLAYER_ENTERING_WORLD()
	-- If TomTom is configured to automatically set a waypoint to the closest quest objective, that will interfere with Archy. Warn, if applicable.
	if TomTomHandler.hasPOIIntegration and _G.TomTom.profile.poi.setClosest then
		TomTomHandler:DisplayConflictError()
	end

	if _G.IsInInstance() then
		HideFrames()
	else
		ShowFrames()
	end
end

function Archy:PLAYER_REGEN_DISABLED()
	private.in_combat = true

	if self.LDB_Tooltip and self.LDB_Tooltip:IsShown() then
		self.LDB_Tooltip:Hide()
	end

	if private.db.general.combathide then
		HideFrames()
	end
end

function Archy:PLAYER_REGEN_ENABLED()
	private.in_combat = nil

	if private.regen_create_frames then
		private.regen_create_frames = nil
		private.InitializeFrames()
	end

	if private.regen_toggle_distance then
		private.regen_toggle_distance = nil
		DistanceIndicatorFrame:Toggle()
	end

	if private.regen_update_tracking then
		private.regen_update_tracking = nil
		self:UpdateTracking()
	end

	if private.regen_clear_override then
		_G.ClearOverrideBindings(SECURE_ACTION_BUTTON)
		private.override_binding_on = nil
		private.regen_clear_override = nil
	end

	if private.regen_update_digsites then
		private.regen_update_digsites = nil
		DigSiteFrame:UpdateChrome()
	end

	if private.regen_update_races then
		private.regen_update_races = nil
		ArtifactFrame:UpdateChrome()
	end

	if private.regen_scan_bags then
		private.regen_scan_bags = nil
		self:ScanBags()
	end

	if private.db.general.combathide then
		ShowFrames()
	end
end

function Archy:PLAYER_STARTED_MOVING()
	if not _G.IsInInstance() then
		self:UpdatePlayerPosition()
		PositionUpdateTimerHandle = self:ScheduleRepeatingTimer("UpdatePlayerPosition", 0.1)
	end
end

function Archy:PLAYER_STOPPED_MOVING()
	if PositionUpdateTimerHandle then
		self:UpdatePlayerPosition()
		PositionUpdateTimerHandle = self:CancelTimer(PositionUpdateTimerHandle)
	end
end

-- Delay loading Blizzard_ArchaeologyUI until QUEST_LOG_UPDATE so races main page doesn't bug.
function Archy:QUEST_LOG_UPDATE()
	-- Hook and overwrite the default SolveArtifact function to provide confirmations when nearing cap
	if not Blizzard_SolveArtifact then
		if not _G.IsAddOnLoaded("Blizzard_ArchaeologyUI") then
			local loaded, reason = _G.LoadAddOn("Blizzard_ArchaeologyUI")
			if not loaded then
				self:Print(L["ArchaeologyUI not loaded: %s SolveArtifact hook not installed."]:format(_G["ADDON_" .. reason]))
			end
		end
		Blizzard_SolveArtifact = _G.SolveArtifact
		function _G.SolveArtifact(race_index, use_stones)
			local rank, max_rank = GetArchaeologyRank()
			if private.db.general.confirmSolve and max_rank < MAX_ARCHAEOLOGY_RANK and (rank + 25) >= max_rank then
				Dialog:Spawn("ArchyConfirmSolve", {
					race_index = race_index,
					use_stones = use_stones,
					rank = rank,
					max_rank = max_rank
				})
			else
				return SolveRaceArtifact(race_index, use_stones)
			end
		end
	end

	self:ConfigUpdated()
	self:UnregisterEvent("QUEST_LOG_UPDATE")
	self.QUEST_LOG_UPDATE = nil
end

do
	local function SetLoreItemCooldown(time)
		_G.CooldownFrame_SetTimer(DistanceIndicatorFrame.loritemButton.cooldown, _G.GetItemCooldown(LOREWALKER_ITEMS.MAP.id))
	end

	function Archy:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank, line_id, spell_id)
		if unit ~= "player" then
			return
		end

		if spell_id == LOREWALKER_ITEMS.MAP.spell and event == "UNIT_SPELLCAST_SUCCEEDED" then
			if DistanceIndicatorFrame.loritemButton:IsShown() then
				self:ScheduleTimer(SetLoreItemCooldown, 0.2)
			end
		end

		if spell_id == private.CRATE_SPELL_ID then
			if private.busy_crating then
				private.busy_crating = nil
				self:ScheduleTimer("ScanBags", 1)
			end
		end
	end
end -- do-block

function Archy:TAXIMAP_CLOSED()
	private.isTaxiMapOpen = nil
end

function Archy:TAXIMAP_OPENED()
	private.isTaxiMapOpen = true
end

function Archy:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	if unit == "player" and spell == private.CRATE_SPELL_NAME then
		private.busy_crating = true
	end
end
