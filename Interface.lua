-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-- Libraries
local math = _G.math
local table = _G.table

-- Functions
local pairs = _G.pairs
local setmetatable = _G.setmetatable
local unpack = _G.unpack

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale("Archy", false)
local Archy = LibStub("AceAddon-3.0"):GetAddon("Archy")
local LSM = LibStub("LibSharedMedia-3.0")

-----------------------------------------------------------------------
-- Constants.
-----------------------------------------------------------------------
local NUM_DIGSITE_FINDS_DEFAULT = 6
local NUM_DIGSITE_FINDS_DRAENOR = 9

local CONTINENT_RACES = {}
for _, site in pairs(private.DIG_SITES) do
	CONTINENT_RACES[site.continent] = CONTINENT_RACES[site.continent] or {}
	CONTINENT_RACES[site.continent][site.race] = true
end

-----------------------------------------------------------------------
-- Helpers.
-----------------------------------------------------------------------
local function FramesShouldBeHidden()
	return (not private.db.general.show or not private.current_continent or _G.UnitIsGhost("player") or _G.IsInInstance() or _G.C_PetBattles.IsInBattle() or not private.HasArchaeology())
end

private.FramesShouldBeHidden = FramesShouldBeHidden

local function FontString_SetShadow(fs, hasShadow)
	if hasShadow then
		fs:SetShadowColor(0, 0, 0, 1)
		fs:SetShadowOffset(1, -1)
	else
		fs:SetShadowColor(0, 0, 0, 0)
		fs:SetShadowOffset(0, 0)
	end
end

local DigSiteFrame
local RacesFrame
local DistanceIndicatorFrame

local function InitializeFrames()
	if private.IsTaintable() then
		private.regen_create_frames = true
		return
	end

	DigSiteFrame = _G.CreateFrame("Frame", "ArchyDigSiteFrame", _G.UIParent, (private.db.general.theme == "Graphical" and "ArchyDigSiteContainer" or "ArchyMinDigSiteContainer"))
	DigSiteFrame.children = setmetatable({}, {
		__index = function(t, k)
			if k then
				local template = (private.db.general.theme == "Graphical" and "ArchyDigSiteRowTemplate" or "ArchyMinDigSiteRowTemplate")
				local child = _G.CreateFrame("Frame", "ArchyDigSiteChildFrame" .. k, DigSiteFrame, template)
				child:Show()
				t[k] = child
				return child
			end
		end
	})

	private.digsite_frame = DigSiteFrame

	RacesFrame = _G.CreateFrame("Frame", "ArchyArtifactFrame", _G.UIParent, (private.db.general.theme == "Graphical" and "ArchyArtifactContainer" or "ArchyMinArtifactContainer"))
	RacesFrame.children = setmetatable({}, {
		__index = function(t, k)
			if k then
				local template = (private.db.general.theme == "Graphical" and "ArchyArtifactRowTemplate" or "ArchyMinArtifactRowTemplate")
				local child = _G.CreateFrame("Frame", "ArchyArtifactChildFrame" .. private.DigsiteRaceLabelFromID[k], RacesFrame, template)
				child:Show()
				t[k] = child
				return child
			end
		end
	})

	private.races_frame = RacesFrame

	DistanceIndicatorFrame = _G.CreateFrame("Frame", "ArchyDistanceIndicatorFrame", _G.UIParent, "ArchyDistanceIndicator")
	DistanceIndicatorFrame.circle:SetScale(0.65)

	private.distance_indicator_frame = DistanceIndicatorFrame

	Archy:UpdateFramePositions()
	Archy:UpdateDigSiteFrame()
	Archy:UpdateRacesFrame()
end

private.InitializeFrames = InitializeFrames

-----------------------------------------------------------------------
-- Methods.
-----------------------------------------------------------------------
function Archy:UpdateRacesFrame()
	if private.IsTaintable() then
		private.regen_update_races = true
		return
	end

	RacesFrame:SetScale(private.db.artifact.scale)
	RacesFrame:SetAlpha(private.db.artifact.alpha)

	local is_movable = not private.db.general.locked
	RacesFrame:SetMovable(is_movable)
	RacesFrame:EnableMouse(is_movable)

	if is_movable then
		RacesFrame:RegisterForDrag("LeftButton")
	else
		RacesFrame:RegisterForDrag()
	end

	local artifactFont = private.db.artifact.font
	local fragmentFont = private.db.artifact.fragmentFont
	local keystoneFont = private.db.artifact.keystoneFont

	local artifactFontName = LSM:Fetch("font", artifactFont.name)
	local fragmentFontName = LSM:Fetch("font", fragmentFont.name)
	local keystoneFontName = LSM:Fetch("font", keystoneFont.name)

	for _, child in pairs(RacesFrame.children) do
		if private.db.general.theme == "Graphical" then
			child.fragmentBar.artifact:SetFont(artifactFontName, artifactFont.size, artifactFont.outline)
			child.fragmentBar.artifact:SetTextColor(artifactFont.color.r, artifactFont.color.g, artifactFont.color.b, artifactFont.color.a)
			FontString_SetShadow(child.fragmentBar.artifact, artifactFont.shadow)

			child.fragmentBar.fragments:SetFont(fragmentFontName, fragmentFont.size, fragmentFont.outline)
			child.fragmentBar.fragments:SetTextColor(fragmentFont.color.r, fragmentFont.color.g, fragmentFont.color.b, fragmentFont.color.a)
			FontString_SetShadow(child.fragmentBar.fragments, fragmentFont.shadow)

			child.fragmentBar.keystones.count:SetFont(keystoneFontName, keystoneFont.size, keystoneFont.outline)
			child.fragmentBar.keystones.count:SetTextColor(keystoneFont.color.r, keystoneFont.color.g, keystoneFont.color.b, keystoneFont.color.a)
			FontString_SetShadow(child.fragmentBar.keystones.count, keystoneFont.shadow)

			child.solveButton:SetText(_G.SOLVE)
			child.solveButton:SetWidth(child.solveButton:GetTextWidth() + 20)
			child.solveButton.tooltip = _G.SOLVE

			if child.style ~= private.db.artifact.style then
				if private.db.artifact.style == "Compact" then
					child.crest:ClearAllPoints()
					child.crest:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)

					child.icon:ClearAllPoints()
					child.icon:SetPoint("LEFT", child.crest, "RIGHT", 0, 0)
					child.icon:SetWidth(32)
					child.icon:SetHeight(32)
					child.icon.texture:SetWidth(32)
					child.icon.texture:SetHeight(32)

					child.crest.text:Hide()
					child.crest:SetWidth(36)
					child.crest:SetHeight(36)
					child.solveButton:SetText("")
					child.solveButton:SetWidth(34)
					child.solveButton:SetHeight(34)
					child.solveButton:SetNormalTexture([[Interface\ICONS\TRADE_ARCHAEOLOGY_AQIR_ARTIFACTFRAGMENT]])
					child.solveButton:SetDisabledTexture([[Interface\ICONS\TRADE_ARCHAEOLOGY_AQIR_ARTIFACTFRAGMENT]])
					child.solveButton:GetDisabledTexture():SetBlendMode("MOD")

					child.solveButton:ClearAllPoints()
					child.solveButton:SetPoint("LEFT", child.fragmentBar, "RIGHT", 5, 0)
					child.fragmentBar.fragments:ClearAllPoints()
					child.fragmentBar.fragments:SetPoint("RIGHT", child.fragmentBar.keystones, "LEFT", -7, 2)
					child.fragmentBar.keystone1:Hide()
					child.fragmentBar.keystone2:Hide()
					child.fragmentBar.keystone3:Hide()
					child.fragmentBar.keystone4:Hide()
					child.fragmentBar.artifact:SetWidth(160)

					child:SetWidth(315 + child.solveButton:GetWidth())
					child:SetHeight(36)
				else
					child.icon:ClearAllPoints()
					child.icon:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
					child.icon:SetWidth(36)
					child.icon:SetHeight(36)
					child.icon.texture:SetWidth(36)
					child.icon.texture:SetHeight(36)

					child.icon:Show()
					child.crest.text:Show()
					child.crest:SetWidth(24)
					child.crest:SetHeight(24)
					child.crest:ClearAllPoints()
					child.crest:SetPoint("TOPLEFT", child.icon, "BOTTOMLEFT", 0, 0)
					child.solveButton:SetHeight(24)
					child.solveButton:SetNormalTexture(nil)
					child.solveButton:SetDisabledTexture(nil)
					child.solveButton:ClearAllPoints()
					child.solveButton:SetPoint("TOPRIGHT", child.fragmentBar, "BOTTOMRIGHT", 0, -3)
					child.fragmentBar.fragments:ClearAllPoints()
					child.fragmentBar.fragments:SetPoint("RIGHT", child.fragmentBar, "RIGHT", -5, 2)
					child.fragmentBar.keystones:Hide()
					child.fragmentBar.artifact:SetWidth(200)

					child:SetWidth(295)
					child:SetHeight(70)
				end
			end
		else
			child.fragments.text:SetFont(artifactFontName, artifactFont.size, artifactFont.outline)
			child.fragments.text:SetTextColor(artifactFont.color.r, artifactFont.color.g, artifactFont.color.b, artifactFont.color.a)
			FontString_SetShadow(child.fragments.text, artifactFont.shadow)

			child.sockets.text:SetFont(artifactFontName, artifactFont.size, artifactFont.outline)
			child.sockets.text:SetTextColor(artifactFont.color.r, artifactFont.color.g, artifactFont.color.b, artifactFont.color.a)
			FontString_SetShadow(child.sockets.text, artifactFont.shadow)

			child.artifact.text:SetFont(artifactFontName, artifactFont.size, artifactFont.outline)
			child.artifact.text:SetTextColor(artifactFont.color.r, artifactFont.color.g, artifactFont.color.b, artifactFont.color.a)
			FontString_SetShadow(child.artifact.text, artifactFont.shadow)
		end
	end

	RacesFrame:SetBackdrop({
		bgFile = LSM:Fetch('background', private.db.artifact.backgroundTexture),
		edgeFile = LSM:Fetch('border', private.db.artifact.borderTexture),
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

	RacesFrame:SetBackdropColor(1, 1, 1, private.db.artifact.bgAlpha)
	RacesFrame:SetBackdropBorderColor(1, 1, 1, private.db.artifact.borderAlpha)

	if not private.IsTaintable() then
		local height = RacesFrame.container:GetHeight() + ((private.db.general.theme == "Graphical") and 15 or 25)
		if private.db.general.showSkillBar and private.db.general.theme == "Graphical" then
			height = height + 30
		end
		RacesFrame:SetHeight(height)
		RacesFrame:SetWidth(RacesFrame.container:GetWidth() + ((private.db.general.theme == "Graphical") and 45 or 0))
	end

	if RacesFrame:IsVisible() then
		if private.db.general.stealthMode or not private.db.artifact.show or FramesShouldBeHidden() then
			RacesFrame:Hide()
		end
	else
		if not private.db.general.stealthMode and private.db.artifact.show and not FramesShouldBeHidden() then
			RacesFrame:Show()
		end
	end
end

function Archy:RefreshRacesDisplay()
	if FramesShouldBeHidden() or _G.GetNumArchaeologyRaces() == 0 then
		return
	end
	local maxWidth, maxHeight = 0, 0
	self:UpdateSkillBar()

	local topFrame = RacesFrame.container
	local hiddenAnchor = RacesFrame
	local racesCount = 0

	if private.db.general.theme == "Minimal" then
		RacesFrame.title.text:SetText(L["Artifacts"])
	end

	for _, child in pairs(RacesFrame.children) do
		child:Hide()
	end

	for raceID, race in pairs(private.Races) do
		local child = RacesFrame.children[raceID]
		local artifact = race.artifact
		local _, _, completionCount = race:GetArtifactCompletionDataByName(artifact.name)

		child:SetID(raceID)

		local continentHasRace = CONTINENT_RACES[private.current_continent][raceID]
		if not private.db.artifact.blacklist[raceID] and artifact.fragments_required > 0 and (not private.db.artifact.filter or continentHasRace) then
			child:ClearAllPoints()

			if topFrame == RacesFrame.container then
				child:SetPoint("TOPLEFT", topFrame, "TOPLEFT", 0, 0)
			else
				child:SetPoint("TOPLEFT", topFrame, "BOTTOMLEFT", 0, -5)
			end
			topFrame = child
			child:Show()
			maxHeight = maxHeight + child:GetHeight() + 5
			maxWidth = (maxWidth > child:GetWidth()) and maxWidth or child:GetWidth()
			racesCount = racesCount + 1
		else
			child:Hide()
		end

		if private.db.general.theme == "Graphical" then
			child.crest.texture:SetTexture(race.texture)
			child.crest.tooltip = race.name .. "\n" .. _G.NORMAL_FONT_COLOR_CODE .. L["Key Stones:"] .. "|r " .. race.keystone.inventory
			child.crest.text:SetText(race.name)
			child.icon.texture:SetTexture(artifact.icon)
			child.icon.tooltip = _G.HIGHLIGHT_FONT_COLOR_CODE .. artifact.name .. "|r\n" .. _G.NORMAL_FONT_COLOR_CODE .. artifact.tooltip .. "\n\n" .. _G.HIGHLIGHT_FONT_COLOR_CODE .. L["Solved Count: %s"]:format(_G.NORMAL_FONT_COLOR_CODE .. (completionCount or "0") .. "|r") .. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to open artifact in default Archaeology UI"] .. "|r"

			-- setup the bar texture here
			local barTexture = (LSM and LSM:Fetch('statusbar', private.db.artifact.fragmentBarTexture)) or _G.DEFAULT_STATUSBAR_TEXTURE
			child.fragmentBar.barTexture:SetTexture(barTexture)
			child.fragmentBar.barTexture:SetHorizTile(false)

			local barColor
			if artifact.isRare then
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
			child.fragmentBar:SetMinMaxValues(0, artifact.fragments_required)
			child.fragmentBar:SetValue(math.min(artifact.fragments + artifact.keystone_adjustment, artifact.fragments_required))

			local adjust = (artifact.keystone_adjustment > 0) and (" (|cFF00FF00+%d|r)"):format(artifact.keystone_adjustment) or ""
			child.fragmentBar.fragments:SetFormattedText("%d%s / %d", artifact.fragments, adjust, artifact.fragments_required)
			child.fragmentBar.artifact:SetText(artifact.name)
			child.fragmentBar.artifact:SetWordWrap(true)

			local endFound = false
			local artifactNameSize = child.fragmentBar:GetWidth() - 10

			if private.db.artifact.style == "Compact" then
				artifactNameSize = artifactNameSize - 40

				if artifact.sockets > 0 then
					child.fragmentBar.keystones.tooltip = L["%d Key stone sockets available"]:format(artifact.sockets) .. "\n" .. L["%d %ss in your inventory"]:format(race.keystone.inventory or 0, race.keystone.name or L["Key stone"])
					child.fragmentBar.keystones:Show()

					if child.fragmentBar.keystones and child.fragmentBar.keystones.count then
						child.fragmentBar.keystones.count:SetFormattedText("%d/%d", artifact.keystones_added, artifact.sockets)
					end

					if artifact.keystones_added > 0 then
						child.fragmentBar.keystones.icon:SetTexture(race.keystone.texture)
					else
						child.fragmentBar.keystones.icon:SetTexture(nil)
					end
				else
					child.fragmentBar.keystones:Hide()
				end
			else
				for keystone_index = 1, (_G.ARCHAEOLOGY_MAX_STONES or 4) do
					local field = "keystone" .. keystone_index

					if keystone_index > artifact.sockets or not race.keystone.name then
						child.fragmentBar[field]:Hide()
					else
						child.fragmentBar[field].icon:SetTexture(race.keystone.texture)

						if keystone_index <= artifact.keystones_added then
							child.fragmentBar[field].icon:Show()
							child.fragmentBar[field].tooltip = _G.ARCHAEOLOGY_KEYSTONE_REMOVE_TOOLTIP:format(race.keystone.name)
							child.fragmentBar[field]:Enable()
						else
							child.fragmentBar[field].icon:Hide()
							child.fragmentBar[field].tooltip = _G.ARCHAEOLOGY_KEYSTONE_ADD_TOOLTIP:format(race.keystone.name)
							child.fragmentBar[field]:Enable()

							if endFound then
								child.fragmentBar[field]:Disable()
							end
							endFound = true
						end
						child.fragmentBar[field]:Show()
					end
				end
			end

			-- Actual user-filled sockets enough to solve so enable the manual solve button
			if artifact.canSolve or (artifact.keystones_added > 0 and artifact.canSolveStone) then
				child.solveButton:Enable()
				barColor = private.db.artifact.fragmentBarColors["Solvable"]
			else
				-- Can solve with available stones from inventory, but not enough are socketed.
				if artifact.canSolveInventory then
					barColor = private.db.artifact.fragmentBarColors["AttachToSolve"]
				end
				child.solveButton:Disable()
			end

			child.fragmentBar.barTexture:SetVertexColor(barColor.r, barColor.g, barColor.b, 1)

			artifactNameSize = artifactNameSize - child.fragmentBar.fragments:GetStringWidth()
			child.fragmentBar.artifact:SetWidth(artifactNameSize)

		else
			local fragmentColor = (artifact.canSolve and "|cFF00FF00" or (artifact.canSolveStone and "|cFFFFFF00" or ""))
			local nameColor = (artifact.isRare and "|cFF0070DD" or ((completionCount and completionCount > 0) and _G.GRAY_FONT_COLOR_CODE or ""))
			child.fragments.text:SetFormattedText("%s%d/%d", fragmentColor, artifact.fragments, artifact.fragments_required)

			if race.keystone.inventory > 0 or artifact.sockets > 0 then
				child.sockets.text:SetFormattedText("%d/%d", race.keystone.inventory, artifact.sockets)
				child.sockets.tooltip = L["%d Key stone sockets available"]:format(artifact.sockets) .. "\n" .. L["%d %ss in your inventory"]:format(race.keystone.inventory or 0, race.keystone.name or L["Key stone"])
			else
				child.sockets.text:SetText("")
				child.sockets.tooltip = nil
			end
			child.crest:SetNormalTexture(race.texture)
			child.crest:SetHighlightTexture(race.texture)
			child.crest.tooltip = artifact.name .. "\n" .. _G.NORMAL_FONT_COLOR_CODE .. _G.RACE .. " - " .. "|r" .. _G.HIGHLIGHT_FONT_COLOR_CODE .. race.name .. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to solve without key stones"] .. "\n" .. L["Right-Click to solve with key stones"]

			child.artifact.text:SetFormattedText("%s%s", nameColor, artifact.name)
			child.artifact.tooltip = _G.HIGHLIGHT_FONT_COLOR_CODE .. artifact.name .. "|r\n" .. _G.NORMAL_FONT_COLOR_CODE .. artifact.tooltip .. "\n\n" .. _G.HIGHLIGHT_FONT_COLOR_CODE .. L["Solved Count: %s"]:format(_G.NORMAL_FONT_COLOR_CODE .. (completionCount or "0") .. "|r") .. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to open artifact in default Archaeology UI"] .. "|r"

			child.artifact:SetWidth(child.artifact.text:GetStringWidth())
			child.artifact:SetHeight(child.artifact.text:GetStringHeight())
			child:SetWidth(child.fragments:GetWidth() + child.sockets:GetWidth() + child.crest:GetWidth() + child.artifact:GetWidth() + 30)
		end
	end
	local containerXofs = 0

	if private.db.general.theme == "Graphical" and private.db.artifact.style == "Compact" then
		maxHeight = maxHeight + 10
		containerXofs = -10
	end

	RacesFrame.container:SetHeight(maxHeight)
	RacesFrame.container:SetWidth(maxWidth)

	if RacesFrame.skillBar then
		RacesFrame.skillBar:SetWidth(maxWidth)
		RacesFrame.skillBar.border:SetWidth(maxWidth + 9)

		if private.db.general.showSkillBar then
			RacesFrame.skillBar:Show()
			RacesFrame.container:ClearAllPoints()
			RacesFrame.container:SetPoint("TOP", RacesFrame.skillBar, "BOTTOM", containerXofs, -10)
			maxHeight = maxHeight + 30
		else
			RacesFrame.skillBar:Hide()
			RacesFrame.container:ClearAllPoints()
			RacesFrame.container:SetPoint("TOP", RacesFrame, "TOP", containerXofs, -20)
			maxHeight = maxHeight + 10
		end
	else
		RacesFrame.container:ClearAllPoints()
		RacesFrame.container:SetPoint("TOP", RacesFrame, "TOP", containerXofs, -20)
		maxHeight = maxHeight + 10
	end

	if not private.IsTaintable() then
		if racesCount == 0 then
			RacesFrame:Hide()
		end
		RacesFrame:SetHeight(maxHeight + ((private.db.general.theme == "Graphical") and 15 or 25))
		RacesFrame:SetWidth(maxWidth + ((private.db.general.theme == "Graphical") and 45 or 0))
	end
end

function Archy:UpdateDigSiteFrame()
	if private.IsTaintable() then
		private.regen_update_digsites = true
		return
	end

	DigSiteFrame:SetScale(private.db.digsite.scale)
	DigSiteFrame:SetAlpha(private.db.digsite.alpha)

	DigSiteFrame:SetBackdrop({
		bgFile = LSM:Fetch('background', private.db.digsite.backgroundTexture),
		edgeFile = LSM:Fetch('border', private.db.digsite.borderTexture),
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

	DigSiteFrame:SetBackdropColor(1, 1, 1, private.db.digsite.bgAlpha)
	DigSiteFrame:SetBackdropBorderColor(1, 1, 1, private.db.digsite.borderAlpha)

	local digsiteFont = private.db.digsite.font
	local digsiteFontName = LSM:Fetch("font", digsiteFont.name)

	local zoneFont = private.db.digsite.zoneFont
	local zoneFontName = LSM:Fetch("font", zoneFont.name)

	for _, siteFrame in pairs(DigSiteFrame.children) do
		siteFrame.site.name:SetFont(digsiteFontName, digsiteFont.size, digsiteFont.outline)
		siteFrame.site.name:SetTextColor(digsiteFont.color.r, digsiteFont.color.g, digsiteFont.color.b, digsiteFont.color.a)
		FontString_SetShadow(siteFrame.site.name, digsiteFont.shadow)

		siteFrame.digCounter.value:SetFont(digsiteFontName, digsiteFont.size, digsiteFont.outline)
		siteFrame.digCounter.value:SetTextColor(digsiteFont.color.r, digsiteFont.color.g, digsiteFont.color.b, digsiteFont.color.a)
		FontString_SetShadow(siteFrame.digCounter.value, digsiteFont.shadow)

		if private.db.general.theme == "Graphical" then
			siteFrame.zone.name:SetFont(zoneFontName, zoneFont.size, zoneFont.outline)
			siteFrame.zone.name:SetTextColor(zoneFont.color.r, zoneFont.color.g, zoneFont.color.b, zoneFont.color.a)
			FontString_SetShadow(siteFrame.zone.name, zoneFont.shadow)

			siteFrame.distance.value:SetFont(zoneFontName, zoneFont.size, zoneFont.outline)
			siteFrame.distance.value:SetTextColor(zoneFont.color.r, zoneFont.color.g, zoneFont.color.b, zoneFont.color.a)
			FontString_SetShadow(siteFrame.distance.value, zoneFont.shadow)

			if siteFrame.style ~= private.db.digsite.style then
				if private.db.digsite.style == "Compact" then
					siteFrame.crest:SetWidth(20)
					siteFrame.crest:SetHeight(20)
					siteFrame.crest.icon:SetWidth(20)
					siteFrame.crest.icon:SetHeight(20)
					siteFrame.zone:Hide()
					siteFrame.distance:Hide()
					siteFrame:SetHeight(24)
				else
					siteFrame.crest:SetWidth(40)
					siteFrame.crest:SetHeight(40)
					siteFrame.crest.icon:SetWidth(40)
					siteFrame.crest.icon:SetHeight(40)
					siteFrame.zone:Show()
					siteFrame.distance:Show()
					siteFrame:SetHeight(40)
				end
			end
		else
			siteFrame.zone.name:SetFont(digsiteFontName, digsiteFont.size, digsiteFont.outline)
			siteFrame.zone.name:SetTextColor(digsiteFont.color.r, digsiteFont.color.g, digsiteFont.color.b, digsiteFont.color.a)
			FontString_SetShadow(siteFrame.zone.name, digsiteFont.shadow)

			siteFrame.distance.value:SetFont(digsiteFontName, digsiteFont.size, digsiteFont.outline)
			siteFrame.distance.value:SetTextColor(digsiteFont.color.r, digsiteFont.color.g, digsiteFont.color.b, digsiteFont.color.a)
			FontString_SetShadow(siteFrame.distance.value, digsiteFont.shadow)
		end
	end

	local continentID = private.current_continent
	local continentDigsites = private.continent_digsites

	local canShow = not private.db.general.stealthMode and private.db.digsite.show and not FramesShouldBeHidden() and continentDigsites[continentID] and #continentDigsites[continentID] > 0
	if DigSiteFrame:IsVisible() then
		if not canShow then
			DigSiteFrame:Hide()
		end
	else
		if canShow then
			DigSiteFrame:Show()
		end
	end
end

function Archy:ShowDigSiteTooltip(digsite)
	local site_id = digsite:GetParent():GetID()
	local normal_font = _G.NORMAL_FONT_COLOR_CODE
	local highlight_font = _G.HIGHLIGHT_FONT_COLOR_CODE
	local site_stats = self.db.char.digsites.stats

	digsite.tooltip = digsite.name:GetText()
	digsite.tooltip = digsite.tooltip .. ("\n%s%s%s%s|r"):format(normal_font, _G.ZONE .. ": ", highlight_font, digsite:GetParent().zone.name:GetText())
	digsite.tooltip = digsite.tooltip .. ("\n\n%s%s %s%s|r"):format(normal_font, L["Surveys:"], highlight_font, site_stats[site_id].surveys or 0)
	digsite.tooltip = digsite.tooltip .. ("\n%s%s %s%s|r"):format(normal_font, L["Digs"] .. ": ", highlight_font, site_stats[site_id].looted or 0)
	digsite.tooltip = digsite.tooltip .. ("\n%s%s %s%s|r"):format(normal_font, _G.ARCHAEOLOGY_RUNE_STONES .. ": ", highlight_font, site_stats[site_id].fragments or 0)
	digsite.tooltip = digsite.tooltip .. ("\n%s%s %s%s|r"):format(normal_font, L["Key Stones:"], highlight_font, site_stats[site_id].keystones or 0)
	digsite.tooltip = digsite.tooltip .. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to view the zone map"]

	if self:IsSiteBlacklisted(digsite.siteName) then
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
	local topFrame = DigSiteFrame.container
	local siteIndex = 0
	local maxNameWidth, maxZoneWidth, maxDistWidth, maxDigCounterWidth = 0, 0, 70, 20

	for _, siteFrame in pairs(DigSiteFrame.children) do
		siteIndex = siteIndex + 1
		siteFrame.zone:SetWidth(siteFrame.zone.name:GetStringWidth())
		siteFrame.distance:SetWidth(siteFrame.distance.value:GetStringWidth())
		siteFrame.site:SetWidth(siteFrame.site.name:GetStringWidth())

		local width
		local nameWidth = siteFrame.site:GetWidth()
		local zoneWidth = siteFrame.zone:GetWidth()

		if maxNameWidth < nameWidth then
			maxNameWidth = nameWidth
		end

		if maxZoneWidth < zoneWidth then
			maxZoneWidth = zoneWidth
		end

		if maxDistWidth < siteFrame.distance:GetWidth() then
			maxDistWidth = siteFrame.distance:GetWidth()
		end

		maxHeight = maxHeight + siteFrame:GetHeight() + 5
		siteFrame:ClearAllPoints()

		if siteIndex == 1 then
			siteFrame:SetPoint("TOP", topFrame, "TOP", 0, 0)
		else
			siteFrame:SetPoint("TOP", topFrame, "BOTTOM", 0, -5)
		end
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

	for _, siteFrame in pairs(DigSiteFrame.children) do
		siteFrame.zone:SetWidth(maxZoneWidth == 0 and 1 or maxZoneWidth)
		siteFrame.site:SetWidth(maxNameWidth)
		siteFrame.distance:SetWidth(maxDistWidth == 0 and 1 or maxDistWidth)
		siteFrame:SetWidth(maxWidth)
		siteFrame.distance:SetAlpha(private.db.digsite.minimal.showDistance and 1 or 0)
		siteFrame.zone:SetAlpha(private.db.digsite.minimal.showZone and 1 or 0)
	end
	DigSiteFrame.container:SetWidth(maxWidth)
	DigSiteFrame.container:SetHeight(maxHeight)

	if not private.IsTaintable() then
		local cpoint, crelTo, crelPoint, cxOfs, cyOfs = DigSiteFrame.container:GetPoint()
		DigSiteFrame:SetHeight(maxHeight + cyOfs + 40)
		DigSiteFrame:SetWidth(maxWidth + cxOfs + 30)
	end
end

function Archy:ResizeGraphicalDigSiteDisplay()
	local maxWidth, maxHeight = 0, 0
	local topFrame = DigSiteFrame.container
	local siteIndex = 0

	for _, siteFrame in pairs(DigSiteFrame.children) do
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

		if width > maxWidth then
			maxWidth = width
		end
		maxHeight = maxHeight + siteFrame:GetHeight() + 5

		siteFrame:ClearAllPoints()

		if siteIndex == 1 then
			siteFrame:SetPoint("TOP", topFrame, "TOP", 0, 0)
		else
			siteFrame:SetPoint("TOP", topFrame, "BOTTOM", 0, -5)
		end
		topFrame = siteFrame
	end

	for _, siteFrame in pairs(DigSiteFrame.children) do
		siteFrame:SetWidth(maxWidth)
	end
	DigSiteFrame.container:SetWidth(maxWidth)
	DigSiteFrame.container:SetHeight(maxHeight)

	if not private.IsTaintable() then
		local cpoint, crelTo, crelPoint, cxOfs, cyOfs = DigSiteFrame.container:GetPoint()
		DigSiteFrame:SetHeight(maxHeight + cyOfs + 40)
		DigSiteFrame:SetWidth(maxWidth + cxOfs + 30)
	end
end

function Archy:RefreshDigSiteDisplay()
	if FramesShouldBeHidden() then
		return
	end
	local continentID = private.current_continent
	local continentDigsites = private.continent_digsites

	if not continentID or not continentDigsites[continentID] or #continentDigsites[continentID] == 0 then
		return
	end

	local maxSurveyCount = (continentID == _G.WORLDMAP_DRAENOR_ID) and NUM_DIGSITE_FINDS_DRAENOR or NUM_DIGSITE_FINDS_DEFAULT

	for digSiteIndex, digSite in pairs(continentDigsites[continentID]) do
		local childFrame = DigSiteFrame.children[digSiteIndex]
		local count = self.db.char.digsites.stats[digSite.id].counter

		if private.db.general.theme == "Graphical" then
			childFrame.digCounter.value:SetText(count or "")
		else
			childFrame.digCounter.value:SetFormattedText("%d/%d", count or 0, maxSurveyCount)
		end

		if digSite.distance then
			childFrame.distance.value:SetFormattedText(L["%d yards"], digSite.distance)
		else
			childFrame.distance.value:SetText(_G.UNKNOWN)
		end


		if self:IsSiteBlacklisted(digSite.name) then
			childFrame.site.name:SetFormattedText("|cFFFF0000%s", digSite.name)
		else
			childFrame.site.name:SetText(digSite.name)
		end

		if childFrame.site.siteName ~= digSite.name then
			local race = private.Races[digSite.raceId]
			childFrame.crest.icon:SetTexture(race.texture)
			childFrame.crest.tooltip = race.name
			childFrame.zone.name:SetText(digSite.zoneName)
			childFrame.site.siteName = digSite.name or _G.UNKNOWN
			childFrame.site.zoneId = digSite.zoneId
			childFrame:SetID(digSite.id)
		end
	end
	self:ResizeDigSiteDisplay()
end

function Archy:SetFramePosition(frame)
	if frame.isMoving or (frame:IsProtected() and private.IsTaintable()) then
		return
	end
	local bPoint, bRelativePoint, bXofs, bYofs
	local bRelativeTo = _G.UIParent

	if frame == DigSiteFrame then
		bPoint, bRelativePoint, bXofs, bYofs = unpack(private.db.digsite.position)
	elseif frame == RacesFrame then
		bPoint, bRelativePoint, bXofs, bYofs = unpack(private.db.artifact.position)
	elseif frame == DistanceIndicatorFrame then
		if not private.db.digsite.distanceIndicator.undocked then
			bRelativeTo = DigSiteFrame
			bPoint, bRelativePoint, bXofs, bYofs = "CENTER", "TOPLEFT", 50, -5
			frame:SetParent(DigSiteFrame)
		else
			frame:SetParent(_G.UIParent)
			bPoint, bRelativePoint, bXofs, bYofs = unpack(private.db.digsite.distanceIndicator.position)
		end
	end
	frame:ClearAllPoints()
	frame:SetPoint(bPoint, bRelativeTo, bRelativePoint, bXofs, bYofs)
	frame:SetFrameLevel(2)

	if frame:GetParent() == _G.UIParent and not private.IsTaintable() and not private.db.general.locked then
		frame:SetUserPlaced(false)
	end
end

function Archy:SaveFramePosition(frame)
	local bPoint, bRelativeTo, bRelativePoint, bXofs, bYofs = frame:GetPoint()
	local width, height
	local anchor, position

	if frame == DigSiteFrame then
		anchor = self.db.profile.digsite.anchor
		position = self.db.profile.digsite.position
	elseif frame == RacesFrame then
		anchor = self.db.profile.artifact.anchor
		position = self.db.profile.artifact.position
	elseif frame == DistanceIndicatorFrame then
		anchor = self.db.profile.digsite.distanceIndicator.anchor
		position = self.db.profile.digsite.distanceIndicator.position
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
	end

	if frame == DigSiteFrame then
		private.db.digsite.position = position
	elseif frame == RacesFrame then
		private.db.artifact.position = position
	elseif frame == DistanceIndicatorFrame then
		private.db.digsite.distanceIndicator.position = position
	end
end

