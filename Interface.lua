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
local tonumber = _G.tonumber
local unpack = _G.unpack

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale("Archy", false)
local Archy = LibStub("AceAddon-3.0"):GetAddon("Archy")
local LSM = LibStub("LibSharedMedia-3.0")

local Astrolabe = _G.DongleStub("Astrolabe-1.0")

-----------------------------------------------------------------------
-- Constants.
-----------------------------------------------------------------------
local NUM_DIGSITE_FINDS_DEFAULT = 6
local NUM_DIGSITE_FINDS_DRAENOR = 9

-----------------------------------------------------------------------
-- Helpers.
-----------------------------------------------------------------------
local function FramesShouldBeHidden()
	return (not private.db.general.show or not private.current_continent or private.current_continent == -1 or _G.UnitIsGhost("player") or _G.IsInInstance() or _G.C_PetBattles.IsInBattle() or not private.HasArchaeology())
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

local ArtifactFrame
local DigSiteFrame
local DistanceIndicatorFrame
do
	-----------------------------------------------------------------------
	-- ArtifactFrame
	-----------------------------------------------------------------------
	local function ArtifactFrame_RefreshDisplay(self)
		if FramesShouldBeHidden() then
			return
		end
		local maxWidth, maxHeight = 0, 0
		Archy:UpdateSkillBar()

		local topFrame = self.container
		local hiddenAnchor = self
		local racesCount = 0

		if private.db.general.theme == "Minimal" then
			self.title.text:SetText(L["Artifacts"])
		end

		for _, child in pairs(self.children) do
			child:Hide()
		end

		for raceID, race in pairs(private.Races) do
			local child = self.children[raceID]
			local artifact = race.currentProject
			local _, _, completionCount = race:GetArtifactCompletionDataByName(artifact.name)

			child:SetID(raceID)

			local continentHasRace = private.CONTINENT_RACES[private.current_continent][raceID]
			if not race:IsOnArtifactBlacklist() and artifact.fragments_required > 0 and (not private.db.artifact.filter or continentHasRace) then
				child:ClearAllPoints()

				if topFrame == self.container then
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
					child.fragmentBar.barBackground:SetTexCoord(0, 0.72265625, 0.3671875, 0.7890625)
				else
					if completionCount == 0 then
						barColor = private.db.artifact.fragmentBarColors["FirstTime"]
					else
						barColor = private.db.artifact.fragmentBarColors["Normal"]
					end
					child.fragmentBar.barBackground:SetTexCoord(0, 0.72265625, 0, 0.411875)
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

		self.container:SetHeight(maxHeight)
		self.container:SetWidth(maxWidth)

		if self.skillBar then
			self.skillBar:SetWidth(maxWidth)
			self.skillBar.border:SetWidth(maxWidth + 9)

			if private.db.general.showSkillBar then
				self.skillBar:Show()
				self.container:ClearAllPoints()
				self.container:SetPoint("TOP", self.skillBar, "BOTTOM", containerXofs, -10)
				maxHeight = maxHeight + 30
			else
				self.skillBar:Hide()
				self.container:ClearAllPoints()
				self.container:SetPoint("TOP", self, "TOP", containerXofs, -20)
				maxHeight = maxHeight + 10
			end
		else
			self.container:ClearAllPoints()
			self.container:SetPoint("TOP", self, "TOP", containerXofs, -20)
			maxHeight = maxHeight + 10
		end

		if not private.IsTaintable() then
			if racesCount == 0 then
				self:Hide()
			end
			self:SetHeight(maxHeight + ((private.db.general.theme == "Graphical") and 15 or 25))
			self:SetWidth(maxWidth + ((private.db.general.theme == "Graphical") and 45 or 0))
		end
	end

	local function ArtifactFrame_UpdateChrome(self)
		if private.IsTaintable() then
			private.regen_update_races = true
			return
		end

		self:SetScale(private.db.artifact.scale)
		self:SetAlpha(private.db.artifact.alpha)

		local is_movable = not private.db.general.locked
		self:SetMovable(is_movable)
		self:EnableMouse(is_movable)

		if is_movable then
			self:RegisterForDrag("LeftButton")
		else
			self:RegisterForDrag()
		end

		local artifactFont = private.db.artifact.font
		local fragmentFont = private.db.artifact.fragmentFont
		local keystoneFont = private.db.artifact.keystoneFont

		local artifactFontName = LSM:Fetch("font", artifactFont.name)
		local fragmentFontName = LSM:Fetch("font", fragmentFont.name)
		local keystoneFontName = LSM:Fetch("font", keystoneFont.name)

		for _, child in pairs(self.children) do
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

		self:SetBackdrop({
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

		self:SetBackdropColor(1, 1, 1, private.db.artifact.bgAlpha)
		self:SetBackdropBorderColor(1, 1, 1, private.db.artifact.borderAlpha)

		if not private.IsTaintable() then
			local height = self.container:GetHeight() + ((private.db.general.theme == "Graphical") and 15 or 25)
			if private.db.general.showSkillBar and private.db.general.theme == "Graphical" then
				height = height + 30
			end
			self:SetHeight(height)
			self:SetWidth(self.container:GetWidth() + ((private.db.general.theme == "Graphical") and 45 or 0))
		end

		local canShow = not private.db.general.stealthMode and private.db.artifact.show and not FramesShouldBeHidden()
		if self:IsVisible() then
			if not canShow then
				self:Hide()
			end
		else
			if canShow then
				self:Show()
			end
		end
	end

	-----------------------------------------------------------------------
	-- DigSiteFrame
	-----------------------------------------------------------------------
	local function DigSiteFrame_UpdateChrome(self)
		if private.IsTaintable() then
			private.regen_update_digsites = true
			return
		end

		self:SetScale(private.db.digsite.scale)
		self:SetAlpha(private.db.digsite.alpha)

		self:SetBackdrop({
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

		self:SetBackdropColor(1, 1, 1, private.db.digsite.bgAlpha)
		self:SetBackdropBorderColor(1, 1, 1, private.db.digsite.borderAlpha)

		local digsiteFont = private.db.digsite.font
		local digsiteFontName = LSM:Fetch("font", digsiteFont.name)

		local zoneFont = private.db.digsite.zoneFont
		local zoneFontName = LSM:Fetch("font", zoneFont.name)

		for _, siteFrame in pairs(self.children) do
			siteFrame.siteButton.name:SetFont(digsiteFontName, digsiteFont.size, digsiteFont.outline)
			siteFrame.siteButton.name:SetTextColor(digsiteFont.color.r, digsiteFont.color.g, digsiteFont.color.b, digsiteFont.color.a)
			FontString_SetShadow(siteFrame.siteButton.name, digsiteFont.shadow)

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
		if self:IsVisible() then
			if not canShow then
				self:Hide()
			end
		else
			if canShow then
				self:Show()
			end
		end
	end

	-----------------------------------------------------------------------
	-- DistanceIndicatorFrame
	-----------------------------------------------------------------------
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

	local function DistanceIndicatorFrame_Reset(self)
		self:SetColor("green")
		self.circle.distance:SetFormattedText("%1.f", 0)
	end

	local function DistanceIndicatorFrame_SetColor(self, color)
		self.circle.texture:SetTexCoord(unpack(DISTANCE_COLOR_TEXCOORDS[color]))
		self.circle:SetAlpha(1)
		self:Toggle()
	end

	local function DistanceIndicatorFrame_Update(self, mapID, mapLevel, mapX, mapY, surveyMapID, surveyMapLevel, surveyMapX, surveyMapY)
		if surveyMapX == 0 and surveyMapY == 0 or _G.IsInInstance() then
			return
		end

		local distance = Astrolabe:ComputeDistance(mapID, mapLevel, mapX, mapY, surveyMapID, surveyMapLevel, surveyMapX, surveyMapY) or 0
		local greenMin, greenMax = 0, private.db.digsite.distanceIndicator.green
		local yellowMin, yellowMax = greenMax, private.db.digsite.distanceIndicator.yellow
		local redMin, redMax = yellowMax, 500

		if distance >= greenMin and distance <= greenMax then
			self:SetColor("green")
		elseif distance >= yellowMin and distance <= yellowMax then
			self:SetColor("yellow")
		elseif distance >= redMin and distance <= redMax then
			self:SetColor("red")
		else
			self:Toggle()
			return
		end

		self.circle.distance:SetFormattedText("%1.f", distance)
	end

	local function DistanceIndicatorFrame_Toggle(self)
		if private.IsTaintable() then
			private.regen_toggle_distance = true
			return
		end

		local indicatorSettings = private.db.digsite.distanceIndicator
		if not indicatorSettings.enabled or private.FramesShouldBeHidden() then
			self:Hide()
			return
		end
		self:Show()

		if self.isActive then
			self.circle:SetAlpha(1)
		else
			self.circle.distance:SetText("0")

			if indicatorSettings.undocked and not private.db.general.locked and (indicatorSettings.showSurveyButton or indicatorSettings.showCrateButton or indicatorSettings.showLorItemButton) then
				self.circle:SetAlpha(0.25)
			else
				self.circle:SetAlpha(0)
			end
		end

		if indicatorSettings.showSurveyButton then
			self.surveyButton:Show()
			self:SetWidth(52 + self.surveyButton:GetWidth())
		else
			self.surveyButton:Hide()
			self:SetWidth(42)
		end

		if indicatorSettings.showCrateButton then
			self.crateButton:Show()
			self:SetWidth(self:GetWidth() + 10 + self.crateButton:GetWidth())
		else
			self.crateButton:Hide()
		end

		if indicatorSettings.showLorItemButton then
			self.loritemButton:Show()
			self:SetWidth(self:GetWidth() + 10 + self.loritemButton:GetWidth())
		else
			self.loritemButton:Hide()
		end
	end

	local function InitializeFrames()
		if private.IsTaintable() then
			private.regen_create_frames = true
			return
		end

		-----------------------------------------------------------------------
		-- ArtifactFrame
		-----------------------------------------------------------------------
		local artifactTemplate = (private.db.general.theme == "Graphical" and "ArchyArtifactContainer" or "ArchyMinArtifactContainer")
		ArtifactFrame = _G.CreateFrame("Frame", "ArchyArtifactFrame", _G.UIParent, artifactTemplate)
		ArtifactFrame.children = setmetatable({}, {
			__index = function(t, k)
				if k then
					local template = (private.db.general.theme == "Graphical" and "ArchyArtifactRowTemplate" or "ArchyMinArtifactRowTemplate")
					local child = _G.CreateFrame("Frame", "ArchyArtifactChildFrame" .. private.DigsiteRaceLabelFromID[k], ArtifactFrame, template)
					child:Show()
					t[k] = child
					return child
				end
			end
		})

		ArtifactFrame.RefreshDisplay = ArtifactFrame_RefreshDisplay
		ArtifactFrame.UpdateChrome = ArtifactFrame_UpdateChrome

		private.ArtifactFrame = ArtifactFrame

		-----------------------------------------------------------------------
		-- DigSiteFrame
		-----------------------------------------------------------------------
		local digSiteTemplate = (private.db.general.theme == "Graphical" and "ArchyDigSiteContainer" or "ArchyMinDigSiteContainer")
		DigSiteFrame = _G.CreateFrame("Frame", "ArchyDigSiteFrame", _G.UIParent, digSiteTemplate)
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

		DigSiteFrame.UpdateChrome = DigSiteFrame_UpdateChrome

		private.DigSiteFrame = DigSiteFrame

		-----------------------------------------------------------------------
		-- DistanceIndicatorFrame
		-----------------------------------------------------------------------
		DistanceIndicatorFrame = _G.CreateFrame("Frame", "ArchyDistanceIndicatorFrame", _G.UIParent, "ArchyDistanceIndicator")
		DistanceIndicatorFrame.circle:SetScale(0.65)

		DistanceIndicatorFrame.Reset = DistanceIndicatorFrame_Reset
		DistanceIndicatorFrame.SetColor = DistanceIndicatorFrame_SetColor
		DistanceIndicatorFrame.Toggle = DistanceIndicatorFrame_Toggle
		DistanceIndicatorFrame.Update = DistanceIndicatorFrame_Update

		private.DistanceIndicatorFrame = DistanceIndicatorFrame
	end

	private.InitializeFrames = InitializeFrames
end -- do-block

-----------------------------------------------------------------------
-- Methods.
-----------------------------------------------------------------------
function Archy:ShowDigSiteChildFrameSiteButtonTooltip(siteButton)
	local digsite = siteButton.digsite
	local highlightFont = _G.HIGHLIGHT_FONT_COLOR_CODE
	local normalFont = _G.NORMAL_FONT_COLOR_CODE

	siteButton.tooltip = siteButton.name:GetText()
	siteButton.tooltip = siteButton.tooltip .. ("\n%s%s: %s%s|r"):format(normalFont, _G.ZONE, highlightFont, digsite.zoneName)
	siteButton.tooltip = siteButton.tooltip .. ("\n\n%s%s %s%s|r"):format(normalFont, L["Surveys:"], highlightFont, digsite.stats.surveys)
	siteButton.tooltip = siteButton.tooltip .. ("\n%s%s: %s%s|r"):format(normalFont, L["Digs"], highlightFont, digsite.stats.looted)
	siteButton.tooltip = siteButton.tooltip .. ("\n%s%s: %s%s|r"):format(normalFont, _G.ARCHAEOLOGY_RUNE_STONES, highlightFont, digsite.stats.fragments)
	siteButton.tooltip = siteButton.tooltip .. ("\n%s%s %s%s|r"):format(normalFont, L["Key Stones:"], highlightFont, digsite.stats.keystones)
	siteButton.tooltip = siteButton.tooltip .. "\n\n" .. _G.GREEN_FONT_COLOR_CODE .. L["Left-Click to view the zone map"]

	if siteButton.digsite:IsBlacklisted() then
		siteButton.tooltip = siteButton.tooltip .. "\n" .. L["Right-Click to remove from blacklist"]
	else
		siteButton.tooltip = siteButton.tooltip .. "\n" .. L["Right-Click to blacklist"]
	end
	_G.GameTooltip:SetOwner(siteButton, "ANCHOR_BOTTOMRIGHT")
	_G.GameTooltip:SetText(siteButton.tooltip, _G.NORMAL_FONT_COLOR[1], _G.NORMAL_FONT_COLOR[2], _G.NORMAL_FONT_COLOR[3], 1, true)
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
		siteFrame.siteButton:SetWidth(siteFrame.siteButton.name:GetStringWidth())
		siteFrame.digCounter:SetWidth(siteFrame.digCounter.value:GetStringWidth())

		local width
		local nameWidth = siteFrame.siteButton:GetWidth()
		local zoneWidth = siteFrame.zone:GetWidth()
		local digCounterWidth = siteFrame.digCounter:GetWidth()
		local distWidth = siteFrame.distance:GetWidth()

		if maxNameWidth < nameWidth then
			maxNameWidth = nameWidth
		end

		if maxZoneWidth < zoneWidth then
			maxZoneWidth = zoneWidth
		end

		if maxDistWidth < distWidth then
			maxDistWidth = distWidth
		end

		if maxDigCounterWidth < digCounterWidth then
			maxDigCounterWidth = digCounterWidth
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
		siteFrame.siteButton:SetWidth(maxNameWidth)
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
		siteFrame.siteButton:SetWidth(siteFrame.siteButton.name:GetStringWidth())
		siteFrame.digCounter:SetWidth(siteFrame.digCounter.value:GetStringWidth())

		local width
		local nameWidth = siteFrame.siteButton:GetWidth()
		local zoneWidth = siteFrame.zone:GetWidth() + 10

		if nameWidth > zoneWidth then
			width = siteFrame.crest:GetWidth() + nameWidth + siteFrame.digCounter:GetWidth() + 6
		else
			width = siteFrame.crest:GetWidth() + zoneWidth + siteFrame.distance:GetWidth() + 6
		end
		width = width + siteFrame.digCounter:GetWidth()

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

	for digsiteIndex, digsite in pairs(continentDigsites[continentID]) do
		local childFrame = DigSiteFrame.children[digsiteIndex]
		local count = digsite.stats.counter

		childFrame.digCounter.value:SetFormattedText("%d/%d", count or 0, digsite.maxFindCount or maxSurveyCount)

		if digsite.distance then
			childFrame.distance.value:SetFormattedText(L["%d yards"], digsite.distance)
		else
			childFrame.distance.value:SetText(_G.UNKNOWN)
		end


		if digsite:IsBlacklisted() then
			childFrame.siteButton.name:SetFormattedText("|cFFFF0000%s", digsite.name)
		else
			childFrame.siteButton.name:SetText(digsite.name)
		end

		if childFrame.siteButton.digsite ~= digsite then
			childFrame.siteButton.digsite = digsite
			childFrame.siteButton.zoneID = digsite.zoneID
			childFrame.zone.name:SetText(digsite.zoneName)
			childFrame:SetID(digsite.blobID)

			local race = digsite.race
			childFrame.crest.icon:SetTexture(race.texture)
			childFrame.crest.tooltip = race.name
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
	elseif frame == ArtifactFrame then
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
	elseif frame == ArtifactFrame then
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
	elseif frame == ArtifactFrame then
		private.db.artifact.position = position
	elseif frame == DistanceIndicatorFrame then
		private.db.digsite.distanceIndicator.position = position
	end
end

