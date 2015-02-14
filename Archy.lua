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
local DIG_SITES = private.DIG_SITES
local MAX_PROFESSION_RANK = _G.GetExpansionLevel() + 4 -- Skip the 4 ranks of vanilla
local MAX_ARCHAEOLOGY_RANK = _G.PROFESSION_RANKS[MAX_PROFESSION_RANK][1]
private.MAX_ARCHAEOLOGY_RANK = MAX_ARCHAEOLOGY_RANK

local MAP_ID_TO_ZONE_ID = {} -- Popupated in Archy:OnInitialize()
local MAP_ID_TO_ZONE_NAME = {} -- Popupated in Archy:OnInitialize()

local MINIMAP_SIZES = {
	indoor = {
		[0] = 300,
		[1] = 240,
		[2] = 180,
		[3] = 120,
		[4] = 80,
		[5] = 50,
	},
	outdoor = {
		[0] = 466 + 2 / 3,
		[1] = 400,
		[2] = 333 + 1 / 3,
		[3] = 266 + 2 / 6,
		[4] = 200,
		[5] = 133 + 1 / 3,
	},
	indoor_scale = {
		[0] = 1,
		[1] = 1.25,
		[2] = 5 / 3,
		[3] = 2.5,
		[4] = 3.75,
		[5] = 6,
	},
	outdoor_scale = {
		[0] = 1,
		[1] = 7 / 6,
		[2] = 1.4,
		[3] = 1.75,
		[4] = 7 / 3,
		[5] = 3.5,
	},
}

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
				-200,
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
				"TOPRIGHT", "TOPRIGHT", -200, -200
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
			scale = 1,
		},
		tomtom = {
			enabled = true,
			distance = 125,
			ping = true,
		},
	},
}

local GLOBAL_COOLDOWN_TIME = 1.5
local SECURE_ACTION_BUTTON -- Populated in Archy:OnInitialize()
local SITES_PER_CONTINENT = 4
local SURVEY_SPELL_ID = 80451
local CRATE_USE_STRING -- Populate in Archy:OnEnable()
local DIG_LOCATION_TEXTURE_INDEX = 177

local ZONE_DATA = {}
private.ZONE_DATA = ZONE_DATA

local ZONE_ID_TO_NAME = {} -- Popupated in Archy:OnInitialize()
local MAP_CONTINENTS = {} -- Popupated in Archy:OnEnable()

local LOREWALKER_ITEMS = {
	MAP = { id = 87549, spell = 126957 },
	LODESTONE = { id = 87548, spell = 126956 },
}

local CRATE_OF_FRAGMENTS = {
	-- all pre-MoP races at Mists of Pandaria expansion
	[87533] = true, -- Dwarven
	[87534] = true, -- Draenei
	[87535] = true, -- Fossil
	[87536] = true, -- Night Elf
	[87537] = true, -- Nerubian
	[87538] = true, -- Orc
	[87539] = true, -- Tol'vir
	[87540] = true, -- Troll
	[87541] = true, -- Vrykul
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
local artifactSolved = {
	raceId = 0,
	name = ""
}

local continent_digsites = {}
private.continent_digsites = continent_digsites

local keystoneIDToRaceID = {}
local keystoneLootRaceID -- this is to force a refresh after the BAG_UPDATE event
local digsitesTrackingID -- set in Archy:OnEnable()
local lastSite = {}
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
local UpdateMinimapPOIs
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

local function POI_OnEnter(self)
	if not self.tooltip then
		return
	end
	_G.GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	_G.GameTooltip:SetText(self.tooltip, _G.NORMAL_FONT_COLOR[1], _G.NORMAL_FONT_COLOR[2], _G.NORMAL_FONT_COLOR[3], 1) --, true)
end

local function POI_OnLeave(self)
	_G.GameTooltip:Hide()
end

local Arrow_OnUpdate
do
	local ARROW_UPDATE_THRESHOLD = 0.1
	local RAD_135 = math.rad(135)
	local SQUARE_HALF = math.sqrt(0.5)

	function Arrow_OnUpdate(self, elapsed)
		self.t = self.t + elapsed

		if self.t < ARROW_UPDATE_THRESHOLD then
			return
		end
		self.t = 0

		if _G.IsInInstance() then
			self:Hide()
			return
		end

		local isOnEdge = Astrolabe:IsIconOnEdge(self)

		if self.type == "site" then
			if isOnEdge then
				if self.icon:IsShown() then
					self.icon:Hide()
				end

				if not self.arrow:IsShown() then
					self.arrow:Show()
				end

				-- Rotate the icon, as required
				local angle = Astrolabe:GetDirectionToIcon(self) + RAD_135
				if _G.GetCVar("rotateMinimap") == "1" then
					angle = angle - _G.GetPlayerFacing()
				end

				local sin, cos = math.sin(angle) * SQUARE_HALF, math.cos(angle) * SQUARE_HALF
				self.arrow:SetTexCoord(0.5 - sin, 0.5 + cos, 0.5 + cos, 0.5 + sin, 0.5 - cos, 0.5 - sin, 0.5 + sin, 0.5 - cos)
			else
				if not self.icon:IsShown() then
					self.icon:Show()
				end

				if self.arrow:IsShown() then
					self.arrow:Hide()
				end
			end
		elseif isOnEdge then
			if self.icon:IsShown() then
				self.icon:Hide()
			end
		else
			if not self.icon:IsShown() then
				self.icon:Show()
			end
		end
	end
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
	if not nearestSite or not nearestSite.distance or nearestSite.distance == 999999 then
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
		local artifact = race.artifact

		_G.SetSelectedArtifact(raceID)
		artifactSolved.raceId = raceID
		artifactSolved.name = _G.GetSelectedArtifactInfo()
		artifact.name = artifactSolved.name
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
			for raceID = 1, _G.GetNumArchaeologyRaces() do
				private.Races[raceID]:UpdateArtifact()
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
		UpdateMinimapPOIs(true)
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
		UpdateMinimapPOIs(true)
		SuspendClickToMove()

		TomTomHandler:Refresh(nearestSite)
	end
end

function Archy:SolveAnyArtifact(use_stones)
	local found = false
	for raceID, race in pairs(private.Races) do
		local artifact = race.artifact
		if not private.db.artifact.blacklist[raceID] and (artifact.canSolve or (use_stones and artifact.canSolveInventory)) then
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
			if siteA.id == siteB.id then
				exists = true
				break
			end
		end

		if not exists then
			Archy.db.char.digsites.stats[siteA.id].counter = 0
		end
	end
end

local sessionErrors = {}
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

				-- TODO: Remove landmarkName check once LibBabble-Digsites is gone.
				local site = DIG_SITES[siteKey] or DIG_SITES[landmarkName]
				if not site then
					local blobID = _G.ArcheologyGetVisibleBlobID(landmarkIndex)

					if not sessionErrors[siteKey] then
						local message = "Archy is missing data for dig site %s (key: %s blobID: %d)"
						Archy:Printf(message, landmarkName, siteKey, blobID)
						DebugPour(message, landmarkName, siteKey, blobID)
						sessionErrors[siteKey] = true
					end

					site = {
						blobID = blobID,
						mapID = 0,
						typeID = private.DigsiteRaces.Unknown
					}
				end

				local mapID = site.mapID
				local x, y = Astrolabe:TranslateWorldMapPosition(mc, fc, mapPositionX, mapPositionY, mapID, 0)

				table.insert(sites, {
					continent = mc,
					distance = 999999,
					maxFindCount = site.maxFindCount,
					id = site.blobID,
					level = 0,
					map = mapID,
					name = landmarkName,
					raceId = site.typeID,
					x = x,
					y = y,
					zoneId = MAP_ID_TO_ZONE_ID[mapID],
					zoneName = MAP_ID_TO_ZONE_NAME[mapID] or _G.UNKNOWN,
				})
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

function Archy:IsSiteBlacklisted(name)
	return self.db.char.digsites.blacklist[name]
end

function Archy:ToggleSiteBlacklist(name)
	self.db.char.digsites.blacklist[name] = not self.db.char.digsites.blacklist[name]
end

local function SortSitesByDistance(a, b)
	if Archy:IsSiteBlacklisted(a.name) and not Archy:IsSiteBlacklisted(b.name) then
		return 1 < 0
	elseif not Archy:IsSiteBlacklisted(a.name) and Archy:IsSiteBlacklisted(b.name) then
		return 0 < 1
	end

	if (a.distance == -1 and b.distance == -1) or (not a.distance and not b.distance) then
		return a.zoneName .. ":" .. a.name < b.zoneName .. ":" .. b.name
	else
		return (a.distance or 0) < (b.distance or 0)
	end
end

local function SortSitesByZoneNameAndName(a, b)
	return a.zoneName .. ":" .. a.name < b.zoneName .. ":" .. b.name
end

function Archy:UpdateSiteDistances()
	if not continent_digsites[private.current_continent] or (#continent_digsites[private.current_continent] == 0) then
		nearestSite = nil
		return
	end
	local distance, nearest

	for index = 1, #continent_digsites[private.current_continent] do
		local site = continent_digsites[private.current_continent][index]

		if site.poi then
			site.distance = Astrolabe:GetDistanceToIcon(site.poi)
		else
			site.distance = Astrolabe:ComputeDistance(player_position.map, player_position.level, player_position.x, player_position.y, site.map, site.level, site.x, site.y)
		end

		if site.x and not Archy:IsSiteBlacklisted(site.name) then
			if not distance or site.distance < distance then
				distance = site.distance
				nearest = site
			end
		end
	end

	if nearest and (not nearestSite or nearestSite.id ~= nearest.id) then
		nearestSite = nearest
		TomTomHandler.isActive = true
		TomTomHandler:Refresh(nearestSite)
		UpdateMinimapPOIs()

		if private.db.digsite.announceNearest and private.db.general.show then
			AnnounceNearestSite()
		end
	end

	local sites = continent_digsites[private.current_continent]
	if private.db.digsite.sortByDistance then
		table.sort(sites, SortSitesByDistance)
	else
		table.sort(sites, SortSitesByZoneNameAndName)
	end
end

function Archy:ImportOldStatsDB()
	local siteStats = self.db.char.digsites.stats

	for key, st in pairs(self.db.char.digsites) do
		if type(key) == "string" and key ~= "blacklist" and key ~= "stats" and key ~= "counter" and key ~= "" and DIG_SITES[key] then
			local site = DIG_SITES[key]
			if type(site.blob_id) == "number" and site.blob_id > 0 then
				local blobStats = siteStats[site.blob_id]
				blobStats.surveys = (blobStats.surveys or 0) + (st.surveys or 0)
				blobStats.fragments = (blobStats.fragments or 0) + (st.fragments or 0)
				blobStats.looted = (blobStats.looted or 0) + (st.looted or 0)
				blobStats.keystones = (blobStats.keystones or 0) + (st.keystones or 0)

				self.db.char.digsites[key] = nil
			end
		end
	end

	-- Drii: let's also try to fix whatever crap was put in the SV by the old version of this function so users don't have to delete their variables.
	if next(siteStats) then
		for blobID, _ in pairs(siteStats) do
			if type(blobID) ~= "number" or blobID <= 0 then
				siteStats[blobID] = nil
			end
		end
	end
end

--[[ Survey Functions ]] --
local function AddSurveyNode(siteId, map, level, x, y)
	local exists = false

	Archy.db.global.surveyNodes = Archy.db.global.surveyNodes or {}
	Archy.db.global.surveyNodes[siteId] = Archy.db.global.surveyNodes[siteId] or {}

	for _, node in pairs(Archy.db.global.surveyNodes[siteId]) do
		local distance = Astrolabe:ComputeDistance(map, level, x, y, node.m, node.f, node.x, node.y)
		if not distance or _G.IsInInstance() then
			distance = 0
		end

		if distance <= 10 then
			exists = true
			break
		end
	end

	if not exists then
		table.insert(Archy.db.global.surveyNodes[siteId], {
			m = map,
			f = level,
			x = x,
			y = y
		})
	end
end

local function UpdateDistanceIndicator()
	if survey_location.x == 0 and survey_location.y == 0 or _G.IsInInstance() then
		return
	end
	local distance = Astrolabe:ComputeDistance(player_position.map, player_position.level, player_position.x, player_position.y, survey_location.map, survey_location.level, survey_location.x, survey_location.y)

	if not distance then
		distance = 0
	end
	local greenMin, greenMax = 0, private.db.digsite.distanceIndicator.green
	local yellowMin, yellowMax = greenMax, private.db.digsite.distanceIndicator.yellow
	local redMin, redMax = yellowMax, 500

	if distance >= greenMin and distance <= greenMax then
		DistanceIndicatorFrame:SetColor("green")
	elseif distance >= yellowMin and distance <= yellowMax then
		DistanceIndicatorFrame:SetColor("yellow")
	elseif distance >= redMin and distance <= redMax then
		DistanceIndicatorFrame:SetColor("red")
	else
		DistanceIndicatorFrame:Toggle()
		return
	end
	DistanceIndicatorFrame.circle.distance:SetFormattedText("%1.f", distance)
end

--[[ Minimap Functions ]] --
local sitePool = {}
local surveyPool = {}
local PointsOfInterest = {}
local sitePoiCount, surveyPoiCount = 0, 0

local function GetSitePOI(siteId, map, level, x, y, tooltip)
	local poi = table.remove(sitePool)

	if not poi then
		sitePoiCount = sitePoiCount + 1
		poi = _G.CreateFrame("Frame", "ArchyMinimap_SitePOI" .. sitePoiCount, _G.Minimap)
		poi.index = sitePoiCount
		poi:SetWidth(10)
		poi:SetHeight(10)

		poi.icon = poi:CreateTexture("BACKGROUND")
		poi.icon:SetTexture([[Interface\Archeology\Arch-Icon-Marker.blp]])
		poi.icon:SetPoint("CENTER", 0, 0)
		poi.icon:SetHeight(14)
		poi.icon:SetWidth(14)
		poi.icon:Hide()

		poi.arrow = poi:CreateTexture("BACKGROUND")
		poi.arrow:SetTexture([[Interface\Minimap\ROTATING-MINIMAPGUIDEARROW.tga]])
		poi.arrow:SetPoint("CENTER", 0, 0)
		poi.arrow:SetWidth(32)
		poi.arrow:SetHeight(32)
		poi.arrow:Hide()
		poi:Hide()
	end
	poi:SetScript("OnEnter", POI_OnEnter)
	poi:SetScript("OnLeave", POI_OnLeave)
	poi:SetScript("OnUpdate", Arrow_OnUpdate)
	poi.type = "site"
	poi.tooltip = tooltip
	poi.location = {
		map = map,
		level = level,
		x = x,
		y = y,
	}
	poi.siteId = siteId
	poi.t = 0

	PointsOfInterest[poi] = true
	return poi
end

local function GetSurveyPOI(siteId, map, level, x, y, tooltip)
	local poi = table.remove(surveyPool)

	if not poi then
		surveyPoiCount = surveyPoiCount + 1
		poi = _G.CreateFrame("Frame", "ArchyMinimap_SurveyPOI" .. surveyPoiCount, _G.Minimap)
		poi.index = surveyPoiCount
		poi:SetWidth(8)
		poi:SetHeight(8)

		poi.icon = poi:CreateTexture("BACKGROUND")
		poi.icon:SetTexture([[Interface\AddOns\Archy\Media\Nodes]])

		if private.db.minimap.fragmentIcon == "Cross" then
			poi.icon:SetTexCoord(0, 0.46875, 0, 0.453125)
		else
			poi.icon:SetTexCoord(0, 0.234375, 0.5, 0.734375)
		end
		poi.icon:SetPoint("CENTER", 0, 0)
		poi.icon:SetHeight(8)
		poi.icon:SetWidth(8)
		poi.icon:Hide()

		poi:Hide()
	end
	poi:SetScript("OnEnter", POI_OnEnter)
	poi:SetScript("OnLeave", POI_OnLeave)
	poi:SetScript("OnUpdate", Arrow_OnUpdate)
	poi.type = "survey"
	poi.tooltip = tooltip
	poi.location = {
		map = map,
		level = level,
		x = x,
		y = y,
	}
	poi.siteId = siteId
	poi.t = 0

	PointsOfInterest[poi] = true
	return poi
end

local function ClearPOI(poi)
	if not poi then
		return
	end
	Astrolabe:RemoveIconFromMinimap(poi)

	poi.location = nil
	poi.siteId = nil
	poi.tooltip = nil

	poi.icon:Hide()
	poi:Hide()
	poi:SetScript("OnEnter", nil)
	poi:SetScript("OnLeave", nil)
	poi:SetScript("OnUpdate", nil)

	PointsOfInterest[poi] = nil

	if poi.type == "site" then
		poi.arrow:Hide()
		table.insert(sitePool, poi)
	elseif poi.type == "survey" then
		table.insert(surveyPool, poi)
	end
end

local lastNearestSite

local function ClearInvalidPOIs()
	local validSiteIDs = {}

	if private.db.general.show and private.db.minimap.show then
		return validSiteIDs
	end

	if continent_digsites[private.current_continent] then
		for _, site in pairs(continent_digsites[private.current_continent]) do
			table.insert(validSiteIDs, site.id)
		end
	end

	for poi in pairs(PointsOfInterest) do
		if not validSiteIDs[poi.siteId] then
			ClearPOI(poi)
		elseif poi.type == "survey" and lastNearestSite.id ~= nearestSite.id and lastNearestSite.id == poi.siteId then
			ClearPOI(poi)
		end
	end
end

function UpdateMinimapPOIs(force)
	if _G.WorldMapButton:IsVisible() then
		return
	end

	if lastNearestSite == nearestSite and not force then
		return
	end
	lastNearestSite = nearestSite

	local sites = continent_digsites[private.current_continent]

	if not sites or #sites == 0 or _G.IsInInstance() then
		for poi in pairs(PointsOfInterest) do
			ClearPOI(poi)
		end
		return
	end
	ClearInvalidPOIs()

	if not player_position.x and not player_position.y then
		return
	end
	local i = 1

	for _, site in pairs(sites) do
		site.poi = GetSitePOI(site.id, site.map, site.level, site.x, site.y, ("%s\n(%s)"):format(site.name, site.zoneName))

		if site.map > 0 then
			Astrolabe:PlaceIconOnMinimap(site.poi, site.map, site.level, site.x, site.y)
		end

		if (not private.db.minimap.nearest or (nearestSite and nearestSite.id == site.id)) and private.db.general.show and private.db.minimap.show then
			site.poi:Show()
			site.poi.icon:Show()
		else
			site.poi:Hide()
			site.poi.icon:Hide()
		end

		if nearestSite and nearestSite.id == site.id then
			if not site.surveyPOIs then
				site.surveyPOIs = {}
			end

			if Archy.db.global.surveyNodes[site.id] and private.db.minimap.fragmentNodes then
				for index, node in pairs(Archy.db.global.surveyNodes[site.id]) do
					site.surveyPOIs[index] = GetSurveyPOI(site.id, node.m, node.f, node.x, node.y, ("%s #%d\n%s\n(%s)"):format(L["Survey"], index, site.name, site.zoneName))

					local POI = site.surveyPOIs[index]

					Astrolabe:PlaceIconOnMinimap(POI, node.m, node.f, node.x, node.y)

					if private.db.general.show then
						POI:Show()
						POI.icon:Show()
					else
						POI:Hide()
						POI.icon:Hide()
					end
					Arrow_OnUpdate(POI, 5)
				end
			end
		end

		Arrow_OnUpdate(site.poi, 5)
	end

	if private.db.minimap.fragmentColorBySurveyDistance and private.db.minimap.fragmentIcon ~= "CyanDot" then
		for poi in pairs(PointsOfInterest) do
			if poi.type == "survey" then
				poi.icon:SetTexCoord(0, 0.234375, 0.5, 0.734375)
			end
		end
	end
end

function Archy:OnInitialize()
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

	self.db.char.digsites.stats = self.db.char.digsites.stats or {}
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
	setmetatable(self.db.char.digsites.blacklist, {
		__index = function(t, k)
			if k then
				t[k] = false
				return t[k]
			end
		end
	})

	private.db = self.db.profile
	prevTheme = private.db and private.db.general and private.db.general.theme or PROFILE_DEFAULTS.profile.general.theme

	private.db.data = private.db.data or {}
	private.db.data.imported = false

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
	self:ImportOldStatsDB()
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
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:RegisterEvent("SKILL_LINES_CHANGED", "UpdateSkillBar")
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

	for raceID = 1, _G.GetNumArchaeologyRaces() do
		local race = self:AddRace(raceID)
		if race then
			keystoneIDToRaceID[race.keystone.id] = raceID
		end
	end

	local CONTINENT_RACES = private.CONTINENT_RACES
	for siteKey, site in pairs(private.DIG_SITES) do
		local continentID = site.continentID or tonumber(((":"):split(siteKey)))
		CONTINENT_RACES[continentID] = CONTINENT_RACES[continentID] or {}
		CONTINENT_RACES[continentID][site.typeID] = true
	end

	_G.RequestArtifactCompletionHistory()

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
			private.MAP_ID_TO_CONTINENT_ID[mapID] = continentID

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
					ZONE_ID_TO_NAME[zoneID] = zoneName
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
	self:ScheduleTimer(function() PositionUpdateTimerHandle = self:ScheduleRepeatingTimer("UpdatePlayerPosition", 0.2) end, 3)
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
	-- @debug@
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

					if not DIG_SITES[siteKey] and not sites[siteKey] then
						Debug(("[\"%s\"] = { blobID = %d, mapID = 0, typeID = DigsiteRaces.Unknown } -- \"%s\""):format(siteKey, _G.ArcheologyGetVisibleBlobID(landmarkIndex), landmarkName))
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
	dump = function()
		local DigsiteRaces = private.DigsiteRaces
		local sidjiData = {
			["1:0.439747:0.333789"] = { blobID = 55354, map = 42, race = RACE_NIGHTELF }, -- "Nazj'vel Digsite"
			["1:0.439312:0.359957"] = { blobID = 55356, map = 43, race = RACE_NIGHTELF }, -- "Zoram Strand Digsite"
			["1:0.463823:0.378463"] = { blobID = 55398, map = 43, race = RACE_NIGHTELF }, -- "Ruins of Ordil'Aran"
			["1:0.470426:0.436588"] = { blobID = 55400, map = 43, race = RACE_NIGHTELF }, -- "Ruins of Stardust"
			["1:0.424692:0.419346"] = { blobID = 55404, map = 81, race = RACE_NIGHTELF }, -- "Stonetalon Peak"
			["1:0.434937:0.502743"] = { blobID = 55406, map = 81, race = RACE_NIGHTELF }, -- "Ruins of Eldre'Thar"
			["1:0.480345:0.505719"] = { blobID = 55408, map = 81, race = RACE_FOSSIL }, -- "Unearthed Grounds"
			["1:0.385969:0.540773"] = { blobID = 55418, map = 101, race = RACE_NIGHTELF }, -- "Slitherblade Shore Digsite"
			["1:0.396377:0.534088"] = { blobID = 55420, map = 101, race = RACE_NIGHTELF }, -- "Ethel Rethor Digsite"
			["1:0.412057:0.598124"] = { blobID = 55424, map = 101, race = RACE_NIGHTELF }, -- "Mannoroc Coven Digsite"
			["1:0.413714:0.576154"] = { blobID = 55426, map = 101, race = RACE_FOSSIL }, -- "Kodo Graveyard"
			["1:0.427192:0.610638"] = { blobID = 55422, map = 101, race = RACE_FOSSIL }, -- "Valley of Bones"
			["1:0.439584:0.529238"] = { blobID = 55428, map = 101, race = RACE_NIGHTELF }, -- "Sargeron Digsite"
			["1:0.366268:0.719103"] = { blobID = 56335, map = 121, race = RACE_NIGHTELF }, -- "Solarsal Digsite"
			["1:0.390236:0.641127"] = { blobID = 56331, map = 121, race = RACE_NIGHTELF }, -- "Ravenwind Digsite"
			["1:0.415888:0.647527"] = { blobID = 56333, map = 121, race = RACE_NIGHTELF }, -- "Oneiros Digsite"
			["1:0.427980:0.705815"] = { blobID = 56327, map = 121, race = RACE_NIGHTELF }, -- "Dire Maul Digsite"
			["1:0.428008:0.746046"] = { blobID = 56339, map = 121, race = RACE_NIGHTELF }, -- "South Isildien Digsite"
			["1:0.431323:0.724035"] = { blobID = 56341, map = 121, race = RACE_NIGHTELF }, -- "North Isildien Digsite"
			["1:0.434366:0.674429"] = { blobID = 56329, map = 121, race = RACE_NIGHTELF }, -- "Broken Commons Digsite"
			["1:0.438198:0.730965"] = { blobID = 56337, map = 121, race = RACE_NIGHTELF }, -- "Darkmist Digsite"
			["1:0.558606:0.709891"] = { blobID = 55755, map = 141, race = RACE_FOSSIL }, -- "Wyrmbog Fossil Field"
			["1:0.559231:0.684945"] = { blobID = 55757, map = 141, race = RACE_FOSSIL }, -- "Quagmire Fossil Field"
			["1:0.543117:0.801114"] = { blobID = 56364, map = 161, race = RACE_TROLL }, -- "Zul'Farrak Digsite"
			["1:0.543660:0.885734"] = { blobID = 56373, map = 161, race = RACE_FOSSIL }, -- "Dunemaul Fossil Ridge"
			["1:0.545237:0.896740"] = { blobID = 56371, map = 161, race = RACE_TROLL }, -- "Southmoon Ruins Digsite"
			["1:0.554639:0.842079"] = { blobID = 56375, map = 161, race = RACE_FOSSIL }, -- "Abyssal Sands Fossil Ridge"
			["1:0.556432:0.883452"] = { blobID = 56369, map = 161, race = RACE_TROLL }, -- "Eastmoon Ruins Digsite"
			["1:0.568525:0.846115"] = { blobID = 56367, map = 161, race = RACE_TROLL }, -- "Broken Pillar Digsite"
			["1:0.603905:0.379930"] = { blobID = 55412, map = 181, race = RACE_NIGHTELF }, -- "Ruins of Eldarath"
			["1:0.661732:0.352457"] = { blobID = 55414, map = 181, race = RACE_NIGHTELF }, -- "Ruins of Arkkoran"
			["1:0.477519:0.337294"] = { blobID = 56343, map = 182, race = RACE_NIGHTELF }, -- "Constellas Digsite"
			["1:0.477791:0.321805"] = { blobID = 56347, map = 182, race = RACE_NIGHTELF }, -- "Jaedenar Digsite"
			["1:0.496378:0.277090"] = { blobID = 56349, map = 182, race = RACE_NIGHTELF }, -- "Ironwood Digsite"
			["1:0.508687:0.366886"] = { blobID = 56345, map = 182, race = RACE_NIGHTELF }, -- "Morlos'Aran Digsite"
			["1:0.482573:0.840286"] = { blobID = 56384, map = 201, race = RACE_FOSSIL }, -- "Terror Run Fossil Field"
			["1:0.483253:0.796590"] = { blobID = 56386, map = 201, race = RACE_FOSSIL }, -- "Screaming Reaches Fossil Field"
			["1:0.497519:0.784565"] = { blobID = 56382, map = 201, race = RACE_FOSSIL }, -- "Upper Lakkari Tar Pits"
			["1:0.502193:0.796060"] = { blobID = 56380, map = 201, race = RACE_FOSSIL }, -- "Lower Lakkari Tar Pits"
			["1:0.518389:0.830585"] = { blobID = 56388, map = 201, race = RACE_FOSSIL }, -- "Marshlands Fossil Bank"
			["1:0.454122:0.813384"] = { blobID = 56390, map = 261, race = RACE_NIGHTELF }, -- "Southwind Village Digsite"
			["1:0.574177:0.255976"] = { blobID = 56351, map = 281, race = RACE_NIGHTELF }, -- "Lake Kel'Theril Digsite"
			["1:0.592655:0.306642"] = { blobID = 56356, map = 281, race = RACE_NIGHTELF }, -- "Frostwhisper Gorge Digsite"
			["1:0.598036:0.292620"] = { blobID = 56354, map = 281, race = RACE_NIGHTELF }, -- "Owl Wing Thicket Digsite"
			["1:0.510834:0.314223"] = { blobID = 56570, map = 606, race = RACE_NIGHTELF }, -- "Grove of Aessina Digsite"
			["1:0.519774:0.341003"] = { blobID = 56572, map = 606, race = RACE_NIGHTELF }, -- "Sanctuary of Malorne Digsite"
			["1:0.522410:0.305949"] = { blobID = 56568, map = 606, race = RACE_NIGHTELF }, -- "Shrine of Goldrinn Digsite"
			["1:0.546133:0.291234"] = { blobID = 56566, map = 606, race = RACE_NIGHTELF }, -- "Ruins of Lar'donir Digsite"
			["1:0.518117:0.602282"] = { blobID = 56358, map = 607, race = RACE_FOSSIL }, -- "Fields of Blood Fossil Bank"
			["1:0.524584:0.687758"] = { blobID = 55410, map = 607, race = RACE_DWARF }, -- "Bael Modan Digsite"
			["1:0.451513:0.957066"] = { blobID = 56601, map = 720, race = RACE_TOLVIR }, -- "Ruins of Ammon Digsite"
			["1:0.454258:0.899186"] = { blobID = 56605, map = 720, race = RACE_TOLVIR }, -- "Temple of Uldum Digsite"
			["1:0.464801:0.918425"] = { blobID = 56599, map = 720, race = RACE_TOLVIR }, -- "Orsis Digsite"
			["1:0.478932:0.984906"] = { blobID = 56597, map = 720, race = RACE_TOLVIR }, -- "Neferset Digsite"
			["1:0.481242:0.884512"] = { blobID = 60361, map = 720, race = RACE_TOLVIR }, -- "Sahket Wastes Digsite"
			["1:0.490535:0.938357"] = { blobID = 60356, map = 720, race = RACE_TOLVIR }, -- "Akhenet Fields Digsite"
			["1:0.506323:0.886183"] = { blobID = 56591, map = 720, race = RACE_TOLVIR }, -- "Khartut's Tomb Digsite"
			["1:0.506677:0.897433"] = { blobID = 60358, map = 720, race = RACE_TOLVIR }, -- "Obelisk of the Stars Digsite"
			["1:0.508144:0.978751"] = { blobID = 60350, map = 720, race = RACE_TOLVIR }, -- "River Delta Digsite"
			["1:0.530861:0.926699"] = { blobID = 60354, map = 720, race = RACE_TOLVIR }, -- "Keset Pass Digsite" -- blob ?? old one was 56611
			["1:0.539285:0.932202"] = { blobID = 60352, map = 720, race = RACE_TOLVIR }, -- "Cursed Landing Digsite"
			["2:0.488890:0.436740"] = { blobID = 54129, map = 16, race = RACE_DWARF }, -- "Thoradin's Wall"
			["2:0.526469:0.477661"] = { blobID = 54132, map = 16, race = RACE_TROLL }, -- "Witherbark Digsite"
			["2:0.525831:0.635232"] = { blobID = 54838, map = 17, race = RACE_DWARF }, -- "Uldaman Entrance Digsite"
			["2:0.529095:0.647865"] = { blobID = 54832, map = 17, race = RACE_DWARF }, -- "Hammertoe's Digsite"
			["2:0.529365:0.664698"] = { blobID = 54834, map = 17, race = RACE_DWARF }, -- "Tomb of the Watchers Digsite"
			["2:0.515424:0.833798"] = { blobID = 55436, map = 19, race = RACE_FOSSIL }, -- "Dreadmaul Fossil Field"
			["2:0.532311:0.872840"] = { blobID = 55434, map = 19, race = RACE_FOSSIL }, -- "Red Reaches Fossil Bank"
			["2:0.471218:0.365394"] = { blobID = 55482, map = 22, race = RACE_FOSSIL }, -- "Andorhal Fossil Bank"
			["2:0.474630:0.348157"] = { blobID = 55478, map = 22, race = RACE_FOSSIL }, -- "Felstone Fossil Field"
			["2:0.485699:0.325357"] = { blobID = 55480, map = 22, race = RACE_FOSSIL }, -- "Northridge Fossil Field"
			["2:0.516013:0.297438"] = { blobID = 60442, map = 23, race = RACE_NERUBIAN }, -- "Terrorweb Tunnel Digsite"
			["2:0.538079:0.298359"] = { blobID = 60444, map = 23, race = RACE_NERUBIAN }, -- "Plaguewood Digsite"
			["2:0.549026:0.288929"] = { blobID = 55450, map = 23, race = RACE_NIGHTELF }, -- "Quel'Lithien Lodge Digsite"
			["2:0.550131:0.336812"] = { blobID = 55452, map = 23, race = RACE_FOSSIL }, -- "Infectis Scar Fossil Field"
			["2:0.566404:0.287382"] = { blobID = 55448, map = 23, race = RACE_TROLL }, -- "Zul'Mashar Digsite"
			["2:0.468837:0.430073"] = { blobID = 54135, map = 24, race = RACE_FOSSIL }, -- "Southshore Fossil Field"
			["2:0.474016:0.457587"] = { blobID = 54134, map = 24, race = RACE_DWARF }, -- "Dun Garok Digsite"
			["2:0.498463:0.405910"] = { blobID = 54136, map = 26, race = RACE_DWARF }, -- "Aerie Peak Digsite"
			["2:0.498463:0.405910"] = { blobID = 54136, map = 26, race = RACE_DWARF }, -- "Aerie Peak Digsite"
			["2:0.517215:0.423664"] = { blobID = 54137, map = 26, race = RACE_TROLL }, -- "Shadra'Alor Digsite"
			["2:0.528555:0.396444"] = { blobID = 54141, map = 26, race = RACE_TROLL }, -- "Agol'watha Digsite"
			["2:0.529488:0.420533"] = { blobID = 54138, map = 26, race = RACE_TROLL }, -- "Altar of Zul Digsite"
			["2:0.541932:0.427274"] = { blobID = 54140, map = 26, race = RACE_TROLL }, -- "Jintha'Alor Upper City Digsite"
			["2:0.547062:0.424069"] = { blobID = 54139, map = 26, race = RACE_TROLL }, -- "Jintha'Alor Lower City Digsite"
			["2:0.475980:0.660978"] = { blobID = 55440, map = 28, race = RACE_DWARF }, -- "Pyrox Flats Digsite"
			["2:0.492155:0.698253"] = { blobID = 55442, map = 29, race = RACE_DWARF }, -- "Western Ruins of Thaurissan"
			["2:0.498807:0.698105"] = { blobID = 55444, map = 29, race = RACE_DWARF }, -- "Eastern Ruins of Thaurissan"
			["2:0.518835:0.710886"] = { blobID = 55446, map = 29, race = RACE_FOSSIL }, -- "Terror Wing Fossil Field"
			["2:0.448857:0.817149"] = { blobID = 55352, map = 34, race = RACE_FOSSIL }, -- "Vul'Gol Fossil Bank"
			["2:0.457080:0.797333"] = { blobID = 55350, map = 34, race = RACE_NIGHTELF }, -- "Twilight Grove Digsite"
			["2:0.541343:0.620130"] = { blobID = 54097, map = 35, race = RACE_DWARF }, -- "Ironband's Excavation Site"
			["2:0.507029:0.767830"] = { blobID = 55416, map = 36, race = RACE_FOSSIL }, -- "Lakeridge Highway Fossil Bank"
			["2:0.428804:0.840170"] = { blobID = 55456, map = 37, race = RECE_TROLL }, -- "Western Zul'Kunda Digsite"
			["2:0.432240:0.839175"] = { blobID = 55454, map = 37, race = RACE_TROLL }, -- "Eastern Zul'Kunda Digsite"
			["2:0.436756:0.853650"] = { blobID = 55458, map = 37, race = RACE_TROLL }, -- "Bal'lal Ruins Digsite"
			["2:0.440119:0.859691"] = { blobID = 55468, map = 37, race = RACE_FOSSIL }, -- "Savage Coast Raptor Fields"
			["2:0.457301:0.878770"] = { blobID = 55462, map = 37, race = RACE_TROLL }, -- "Ziata'jai Digsite"
			["2:0.462185:0.888089"] = { blobID = 55466, map = 37, race = RACE_TROLL }, -- "Western Zul'Mamwe Digsite"
			["2:0.463707:0.872840"] = { blobID = 55460, map = 37, race = RACE_TROLL }, -- "Balia'mah Digsite"
			["2:0.466701:0.888863"] = { blobID = 55464, map = 37, race = RACE_TROLL }, -- "Eastern Zul'Mamwe Digsite"
			["2:0.488252:0.669339"] = { blobID = 55438, map = 38, race = RACE_DWARF }, -- "Grimsilt Digsite"
			["2:0.540337:0.800427"] = { blobID = 54862, map = 38, race = RACE_TROLL }, -- "Sunken Temple Digsite"
			["2:0.548732:0.813171"] = { blobID = 54864, map = 38, race = RACE_FOSSIL }, -- "Misty Reed Fossil Bank"
			["2:0.490486:0.540093"] = { blobID = 54126, map = 40, race = RACE_DWARF }, -- "Whelgar's Excavation Site"
			["2:0.500402:0.516335"] = { blobID = 54124, map = 40, race = RACE_DWARF }, -- "Ironbeard's Tomb"
			["2:0.506735:0.502891"] = { blobID = 54133, map = 40, race = RACE_DWARF }, -- "Thandol Span"
			["2:0.521069:0.543813"] = { blobID = 54127, map = 40, race = RACE_FOSSIL }, -- "Greenwarden's Fossil Bank"
			["2:0.438327:0.894682"] = { blobID = 55474, map = 673, race = RECE_TROLL }, -- "Gurubashi Arena Digsite"
			["2:0.445519:0.903191"] = { blobID = 55472, map = 673, race = RACE_TROLL }, -- "Ruins of Jubuwal"
			["2:0.453668:0.915198"] = { blobID = 55470, map = 673, race = RACE_TROLL }, -- "Ruins of Aboraz"
			["2:0.560341:0.521087"] = { blobID = 56587, map = 700, race = RACE_DWARF }, -- "Humboldt Conflagration Digsite"
			["2:0.570552:0.584292"] = { blobID = 56583, map = 700, race = RACE_DWARF }, -- "Dunwald Ruins Digsite"
			["2:0.570896:0.533978"] = { blobID = 56585, map = 700, race = RACE_DWARF }, -- "Thundermar Ruins Digsite"
			["3:0.468278:0.545093"] = { blobID = 56400, map = 465, race = RACE_DRAENEI }, -- "Sha'naar Digsite"
			["3:0.559035:0.593964"] = { blobID = 56392, map = 465, race = RACE_ORC }, -- "Gor'gaz Outpost Digsite"
			["3:0.561154:0.525767"] = { blobID = 56396, map = 465, race = RACE_ORC }, -- "Hellfire Basin Digsite"
			["3:0.575068:0.527914"] = { blobID = 56398, map = 465, race = RACE_ORC }, -- "Hellfire Citadel Digsite"
			["3:0.624713:0.584688"] = { blobID = 56394, map = 465, race = RACE_ORC }, -- "Zeth'Gor Digsite"
			["3:0.329479:0.525166"] = { blobID = 56402, map = 467, race = RACE_DRAENEI }, -- "Boha'mu Ruins Digsite"
			["3:0.338583:0.482822"] = { blobID = 56404, map = 467, race = RACE_DRAENEI }, -- "Twin Spire Ruins Digsite"
			["3:0.597114:0.834630"] = { blobID = 56439, map = 473, race = RACE_DRAENEI }, -- "Illidari Point Digsite"
			["3:0.647274:0.756383"] = { blobID = 56441, map = 473, race = RACE_DRAENEI }, -- "Coilskar Point Digsite"
			["3:0.647961:0.882814"] = { blobID = 56448, map = 473, race = RACE_DRAENEI }, -- "Eclipse Point Digsite"
			["3:0.682718:0.783782"] = { blobID = 56446, map = 473, race = RACE_DRAENEI }, -- "Ruins of Baa'ri Digsite"
			["3:0.688788:0.819857"] = { blobID = 56450, map = 473, race = RACE_ORC }, -- "Warden's Cage Digsite"
			["3:0.721254:0.860569"] = { blobID = 56455, map = 473, race = RACE_ORC }, -- "Dragonmaw Fortress"
			["3:0.238263:0.685266"] = { blobID = 56412, map = 477, race = RACE_ORC }, -- "Ancestral Grounds Digsite"
			["3:0.255040:0.631928"] = { blobID = 56416, map = 477, race = RACE_ORC }, -- "Sunspring Post Digsite"
			["3:0.288995:0.635278"] = { blobID = 56422, map = 477, race = RACE_DRAENEI }, -- "Halaa Digsite"
			["3:0.298501:0.565363"] = { blobID = 56418, map = 477, race = RACE_ORC }, -- "Laughing Skull Digsite"
			["3:0.387369:0.716616"] = { blobID = 56420, map = 477, race = RACE_ORC }, -- "Burning Blade Digsite"
			["3:0.400138:0.781807"] = { blobID = 56428, map = 478, race = RACE_ORC }, -- "Bleeding Hollow Ruins Digsite"
			["3:0.452130:0.788678"] = { blobID = 56437, map = 478, race = RACE_DRAENEI }, -- "West Auchindoun Digsite"
			["3:0.460261:0.709917"] = { blobID = 56424, map = 478, race = RACE_ORC }, -- "Grangol'var Village Digsite"
			["3:0.470110:0.786789"] = { blobID = 56434, map = 478, race = RACE_DRAENEI }, -- "East Auchindoun Digsite"
			["3:0.485685:0.768494"] = { blobID = 56432, map = 478, race = RACE_DRAENEI }, -- "Bone Wastes Digsite"
			["3:0.504008:0.680456"] = { blobID = 56426, map = 478, race = RACE_DRAENEI }, -- "Tuurem Digsite"
			["3:0.543174:0.749856"] = { blobID = 56430, map = 478, race = RACE_ORC }, -- "Bonechewer Ruins Digsite"
			["3:0.539567:0.202217"] = { blobID = 56406, map = 479, race = RACE_DRAENEI }, -- "Ruins of Enkaat Digsite"
			["3:0.560123:0.262942"] = { blobID = 56408, map = 479, race = RACE_DRAENEI }, -- "Arklon Ruins Digsite"
			["3:0.600377:0.100351"] = { blobID = 56410, map = 479, race = RACE_DRAENEI }, -- "Ruins of Farahlon Digsite"
			["4:0.194416:0.775830"] = { blobID = 56526, map = 486, race = RACE_NIGHTELF }, -- "Riplash Ruins Digsite"
			["4:0.207485:0.701216"] = { blobID = 60369, map = 486, race = RACE_NERUBIAN }, -- "Sands of Nasam"
			["4:0.261171:0.528075"] = { blobID = 56541, map = 486, race = RACE_NERUBIAN }, -- "Talramas Digsite"
			["4:0.315702:0.564494"] = { blobID = 56522, map = 486, race = RACE_NERUBIAN }, -- "En'kilah Digsite"
			["4:0.385894:0.611983"] = { blobID = 56520, map = 488, race = RACE_NIGHTELF }, -- "Moonrest Gardens Digsite"
			["4:0.398569:0.584352"] = { blobID = 56518, map = 488, race = RACE_NERUBIAN }, -- "Pit of Narjun Digsite"
			["4:0.666998:0.651107"] = { blobID = 56543, map = 490, race = RACE_VRYKUL }, -- "Voldrune Digsite"
			["4:0.793467:0.505175"] = { blobID = 56547, map = 490, race = RACE_TROLL }, -- "Drakil'Jin Ruins Digsite"
			["4:0.720065:0.671641"] = { blobID = 56516, map = 491, race = RACE_VRYKUL }, -- "Gjalerbron Digsite"
			["4:0.751386:0.735270"] = { blobID = 56504, map = 491, race = RACE_VRYKUL }, -- "Skorn Digsite"
			["4:0.769018:0.816474"] = { blobID = 56506, map = 491, race = RACE_VRYKUL }, -- "Halgrind Digsite"
			["4:0.796509:0.809038"] = { blobID = 56508, map = 491, race = RACE_VRYKUL }, -- "Wyrmskull Digsite"
			["4:0.800847:0.902242"] = { blobID = 56510, map = 491, race = RACE_VRYKUL }, -- "Shield Hill Digsite"
			["4:0.816113:0.768901"] = { blobID = 56512, map = 491, race = RACE_VRYKUL }, -- "Baleheim Digsite"
			["4:0.830704:0.815545"] = { blobID = 56514, map = 491, race = RACE_VRYKUL }, -- "Nifflevar Digsite"
			["4:0.282578:0.301614"] = { blobID = 56562, map = 492, race = RACE_VRYKUL }, -- "Jotunheim Digsite"
			["4:0.315082:0.237731"] = { blobID = 56564, map = 492, race = RACE_VRYKUL }, -- "Njorndar Village Digsite"
			["4:0.413722:0.301191"] = { blobID = 56560, map = 492, race = RACE_VRYKUL }, -- "Ymirheim Digsite"
			["4:0.482337:0.286066"] = { blobID = 60367, map = 492, race = RACE_NERUBIAN }, -- "Pit of Fiends Digsite"
			["4:0.577766:0.319359"] = { blobID = 56551, map = 495, race = RACE_VRYKUL }, -- "Sifreldar Village Digsite"
			["4:0.611679:0.306430"] = { blobID = 56549, map = 495, race = RACE_VRYKUL }, -- "Brunnhildar Village Digsite"
			["4:0.719783:0.370312"] = { blobID = 56535, map = 496, race = RACE_TROLL }, -- "Zim'Rhuk Digsite"
			["4:0.722093:0.468586"] = { blobID = 56524, map = 496, race = RACE_NERUBIAN }, -- "Kolramas Digsite"
			["4:0.760625:0.411718"] = { blobID = 56539, map = 496, race = RACE_TROLL }, -- "Altar of Quetz'lun Digsite"
			["4:0.771722:0.348849"] = { blobID = 56537, map = 496, race = RACE_TROLL }, -- "Zol'Heb Digsite"
			["4:0.462113:0.410957"] = { blobID = 56528, map = 510, race = RACE_NIGHTELF }, -- "Violet Stand Digsite"
			["4:0.562049:0.441800"] = { blobID = 56530, map = 510, race = RACE_NIGHTELF }, -- "Ruins of Shandaral Digsite"
			["6:0.611130:0.476351"] = { blobID = 66767, map = 806, race = RACE_PANDAREN }, -- "Tiger's Wood Digsite"
			["6:0.648512:0.473161"] = { blobID = 67023, map = 806, race = RACE_PANDAREN }, -- "Gong of Hope Digsite"
			["6:0.651284:0.629684"] = { blobID = 66890, map = 806, race = RACE_MOGU }, -- "Thunderwood Digsite"
			["6:0.655344:0.401909"] = { blobID = 66784, map = 806, race = RACE_PANDAREN }, -- "Tian Digsite"
			["6:0.669073:0.360724"] = { blobID = 66795, map = 806, race = RACE_MOGU }, -- "Ruins of Gan Shi Digsite"
			["6:0.673584:0.621660"] = { blobID = 67033, map = 806, race = RACE_PANDAREN }, -- "South Orchard Digsite"
			["6:0.677516:0.454985"] = { blobID = 67021, map = 806, race = RACE_PANDAREN }, -- "Forest Heart Digsite"
			["6:0.699043:0.406936"] = { blobID = 66817, map = 806, race = RACE_PANDAREN }, -- "Emperor's Omen Digsite"
			["6:0.699365:0.539386"] = { blobID = 67025, map = 806, race = RACE_PANDAREN }, -- "Great Bridge Digsite"
			["6:0.707937:0.493077"] = { blobID = 66854, map = 806, race = RACE_PANDAREN }, -- "The Arboretum Digsite"
			["6:0.709484:0.457596"] = { blobID = 66789, map = 806, race = RACE_PANDAREN }, -- "Shrine of the Dawn Digsite"
			["6:0.713803:0.558142"] = { blobID = 67031, map = 806, race = RACE_PANDAREN }, -- "Jade Temple Grounds Digsite"
			["6:0.723793:0.507965"] = { blobID = 67027, map = 806, race = RACE_PANDAREN }, -- "Orchard Digsite"
			["6:0.764011:0.661878"] = { blobID = 67035, map = 806, race = RACE_PANDAREN }, -- "Den of Sorrow Digsite"
			["6:0.414292:0.711184"] = { blobID = 66923, map = 807, race = RACE_MOGU }, -- "South Great Wall Digsite"
			["6:0.416677:0.658881"] = { blobID = 66919, map = 807, race = RACE_MOGU }, -- "North Great Wall Digsite"
			["6:0.432596:0.623013"] = { blobID = 66933, map = 807, race = RACE_PANDAREN }, -- "Paoquan Hollow Digsite"
			["6:0.439686:0.734000"] = { blobID = 66925, map = 807, race = RACE_MOGU }, -- "Torjari Pit Digsite"
			["6:0.454188:0.654820"] = { blobID = 66917, map = 807, race = RACE_MOGU }, -- "Singing Marshes Digsite"
			["6:0.473330:0.672319"] = { blobID = 66939, map = 807, race = RACE_PANDAREN }, -- "South Fruited Fields Digsite"
			["6:0.481258:0.635775"] = { blobID = 66935, map = 807, race = RACE_PANDAREN }, -- "North Fruited Fields Digsite"
			["6:0.552929:0.604934"] = { blobID = 66941, map = 807, race = RACE_PANDAREN }, -- "Pools of Purity Digsite"
			["6:0.376523:0.352313"] = { blobID = 66991, map = 809, race = RACE_PANDAREN }, -- "Small Gate Digsite"
			["6:0.398888:0.323212"] = { blobID = 66969, map = 809, race = RACE_MOGU }, -- "Snow Covered Hills Digsite"
			["6:0.411391:0.317218"] = { blobID = 66971, map = 809, race = RACE_MOGU }, -- "East Snow Covered Hills Digsite"
			["6:0.427118:0.300203"] = { blobID = 67005, map = 809, race = RACE_PANDAREN }, -- "Kun-Lai Peak Digsite"
			["6:0.476553:0.470454"] = { blobID = 66967, map = 809, race = RACE_MOGU }, -- "Gate to Golden Valley Digsite"
			["6:0.479647:0.294692"] = { blobID = 66965, map = 809, race = RACE_MOGU }, -- "Valley of Kings Digsite"
			["6:0.491570:0.453632"] = { blobID = 66987, map = 809, race = RACE_PANDAREN }, -- "Chow Farmstead Digsite"
			["6:0.503365:0.234751"] = { blobID = 66973, map = 809, race = RACE_PANDAREN }, -- "Remote Village Digsite"
			["6:0.533722:0.384700"] = { blobID = 66985, map = 809, race = RACE_PANDAREN }, -- "Grumblepaw Ranch Digsite"
			["6:0.537138:0.465717"] = { blobID = 66983, map = 809, race = RACE_PANDAREN }, -- "Old Village Digsite"
			["6:0.542101:0.327176"] = { blobID = 66979, map = 809, race = RACE_PANDAREN }, -- "Destroyed Village Digsite"
			["6:0.173239:0.353570"] = { blobID = 177501, map = 810, race = RACE_MANTID }, -- "Ikz'ka Ridge Digsite"
			["6:0.177107:0.393594"] = { blobID = 177489, map = 810, race = RACE_MANTID }, -- "West Sra'vess Digsite"
			["6:0.179233:0.413704"] = { blobID = 177491, map = 810, race = RACE_MANTID }, -- "The Feeding Pits Digsite"
			["6:0.199987:0.382090"] = { blobID = 177495, map = 810, race = RACE_MANTID }, -- "East Sra'vess Digsite"
			["6:0.201470:0.411287"] = { blobID = 177493, map = 810, race = RACE_MANTID }, -- "Kzzok Warcamp Digsite"
			["6:0.201792:0.347865"] = { blobID = 177487, map = 810, race = RACE_MANTID }, -- "Sra'thik Swarmdock Digsite"
			["6:0.225768:0.253507"] = { blobID = 92196, map = 810, race = RACE_MOGU }, -- "Shanze'Dao Digsite"
			["6:0.240334:0.430719"] = { blobID = 92174, map = 810, race = RACE_PANDAREN }, -- "Niuzao Temple Digsite"
			["6:0.261539:0.516763"] = { blobID = 177505, map = 810, race = RACE_MANTID }, -- "West Sik'vess Digsite"
			["6:0.266695:0.405293"] = { blobID = 92172, map = 810, race = RACE_PANDAREN }, -- "Sra'thik Digsite"
			["6:0.268307:0.503905"] = { blobID = 177507, map = 810, race = RACE_MANTID }, -- "North Sik'vess Digsite"
			["6:0.283582:0.508255"] = { blobID = 177503, map = 810, race = RACE_MANTID }, -- "Sik'vess Digsite"
			["6:0.328699:0.412060"] = { blobID = 177497, map = 810, race = RACE_MANTID }, -- "The Underbough Digsite"
			["6:0.348808:0.361787"] = { blobID = 92178, map = 810, race = RACE_MOGU }, -- "Fire Camp Osul Digsite"
			["6:0.401724:0.458466"] = { blobID = 92180, map = 810, race = RACE_MOGU }, -- "Hatred's Vice Digsite"
			["6:0.431952:0.535132"] = { blobID = 92026, map = 811, race = RACE_PANDAREN }, -- "Five Sisters Digsite"
			["6:0.441168:0.523821"] = { blobID = 92032, map = 811, race = RACE_MOGU }, -- "South Ruins of Guo-Lai Digsite"
			["6:0.442844:0.504195"] = { blobID = 92046, map = 811, race = RACE_MOGU }, -- "West Ruins of Guo-Lai Digsite"
			["6:0.451481:0.551857"] = { blobID = 92150, map = 811, race = RACE_MOGU }, -- "Winterbough Digsite"
			["6:0.457153:0.499651"] = { blobID = 92030, map = 811, race = RACE_MOGU }, -- "North Ruins of Guo-Lai Digsite"
			["6:0.465918:0.571773"] = { blobID = 92022, map = 811, race = RACE_PANDAREN }, -- "Mistfall Village Digsite"
			["6:0.483578:0.549441"] = { blobID = 92156, map = 811, race = RACE_MOGU }, -- "Emperor's Approach Digsite"
			["6:0.484545:0.569260"] = { blobID = 92038, map = 811, race = RACE_MOGU }, -- "Tu Shen Digsite"
			["6:0.543326:0.520630"] = { blobID = 92162, map = 811, race = RACE_MOGU }, -- "North Summer Fields Digsite"
			["6:0.551060:0.536969"] = { blobID = 92166, map = 811, race = RACE_MOGU }, -- "East Summer Fields Digsite"
			["6:0.444907:0.792974"] = { blobID = 66945, map = 857, race = RACE_MOGU }, -- "Ruins of Korja Digsite"
			["6:0.461858:0.762617"] = { blobID = 66943, map = 857, race = RACE_MOGU }, -- "Fallsong Village Digsite"
			["6:0.502334:0.809603"] = { blobID = 66957, map = 857, race = RACE_PANDAREN }, -- "North Temple of the Red Crane Digsite"
			["6:0.508972:0.783500"] = { blobID = 66949, map = 857, race = RACE_MOGU }, -- "Krasarang Wilds Digsite"
			["6:0.539201:0.771318"] = { blobID = 92210, map = 857, race = RACE_MOGU }, -- "South Ruins of Dojan Digsite"
			["6:0.542874:0.753626"] = { blobID = 92212, map = 857, race = RACE_MOGU }, -- "North Ruins of Dojan Digsite"
			["6:0.578517:0.720755"] = { blobID = 66951, map = 857, race = RACE_MOGU }, -- "Lost Dynasty Digsite"
			["6:0.601140:0.688851"] = { blobID = 66961, map = 857, race = RACE_PANDAREN }, -- "Zhu Province Digsite"
			["6:0.250325:0.757590"] = { blobID = 177513, map = 858, race = RACE_MANTID }, -- "Zan'vess Digsite"
			["6:0.261346:0.655980"] = { blobID = 177515, map = 858, race = RACE_MANTID }, -- "Venomous Ledge Digsite"
			["6:0.270692:0.822365"] = { blobID = 177517, map = 858, race = RACE_MANTID }, -- "Amber Quarry Digsite"
			["6:0.303305:0.752369"] = { blobID = 177519, map = 858, race = RACE_MANTID }, -- "The Briny Muck Digsite"
			["6:0.327668:0.556981"] = { blobID = 177485, map = 858, race = RACE_MANTID }, -- "Kor'vess Digsite"
			["6:0.333984:0.637128"] = { blobID = 177509, map = 858, race = RACE_MANTID }, -- "The Clutches of Shek'zeer Digsite"
			["6:0.348228:0.689528"] = { blobID = 177511, map = 858, race = RACE_MANTID }, -- "Kypari'ik Digsite"
			["6:0.368079:0.720659"] = { blobID = 177523, map = 858, race = RACE_MANTID }, -- "Kypari'zar Digsite"
			["6:0.386190:0.573030"] = { blobID = 177529, map = 858, race = RACE_MANTID }, -- "Kypari Vor Digsite"
			["6:0.387673:0.691752"] = { blobID = 177525, map = 858, race = RACE_MANTID }, -- "Lake of Stars Digsite"
			["6:0.398952:0.659654"] = { blobID = 92206, map = 858, race = RACE_MOGU }, -- "Writhingwood Digsite"
			["6:0.400886:0.725589"] = { blobID = 92200, map = 858, race = RACE_MANTID }, -- "Lake of Stars Digsite"
			["6:0.422993:0.580378"] = { blobID = 92202, map = 858, race = RACE_MOGU }, -- "Terrace of Gurthan Digsite"
			["6:0.574327:0.555338"] = { blobID = 66929, map = 873, race = RACE_MOGU }, -- "The Spring Road Digsite"
			["7:0.242496:0.327765"] = { blobID = 307916, map = 941, race = RACE_DRAENOR_CLANS }, -- "Frostboar Drifts Digsite"
			["7:0.266599:0.371771"] = { blobID = 264225, map = 941, race = RACE_DRAENOR_CLANS }, -- "Wor'gol Ridge Digsite"
			["7:0.275440:0.244834"] = { blobID = 264229, map = 941, race = RACE_DRAENOR_CLANS }, -- "Lashwind Cleft Digsite"
			["7:0.276847:0.342082"] = { blobID = 264223, map = 941, race = RACE_DRAENOR_CLANS }, -- "Frozen Lake Digsite"
			["7:0.301478:0.231573"] = { blobID = 264227, map = 941, race = RACE_DRAENOR_CLANS }, -- "Daggermaw Flows Digsite"
			["7:0.316872:0.343533"] = { blobID = 264237, map = 941, race = RACE_DRAENOR_CLANS }, -- "Frostwind Crag Digsite"
			["7:0.354214:0.244702"] = { blobID = 307922, map = 941, race = RACE_DRAENOR_CLANS }, -- "Coldsnap Bluffs Digsite"
			["7:0.357337:0.290951"] = { blobID = 264231, map = 941, race = RACE_DRAENOR_CLANS }, -- "The Crackling Plains Digsite"
			["7:0.363583:0.375729"] = { blobID = 264233, map = 941, race = RACE_DRAENOR_CLANS }, -- "Grom'gar Digsite"
			["7:0.374623:0.316286"] = { blobID = 307918, map = 941, race = RACE_DRAENOR_CLANS }, -- "Icewind Drifts Digsite"
			["7:0.378317:0.236851"] = { blobID = 307920, map = 941, race = RACE_DRAENOR_CLANS }, -- "East Coldsnap Bluffs Digsite"
			["7:0.380517:0.407529"] = { blobID = 308018, map = 941, race = RACE_DRAENOR_CLANS }, -- "Southwind Cliffs Digsite"
			["7:0.370268:0.595823"] = { blobID = 307973, map = 946, race = RACE_OGRE }, -- "Forgotten Ogre Ruin Digsite"
			["7:0.389797:0.665823"] = { blobID = 307971, map = 946, race = RACE_OGRE }, -- "Ango'rosh Digsite"
			["7:0.461974:0.588764"] = { blobID = 307964, map = 946, race = RACE_OGRE }, -- "Duskfall Island Digsite"
			["7:0.465053:0.648471"] = { blobID = 307960, map = 946, race = RACE_OGRE }, -- "Gordal Fortress Digsite"
			["7:0.483174:0.606907"] = { blobID = 307962, map = 946, race = RACE_ARAKKOA }, -- "Veil Shadar Digsite"
			["7:0.499096:0.520875"] = { blobID = 307966, map = 946, race = RACE_OGRE }, -- "Zangarra Digsite"
			["7:0.502351:0.612515"] = { blobID = 307930, map = 947, race = RACE_DRAENOR_CLANS }, -- "Cursed Woods Digsite"
			["7:0.524607:0.664305"] = { blobID = 307928, map = 947, race = RACE_DRAENOR_CLANS }, -- "Anguish Fortress Digsite"
			["7:0.549413:0.767359"] = { blobID = 307924, map = 947, race = RACE_DRAENOR_CLANS }, -- "Shaz'gul Digsite"
			["7:0.559706:0.645238"] = { blobID = 307940, map = 947, race = RACE_DRAENOR_CLANS }, -- "Gloomshade Digsite"
			["7:0.568634:0.746906"] = { blobID = 307926, map = 947, race = RACE_DRAENOR_CLANS }, -- "Burial Fields Digsite"
			["7:0.597795:0.623269"] = { blobID = 307934, map = 947, race = RACE_OGRE }, -- "Umbrafen Digsite"
			["7:0.617544:0.762938"] = { blobID = 307936, map = 947, race = RACE_ARAKKOA }, -- "Shimmering Moor Digsite"
			["7:0.418738:0.766039"] = { blobID = 307948, map = 948, race = RACE_OGRE }, -- "Writhing Mire Digsite"
			["7:0.427447:0.718207"] = { blobID = 307958, map = 948, race = RACE_ARAKKOA }, -- "Apexis Excavation Digsite"
			["7:0.447328:0.711148"] = { blobID = 307946, map = 948, race = RACE_ARAKKOA }, -- "Veil Akraz Digsite"
			["7:0.453309:0.823504"] = { blobID = 307950, map = 948, race = RACE_ARAKKOA }, -- "Bloodmane Pridelands Digsite"
			["7:0.464349:0.806878"] = { blobID = 307954, map = 948, race = RACE_ARAKKOA }, -- "Bloodmane Valley Digsite"
			["7:0.474949:0.867443"] = { blobID = 307952, map = 948, race = RACE_ARAKKOA }, -- "Pinchwhistle Point Digsite"
			["7:0.492235:0.796520"] = { blobID = 307956, map = 948, race = RACE_ARAKKOA }, -- "Veil Zekk Digsite"
			["7:0.499360:0.749875"] = { blobID = 307944, map = 948, race = RACE_ARAKKOA }, -- "Sethekk Hollow North Digsite"
			["7:0.513303:0.773231"] = { blobID = 307942, map = 948, race = RACE_ARAKKOA }, -- "Sethekk Hollow South Digsite"
			["7:0.458060:0.365833"] = { blobID = 308005, map = 949, race = RACE_OGRE }, -- "Deadgrin Ruins Digsite" -- race??
			["7:0.474597:0.356333"] = { blobID = 308007, map = 949, race = RACE_OGRE }, -- "The Broken Spine Digsite"
			["7:0.498524:0.393081"] = { blobID = 308015, map = 949, race = RACE_OGRE }, -- "Ruins of the First Bastion Digsite"
			["7:0.500724:0.364250"] = { blobID = 308011, map = 949, race = RACE_OGRE }, -- "Overlook Ruins Digsite"
			["7:0.522232:0.293722"] = { blobID = 308013, map = 949, race = RACE_OGRE }, -- "Wildwood Wash Dam Digsite"
			["7:0.225739:0.548585"] = { blobID = 307987, map = 950, race = RACE_DRAENOR_CLANS }, -- "Ancestral Grounds Digsite"
			["7:0.247247:0.557029"] = { blobID = 307983, map = 950, race = RACE_DRAENOR_CLANS }, -- "North Spirit Woods Digsite"
			["7:0.254680:0.512232"] = { blobID = 307975, map = 950, race = RACE_OGRE }, -- "Ruins of Na'gwa Digsite"
			["7:0.258154:0.586718"] = { blobID = 307985, map = 950, race = RACE_DRAENOR_CLANS }, -- "Kag'ah Digsite"
			["7:0.266863:0.472119"] = { blobID = 308001, map = 950, race = RACE_OGRE }, -- "Highmaul Watchtower Digsite"
			["7:0.291098:0.541459"] = { blobID = 307981, map = 950, race = RACE_OGRE }, -- "Stonecrag Excavation Digsite"  -- 13 digs
			["7:0.295101:0.439066"] = { blobID = 307997, map = 950, race = RACE_DRAENOR_CLANS }, -- "Burning Plateau Digsite"
			["7:0.303194:0.521007"] = { blobID = 307979, map = 950, race = RACE_DRAENOR_CLANS }, -- "Razed Warsong Outpost Digsite"
			["7:0.316213:0.441111"] = { blobID = 307995, map = 950, race = RACE_DRAENOR_CLANS }, -- "Drowning Plateau Digsite"
			["7:0.318060:0.529386"] = { blobID = 307989, map = 950, race = RACE_DRAENOR_CLANS }, -- "Ring of Trials Sludge Digsite"
			["7:0.327604:0.471064"] = { blobID = 307991, map = 950, race = RACE_DRAENOR_CLANS }, -- "Howling Plateau Digsite"
			["7:0.328220:0.587840"] = { blobID = 308003, map = 950, race = RACE_OGRE }, -- "Mar'gok's Overwatch Digsite"
			["7:0.329540:0.452525"] = { blobID = 307993, map = 950, race = RACE_DRAENOR_CLANS }, -- "Rumbling Plateau Digsite"
		}

		local sidjiDataByBlobID = {}
		for siteKey, site in pairs(sidjiData) do
			site.siteKey = siteKey
			sidjiDataByBlobID[site.blobID] = site
		end

		local sortedSites = {}

		for siteKey, site in pairs(DIG_SITES) do
			local sidjiSite = sidjiDataByBlobID[site.blob_id]
			local newSite

			if sidjiSite then
				local continentID = (":"):split(sidjiSite.siteKey)

				newSite = {
					blobID = site.blob_id,
					continentID = tonumber(continentID),
					mapID = site.map,
					typeID = site.race,
					siteKey = sidjiSite.siteKey,
					siteName = siteKey,
				}
			else
				newSite = {
					blobID = site.blob_id,
					continentID = site.continent,
					mapID = site.map,
					typeID = site.race,
					siteKey = siteKey,
					siteName = siteKey,
					isOld = true,
				}
			end

			sortedSites[#sortedSites + 1] = newSite
		end

		local function SortByContinentIDThenByName(a, b)
			if a.continentID == b.continentID then
				return a.siteName < b.siteName
			end

			return a.continentID < b.continentID
		end

		table.sort(sortedSites, SortByContinentIDThenByName)

		local currentContinentIndex = 0
		local separatorBar = "-----------------------------------------------------------------------"

		local continentName = {
			"Kalimdor",
			"Eastern Kingdoms",
			"Outland",
			"Northrend",
			"",
			"Pandaria",
			"Draenor",
		}
		Debug("local DIG_SITES = {")
		for index = 1, #sortedSites do
			local site = sortedSites[index]

			if site.continentID ~= currentContinentIndex then
				Debug("%s%s\n-- %s\n%s", currentContinentIndex == 0 and "" or "\n", separatorBar, continentName[site.continentID], separatorBar)

				currentContinentIndex = site.continentID
			end

			if site.isOld then
				Debug("[DS[\"%s\"]] = {\nblobID = %d,\ncontinentID = %d,\nmapID = %d,\ntypeID = DigsiteRaces.%s,\n},", site.siteKey, site.blobID, site.continentID, site.mapID, private.DigsiteRaceLabelFromID[site.typeID])
			else
				Debug("[\"%s\"] = { -- %s\nblobID = %d,\nmapID = %d,\ntypeID = DigsiteRaces.%s,\n},", site.siteKey, site.siteName, site.blobID, site.mapID, private.DigsiteRaceLabelFromID[site.typeID])
			end
		end
		Debug("}")

	end

	-- @end-debug@
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
	if not private.current_continent or not HasArchaeology() then
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

	if force then
		_G.RequestArtifactCompletionHistory()
	end

	if _G.GetCurrentMapAreaID() == -1 then
		self:UpdateSiteDistances()
		DigSiteFrame:UpdateChrome()
		self:RefreshDigSiteDisplay()
		return
	end
	local map, level, x, y = Astrolabe:GetCurrentPlayerPosition()

	if not map or not level or (x == 0 and y == 0) then
		return
	end

	if force or player_position.x ~= x or player_position.y ~= y or player_position.map ~= map or player_position.level ~= level then
		player_position.x, player_position.y, player_position.map, player_position.level = x, y, map, level

		self:UpdateSiteDistances()
		UpdateDistanceIndicator()
		UpdateMinimapPOIs()
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

	if _G.GetNumArchaeologyRaces() > 0 then
		for raceID = 1, _G.GetNumArchaeologyRaces() do
			private.Races[raceID]:UpdateArtifact()
		end
		ArtifactFrame:UpdateChrome()
		ArtifactFrame:RefreshDisplay()
	end

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

	local function UpdateDigsiteCounter(numFindsCompleted)
		Archy.db.char.digsites.stats[lastSite.id].counter = numFindsCompleted
	end

	function Archy:ARCHAEOLOGY_FIND_COMPLETE(eventName, numFindsCompleted, totalFinds)
		UpdateDigsiteCounter(numFindsCompleted)
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
		self.db.char.digsites.stats[lastSite.id].surveys = self.db.char.digsites.stats[lastSite.id].surveys + 1

		DistanceIndicatorFrame.isActive = true
		DistanceIndicatorFrame:Toggle()
		UpdateDistanceIndicator()

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

		if private.db.minimap.fragmentColorBySurveyDistance then
			local min_green, max_green = 0, private.db.digsite.distanceIndicator.green or 0
			local min_yellow, max_yellow = max_green, private.db.digsite.distanceIndicator.yellow or 0
			local min_red, max_red = max_yellow, 500

			for poi in pairs(PointsOfInterest) do
				if poi.type == "survey" then
					local distance = Astrolabe:GetDistanceToIcon(poi) or 0

					if distance >= min_green and distance <= max_green then
						poi.icon:SetTexCoord(0.75, 1, 0.5, 0.734375)
					elseif distance >= min_yellow and distance <= max_yellow then
						poi.icon:SetTexCoord(0.5, 0.734375, 0.5, 0.734375)
					elseif distance >= min_red and distance <= max_red then
						poi.icon:SetTexCoord(0.25, 0.484375, 0.5, 0.734375)
					end
				end
			end
		end
		TomTomHandler.isActive = false
		TomTomHandler:Refresh(nearestSite)

		UpdateDigsiteCounter(numFindsCompleted)
		self:RefreshDigSiteDisplay()
	end
end

do
	local function UpdateAndRefresh(race)
		race:UpdateArtifact()
		ArtifactFrame:RefreshDisplay()
	end

	function Archy:ARTIFACT_COMPLETE(event, name)
		for raceID, race in pairs(private.Races) do
			local artifact = race.artifact

			if artifact and artifact.name == name then
				artifact.hasAnnounced = nil
				artifact.hasPinged = nil

				race:UpdateArtifact()
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
	for raceID, race in pairs(private.Races) do
		local artifact = race.artifact

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
	private.Races[keystoneLootRaceID]:UpdateArtifact()
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
		local race_id = keystoneIDToRaceID[itemID]

		if race_id then
			if lastSite.id then
				self.db.char.digsites.stats[lastSite.id].keystones = self.db.char.digsites.stats[lastSite.id].keystones + 1
			end
			keystoneLootRaceID = race_id
		end
	end
end -- do-block

function Archy:CURRENCY_DISPLAY_UPDATE()
	local raceCount = _G.GetNumArchaeologyRaces()

	if not private.current_continent or raceCount == 0 then
		return
	end

	for raceID = 1, raceCount do
		local race = private.Races[raceID]
		local _, _, _, currency_amount = _G.GetArchaeologyRaceInfo(raceID)
		local diff = currency_amount - (race.currency or 0)

		race.currency = currency_amount
		race:UpdateArtifact()

		if diff < 0 then
			-- we've spent fragments, aka. Solved an artifact
			race.artifact.keystones_added = 0

			if artifactSolved.raceId == race.id then
				local _, _, completionCount = race:GetArtifactCompletionDataByName(artifactSolved.name)
				self:Pour(L["You have solved |cFFFFFF00%s|r Artifact - |cFFFFFF00%s|r (Times completed: %d)"]:format(race.name, artifactSolved.name, completionCount or 0), 1, 1, 1)

				artifactSolved.raceId = 0
				artifactSolved.name = ""
			end

		elseif diff > 0 then
			-- we've gained fragments, aka. Successfully dug at a dig site
			local siteStats = self.db.char.digsites.stats

			DistanceIndicatorFrame.isActive = false
			DistanceIndicatorFrame:Toggle()

			-- Drii: for now let's just avoid the error
			-- TODO: Figure out why the fuck this was done. Burying errors instead of figureout out and fixing their cause is...WTF?!?
			if type(lastSite.id) == "number" and lastSite.id > 0 then
				siteStats[lastSite.id].looted = (siteStats[lastSite.id].looted or 0) + 1
				siteStats[lastSite.id].fragments = siteStats[lastSite.id].fragments + diff

				AddSurveyNode(lastSite.id, player_position.map, player_position.level, player_position.x, player_position.y)
			end
			survey_location.map = 0
			survey_location.level = 0
			survey_location.x = 0
			survey_location.y = 0

			UpdateMinimapPOIs(true)
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
	else
		-- store our visible state to restore after pet battle
		private.pet_battle_shown = true
		private.db.general.show = false
		self:ConfigUpdated()
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

function Archy:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	if unit == "player" and spell == private.CRATE_SPELL_NAME then
		private.busy_crating = true
	end
end
