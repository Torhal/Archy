-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-- Libraries
local math = _G.math
local table = _G.table

-- Functions
local pairs = _G.pairs
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
local SURVEYS_PER_DIGSITE = 6

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

-----------------------------------------------------------------------
-- Methods.
-----------------------------------------------------------------------
function Archy:UpdateRacesFrame()
	if private.IsTaintable() then
		private.regen_update_races = true
		return
	end
	local races_frame = private.races_frame

	races_frame:SetScale(private.db.artifact.scale)
	races_frame:SetAlpha(private.db.artifact.alpha)

	local is_movable = not private.db.general.locked
	races_frame:SetMovable(is_movable)
	races_frame:EnableMouse(is_movable)

	if is_movable then
		races_frame:RegisterForDrag("LeftButton")
	else
		races_frame:RegisterForDrag()
	end

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

			FontString_SetShadow(child.fragmentBar.artifact, artifact_font_data.shadow)
			FontString_SetShadow(child.fragmentBar.fragments, artifact_fragment_font_data.shadow)
			FontString_SetShadow(child.fragmentBar.keystones.count, private.db.artifact.keystoneFont.shadow)
		else
			child.fragments.text:SetFont(font, artifact_font_data.size, artifact_font_data.outline)
			child.fragments.text:SetTextColor(artifact_font_data.color.r, artifact_font_data.color.g, artifact_font_data.color.b, artifact_font_data.color.a)

			child.sockets.text:SetFont(font, artifact_font_data.size, artifact_font_data.outline)
			child.sockets.text:SetTextColor(artifact_font_data.color.r, artifact_font_data.color.g, artifact_font_data.color.b, artifact_font_data.color.a)

			child.artifact.text:SetFont(font, artifact_font_data.size, artifact_font_data.outline)
			child.artifact.text:SetTextColor(artifact_font_data.color.r, artifact_font_data.color.g, artifact_font_data.color.b, artifact_font_data.color.a)

			FontString_SetShadow(child.fragments.text, artifact_font_data.shadow)
			FontString_SetShadow(child.sockets.text, artifact_font_data.shadow)
			FontString_SetShadow(child.artifact.text, artifact_font_data.shadow)
		end
	end
	local borderTexture = LSM:Fetch('border', private.db.artifact.borderTexture)
	local backgroundTexture = LSM:Fetch('background', private.db.artifact.backgroundTexture)

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


	if not private.IsTaintable() then
		local height = races_frame.container:GetHeight() + ((private.db.general.theme == "Graphical") and 15 or 25)
		if private.db.general.showSkillBar and private.db.general.theme == "Graphical" then
			height = height + 30
		end
		races_frame:SetHeight(height)
		races_frame:SetWidth(races_frame.container:GetWidth() + ((private.db.general.theme == "Graphical") and 45 or 0))
	end

	if races_frame:IsVisible() then
		if private.db.general.stealthMode or not private.db.artifact.show or FramesShouldBeHidden() then
			races_frame:Hide()
		end
	else
		if not private.db.general.stealthMode and private.db.artifact.show and not FramesShouldBeHidden() then
			races_frame:Show()
		end
	end
end

-- returns a list of race ids for the continent map id
-- TODO: This should be a static list. Creating throwaway tables to perform costly iterations on, every time this information is requested, is madness.
local function ContinentRaces(continent_id)
	local races = {}
	for _, site in pairs(private.DIG_SITES) do
		if site.continent == continent_id and not _G.tContains(races, site.race) then
			table.insert(races, site.race)
		end
	end
	return races
end

function Archy:RefreshRacesDisplay()
	if FramesShouldBeHidden() or _G.GetNumArchaeologyRaces() == 0 then
		return
	end
	local maxWidth, maxHeight = 0, 0
	self:UpdateSkillBar()

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

	for raceID, race in pairs(private.Races) do
		local child = races_frame.children[raceID]
		local artifact = race.artifact
		local _, _, completionCount = race:GetArtifactCompletionDataByName(artifact.name)

		child:SetID(raceID)

		if private.db.general.theme == "Graphical" then
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

		if not private.db.artifact.blacklist[raceID] and artifact.fragments_required > 0 and (not private.db.artifact.filter or _G.tContains(ContinentRaces(private.current_continent), raceID)) then
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

	if not private.IsTaintable() then
		if count == 0 then
			races_frame:Hide()
		end
		races_frame:SetHeight(maxHeight + ((private.db.general.theme == "Graphical") and 15 or 25))
		races_frame:SetWidth(maxWidth + ((private.db.general.theme == "Graphical") and 45 or 0))
	end
end

function Archy:UpdateDigSiteFrame()
	if private.IsTaintable() then
		private.regen_update_digsites = true
		return
	end
	private.digsite_frame:SetScale(private.db.digsite.scale)
	private.digsite_frame:SetAlpha(private.db.digsite.alpha)

	local borderTexture = LSM:Fetch('border', private.db.digsite.borderTexture)
	local backgroundTexture = LSM:Fetch('background', private.db.digsite.backgroundTexture)

	private.digsite_frame:SetBackdrop({
		bgFile = backgroundTexture,
		edgeFile = borderTexture,
		tile = false,
		edgeSize = 8,
		tileSize = 8,
		insets = { left = 2, top = 2, right = 2, bottom = 2 }
	})

	private.digsite_frame:SetBackdropColor(1, 1, 1, private.db.digsite.bgAlpha)
	private.digsite_frame:SetBackdropBorderColor(1, 1, 1, private.db.digsite.borderAlpha)

	local font = LSM:Fetch("font", private.db.digsite.font.name)
	local zoneFont = LSM:Fetch("font", private.db.digsite.zoneFont.name)
	local digsite_font = private.db.digsite.font

	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteFrame.site.name:SetFont(font, digsite_font.size, digsite_font.outline)
		siteFrame.digCounter.value:SetFont(font, digsite_font.size, digsite_font.outline)
		siteFrame.site.name:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
		siteFrame.digCounter.value:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
		FontString_SetShadow(siteFrame.site.name, digsite_font.shadow)
		FontString_SetShadow(siteFrame.digCounter.value, digsite_font.shadow)

		if private.db.general.theme == "Graphical" then
			local zone_font = private.db.digsite.zoneFont

			siteFrame.zone.name:SetFont(zoneFont, zone_font.size, zone_font.outline)
			siteFrame.distance.value:SetFont(zoneFont, zone_font.size, zone_font.outline)
			siteFrame.zone.name:SetTextColor(zone_font.color.r, zone_font.color.g, zone_font.color.b, zone_font.color.a)
			siteFrame.distance.value:SetTextColor(zone_font.color.r, zone_font.color.g, zone_font.color.b, zone_font.color.a)
			FontString_SetShadow(siteFrame.zone.name, zone_font.shadow)
			FontString_SetShadow(siteFrame.distance.value, zone_font.shadow)
		else
			siteFrame.zone.name:SetFont(font, digsite_font.size, digsite_font.outline)
			siteFrame.distance.value:SetFont(font, digsite_font.size, digsite_font.outline)
			siteFrame.zone.name:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
			siteFrame.distance.value:SetTextColor(digsite_font.color.r, digsite_font.color.g, digsite_font.color.b, digsite_font.color.a)
			FontString_SetShadow(siteFrame.zone.name, digsite_font.shadow)
			FontString_SetShadow(siteFrame.distance.value, digsite_font.shadow)
		end
	end

	local continentID = private.current_continent
	local continentDigsites = private.continent_digsites

	if private.digsite_frame:IsVisible() then
		if private.db.general.stealthMode or not private.db.digsite.show or FramesShouldBeHidden() or not continentDigsites[continentID] or #continentDigsites[continentID] == 0 then
			private.digsite_frame:Hide()
		end
	else
		if not private.db.general.stealthMode and private.db.digsite.show and not FramesShouldBeHidden() and continentDigsites[continentID] and #continentDigsites[continentID] > 0 then
			private.digsite_frame:Show()
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

	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteFrame.zone:SetWidth(maxZoneWidth == 0 and 1 or maxZoneWidth)
		siteFrame.site:SetWidth(maxNameWidth)
		siteFrame.distance:SetWidth(maxDistWidth == 0 and 1 or maxDistWidth)
		siteFrame:SetWidth(maxWidth)
		siteFrame.distance:SetAlpha(private.db.digsite.minimal.showDistance and 1 or 0)
		siteFrame.zone:SetAlpha(private.db.digsite.minimal.showZone and 1 or 0)
	end
	private.digsite_frame.container:SetWidth(maxWidth)
	private.digsite_frame.container:SetHeight(maxHeight)

	if not private.IsTaintable() then
		local cpoint, crelTo, crelPoint, cxOfs, cyOfs = private.digsite_frame.container:GetPoint()
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

	for _, siteFrame in pairs(private.digsite_frame.children) do
		siteFrame:SetWidth(maxWidth)
	end
	private.digsite_frame.container:SetWidth(maxWidth)
	private.digsite_frame.container:SetHeight(maxHeight)

	if not private.IsTaintable() then
		local cpoint, crelTo, crelPoint, cxOfs, cyOfs = private.digsite_frame.container:GetPoint()
		private.digsite_frame:SetHeight(maxHeight + cyOfs + 40)
		private.digsite_frame:SetWidth(maxWidth + cxOfs + 30)
	end
end

function Archy:RefreshDigSiteDisplay()
	if FramesShouldBeHidden() then
		return
	end
	local continent_id = private.current_continent
	local continentDigsites = private.continent_digsites

	if not continent_id or not continentDigsites[continent_id] or #continentDigsites[continent_id] == 0 then
		return
	end

	for _, site_frame in pairs(private.digsite_frame.children) do
		site_frame:Hide()
	end

	for _, site in pairs(continentDigsites[continent_id]) do
		if not site.distance then
			return
		end
	end

	for site_index, site in pairs(continentDigsites[continent_id]) do
		local site_frame = private.digsite_frame.children[site_index]
		local count = self.db.char.digsites.stats[site.id].counter

		if private.db.general.theme == "Graphical" then
			if site_frame.style ~= private.db.digsite.style then
				if private.db.digsite.style == "Compact" then
					site_frame.crest:SetWidth(20)
					site_frame.crest:SetHeight(20)
					site_frame.crest.icon:SetWidth(20)
					site_frame.crest.icon:SetHeight(20)
					site_frame.zone:Hide()
					site_frame.distance:Hide()
					site_frame:SetHeight(24)
				else
					site_frame.crest:SetWidth(40)
					site_frame.crest:SetHeight(40)
					site_frame.crest.icon:SetWidth(40)
					site_frame.crest.icon:SetHeight(40)
					site_frame.zone:Show()
					site_frame.distance:Show()
					site_frame:SetHeight(40)
				end
			end
			site_frame.digCounter.value:SetText(count or "")
		else
			site_frame.digCounter.value:SetFormattedText("%d/%d", count or 0, SURVEYS_PER_DIGSITE)
		end

		site_frame.distance.value:SetFormattedText(L["%d yards"], site.distance)

		if self:IsSiteBlacklisted(site.name) then
			site_frame.site.name:SetFormattedText("|cFFFF0000%s", site.name)
		else
			site_frame.site.name:SetText(site.name)
		end

		if site_frame.site.siteName ~= site.name then
			local race = private.Races[site.raceId]
			site_frame.crest.icon:SetTexture(race.texture)
			site_frame.crest.tooltip = race.name
			site_frame.zone.name:SetText(site.zoneName)
			site_frame.site.siteName = site.name
			site_frame.site.zoneId = site.zoneId
			site_frame:SetID(site.id)
		end
		site_frame:Show()
	end
	self:ResizeDigSiteDisplay()
end

function Archy:SetFramePosition(frame)
	if frame.isMoving or (frame:IsProtected() and private.IsTaintable()) then
		return
	end
	local bPoint, bRelativePoint, bXofs, bYofs
	local bRelativeTo = _G.UIParent

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

	if frame:GetParent() == _G.UIParent and not private.IsTaintable() and not private.db.general.locked then
		frame:SetUserPlaced(false)
	end
end

function Archy:SaveFramePosition(frame)
	local bPoint, bRelativeTo, bRelativePoint, bXofs, bYofs = frame:GetPoint()
	local width, height
	local anchor, position

	if frame == private.digsite_frame then
		anchor = self.db.profile.digsite.anchor
		position = self.db.profile.digsite.position
	elseif frame == private.races_frame then
		anchor = self.db.profile.artifact.anchor
		position = self.db.profile.artifact.position
	elseif frame == private.distance_indicator_frame then
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

	if frame == private.digsite_frame then
		private.db.digsite.position = position
	elseif frame == private.races_frame then
		private.db.artifact.position = position
	elseif frame == private.distance_indicator_frame then
		private.db.digsite.distanceIndicator.position = position
	end
end

