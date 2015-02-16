-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local Archy = LibStub("AceAddon-3.0"):GetAddon("Archy")

local Digsites = {}
private.Digsites = Digsites

-----------------------------------------------------------------------
-- Local constants.
-----------------------------------------------------------------------
local Digsite = {}
local digsiteMetatable = {
	__index = Digsite
}

-----------------------------------------------------------------------
-- Helpers.
-----------------------------------------------------------------------
function private.AddDigsite(digsiteTemplate, landmarkName, continentID, zoneID, zoneName, coordX, coordY)
	local existingDigsite = Digsite[digsiteTemplate.blobID]
	if existingDigsite then
		-- TODO: Debug output
		return
	end

	local digsite = _G.setmetatable({
		blobID = digsiteTemplate.blobID,
		coordX = coordX,
		coordY = coordY,
		continentID = continentID,
		distance = nil,
		level = 0,
		mapID = digsiteTemplate.mapID,
		maxFindCount = digsiteTemplate.maxFindCount,
		name = landmarkName,
		typeID = digsiteTemplate.typeID,
		zoneID = zoneID,
		zoneName = zoneName or ("%s %s"):format(_G.UNKNOWN, _G.PARENS_TEMPLATE:format(zoneID)),
	}, digsiteMetatable)

	Digsites[digsiteTemplate.blobID] = digsite

	return digsite
end

-----------------------------------------------------------------------
-- Digsite methods.
-----------------------------------------------------------------------
function Digsite:IsBlacklisted()
	return Archy.db.char.digsites.blacklist[self.name]
end

function Digsite:ToggleBlacklistStatus()
	local blacklist = Archy.db.char.digsites.blacklist

	-- TODO: Change this to use the blobID, since digsite names can be non-unique (Outland vs Draenor, for example)
	if blacklist[self.name] then
		blacklist[self.name] = nil
	else
		blacklist[self.name] = true
	end
end
