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

local MAP_FILENAME_TO_MAP_ID = {} -- Popupated in Archy:OnInitialize()
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
			filter_continent = false,
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
local QUEST_ITEM_IDS = {
	[79049] = true
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

local distanceIndicatorActive = false
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

-----------------------------------------------------------------------
-- Function upvalues
-----------------------------------------------------------------------
local Blizzard_SolveArtifact
local UpdateMinimapPOIs
local UpdateAllSites

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
	private.digsite_frame:Hide()
	private.races_frame:Hide()
end

local function ShowFrames()
	if private.in_combat or private.FramesShouldBeHidden() then
		return
	end
	private.digsite_frame:Show()
	private.races_frame:Show()
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

local function ToggleDistanceIndicator()
	if IsTaintable() then
		private.regen_toggle_distance = true
		return
	end

	if not private.db.digsite.distanceIndicator.enabled or private.FramesShouldBeHidden() then
		private.distance_indicator_frame:Hide()
		return
	end
	private.distance_indicator_frame:Show()

	if distanceIndicatorActive then
		private.distance_indicator_frame.circle:SetAlpha(1)
	else
		private.distance_indicator_frame.circle.distance:SetText("0")
		if private.db.digsite.distanceIndicator.undocked and not private.db.general.locked and (private.db.digsite.distanceIndicator.showSurveyButton or private.db.digsite.distanceIndicator.showCrateButton or private.db.digsite.distanceIndicator.showLorItemButton) then
			private.distance_indicator_frame.circle:SetAlpha(0.25)
		else
			private.distance_indicator_frame.circle:SetAlpha(0)
		end
	end

	if private.db.digsite.distanceIndicator.showSurveyButton then
		private.distance_indicator_frame.surveyButton:Show()
		private.distance_indicator_frame:SetWidth(52 + private.distance_indicator_frame.surveyButton:GetWidth())
	else
		private.distance_indicator_frame.surveyButton:Hide()
		private.distance_indicator_frame:SetWidth(42)
	end

	if private.db.digsite.distanceIndicator.showCrateButton then
		private.distance_indicator_frame.crateButton:Show()
		local w = private.distance_indicator_frame:GetWidth()
		private.distance_indicator_frame:SetWidth(w + 10 + private.distance_indicator_frame.crateButton:GetWidth())
	else
		private.distance_indicator_frame.crateButton:Hide()
	end

	if private.db.digsite.distanceIndicator.showLorItemButton then
		private.distance_indicator_frame.loritemButton:Show()
		local w = private.distance_indicator_frame:GetWidth()
		private.distance_indicator_frame:SetWidth(w + 10 + private.distance_indicator_frame.loritemButton:GetWidth())
	else
		private.distance_indicator_frame.loritemButton:Hide()
	end
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
			Archy:RefreshRacesDisplay()
		else
			Archy:UpdateRacesFrame()
			Archy:RefreshRacesDisplay()
			Archy:SetFramePosition(private.races_frame)
		end
	end,
	digsite = function(option)
		if option == "tooltip" then
			UpdateAllSites()
		end
		Archy:UpdateSiteDistances()
		Archy:UpdateDigSiteFrame()

		if option == "font" then
			Archy:ResizeDigSiteDisplay()
		else
			Archy:RefreshDigSiteDisplay()
		end
		Archy:SetFramePosition(private.digsite_frame)
		Archy:SetFramePosition(private.distance_indicator_frame)
		ToggleDistanceIndicator()
	end,
	minimap = function(option)
		UpdateMinimapPOIs(true)
	end,
	tomtom = function(option)
		local db = private.db
		local handler = private.TomTomHandler
		handler.hasTomTom = (_G.TomTom and _G.TomTom.AddZWaypoint and _G.TomTom.RemoveWaypoint) and true or false

		if handler.hasTomTom and db.tomtom.enabled then
			if _G.TomTom.profile then
				_G.TomTom.profile.arrow.arrival = db.tomtom.distance
				_G.TomTom.profile.arrow.enablePing = db.tomtom.ping
			end
		end
		handler:Refresh(nearestSite)
	end,
}

function Archy:ConfigUpdated(namespace, option)
	if namespace then
		CONFIG_UPDATE_FUNCTIONS[namespace](option)
	else
		self:UpdateRacesFrame()
		self:RefreshRacesDisplay()
		self:UpdateDigSiteFrame()
		self:RefreshDigSiteDisplay()
		self:UpdateTracking()

		ToggleDistanceIndicator()
		UpdateMinimapPOIs(true)
		SuspendClickToMove()

		private.TomTomHandler:Refresh(nearestSite)
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
	Archy:RefreshRacesDisplay()
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

function UpdateAllSites()
	-- Set this for restoration at the end of the loop, since it's changed every iteration.
	local originalMapID = _G.GetCurrentMapAreaID()

	if next(MAP_CONTINENTS) then
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
					local site = DIG_SITES[landmarkName]
					local mapID = site.map
					local _, mapFilePath = _G.UpdateMapHighlight(mapPositionX, mapPositionY)
					local mc, fc = Astrolabe:GetMapID(continentID, 0)
					local x, y = Astrolabe:TranslateWorldMapPosition(mc, fc, mapPositionX, mapPositionY, mapID, 0)

					table.insert(sites, {
						continent = mc,
						distance = 999999,
						id = site.blob_id,
						level = 0,
						mapFile = mapFilePath,
						map = mapID,
						name = landmarkName,
						raceId = site.race,
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
		private.TomTomHandler.isActive = true
		private.TomTomHandler:Refresh(nearestSite)
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

local DISTANCE_COLOR_TEXCOORDS = {
	green = {
		0, 0.24609375, 0, 1
	},
	yellow = {
		0.24609375, 0.5, 0, 1
	},
	red = {
		0.5, 0.75, 0, 1
	},
}
local function SetDistanceIndicatorColor(color)
	private.distance_indicator_frame.circle.texture:SetTexCoord(unpack(DISTANCE_COLOR_TEXCOORDS[color]))
	private.distance_indicator_frame.circle:SetAlpha(1)
	ToggleDistanceIndicator()
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
		SetDistanceIndicatorColor("green")
	elseif distance >= yellowMin and distance <= yellowMax then
		SetDistanceIndicatorColor("yellow")
	elseif distance >= redMin and distance <= redMax then
		SetDistanceIndicatorColor("red")
	else
		ToggleDistanceIndicator()
		return
	end
	private.distance_indicator_frame.circle.distance:SetFormattedText("%1.f", distance)
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
	self:SetFramePosition(private.distance_indicator_frame)
	self:SetFramePosition(private.digsite_frame)
	self:SetFramePosition(private.races_frame)
end

local timer_handle

function Archy:OnEnable()
	-- Ignore this event for now as it's can break other Archaeology UIs
	-- Would have been nice if Blizzard passed the race index or artifact name with the event
	--    self:RegisterEvent("ARTIFACT_UPDATE")
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

	local handler = private.TomTomHandler
	handler.isActive = true
	handler.hasTomTom = (_G.TomTom and _G.TomTom.AddZWaypoint and _G.TomTom.RemoveWaypoint) and true or false
	handler.hasPOIIntegration = handler.hasTomTom and (_G.TomTom.profile and _G.TomTom.profile.poi and _G.TomTom.EnableDisablePOIIntegration) and true or false

	for raceID = 1, _G.GetNumArchaeologyRaces() do
		local race = self:AddRace(raceID)
		if race then
			keystoneIDToRaceID[race.keystone.id] = raceID
		end
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
			local mapFileName = _G.GetMapInfo()

			MAP_CONTINENTS[continentID] = continentName
			MAP_FILENAME_TO_MAP_ID[mapFileName] = mapID
			MAP_ID_TO_ZONE_NAME[mapID] = continentName
			private.MAP_ID_TO_CONTINENT_ID[mapID] = continentID

			ZONE_DATA[mapID] = {
				continent = continentID,
				id = 0,
				level = 0,
				map = mapID,
				mapFile = mapFileName,
				name = continentName
			}

			local zoneData = { _G.GetMapZones(continentID) }
			for zoneDataIndex = 1, #zoneData do
				-- Odd indices are IDs, even are names.
				if zoneDataIndex % 2 == 0 then
					_G.SetMapByID(mapID)

					local mapFileName = _G.GetMapInfo()
					local zoneID = _G.GetCurrentMapZone()
					local zoneName = zoneData[zoneDataIndex]

					MAP_FILENAME_TO_MAP_ID[mapFileName] = mapID
					MAP_ID_TO_ZONE_ID[mapID] = zoneID
					MAP_ID_TO_ZONE_NAME[mapID] = zoneName
					ZONE_ID_TO_NAME[zoneID] = zoneName
					ZONE_DATA[mapID] = {
						continent = continentID,
						id = zoneID,
						level = _G.GetCurrentMapDungeonLevel(),
						map = mapID,
						mapFile = mapFileName,
						name = zoneName
					}
				else
					mapID = zoneData[zoneDataIndex]
				end
			end
		end
	end
end

function Archy:OnDisable()
	self:CancelTimer(timer_handle)
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

	-- 'OnNewProfile' fires for fresh installations too it seems.
	if private.frames_init_done then
		self:ConfigUpdated()
		self:UpdateFramePositions()
	end
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
		private.TomTomHandler:Refresh(nearestSite)
	end,
	test = function()
		private.races_frame:SetBackdropBorderColor(1, 1, 1, 0.5)
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
				local landmarkName, _, textureIndex, x, y = _G.GetMapLandmarkInfo(landmarkIndex)

				if textureIndex == DIG_LOCATION_TEXTURE_INDEX then
					local siteKey = ("%d:%f:%f"):format(_G.GetCurrentMapContinent(), x, y)

					if not sites[siteKey] then
						Debug(("%s {blobID=,map=,race=} -- \"%s\""):format(siteKey, landmarkName))
						sites[siteKey] = true
						found = found + 1
					end
				end
			end
		end
		Debug(("%d found"):format(found))

		_G.SetMapByID(currentMapID)
	end,
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
		local crateButton = private.distance_indicator_frame.crateButton

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
		local loreItemButton = private.distance_indicator_frame.loritemButton

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
	local races_frame = private.races_frame

	if not races_frame or not races_frame.skillBar then
		return
	end
	local rank, maxRank = GetArchaeologyRank()

	races_frame.skillBar:SetMinMaxValues(0, maxRank)
	races_frame.skillBar:SetValue(rank)
	races_frame.skillBar.text:SetFormattedText("%s : %d/%d", _G.GetArchaeologyInfo(), rank, maxRank)
end

--[[ Positional functions ]] --
function Archy:UpdatePlayerPosition(force)
	if not private.db.general.show and not force then
		return
	end

	if not HasArchaeology() or _G.IsInInstance() or _G.UnitIsGhost("player") then
		return
	end

	if force then
		_G.RequestArtifactCompletionHistory()
	end

	if not private.frames_init_done then
		return
	end

	if _G.GetCurrentMapAreaID() == -1 then
		self:UpdateSiteDistances()
		self:UpdateDigSiteFrame()
		self:RefreshDigSiteDisplay()
		return
	end
	local map, level, x, y = Astrolabe:GetCurrentPlayerPosition()

	if not map or not level or (x == 0 and y == 0) then
		return
	end

	if player_position.x ~= x or player_position.y ~= y or player_position.map ~= map or player_position.level ~= level or force then
		player_position.x, player_position.y, player_position.map, player_position.level = x, y, map, level

		self:RefreshAll()
	end
	local continentID = _G.GetCurrentMapContinent()

	if private.current_continent == continentID then
		if force then
			if private.current_continent then
				UpdateAllSites()
				ToggleDistanceIndicator()
			elseif not continentID then
				-- Edge case where continent and private.current_continent are both nil
				self:ScheduleTimer("UpdatePlayerPosition", 1, true)
			end
		end
		return
	end
	private.current_continent = continentID

	if force then
		ToggleDistanceIndicator()
	end

	private.TomTomHandler:ClearWaypoint()
	private.TomTomHandler:Refresh(nearestSite)
	UpdateAllSites()

	if _G.GetNumArchaeologyRaces() > 0 then
		for raceID = 1, _G.GetNumArchaeologyRaces() do
			private.Races[raceID]:UpdateArtifact()
		end
		self:UpdateRacesFrame()
		self:RefreshRacesDisplay()
	end

	if force then
		self:UpdateSiteDistances()
	end
	self:UpdateDigSiteFrame()
	self:RefreshDigSiteDisplay()
	self:UpdateFramePositions()
end

function Archy:RefreshAll()
	if not _G.IsInInstance() then
		self:UpdateSiteDistances()
		UpdateDistanceIndicator()
		UpdateMinimapPOIs()
	end
	self:RefreshDigSiteDisplay()
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
function Archy:ADDON_LOADED(event, addon)
	if addon == "Blizzard_BattlefieldMinimap" then
		InitializeBattlefieldDigsites()
		self:UnregisterEvent("ADDON_LOADED")
	end
end

do
	local function UpdateAndRefresh(race)
		race:UpdateArtifact()
		Archy:RefreshRacesDisplay()
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
	self:RefreshRacesDisplay()
end

function Archy:BAG_UPDATE_DELAYED()
	self:ScanBags()

	if not private.current_continent or not keystoneLootRaceID then
		return
	end
	private.Races[keystoneLootRaceID]:UpdateArtifact()
	self:RefreshRacesDisplay()
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
			local site_stats = self.db.char.digsites.stats

			distanceIndicatorActive = false
			ToggleDistanceIndicator()

			-- Drii: for now let's just avoid the error
			-- TODO: Figure out why the fuck this was done. Burying errors instead of figureout out and fixing their cause is...WTF?!?
			if type(lastSite.id) == "number" and lastSite.id > 0 then
				-- Only increment when digging; not when looting from world objects.
				if private.has_dug then
					local siteStats = Archy.db.char.digsites.stats
					siteStats[lastSite.id].counter = (siteStats[lastSite.id].counter or 0) + 1
					private.has_dug = nil
				end
				site_stats[lastSite.id].looted = (site_stats[lastSite.id].looted or 0) + 1
				site_stats[lastSite.id].fragments = site_stats[lastSite.id].fragments + diff

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
	self:RefreshRacesDisplay()
end

function Archy:GET_ITEM_INFO_RECEIVED(event)
	for raceID, keystoneItemID in next, private.RaceKeystoneProcessingQueue, nil do
		local keystoneName, _, _, _, _, _, _, _, _, keystoneTexture, _ = _G.GetItemInfo(keystoneItemID)
		if keystoneName and keystoneTexture then
			private.Races[raceID]:SetKeystoneNameAndTexture(keystoneName, keystoneTexture)
		end
	end

	if not next(private.RaceKeystoneProcessingQueue) then
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
	end
end

function Archy:LOOT_OPENED(event, ...)
	local auto_loot_enabled = ...

	if not private.db.general.autoLoot or auto_loot_enabled == 1 then
		return
	end

	for slot_id = 1, _G.GetNumLootItems() do
		local slot_type = _G.GetLootSlotType(slot_id)

		if slot_type == _G.LOOT_SLOT_CURRENCY then
			_G.LootSlot(slot_id)
		elseif slot_type == _G.LOOT_SLOT_ITEM then
			local link = _G.GetLootSlotLink(slot_id)

			if link then
				local item_id = GetIDFromLink(link)

				if item_id and (keystoneIDToRaceID[item_id] or QUEST_ITEM_IDS[item_id]) then
					_G.LootSlot(slot_id)
				end
			end
		end
	end
end

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
	_G.SetMapToCurrentZone()

	-- Two timers are needed here: If we force a call to UpdatePlayerPosition() too soon, the site distances will not update properly and the notifications may vanish just as the player is able to see them.
	if not timer_handle then
		self:ScheduleTimer(function()
			if private.frames_init_done then
				self:UpdateDigSiteFrame()
				self:UpdateRacesFrame()
			end
			timer_handle = self:ScheduleRepeatingTimer("UpdatePlayerPosition", 0.2)
		end, 1)
	end
	self:ScheduleTimer("UpdatePlayerPosition", 2, true)

	-- If TomTom is configured to automatically set a waypoint to the closest quest objective, that will interfere with Archy. Warn, if applicable.
	if private.TomTomHandler.hasPOIIntegration and _G.TomTom.profile.poi.setClosest then
		private.TomTomHandler:DisplayConflictError()
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
		ToggleDistanceIndicator()
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
		self:UpdateDigSiteFrame()
	end

	if private.regen_update_races then
		private.regen_update_races = nil
		self:UpdateRacesFrame()
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

	if private.frames_init_done then
		self:ConfigUpdated()
	end
	self:UnregisterEvent("QUEST_LOG_UPDATE")
	self.QUEST_LOG_UPDATE = nil
end

do
	local function SetLoreItemCooldown(time)
		_G.CooldownFrame_SetTimer(private.distance_indicator_frame.loritemButton.cooldown, _G.GetItemCooldown(LOREWALKER_ITEMS.MAP.id))
	end

	local function SetSurveyCooldown(time)
		_G.CooldownFrame_SetTimer(private.distance_indicator_frame.surveyButton.cooldown, _G.GetSpellCooldown(SURVEY_SPELL_ID))
	end

	function Archy:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank, line_id, spell_id)
		if unit ~= "player" then
			return
		end

		if spell_id == LOREWALKER_ITEMS.MAP.spell and event == "UNIT_SPELLCAST_SUCCEEDED" then
			if private.distance_indicator_frame.loritemButton and private.distance_indicator_frame.loritemButton:IsShown() then
				self:ScheduleTimer(SetLoreItemCooldown, 0.2)
			end
		end

		if spell_id == private.CRATE_SPELL_ID then
			if private.busy_crating then
				private.busy_crating = nil
				self:ScheduleTimer("ScanBags", 1)
			end
		end

		if spell_id == SURVEY_SPELL_ID and event == "UNIT_SPELLCAST_SUCCEEDED" then
			private.has_dug = true
			if not player_position or not nearestSite then
				survey_location.map = 0
				survey_location.level = 0
				survey_location.x = 0
				survey_location.y = 0
				return
			end
			survey_location.x = player_position.x
			survey_location.y = player_position.y
			survey_location.map = player_position.map
			survey_location.level = player_position.level

			distanceIndicatorActive = true
			lastSite = nearestSite
			self.db.char.digsites.stats[lastSite.id].surveys = self.db.char.digsites.stats[lastSite.id].surveys + 1

			ToggleDistanceIndicator()
			UpdateDistanceIndicator()

			if private.distance_indicator_frame.surveyButton and private.distance_indicator_frame.surveyButton:IsShown() then
				local now = _G.GetTime()
				local start, duration, enable = _G.GetSpellCooldown(SURVEY_SPELL_ID)

				if start > 0 and duration > 0 and now < (start + duration) then
					if duration <= GLOBAL_COOLDOWN_TIME then
						self:ScheduleTimer(SetSurveyCooldown, (start + duration) - now)
					elseif duration > GLOBAL_COOLDOWN_TIME then -- in case they ever take it off the gcd
					_G.CooldownFrame_SetTimer(private.distance_indicator_frame.surveyButton.cooldown, start, duration, enable)
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
			private.TomTomHandler.isActive = false
			private.TomTomHandler:Refresh(nearestSite)
			self:RefreshDigSiteDisplay()
		end
	end
end -- do-block

function Archy:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	if unit == "player" and spell == private.CRATE_SPELL_NAME then
		private.busy_crating = true
	end
end
