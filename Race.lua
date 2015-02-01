-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-- Functions

-- Libraries

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local Archy = LibStub("AceAddon-3.0"):GetAddon("Archy")

local Races = {}
private.Races = Races

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
function Archy:AddRace(raceID)
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
	local itemName, _, _, _, _, _, _, _, _, itemTexture, _ = _G.GetItemInfo(keystoneItemID)

	Races[raceID] = _G.setmetatable({
		currency = currencyAmount,
		id = raceID,
		name = raceName,
		texture = raceTexture,
		keystone = {
			id = keystoneItemID,
			name = itemName,
			texture = itemTexture,
			inventory = 0
		}
	}, raceMetatable)

	if keystoneItemID and keystoneItemID > 0 and (not itemName or itemName == "") then
		RaceKeystoneProcessingQueue[raceID] = keystoneItemID
		Archy:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	end

	return Races[raceID]
end

-----------------------------------------------------------------------
-- Race methods.
-----------------------------------------------------------------------
function Race:SetKeystoneNameAndTexture(keystoneName, keystoneTexture)
	RaceKeystoneProcessingQueue[self.id] = nil

	self.keystone.name = keystoneName
	self.keystone.texture = keystoneTexture

end
