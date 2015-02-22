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
	local existingRace = Races[raceID]
	if existingRace then
		-- TODO: Debug output
		return
	end

	local raceName, raceTexture, keystoneItemID, currencyAmount = _G.GetArchaeologyRaceInfo(raceID)
	local keystoneName, _, _, _, _, _, _, _, _, keystoneTexture, _ = _G.GetItemInfo(keystoneItemID)

	local race = _G.setmetatable({
		Artifacts = {},
		currency = currencyAmount,
		currentProject = nil,
		ID = raceID,
		name = raceName,
		texture = raceTexture,
		keystone = {
			ID = keystoneItemID,
			inventory = 0,
			name = keystoneName,
			texture = keystoneTexture,
		},
	}, raceMetatable)

	Races[raceID] = race

	if keystoneItemID and keystoneItemID > 0 and (not keystoneName or keystoneName == "") then
		RaceKeystoneProcessingQueue[race] = keystoneItemID
		Archy:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	end

	local artifactNameToInfoIndexMapping = {}
	for artifactIndex = 1, _G.GetNumArtifactsByRace(raceID) do
		local artifactName, artifactDescription, artifactRarity, artifactIcon, hoverDescription, keystoneCount, bgTexture, firstCompletionTime, completionCount = _G.GetArtifactInfoByRace(raceID, artifactIndex)
		local artifact = {
			ID = artifactIndex,
			completionCount = completionCount,
			isRare = artifactRarity ~= 0,
			name = artifactName,
			texture = artifactIcon,
		}

		race.Artifacts[artifactName] = artifact
		artifactNameToInfoIndexMapping[artifactName] = artifactIndex
	end
	race.ArtifactNameToInfoIndexMapping = artifactNameToInfoIndexMapping

	for itemID, data in pairs(private.ARTIFACT_TEMPLATES[raceID]) do
		local artifactName = _G.GetItemInfo(itemID)
		if artifactName then
			local artifact = race.Artifacts[artifactName]
			if artifact then
				artifact.isRare = data.isRare
				artifact.itemID = data.itemID
				artifact.spellID = data.spellID
			else
				race.Artifacts[artifactName] = {
					completionCount = 0,
					isRare = data.isRare,
					itemID = data.itemID,
					name = artifactName,
					spellID = data.spellID,
				}
			end
		else
			RaceArtifactProcessingQueue[data] = race
			Archy:RegisterEvent("GET_ITEM_INFO_RECEIVED")
		end
	end

	race:UpdateCurrentProject()

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

	local _, _, _, _, _, _, _, firstCompletionTime, completionCount = _G.GetArtifactInfoByRace(self.ID, artifactIndex)
	return artifactIndex, firstCompletionTime, completionCount
end

function Race:IsOnArtifactBlacklist()
	return private.ProfileSettings.artifact.blacklist[self.ID]
end

function Race:KeystoneSocketOnClick(mouseButtonName)
	local artifact = self.currentProject

	if mouseButtonName == "LeftButton" and artifact.keystones_added < artifact.sockets and artifact.keystones_added < self.keystone.inventory then
		artifact.keystones_added = artifact.keystones_added + 1
	elseif mouseButtonName == "RightButton" and artifact.keystones_added > 0 then
		artifact.keystones_added = artifact.keystones_added - 1
	end

	self:UpdateCurrentProject()
end

function Race:UpdateCurrentProject()
	if _G.GetNumArtifactsByRace(self.ID) == 0 then
		return
	end

	if _G.ArchaeologyFrame and _G.ArchaeologyFrame:IsVisible() then
		_G.ArchaeologyFrame_ShowArtifact(self.ID)
	end

	_G.SetSelectedArtifact(self.ID)

	local artifactName, _, rarity, icon, spellDescription, numSockets = _G.GetSelectedArtifactInfo()
	local artifact = self.Artifacts[artifactName]
	if not artifact then
		local errorMessage = "Missing data for artifact \"%s\""
		private.DebugPour(errorMessage, artifactName)
		Archy:Printf(errorMessage, artifactName)
		return
	end

	local _, completionCount
	local project = self.currentProject or artifact
	if project then
		if project.name ~= artifactName then
			if not private.isLoading then
				project.hasAnnounced = nil
				project.hasPinged = nil

				_, _, completionCount = self:GetArtifactCompletionDataByName(project.name)
				Archy:Pour(L["You have solved |cFFFFFF00%s|r Artifact - |cFFFFFF00%s|r (Times completed: %d)"]:format(self.name, project.name, completionCount or 0), 1, 1, 1)
			end
		else
			_, _, completionCount = self:GetArtifactCompletionDataByName(artifactName)
		end
	end
	project = artifact
	self.currentProject = project

	local baseFragments, adjustedFragments, totalFragments = _G.GetArtifactProgress()

	project.canSolve = _G.CanSolveArtifact()
	project.canSolveInventory = nil
	project.canSolveStone = nil
	project.completionCount = completionCount
	project.fragments = baseFragments
	project.fragments_required = totalFragments
	project.icon = icon
	project.isRare = (rarity ~= 0)
	project.keystone_adjustment = 0
	project.keystones_added = project.keystones_added or 0
	project.name = artifactName
	project.sockets = numSockets
	project.tooltip = spellDescription

	self.keystone.inventory = _G.GetItemCount(self.keystone.ID) or 0

	local keystoneInventory = self.keystone.inventory
	local prevAdded = math.min(project.keystones_added, keystoneInventory, numSockets)
	local artifactSettings = private.ProfileSettings.artifact

	if artifactSettings.autofill[self.ID] then
		prevAdded = math.min(keystoneInventory, numSockets)
	end
	project.keystones_added = math.min(keystoneInventory, numSockets)

	-- TODO: This whole section looks like a needlessly convoluted way of doing things.
	if project.keystones_added > 0 and numSockets > 0 then
		for index = 1, math.min(project.keystones_added, numSockets) do
			_G.SocketItemToArtifact()

			if not _G.ItemAddedToArtifact(index) then
				break
			end

			if index == prevAdded then
				_, adjustedFragments = _G.GetArtifactProgress()
				project.keystone_adjustment = adjustedFragments
				project.canSolveStone = _G.CanSolveArtifact()
			end
		end
		project.canSolveInventory = _G.CanSolveArtifact()

		if prevAdded > 0 and project.keystone_adjustment <= 0 then
			_, adjustedFragments = _G.GetArtifactProgress()
			project.keystone_adjustment = adjustedFragments
			project.canSolveStone = _G.CanSolveArtifact()
		end
	end
	project.keystones_added = prevAdded

	_G.RequestArtifactCompletionHistory()

	if not private.isLoading and private.ProfileSettings.general.show and not self:IsOnArtifactBlacklist() then
		local currencyOwned = project.fragments + project.keystone_adjustment
		local currencyRequired = project.fragments_required

		if currencyOwned > 0 and currencyRequired > 0 then
			if not project.hasAnnounced and ((artifactSettings.announce and project.canSolve) or (artifactSettings.keystoneAnnounce and project.canSolveInventory)) then
				project.hasAnnounced = true
				Archy:Pour(L["You can solve %s Artifact - %s (Fragments: %d of %d)"]:format("|cFFFFFF00" .. self.name .. "|r", "|cFFFFFF00" .. project.name .. "|r", currencyOwned, currencyRequired), 1, 1, 1)
			end

			if not project.hasPinged and ((artifactSettings.ping and project.canSolve) or (artifactSettings.keystonePing and project.canSolveInventory)) then
				project.hasPinged = true
				_G.PlaySoundFile([[Interface\AddOns\Archy\Media\dingding.mp3]])
			end
		end
	end
end
