-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

-----------------------------------------------------------------------
-- Constants.
-----------------------------------------------------------------------
private.CONTINENT_RACES = {}

private.CRATE_SPELL_ID = 126935
private.CRATE_SPELL_NAME = (_G.GetSpellInfo(private.CRATE_SPELL_ID))

private.MAP_ID_TO_CONTINENT_ID = {} -- Popupated in Archy:OnInitialize()
