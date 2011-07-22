-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

local math = _G.math
local table = _G.table

local pairs = _G.pairs
local setmetatable = _G.setmetatable
local tonumber = _G.tonumber
local tostring = _G.tostring
local unpack = _G.unpack

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LibStub = _G.LibStub

local Archy = LibStub("AceAddon-3.0"):NewAddon("Archy", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0", "LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Archy", false)

local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("Archy", {
	type = "data source",
	icon = "Interface\\Icons\\trade_archaeology",
	iconCoords = { 0.075, 0.925, 0.075, 0.925 },
	text = "Archy",
})
local LDBI = LibStub("LibDBIcon-1.0")
local astrolabe = _G.DongleStub("Astrolabe-1.0")
local qtip = LibStub("LibQTip-1.0")
local LSM = LibStub("LibSharedMedia-3.0")

if not LSM then
	_G.LoadAddOn("LibSharedMedia-3.0")
	LSM = LibStub("LibSharedMedia-3.0", true)
end

local DEFAULT_LSM_FONT = "Arial Narrow"
if LSM then
	if not LSM:IsValid("font", DEFAULT_LSM_FONT) then
		DEFAULT_LSM_FONT = LSM:GetDefault("font")
	end
end

_G["Archy"] = Archy
Archy.version = _G.GetAddOnMetadata("Archy", "Version")

-----------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------
local MAX_ARCHAEOLOGY_RANK = 525
local SITES_PER_CONTINENT = 4
local SURVEY_SPELL_ID = 80451

local DIG_SITES = private.dig_sites

-- Populated later.
local ARTIFACT_NAME_TO_RACE_ID_MAP = {}

-----------------------------------------------------------------------
-- Variables
-----------------------------------------------------------------------
local rank, maxRank
local confirmArgs
local raceDataLoaded = false
local archRelatedBagUpdate = false
local keystoneLootRaceID
local playerContinent
local siteStats
local blacklisted_sites
local zoneData, artifacts, digsites = {}, {}, {}
local tomtomPoint, tomtomActive, tomtomFrame, tomtomSite
local distanceIndicatorActive = false

local nearestSite
local lastSite = {}

local playerPosition = {
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

local artifactSolved = {
	raceId = 0,
	name = ""
}

local continentMapToID = {}
local mapFileToID = {}
local mapIDToZone = {}
local mapIDToZoneName = {}
local zoneIDToName = {}
local raceNameToID = {}
local keystoneIDToRaceID = {}
local minimapSize = {}

local Arrow_OnUpdate, POI_OnEnter, POI_OnLeave, GetArchaeologyRank, SolveRaceArtifact
local ClearTomTomPoint, UpdateTomTomPoint, RefreshTomTom
local RefreshBlobInfo, MinimapBlobSetPositionAndSize, UpdateSiteBlobs
local UpdateMinimapEdges, UpdateMinimapPOIs
local AnnounceNearestSite, ResetPositions, UpdateRaceArtifact, ToggleDistanceIndicator
local inCombat = false
local TrapWorldMouse

--[[ Archy variables ]] --
Archy.NearestSite = nearestSite
Archy.PlayerPosition = playerPosition
Archy.ZoneData = zoneData
Archy.CurrentSites = digsites
Archy.CurrentArtifacts = artifacts


--[[ Default profile values ]] --
local defaults = {
	profile = {
		general = {
			enabled = true,
			show = true,
			stealthMode = false,
			icon = { hide = false },
			locked = false,
			confirmSolve = true,
			showSkillBar = true,
			sinkOptions = {},
			easyCast = false,
			autoLoot = true,
			theme = "Graphical",
		},
		artifact = {
			show = true,
			position = { "TOPRIGHT", "TOPRIGHT", -200, -425 },
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
			font = { name = "Friz Quadrata TT", size = 14, shadow = true, outline = "", color = { r = 1, g = 1, b = 1, a = 1 } },
			fragmentFont = { name = "Friz Quadrata TT", size = 14, shadow = true, outline = "", color = { r = 1, g = 1, b = 1, a = 1 } },
			keystoneFont = { name = "Friz Quadrata TT", size = 12, shadow = true, outline = "", color = { r = 1, g = 1, b = 1, a = 1 } },
			fragmentBarColors = {
				["Normal"] = { r = 1, g = 0.5, b = 0 },
				["Solvable"] = { r = 0, g = 1, b = 0 },
				["Rare"] = { r = 0, g = 0.4, b = 0.8 },
				["AttachToSolve"] = { r = 1, g = 1, b = 0 },
				["FirstTime"] = { r = 1, g = 1, b = 1 },
			},
			fragmentBarTexture = "Blizzard Parchment",
			borderTexture = "Blizzard Dialog Gold",
			backgroundTexture = "Blizzard Parchment",
		},
		digsite = {
			show = true,
			position = { "TOPRIGHT", "TOPRIGHT", -200, -200 },
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
				position = { "CENTER", "CENTER", 0, 0 },
				anchor = "TOPLEFT",
				undocked = false,
				showSurveyButton = true,
				font = { name = "Friz Quadrata TT", size = 16, shadow = false, outline = "OUTLINE", color = { r = 1, g = 1, b = 1, a = 1 } },
			},
			filterLDB = false,
			borderAlpha = 1,
			bgAlpha = 0.5,
			font = { name = "Friz Quadrata TT", size = 18, shadow = true, outline = "", color = { r = 1, g = 1, b = 1, a = 1 } },
			zoneFont = { name = "Friz Quadrata TT", size = 14, shadow = true, outline = "", color = { r = 1, g = 0.82, b = 0, a = 1 } },
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
			blob = false,
			zoneBlob = false,
			blobAlpha = 0.25,
			blobDistance = 400,
			useBlobDistance = true,
		},
		tomtom = {
			enabled = true,
			distance = 125,
			ping = true,
		},
	},
}

--[[ Keybinds ]]
BINDING_HEADER_ARCHY = "Archy"
BINDING_NAME_OPTIONS = L["BINDING_NAME_OPTIONS"]
BINDING_NAME_TOGGLE = L["BINDING_NAME_TOGGLE"]
BINDING_NAME_SOLVE = L["BINDING_NAME_SOLVE"]
BINDING_NAME_SOLVE_WITH_KEYSTONES = L["BINDING_NAME_SOLVESTONE"]
BINDING_NAME_ARTIFACTS = L["BINDING_NAME_ARTIFACTS"]
BINDING_NAME_DIGSITES = L["BINDING_NAME_DIGSITES"]

-----------------------------------------------------------------------
-- Metatables.
-----------------------------------------------------------------------
local race_data = {}
setmetatable(race_data, {
	__index = function(t, k)
		if _G.GetNumArchaeologyRaces() == 0 then
			return
		end
		local raceName, raceTexture, itemID, currencyAmount = _G.GetArchaeologyRaceInfo(k)
		local itemName, _, _, _, _, _, _, _, _, itemTexture, _ = _G.GetItemInfo(itemID)

		t[k] = {
			name = raceName,
			currency = currencyAmount,
			texture = raceTexture,
			keystone = {
				id = itemID,
				name = itemName,
				texture = itemTexture,
				inventory = 0
			}
		}
		return t[k]
	end
})
private.race_data = race_data

setmetatable(artifacts, {
	__index = function(t, k)
		if k then
			t[k] = {
				name = "",
				tooltip = "",
				icon = "",
				sockets = 0,
				stonesAdded = 0,
				fragments = 0,
				fragAdjust = 0,
				fragTotal = 0,
			}
			return t[k]
		end
	end
})


local blobs = setmetatable({}, {
	__index = function(t, k)
		local f = _G.CreateFrame("ArchaeologyDigSiteFrame", "Archy" .. k .. "_Blob")
		_G.rawset(t, k, f)
		f:ClearAllPoints()
		f:EnableMouse(false)
		f:SetFillAlpha(256 * private.db.minimap.blobAlpha)
		f:SetFillTexture("Interface\\WorldMap\\UI-ArchaeologyBlob-Inside")
		f:SetBorderTexture("Interface\\WorldMap\\UI-ArchaeologyBlob-Outside")
		f:EnableSmoothing(true)
		f:SetBorderScalar(0.1)
		f:Hide()
		return f
	end
})

local pois = setmetatable({}, {
	__index = function(t, k)
		local poi = _G.CreateFrame("Frame", "ArchyMinimap_POI" .. k, _G.Minimap)
		poi:SetWidth(10)
		poi:SetHeight(10)
		poi:SetScript("OnEnter", POI_OnEnter)
		poi:SetScript("OnLeave", POI_OnLeave)

		local arrow = _G.CreateFrame("Frame", nil, poi)
		arrow:SetPoint("CENTER", poi)
		arrow:SetScript("OnUpdate", Arrow_OnUpdate)
		arrow:SetWidth(32)
		arrow:SetHeight(32)

		local arrowtexture = arrow:CreateTexture(nil, "OVERLAY")
		arrowtexture:SetTexture([[Interface\Minimap\ROTATING-MINIMAPGUIDEARROW]]) -- [[Interface\Archeology\Arch-Icon-Marker]])
		arrowtexture:SetAllPoints(arrow)
		arrow.texture = arrowtexture
		arrow.t = 0
		arrow.poi = poi
		arrow:Hide()
		poi.useArrow = false
		poi.arrow = arrow
		poi:Hide()
		return poi
	end
})




--[[ Pre load tables ]] --
do
	-- cache the zone/map data
	local orig = _G.GetCurrentMapAreaID()

	for cid, cname in pairs{ _G.GetMapContinents() } do
		_G.SetMapZoom(cid)
		local mapid = _G.GetCurrentMapAreaID()
		continentMapToID[mapid] = cid

		local cmn = _G.GetMapInfo()

		zoneData[mapid] = {
			continent = cid,
			map = mapid,
			level = 0,
			mapFile = cmn,
			id = 0,
			name = cname
		}
		mapFileToID[cmn] = mapid
		mapIDToZoneName[mapid] = cname

		for zid, zname in pairs{ _G.GetMapZones(cid) } do
			_G.SetMapZoom(cid, zid)
			local mapid = _G.GetCurrentMapAreaID()
			local level = _G.GetCurrentMapDungeonLevel()
			mapFileToID[_G.GetMapInfo()] = mapid
			mapIDToZone[mapid] = zid
			mapIDToZoneName[mapid] = zname
			zoneIDToName[zid] = zname
			zoneData[mapid] = {
				continent = zid,
				map = mapid,
				level = level,
				mapFile = _G.GetMapInfo(),
				id = zid,
				name = zname
			}
		end
	end
	_G.SetMapByID(orig)

	--  Minimap size values
	minimapSize = {
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
		inScale = {
			[0] = 1,
			[1] = 1.25,
			[2] = 5 / 3,
			[3] = 2.5,
			[4] = 3.75,
			[5] = 6,
		},
		outScale = {
			[0] = 1,
			[1] = 7 / 6,
			[2] = 1.4,
			[3] = 1.75,
			[4] = 7 / 3,
			[5] = 3.5,
		},
	}
end

--[[ Function Hooks ]] --
-- Hook and overwrite the default SolveArtifact function to provide confirmations when nearing cap
local blizSolveArtifact = SolveArtifact
SolveArtifact = function(race_index, use_stones)
	if not race_index then
		race_index = ARTIFACT_NAME_TO_RACE_ID_MAP[_G.GetSelectedArtifactInfo()]
	end
	local rank, maxRank = GetArchaeologyRank()

	if private.db.general.confirmSolve and maxRank < MAX_ARCHAEOLOGY_RANK and (rank + 25) >= maxRank then
		if not confirmArgs then
			confirmArgs = {}
		end
		confirmArgs.race = race_index
		confirmArgs.useStones = use_stones
		_G.StaticPopup_Show("ARCHY_CONFIRM_SOLVE", rank, maxRank)
	else
		return SolveRaceArtifact(race_index, use_stones)
	end
end

--[[ Dialog declarations ]] --
_G.StaticPopupDialogs["ARCHY_CONFIRM_SOLVE"] = {
	text = L["Your Archaeology skill is at %d of %d.  Are you sure you would like to solve this artifact before visiting a trainer?"],
	button1 = _G.YES,
	button2 = _G.NO,
	OnAccept = function()
		if confirmArgs and confirmArgs.race then
			SolveRaceArtifact(confirmArgs.race, confirmArgs.useStones)
			confirmArgs = nil
		else
			blizSolveArtifact()
			confirmArgs = nil
		end
	end,
	OnCancel = function()
		confirmArgs = nil
	end,
	timeout = 0,
	sound = "levelup2",
	whileDead = false,
	hideOnEscape = true,
}


--[[ Local Helper Functions ]] --

-- Returns true if the player has the archaeology secondary skill
local function HasArchaeology()
	local _, _, arch = _G.GetProfessions()
	return arch
end

local function IsTaintable()
	return (inCombat or _G.InCombatLockdown() or _G.UnitAffectingCombat("player"))
end

local function ShouldBeHidden()
	return (not private.db.general.show or not playerContinent or _G.UnitIsGhost("player") or _G.IsInInstance() or not HasArchaeology())
end

-- opens the Blizzard_ArchaeologyUI panel
function Archy:ShowArchaeology()
	if _G.IsAddOnLoaded("Blizzard_ArchaeologyUI") then
		_G.ShowUIPanel(_G.ArchaeologyFrame)
		return true
	end
	local loaded, reason = _G.LoadAddOn("Blizzard_ArchaeologyUI")

	if loaded then
		_G.ShowUIPanel(_G.ArchaeologyFrame)
		return true
	else
		Archy:Print(L["ArchaeologyUI not loaded: %s Try opening manually."]:format(_G["ADDON_" .. reason]))
		return false
	end
end

-- returns the rank and max rank for the players archaeology skill
function GetArchaeologyRank()
	local _, _, archaeology_index = _G.GetProfessions()

	if not archaeology_index then
		return
	end
	local _, _, rank, maxRank = _G.GetProfessionInfo(archaeology_index)
	return rank, maxRank
end

-- Toggles the lock of the panels
local function ToggleLock()
	private.db.general.locked = not private.db.general.locked
	Archy:Print(private.db.general.locked and _G.LOCKED or _G.UNLOCK)
	Archy:ConfigUpdated()
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

-- deformat substitute
local function MatchFormat(msg, pattern)
	return msg:match(pattern:gsub("(%%s)", "(.+)"):gsub("(%%d)", "(.+)"))
end


-- return the player, itemlink and quantity of the item in the chat_msg_loot
local function ParseLootMessage(msg)
	local player = _G.UnitName("player")
	local item, quantity = MatchFormat(msg, _G.LOOT_ITEM_SELF_MULTIPLE)

	if item and quantity then
		return player, item, tonumber(quantity)
	end
	quantity = 1
	item = MatchFormat(msg, _G.LOOT_ITEM_SELF)

	if item then
		return player, item, tonumber(quantity)
	end
	player, item, quantity = MatchFormat(msg, _G.LOOT_ITEM_MULTIPLE)

	if player and item and quantity then
		return player, item, tonumber(quantity)
	end
	quantity = 1
	player, item = MatchFormat(msg, _G.LOOT_ITEM)

	return player, item, tonumber(quantity)
end

-- load the race related data tables
local function LoadRaceData()
	if _G.GetNumArchaeologyRaces() == 0 then
		return
	end

	for race_id = 1, _G.GetNumArchaeologyRaces() do
		local race = race_data[race_id] -- meta table should load the data

		if race then -- we have race data
			raceNameToID[race.name] = race_id
			keystoneIDToRaceID[race.keystone.id] = race_id
		end
	end
	_G.RequestArtifactCompletionHistory()
	raceDataLoaded = true
end

-- returns a list of race ids for the continent map id
local function ContinentRaces(cid)
	local races = {}
	for _, site in pairs(DIG_SITES) do
		if site.continent == continentMapToID[cid] and not _G.tContains(races, site.race) then
			table.insert(races, site.race)
		end
	end
	return races
end

function ResetPositions()
	private.db.digsite.distanceIndicator.position = { unpack(defaults.profile.digsite.distanceIndicator.position) }
	private.db.digsite.distanceIndicator.anchor = defaults.profile.digsite.distanceIndicator.anchor
	private.db.digsite.distanceIndicator.undocked = defaults.profile.digsite.distanceIndicator.undocked
	private.db.digsite.position = { unpack(defaults.profile.digsite.position) }
	private.db.digsite.anchor = defaults.profile.digsite.anchor
	private.db.artifact.position = { unpack(defaults.profile.artifact.position) }
	private.db.artifact.anchor = defaults.profile.artifact.anchor
	Archy:ConfigUpdated()
	Archy:UpdateFramePositions()
end

local CONFIG_UPDATE_FUNCTIONS = {
	artifact = function(option)
		if option == "autofill" then
			for race_id = 1, _G.GetNumArchaeologyRaces() do
				UpdateRaceArtifact(race_id)
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
		UpdateSiteBlobs()
	end,
	tomtom = function(option)
		local db = private.db

		if db.tomtom.enabled and private.tomtomExists then
			if _G.TomTom.profile then
				_G.TomTom.profile.arrow.arrival = db.tomtom.distance
				_G.TomTom.profile.arrow.enablePing = db.tomtom.ping
			end
		end
		RefreshTomTom()
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
		UpdateMinimapPOIs(true)
		UpdateSiteBlobs()
		RefreshTomTom()
	end
end

--[[ Artifact Functions ]] --
local function Announce(race_id)
	if not private.db.general.show then
		return
	end
	local race_name = "|cFFFFFF00" .. race_data[race_id].name .. "|r"
	local artifact = artifacts[race_id]
	local artifact_name = "|cFFFFFF00" .. artifact.name .. "|r"
	local text = L["You can solve %s Artifact - %s (Fragments: %d of %d)"]:format(race_name, artifact_name, artifact.fragments + artifact.fragAdjust, artifact.fragTotal)
	Archy:Pour(text, 1, 1, 1)
end

local function Ping()
	if not private.db.general.show then
		return
	end
	_G.PlaySoundFile("Interface\\AddOns\\Archy\\Media\\dingding.mp3")
end

function UpdateRaceArtifact(race_id)
	local race = race_data[race_id]

	if not race then
		--@??? Maybe use a wipe statement here
		artifacts[race_id] = nil
		return
	end
	race_data[race_id].keystone.inventory = _G.GetItemCount(race_data[race_id].keystone.id) or 0

	if _G.GetNumArtifactsByRace(race_id) == 0 then
		return
	end

	if _G.ArchaeologyFrame and _G.ArchaeologyFrame:IsVisible() then
		_G.ArchaeologyFrame_ShowArtifact(race_id)
	end
	_G.SetSelectedArtifact(race_id)

	local name, _, rarity, icon, spellDescription, numSockets = _G.GetSelectedArtifactInfo()
	local base, adjust, total = _G.GetArtifactProgress()
	local artifact = artifacts[race_id]

	ARTIFACT_NAME_TO_RACE_ID_MAP[name] = race_id

	artifact.canSolve = _G.CanSolveArtifact()
	artifact.fragments = base
	artifact.fragTotal = total
	artifact.sockets = numSockets
	artifact.icon = icon
	artifact.tooltip = spellDescription
	artifact.rare = (rarity ~= 0)
	artifact.name = name
	artifact.canSolveStone = nil
	artifact.fragAdjust = 0
	artifact.completionCount = 0

	local prevAdded = math.min(artifact.stonesAdded, race_data[race_id].keystone.inventory, numSockets)

	if private.db.artifact.autofill[race_id] then
		prevAdded = math.min(race_data[race_id].keystone.inventory, numSockets)
	end
	artifact.stonesAdded = math.min(race_data[race_id].keystone.inventory, numSockets)

	if artifact.stonesAdded > 0 and numSockets > 0 then
		for i = 1, math.min(artifact.stonesAdded, numSockets) do
			_G.SocketItemToArtifact()

			if not _G.ItemAddedToArtifact(i) then
				break
			end
		end
		base, adjust, total = _G.GetArtifactProgress()
		artifact.canSolveStone = _G.CanSolveArtifact()

		if prevAdded > 0 then
			artifact.fragAdjust = adjust
		end
	end
	artifact.stonesAdded = prevAdded

	_G.RequestArtifactCompletionHistory()

	if private.db.artifact.blacklist[race_id] then
		return
	end

	if not artifact.has_announced and ((private.db.artifact.announce and artifact.canSolve) or (private.db.artifact.keystoneAnnounce and artifact.canSolveStone)) then
		artifact.has_announced = true
		Announce(race_id)
	end

	if not artifact.has_pinged and ((private.db.artifact.ping and artifact.canSolve) or (private.db.artifact.keystonePing and artifact.canSolveStone)) then
		artifact.has_pinged = true
		Ping()
	end
end

local function UpdateRace(race_id)
	UpdateRaceArtifact(race_id)
	UpdateArtifactFrame(race_id)
end

function SolveRaceArtifact(race_id, useStones)
	if race_id then
		_G.SetSelectedArtifact(race_id)
		artifactSolved.raceId = race_id
		artifactSolved.name = _G.GetSelectedArtifactInfo()
		keystoneLootRaceID = race_id -- this is to force a refresh after the ARTIFACT_COMPLETE event

		if useStones ~= nil then
			if useStones then
				artifacts[race_id].stonesAdded = math.min(race_data[race_id].keystone.inventory, artifacts[race_id].sockets)
			else
				artifacts[race_id].stonesAdded = 0
			end
		end

		if artifacts[race_id].stonesAdded > 0 then
			for index = 1, artifacts[race_id].stonesAdded do
				SocketItemToArtifact()

				if not ItemAddedToArtifact(index) then
					break
				end
			end
		else
			if artifacts[race_id].sockets > 0 then
				for index = 1, artifacts[race_id].stonesAdded do
					RemoveItemFromArtifact()
				end
			end
		end
		GetArtifactProgress()
	end
	blizSolveArtifact()
end

function Archy:SolveAnyArtifact(useStones)
	local found = false
	for rid, artifact in pairs(artifacts) do
		if not private.db.artifact.blacklist[rid] then
			if (artifact.canSolve or (useStones and artifact.canSolveStone)) then
				SolveRaceArtifact(rid, useStones)
				found = true
				break
			end
		end
	end
	if not found then
		Archy:Print(L["No artifacts were solvable"])
	end
end

local function GetArtifactStats(rid, name)
	local numArtifacts = GetNumArtifactsByRace(rid)

	if not numArtifacts then
		return
	end

	for artifactIndex = 1, numArtifacts do
		local artifactName, _, _, _, _, _, _, firstCompletionTime, completionCount = GetArtifactInfoByRace(rid, artifactIndex)
		if name == artifactName then
			return artifactIndex, firstCompletionTime, completionCount
		end
	end
end

local function UpdateArtifactFrame(rid)
end

function Archy:SocketClicked(self, button, down)
	local race_id = self:GetParent():GetParent():GetID()

	if button == "LeftButton" then
		if artifacts[race_id].stonesAdded < artifacts[race_id].sockets and artifacts[race_id].stonesAdded < race_data[race_id].keystone.inventory then
			artifacts[race_id].stonesAdded = artifacts[race_id].stonesAdded + 1
		end
	else
		if artifacts[race_id].stonesAdded > 0 then
			artifacts[race_id].stonesAdded = artifacts[race_id].stonesAdded - 1
		end
	end
	UpdateRaceArtifact(race_id)
	Archy:RefreshRacesDisplay()
end

--[[ Dig Site List Functions ]] --
local function ResetDigCounter(id)
	siteStats[id].counter = 0
end

local function IncrementDigCounter(id)
	siteStats[id].counter = (siteStats[id].counter or 0) + 1
end

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
			ResetDigCounter(siteA.id)
		end
	end
end

local DIG_LOCATION_TEXTURE = 177

local function GetContinentSites(continent_id)
	local sites, orig = {}, _G.GetCurrentMapAreaID()
	_G.SetMapZoom(continent_id)

	local totalPOIs = _G.GetNumMapLandmarks()

	for index = 1, totalPOIs do
		local name, description, textureIndex, px, py = _G.GetMapLandmarkInfo(index)

		if textureIndex == DIG_LOCATION_TEXTURE then
			local zoneName, mapFile, texPctX, texPctY, texX, texY, scrollX, scrollY = _G.UpdateMapHighlight(px, py)
			local site = DIG_SITES[name]
			local mc, fc, mz, fz, zoneID = 0, 0, 0, 0, 0
			mc, fc = astrolabe:GetMapID(continent_id, 0)
			mz = site.map
			zoneID = mapIDToZone[mz]


			if site then
				local x, y = astrolabe:TranslateWorldMapPosition(mc, fc, px, py, mz, fz)

				local raceName, raceCrestTexture = _G.GetArchaeologyRaceInfo(site.race)

				local digsite = {
					continent = mc,
					zoneId = zoneID,
					zoneName = mapIDToZoneName[mz] or _G.UNKNOWN,
					mapFile = mapFile,
					map = mz,
					level = fz,
					x = x,
					y = y,
					name = name,
					raceId = site.race,
					id = site.blob,
					distance = 999999,
				}
				table.insert(sites, digsite)
			end
		end
	end
	_G.SetMapByID(orig)
	return sites
end

local function UpdateSites()
	local sites

	for continent_id, continent_name in pairs{ _G.GetMapContinents() } do
		if not digsites[continent_id] then
			digsites[continent_id] = {}
		end
		sites = GetContinentSites(continent_id)

		if sites and #sites > 0 and continent_id == continentMapToID[playerContinent] then
			CompareAndResetDigCounters(digsites[continent_id], sites)
			CompareAndResetDigCounters(sites, digsites[continent_id])
		end

		if #sites > 0 then
			digsites[continent_id] = sites
		end
	end
end

function Archy:IsSiteBlacklisted(name)
	return blacklisted_sites[name]
end

function Archy:ToggleSiteBlacklist(name)
	blacklisted_sites[name] = not blacklisted_sites[name]
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

local function SortSitesByName(a, b)
	return a.zoneName .. ":" .. a.name < b.zoneName .. ":" .. b.name
end

function Archy:UpdateSiteDistances()
	if not digsites[continentMapToID[playerContinent]] or (#digsites[continentMapToID[playerContinent]] == 0) then
		nearestSite = nil
		return
	end
	local distance, nearest

	for index = 1, SITES_PER_CONTINENT do
		local site = digsites[continentMapToID[playerContinent]][index]

		if site.poi then
			site.distance = astrolabe:GetDistanceToIcon(site.poi)
		else
			site.distance = astrolabe:ComputeDistance(playerPosition.map, playerPosition.level, playerPosition.x, playerPosition.y, site.map, site.level, site.x, site.y)
		end
		if not Archy:IsSiteBlacklisted(site.name) then
			if not distance or site.distance < distance then
				distance = site.distance
				nearest = site
			end
		end
	end

	if nearest and (not nearestSite or nearestSite.id ~= nearest.id) then
		-- nearest dig site has changed
		nearestSite = nearest
		tomtomActive = true
		RefreshTomTom()
		UpdateSiteBlobs()
		UpdateMinimapPOIs()
		if private.db.digsite.announceNearest and private.db.general.show then
			AnnounceNearestSite()
		end
	end

	-- Sort sites
	local sites = digsites[continentMapToID[playerContinent]]
	if private.db.digsite.sortByDistance then
		table.sort(sites, SortSitesByDistance)
	else -- sort by zone then name
		table.sort(sites, SortSitesByName)
	end
end

function AnnounceNearestSite()
	if not nearestSite or not nearestSite.distance or nearestSite.distance == 999999 then
		return
	end
	local site_name = ("%s%s|r"):format(_G.GREEN_FONT_COLOR_CODE, nearestSite.name)
	local site_zone = ("%s%s|r"):format(_G.GREEN_FONT_COLOR_CODE, nearestSite.zoneName)

	Archy:Pour(L["Nearest Dig Site is: %s in %s (%.1f yards away)"]:format(site_name, site_zone, nearestSite.distance), 1, 1, 1)
end

local function UpdateSiteFrame(index)
end

function Archy:ImportOldStatsDB()
	for key, st in pairs(Archy.db.char.digsites) do
		if key ~= "blacklist" and key ~= "stats" and key ~= "counter" and key ~= "" then
			if DIG_SITES[key] then
				local site = DIG_SITES[key]
				siteStats[site.blob].surveys = (siteStats[site.blob].surveys or 0) + (st.surveys or 0)
				siteStats[site.blob].fragments = (siteStats[site.blob].fragments or 0) + (st.fragments or 0)
				siteStats[site.blob].looted = (siteStats[site.blob].looted or 0) + (st.looted or 0)
				siteStats[site.blob].keystones = (siteStats[site.blob].keystones or 0) + (st.keystones or 0)
				Archy.db.char.digsites[key] = nil
			end
		end
	end
end




--[[ Survey Functions ]] --
local function AddSurveyNode(siteId, map, level, x, y)
	local newNode = {
		m = map,
		f = level,
		x = x,
		y = y
	}
	local exists = false

	if not Archy.db.global.surveyNodes then
		Archy.db.global.surveyNodes = {}
	end

	if not Archy.db.global.surveyNodes[siteId] then
		Archy.db.global.surveyNodes[siteId] = {}
	end

	for _, node in pairs(Archy.db.global.surveyNodes[siteId]) do
		local distance = astrolabe:ComputeDistance(newNode.m, newNode.f, newNode.x, newNode.y, node.m, node.f, node.x, node.y)

		if not distance or _G.IsInInstance() then
			distance = 0
		end

		if distance <= 10 then
			exists = true
			break
		end
	end
	if not exists then
		table.insert(Archy.db.global.surveyNodes[siteId], newNode)
	end
end

function Archy:InjectSurveyNode(siteId, map, level, x, y)
	local newNode = {
		m = map,
		f = level,
		x = x,
		y = y
	}
	local exists = false

	if not Archy.db.global.surveyNodes then
		Archy.db.global.surveyNodes = {}
	end

	if not Archy.db.global.surveyNodes[siteId] then
		Archy.db.global.surveyNodes[siteId] = {}
	end

	for _, node in pairs(Archy.db.global.surveyNodes[siteId]) do
		local distance = astrolabe:ComputeDistance(newNode.m, newNode.f, newNode.x, newNode.y, node.m, node.f, node.x, node.y)
		if not distance then
			distance = 0
		end

		if distance <= 10 then
			exists = true
			break
		end
	end
	if not exists then
		table.insert(Archy.db.global.surveyNodes[siteId], newNode)
	end
end

function Archy:ClearSurveyNodeDB()
	Archy.db.global.surveyNodes = {}
	collectgarbage('collect')
end

function ToggleDistanceIndicator()
	if IsTaintable() then
		return
	end

	if not private.db.digsite.distanceIndicator.enabled or ShouldBeHidden() then
		private.distance_indicator_frame:Hide()
		return
	end
	private.distance_indicator_frame:Show()

	if distanceIndicatorActive then
		private.distance_indicator_frame.circle:SetAlpha(1) else private.distance_indicator_frame.circle:SetAlpha(0)
	end

	if private.db.digsite.distanceIndicator.showSurveyButton then
		private.distance_indicator_frame.surveyButton:Show()
		private.distance_indicator_frame:SetWidth(52 + private.distance_indicator_frame.surveyButton:GetWidth())
	else
		private.distance_indicator_frame.surveyButton:Hide()
		private.distance_indicator_frame:SetWidth(42)
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
	local distance = astrolabe:ComputeDistance(playerPosition.map, playerPosition.level, playerPosition.x, playerPosition.y, survey_location.map, survey_location.level, survey_location.x, survey_location.y)

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
local allPois = {}
local sitePoiCount, surveyPoiCount = 0, 0

local function GetSitePOI(siteId, map, level, x, y, tooltip)
	local poi = table.remove(sitePool)

	if not poi then
		sitePoiCount = sitePoiCount + 1
		poi = _G.CreateFrame("Frame", "ArchyMinimap_SitePOI" .. sitePoiCount, _G.Minimap)
		poi.index = sitePoiCount
		poi:SetWidth(10)
		poi:SetHeight(10)

		table.insert(allPois, poi)

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
		map,
		level,
		x,
		y
	}
	poi.active = true
	poi.siteId = siteId
	poi.t = 0
	return poi
end

local function ClearSitePOI(poi)
	if not poi then
		return
	end
	astrolabe:RemoveIconFromMinimap(poi)
	poi.icon:Hide()
	poi.arrow:Hide()
	poi:Hide()
	poi.active = false
	poi.tooltip = nil
	poi.location = nil
	poi.siteId = nil
	poi:SetScript("OnEnter", nil)
	poi:SetScript("OnLeave", nil)
	poi:SetScript("OnUpdate", nil)
	table.insert(sitePool, poi)
end

local function GetSurveyPOI(siteId, map, level, x, y, tooltip)
	local poi = table.remove(surveyPool)

	if not poi then
		surveyPoiCount = surveyPoiCount + 1
		poi = _G.CreateFrame("Frame", "ArchyMinimap_SurveyPOI" .. surveyPoiCount, _G.Minimap)
		poi.index = surveyPoiCount
		poi:SetWidth(8)
		poi:SetHeight(8)

		table.insert(allPois, poi)

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
		map,
		level,
		x,
		y
	}
	poi.active = true
	poi.siteId = siteId
	poi.t = 0
	return poi
end

local function ClearSurveyPOI(poi)
	if not poi then
		return
	end
	astrolabe:RemoveIconFromMinimap(poi)
	poi.icon:Hide()
	poi:Hide()
	poi.active = nil
	poi.tooltip = nil
	poi.siteId = nil
	poi.location = nil
	poi:SetScript("OnEnter", nil)
	poi:SetScript("OnLeave", nil)
	poi:SetScript("OnUpdate", nil)
	table.insert(surveyPool, poi)
end

-- TODO: Figure out if this should be used somewhere - it currently is not, and should maybe be removed.
local function CreateMinimapPOI(index, type, loc, title, siteId)
	local poi = pois[index]
	local poiButton = _G.CreateFrame("Frame", nil, poi)
	poiButton.texture = poiButton:CreateTexture(nil, "OVERLAY")

	if type == "site" then
		poi.useArrow = true
		poiButton.texture:SetTexture([[Interface\Archeology\Arch-Icon-Marker.blp]])
		poiButton:SetWidth(14)
		poiButton:SetHeight(14)
	else
		poi.useArrow = false
		poiButton.texture:SetTexture([[Interface\AddOns\Archy\Media\Nodes]])
		if private.db.minimap.fragmentIcon == "Cross" then
			poiButton.texture:SetTexCoord(0, 0.46875, 0, 0.453125)
		else
			poiButton.texture:SetTexCoord(0, 0.234375, 0.5, 0.734375)
		end
		poiButton:SetWidth(8)
		poiButton:SetHeight(8)
	end
	poiButton.texture:SetAllPoints(poiButton)
	poiButton:SetPoint("CENTER", poi)
	poiButton:SetScale(1)
	poiButton:SetParent(poi)
	poiButton:EnableMouse(false)
	poi.poiButton = poiButton
	poi.index = index
	poi.type = type
	poi.title = title
	poi.location = loc
	poi.active = true
	poi.siteId = siteId
	pois[index] = poi
	return poi
end

function UpdateMinimapEdges()
	for id, poi in pairs(allPois) do
		if poi.active then
			local edge = astrolabe:IsIconOnEdge(poi)
			if poi.type == "site" then
				if edge then
					poi.icon:Hide()
					poi.arrow:Show()
				else
					poi.icon:Show()
					poi.arrow:Hide()
				end
			else
				if edge then
					poi.icon:Hide()
					poi:Hide()
				else
					poi.icon:Show()
					poi:Show()
				end
			end
		end
	end
end

local lastNearestSite

local function GetContinentSiteIDs()
	local validSiteIDs = {}

	if private.db.general.show and private.db.minimap.show then
		return validSiteIDs
	end

	if digsites[continentMapToID[playerContinent]] then
		for _, site in pairs(digsites[continentMapToID[playerContinent]]) do
			table.insert(validSiteIDs, site.id)
		end
	end
	return validSiteIDs
end

local function ClearAllPOIs()
	for idx, poi in ipairs(allPois) do
		if poi.type == "site" then
			ClearSitePOI(poi)
		elseif poi.type == "survey" then
			ClearSurveyPOI(poi)
		end
	end
end

local function ClearInvalidPOIs()
	local validSiteIDs = GetContinentSiteIDs()

	for idx, poi in ipairs(allPois) do
		if not validSiteIDs[poi.siteId] then
			if poi.type == "site" then
				ClearSitePOI(poi)
			else
				ClearSurveyPOI(poi)
			end
		elseif poi.type == "survey" and lastNearestSite.id ~= nearestSite.id and lastNearestSite.id == poi.siteId then
			ClearSurveyPOI(poi)
		end
	end
end

function UpdateMinimapPOIs(force)
	if _G.WorldMapButton:IsVisible() then
		return
	end

	if lastNearestSite ~= nearestSite or force then
		lastNearestSite = nearestSite
		local validSiteIDs = GetContinentSiteIDs()
		local sites = digsites[continentMapToID[playerContinent]]

		if not sites or #sites == 0 or _G.IsInInstance() then
			ClearAllPOIs()
			return
		else
			ClearInvalidPOIs()
		end

		if not playerPosition.x and not playerPosition.y then
			return
		end
		local i = 1

		for _, site in pairs(sites) do
			site.poi = GetSitePOI(site.id, site.map, site.level, site.x, site.y, ("%s\n(%s)"):format(site.name, site.zoneName))
			site.poi.active = true

			astrolabe:PlaceIconOnMinimap(site.poi, site.map, site.level, site.x, site.y)

			if ((not private.db.minimap.nearest) or (nearestSite and nearestSite.id == site.id)) and private.db.general.show and private.db.minimap.show then
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
						POI.active = true

						astrolabe:PlaceIconOnMinimap(POI, node.m, node.f, node.x, node.y)

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
		--UpdateMinimapEdges()
		if private.db.minimap.fragmentColorBySurveyDistance and private.db.minimap.fragmentIcon ~= "CyanDot" then
			for id, poi in pairs(allPois) do
				if poi.active and poi.type == "survey" then
					poi.icon:SetTexCoord(0, 0.234375, 0.5, 0.734375)
				end
			end
		end
		-- print("Calling collectgarbage for UpdateMinimapPOIs(force = ", force,")")
		collectgarbage('collect')
	else
		--        if lastNearestSite then UpdateMinimapEdges() end
	end
end

function POI_OnEnter(self)
	if not self.tooltip then
		return
	end
	_G.GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	_G.GameTooltip:SetText(self.tooltip, _G.NORMAL_FONT_COLOR[1], _G.NORMAL_FONT_COLOR[2], _G.NORMAL_FONT_COLOR[3], 1) --, true)
end

function POI_OnLeave(self)
	_G.GameTooltip:Hide()
end

local square_half = math.sqrt(0.5)
local rad_135 = math.rad(135)
local update_threshold = 0.1
function Arrow_OnUpdate(self, elapsed)
	self.t = self.t + elapsed
	if self.t < update_threshold then
		return
	end
	self.t = 0

	if _G.IsInInstance() then
		self:Hide()
		return
	end

	if not self.active then
		return
	end

	local edge = astrolabe:IsIconOnEdge(self)

	if self.type == "site" then
		if edge then
			if self.icon:IsShown() then self.icon:Hide() end
			if not self.arrow:IsShown() then self.arrow:Show() end

			-- Rotate the icon, as required
			local angle = astrolabe:GetDirectionToIcon(self)
			angle = angle + rad_135

			if _G.GetCVar("rotateMinimap") == "1" then
				--local cring = MiniMapCompassRing:GetFacing()
				local cring = _G.GetPlayerFacing()
				angle = angle - cring
			end

			local sin, cos = math.sin(angle) * square_half, math.cos(angle) * square_half
			self.arrow:SetTexCoord(0.5 - sin, 0.5 + cos, 0.5 + cos, 0.5 + sin, 0.5 - cos, 0.5 - sin, 0.5 + sin, 0.5 - cos)
		else
			if not self.icon:IsShown() then self.icon:Show() end
			if self.arrow:IsShown() then self.arrow:Hide() end
		end
	else
		if edge then
			if self.icon:IsShown() then self.icon:Hide() end
		else
			if not self.icon:IsShown() then self.icon:Show() end
		end
	end
end

--[[ Blob Functions ]] --
function RefreshBlobInfo(f)
	f:DrawNone()
	local numEntries = _G.ArchaeologyMapUpdateAll()

	for i = 1, numEntries do
		local blobID = _G.ArcheologyGetVisibleBlobID(i)
		f:DrawBlob(blobID, true)
	end
end

function MinimapBlobSetPositionAndSize(f)
	if not f or not playerPosition.x or not playerPosition.y then
		return
	end
	local dx = (playerPosition.x - 0.5) * f:GetWidth()
	local dy = (playerPosition.y - 0.5) * f:GetHeight()
	f:ClearAllPoints()
	f:SetPoint("CENTER", _G.Minimap, "CENTER", -dx, dy)

	local mapWidth = f:GetParent():GetWidth()
	local mapHeight = f:GetParent():GetHeight()
	local mapSizePix = math.min(mapWidth, mapHeight)

	local indoors = _G.GetCVar("minimapZoom") + 0 == _G.Minimap:GetZoom() and "outdoor" or "indoor"
	local zoom = _G.Minimap:GetZoom()
	local mapSizeYards = minimapSize[indoors][zoom]

	if not playerPosition.map or playerPosition.map == -1 then
		return
	end

	local _, _, yw, yh, _, _ = astrolabe:GetMapInfo(playerPosition.map, playerPosition.level)
	local pw = yw * mapSizePix / mapSizeYards
	local ph = yh * mapSizePix / mapSizeYards

	if pw == old_pw and ph == oldph then
		return
	end
	old_pw, old_ph = pw, ph

	f:SetSize(pw, ph)

	f:SetFillAlpha(256 * private.db.minimap.blobAlpha)
	--    f:SetFrameStrata("LOW")
	--    f:SetFrameLevel(f:GetParent():GetFrameLevel() + 7)
end

function UpdateSiteBlobs()
	if IsTaintable() then
		return
	end

	if _G.BattlefieldMinimap then
		if private.db.minimap.zoneBlob and private.db.general.show and not _G.IsInInstance() then
			local blob = blobs["Battlefield"]
			if blob:GetParent() ~= _G.BattlefieldMinimap then -- set the battlefield map parent
				blob:SetParent(_G.BattlefieldMinimap)
				blob:ClearAllPoints()
				blob:SetAllPoints(_G.BattlefieldMinimap)
				blob:SetFrameLevel(_G.BattlefieldMinimap:GetFrameLevel() + 2)
			end
			RefreshBlobInfo(blob)
			if not blob:IsShown() then blob:Show() end
		elseif blobs["Battlefield"]:IsShown() then
			blobs["Battlefield"]:Hide()
		end
	end

	if private.db.minimap.show and private.db.minimap.blob and private.db.general.show and not _G.IsInInstance() then
		local blob = blobs["Minimap"]

		if blob:GetParent() ~= _G.Minimap then -- set the minimap parent
			blob:SetParent(_G.Minimap)
			blob:SetFrameLevel(_G.Minimap:GetFrameLevel() + 2)
		end

		if (private.db.minimap.useBlobDistance and nearestSite and nearestSite.distance and (nearestSite.distance > private.db.minimap.blobDistance)) then
			if blob:IsShown() then blob:Hide() end
			return
		end

		RefreshBlobInfo(blob)
		MinimapBlobSetPositionAndSize(blob)

		if not blob:IsShown() then
			blob:Show()
		end
	elseif blobs["Minimap"]:IsShown() then
		blobs["Minimap"]:Hide()
	end
end


--[[ TomTom Functions ]] --
-- clear the waypoint we gave tomtom
function ClearTomTomPoint()
	if not tomtomPoint then
		return
	end
	tomtomPoint = _G.TomTom:RemoveWaypoint(tomtomPoint)
end

function UpdateTomTomPoint()
	if not tomtomSite and not nearestSite then
		-- we have no information to pass tomtom
		ClearTomTomPoint()
		return
	end

	if nearestSite then
		tomtomSite = nearestSite
	else
		nearestSite = tomtomSite
	end

	if not tomtomFrame then
		tomtomFrame = _G.CreateFrame("Frame")
	end

	if not tomtomFrame:IsShown() then
		tomtomFrame:Show()
	end
	local waypointExists

	if _G.TomTom.WaypointExists then -- do we have the legit TomTom?
		waypointExists = _G.TomTom:WaypointExists(continentMapToID[tomtomSite.continent], tomtomSite.zoneId, tomtomSite.x * 100, tomtomSite.y * 100, tomtomSite.name .. "\n" .. tomtomSite.zoneName)
	end

	if not waypointExists then -- waypoint doesn't exist or we have a TomTom emulator
		ClearTomTomPoint()
		tomtomPoint = _G.TomTom:AddZWaypoint(continentMapToID[tomtomSite.continent], tomtomSite.zoneId, tomtomSite.x * 100, tomtomSite.y * 100, tomtomSite.name .. "\n" .. tomtomSite.zoneName, false, false, false, false, false, true)
	end
end

function RefreshTomTom()
	if private.db.general.show and private.db.tomtom.enabled and private.tomtomExists and tomtomActive then
		UpdateTomTomPoint()
	else
		if private.db.tomtom.enabled and not private.tomtomExists then
			-- TomTom (or emulator) was disabled, disabling TomTom support
			private.db.tomtom.enabled = false
			Archy:Print("TomTom doesn't exist... disabling it")
		end

		if tomtomPoint then
			ClearTomTomPoint()
			tomtomPoint = nil
		end

		if tomtomFrame then
			if tomtomFrame:IsShown() then
				tomtomFrame:Hide()
			end
			tomtomFrame = nil
		end
	end
end

--[[ LibDataBroker functions ]] --
local myProvider, cellPrototype = qtip:CreateCellProvider()
function cellPrototype:InitializeCell()
	local bar = self:CreateTexture(nil, "OVERLAY", self)
	self.bar = bar
	bar:SetWidth(100)
	bar:SetHeight(12)
	bar:SetPoint("LEFT", self, "LEFT", 1, 0)

	local bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg = bg
	bg:SetWidth(102)
	bg:SetHeight(14)
	bg:SetTexture(0, 0, 0, 0.5)
	bg:SetPoint("LEFT", self)

	local fs = self:CreateFontString(nil, "OVERLAY")
	self.fs = fs
	fs:SetAllPoints(self)
	fs:SetFontObject(_G.GameTooltipText)
	fs:SetShadowColor(0, 0, 0)
	fs:SetShadowOffset(1, -1)
	self.r, self.g, self.b = 1, 1, 1
end

function cellPrototype:SetupCell(tooltip, value, justification, font, r, g, b)
	local barTexture = [[Interface\TargetingFrame\UI-StatusBar]]
	local bar = self.bar
	local fs = self.fs
	--[[    {
    1 artifact.fragments,
    2 artifact.fragAdjust,
    3 artifact.fragTotal,
    4 raceData[rid].keystone.inventory,
    5 artifact.sockets,
    6 artifact.stonesAdded,
    7 artifact.canSolve,
    8 artifact.canSolveStone,
    9 artifact.rare }
]]

	local perc = math.min((value[1] + value[2]) / value[3] * 100, 100)
	local bar_colors = private.db.artifact.fragmentBarColors

	if value[7] then
		self.r, self.g, self.b = bar_colors["Solvable"].r, bar_colors["Solvable"].g, bar_colors["Solvable"].b
	elseif value[8] then
		self.r, self.g, self.b = bar_colors["AttachToSolve"].r, bar_colors["AttachToSolve"].g, bar_colors["AttachToSolve"].b
	elseif value[9] then
		self.r, self.g, self.b = bar_colors["Rare"].r, bar_colors["Rare"].g, bar_colors["Rare"].b
	else
		self.r, self.g, self.b = bar_colors["Normal"].r, bar_colors["Normal"].g, bar_colors["Normal"].b
	end
	bar:SetVertexColor(self.r, self.g, self.b)
	bar:SetWidth(perc)
	bar:SetTexture(barTexture)
	bar:Show()
	fs:SetFontObject(font or tooltip:GetFont())
	fs:SetJustifyH("CENTER")
	fs:SetTextColor(1, 1, 1)

	local adjust = ""
	if value[2] > 0 then
		adjust = "(+" .. tostring(value[2]) .. ")"
	end

	fs:SetFormattedText("%d%s / %d", value[1], adjust, value[3])
	fs:Show()

	return bar:GetWidth() + 2, bar:GetHeight() + 2
end

function cellPrototype:ReleaseCell()
	self.r, self.g, self.b = 1, 1, 1
end

function cellPrototype:getContentHeight()
	return self.bar:GetHeight() + 2
end

local progress_data = {}

function ldb:OnEnter()
	local numCols, colIndex, line = 10, 0, 0
	local tooltip = qtip:Acquire("ArchyTooltip", numCols, "CENTER", "LEFT", "LEFT", "LEFT", "RIGHT", "RIGHT", "RIGHT", "RIGHT", "RIGHT")
	tooltip:SetScale(1)
	tooltip:SetAutoHideDelay(0.25, self)
	tooltip:EnableMouse()
	tooltip:SmartAnchorTo(self)
	tooltip:Hide()
	tooltip:Clear()

	local line = tooltip:AddHeader(".")
	tooltip:SetCell(line, 1, ("%s%s%s"):format(_G.ORANGE_FONT_COLOR_CODE, "Archy", "|r"), "CENTER", numCols)

	if HasArchaeology() then
		line = tooltip:AddLine(".")
		local rank, maxRank = GetArchaeologyRank()
		local skill = ("%d/%d"):format(rank, maxRank)

		if maxRank < MAX_ARCHAEOLOGY_RANK and (maxRank - rank) <= 25 then
			skill = ("%s - |cFFFF0000%s|r"):format(skill, L["Visit a trainer!"])
		elseif maxRank == MAX_ARCHAEOLOGY_RANK and rank == maxRank then
			skill = ("%s%s|r"):format(_G.GREEN_FONT_COLOR_CODE, "MAX")
		end
		tooltip:SetCell(line, 1, ("%s%s|r%s"):format(_G.NORMAL_FONT_COLOR_CODE, _G.SKILL .. ": ", skill), "CENTER", numCols)

		line = tooltip:AddLine(".")
		tooltip:SetCell(line, 1, ("%s%s|r"):format("|cFFFFFF00", L["Artifacts"]), "LEFT", numCols)
		tooltip:AddSeparator()

		line = tooltip:AddLine(".")
		tooltip:SetCell(line, 1, " ", "LEFT", 1)
		tooltip:SetCell(line, 2, _G.NORMAL_FONT_COLOR_CODE .. _G.RACE .. "|r", "LEFT", 1)
		tooltip:SetCell(line, 3, " ", "LEFT", 1)
		tooltip:SetCell(line, 4, _G.NORMAL_FONT_COLOR_CODE .. L["Artifact"] .. "|r", "LEFT", 2)
		tooltip:SetCell(line, 6, _G.NORMAL_FONT_COLOR_CODE .. L["Progress"] .. "|r", "CENTER", 1)
		tooltip:SetCell(line, 7, _G.NORMAL_FONT_COLOR_CODE .. L["Keys"] .. "|r", "CENTER", 1)
		tooltip:SetCell(line, 8, _G.NORMAL_FONT_COLOR_CODE .. L["Sockets"] .. "|r", "CENTER", 1)
		tooltip:SetCell(line, 9, _G.NORMAL_FONT_COLOR_CODE .. L["Completed"] .. "|r", "CENTER", 2)

		for rid, artifact in pairs(artifacts) do
			if artifact.fragTotal > 0 then
				line = tooltip:AddLine(" ")
				tooltip:SetCell(line, 1, " " .. ("|T%s:18:18:0:1:128:128:4:60:4:60|t"):format(race_data[rid].texture), "LEFT", 1)
				tooltip:SetCell(line, 2, race_data[rid].name, "LEFT", 1)
				tooltip:SetCell(line, 3, " " .. ("|T%s:18:18|t"):format(artifact.icon), "LEFT", 1)

				local artifactName = artifact.name

				if artifact.rare then
					artifactName = ("%s%s|r"):format("|cFF0070DD", artifactName)
				end

				tooltip:SetCell(line, 4, artifactName, "LEFT", 2)

				progress_data[1] = artifact.fragments
				progress_data[2] = artifact.fragAdjust
				progress_data[3] = artifact.fragTotal
				progress_data[4] = race_data[rid].keystone.inventory
				progress_data[5] = artifact.sockets
				progress_data[6] = artifact.stonesAdded
				progress_data[7] = artifact.canSolve
				progress_data[8] = artifact.canSolveStone
				progress_data[9] = artifact.rare

				tooltip:SetCell(line, 6, progress_data, myProvider, 1, 0, 0)
				tooltip:SetCell(line, 7, (race_data[rid].keystone.inventory > 0) and race_data[rid].keystone.inventory or "", "CENTER", 1)
				tooltip:SetCell(line, 8, (artifact.sockets > 0) and artifact.sockets or "", "CENTER", 1)

				local _, _, completionCount = GetArtifactStats(rid, artifact.name)
				tooltip:SetCell(line, 9, (completionCount or "unknown"), "CENTER", 2)
			end
		end

		line = tooltip:AddLine(" ")
		line = tooltip:AddLine(" ")
		tooltip:SetCell(line, 1, ("%s%s|r"):format("|cFFFFFF00", L["Dig Sites"]), "LEFT", numCols)
		tooltip:AddSeparator()

		for cid, csites in pairs(digsites) do
			if (#csites > 0) and (cid == continentMapToID[playerContinent] or not private.db.digsite.filterLDB) then
				local continentName
				for _, zone in pairs(zoneData) do
					if zone.continent == cid and zone.id == 0 then
						continentName = zone.name
						break
					end
				end
				line = tooltip:AddLine(" ")
				tooltip:SetCell(line, 1, "  " .. _G.ORANGE_FONT_COLOR_CODE .. continentName .. "|r", "LEFT", numCols)

				line = tooltip:AddLine(" ")
				tooltip:SetCell(line, 1, " ", "LEFT", 1)
				tooltip:SetCell(line, 2, _G.NORMAL_FONT_COLOR_CODE .. L["Fragment"] .. "|r", "LEFT", 2)
				tooltip:SetCell(line, 4, _G.NORMAL_FONT_COLOR_CODE .. L["Dig Site"] .. "|r", "LEFT", 1)
				tooltip:SetCell(line, 5, _G.NORMAL_FONT_COLOR_CODE .. _G.ZONE .. "|r", "LEFT", 2)
				tooltip:SetCell(line, 7, _G.NORMAL_FONT_COLOR_CODE .. L["Surveys"] .. "|r", "CENTER", 1)
				tooltip:SetCell(line, 8, _G.NORMAL_FONT_COLOR_CODE .. L["Digs"] .. "|r", "CENTER", 1)
				tooltip:SetCell(line, 9, _G.NORMAL_FONT_COLOR_CODE .. _G.ARCHAEOLOGY_RUNE_STONES .. "|r", "CENTER", 1)
				tooltip:SetCell(line, 10, _G.NORMAL_FONT_COLOR_CODE .. L["Keys"] .. "|r", "CENTER", 1)

				for _, site in pairs(csites) do
					line = tooltip:AddLine(" ")
					tooltip:SetCell(line, 1, " " .. ("|T%s:18:18:0:1:128:128:4:60:4:60|t"):format(race_data[site.raceId].texture), "LEFT", 1)
					tooltip:SetCell(line, 2, race_data[site.raceId].name, "LEFT", 2)
					tooltip:SetCell(line, 4, site.name, "LEFT", 1)
					tooltip:SetCell(line, 5, site.zoneName, "LEFT", 2)
					tooltip:SetCell(line, 7, siteStats[site.id].surveys, "CENTER", 1)
					tooltip:SetCell(line, 8, siteStats[site.id].looted, "CENTER", 1)
					tooltip:SetCell(line, 9, siteStats[site.id].fragments, "CENTER", 1)
					tooltip:SetCell(line, 10, siteStats[site.id].keystones, "CENTER", 1)
				end
				line = tooltip:AddLine(" ")
			end
		end
	else
		line = tooltip:AddLine(" ")
		tooltip:SetCell(line, 1, L["Learn Archaeology in your nearest major city!"], "CENTER", numCols)
	end

	line = tooltip:AddLine(" ")
	line = tooltip:AddLine(" ") tooltip:SetCell(line, 1, "|cFF00FF00" .. L["Left-Click to toggle Archy"] .. "|r", "LEFT", numCols)
	line = tooltip:AddLine(" ") tooltip:SetCell(line, 1, "|cFF00FF00" .. L["Shift Left-Click to toggle Archy's on-screen lists"] .. "|r", "LEFT", numCols)
	line = tooltip:AddLine(" ") tooltip:SetCell(line, 1, "|cFF00FF00" .. L["Right-Click to lock/unlock Archy"] .. "|r", "LEFT", numCols)
	line = tooltip:AddLine(" ") tooltip:SetCell(line, 1, "|cFF00FF00" .. L["Middle-Click to display the Archaeology window"] .. "|r", "LEFT", numCols)

	tooltip:UpdateScrolling()
	tooltip:Show()
end

function ldb:OnLeave()
end

function ldb:OnClick(button, down)
	if button == "LeftButton" and _G.IsShiftKeyDown() then
		private.db.general.stealthMode = not private.db.general.stealthMode
		Archy:ConfigUpdated()
	elseif button == "LeftButton" and _G.IsControlKeyDown() then
		_G.InterfaceOptionsFrame_OpenToCategory(Archy.optionsFrame)
	elseif button == "LeftButton" then
		private.db.general.show = not private.db.general.show
		Archy:ConfigUpdated()
		ToggleDistanceIndicator()
	elseif button == "RightButton" then
		ToggleLock()
	elseif button == "MiddleButton" then
		Archy:ShowArchaeology()
	end
end


--[[ Slash command handler ]] --
local function SlashHandler(msg, editbox)
	local command = msg:lower()

	if command == L["config"]:lower() then
		_G.InterfaceOptionsFrame_OpenToCategory(Archy.optionsFrame)
	elseif command == L["stealth"]:lower() then
		private.db.general.stealthMode = not private.db.general.stealthMode
		Archy:ConfigUpdated()
	elseif command == L["dig sites"]:lower() then
		private.db.digsite.show = not private.db.digsite.show
		Archy:ConfigUpdated('digsite')
	elseif command == L["artifacts"]:lower() then
		private.db.artifact.show = not private.db.artifact.show
		Archy:ConfigUpdated('artifact')
	elseif command == _G.SOLVE:lower() then
		Archy:SolveAnyArtifact()
	elseif command == L["solve stone"]:lower() then
		Archy:SolveAnyArtifact(true)
	elseif command == L["nearest"]:lower() or command == L["closest"]:lower() then
		AnnounceNearestSite()
	elseif command == L["reset"]:lower() then
		ResetPositions()
	elseif command == ("TomTom"):lower() then
		private.db.tomtom.enabled = not private.db.tomtom.enabled
		RefreshTomTom()
	elseif command == _G.MINIMAP_LABEL:lower() then
		private.db.minimap.show = not private.db.minimap.show
		Archy:ConfigUpdated('minimap')
	elseif command == "test" then
		private.races_frame:SetBackdropBorderColor(1, 1, 1, 0.5)
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
		Archy:Print("|cFF00FF00" .. "TomTom" .. "|r - " .. L["Toggles TomTom Integration"])
		Archy:Print("|cFF00FF00" .. _G.MINIMAP_LABEL .. "|r - " .. L["Toggles the dig site icons on the minimap"])
	end
end


--[[ AddOn Initialization ]] --
function Archy:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ArchyDB", defaults, 'Default')
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdate")

	local about_panel = LibStub:GetLibrary("LibAboutPanel", true)

	if about_panel then
		self.optionsFrame = about_panel.new(nil, "Archy")
	end

	self:SetSinkStorage(Archy.db.profile.general.sinkOptions)

	self:SetupOptions()

	if not self.db.global.surveyNodes then
		self.db.global.surveyNodes = {}
	end

	if not self.db.char.digsites then
		self.db.char.digsites = {
			stats = {},
			blacklist = {}
		}
	end

	siteStats = self.db.char.digsites.stats

	setmetatable(siteStats, {
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

	blacklisted_sites = self.db.char.digsites.blacklist
	setmetatable(blacklisted_sites, {
		__index = function(t, k)
			if k then
				t[k] = false
				return t[k]
			end
		end
	})

	private.db = self.db.profile
	if not private.db.data then
		private.db.data = {}
	end
	private.db.data.imported = false

	private.digsite_frame = _G.CreateFrame("Frame", "ArchyDigSiteFrame", _G.UIParent, (private.db.general.theme == "Graphical" and "ArchyDigSiteContainer" or "ArchyMinDigSiteContainer"))
	private.digsite_frame.children = setmetatable({}, {
		__index = function(t, k)
			if k then
				local f = _G.CreateFrame("Frame", "ArchyDigSiteChildFrame" .. k, private.digsite_frame, (private.db.general.theme == "Graphical" and "ArchyDigSiteRowTemplate" or "ArchyMinDigSiteRowTemplate"))
				f:Show()
				t[k] = f
				return f
			end
		end
	})
	private.races_frame = _G.CreateFrame("Frame", "ArchyArtifactFrame", _G.UIParent, (private.db.general.theme == "Graphical" and "ArchyArtifactContainer" or "ArchyMinArtifactContainer"))
	private.races_frame.children = setmetatable({}, {
		__index = function(t, k)
			if k then
				local f = _G.CreateFrame("Frame", "ArchyArtifactChildFrame" .. k, private.races_frame, (private.db.general.theme == "Graphical" and "ArchyArtifactRowTemplate" or "ArchyMinArtifactRowTemplate"))
				f:Show()
				t[k] = f
				return f
			end
		end
	})

	private.distance_indicator_frame = _G.CreateFrame("Frame", "ArchyDistanceIndicatorFrame", _G.UIParent, "ArchyDistanceIndicator")
	local surveySpellName = _G.GetSpellInfo(80451)
	private.distance_indicator_frame.surveyButton:SetText(surveySpellName)
	private.distance_indicator_frame.surveyButton:SetWidth(private.distance_indicator_frame.surveyButton:GetTextWidth() + 20)
	private.distance_indicator_frame.circle:SetScale(0.65)

	self:UpdateFramePositions()

	LDBI:Register("Archy", ldb, private.db.general.icon)

	TrapWorldMouse()

	self:ImportOldStatsDB()
end

function Archy:UpdateFramePositions()
	self:SetFramePosition(private.distance_indicator_frame)
	self:SetFramePosition(private.digsite_frame)
	self:SetFramePosition(private.races_frame)
end

local timer_handle

function Archy:OnEnable()
	--@TODO Setup and register the options table

	_G["SLASH_ARCHY1"] = "/archy"
	_G.SlashCmdList["ARCHY"] = SlashHandler
	--self:SecureHook("SetCVar")

	self:RegisterEvent("ARTIFACT_HISTORY_READY", "ArtifactHistoryReady")
	--    self:RegisterEvent("ARTIFACT_UPDATE", "ArtifactUpdated")
	self:RegisterEvent("LOOT_OPENED", "OnPlayerLooting")
	self:RegisterEvent("LOOT_CLOSED", "OnPlayerLooting")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerLogin")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatStateChanged")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CombatStateChanged")
	self:RegisterEvent("ARTIFACT_COMPLETE", "ArtifactCompleted")
	self:RegisterEvent("ARTIFACT_DIG_SITE_UPDATED", "DigSitesUpdated")
	self:RegisterEvent("BAG_UPDATE", "BagUpdated")
	self:RegisterEvent("SKILL_LINES_CHANGED", "SkillLinesChanged")
	self:RegisterEvent("CHAT_MSG_LOOT", "LootReceived")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "PlayerCastSurvey")
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "CurrencyUpdated")

	self:ScheduleTimer("UpdatePlayerPosition", 1, true)
	self:ScheduleTimer("UpdateDigSiteFrame", 1)
	self:ScheduleTimer("UpdateRacesFrame", 1)
	self:ScheduleTimer("RefreshAll", 1)

	timer_handle = self:ScheduleRepeatingTimer("UpdatePlayerPosition", 0.1)

	private.db.general.locked = false

	Archy:UpdateDigSiteFrame()
	Archy:UpdateRacesFrame()
	ToggleDistanceIndicator()
	tomtomActive = true
	private.tomtomExists = (_G.TomTom and _G.TomTom.AddZWaypoint and _G.TomTom.RemoveWaypoint) and true or false
	self:CheckForMinimapAddons()
end

function Archy:CheckForMinimapAddons()
	local mbf = LibStub("AceAddon-3.0"):GetAddon("Minimap Button Frame", true)

	if not mbf then
		return
	end
	local foundMBF = false

	if _G.MBF.db.profile.MinimapIcons then
		for i, button in pairs(_G.MBF.db.profile.MinimapIcons) do
			local lower_button = button:lower()

			if lower_button == "archyminimap" or lower_button == "archyminimap_" then
				foundMBF = true
				break
			end
		end
		if not foundMBF then
			table.insert(_G.MBF.db.profile.MinimapIcons, "ArchyMinimap")
			self:Print("Adding Archy to the MinimapButtonFrame protected items list")
		end
	end
end

function Archy:OnDisable()
	--    self:UnregisterEvent("ARTIFACT_HISTORY_READY")
	--    self:UnregisterEvent("ARTIFACT_UPDATE")
	self:UnregisterEvent("ARTIFACT_COMPLETE")
	self:UnregisterEvent("ARTIFACT_DIG_SITE_UPDATED")
	self:UnregisterEvent("BAG_UPDATE")
	self:UnregisterEvent("SKILL_LINES_CHANGED")
	self:UnregisterEvent("CHAT_MSG_LOOT")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:CancelTimer(timer_handle)
	--self:SecureHook("SetCVar")
end

function Archy:OnProfileUpdate()
	private.db = self.db.profile
	self:ConfigUpdated()
	self:UpdateFramePositions()
end

--[[ Event Handlers ]] --
function Archy:ArtifactHistoryReady()
	for rid, artifact in pairs(artifacts) do
		local _, _, completionCount = GetArtifactStats(rid, artifact.name)
		if completionCount then
			artifact.completionCount = completionCount
		end
	end
	self:RefreshRacesDisplay()
end

function Archy:ArtifactUpdated()
	-- ignore this event for now as it's can break other Archaeology UIs
	-- Would have been nice if Blizzard passed the race index or artifact name with the event
end

function Archy:ArtifactCompleted()
	archRelatedBagUpdate = true
end

function Archy:DigSitesUpdated()
	if not playerContinent then
		return
	end
	UpdateSites()
	self:UpdateSiteDistances()
	self:RefreshDigSiteDisplay()
end

function Archy:BagUpdated()
	if not playerContinent then
		return
	end

	if not archRelatedBagUpdate then
		return
	end

	-- perform an artifact refresh here
	if keystoneLootRaceID then
		UpdateRaceArtifact(keystoneLootRaceID)
		self:ScheduleTimer("RefreshRacesDisplay", 0.5)
		keystoneLootRaceID = nil
	end

	archRelatedBagUpdate = false
end

function Archy:SkillLinesChanged()
	if not playerContinent then
		return
	end

	local rank, maxRank = GetArchaeologyRank()
	--[[
    if rank == 300 or rank == 375 or rank == 450 then
        -- Force reload of race and artifact data when outland, northrend and tol'vir become available
        LoadRaceData()
        if _G.GetNumArchaeologyRaces() > 0 then
            for rid = 1,_G.GetNumArchaeologyRaces() do
                UpdateRaceArtifact(rid)
            end
            self:UpdateRacesFrame()
            self:RefreshRacesDisplay()
        end
    end
]]

	local races_frame = private.races_frame

	if races_frame and races_frame.skillBar then
		races_frame.skillBar:SetMinMaxValues(0, maxRank)
		races_frame.skillBar:SetValue(rank)
		races_frame.skillBar.text:SetFormattedText("%s : %d/%d", _G.GetArchaeologyInfo(), rank, maxRank)
	end
end

function Archy:LootReceived(event, msg)
	local _, itemLink, amount = ParseLootMessage(msg)

	if not itemLink then
		return
	end
	local itemID = GetIDFromLink(itemLink)
	local race_id = keystoneIDToRaceID[itemID]

	if race_id then
		siteStats[lastSite.id].keystones = siteStats[lastSite.id].keystones + 1
		keystoneLootRaceID = race_id
		archRelatedBagUpdate = true
	end
end

function Archy:PlayerCastSurvey(event, unit, spell, _, _, spellid)
	if unit ~= "player" or spellid ~= SURVEY_SPELL_ID then
		return
	end

	if not playerPosition or not nearestSite then
		survey_location.map = 0
		survey_location.level = 0
		survey_location.x = 0
		survey_location.y = 0
		return
	end
	survey_location.x = playerPosition.x
	survey_location.y = playerPosition.y
	survey_location.map = playerPosition.map
	survey_location.level = playerPosition.level

	distanceIndicatorActive = true
	lastSite = nearestSite
	siteStats[lastSite.id].surveys = siteStats[lastSite.id].surveys + 1

	ToggleDistanceIndicator()
	UpdateDistanceIndicator()

	if private.db.minimap.fragmentColorBySurveyDistance then
		local min_green, max_green = 0, private.db.digsite.distanceIndicator.green or 0
		local min_yellow, max_yellow = max_green, private.db.digsite.distanceIndicator.yellow or 0
		local min_red, max_red = max_yellow, 500

		for id, poi in pairs(allPois) do
			if poi.active and poi.type == "survey" then
				local distance = astrolabe:GetDistanceToIcon(poi)

				if distance >= min_green and distance <= max_green then
					poi.icon:SetTexCoord(0.75, 1, 0.5, 0.734375)
					--                poi.poiButton.texture:SetVertexColor(0,1,0,1)
				elseif distance >= min_yellow and distance <= max_yellow then
					poi.icon:SetTexCoord(0.5, 0.734375, 0.5, 0.734375)
					--                poi.poiButton.texture:SetVertexColor(1,1,0,1)
				elseif distance >= min_red and distance <= max_red then
					poi.icon:SetTexCoord(0.25, 0.484375, 0.5, 0.734375)
					--                poi.poiButton.texture:SetVertexColor(1,0,0,1)
				end
			end
		end
	end
	tomtomActive = false
	RefreshTomTom()
	self:RefreshDigSiteDisplay()
end

function Archy:CurrencyUpdated()
	if not playerContinent or _G.GetNumArchaeologyRaces() == 0 then
		return
	end

	for race_id = 1, _G.GetNumArchaeologyRaces() do
		local _, _, _, currencyAmount = _G.GetArchaeologyRaceInfo(race_id)
		local diff = currencyAmount - (race_data[race_id].currency or 0)

		race_data[race_id].currency = currencyAmount

		if diff < 0 then
			-- we've spent fragments, aka. Solved an artifact
			artifacts[race_id].stonesAdded = 0

			if artifactSolved.raceId > 0 then
				-- announce that we have solved an artifact
				local _, _, completionCount = GetArtifactStats(race_id, artifactSolved.name)
				local text = L["You have solved %s Artifact - %s (Times completed: %d)"]:format("|cFFFFFF00" .. race_data[race_id].name .. "|r", "|cFFFFFF00" .. artifactSolved.name .. "|r", completionCount or 0)
				self:Pour(text, 1, 1, 1)

				-- reset it since we know it's been solved
				artifactSolved.raceId = 0
				artifactSolved.name = ""
				self:RefreshRacesDisplay()
			end

		elseif diff > 0 then
			-- we've gained fragments, aka. Successfully dug at a dig site

			-- update the artifact info
			UpdateRaceArtifact(race_id)

			-- deactivate the distance indicator
			distanceIndicatorActive = false
			ToggleDistanceIndicator()

			-- Increment the site stats
			IncrementDigCounter(lastSite.id)
			siteStats[lastSite.id].looted = (siteStats[lastSite.id].looted or 0) + 1
			siteStats[lastSite.id].fragments = siteStats[lastSite.id].fragments + diff

			AddSurveyNode(lastSite.id, playerPosition.map, playerPosition.level, playerPosition.x, playerPosition.y)

			survey_location.map = 0
			survey_location.level = 0
			survey_location.x = 0
			survey_location.y = 0

			UpdateMinimapPOIs(true)
			self:RefreshRacesDisplay()
			self:RefreshDigSiteDisplay()
		end
	end
end

function Archy:CombatStateChanged(event)
	if event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		blobs["Minimap"]:DrawNone()
	elseif event == "PLAYER_REGEN_ENABLED" then
		inCombat = false
	end
end


--[[ Positional functions ]] --
function Archy:UpdatePlayerPosition(force)
	if not private.db.general.show or not HasArchaeology() or _G.IsInInstance() or _G.UnitIsGhost("player") then
		return
	end

	if _G.GetCurrentMapAreaID() == -1 then
		self:UpdateSiteDistances()
		self:UpdateDigSiteFrame()
		self:RefreshDigSiteDisplay()
		return
	end
	local map, level, x, y = astrolabe:GetCurrentPlayerPosition()

	if not map or not level or (x == 0 and y == 0) then
		return
	end
	local continent = astrolabe:GetMapInfo(map, level)

	if playerPosition.x ~= x or playerPosition.y ~= y or playerPosition.map ~= map or playerPosition.level ~= level or force then
		playerPosition.x, playerPosition.y, playerPosition.map, playerPosition.level = x, y, map, level

		self:RefreshAll()
	end

	if playerContinent ~= continent then
		playerContinent = continent

		if #race_data == 0 then
			LoadRaceData()
		end
		ClearTomTomPoint()
		RefreshTomTom()
		UpdateSites()

		if _G.GetNumArchaeologyRaces() > 0 then
			for race_id = 1, _G.GetNumArchaeologyRaces() do
				UpdateRaceArtifact(race_id)
			end
			self:UpdateRacesFrame()
			self:RefreshRacesDisplay()
		end
		self:UpdateDigSiteFrame()
		self:RefreshDigSiteDisplay()
		self:UpdateFramePositions()
	end
end

function Archy:RefreshAll()
	if not _G.IsInInstance() then
		self:UpdateSiteDistances()
		UpdateDistanceIndicator()
		UpdateMinimapPOIs()
		UpdateSiteBlobs()
	end
	self:RefreshDigSiteDisplay()
end


--[[ UI functions ]] --
local function TransformSiteFrame(frame)
	if private.db.digsite.style == "Compact" then
		frame.crest:SetWidth(20)
		frame.crest:SetHeight(20)
		frame.crest.icon:SetWidth(20)
		frame.crest.icon:SetHeight(20)
		frame.zone:Hide()
		frame.distance:Hide()
		frame:SetHeight(24)
	else
		frame.crest:SetWidth(40)
		frame.crest:SetHeight(40)
		frame.crest.icon:SetWidth(40)
		frame.crest.icon:SetHeight(40)
		frame.zone:Show()
		frame.distance:Show()
		frame:SetHeight(40)
	end
end

local function TransformRaceFrame(frame)
	if private.db.artifact.style == "Compact" then
		--[[
        frame.icon:Hide()
]]

		frame.crest:ClearAllPoints()
		frame.crest:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

		frame.icon:ClearAllPoints()
		frame.icon:SetPoint("LEFT", frame.crest, "RIGHT", 0, 0)
		frame.icon:SetWidth(32)
		frame.icon:SetHeight(32)
		frame.icon.texture:SetWidth(32)
		frame.icon.texture:SetHeight(32)
		--        frame.fragmentBar:ClearAllPoints()
		--        frame.fragmentBar:SetPoint("LEFT", frame.icon, "RIGHT", 5, 0)


		frame.crest.text:Hide()
		frame.crest:SetWidth(36)
		frame.crest:SetHeight(36)
		frame.solveButton:SetText("")
		frame.solveButton:SetWidth(34)
		frame.solveButton:SetHeight(34)
		frame.solveButton:SetNormalTexture([[Interface\ICONS\TRADE_ARCHAEOLOGY_AQIR_ARTIFACTFRAGMENT]])
		frame.solveButton:SetDisabledTexture([[Interface\ICONS\TRADE_ARCHAEOLOGY_AQIR_ARTIFACTFRAGMENT]])
		frame.solveButton:GetDisabledTexture():SetBlendMode("MOD")

		frame.solveButton:ClearAllPoints()
		frame.solveButton:SetPoint("LEFT", frame.fragmentBar, "RIGHT", 5, 0)
		frame.fragmentBar.fragments:ClearAllPoints()
		frame.fragmentBar.fragments:SetPoint("RIGHT", frame.fragmentBar.keystones, "LEFT", -7, 2)
		frame.fragmentBar.keystone1:Hide()
		frame.fragmentBar.keystone2:Hide()
		frame.fragmentBar.keystone3:Hide()
		frame.fragmentBar.keystone4:Hide()
		frame.fragmentBar.artifact:SetWidth(160)

		frame:SetWidth(315 + frame.solveButton:GetWidth())
		frame:SetHeight(36)
	else
		frame.icon:ClearAllPoints()
		frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		frame.icon:SetWidth(36)
		frame.icon:SetHeight(36)
		frame.icon.texture:SetWidth(36)
		frame.icon.texture:SetHeight(36)

		frame.icon:Show()
		frame.crest.text:Show()
		frame.crest:SetWidth(24)
		frame.crest:SetHeight(24)
		frame.crest:ClearAllPoints()
		frame.crest:SetPoint("TOPLEFT", frame.icon, "BOTTOMLEFT", 0, 0)
		frame.solveButton:SetHeight(24)
		frame.solveButton:SetNormalTexture(nil)
		frame.solveButton:SetDisabledTexture(nil)
		frame.solveButton:ClearAllPoints()
		frame.solveButton:SetPoint("TOPRIGHT", frame.fragmentBar, "BOTTOMRIGHT", 0, -3)
		frame.fragmentBar.fragments:ClearAllPoints()
		frame.fragmentBar.fragments:SetPoint("RIGHT", frame.fragmentBar, "RIGHT", -5, 2)
		frame.fragmentBar.keystones:Hide()
		frame.fragmentBar.artifact:SetWidth(200)

		frame:SetWidth(295)
		frame:SetHeight(70)
	end
end

local function SetMovableState(self, value)
	self:SetMovable(value)
	self:EnableMouse(value)

	if value then
		self:RegisterForDrag("LeftButton")
	else
		self:RegisterForDrag()
	end
end

local function ApplyShadowToFontString(fs, hasShadow)
	if hasShadow then
		fs:SetShadowColor(0, 0, 0, 1)
		fs:SetShadowOffset(1, -1)
	else
		fs:SetShadowColor(0, 0, 0, 0)
		fs:SetShadowOffset(0, 0)
	end
end

function Archy:UpdateRacesFrame()
	if IsTaintable() then
		return
	end
	local races_frame = private.races_frame

	races_frame:SetScale(private.db.artifact.scale)
	races_frame:SetAlpha(private.db.artifact.alpha)
	--    private.races_frame:ClearAllPoints()
	--    private.races_frame:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", db.artifact.positionX, db.artifact.positionY)
	SetMovableState(races_frame, (not private.db.general.locked))

	local artifact_font_data = private.db.artifact.font
	local artifact_fragment_font_data = private.db.artifact.fragmentFont

	local font = LSM:Fetch("font", artifact_font_data.name)
	local fragment_font = LSM:Fetch("font", artifact_fragment_font_data.name)
	local keystone_font = LSM:Fetch("font", private.db.artifact.keystoneFont.name)

	for _, child in pairs(races_frame.children) do
		if private.db.general.theme == "Graphical" then
			child.fragmentBar.artifact:SetFont(font, artifact_font_data.size, artifact_font_data.outline)
			child.fragmentBar.artifact:SetTextColor(artifact_font_data.color.r, artifact_font_data.color.g, artifact_font_data.color.b, artifact_font_data.color.a)

			child.fragmentBar.fragments:SetFont(fragment_font, artifact_fragment_font_data.size, artifact_fragment_font_data.outline)
			child.fragmentBar.fragments:SetTextColor(artifact_fragment_font_data.color.r, artifact_fragment_font_data.color.g, artifact_fragment_font_data.color.b, artifact_fragment_font_data.color.a)

			child.fragmentBar.keystones.count:SetFont(keystone_font, private.db.artifact.keystoneFont.size, private.db.artifact.keystoneFont.outline)
			child.fragmentBar.keystones.count:SetTextColor(private.db.artifact.keystoneFont.color.r, private.db.artifact.keystoneFont.color.g, private.db.artifact.keystoneFont.color.b, private.db.artifact.keystoneFont.color.a)

			ApplyShadowToFontString(child.fragmentBar.artifact, artifact_font_data.shadow)
			ApplyShadowToFontString(child.fragmentBar.fragments, artifact_fragment_font_data.shadow)
			ApplyShadowToFontString(child.fragmentBar.keystones.count, private.db.artifact.keystoneFont.shadow)
		else
			child.fragments.text:SetFont(font, artifact_font_data.size, artifact_font_data.outline)
			child.fragments.text:SetTextColor(artifact_font_data.color.r, artifact_font_data.color.g, artifact_font_data.color.b, artifact_font_data.color.a)

			child.sockets.text:SetFont(font, artifact_font_data.size, artifact_font_data.outline)
			child.sockets.text:SetTextColor(artifact_font_data.color.r, artifact_font_data.color.g, artifact_font_data.color.b, artifact_font_data.color.a)

			child.artifact.text:SetFont(font, artifact_font_data.size, artifact_font_data.outline)
			child.artifact.text:SetTextColor(artifact_font_data.color.r, artifact_font_data.color.g, artifact_font_data.color.b, artifact_font_data.color.a)

			ApplyShadowToFontString(child.fragments.text, artifact_font_data.shadow)
			ApplyShadowToFontString(child.sockets.text, artifact_font_data.shadow)
			ApplyShadowToFontString(child.artifact.text, artifact_font_data.shadow)
		end
	end

	local borderTexture = LSM:Fetch('border', private.db.artifact.borderTexture) or [[Interface\None]]
	local backgroundTexture = LSM:Fetch('background', private.db.artifact.backgroundTexture) or [[Interface\None]]
	races_frame:SetBackdrop({
		bgFile = backgroundTexture,
		edgeFile = borderTexture,
		tile = false,
		edgeSize = 8,
		tileSize = 8,
		insets = {
			left = 2,
			top = 2,
			right = 2,
			bottom = 2
		}
	})
	races_frame:SetBackdropColor(1, 1, 1, private.db.artifact.bgAlpha)
	races_frame:SetBackdropBorderColor(1, 1, 1, private.db.artifact.borderAlpha)


	if not IsTaintable() then
		local height = races_frame.container:GetHeight() + ((private.db.general.theme == "Graphical") and 15 or 25)
		if private.db.general.showSkillBar and private.db.general.theme == "Graphical" then
			height = height + 30
		end
		races_frame:SetHeight(height)
		races_frame:SetWidth(races_frame.container:GetWidth() + ((private.db.general.theme == "Graphical") and 45 or 0))
	end

	if races_frame:IsVisible() then
		if private.db.general.stealthMode or not private.db.artifact.show or ShouldBeHidden() then
			races_frame:Hide()
		end
	else
		if not private.db.general.stealthMode and private.db.artifact.show and not ShouldBeHidden() then
			races_frame:Show()
		end
	end
end

function Archy:RefreshRacesDisplay()
	if ShouldBeHidden() or _G.GetNumArchaeologyRaces() == 0 then
		return
	end
	local maxWidth, maxHeight = 0, 0
	self:SkillLinesChanged()

	local races_frame = private.races_frame
	local topFrame = races_frame.container
	local hiddenAnchor = races_frame
	local count = 0

	if private.db.general.theme == "Minimal" then
		races_frame.title.text:SetText(L["Artifacts"])
	end

	for _, child in pairs(races_frame.children) do
		child:Hide()
	end

	for rid, race in pairs(race_data) do
		local child = races_frame.children[rid]
		local artifact = artifacts[rid]
		local _, _, completionCount = GetArtifactStats(rid, artifact.name)
		child:SetID(rid)

		if private.db.general.theme == "Graphical" then
			child.solveButton:SetText(_G.SOLVE)
			child.solveButton:SetWidth(child.solveButton:GetTextWidth() + 20)
			child.solveButton.tooltip = _G.SOLVE

			if child.style ~= private.db.artifact.style then
				TransformRaceFrame(child)
			end

			child.crest.texture:SetTexture(race.texture)
			child.crest.tooltip = race.name .. "\n" .. _G.NORMAL_FONT_COLOR_CODE .. L["Key Stones:"] .. "|r " .. race.keystone.inventory
			child.crest.text:SetText(race.name)
			child.icon.texture:SetTexture(artifact.icon)
			child.icon.tooltip = _G.HIGHLIGHT_FONT_COLOR_CODE .. artifact.name .. "|r\n" .. _G.NORMAL_FONT_COLOR_CODE .. artifact.tooltip
				.. "\n\n" .. _G.HIGHLIGHT_FONT_COLOR_CODE .. L["Solved Count: %s"]:format(_G.NORMAL_FONT_COLOR_CODE .. (completionCount or "0") .. "|r")
				.. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to open artifact in default Archaeology UI"] .. "|r"

			-- setup the bar texture here
			local barTexture = (LSM and LSM:Fetch('statusbar', private.db.artifact.fragmentBarTexture)) or _G.DEFAULT_STATUSBAR_TEXTURE
			child.fragmentBar.barTexture:SetTexture(barTexture)
			child.fragmentBar.barTexture:SetHorizTile(false)
			--            if db.artifact.fragmentBarTexture == "Archy" then
			--                child.fragmentBar.barTexture:SetTexCoord(0, 0.810546875, 0.40625, 0.5625)            -- can solve with keystones if they were attached
			--            else
			--                child.fragmentBar.barTexture:SetTexCoord(0, 0, 0.77525001764297, 0.810546875)
			--            end


			local barColor
			if artifact.rare then
				barColor = private.db.artifact.fragmentBarColors["Rare"]
				child.fragmentBar.barBackground:SetTexCoord(0, 0.72265625, 0.3671875, 0.7890625) -- rare
			else
				if completionCount == 0 then
					barColor = private.db.artifact.fragmentBarColors["FirstTime"]
				else
					barColor = private.db.artifact.fragmentBarColors["Normal"]
				end
				child.fragmentBar.barBackground:SetTexCoord(0, 0.72265625, 0, 0.411875) -- bg
			end
			child.fragmentBar:SetMinMaxValues(0, artifact.fragTotal)
			child.fragmentBar:SetValue(math.min(artifact.fragments + artifact.fragAdjust, artifact.fragTotal))

			local adjust = (artifact.fragAdjust > 0) and (" (|cFF00FF00+%d|r)"):format(artifact.fragAdjust) or ""
			child.fragmentBar.fragments:SetFormattedText("%d%s / %d", artifact.fragments, adjust, artifact.fragTotal)
			child.fragmentBar.artifact:SetText(artifact.name)
			child.fragmentBar.artifact:SetWordWrap(true)

			local endFound = false
			local artifactNameSize = child.fragmentBar:GetWidth() - 10

			if private.db.artifact.style == "Compact" then
				artifactNameSize = artifactNameSize - 40

				if artifact.sockets > 0 then
					child.fragmentBar.keystones.tooltip = L["%d Key stone sockets available"]:format(artifact.sockets)
						.. "\n" .. L["%d %ss in your inventory"]:format(race.keystone.inventory or 0, race.keystone.name or L["Key stone"])
					child.fragmentBar.keystones:Show()

					if child.fragmentBar.keystones and child.fragmentBar.keystones.count then
						child.fragmentBar.keystones.count:SetFormattedText("%d/%d", artifact.stonesAdded, artifact.sockets)
					end

					if artifact.stonesAdded > 0 then
						child.fragmentBar.keystones.icon:SetTexture(race.keystone.texture)
					else
						child.fragmentBar.keystones.icon:SetTexture(nil)
					end
				else
					child.fragmentBar.keystones:Hide()
				end
			else
				for ki = 1, (_G.ARCHAEOLOGY_MAX_STONES or 4) do
					if ki > artifact.sockets or not race.keystone.name then
						child.fragmentBar["keystone" .. ki]:Hide()
					else
						child.fragmentBar["keystone" .. ki].icon:SetTexture(race.keystone.texture)
						if ki <= artifact.stonesAdded then
							child.fragmentBar["keystone" .. ki].icon:Show()
							child.fragmentBar["keystone" .. ki].tooltip = _G.ARCHAEOLOGY_KEYSTONE_REMOVE_TOOLTIP:format(race.keystone.name)
							child.fragmentBar["keystone" .. ki]:Enable()
						else
							child.fragmentBar["keystone" .. ki].icon:Hide()
							child.fragmentBar["keystone" .. ki].tooltip = _G.ARCHAEOLOGY_KEYSTONE_ADD_TOOLTIP:format(race.keystone.name)
							child.fragmentBar["keystone" .. ki]:Enable()
							if endFound then
								child.fragmentBar["keystone" .. ki]:Disable()
							end
							endFound = true
						end
						child.fragmentBar["keystone" .. ki]:Show()
					end
				end
			end

			if artifact.canSolve or (artifact.stonesAdded > 0 and artifact.canSolveStone) then
				child.solveButton:Enable()
				barColor = private.db.artifact.fragmentBarColors["Solvable"]
			else
				if artifact.canSolveStone then
					barColor = private.db.artifact.fragmentBarColors["AttachToSolve"]
				end
				child.solveButton:Disable()
			end

			child.fragmentBar.barTexture:SetVertexColor(barColor.r, barColor.g, barColor.b, 1)

			artifactNameSize = artifactNameSize - child.fragmentBar.fragments:GetStringWidth()
			child.fragmentBar.artifact:SetWidth(artifactNameSize)

		else
			local fragmentColor = (artifact.canSolve and "|cFF00FF00" or (artifact.canSolveStone and "|cFFFFFF00" or ""))
			local nameColor = (artifact.rare and "|cFF0070DD" or ((completionCount and completionCount > 0) and _G.GRAY_FONT_COLOR_CODE or ""))
			child.fragments.text:SetFormattedText("%s%d/%d", fragmentColor, artifact.fragments, artifact.fragTotal)

			if race_data[rid].keystone.inventory > 0 or artifact.sockets > 0 then
				child.sockets.text:SetFormattedText("%d/%d", race_data[rid].keystone.inventory, artifact.sockets)
				child.sockets.tooltip = L["%d Key stone sockets available"]:format(artifact.sockets) .. "\n" .. L["%d %ss in your inventory"]:format(race.keystone.inventory or 0, race.keystone.name or L["Key stone"])
			else
				child.sockets.text:SetText("")
				child.sockets.tooltip = nil
			end
			child.crest:SetNormalTexture(race_data[rid].texture)
			child.crest:SetHighlightTexture(race_data[rid].texture)
			child.crest.tooltip = artifact.name .. "\n" .. _G.NORMAL_FONT_COLOR_CODE .. _G.RACE .. " - " .. "|r" .. _G.HIGHLIGHT_FONT_COLOR_CODE .. race_data[rid].name .. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to solve without key stones"] .. "\n" .. L["Right-Click to solve with key stones"]

			child.artifact.text:SetFormattedText("%s%s", nameColor, artifact.name)
			child.artifact.tooltip = _G.HIGHLIGHT_FONT_COLOR_CODE .. artifact.name .. "|r\n" .. _G.NORMAL_FONT_COLOR_CODE .. artifact.tooltip
				.. "\n\n" .. _G.HIGHLIGHT_FONT_COLOR_CODE .. L["Solved Count: %s"]:format(_G.NORMAL_FONT_COLOR_CODE .. (completionCount or "0") .. "|r")
				.. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to open artifact in default Archaeology UI"] .. "|r"

			child.artifact:SetWidth(child.artifact.text:GetStringWidth())
			child.artifact:SetHeight(child.artifact.text:GetStringHeight())
			child:SetWidth(child.fragments:GetWidth() + child.sockets:GetWidth() + child.crest:GetWidth() + child.artifact:GetWidth() + 30)
		end

		if not private.db.artifact.blacklist[rid] and artifact.fragTotal > 0 and (not private.db.artifact.filter or _G.tContains(ContinentRaces(playerContinent), rid)) then
			child:ClearAllPoints()

			if topFrame == races_frame.container then
				child:SetPoint("TOPLEFT", topFrame, "TOPLEFT", 0, 0)
			else
				child:SetPoint("TOPLEFT", topFrame, "BOTTOMLEFT", 0, -5)
			end
			topFrame = child
			child:Show()
			maxHeight = maxHeight + child:GetHeight() + 5
			maxWidth = (maxWidth > child:GetWidth()) and maxWidth or child:GetWidth()
			count = count + 1
		else
			child:Hide()
		end
	end
	local containerXofs = 0

	if private.db.general.theme == "Graphical" and private.db.artifact.style == "Compact" then
		maxHeight = maxHeight + 10
		containerXofs = -10
	end


	races_frame.container:SetHeight(maxHeight)
	races_frame.container:SetWidth(maxWidth)

	if races_frame.skillBar then
		races_frame.skillBar:SetWidth(maxWidth)
		races_frame.skillBar.border:SetWidth(maxWidth + 9)

		if private.db.general.showSkillBar then
			races_frame.skillBar:Show()
			races_frame.container:ClearAllPoints()
			races_frame.container:SetPoint("TOP", races_frame.skillBar, "BOTTOM", containerXofs, -10)
			maxHeight = maxHeight + 30
		else
			races_frame.skillBar:Hide()
			races_frame.container:ClearAllPoints()
			races_frame.container:SetPoint("TOP", races_frame, "TOP", containerXofs, -20)
			maxHeight = maxHeight + 10
		end
	else
		races_frame.container:ClearAllPoints()
		races_frame.container:SetPoint("TOP", races_frame, "TOP", containerXofs, -20)
		maxHeight = maxHeight + 10
	end

	if not IsTaintable() then
		if count == 0 then races_frame:Hide() end
		races_frame:SetHeight(maxHeight + ((private.db.general.theme == "Graphical") and 15 or 25))
		races_frame:SetWidth(maxWidth + ((private.db.general.theme == "Graphical") and 45 or 0))
	end
end

function Archy:UpdateDigSiteFrame()
	if IsTaintable() then
		return
	end
	private.digsite_frame:SetScale(private.db.digsite.scale)
	private.digsite_frame:SetAlpha(private.db.digsite.alpha)

	local borderTexture = LSM:Fetch('border', private.db.digsite.borderTexture) or [[Interface\None]]
	local backgroundTexture = LSM:Fetch('background', private.db.digsite.backgroundTexture) or [[Interface\None]]
	private.digsite_frame:SetBackdrop({ bgFile = backgroundTexture, edgeFile = borderTexture, tile = false, edgeSize = 8, tileSize = 8, insets = { left = 2, top = 2, right = 2, bottom = 2 } })
	private.digsite_frame:SetBackdropColor(1, 1, 1, private.db.digsite.bgAlpha)
	private.digsite_frame:SetBackdropBorderColor(1, 1, 1, private.db.digsite.borderAlpha)
	--SetMovableState(private.digsite_frame, (not db.general.locked))

	local font = LSM:Fetch("font", private.db.digsite.font.name)
	local zoneFont = LSM:Fetch("font", private.db.digsite.zoneFont.name)
	local digsite_font = private.db.digsite.font

	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteFrame.site.name:SetFont(font, digsite_font.size, digsite_font.outline)
		siteFrame.digCounter.value:SetFont(font, digsite_font.size, digsite_font.outline)
		siteFrame.site.name:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
		siteFrame.digCounter.value:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
		ApplyShadowToFontString(siteFrame.site.name, digsite_font.shadow)
		ApplyShadowToFontString(siteFrame.digCounter.value, digsite_font.shadow)

		if private.db.general.theme == "Graphical" then
			local zone_font = private.db.digsite.zoneFont

			siteFrame.zone.name:SetFont(zoneFont, zone_font.size, zone_font.outline)
			siteFrame.distance.value:SetFont(zoneFont, zone_font.size, zone_font.outline)
			siteFrame.zone.name:SetTextColor(zone_font.color.r, zone_font.color.g, zone_font.color.b, zone_font.color.a)
			siteFrame.distance.value:SetTextColor(zone_font.color.r, zone_font.color.g, zone_font.color.b, zone_font.color.a)
			ApplyShadowToFontString(siteFrame.zone.name, zone_font.shadow)
			ApplyShadowToFontString(siteFrame.distance.value, zone_font.shadow)
		else
			siteFrame.zone.name:SetFont(font, digsite_font.size, digsite_font.outline)
			siteFrame.distance.value:SetFont(font, digsite_font.size, digsite_font.outline)
			siteFrame.zone.name:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
			siteFrame.distance.value:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
			ApplyShadowToFontString(siteFrame.zone.name, digsite_font.shadow)
			ApplyShadowToFontString(siteFrame.distance.value, digsite_font.shadow)
		end
	end

	local cid = continentMapToID[playerContinent]

	if private.digsite_frame:IsVisible() then
		if private.db.general.stealthMode or not private.db.digsite.show or ShouldBeHidden() or not digsites[cid] or #digsites[cid] == 0 then
			private.digsite_frame:Hide()
		end
	else
		if not private.db.general.stealthMode and private.db.digsite.show and not ShouldBeHidden() and digsites[cid] and #digsites[cid] > 0 then
			private.digsite_frame:Show()
		end
	end
end

function Archy:ShowDigSiteTooltip(digsite)
	local site_id = digsite:GetParent():GetID()
	local normal_font = _G.NORMAL_FONT_COLOR_CODE
	local highlight_font = _G.HIGHLIGHT_FONT_COLOR_CODE

	digsite.tooltip = digsite.name:GetText()
	digsite.tooltip = digsite.tooltip .. ("\n%s%s%s%s|r"):format(normal_font, _G.ZONE .. ": ", highlight_font, digsite:GetParent().zone.name:GetText())
	digsite.tooltip = digsite.tooltip .. ("\n\n%s%s %s%s|r"):format(normal_font, L["Surveys:"], highlight_font, siteStats[site_id].surveys or 0)
	digsite.tooltip = digsite.tooltip .. ("\n%s%s %s%s|r"):format(normal_font, L["Digs"] .. ": ", highlight_font, siteStats[site_id].looted or 0)
	digsite.tooltip = digsite.tooltip .. ("\n%s%s %s%s|r"):format(normal_font, _G.ARCHAEOLOGY_RUNE_STONES .. ": ", highlight_font, siteStats[site_id].fragments or 0)
	digsite.tooltip = digsite.tooltip .. ("\n%s%s %s%s|r"):format(normal_font, L["Key Stones:"], highlight_font, siteStats[site_id].keystones or 0)
	digsite.tooltip = digsite.tooltip .. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to view the zone map"]

	if Archy:IsSiteBlacklisted(digsite.siteName) then
		digsite.tooltip = digsite.tooltip .. "\n" .. L["Right-Click to remove from blacklist"]
	else
		digsite.tooltip = digsite.tooltip .. "\n" .. L["Right-Click to blacklist"]
	end
	_G.GameTooltip:SetOwner(digsite, "ANCHOR_BOTTOMRIGHT")
	_G.GameTooltip:SetText(digsite.tooltip, _G.NORMAL_FONT_COLOR[1], _G.NORMAL_FONT_COLOR[2], _G.NORMAL_FONT_COLOR[3], 1, true)
end

function Archy:ResizeDigSiteDisplay()
	if private.db.general.theme == "Graphical" then
		self:ResizeGraphicalDigSiteDisplay()
	else
		self:ResizeMinimalDigSiteDisplay()
	end
end

function Archy:ResizeMinimalDigSiteDisplay()
	local maxWidth, maxHeight = 0, 0
	local topFrame = private.digsite_frame.container
	local siteIndex = 0
	local maxNameWidth, maxZoneWidth, maxDistWidth, maxDigCounterWidth = 0, 0, 70, 20
	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteIndex = siteIndex + 1
		siteFrame.zone:SetWidth(siteFrame.zone.name:GetStringWidth())
		siteFrame.distance:SetWidth(siteFrame.distance.value:GetStringWidth())
		siteFrame.site:SetWidth(siteFrame.site.name:GetStringWidth())
		local width
		local nameWidth = siteFrame.site:GetWidth()
		local zoneWidth = siteFrame.zone:GetWidth()
		if maxNameWidth < nameWidth then maxNameWidth = nameWidth end
		if maxZoneWidth < zoneWidth then maxZoneWidth = zoneWidth end
		if maxDistWidth < siteFrame.distance:GetWidth() then maxDistWidth = siteFrame.distance:GetWidth() end
		maxHeight = maxHeight + siteFrame:GetHeight() + 5

		siteFrame:ClearAllPoints()
		if siteIndex == 1 then siteFrame:SetPoint("TOP", topFrame, "TOP", 0, 0) else siteFrame:SetPoint("TOP", topFrame, "BOTTOM", 0, -5) end
		topFrame = siteFrame
	end

	if not private.db.digsite.minimal.showDistance then
		maxDistWidth = 0
	end

	if not private.db.digsite.minimal.showZone then
		maxZoneWidth = 0
	end

	if not private.db.digsite.minimal.showDigCounter then
		maxDigCounterWidth = 0
	end
	maxWidth = 57 + maxDigCounterWidth + maxNameWidth + maxZoneWidth + maxDistWidth

	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteFrame.zone:SetWidth(maxZoneWidth == 0 and 1 or maxZoneWidth)
		siteFrame.site:SetWidth(maxNameWidth)
		siteFrame.distance:SetWidth(maxDistWidth == 0 and 1 or maxDistWidth)
		siteFrame:SetWidth(maxWidth)
		siteFrame.distance:SetAlpha(private.db.digsite.minimal.showDistance and 1 or 0)
		siteFrame.zone:SetAlpha(private.db.digsite.minimal.showZone and 1 or 0)
	end
	local cpoint, crelTo, crelPoint, cxOfs, cyOfs = private.digsite_frame.container:GetPoint()

	private.digsite_frame.container:SetWidth(maxWidth)

	private.digsite_frame.container:SetHeight(maxHeight)
	if not IsTaintable() then
		-- private.digsite_frame:SetHeight(private.digsite_frame.container:GetHeight() + cyOfs + 40)
		private.digsite_frame:SetHeight(maxHeight + cyOfs + 40)
		private.digsite_frame:SetWidth(maxWidth + cxOfs + 30)
	end
end

function Archy:ResizeGraphicalDigSiteDisplay()
	local maxWidth, maxHeight = 0, 0
	local topFrame = private.digsite_frame.container
	local siteIndex = 0
	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteIndex = siteIndex + 1
		siteFrame.zone:SetWidth(siteFrame.zone.name:GetStringWidth())
		siteFrame.distance:SetWidth(siteFrame.distance.value:GetStringWidth())
		siteFrame.site:SetWidth(siteFrame.site.name:GetStringWidth())
		local width
		local nameWidth = siteFrame.site:GetWidth()
		local zoneWidth = siteFrame.zone:GetWidth() + 10
		if nameWidth > zoneWidth then
			width = siteFrame.crest:GetWidth() + nameWidth + siteFrame.digCounter:GetWidth() + 6
		else
			width = siteFrame.crest:GetWidth() + zoneWidth + siteFrame.distance:GetWidth() + 6
		end
		if width > maxWidth then maxWidth = width end
		maxHeight = maxHeight + siteFrame:GetHeight() + 5

		siteFrame:ClearAllPoints()
		if siteIndex == 1 then siteFrame:SetPoint("TOP", topFrame, "TOP", 0, 0) else siteFrame:SetPoint("TOP", topFrame, "BOTTOM", 0, -5) end
		topFrame = siteFrame
	end
	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteFrame:SetWidth(maxWidth)
	end
	local cpoint, crelTo, crelPoint, cxOfs, cyOfs = private.digsite_frame.container:GetPoint()

	private.digsite_frame.container:SetWidth(maxWidth)

	private.digsite_frame.container:SetHeight(maxHeight)
	if not IsTaintable() then
		-- private.digsite_frame:SetHeight(private.digsite_frame.container:GetHeight() + cyOfs + 40) -- masahikatao on wowinterface
		private.digsite_frame:SetHeight(maxHeight + cyOfs + 40)
		private.digsite_frame:SetWidth(maxWidth + cxOfs + 30)
	end
end

function Archy:RefreshDigSiteDisplay()
	if ShouldBeHidden() then
		return
	end
	local continent_id = continentMapToID[playerContinent]

	if not continent_id or not digsites[continent_id] or #digsites[continent_id] == 0 then
		return
	end

	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteFrame:Hide()
	end

	for _, site in pairs(digsites[continent_id]) do
		if not site.distance then
			return
		end
	end

	for siteIndex, site in pairs(digsites[continent_id]) do
		local siteFrame = private.digsite_frame.children[siteIndex]
		local count = siteStats[site.id].counter

		if private.db.general.theme == "Graphical" then
			if siteFrame.style ~= private.db.digsite.style then
				TransformSiteFrame(siteFrame)
			end
			count = (count and count > 0) and tostring(count) or ""
		else
			count = (count and tostring(count) or "0") .. "/3"
		end

		siteFrame.distance.value:SetFormattedText(L["%d yards"], site.distance)
		siteFrame.digCounter.value:SetText(count)

		if Archy:IsSiteBlacklisted(site.name) then
			siteFrame.site.name:SetFormattedText("|cFFFF0000%s", site.name)
		else
			siteFrame.site.name:SetText(site.name)
		end

		if siteFrame.site.siteName ~= site.name then
			siteFrame.crest.icon:SetTexture(race_data[site.raceId].texture)
			siteFrame.crest.tooltip = race_data[site.raceId].name
			siteFrame.zone.name:SetText(site.zoneName)
			siteFrame.site.siteName = site.name
			siteFrame.site.zoneId = site.zoneId
			siteFrame:SetID(site.id)
		end
		siteFrame:Show()
	end
	self:ResizeDigSiteDisplay()
end

function Archy:SetFramePosition(frame)
	local bPoint, bRelativeTo, bRelativePoint, bXofs, bYofs

	if not frame.isMoving then
		bRelativeTo = _G.UIParent
		if frame == private.digsite_frame then
			bPoint, bRelativePoint, bXofs, bYofs = unpack(private.db.digsite.position)
		elseif frame == private.races_frame then
			bPoint, bRelativePoint, bXofs, bYofs = unpack(private.db.artifact.position)
		elseif frame == private.distance_indicator_frame then
			if not private.db.digsite.distanceIndicator.undocked then
				bRelativeTo = private.digsite_frame
				bPoint, bRelativePoint, bXofs, bYofs = "CENTER", "TOPLEFT", 50, -5
				frame:SetParent(private.digsite_frame)
			else
				frame:SetParent(_G.UIParent)
				bPoint, bRelativePoint, bXofs, bYofs = unpack(private.db.digsite.distanceIndicator.position)
			end
		end

		frame:ClearAllPoints()
		frame:SetPoint(bPoint, bRelativeTo, bRelativePoint, bXofs, bYofs)
		frame:SetFrameLevel(2)

		if frame:GetParent() == _G.UIParent and not IsTaintable() and not private.db.general.locked then
			frame:SetUserPlaced(false)
		end
	end
end

function Archy:SaveFramePosition(frame)
	local bPoint, bRelativeTo, bRelativePoint, bXofs, bYofs = frame:GetPoint()
	local width, height
	local anchor, position

	if frame == private.digsite_frame then
		anchor = Archy.db.profile.digsite.anchor
		position = Archy.db.profile.digsite.position
	elseif frame == private.races_frame then
		anchor = Archy.db.profile.artifact.anchor
		position = Archy.db.profile.artifact.position
	elseif frame == private.distance_indicator_frame then
		anchor = Archy.db.profile.digsite.distanceIndicator.anchor
		position = Archy.db.profile.digsite.distanceIndicator.position
	end

	if not anchor or not position then
		return
	end

	if anchor == bPoint then
		position = { bPoint, bRelativePoint, bXofs, bYofs }
	else
		width = frame:GetWidth()
		height = frame:GetHeight()

		if bPoint == "TOP" then
			bXofs = bXofs - (width / 2)
		elseif bPoint == "LEFT" then
			bYofs = bYofs + (height / 2)
		elseif bPoint == "BOTTOMLEFT" then
			bYofs = bYofs + height
		elseif bPoint == "TOPRIGHT" then
			bXofs = bXofs - width
		elseif bPoint == "RIGHT" then
			bYofs = bYofs + (height / 2)
			bXofs = bXofs - width
		elseif bPoint == "BOTTOM" then
			bYofs = bYofs + height
			bXofs = bXofs - (width / 2)
		elseif bPoint == "BOTTOMRIGHT" then
			bYofs = bYofs + height
			bXofs = bXofs - width
		elseif bPoint == "CENTER" then
			bYofs = bYofs + (height / 2)
			bXofs = bXofs - (width / 2)
		end

		if anchor == "TOPRIGHT" then
			bXofs = bXofs + width
		elseif anchor == "BOTTOMRIGHT" then
			bYofs = bYofs - height
			bXofs = bXofs + width
		elseif anchor == "BOTTOMLEFT" then
			bYofs = bYofs - height
		end

		position = {
			anchor,
			bRelativePoint,
			bXofs,
			bYofs
		}
		if frame == private.digsite_frame then
			private.db.digsite.position = position
		elseif frame == private.races_frame then
			private.db.artifact.position = position
		elseif frame == private.distance_indicator_frame then
			private.db.digsite.distanceIndicator.position = position
		end
	end

	self:OnProfileUpdate()
	--Archy:SetFramePosition(frame)
end




--[[
    Hook World Frame Mouse Interaction - Credit to Sutorix for his implementation of this in Fishing Buddy
    This code is quite raw and does need some cleaning up as it is experimental at best
]] --
-- handle option keys for enabling casting
local function NormalHijackCheck()
	-- if ( not IsTaintable() and db.general.easyCast and not ShouldBeHidden() ) then -- karl_w_w
	if (not IsTaintable() and private.db.general.easyCast and not ShouldBeHidden() and 0 ~= _G.ArchaeologyMapUpdateAll()) then
		return true
	end
end

local HijackCheck = NormalHijackCheck

local function SetHijackCheck(func)
	if not func then
		func = NormalHijackCheck
	end
	HijackCheck = func
end

local sabutton
local function CreateSAButton(name, postclick)
	if sabutton then
		return
	end
	local btn = _G.CreateFrame("Button", name, _G.UIParent, "SecureActionButtonTemplate")
	btn:SetPoint("LEFT", _G.UIParent, "RIGHT", 10000, 0)
	btn:SetFrameStrata("LOW")
	btn:EnableMouse(true)
	btn:RegisterForClicks("RightButtonUp")
	btn:SetScript("PostClick", postclick)
	btn:Hide()
	btn.name = name

	sabutton = btn

	return btn
end

local function GetSurveySkillInfo()
	local _, _, arch = _G.GetProfessions()

	if arch then
		local name = _G.GetProfessionInfo(arch)
		return true, name
	end
	return false, _G.PROFESSIONS_ARCHAEOLOGY
end

local ActionBarID
local SURVEYTEXTURE = "Interface\\Icons\\INV_Misc_Shovel_01"
local function GetSurveyActionBarID(force)
	if force or not ActionBarID then
		for slot = 1, 72 do
			if _G.HasAction(slot) and not _G.IsAttackAction(slot) then
				local action_type, _, _ = _G.GetActionInfo(slot)

				if action_type == "spell" then
					local tex = _G.GetActionTexture(slot)

					if tex and tex == SURVEYTEXTURE then
						ActionBarID = slot
						break
					end
				end
			end
		end
	end
	return ActionBarID
end

local function InvokeSurvey(useaction, btn)
	btn = btn or sabutton

	if not btn then
		return
	end
	local _, name = GetSurveySkillInfo()
	local findid = GetSurveyActionBarID()

	if not useaction or not findid then
		btn:SetAttribute("type", "spell")
		btn:SetAttribute("spell", 80451)
		btn:SetAttribute("action", nil)
	else
		btn:SetAttribute("type", "action")
		btn:SetAttribute("action", findid)
		btn:SetAttribute("spell", nil)
	end
end

local function OverrideClick(btn)
	btn = btn or sabutton

	if not sabutton then
		return
	end
	_G.SetOverrideBindingClick(btn, true, "BUTTON2", btn.name)
end

local function CentralCasting()
	InvokeSurvey(true)
	OverrideClick()
	OverrideOn = true
end

local lastClickTime
local ACTIONDOUBLEWAIT = 0.4
local MINACTIONDOUBLECLICK = 0.05
local isLooting = false

local function CheckForDoubleClick()
	if not isLooting and lastClickTime then
		local pressTime = _G.GetTime()
		local doubleTime = pressTime - lastClickTime

		if doubleTime < ACTIONDOUBLEWAIT and doubleTime > MINACTIONDOUBLECLICK then
			lastClickTime = nil
			return true
		end
	end
	lastClickTime = _G.GetTime()
	return false
end

local function ExtendDoubleClick()
	if not lastClickTime then
		return
	end
	lastClickTime = lastClickTime + ACTIONDOUBLEWAIT / 2
end

local SavedWFOnMouseDown

-- handle mouse up and mouse down in the WorldFrame so that we can steal
-- the hardware events to implement 'Easy Cast'
-- Thanks to the Cosmos team for figuring this one out -- I didn't realize
-- that the mouse handler in the WorldFrame got everything first!
local function WF_OnMouseDown(...)
	-- Only steal 'right clicks' (self is arg #1!)
	local button = select(2, ...)

	if button == "RightButton" and HijackCheck() then
		if CheckForDoubleClick() then
			-- We're stealing the mouse-up event, make sure we exit MouseLook
			if IsMouselooking() and not InCombatLockdown() then
				MouselookStop()
			end
			CentralCasting()
		end
	end

	if SavedWFOnMouseDown then
		SavedWFOnMouseDown(...)
	end
end

local function SafeHookMethod(object, method, new_method)
	local oldValue = object[method]

	if oldValue ~= _G[new_method] then
		object[method] = new_method
		return true
	end
	return false
end

local function SafeHookScript(frame, handlername, newscript)
	local oldValue = frame:GetScript(handlername)
	frame:SetScript(handlername, newscript)
	return oldValue
end


function TrapWorldMouse()
	if WorldFrame.OnMouseDown then
		hooksecurefunc(WorldFrame, "OnMouseDown", WF_OnMouseDown)
	else
		SavedWFOnMouseDown = SafeHookScript(WorldFrame, "OnMouseDown", WF_OnMouseDown)
	end
end

function Archy:CheckOverride()
	if not IsTaintable() then
		ClearOverrideBindings(Archy_SurveyButton)
	end
	OverrideOn = false
end

function Archy:OnPlayerLogin()
	CreateSAButton("Archy_SurveyButton", Archy.CheckOverride)
end

function Archy:OnPlayerLooting(event, ...)
	isLooting = (event == "LOOT_OPENED")
	local autoLootEnabled = ...

	if autoLootEnabled == 1 then
		return
	end

	if isLooting and private.db.general.autoLoot then
		for slotNum = 1, _G.GetNumLootItems() do
			if _G.LootSlotIsCurrency(slotNum) then
				_G.LootSlot(slotNum)
			elseif _G.LootSlotIsItem(slotNum) then
				local link = _G.GetLootSlotLink(slotNum)

				if link then
					local itemID = GetIDFromLink(link)

					if itemID and keystoneIDToRaceID[itemID] then
						_G.LootSlot(slotNum)
					end
				end
			end
		end
	end
end
