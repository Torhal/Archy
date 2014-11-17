﻿--[[
	Artifact Database current as of WoW 4.3 build 15050
	27-Aug-2012: Artifact Database updated to WoW 5.04 build 16016
]]
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...
local LibStub = _G.LibStub
local AF = LibStub("LibBabble-Artifacts-3.0"):GetLookupTable()

local sessionErrors = {}

-----------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------
local RACE_DWARF = 1
local RACE_DRAENEI = 2
local RACE_FOSSIL = 3
local RACE_NIGHTELF = 4
local RACE_NERUBIAN = 5
local RACE_ORC = 6
local RACE_TOLVIR = 7
local RACE_TROLL = 8
local RACE_VRYKUL = 9
local RACE_MANTID = 10
local RACE_PANDAREN = 11
local RACE_MOGU = 12
local RACE_ARAKKOA = 13
local RACE_DRAENOR_CLANS = 14
local RACE_OGRE = 15

-- Extracted from ResearchBranch.dbc
local raceIDtoCurrencyID = {
	[RACE_DWARF] = 384,
	[RACE_DRAENEI] = 398,
	[RACE_FOSSIL] = 393,
	[RACE_NIGHTELF] = 394,
	[RACE_NERUBIAN] = 400,
	[RACE_ORC] = 397,
	[RACE_TOLVIR] = 401,
	[RACE_TROLL] = 385,
	[RACE_VRYKUL] = 399,
	[RACE_MANTID] = 754,
	[RACE_PANDAREN] = 676,
	[RACE_MOGU] = 677,
	[RACE_ARAKKOA] = 829,
	[RACE_DRAENOR_CLANS] = 821,
	[RACE_OGRE] = 828,
}
local raceIDtoKeystoneID = {
	[RACE_DWARF] = 52843,
	[RACE_DRAENEI] = 64394,
	[RACE_FOSSIL] = 0,
	[RACE_NIGHTELF] = 63127,
	[RACE_NERUBIAN] = 64396,
	[RACE_ORC] = 64392,
	[RACE_TOLVIR] = 64397,
	[RACE_TROLL] = 63128,
	[RACE_VRYKUL] = 64395,
	[RACE_MANTID] = 95373,
	[RACE_PANDAREN] = 79868,
	[RACE_MOGU] = 79869,
	[RACE_ARAKKOA] = 109585,
	[RACE_DRAENOR_CLANS] = 108439,
	[RACE_OGRE] = 109584,
}

-- Extracted from ResearchProject.dbc 
-- ItemIDs from wowhead (haven't found a lookup table in the dbcs yet)
local ARTIFACTS = {
	[AF["Chalice of the Mountain Kings"]] = {
		itemid = 64373,
		spellid = 90553,
		raceid = RACE_DWARF,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Clockwork Gnome"]] = {
		itemid = 64372,
		spellid = 90521,
		raceid = RACE_DWARF,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Staff of Sorcerer-Thane Thaurissan"]] = {
		itemid = 64489,
		spellid = 91227,
		raceid = RACE_DWARF,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["The Innkeeper's Daughter"]] = {
		itemid = 64488,
		spellid = 91226,
		raceid = RACE_DWARF,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Belt Buckle with Anvilmar Crest"]] = {
		itemid = 63113,
		spellid = 88910,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 0,
		fragments = 34,
	},
	[AF["Bodacious Door Knocker"]] = {
		itemid = 64339,
		spellid = 90411,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Bone Gaming Dice"]] = {
		itemid = 63112,
		spellid = 86866,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 0,
		fragments = 32,
	},
	[AF["Boot Heel with Scrollwork"]] = {
		itemid = 64340,
		spellid = 90412,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 34,
	},
	[AF["Ceramic Funeral Urn"]] = {
		itemid = 63409,
		spellid = 86864,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Dented Shield of Horuz Killcrow"]] = {
		itemid = 64362,
		spellid = 90504,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Dwarven Baby Socks"]] = {
		itemid = 66054,
		spellid = 93440,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Golden Chamber Pot"]] = {
		itemid = 64342,
		spellid = 90413,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Ironstar's Petrified Shield"]] = {
		itemid = 64344,
		spellid = 90419,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 36,
	},
	[AF["Mithril Chain of Angerforge"]] = {
		itemid = 64368,
		spellid = 90518,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Moltenfist's Jeweled Goblet"]] = {
		itemid = 63414,
		spellid = 89717,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 34,
	},
	[AF["Notched Sword of Tunadil the Redeemer"]] = {
		itemid = 64337,
		spellid = 90410,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Pewter Drinking Cup"]] = {
		itemid = 63408,
		spellid = 86857,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Pipe of Franclorn Forgewright"]] = {
		itemid = 64659,
		spellid = 91793,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Scepter of Bronzebeard"]] = {
		itemid = 64487,
		spellid = 91225,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Scepter of Charlga Razorflank"]] = {
		itemid = 64367,
		spellid = 90509,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Scorched Staff of Shadow Priest Anund"]] = {
		itemid = 64366,
		spellid = 90506,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Silver Kris of Korl"]] = {
		itemid = 64483,
		spellid = 91219,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Silver Neck Torc"]] = {
		itemid = 63411,
		spellid = 88181,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 34,
	},
	[AF["Skull Staff of Shadowforge"]] = {
		itemid = 64371,
		spellid = 90519,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Spiked Gauntlets of Anvilrage"]] = {
		itemid = 64485,
		spellid = 91223,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Stone Gryphon"]] = {
		itemid = 63410,
		spellid = 88180,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Warmaul of Burningeye"]] = {
		itemid = 64484,
		spellid = 91221,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Winged Helm of Corehammer"]] = {
		itemid = 64343,
		spellid = 90415,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Wooden Whistle"]] = {
		itemid = 63111,
		spellid = 88909,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 0,
		fragments = 28,
	},
	[AF["Word of Empress Zoe"]] = {
		itemid = 64486,
		spellid = 91224,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Worn Hunting Knife"]] = {
		itemid = 63110,
		spellid = 86865,
		raceid = RACE_DWARF,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Arrival of the Naaru"]] = {
		itemid = 64456,
		spellid = 90983,
		raceid = RACE_DRAENEI,
		rarity = 1,
		keystones = 3,
		fragments = 124,
	},
	[AF["The Last Relic of Argus"]] = {
		itemid = 64457,
		spellid = 90984,
		raceid = RACE_DRAENEI,
		rarity = 1,
		keystones = 3,
		fragments = 130,
	},
	[AF["Anklet with Golden Bells"]] = {
		itemid = 64440,
		spellid = 90853,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Baroque Sword Scabbard"]] = {
		itemid = 64453,
		spellid = 90968,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 46,
	},
	[AF["Carved Harp of Exotic Wood"]] = {
		itemid = 64442,
		spellid = 90860,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Dignified Portrait"]] = {
		itemid = 64455,
		spellid = 90975,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Fine Crystal Candelabra"]] = {
		itemid = 64454,
		spellid = 90974,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 44,
	},
	[AF["Plated Elekk Goad"]] = {
		itemid = 64458,
		spellid = 90987,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Scepter of the Nathrezim"]] = {
		itemid = 64444,
		spellid = 90864,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 46,
	},
	[AF["Strange Silver Paperweight"]] = {
		itemid = 64443,
		spellid = 90861,
		raceid = RACE_DRAENEI,
		rarity = 0,
		keystones = 2,
		fragments = 46,
	},
	[AF["Ancient Amber"]] = {
		itemid = 69776,
		spellid = 98560,
		raceid = RACE_FOSSIL,
		rarity = 1,
		keystones = 0,
		fragments = 100,
	},
	[AF["Extinct Turtle Shell"]] = {
		itemid = 69764,
		spellid = 98533,
		raceid = RACE_FOSSIL,
		rarity = 1,
		keystones = 0,
		fragments = 150,
	},
	[AF["Fossilized Hatchling"]] = {
		itemid = 60955,
		spellid = 89693,
		raceid = RACE_FOSSIL,
		rarity = 1,
		keystones = 0,
		fragments = 85,
	},
	[AF["Fossilized Raptor"]] = {
		itemid = 60954,
		spellid = 90619,
		raceid = RACE_FOSSIL,
		rarity = 1,
		keystones = 0,
		fragments = 100,
	},
	[AF["Pterrordax Hatchling"]] = {
		itemid = 69821,
		spellid = 98582,
		raceid = RACE_FOSSIL,
		rarity = 1,
		keystones = 0,
		fragments = 120,
	},
	[AF["Ancient Shark Jaws"]] = {
		itemid = 64355,
		spellid = 90452,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 35,
	},
	[AF["Beautiful Preserved Fern"]] = {
		itemid = 63121,
		spellid = 88930,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 25,
	},
	[AF["Black Trilobite"]] = {
		itemid = 63109,
		spellid = 88929,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 31,
	},
	[AF["Devilsaur Tooth"]] = {
		itemid = 64349,
		spellid = 90432,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 35,
	},
	[AF["Feathered Raptor Arm"]] = {
		itemid = 64385,
		spellid = 90617,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 33,
	},
	[AF["Imprint of a Kraken Tentacle"]] = {
		itemid = 64473,
		spellid = 91132,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 45,
	},
	[AF["Insect in Amber"]] = {
		itemid = 64350,
		spellid = 90433,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 35,
	},
	[AF["Proto-Drake Skeleton"]] = {
		itemid = 64468,
		spellid = 91089,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 45,
	},
	[AF["Shard of Petrified Wood"]] = {
		itemid = 66056,
		spellid = 93442,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Strange Velvet Worm"]] = {
		itemid = 66057,
		spellid = 93443,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 35,
	},
	[AF["Twisted Ammonite Shell"]] = {
		itemid = 63527,
		spellid = 89895,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 35,
	},
	[AF["Vicious Ancient Fish"]] = {
		itemid = 64387,
		spellid = 90618,
		raceid = RACE_FOSSIL,
		rarity = 0,
		keystones = 0,
		fragments = 35,
	},
	[AF["Bones of Transformation"]] = {
		itemid = 64646,
		spellid = 91761,
		raceid = RACE_NIGHTELF,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Druid and Priest Statue Set"]] = {
		itemid = 64361,
		spellid = 90493,
		raceid = RACE_NIGHTELF,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Highborne Soul Mirror"]] = {
		itemid = 64358,
		spellid = 90464,
		raceid = RACE_NIGHTELF,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Kaldorei Wind Chimes"]] = {
		itemid = 64383,
		spellid = 90614,
		raceid = RACE_NIGHTELF,
		rarity = 1,
		keystones = 3,
		fragments = 98,
	},
	[AF["Queen Azshara's Dressing Gown"]] = {
		itemid = 64643,
		spellid = 90616,
		raceid = RACE_NIGHTELF,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Tyrande's Favorite Doll"]] = {
		itemid = 64645,
		spellid = 91757,
		raceid = RACE_NIGHTELF,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Wisp Amulet"]] = {
		itemid = 64651,
		spellid = 91773,
		raceid = RACE_NIGHTELF,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Carcanet of the Hundred Magi"]] = {
		itemid = 64647,
		spellid = 91762,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Chest of Tiny Glass Animals"]] = {
		itemid = 64379,
		spellid = 90610,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 34,
	},
	[AF["Cloak Clasp with Antlers"]] = {
		itemid = 63407,
		spellid = 89696,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Coin from Eldre'Thalas"]] = {
		itemid = 63525,
		spellid = 89893,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Cracked Crystal Vial"]] = {
		itemid = 64381,
		spellid = 90611,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Delicate Music Box"]] = {
		itemid = 64357,
		spellid = 90458,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Green Dragon Ring"]] = {
		itemid = 63528,
		spellid = 89896,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Hairpin of Silver and Malachite"]] = {
		itemid = 64356,
		spellid = 90453,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Highborne Pyxis"]] = {
		itemid = 63129,
		spellid = 89009,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Inlaid Ivory Comb"]] = {
		itemid = 63130,
		spellid = 89012,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Kaldorei Amphora"]] = {
		itemid = 64354,
		spellid = 90451,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Necklace with Elune Pendant"]] = {
		itemid = 66055,
		spellid = 93441,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Scandalous Silk Nightgown"]] = {
		itemid = 63131,
		spellid = 89014,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Scepter of Xavius"]] = {
		itemid = 64382,
		spellid = 90612,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Shattered Glaive"]] = {
		itemid = 63526,
		spellid = 89894,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Silver Scroll Case"]] = {
		itemid = 64648,
		spellid = 91766,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["String of Small Pink Pearls"]] = {
		itemid = 64378,
		spellid = 90609,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Umbra Crescent"]] = {
		itemid = 64650,
		spellid = 91769,
		raceid = RACE_NIGHTELF,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Blessing of the Old God"]] = {
		itemid = 64481,
		spellid = 91214,
		raceid = RACE_NERUBIAN,
		rarity = 1,
		keystones = 3,
		fragments = 140,
	},
	[AF["Puzzle Box of Yogg-Saron"]] = {
		itemid = 64482,
		spellid = 91215,
		raceid = RACE_NERUBIAN,
		rarity = 1,
		keystones = 3,
		fragments = 140,
	},
	[AF["Ewer of Jormungar Blood"]] = {
		itemid = 64479,
		spellid = 91209,
		raceid = RACE_NERUBIAN,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Gruesome Heart Box"]] = {
		itemid = 64477,
		spellid = 91191,
		raceid = RACE_NERUBIAN,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Infested Ruby Ring"]] = {
		itemid = 64476,
		spellid = 91188,
		raceid = RACE_NERUBIAN,
		rarity = 0,
		keystones = 3,
		fragments = 45,
	},
	[AF["Scepter of Nezar'Azret"]] = {
		itemid = 64475,
		spellid = 91170,
		raceid = RACE_NERUBIAN,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Six-Clawed Cornice"]] = {
		itemid = 64478,
		spellid = 91197,
		raceid = RACE_NERUBIAN,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Spidery Sundial"]] = {
		itemid = 64474,
		spellid = 91133,
		raceid = RACE_NERUBIAN,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Vizier's Scrawled Streamer"]] = {
		itemid = 64480,
		spellid = 91211,
		raceid = RACE_NERUBIAN,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Headdress of the First Shaman"]] = {
		itemid = 64644,
		spellid = 90843,
		raceid = RACE_ORC,
		rarity = 1,
		keystones = 3,
		fragments = 130,
	},
	[AF["Fiendish Whip"]] = {
		itemid = 64436,
		spellid = 90831,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Fierce Wolf Figurine"]] = {
		itemid = 64421,
		spellid = 90734,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Gray Candle Stub"]] = {
		itemid = 64418,
		spellid = 90728,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Maul of Stone Guard Mur'og"]] = {
		itemid = 64417,
		spellid = 90720,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Rusted Steak Knife"]] = {
		itemid = 64419,
		spellid = 90730,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Scepter of Nekros Skullcrusher"]] = {
		itemid = 64420,
		spellid = 90732,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Skull Drinking Cup"]] = {
		itemid = 64438,
		spellid = 90833,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Tile of Glazed Clay"]] = {
		itemid = 64437,
		spellid = 90832,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Tiny Bronze Scorpion"]] = {
		itemid = 64389,
		spellid = 90622,
		raceid = RACE_ORC,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	}, -- Mummified Monkey Paw is the project name, Crawling Claw the item/spell name produced.
	[AF["Mummified Monkey Paw"]] = {
		itemid = 60847,
		spellid = 92137,
		raceid = RACE_TOLVIR,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Pendant of the Scarab Storm"]] = {
		itemid = 64881,
		spellid = 92145,
		raceid = RACE_TOLVIR,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Ring of the Boy Emperor"]] = {
		itemid = 64904,
		spellid = 92168,
		raceid = RACE_TOLVIR,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Scepter of Azj'Aqir"]] = {
		itemid = 64883,
		spellid = 92148,
		raceid = RACE_TOLVIR,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Scimitar of the Sirocco"]] = {
		itemid = 64885,
		spellid = 92163,
		raceid = RACE_TOLVIR,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Staff of Ammunae"]] = {
		itemid = 64880,
		spellid = 92139,
		raceid = RACE_TOLVIR,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Canopic Jar"]] = {
		itemid = 64657,
		spellid = 91790,
		raceid = RACE_TOLVIR,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Castle of Sand"]] = {
		itemid = 64652,
		spellid = 91775,
		raceid = RACE_TOLVIR,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Cat Statue with Emerald Eyes"]] = {
		itemid = 64653,
		spellid = 91779,
		raceid = RACE_TOLVIR,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Engraved Scimitar Hilt"]] = {
		itemid = 64656,
		spellid = 91785,
		raceid = RACE_TOLVIR,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Sketch of a Desert Palace"]] = {
		itemid = 64658,
		spellid = 91792,
		raceid = RACE_TOLVIR,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Soapstone Scarab Necklace"]] = {
		itemid = 64654,
		spellid = 91780,
		raceid = RACE_TOLVIR,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Tiny Oasis Mosaic"]] = {
		itemid = 64655,
		spellid = 91782,
		raceid = RACE_TOLVIR,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Haunted War Drum"]] = {
		itemid = 69777,
		spellid = 98556,
		raceid = RACE_TROLL,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Voodoo Figurine"]] = {
		itemid = 69824,
		spellid = 98588,
		raceid = RACE_TROLL,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Zin'rokh, Destroyer of Worlds"]] = {
		itemid = 64377,
		spellid = 90608,
		raceid = RACE_TROLL,
		rarity = 1,
		keystones = 3,
		fragments = 150,
	},
	[AF["Atal'ai Scepter"]] = {
		itemid = 64348,
		spellid = 90429,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Bracelet of Jade and Coins"]] = {
		itemid = 64346,
		spellid = 90421,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Cinnabar Bijou"]] = {
		itemid = 63524,
		spellid = 89891,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Drakkari Sacrificial Knife"]] = {
		itemid = 64375,
		spellid = 90581,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Eerie Smolderthorn Idol"]] = {
		itemid = 63523,
		spellid = 89890,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Feathered Gold Earring"]] = {
		itemid = 63413,
		spellid = 89711,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 34,
	},
	[AF["Fetish of Hir'eek"]] = {
		itemid = 63120,
		spellid = 88907,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Fine Bloodscalp Dinnerware"]] = {
		itemid = 66058,
		spellid = 93444,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 0,
		fragments = 32,
	},
	[AF["Gahz'rilla Figurine"]] = {
		itemid = 64347,
		spellid = 90423,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Jade Asp with Ruby Eyes"]] = {
		itemid = 63412,
		spellid = 89701,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Lizard Foot Charm"]] = {
		itemid = 63118,
		spellid = 88908,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 0,
		fragments = 32,
	},
	[AF["Skull-Shaped Planter"]] = {
		itemid = 64345,
		spellid = 90420,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Tooth with Gold Filling"]] = {
		itemid = 64374,
		spellid = 90558,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 1,
		fragments = 35,
	},
	[AF["Zandalari Voodoo Doll"]] = {
		itemid = 63115,
		spellid = 88262,
		raceid = RACE_TROLL,
		rarity = 0,
		keystones = 0,
		fragments = 27,
	},
	[AF["Nifflevar Bearded Axe"]] = {
		itemid = 64460,
		spellid = 90997,
		raceid = RACE_VRYKUL,
		rarity = 1,
		keystones = 3,
		fragments = 130,
	},
	[AF["Vrykul Drinking Horn"]] = {
		itemid = 69775,
		spellid = 98569,
		raceid = RACE_VRYKUL,
		rarity = 1,
		keystones = 3,
		fragments = 100,
	},
	[AF["Fanged Cloak Pin"]] = {
		itemid = 64464,
		spellid = 91014,
		raceid = RACE_VRYKUL,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Flint Striker"]] = {
		itemid = 64462,
		spellid = 91012,
		raceid = RACE_VRYKUL,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Intricate Treasure Chest Key"]] = {
		itemid = 64459,
		spellid = 90988,
		raceid = RACE_VRYKUL,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Scramseax"]] = {
		itemid = 64461,
		spellid = 91008,
		raceid = RACE_VRYKUL,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Thorned Necklace"]] = {
		itemid = 64467,
		spellid = 91084,
		raceid = RACE_VRYKUL,
		rarity = 0,
		keystones = 2,
		fragments = 45,
	},
	[AF["Pandaren Tea Set"]] = {
		itemid = 79896,
		spellid = 113968,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Pandaren Game Board"]] = {
		itemid = 79897,
		spellid = 113971,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 0,
		fragments = 40,
	},
	[AF["Twin Stein Set of Brewfather Quan Tou Kuo"]] = {
		itemid = 79898,
		spellid = 113972,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Walking Cane of Brewfather Ren Yun"]] = {
		itemid = 79899,
		spellid = 113973,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Empty Keg of Brewfather Xin Wo Yin"]] = {
		itemid = 79900,
		spellid = 113974,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Carved Bronze Mirror"]] = {
		itemid = 79901,
		spellid = 113975,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Gold-Inlaid Porcelain Funerary Figurine"]] = {
		itemid = 79902,
		spellid = 113976,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Apothecary Tins"]] = {
		itemid = 79903,
		spellid = 113977,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Pearl of Yu'lon"]] = {
		itemid = 79904,
		spellid = 113978,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 2,
		fragments = 60,
	},
	[AF["Standard of Niuzao"]] = {
		itemid = 79905,
		spellid = 113979,
		raceid = RACE_PANDAREN,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Umbrella of Chi-Ji"]] = {
		itemid = 79906,
		spellid = 113980,
		raceid = RACE_PANDAREN,
		rarity = 1,
		keystones = 3,
		fragments = 180,
	},
	[AF["Spear of Xuen"]] = {
		itemid = 79907,
		spellid = 113981,
		raceid = RACE_PANDAREN,
		rarity = 1,
		keystones = 3,
		fragments = 180,
	},
	[AF["Manacles of Rebellion"]] = {
		itemid = 79908,
		spellid = 113982,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Cracked Mogu Runestone"]] = {
		itemid = 79909,
		spellid = 113983,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Terracotta Arm"]] = {
		itemid = 79910,
		spellid = 113984,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Petrified Bone Whip"]] = {
		itemid = 79911,
		spellid = 113985,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Thunder King Insignia"]] = {
		itemid = 79912,
		spellid = 113986,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Edicts of the Thunder King"]] = {
		itemid = 79913,
		spellid = 113987,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 2,
		fragments = 60,
	},
	[AF["Iron Amulet"]] = {
		itemid = 79914,
		spellid = 113988,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Warlord's Branding Iron"]] = {
		itemid = 79915,
		spellid = 113989,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Mogu Coin"]] = {
		itemid = 79916,
		spellid = 113990,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 0,
		fragments = 30,
	},
	[AF["Worn Monument Ledger"]] = {
		itemid = 79917,
		spellid = 113991,
		raceid = RACE_MOGU,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Quilen Statuette"]] = {
		itemid = 79918,
		spellid = 113992,
		raceid = RACE_MOGU,
		rarity = 1,
		keystones = 3,
		fragments = 180,
	},
	[AF["Anatomical Dummy"]] = {
		itemid = 79919,
		spellid = 113993,
		raceid = RACE_MOGU,
		rarity = 1,
		keystones = 3,
		fragments = 180,
	},
	[AF["Banner of the Mantid Empire"]] = {
		itemid = 95375,
		spellid = 139776,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Ancient Sap Feeder"]] = {
		itemid = 95376,
		spellid = 139779,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["The Praying Mantid"]] = {
		itemid = 95377,
		spellid = 139780,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Inert Sound Beacon"]] = {
		itemid = 95378,
		spellid = 139781,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Remains of a Paragon"]] = {
		itemid = 95379,
		spellid = 139782,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Mantid Lamp"]] = {
		itemid = 95380,
		spellid = 139783,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Pollen Collector"]] = {
		itemid = 95381,
		spellid = 139784,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Kypari Sap Container"]] = {
		itemid = 95382,
		spellid = 139785,
		raceid = RACE_MANTID,
		rarity = 0,
		keystones = 1,
		fragments = 50,
	},
	[AF["Mantid Sky Reaver"]] = {
		itemid = 95391,
		spellid = 139786,
		raceid = RACE_MANTID,
		rarity = 1,
		keystones = 3,
		fragments = 180,
	},
	[AF["Sonic Pulse Generator"]] = {
		itemid = 95392,
		spellid = 139787,
		raceid = RACE_MANTID,
		rarity = 1,
		keystones = 3,
		fragments = 180,
	},
}
for artifact, data in pairs(ARTIFACTS) do
	data.currencyid = raceIDtoCurrencyID[data.raceid]
	data.keystoneid = raceIDtoKeystoneID[data.raceid]
end

local NULL_ARTIFACT = {
	itemid = 0,
	spellid = 0,
	raceid = 0,
	rarity = -1,
	keystones = -1,
	fragments = -1,
	currencyid = 0,
	keystoneid = 0,
}

_G.setmetatable(ARTIFACTS, {
	__index = function(t, k)
		if k and not sessionErrors[k] then
			_G.DEFAULT_CHAT_FRAME:AddMessage("Archy is missing data for artifact " .. k)
			sessionErrors[k] = true
		end
		return NULL_ARTIFACT
	end
})

private.artifacts_db = ARTIFACTS