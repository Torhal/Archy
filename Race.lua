-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-- Functions
local pairs = _G.pairs

-- Libraries
local math = _G.math

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale("Archy", false)
local Archy = LibStub("AceAddon-3.0"):GetAddon("Archy")

local Races = {}
private.Races = Races

local RaceArtifactProcessingQueue = {}
private.RaceArtifactProcessingQueue = RaceArtifactProcessingQueue

local RaceKeystoneProcessingQueue = {}
private.RaceKeystoneProcessingQueue = RaceKeystoneProcessingQueue

-----------------------------------------------------------------------
-- Local constants.
-----------------------------------------------------------------------
local Race = {}
local raceMetatable = {
	__index = Race
}

-----------------------------------------------------------------------
-- Helpers.
-----------------------------------------------------------------------
function private.AddRace(raceID)
	if _G.GetNumArchaeologyRaces() == 0 then
		-- TODO: Debug output
		return
	end

	local existingRace = Races[raceID]
	if existingRace then
		-- TODO: Debug output
		return
	end

	local raceName, raceTexture, keystoneItemID, currencyAmount = _G.GetArchaeologyRaceInfo(raceID)
	local keystoneName, _, _, _, _, _, _, _, _, keystoneTexture, _ = _G.GetItemInfo(keystoneItemID)

	local race = _G.setmetatable({
		ArtifactItemIDs = {},
		ArtifactSpellIDs = {},
		currency = currencyAmount,
		id = raceID,
		name = raceName,
		texture = raceTexture,
		artifact = {
			canSolve = false,
			fragments = 0,
			fragments_required = 0,
			icon = "",
			keystones_added = 0,
			keystone_adjustment = 0,
			name = "",
			sockets = 0,
			tooltip = "",
		},
		keystone = {
			id = keystoneItemID,
			name = keystoneName,
			texture = keystoneTexture,
			inventory = 0
		}
	}, raceMetatable)

	Races[raceID] = race

	local artifactNameToInfoIndexMapping = {}
	for artifactIndex = 1, _G.GetNumArtifactsByRace(raceID) do
		local artifactName = _G.GetArtifactInfoByRace(raceID, artifactIndex)
		artifactNameToInfoIndexMapping[artifactName] = artifactIndex
	end
	race.ArtifactNameToInfoIndexMapping = artifactNameToInfoIndexMapping

	if keystoneItemID and keystoneItemID > 0 and (not keystoneName or keystoneName == "") then
		RaceKeystoneProcessingQueue[race] = keystoneItemID
		Archy:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	end

	for itemID, data in pairs(private.ARTIFACTS[raceID]) do
		local artifactName = _G.GetItemInfo(itemID)
		if artifactName then
			race.ArtifactItemIDs[artifactName] = data.itemID
			race.ArtifactSpellIDs[artifactName] = data.spellID
		else
			RaceArtifactProcessingQueue[data] = race
			Archy:RegisterEvent("GET_ITEM_INFO_RECEIVED")
		end
	end

	race:UpdateArtifact()

	return Races[raceID]
end

-----------------------------------------------------------------------
-- Race methods.
-----------------------------------------------------------------------
function Race:GetArtifactCompletionDataByName(artifactName)
	if not artifactName or artifactName == "" then
		return
	end

	local artifactIndex = self.ArtifactNameToInfoIndexMapping[artifactName]
	if not artifactIndex then
		return 0, 0, 0
	end

	local _, _, _, _, _, _, _, firstCompletionTime, completionCount = _G.GetArtifactInfoByRace(self.id, artifactIndex)
	return artifactIndex, firstCompletionTime, completionCount
end

function Race:IsOnArtifactBlacklist()
	return private.db.artifact.blacklist[self.id]
end

function Race:KeystoneSocketOnClick(mouseButtonName)
	local artifact = self.artifact

	if mouseButtonName == "LeftButton" and artifact.keystones_added < artifact.sockets and artifact.keystones_added < self.keystone.inventory then
		artifact.keystones_added = artifact.keystones_added + 1
	elseif mouseButtonName == "RightButton" and artifact.keystones_added > 0 then
		artifact.keystones_added = artifact.keystones_added - 1
	end

	self:UpdateArtifact()
end

function Race:UpdateArtifact()
	if _G.GetNumArtifactsByRace(self.id) == 0 then
		return
	end

	if _G.ArchaeologyFrame and _G.ArchaeologyFrame:IsVisible() then
		_G.ArchaeologyFrame_ShowArtifact(self.id)
	end
	_G.SetSelectedArtifact(self.id)

	local artifactName, _, rarity, icon, spellDescription, numSockets = _G.GetSelectedArtifactInfo()
	local baseFragments, adjustedFragments, totalFragments = _G.GetArtifactProgress()

	local artifact = self.artifact
	artifact.canSolve = _G.CanSolveArtifact()
	artifact.canSolveInventory = nil
	artifact.canSolveStone = nil
	artifact.completionCount = 0
	artifact.fragments = baseFragments
	artifact.fragments_required = totalFragments
	artifact.icon = icon
	artifact.isRare = (rarity ~= 0)
	artifact.itemID = self.ArtifactItemIDs[artifactName]
	artifact.keystone_adjustment = 0
	artifact.name = artifactName
	artifact.sockets = numSockets
	artifact.spellID = self.ArtifactSpellIDs[artifactName]
	artifact.tooltip = spellDescription

	self.keystone.inventory = _G.GetItemCount(self.keystone.id) or 0

	local keystoneInventory = self.keystone.inventory
	local prevAdded = math.min(artifact.keystones_added, keystoneInventory, numSockets)

	if private.db.artifact.autofill[self.id] then
		prevAdded = math.min(keystoneInventory, numSockets)
	end
	artifact.keystones_added = math.min(keystoneInventory, numSockets)

	-- TODO: This whole section looks like a needlessly convoluted way of doing things.
	if artifact.keystones_added > 0 and numSockets > 0 then
		for index = 1, math.min(artifact.keystones_added, numSockets) do
			_G.SocketItemToArtifact()

			if not _G.ItemAddedToArtifact(index) then
				break
			end

			if index == prevAdded then
				_, adjustedFragments = _G.GetArtifactProgress()
				artifact.keystone_adjustment = adjustedFragments
				artifact.canSolveStone = _G.CanSolveArtifact()
			end
		end
		artifact.canSolveInventory = _G.CanSolveArtifact()

		if prevAdded > 0 and artifact.keystone_adjustment <= 0 then
			_, adjustedFragments = _G.GetArtifactProgress()
			artifact.keystone_adjustment = adjustedFragments
			artifact.canSolveStone = _G.CanSolveArtifact()
		end
	end
	artifact.keystones_added = prevAdded

	_G.RequestArtifactCompletionHistory()

	if not private.db.general.show or self:IsOnArtifactBlacklist() then
		return
	end

	if not artifact.hasAnnounced and ((private.db.artifact.announce and artifact.canSolve) or (private.db.artifact.keystoneAnnounce and artifact.canSolveInventory)) then
		artifact.hasAnnounced = true
		Archy:Pour(L["You can solve %s Artifact - %s (Fragments: %d of %d)"]:format("|cFFFFFF00" .. self.name .. "|r", "|cFFFFFF00" .. artifact.name .. "|r", artifact.fragments + artifact.keystone_adjustment, artifact.fragments_required), 1, 1, 1)
	end

	if not artifact.hasPinged and ((private.db.artifact.ping and artifact.canSolve) or (private.db.artifact.keystonePing and artifact.canSolveInventory)) then
		artifact.hasPinged = true
		_G.PlaySoundFile([[Interface\AddOns\Archy\Media\dingding.mp3]])
	end
end
