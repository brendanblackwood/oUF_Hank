local oUF_Hank = {}
local cfg = oUF_Hank_config

oUF_Hank.digitTexCoords = {
	["1"] = {1, 20},
	["2"] = {21, 31},
	["3"] = {53, 30},
	["4"] = {84, 33},
	["5"] = {118, 30},
	["6"] = {149, 31},
	["7"] = {181, 30},
	["8"] = {212, 31},
	["9"] = {244, 31},
	["0"] = {276, 31},
	["%"] = {308, 17},
	["X"] = {326, 31}, -- Dead
	["G"] = {358, 36}, -- Ghost
	["Off"] = {395, 23}, -- Offline
	["B"] = {419, 42}, -- Boss
	["height"] = 42,
	["texWidth"] = 512,
	["texHeight"] = 128
}

local fntBig = CreateFont("UFFontBig")
fntBig:SetFont(unpack(cfg.FontStyleBig))
local fntMedium = CreateFont("UFFontMedium")
fntMedium:SetFont(unpack(cfg.FontStyleMedium))
fntMedium:SetTextColor(unpack(cfg.colors.text))
fntMedium:SetShadowColor(unpack(cfg.colors.textShadow))
fntMedium:SetShadowOffset(1, -1)
local fntSmall = CreateFont("UFFontSmall")
fntSmall:SetFont(unpack(cfg.FontStyleSmall))
fntSmall:SetTextColor(unpack(cfg.colors.text))
fntSmall:SetShadowColor(unpack(cfg.colors.textShadow))
fntSmall:SetShadowOffset(1, -1)

local canDispel = {}

-- Functions -------------------------------------

-- Unit menu
oUF_Hank.menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)
	
	-- Swap menus in vehicle
	if self == oUF_player and cunit=="Vehicle" then cunit = "Player" end
	if self == oUF_pet and cunit=="Player" then cunit = "Pet" end

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

-- Party frames be gone!
oUF_Hank.HideParty = function()
	for i = 1, 4 do
		local party = "PartyMemberFrame" .. i
		local frame = _G[party]

		frame:UnregisterAllEvents()
		frame.Show = function() end
		frame:Hide()

		_G[party .. "HealthBar"]:UnregisterAllEvents()
		_G[party .. "ManaBar"]:UnregisterAllEvents()
	end
end

-- Set up the mirror bars (breath, exhaustion etc.)
oUF_Hank.AdjustMirrorBars = function()
	for k, v in pairs(MirrorTimerColors) do
		MirrorTimerColors[k].r = cfg.colors.castbar.bar[1]
		MirrorTimerColors[k].g = cfg.colors.castbar.bar[2]
		MirrorTimerColors[k].b = cfg.colors.castbar.bar[3]
	end

	for i = 1, MIRRORTIMER_NUMTIMERS do
		local mirror = _G["MirrorTimer" .. i]
		local statusbar = _G["MirrorTimer" .. i .. "StatusBar"]
		local backdrop = select(1, mirror:GetRegions())
		local border = _G["MirrorTimer" .. i .. "Border"]
		local text = _G["MirrorTimer" .. i .. "Text"]

		mirror:ClearAllPoints()
		mirror:SetPoint("BOTTOM", (i == 1) and oUF_player.Castbar or _G["MirrorTimer" .. i - 1], "TOP", 0, 5 + ((i == 1) and 5 or 0))
		mirror:SetSize(cfg.CastbarSize[1], 12)
		statusbar:SetStatusBarTexture(cfg.CastbarTexture)
		statusbar:SetAllPoints(mirror)
		backdrop:SetTexture(cfg.CastbarBackdropTexture)
		backdrop:SetVertexColor(0.22, 0.22, 0.19, 0.8)
		backdrop:SetAllPoints(mirror)
		border:Hide()
		text:SetFont(unpack(cfg.CastBarMedium))
		text:SetJustifyH("LEFT")
		text:SetJustifyV("MIDDLE")
		text:ClearAllPoints()
		text:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 10, 0)
		text:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -10, 0)
	end	
end

-- Update the dispel table after talent changes
oUF_Hank.UpdateDispel = function()
	canDispel = {
		["DRUID"] = {["Poison"] = true, ["Curse"] = true, ["Magic"] = ({GetTalentInfo(3, 17, false, false, nil)})[5] == 1},
		["MAGE"] = {["Curse"] = true},
		["PALADIN"] = {["Poison"] = true, ["Disease"] = true, ["Magic"] = ({GetTalentInfo(1, 14, false, false, nil)})[5] == 1},
		["PRIEST"] = {["Disease"] = true, ["Magic"] = true},
		["SHAMAN"] = {["Curse"] = true, ["Magic"] = ({GetTalentInfo(3, 12, false, false, nil)})[5] == 1},
		["WARLOCK"] = {["Magic"] = true},
		["HUNTER"] = {},
		["ROGUE"] = {},
		["WARRIOR"] = {},
		["DEATHKNIGHT"] = {}
	}
end

-- This is where the magic happens. Handle health update, display digit textures
oUF_Hank.UpdateHealth = function(self)
	local h, hMax
	
	-- In vehicle
	if self.unit == "player" and UnitHasVehicleUI("player") then
		h, hMax = UnitHealth("pet"), UnitHealthMax("pet")
	else
		h, hMax = UnitHealth(self.unit), UnitHealthMax(self.unit)
	end

	local status = (not UnitIsConnected(self.unit) or nil) and "Off" or UnitIsGhost(self.unit) and "G" or UnitIsDead(self.unit) and "X"
	
	if not status then
		local hPerc = ("%d%%"):format(h / hMax * 100 + 0.5)
		local len = string.len(hPerc)
		
		if self.unit:find("boss") then
			self.health[1]:SetSize(oUF_Hank.digitTexCoords["B"][2], oUF_Hank.digitTexCoords["height"])
			self.health[1]:SetTexCoord(oUF_Hank.digitTexCoords["B"][1] / oUF_Hank.digitTexCoords["texWidth"], (oUF_Hank.digitTexCoords["B"][1] + oUF_Hank.digitTexCoords["B"][2]) / oUF_Hank.digitTexCoords["texWidth"], 1 / oUF_Hank.digitTexCoords["texHeight"], (1 + oUF_Hank.digitTexCoords["height"]) / oUF_Hank.digitTexCoords["texHeight"])
			self.health[1]:Show()
			self.healthFill[1]:SetSize(oUF_Hank.digitTexCoords["B"][2], oUF_Hank.digitTexCoords["height"] * h / hMax)
			self.healthFill[1]:SetTexCoord(
				oUF_Hank.digitTexCoords["B"][1] / oUF_Hank.digitTexCoords["texWidth"],
				(oUF_Hank.digitTexCoords["B"][1] + oUF_Hank.digitTexCoords["B"][2]) / oUF_Hank.digitTexCoords["texWidth"],
				(2 + 2 * oUF_Hank.digitTexCoords["height"] - oUF_Hank.digitTexCoords["height"] * h / hMax) / oUF_Hank.digitTexCoords["texHeight"],
				(2 + 2 * oUF_Hank.digitTexCoords["height"]) / oUF_Hank.digitTexCoords["texHeight"]
			)
			self.healthFill[1]:Show()
		else
			for i = 1, 4 do
				if i > len then
					self.health[5 - i]:Hide()
					self.healthFill[5 - i]:Hide()
				else
					local digit
					if self == oUF_player then
						digit = string.sub(hPerc , -i, -i)
					elseif self == oUF_target or self == oUF_focus then
						digit = string.sub(hPerc , i, i)
					end
					self.health[5 - i]:SetSize(oUF_Hank.digitTexCoords[digit][2], oUF_Hank.digitTexCoords["height"])
					self.health[5 - i]:SetTexCoord(oUF_Hank.digitTexCoords[digit][1] / oUF_Hank.digitTexCoords["texWidth"], (oUF_Hank.digitTexCoords[digit][1] + oUF_Hank.digitTexCoords[digit][2]) / oUF_Hank.digitTexCoords["texWidth"], 1 / oUF_Hank.digitTexCoords["texHeight"], (1 + oUF_Hank.digitTexCoords["height"]) / oUF_Hank.digitTexCoords["texHeight"])
					self.health[5 - i]:Show()
					self.healthFill[5 - i]:SetSize(oUF_Hank.digitTexCoords[digit][2], oUF_Hank.digitTexCoords["height"] * h / hMax)
					self.healthFill[5 - i]:SetTexCoord(oUF_Hank.digitTexCoords[digit][1] / oUF_Hank.digitTexCoords["texWidth"], (oUF_Hank.digitTexCoords[digit][1] + oUF_Hank.digitTexCoords[digit][2]) / oUF_Hank.digitTexCoords["texWidth"], (2 + 2 * oUF_Hank.digitTexCoords["height"] - oUF_Hank.digitTexCoords["height"] * h / hMax) / oUF_Hank.digitTexCoords["texHeight"], (2 + 2 * oUF_Hank.digitTexCoords["height"]) / oUF_Hank.digitTexCoords["texHeight"])
					self.healthFill[5 - i]:Show()
				end
			end
			
			if self == oUF_player then
				self.power:SetPoint("BOTTOMRIGHT", self.health[5 - len], "BOTTOMLEFT", -5, 0)
			elseif self == oUF_target or self == oUF_focus then
				self.power:SetPoint("BOTTOMLEFT", self.health[5 - len], "BOTTOMRIGHT", 5, 0)
			end
		end
	else
		if self.unit:find("boss") then
			self.healthFill[1]:Hide()
			self.health[1]:SetSize(oUF_Hank.digitTexCoords[status][2], oUF_Hank.digitTexCoords["height"])
			self.health[1]:SetTexCoord(oUF_Hank.digitTexCoords[status][1] / oUF_Hank.digitTexCoords["texWidth"], (oUF_Hank.digitTexCoords[status][1] + oUF_Hank.digitTexCoords[status][2]) / oUF_Hank.digitTexCoords["texWidth"], 1 / oUF_Hank.digitTexCoords["texHeight"], (1 + oUF_Hank.digitTexCoords["height"]) / oUF_Hank.digitTexCoords["texHeight"])
			self.health[1]:Show()
		else
			for i = 1, 4 do
				self.healthFill[i]:Hide()
				self.health[i]:Hide()
			end
			
			self.health[4]:SetSize(oUF_Hank.digitTexCoords[status][2], oUF_Hank.digitTexCoords["height"])
			self.health[4]:SetTexCoord(oUF_Hank.digitTexCoords[status][1] / oUF_Hank.digitTexCoords["texWidth"], (oUF_Hank.digitTexCoords[status][1] + oUF_Hank.digitTexCoords[status][2]) / oUF_Hank.digitTexCoords["texWidth"], 1 / oUF_Hank.digitTexCoords["texHeight"], (1 + oUF_Hank.digitTexCoords["height"]) / oUF_Hank.digitTexCoords["texHeight"])
			self.health[4]:Show()
	
			if self == oUF_player then
				self.power:SetPoint("BOTTOMRIGHT", self.health[4], "BOTTOMLEFT", -5, 0)
			elseif self == oUF_target or self == oUF_focus then
				self.power:SetPoint("BOTTOMLEFT", self.health[4], "BOTTOMRIGHT", 5, 0)
			end
		end
	end
end

-- Manual status icons update
oUF_Hank.UpdateStatus = function(self)
	-- Attach the first icon to the right border of self.power
	local lastElement = {"BOTTOMRIGHT", self.power, "TOPRIGHT"}

	-- Status icon texture names and conditions
	local icons = {
		["C"] = {"Combat", UnitAffectingCombat("player")},
		["R"] = {"Resting", IsResting()},
		["L"] = {"Leader", UnitIsGroupLeader("player")},
		["M"] = {"MasterLooter", ({GetLootMethod()})[1] == "master" and (
				(({GetLootMethod()})[2]) == 0 or
				((({GetLootMethod()})[2]) and UnitIsUnit("player", "party" .. ({GetLootMethod()})[2])) or
				((({GetLootMethod()})[3]) and UnitIsUnit("player", "raid" .. ({GetLootMethod()})[3]))
			)},
		["P"] = {"PvP", UnitIsPVPFreeForAll("player") or UnitIsPVP("player")},
		["A"] = {"Assistant", UnitInRaid("player") and UnitIsGroupAssistant("player") and not UnitIsGroupLeader("player")},
	}
	
	for i = -1, -string.len(cfg.StatusIcons), -1 do
		if icons[string.sub(cfg.StatusIcons, i, i)][2] then
			self[icons[string.sub(cfg.StatusIcons, i, i)][1]]:ClearAllPoints()
			self[icons[string.sub(cfg.StatusIcons, i, i)][1]]:SetPoint(unpack(lastElement))
			self[icons[string.sub(cfg.StatusIcons, i, i)][1]]:Show()
			-- Arrange any successive icon to the last one
			lastElement = {"RIGHT", self[icons[string.sub(cfg.StatusIcons, i, i)][1]], "LEFT"}
		else
			-- Condition for displaying the icon not met
			self[icons[string.sub(cfg.StatusIcons, i, i)][1]]:Hide()
		end
	end
end

-- Reanchoring / -sizing on name update
oUF_Hank.PostUpdateName = function(self)
	if (self.name) then
		-- Reanchor raid icon to the largest string (either name or power)
		if self.name:GetWidth() >= self.power:GetWidth() then
			self.RaidIcon:SetPoint("LEFT", self.name, "RIGHT", 10, 0)
		else
			self.RaidIcon:SetPoint("LEFT", self.power, "RIGHT", 10, 0)
		end
	end
end

-- Sticky aura colors
oUF_Hank.PostUpdateIcon = function(icons, unit, icon, index, offset)
	-- We want the border, not the color for the type indication
	icon.overlay:SetVertexColor(1, 1, 1)

	local _, _, _, _, dtype, _, _, caster, _, _, _ = UnitAura(unit, index, icon.filter)
	if caster == "vehicle" then caster = "player" end
	
	if icon.filter == "HELPFUL" and not UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. string.upper(unit)].StickyAuras.myBuffs then
		-- Sticky aura: myBuffs
		icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
		icon.icon:SetDesaturated(false)
	elseif icon.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. string.upper(unit)].StickyAuras.myDebuffs then
		-- Sticky aura: myDebuffs
		icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
		icon.icon:SetDesaturated(false)
	elseif icon.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "pet" and cfg["Auras" .. string.upper(unit)].StickyAuras.petDebuffs then
		-- Sticky aura: petDebuffs
		icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
		icon.icon:SetDesaturated(false)
	elseif icon.filter == "HARMFUL" and not UnitCanAttack("player", unit) and canDispel[({UnitClass("player")})[2]][dtype] and cfg["Auras" .. string.upper(unit)].StickyAuras.curableDebuffs then
		-- Sticky aura: curableDebuffs
		icon.icon:SetVertexColor(DebuffTypeColor[dtype].r, DebuffTypeColor[dtype].g, DebuffTypeColor[dtype].b)
		icon.icon:SetDesaturated(false)
	elseif icon.filter == "HELPFUL" and UnitCanAttack("player", unit) and UnitIsUnit(unit, caster or "") and cfg["Auras" .. string.upper(unit)].StickyAuras.enemySelfBuffs then
		-- Sticky aura: enemySelfBuffs
		icon.icon:SetVertexColor(unpack(cfg.AuraStickyColor))
		icon.icon:SetDesaturated(false)
	else
		icon.icon:SetVertexColor(1, 1, 1)
		icon.icon:SetDesaturated(true)
	end
end

-- Custom filters
oUF_Hank.customFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
	if caster == "vehicle" then caster = "player" end
	if icons.filter == "HELPFUL" and not UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. string.upper(unit)].StickyAuras.myBuffs then
		-- Sticky aura: myBuffs
		return true
	elseif icons.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "player" and cfg["Auras" .. string.upper(unit)].StickyAuras.myDebuffs then
		-- Sticky aura: myDebuffs
		return true
	elseif icons.filter == "HARMFUL" and UnitCanAttack("player", unit) and caster == "pet" and cfg["Auras" .. string.upper(unit)].StickyAuras.petDebuffs then
		-- Sticky aura: petDebuffs
		return true
	elseif icons.filter == "HARMFUL" and not UnitCanAttack("player", unit) and canDispel[({UnitClass("player")})[2]][dtype] and cfg["Auras" .. string.upper(unit)].StickyAuras.curableDebuffs then
		-- Sticky aura: curableDebuffs
		return true
	-- Usage of UnitIsUnit: Call from within focus frame will return "target" as caster if focus is targeted (player > target > focus)
	elseif icons.filter == "HELPFUL" and UnitCanAttack("player", unit) and UnitIsUnit(unit, caster or "") and cfg["Auras" .. string.upper(unit)].StickyAuras.enemySelfBuffs then
		-- Sticky aura: enemySelfBuffs
		return true
	else
		-- Aura is not sticky, filter is set to blacklist
		if cfg["Auras" .. string.upper(unit)].FilterMethod[icons.filter == "HELPFUL" and "Buffs" or "Debuffs"] == "BLACKLIST" then
			for _, v in ipairs(cfg["Auras" .. string.upper(unit)].BlackList) do
				if v == name then
					return false
				end
			end
			return true
		-- Aura is not sticky, filter is set to whitelist
		elseif cfg["Auras" .. string.upper(unit)].FilterMethod[icons.filter == "HELPFUL" and "Buffs" or "Debuffs"] == "WHITELIST" then
			for _, v in ipairs(cfg["Auras" .. string.upper(unit)].WhiteList) do
				if v == name then
					return true
				end
			end
			return false
		-- Aura is not sticky, filter is set to none
		else
			return true
		end
	end
end

-- Aura mouseover
oUF_Hank.OnEnterAura = function(self, icon)
	-- Aura magnification
	if isDebuff then
		self.HighlightAura:SetSize(cfg.DebuffSize * cfg.AuraMagnification, cfg.DebuffSize * cfg.AuraMagnification)
		self.HighlightAura.icon:SetSize(cfg.DebuffSize * cfg.AuraMagnification, cfg.DebuffSize * cfg.AuraMagnification)
		self.HighlightAura.border:SetSize(cfg.DebuffSize * cfg.AuraMagnification * 1.1, cfg.DebuffSize * cfg.AuraMagnification * 1.1)
		self.HighlightAura:SetPoint("TOPLEFT", icon, "TOPLEFT", -(cfg.DebuffSize * cfg.AuraMagnification - cfg.DebuffSize) / 2, (cfg.DebuffSize * cfg.AuraMagnification - cfg.DebuffSize) / 2)
	else
		self.HighlightAura:SetSize(cfg.BuffSize * cfg.AuraMagnification, cfg.BuffSize * cfg.AuraMagnification)
		self.HighlightAura.icon:SetSize(cfg.BuffSize * cfg.AuraMagnification, cfg.BuffSize * cfg.AuraMagnification)
		self.HighlightAura.border:SetSize(cfg.BuffSize * cfg.AuraMagnification * 1.1, cfg.BuffSize * cfg.AuraMagnification * 1.1)
		self.HighlightAura:SetPoint("TOPLEFT", icon, "TOPLEFT", -(cfg.BuffSize * cfg.AuraMagnification - cfg.BuffSize) / 2, (cfg.BuffSize * cfg.AuraMagnification - cfg.BuffSize) / 2)
	end
	self.HighlightAura.icon:SetTexture(icon.icon:GetTexture())
	self.HighlightAura:Show()
end

-- Aura mouseout
oUF_Hank.OnLeaveAura = function(self)
	self.HighlightAura:Hide()
end

-- Hook aura scripts, set aura border
oUF_Hank.PostCreateIcon = function(icons, icon)
	if cfg.AuraBorder then
		-- Custom aura border
		icon.overlay:SetTexture(cfg.AuraBorder)
		icon.overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
		icon.overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
		icon.overlay:SetTexCoord(0, 1, 0, 1)
		icons.showType = true
	end
	icon.cd:SetReverse(true)
	icon:HookScript("OnEnter", function() oUF_Hank.OnEnterAura(icons:GetParent(), icon) end)
	icon:HookScript("OnLeave", function() oUF_Hank.OnLeaveAura(icons:GetParent()) end)
	-- Cancel player buffs on right click
	icon:HookScript("OnClick", function(_, button, down)
		if button == "RightButton" and down == false then
			if icon.filter == "HELPFUL" and UnitIsUnit("player", icons:GetParent().unit) then
				CancelUnitBuff("player", icon:GetID())
				oUF_Hank.OnLeaveAura(icons:GetParent())
			end
		end
	end)
end

-- Debuff anchoring
oUF_Hank.PreSetPosition = function(buffs, max)
	if buffs.visibleBuffs > 0 then
		-- Anchor debuff frame to bottomost buff icon, i.e the last buff row
		buffs:GetParent().Debuffs:SetPoint("TOP", buffs[buffs.visibleBuffs], "BOTTOM", 0, -cfg.AuraSpacing -2)
	else
		-- No buffs
		if buffs:GetParent().CPoints then
			buffs:GetParent().Debuffs:SetPoint("TOP", buffs:GetParent().CPoints[1], "BOTTOM", 0, -10)
		else
			buffs:GetParent().Debuffs:SetPoint("TOP", buffs:GetParent(), "BOTTOM", 0, -10)
		end
	end
end

-- Castbar
oUF_Hank.PostCastStart = function(castbar, unit, name, rank, castid)
	castbar.castIsChanneled = false
	if unit == "vehicle" then unit = "player" end

	-- Latency display
	if unit == "player" then
		-- Time between cast transmission and cast start event
		local latency = GetTime() - (castbar.castSent or 0)
		latency = latency > castbar.max and castbar.max or latency
		castbar.Latency:SetText(("%dms"):format(latency * 1e3))
		castbar.PreciseSafeZone:SetWidth(castbar:GetWidth() * latency / castbar.max)
		castbar.PreciseSafeZone:ClearAllPoints()
		castbar.PreciseSafeZone:SetPoint("TOPRIGHT")
		castbar.PreciseSafeZone:SetPoint("BOTTOMRIGHT")
		castbar.PreciseSafeZone:SetDrawLayer("BACKGROUND")
	end
	
	if unit ~= "focus" then
		-- Cast layout
		castbar.Text:SetJustifyH("LEFT")
		castbar.Time:SetJustifyH("LEFT")
		if cfg.CastbarIcon then castbar.Dummy.Icon:SetTexture(castbar.Icon:GetTexture()) end
	end
	
	-- Uninterruptible spells
	if castbar.Shield:IsShown() and UnitCanAttack("player", unit) then
		castbar.Background:SetBackdropBorderColor(unpack(cfg.colors.castbar.noInterrupt))
	else
		castbar.Background:SetBackdropBorderColor(0, 0, 0)
	end
end

oUF_Hank.PostChannelStart = function(castbar, unit, name, rank)
	castbar.castIsChanneled = true
	if unit == "vehicle" then unit = "player" end

	if unit == "player" then
		local latency = GetTime() - (castbar.castSent or 0) -- Something happened with UNIT_SPELLCAST_SENT for vehicles
		latency = latency > castbar.max and castbar.max or latency
		castbar.Latency:SetText(("%dms"):format(latency * 1e3))
		castbar.PreciseSafeZone:SetWidth(castbar:GetWidth() * latency / castbar.max)
		castbar.PreciseSafeZone:ClearAllPoints()
		castbar.PreciseSafeZone:SetPoint("TOPLEFT")
		castbar.PreciseSafeZone:SetPoint("BOTTOMLEFT")
		castbar.PreciseSafeZone:SetDrawLayer("OVERLAY")
	end

	if unit ~= "focus" then
		-- Channel layout
		castbar.Text:SetJustifyH("RIGHT")
		castbar.Time:SetJustifyH("RIGHT")
		if cfg.CastbarIcon then castbar.Dummy.Icon:SetTexture(castbar.Icon:GetTexture()) end
	end
	
	if castbar.Shield:IsShown() and UnitCanAttack("player", unit) then
		castbar.Background:SetBackdropBorderColor(unpack(cfg.colors.castbar.noInterrupt))
	else
		castbar.Background:SetBackdropBorderColor(0, 0, 0)
	end
end

-- Castbar animations
oUF_Hank.PostCastSucceeded = function(castbar, spell)
	-- No animation on instant casts (castbar text not set)
	if castbar.Text:GetText() == spell then
		castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castSuccess))
		castbar.Dummy:Show()
		castbar.Dummy.anim:Play()
	end
end

oUF_Hank.PostCastStop = function(castbar, unit, spellname, spellrank, castid)
	if not castbar.Dummy.anim:IsPlaying() then
		castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castFail))
		castbar.Dummy:Show()
		castbar.Dummy.anim:Play()
	end
end

oUF_Hank.PostChannelStop = function(castbar, unit, spellname, spellrank)
	if not spellname then
		castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castSuccess))
		castbar.Dummy:Show()
		castbar.Dummy.anim:Play()
	else
		castbar.Dummy.Fill:SetVertexColor(unpack(cfg.colors.castbar.castFail))
		castbar.Dummy:Show()
		castbar.Dummy.anim:Play()
	end
end

oUF_Hank.PostSpawnFrames = function(this)
	-- custom_modifications function
	oUF_Hank.UpdateDispel()
end

-- Frame constructor -----------------------------

oUF_Hank.sharedStyle = function(self, unit, isSingle)
	self.menu = oUF_Hank.menu
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyDown")
	self:SetAttribute("*type2", "menu")
	
	self.colors = cfg.colors
	
	-- Update dispel table on talent update
	if unit == "player" then self:RegisterEvent("PLAYER_TALENT_UPDATE", oUF_Hank.UpdateDispel) end
	
	-- HP%
	local health = {}
	local healthFill = {}
	
	if unit == "player" or unit == "target" or unit == "focus" or unit:find("boss") then
		
		self:RegisterEvent("UNIT_HEALTH", function(_, _, ...)
			if unit == ... then
				oUF_Hank.UpdateHealth(self)
			elseif unit == "player" and UnitHasVehicleUI("player") and ... == "pet" then
				oUF_Hank.UpdateHealth(self)
			end
		end)
		
		self:RegisterEvent("UNIT_MAXHEALTH", function(_, _, ...)
			if unit == ... then
				oUF_Hank.UpdateHealth(self)
			elseif unit == "player" and UnitHasVehicleUI("player") and ... == "pet" then
				oUF_Hank.UpdateHealth(self)
			end
		end)
		
		-- Health update on unit switch
		-- Thanks @ pelim for this approach
		table.insert(self.__elements, oUF_Hank.UpdateHealth)

		for i = unit:find("boss") and 1 or 4, 1, -1 do
			health[i] = self:CreateTexture(nil, "ARTWORK")
			health[i]:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\digits.blp")
			health[i]:Hide()
			healthFill[i] = self:CreateTexture(nil, "OVERLAY")
			healthFill[i]:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\digits.blp")
			healthFill[i]:SetVertexColor(unpack(cfg.colors.text))
			healthFill[i]:Hide()
		end
		
		if unit == "player" then
			health[4]:SetPoint("RIGHT")
			health[3]:SetPoint("RIGHT", health[4], "LEFT")
			health[2]:SetPoint("RIGHT", health[3], "LEFT")
			health[1]:SetPoint("RIGHT", health[2], "LEFT")
		elseif unit == "target" or unit == "focus" then
			health[4]:SetPoint("LEFT")
			health[3]:SetPoint("LEFT", health[4], "RIGHT")
			health[2]:SetPoint("LEFT", health[3], "RIGHT")
			health[1]:SetPoint("LEFT", health[2], "RIGHT")
		elseif unit:find("boss") then
			health[1]:SetPoint("RIGHT")
		end
		
		if not unit:find("boss") then
			healthFill[4]:SetPoint("BOTTOM", health[4])
			healthFill[3]:SetPoint("BOTTOM", health[3])
			healthFill[2]:SetPoint("BOTTOM", health[2])
		end
		healthFill[1]:SetPoint("BOTTOM", health[1])

		self.health = health
		self.healthFill = healthFill
		
		-- Reanchoring handled in UpdateHealth()
	end

	local name, power
	
	-- Power, threat
	if unit == "player" or unit == "target" or unit == "focus" or unit:find("boss") then
		power = self:CreateFontString(nil, "OVERLAY")
		power:SetFontObject("UFFontMedium")
		
		if unit == "player" then power:SetPoint("BOTTOMRIGHT", health[4], "BOTTOMLEFT", -5, 0)
		elseif unit == "target" or unit == "focus" then power:SetPoint("BOTTOMLEFT", health[4], "BOTTOMRIGHT", 5, 0)
		elseif unit:find("boss") then power:SetPoint("BOTTOMRIGHT", health[1], "BOTTOMLEFT", -5, 0) end
		
		if unit == "player" then self:Tag(power, "[ppDetailed]")
		elseif unit == "target" or unit == "focus" then self:Tag(power, cfg.ShowThreat and "[hpDetailed] || [ppDetailed] [threatPerc]" or "[hpDetailed] || [ppDetailed]")
		elseif unit:find("boss") then self:Tag(power, cfg.ShowThreat and "[threatBoss] || [perhp]%" or "[perhp]%") end

		self.power = power
	end
		
	-- Name
	if unit == "target" or unit == "focus" then 
		name = self:CreateFontString(nil, "OVERLAY")
		name:SetFontObject("UFFontBig")
		name:SetPoint("BOTTOMLEFT", power, "TOPLEFT")
		self:Tag(name, "[statusName]")
	elseif unit:find("boss") then
		name = self:CreateFontString(nil, "OVERLAY")
		name:SetFontObject("UFFontBig")
		name:SetPoint("BOTTOMRIGHT", power, "TOPRIGHT")
		self:Tag(name, "[statusName]")
	elseif unit == "pet" then
		name = self:CreateFontString(nil, "OVERLAY")
		name:SetFontObject("UFFontSmall")
		name:SetPoint("RIGHT")
		self:Tag(name, "[petName] @[perhp]%")
	elseif unit == "targettarget" or  unit == "targettargettarget" or unit == "focustarget" then
		name = self:CreateFontString(nil, "OVERLAY")
		name:SetFontObject("UFFontSmall")
		name:SetPoint("LEFT")
		if unit == "targettarget" or unit == "focustarget" then self:Tag(name, "\226\128\186  [smartName] @[perhp]%")
		elseif unit == "targettargettarget" then self:Tag(name, "\194\187 [smartName] @[perhp]%") end
	end
	
	self.name = name
	
	-- Status icons
	if unit == "player" then
		-- Remove invalid or duplicate placeholders
		local fixedString = ""

		for placeholder in string.gmatch(cfg.StatusIcons, "[CRPMAL]") do
			fixedString = fixedString .. (string.match(fixedString, placeholder) and "" or placeholder)
		end

		cfg.StatusIcons = fixedString
		
		-- Create the status icons
		for i, icon in ipairs({
			{"C", "Combat"},
			{"R", "Resting"},
			{"L", "Leader"},
			{"M", "MasterLooter"},
			{"P", "PvP"},
			{"A", "Assistant"},
		}) do
			if string.match(cfg.StatusIcons, icon[1]) then
				self[icon[2]] = self:CreateTexture(nil, "OVERLAY")
				self[icon[2]]:SetSize(24, 24)
				self[icon[2]]:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\statusicons.blp")
				self[icon[2]]:SetTexCoord((i - 1) * 24 / 256, i * 24 / 256, 0, 24 / 32)
				self[icon[2]].Override = oUF_Hank.UpdateStatus
			end
			
		end
		
		-- Anchoring handled in UpdateStatus()
	end

	-- Raid targets
	if unit == "player" then
		self.RaidIcon = self:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetSize(40, 40)
		self.RaidIcon:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\raidicons.blp")
		self.RaidIcon:SetPoint("RIGHT", self.power, "LEFT", -15, 0)
		self.RaidIcon:SetPoint("TOP", self, "TOP", 0, -5)
	elseif unit == "target" or unit == "focus" then
		self.RaidIcon = self:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetSize(40, 40)
		self.RaidIcon:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\raidicons.blp")
		self.RaidIcon:SetPoint("LEFT", self.name, "RIGHT", 10, 0)
		self.RaidIcon:SetPoint("TOP", self, "TOP", 0, -5)
		
		-- Anchoring on name update
		table.insert(self.__elements, oUF_Hank.PostUpdateName)
		self:RegisterEvent("PLAYER_FLAGS_CHANGED", function(_, _, unit)
			if unit == self.unit then
				oUF_Hank.PostUpdateName(unit)
			end

		end)
	elseif unit:find("boss") then
		self.RaidIcon = self:CreateTexture(nil)
		self.RaidIcon:SetDrawLayer("OVERLAY", 1)
		self.RaidIcon:SetSize(24, 24)
		self.RaidIcon:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\raidicons.blp")
		self.RaidIcon:SetPoint("BOTTOMRIGHT", health[1], 5, -5)
	end

	-- XP, reputation
	if unit == "player" and cfg.ShowXP then
		xprep = self:CreateFontString(nil, "OVERLAY")
		xprep:SetFontObject("UFFontMedium")
		xprep:SetPoint("RIGHT", power, "RIGHT")
		xprep:SetAlpha(0)
		self:Tag(xprep, "[xpRep]")
		self.xprep = xprep
		
		-- Some animation dummies
		local xprepDummy = self:CreateFontString(nil, "OVERLAY")
		xprepDummy:SetFontObject("UFFontMedium")
		xprepDummy:SetAllPoints(xprep)
		xprepDummy:SetAlpha(0)
		xprepDummy:Hide()
		local powerDummy = self:CreateFontString(nil, "OVERLAY")
		powerDummy:SetFontObject("UFFontMedium")
		powerDummy:SetAllPoints(power)
		powerDummy:Hide()
		local raidIconDummy = self:CreateTexture(nil, "OVERLAY")
		raidIconDummy:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\raidicons.blp")
		raidIconDummy:SetAllPoints(self.RaidIcon)
		raidIconDummy:Hide()
		
		local animXPFadeIn = xprepDummy:CreateAnimationGroup()
		-- A short delay so the user needs to mouseover a short time for the xp/rep display to show up
		local delayXP = animXPFadeIn:CreateAnimation("Alpha")
		delayXP:SetChange(0)
		delayXP:SetDuration(cfg.DelayXP)
		delayXP:SetOrder(1)
		local alphaInXP = animXPFadeIn:CreateAnimation("Alpha")
		alphaInXP:SetChange(1)
		alphaInXP:SetSmoothing("OUT")
		alphaInXP:SetDuration(1.5)
		alphaInXP:SetOrder(2)
		
		local animPowerFadeOut = powerDummy:CreateAnimationGroup()
		local delayPower = animPowerFadeOut:CreateAnimation("Alpha")
		delayPower:SetChange(0)
		delayPower:SetDuration(cfg.DelayXP)
		delayPower:SetOrder(1)
		local alphaOutPower = animPowerFadeOut:CreateAnimation("Alpha")
		alphaOutPower:SetChange(-1)
		alphaOutPower:SetSmoothing("OUT")
		alphaOutPower:SetDuration(1.5)
		alphaOutPower:SetOrder(2)
		
		local animRaidIconFadeOut = raidIconDummy:CreateAnimationGroup()
		local delayIcon = animRaidIconFadeOut:CreateAnimation("Alpha")
		delayIcon:SetChange(0)
		delayIcon:SetDuration(cfg.DelayXP * .75)
		delayIcon:SetOrder(1)
		local alphaOutIcon = animRaidIconFadeOut:CreateAnimation("Alpha")
		alphaOutIcon:SetChange(-1)
		alphaOutIcon:SetSmoothing("OUT")
		alphaOutIcon:SetDuration(0.5)
		alphaOutIcon:SetOrder(2)
		
		animXPFadeIn:SetScript("OnFinished", function()
			xprep:SetAlpha(1)
			xprepDummy:Hide()
		end)
		animPowerFadeOut:SetScript("OnFinished", function() powerDummy:Hide() end)
		animRaidIconFadeOut:SetScript("OnFinished", function() raidIconDummy:Hide() end)
		
		self:HookScript("OnEnter", function(_, motion)
			if motion then
				self.power:SetAlpha(0)
				self.RaidIcon:SetAlpha(0)
				powerDummy:SetText(self.power:GetText())
				powerDummy:Show()
				xprepDummy:SetText(self.xprep:GetText())
				xprepDummy:Show()
				raidIconDummy:SetTexCoord(self.RaidIcon:GetTexCoord())
				if self.RaidIcon:IsShown() then raidIconDummy:Show() end
				animXPFadeIn:Play()
				animPowerFadeOut:Play()
				if self.RaidIcon:IsShown() then animRaidIconFadeOut:Play() end
			end
		end)
		
		self:HookScript("OnLeave", function()
			if animXPFadeIn:IsPlaying() then animXPFadeIn:Stop() end
			if animPowerFadeOut:IsPlaying() then animPowerFadeOut:Stop() end
			if animRaidIconFadeOut:IsPlaying() then animRaidIconFadeOut:Stop() end
			powerDummy:Hide()
			xprepDummy:Hide()
			raidIconDummy:Hide()
			self.xprep:SetAlpha(0)
			self.power:SetAlpha(1)
			self.RaidIcon:SetAlpha(1)
		end)
	end

	-- Combo points
	if unit == "target" and (select(2, UnitClass("player")) == "ROGUE" or select(2, UnitClass("player")) == "DRUID") then
		local bg = {}
		local fill = {}
		self.CPoints = {}
		for i = 1, MAX_COMBO_POINTS do
			self.CPoints[i] = CreateFrame("Frame", nil, self)
			self.CPoints[i]:SetSize(16, 16)
			if i > 1 then self.CPoints[i]:SetPoint("LEFT", self.CPoints[i - 1], "RIGHT") end
			bg[i] = self.CPoints[i]:CreateTexture(nil, "ARTWORK")
			bg[i]:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\combo.blp")
			bg[i]:SetTexCoord(0, 16 / 64, 0, 1)
			bg[i]:SetAllPoints(self.CPoints[i])
			fill[i] = self.CPoints[i]:CreateTexture(nil, "OVERLAY")
			fill[i]:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\combo.blp")
			fill[i]:SetTexCoord(0.5, 0.75, 0, 1)
			fill[i]:SetVertexColor(unpack(cfg.colors.power.ENERGY))
			fill[i]:SetAllPoints(self.CPoints[i])
		end
		self.CPoints[1]:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
		self.CPoints.unit = "player"
	end
	
	-- Auras
	if unit == "target" or unit == "focus" then
		-- Buffs
		self.Buffs = CreateFrame("Frame", unit .. "_Buffs", self) -- ButtonFace needs a name
		if self.CPoints then
			self.Buffs:SetPoint("TOPLEFT", self.CPoints[1], "BOTTOMLEFT", 0, -5)
		else
			self.Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -5)
		end
		self.Buffs:SetHeight(cfg.BuffSize)
		self.Buffs:SetWidth(225)
		self.Buffs.size = cfg.BuffSize
		self.Buffs.spacing = cfg.AuraSpacing
		self.Buffs.initialAnchor = "LEFT"
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs.num = cfg["Auras" .. string.upper(unit)].MaxBuffs
		self.Buffs.filter = "HELPFUL" -- Explicitly set the filter or the first customFilter call won't work

		-- Debuffs
		self.Debuffs = CreateFrame("Frame", unit .. "_Debuffs", self)
		self.Debuffs:SetPoint("LEFT", self, "LEFT", 0, 0)
		self.Debuffs:SetPoint("TOP", self, "TOP", 0, 0) -- We will reanchor this in PreAuraSetPosition
		self.Debuffs:SetHeight(cfg.DebuffSize)
		self.Debuffs:SetWidth(225)
		self.Debuffs.size = cfg.DebuffSize
		self.Debuffs.spacing = cfg.AuraSpacing
		self.Debuffs.initialAnchor = "LEFT"
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs.num = cfg["Auras" .. string.upper(unit)].MaxDebuffs
		self.Debuffs.filter = "HARMFUL"
		
		-- Buff magnification effect on mouseover
		self.HighlightAura = CreateFrame("Frame", nil, self)
		self.HighlightAura:SetFrameLevel(5) -- Above auras (level 3) and their cooldown overlay (4)
		self.HighlightAura:SetBackdrop({bgFile = cfg.AuraBorder})
		self.HighlightAura:SetBackdropColor(0, 0, 0, 1)
		self.HighlightAura.icon = self.HighlightAura:CreateTexture(nil, "ARTWORK")
		self.HighlightAura.icon:SetPoint("CENTER")
		self.HighlightAura.border = self.HighlightAura:CreateTexture(nil, "OVERLAY")
		self.HighlightAura.border:SetTexture(cfg.AuraBorder)
		self.HighlightAura.border:SetPoint("CENTER")
		
		self.Buffs.PostUpdateIcon = oUF_Hank.PostUpdateIcon
		self.Debuffs.PostUpdateIcon = oUF_Hank.PostUpdateIcon
		self.Buffs.PostCreateIcon = oUF_Hank.PostCreateIcon
		self.Debuffs.PostCreateIcon = oUF_Hank.PostCreateIcon
		self.Buffs.PreSetPosition = oUF_Hank.PreSetPosition
		self.Buffs.CustomFilter = oUF_Hank.customFilter
		self.Debuffs.CustomFilter = oUF_Hank.customFilter
	end
	
	-- Runes
	if unit == "player" and select(2, UnitClass("player")) == "DEATHKNIGHT" then
		local runemap = { 1, 2, 5, 6, 3, 4 }
		self.Runes = CreateFrame("Frame", nil, self)
		self.Runes:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
		self.Runes:SetSize(96, 16)
		self.Runes.anchor = "TOPLEFT"
		self.Runes.growth = "RIGHT"
		self.Runes.height = 16
		self.Runes.width = 16
			
		for i = 1, 6 do
			self.Runes[i] = CreateFrame("StatusBar", nil, self.Runes)
			self.Runes[i]:SetStatusBarTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\blank.blp")
			self.Runes[i]:SetSize(16, 16)

			if i == 1 then
				self.Runes[i]:SetPoint("TOPLEFT", self.Runes, "TOPLEFT")
			else
				self.Runes[i]:SetPoint("LEFT", self.Runes[i - 1], "RIGHT")
			end

			local backdrop = self.Runes[i]:CreateTexture(nil, "ARTWORK")
			backdrop:SetSize(16, 16)
			backdrop:SetAllPoints()
			backdrop:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\combo.blp")
			backdrop:SetTexCoord(0, 16 / 64, 0, 1)
				
			-- This is actually the fill layer, but "bg" gets automatically vertex-colored by the runebar module. So let's make use of that!
			self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "OVERLAY")
			self.Runes[i].bg:SetSize(16, 16)
			self.Runes[i].bg:SetPoint("BOTTOM")
			self.Runes[i].bg:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\combo.blp")
			self.Runes[i].bg:SetTexCoord(0.5, 0.75, 0, 1)
				
			-- Shine effect
			local shinywheee = CreateFrame("Frame", nil, self.Runes[i])
			shinywheee:SetAllPoints()
			shinywheee:SetAlpha(0)
			shinywheee:Hide()
				
			local shine = shinywheee:CreateTexture(nil, "OVERLAY")
			shine:SetAllPoints()
			shine:SetPoint("CENTER")
			shine:SetTexture("Interface\\Cooldown\\star4.blp")
			shine:SetBlendMode("ADD")

			local anim = shinywheee:CreateAnimationGroup()
			local alphaIn = anim:CreateAnimation("Alpha")
			alphaIn:SetChange(0.3)
			alphaIn:SetDuration(0.4)
			alphaIn:SetOrder(1)
			local rotateIn = anim:CreateAnimation("Rotation")
			rotateIn:SetDegrees(-90)
			rotateIn:SetDuration(0.4)
			rotateIn:SetOrder(1)
			local scaleIn = anim:CreateAnimation("Scale")
			scaleIn:SetScale(2, 2)
			scaleIn:SetOrigin("CENTER", 0, 0)
			scaleIn:SetDuration(0.4)
			scaleIn:SetOrder(1)
			local alphaOut = anim:CreateAnimation("Alpha")
			alphaOut:SetChange(-0.5)
			alphaOut:SetDuration(0.4)
			alphaOut:SetOrder(2)
			local rotateOut = anim:CreateAnimation("Rotation")
			rotateOut:SetDegrees(-90)
			rotateOut:SetDuration(0.3)
			rotateOut:SetOrder(2)
			local scaleOut = anim:CreateAnimation("Scale")
			scaleOut:SetScale(-2, -2)
			scaleOut:SetOrigin("CENTER", 0, 0)
			scaleOut:SetDuration(0.4)
			scaleOut:SetOrder(2)
				
			anim:SetScript("OnFinished", function() shinywheee:Hide() end)
			shinywheee:SetScript("OnShow", function() anim:Play() end)

			self.Runes[i]:SetScript("OnValueChanged", function(self, val)
				local start, duration, runeReady = GetRuneCooldown(runemap[i])
				if runeReady then
					self.last = 0
					-- Rune ready: show all 16x16px, play animation
					self.bg:SetSize(16, 16)
					self.bg:SetTexCoord(0.5, 0.75, 0, 1)
					shinywheee:Show()
				else
					-- Dot distance from top & bottom of texture: 4px
					self.bg:SetSize(16, 4 + 8 * val / 10)
					-- Show at least the empty 4 bottom pixels + val% of the 8 pixels of the actual dot = 12px max
					self.bg:SetTexCoord(0.25, 0.5, 12 / 16 - 8 * val / 10 / 16, 1)
				end
			end)
		end

		self.Runes.PostUpdateRune = function(self, rune, rid, start, duration, runeReady)
			if not runeReady then
				local val = GetTime() - start
				-- Dot distance from top & bottom of texture: 4px
				rune.bg:SetSize(16, 4 + 8 * val / 10)
				-- Show at least the empty 4 bottom pixels + val% of the 8 pixels of the actual dot = 12px max
				rune.bg:SetTexCoord(0.25, 0.5, 12 / 16 - 8 * val / 10 / 16, 1)
			end
		end
	end
	
	-- Holy power
	if unit == "player" and select(2, UnitClass("player")) == "PALADIN" then
		local bg = {}
		local HPowerAnim = {}
		self.ClassIcons = {}
		-- Helper var for animation handling
		self.ClassIcons.lastHPow = UnitPower("player", SPELL_POWER_HOLY_POWER)
		
		for i = 1, 5 do
			bg[i] = CreateFrame("Frame", nil, self)
			bg[i]:SetSize(18, 18)
			
			if i > 1 then bg[i]:SetPoint("RIGHT", bg[i - 1], "LEFT", -5, 0) end
			
			bg[i].tex = bg[i]:CreateTexture(nil, "ARTWORK")
			bg[i].tex:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\HolyPower.blp")
			bg[i].tex:SetTexCoord(0, 18 / 64, 0, 18 / 32)
			bg[i].tex:SetAllPoints(bg[i])
			self.ClassIcons[i] = bg[i]:CreateTexture(nil, "OVERLAY")
			self.ClassIcons[i]:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\HolyPower.blp")
			self.ClassIcons[i]:SetTexCoord(18 / 64, 36 / 64, 0, 18 / 32)
			self.ClassIcons[i]:SetAllPoints(bg[i])
			self.ClassIcons[i]:SetVertexColor(unpack(cfg.colors.power.HOLY_POWER))

			-- need access to the background in the PostUpdate function
			self.ClassIcons[i].bg = bg[i].tex
			
			HPowerAnim[i] = self.ClassIcons[i]:CreateAnimationGroup()
			local alphaIn = HPowerAnim[i]:CreateAnimation("Alpha")
			alphaIn:SetChange(1)
			alphaIn:SetSmoothing("OUT")
			alphaIn:SetDuration(1)
			alphaIn:SetOrder(1)
			
			HPowerAnim[i]:SetScript("OnFinished", function() self.ClassIcons[i]:SetAlpha(1) end)
		end
		
		bg[1]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
		
		self.ClassIcons.PostUpdate = function(_, currentPower, maxPower, changed)
			-- update how many holy power icons are shown
			if maxPower == 3 then
				self.ClassIcons[4]:Hide()
				self.ClassIcons[4].bg:Hide()
				self.ClassIcons[5]:Hide()
				self.ClassIcons[5].bg:Hide()
			else
				self.ClassIcons[4].bg:Show()
				self.ClassIcons[5].bg:Show()
			end

			-- if lastHPow is nil, set it to 0
			self.ClassIcons.lastHPow = self.ClassIcons.lastHPow and self.ClassIcons.lastHPow or 0
			if currentPower > 0 then
				if self.ClassIcons.lastHPow < currentPower then
					-- Play animation only when we gain power
					self.ClassIcons[currentPower]:SetAlpha(0)
					HPowerAnim[currentPower]:Play();
				end
			else
				for i = 1, maxPower do
					-- no holy power, stop all running animations
					self.ClassIcons.lastHPow = currentPower
					if HPowerAnim[i]:IsPlaying() then HPowerAnim[i]:Stop() end
				end
			end
			self.ClassIcons.lastHPow = currentPower
		end
	end

	-- Harmony Orbs
	if unit == "player" and select(2, UnitClass("player")) == "MONK" then
		local bg = {}
		self.ClassIcons = {}

		for i = 1, 5 do
			bg[i] = CreateFrame("Frame", nil, self)
			bg[i]:SetSize(20, 20)
			
			if i > 1 then bg[i]:SetPoint("LEFT", bg[i - 1], "RIGHT", 0, 0) end
			
			bg[i].tex = bg[i]:CreateTexture(nil, "ARTWORK")
			bg[i].tex:SetTexture[[Interface\PlayerFrame\MonkNoPower]]
			bg[i].tex:SetTexCoord(0, 1, 0, 1)
			bg[i].tex:SetAllPoints(bg[i])
			self.ClassIcons[i] = bg[i]:CreateTexture(nil, "OVERLAY")
			self.ClassIcons[i]:SetTexture[[Interface\PlayerFrame\MonkLightPower]]
			self.ClassIcons[i]:SetTexCoord(0, 1, 0, 1)
			self.ClassIcons[i]:SetAllPoints(bg[i])

			-- need access to the background in the PostUpdate function
			self.ClassIcons[i].bg = bg[i].tex
		end
		
		bg[1]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -78, 0)

		self.ClassIcons.PostUpdate = function(_, currentChi, maxChi)
			if maxChi == 4 then
				self.ClassIcons[5]:Hide()
				self.ClassIcons[5].bg:Hide()
			else
				self.ClassIcons[5].bg:Show()
			end
		end
	end

	-- Shadow Orbs
	if unit == "player" and select(2, UnitClass("player")) == "PRIEST" then
		local bg = {}
		self.ClassIcons = {}

		for i = 1, 3 do
			bg[i] = CreateFrame("Frame", nil, self)
			bg[i]:SetSize(28, 28)
			
			if i > 1 then bg[i]:SetPoint("LEFT", bg[i - 1], "RIGHT", 2, 0) end
			
			bg[i].tex = bg[i]:CreateTexture(nil, "ARTWORK")
			bg[i].tex:SetTexture[[Interface\PlayerFrame\Priest-ShadowUI]]
			bg[i].tex:SetTexCoord(76/256, 112/256, 57/128, 94/128)
			bg[i].tex:SetAllPoints(bg[i])
			self.ClassIcons[i] = bg[i]:CreateTexture(nil, "OVERLAY")
			self.ClassIcons[i]:SetTexture[[Interface\PlayerFrame\Priest-ShadowUI]]
			self.ClassIcons[i]:SetTexCoord(116/256, 152/256, 57/128, 94/128)
			self.ClassIcons[i]:SetAllPoints(bg[i])
		end

		-- only 3 shadow orbs, but we need to create throwaway textures for oUF classicons
		local throwAway = CreateFrame("Frame")
		self.ClassIcons[4] = throwAway:CreateTexture()
		self.ClassIcons[5] = throwAway:CreateTexture()
		
		bg[1]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -72, 0)
	end
	
	-- Soul shards
	if unit == "player" and select(2, UnitClass("player")) == "WARLOCK" then
		local bg = {}
		local shinywheee = {}
		self.ClassIcons = {}
		-- Helper var for animation handling
		self.ClassIcons.lastShards = UnitPower(unit, SPELL_POWER_SOUL_SHARDS)
		
		for i = 1, 4 do
			bg[i] = CreateFrame("Frame", nil, self)
			bg[i]:SetSize(17, 17)
			
			if i > 1 then bg[i]:SetPoint("RIGHT", bg[i - 1], "LEFT", -5, 0) end
			
			bg[i].tex = bg[i]:CreateTexture(nil, "ARTWORK")
			bg[i].tex:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\SoulShards.blp")
			bg[i].tex:SetTexCoord(0, 17 / 64, 0, 18 / 32)
			bg[i].tex:SetAllPoints(bg[i])
			self.ClassIcons[i] = bg[i]:CreateTexture(nil, "OVERLAY")
			self.ClassIcons[i]:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\SoulShards.blp")
			self.ClassIcons[i]:SetTexCoord(17 / 64, 34 / 64, 0, 18 / 32)
			self.ClassIcons[i]:SetAllPoints(bg[i])
			self.ClassIcons[i]:SetVertexColor(unpack(cfg.colors.power.SOUL_SHARDS))

			-- need access to the background in the PostUpdate function
			self.ClassIcons[i].bg = bg[i].tex
			
			-- Shine effect
			shinywheee[i] = CreateFrame("Frame", nil, bg[i])
			shinywheee[i]:SetAllPoints()
			shinywheee[i]:SetAlpha(0)
			shinywheee[i]:Hide()
				
			local shine = shinywheee[i]:CreateTexture(nil, "OVERLAY")
			shine:SetSize(25, 25)
			shine:SetPoint("CENTER", bg[i], -2, -2)
			shine:SetTexture("Interface\\Cooldown\\star4.blp")
			shine:SetBlendMode("ADD")
			
			shinywheee[i].anim = shinywheee[i]:CreateAnimationGroup()
			local alphaIn = shinywheee[i].anim:CreateAnimation("Alpha")
			alphaIn:SetChange(0.3)
			alphaIn:SetDuration(0.4)
			alphaIn:SetOrder(1)
			local rotateIn = shinywheee[i].anim:CreateAnimation("Rotation")
			rotateIn:SetDegrees(-90)
			rotateIn:SetDuration(0.4)
			rotateIn:SetOrder(1)
			local scaleIn = shinywheee[i].anim:CreateAnimation("Scale")
			scaleIn:SetScale(2, 2)
			scaleIn:SetOrigin("CENTER", 0, 0)
			scaleIn:SetDuration(0.4)
			scaleIn:SetOrder(1)
			local alphaOut = shinywheee[i].anim:CreateAnimation("Alpha")
			alphaOut:SetChange(-0.5)
			alphaOut:SetDuration(0.4)
			alphaOut:SetOrder(2)
			local rotateOut = shinywheee[i].anim:CreateAnimation("Rotation")
			rotateOut:SetDegrees(-90)
			rotateOut:SetDuration(0.3)
			rotateOut:SetOrder(2)
			local scaleOut = shinywheee[i].anim:CreateAnimation("Scale")
			scaleOut:SetScale(-2, -2)
			scaleOut:SetOrigin("CENTER", 0, 0)
			scaleOut:SetDuration(0.4)
			scaleOut:SetOrder(2)
				
			shinywheee[i].anim:SetScript("OnFinished", function() shinywheee[i]:Hide() end)
			shinywheee[i]:SetScript("OnShow", function() shinywheee[i].anim:Play() end)
		end

		-- max 4 soul shards, but we need to create throwaway textures for oUF classicons
		local throwAway = CreateFrame("Frame")
		self.ClassIcons[5] = throwAway:CreateTexture()
		
		self.ClassIcons.PostUpdate = function(_, currentShards, maxShards)
			if maxShards == 3 then
				self.ClassIcons[4]:Hide()
				self.ClassIcons[4].bg:Hide()
			else
				self.ClassIcons[4].bg:Show()
			end

			self.ClassIcons.lastShards = self.ClassIcons.lastShards and self.ClassIcons.lastShards or 0
			if currentShards > 0 then
				if self.ClassIcons.lastShards <= currentShards then
					-- Play animation only on shard gains
					for i = self.ClassIcons.lastShards + 1, currentShards do
						-- For each shard gained
						shinywheee[i]:Show()
					end
				end
			end
			self.ClassIcons.lastShards = currentShards
		end
		
		bg[1]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
	end
	
	-- Eclipse display
	if unit == "player" and select(2, UnitClass("player")) == "DRUID" then
		self.EclipseBar = CreateFrame("Frame", nil, self)
		self.EclipseBar:SetSize(22, 22)
		self.EclipseBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")

		-- Dummies
		self.EclipseBar.LunarBar = CreateFrame("StatusBar", nil, self.EclipseBar)
		self.EclipseBar.SolarBar = CreateFrame("StatusBar", nil, self.EclipseBar)

		self.EclipseBar.bg = self.EclipseBar:CreateTexture(nil, "ARTWORK")
		self.EclipseBar.bg:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\eclipse.blp")
		self.EclipseBar.bg:SetAllPoints()
		self.EclipseBar.bg:SetTexCoord(0, 22 / 256, 0, 22 / 64)
		
		self.EclipseBar.fill = self.EclipseBar:CreateTexture(nil, "OVERLAY")
		self.EclipseBar.fill:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\eclipse.blp")
		self.EclipseBar.fill:SetAllPoints()
		
		self.EclipseBar.direction = self.EclipseBar:CreateTexture(nil, "OVERLAY")
		self.EclipseBar.direction:SetDrawLayer("OVERLAY", 1)
		self.EclipseBar.direction:SetSize(11, 11)
		self.EclipseBar.direction:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\eclipse.blp")
		self.EclipseBar.direction:SetPoint("BOTTOMRIGHT", self.EclipseBar, "BOTTOMRIGHT", 3, -3)
		self.EclipseBar.direction:SetTexCoord(0, 22 / 256, 0, 22 / 64)
		
		self.EclipseBar.counter = self.EclipseBar:CreateFontString(nil, "OVERLAY")
		self.EclipseBar.counter:SetFontObject("UFFontMedium")
		self.EclipseBar.counter:SetPoint("RIGHT", self.EclipseBar, "LEFT", -5, 0)

		-- Initialize direction on load
		self.EclipseBar.direction:SetVertexColor(unpack(cfg.colors.power.ECLIPSE[GetEclipseDirection() == "sun" and "SOLAR" or "LUNAR"]))
		
		-- Play direction indicator animation on direction change (100% solar or lunar)
		self.EclipseBar.PostDirectionChange = function()
			self.EclipseBar.direction.frame = nil
			self.EclipseBar:SetScript("OnUpdate", function(_ , elapsed)
				AnimateTexCoords(self.EclipseBar.direction, 256, 64, 22, 22, 11, elapsed, 0.025)
				if self.EclipseBar.direction.frame > 6 then
					self.EclipseBar.direction:SetVertexColor(unpack(cfg.colors.power.ECLIPSE[GetEclipseDirection() == "sun" and "SOLAR" or "LUNAR"]))
				end
				if self.EclipseBar.direction.frame == 11 then
					self.EclipseBar:SetScript("OnUpdate", nil)
					self.EclipseBar.direction:SetTexCoord(0, 22 / 256, 0, 22 / 64)
				end
			end)
		end
		
		-- Initialize phase
		if UnitPower("player", 8) < 0 then self.EclipseBar.lastPhase = "sun" end
		
		-- Solar / lunar power updated
		self.EclipseBar.PostUpdatePower = function()
			-- Currently in solar phase
			if self.EclipseBar.SolarBar:GetValue() < self.EclipseBar.LunarBar:GetValue() then
				-- Solar phase has just been entered => play animation
				if self.EclipseBar.lastPhase == "moon" then
					self.EclipseBar.bg.frame = nil
					self.EclipseBar:SetScript("OnUpdate", function(_ , elapsed)
						-- Blizzard global function (UIParent.lua)
						AnimateTexCoords(self.EclipseBar.bg, 256, 64, 22, 22, 11, elapsed, 0.025)
						if self.EclipseBar.bg.frame > 6 then self.EclipseBar.bg:SetVertexColor(unpack(cfg.colors.power.ECLIPSE.SOLAR)) end
						-- Stop animation on last frame
						if self.EclipseBar.bg.frame == 11 then
							self.EclipseBar:SetScript("OnUpdate", nil)
							self.EclipseBar.bg:SetTexCoord(0, 22 / 256, 0, 22 / 64)
						end
					end)
				else
					self.EclipseBar.bg:SetVertexColor(unpack(cfg.colors.power.ECLIPSE.SOLAR))
				end
				
				-- Fill circle
				self.EclipseBar.fill:SetTexCoord((10 + math.floor(self.EclipseBar.SolarBar:GetValue() / 10)) * 22 / 256, (11 + math.floor(self.EclipseBar.SolarBar:GetValue() / 10)) * 22 / 256, 22 / 64, 44 / 64)
				
				-- Update cast counter
				if GetEclipseDirection() == "sun" then
					self.EclipseBar.counter:SetText(math.ceil((100 + self.EclipseBar.SolarBar:GetValue()) / 20) .. " Starfires")
				else
					self.EclipseBar.counter:SetText(math.ceil((100 - self.EclipseBar.SolarBar:GetValue()) / 13) .. " Wraths")
				end
				
				self.EclipseBar.lastPhase = "sun"
			-- Currently in lunar phase
			else
				-- Lunar phase has just been entered => play animation
				if self.EclipseBar.lastPhase == "sun" then
					self.EclipseBar.bg.frame = nil
					self.EclipseBar:SetScript("OnUpdate", function(_ , elapsed)
						-- Blizzard global function (UIParent.lua)
						AnimateTexCoords(self.EclipseBar.bg, 256, 64, 22, 22, 11, elapsed, 0.025)
						if self.EclipseBar.bg.frame > 6 then self.EclipseBar.bg:SetVertexColor(unpack(cfg.colors.power.ECLIPSE.LUNAR)) end
						-- Stop animation on last frame
						if self.EclipseBar.bg.frame == 11 then
							self.EclipseBar:SetScript("OnUpdate", nil)
							self.EclipseBar.bg:SetTexCoord(0, 22 / 256, 0, 22 / 64)
						end
					end)
				else
					self.EclipseBar.bg:SetVertexColor(unpack(cfg.colors.power.ECLIPSE.LUNAR))
				end
				
				-- Fill circle
				self.EclipseBar.fill:SetTexCoord((11 + math.floor(self.EclipseBar.LunarBar:GetValue() / 10)) * 22 / 256, (10 + math.floor(self.EclipseBar.LunarBar:GetValue() / 10)) * 22 / 256, 22 / 64, 44 / 64)
				
				-- Update cast counter
				if GetEclipseDirection() == "sun" then
					self.EclipseBar.counter:SetText(math.ceil((100 - self.EclipseBar.LunarBar:GetValue()) / 20) .. " Starfires")
				else
					self.EclipseBar.counter:SetText(math.ceil((100 + self.EclipseBar.LunarBar:GetValue()) / 13) .. " Wraths")
				end
				
				self.EclipseBar.lastPhase = "moon"
			end
		end
	end

	-- Totems (requires oUF_TotemBar)
	if unit == "player" and select(2, UnitClass("player")) == "SHAMAN" and IsAddOnLoaded("oUF_TotemBar") and cfg.TotemBar then
		self.TotemBar = {}
		self.TotemBar.Destroy = cfg.ClickToDestroy
		self.TotemBar.delay = 0.3
		self.TotemBar.colors = cfg.colors.totems
		for i = 1, 4 do
			self.TotemBar[i] = CreateFrame("StatusBar", nil, self)
			if i > 1 then self.TotemBar[i]:SetPoint("RIGHT", self.TotemBar[i - 1], "LEFT", -3 , 0) end
			self.TotemBar[i]:SetStatusBarTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\blank.blp")
			self.TotemBar[i]:SetSize(23, 20)
			self.TotemBar[i]:SetMinMaxValues(0, 1)
			-- DO NOT WANT! ;p
			self.TotemBar[i].bg = self:CreateTexture(nil)
			
			local backdrop = self.TotemBar[i]:CreateTexture(nil, "ARTWORK")
			backdrop:SetSize(23, 20)
			backdrop:SetAllPoints()
			backdrop:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\totems.blp")
			backdrop:SetTexCoord(0, 23 / 128, 0, 20 / 32)
			
			local fill = self.TotemBar[i]:CreateTexture(nil, "OVERLAY")
			fill:SetSize(23, 20)
			fill:SetPoint("BOTTOM")
			fill:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\totems.blp")
			fill:SetTexCoord((1 + 23) / 128, ((23 * 2) + 1) / 128, 0, 20 / 32)
			
			-- Shine effect
			local glowywheee = CreateFrame("Frame", nil, self.TotemBar[i])
			glowywheee:SetAllPoints()
			glowywheee:SetAlpha(0)
			glowywheee:Hide()
			
			local glow = glowywheee:CreateTexture(nil, "OVERLAY")
			glow:SetAllPoints()
			glow:SetPoint("CENTER")
			glow:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\totems.blp")
			glow:SetTexCoord((2 + 2 * 23) / 128, ((23 * 3) + 2) / 128, 0, 20 / 32)
			
			local glowend = self.TotemBar[i]:CreateTexture(nil, "OVERLAY")
			glowend:SetAllPoints()
			glowend:SetTexture("Interface\\AddOns\\oUF_Hank_v3\\textures\\totems.blp")
			glowend:SetTexCoord((2 + 2 * 23) / 128, ((23 * 3) + 2) / 128, 0, 20 / 32)
			glowend:SetAlpha(0.5)
			glowend:Hide()
			
			local anim = glowywheee:CreateAnimationGroup()
			local alphaIn = anim:CreateAnimation("Alpha")
			alphaIn:SetChange(0.5)
			alphaIn:SetSmoothing("OUT")
			alphaIn:SetDuration(1.5)
			alphaIn:SetOrder(1)

			glowywheee:SetScript("OnShow", function()
				glowend:Hide()
				anim:Play()
			end)
			
			anim:SetScript("OnFinished", function()
				glowend:Show()
				glowend:SetAlpha(0.5)
			end)
			
			-- Fill the totems
			self.TotemBar[i]:SetScript("OnValueChanged", function(self, val)
				if val == 0 then
					-- Totem expired
					glow:SetVertexColor(self:GetStatusBarColor())
					glowend:SetVertexColor(self:GetStatusBarColor())
					fill:Hide()
					glowywheee:Show()
				else
					fill:SetSize(23, 4 + 12 * val / 1)
					fill:SetTexCoord((1 + 23) / 128, ((23 * 2) + 1) / 128, 16 / 32 - 12 * val / 32, 20 / 32)
					-- 2DO: This eats performance!!
					fill:SetVertexColor(self:GetStatusBarColor())
					if glowywheee:IsVisible() then
						glowywheee:Hide()
						glowend:Hide()
					end
					if not fill:IsVisible() then fill:Show() end
				end
			end)
		end
		
		self.TotemBar[1]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
	end
	
	-- Support for oUF_SpellRange. The built-in oUF range check sucks :/
	if (unit == "target" or unit == "focus") and cfg.RangeFade and IsAddOnLoaded("oUF_SpellRange") then
		self.SpellRange = {
			insideAlpha = 1,
			outsideAlpha = cfg.RangeFadeOpacity
		}
	end
	
	-- Castbar
	if cfg.Castbar and (unit == "player" or unit == "target" or unit == "focus") then
		-- StatusBar
		local cb = CreateFrame("StatusBar", nil, self)
		cb:SetStatusBarTexture(cfg.CastbarTexture)
		cb:SetStatusBarColor(unpack(cfg.colors.castbar.bar))
		cb:SetSize(cfg.CastbarSize[1], cfg.CastbarSize[2])
		if unit == "player" then
			cb:SetPoint("LEFT", self, "RIGHT", (cfg.CastbarIcon and (cfg.CastbarSize[2] + 5) or 0) + 5 + cfg.CastbarMargin[1], cfg.CastbarMargin[2])
		elseif unit == "focus" then
			cb:SetSize(0.8 * cfg.CastbarSize[1], cfg.CastbarSize[2])
			cb:SetPoint("LEFT", self, "RIGHT", -10 - cfg.CastbarFocusMargin[1], cfg.CastbarFocusMargin[2])
		else
			cb:SetPoint("RIGHT", self, "LEFT", (cfg.CastbarIcon and (-cfg.CastbarSize[2] - 5) or 0) - 5 - cfg.CastbarMargin[1], cfg.CastbarMargin[2])
		end
		
		-- BG
		cb.Background = CreateFrame("Frame", nil, cb)
		cb.Background:SetFrameStrata("BACKGROUND")
		cb.Background:SetPoint("TOPLEFT", cb, "TOPLEFT", -5, 5)
		cb.Background:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 5, -5)
		
		local backdrop = {
			bgFile = cfg.CastbarBackdropTexture,
			edgeFile = cfg.CastbarBorderTexture,
			tileSize = 16, edgeSize = 16, tile = true,
			insets = {left = 4, right = 4, top = 4, bottom = 4}
		}
		
		cb.Background:SetBackdrop(backdrop)
		cb.Background:SetBackdropColor(0.22, 0.22, 0.19)
		cb.Background:SetBackdropBorderColor(0, 0, 0, 1)
		cb.Background:SetAlpha(0.8)
		
		-- Spark
		cb.Spark = cb:CreateTexture(nil, "OVERLAY")
		cb.Spark:SetSize(20, 35 * 2.2)
		cb.Spark:SetBlendMode("ADD")
		
		-- Spell name
		cb.Text = cb:CreateFontString(nil, "OVERLAY")
		cb.Text:SetTextColor(unpack(cfg.colors.castbar.text))
		if unit == "focus" then
			cb.Text:SetFont(unpack(cfg.CastBarBig))
			cb.Text:SetShadowOffset(1.5, -1.5)
			cb.Text:SetPoint("LEFT", 3, 0)
			cb.Text:SetPoint("RIGHT", -3, 0)
		else
			cb.Text:SetFont(unpack(cfg.CastBarMedium))
			cb.Text:SetShadowOffset(0.8, -0.8)
			cb.Text:SetPoint("LEFT", 3, 9)
			cb.Text:SetPoint("RIGHT", -3, 9)
		end
		
		if unit ~= "focus" then
			-- Icon
			if cfg.CastbarIcon then
				cb.Icon = cb:CreateTexture(nil, "OVERLAY")
				cb.Icon:SetSize(cfg.CastbarSize[2], cfg.CastbarSize[2])
				cb.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				if unit == "player" or unit == "focus" then
					cb.Icon:SetPoint("RIGHT", cb, "LEFT", -5, 0)
				else
					cb.Icon:SetPoint("LEFT", cb, "RIGHT", 5, 0)
				end
			end
			
			-- Cast time
			cb.Time = cb:CreateFontString(nil, "OVERLAY")
			cb.Time:SetFont(unpack(cfg.CastBarBig))
			cb.Time:SetTextColor(unpack(cfg.colors.castbar.text))
			cb.Time:SetShadowOffset(0.8, -0.8)
			cb.Time:SetPoint("TOP", cb.Text, "BOTTOM", 0, -3)
			cb.Time:SetPoint("LEFT", 3, 9)
			cb.Time:SetPoint("RIGHT", -3, 9)
			cb.CustomTimeText = function(_, t)
				cb.Time:SetText(("%.2f / %.2f"):format(cb.castIsChanneled and t or cb.max - t, cb.max))
			end
			cb.CustomDelayText = function(_, t)
				cb.Time:SetText(("%.2f |cFFFF5033%s%.2f|r"):format(cb.castIsChanneled and t or cb.max - t, cb.castIsChanneled and "-" or "+", cb.delay))
			end
		end
		
		-- Latency
		if unit == "player" then
			cb.PreciseSafeZone = cb:CreateTexture(nil, "BACKGROUND")
			cb.PreciseSafeZone:SetTexture(cfg.CastbarBackdropTexture)
			cb.PreciseSafeZone:SetVertexColor(unpack(cfg.colors.castbar.latency))
		
			cb.Latency = cb:CreateFontString(nil, "OVERLAY")
			cb.Latency:SetFont(unpack(cfg.CastBarSmall))
			cb.Latency:SetTextColor(unpack(cfg.colors.castbar.latencyText))
			cb.Latency:SetShadowOffset(0.8, -0.8)
			cb.Latency:SetPoint("CENTER", cb.PreciseSafeZone)
			cb.Latency:SetPoint("BOTTOM", cb.PreciseSafeZone)
			
			self:RegisterEvent("UNIT_SPELLCAST_SENT", function(_, _, caster)
				if caster == "player" or caster == "vehicle" then
					cb.castSent = GetTime()
				end
			end)
		end

		-- Animation dummy
		cb.Dummy = CreateFrame("Frame", nil, self)
		cb.Dummy:SetAllPoints(cb.Background)
		cb.Dummy:SetBackdrop(backdrop)
		cb.Dummy:SetBackdropColor(0.22, 0.22, 0.19)
		cb.Dummy:SetBackdropBorderColor(0, 0, 0, 1)
		cb.Dummy:SetAlpha(0.8)
		
		cb.Dummy.Fill = cb.Dummy:CreateTexture(nil, "OVERLAY")
		cb.Dummy.Fill:SetTexture(cfg.CastbarTexture)
		cb.Dummy.Fill:SetAllPoints(cb)
		
		if unit ~= "focus" and cfg.CastbarIcon then
			cb.Dummy.Icon = cb.Dummy:CreateTexture(nil, "OVERLAY")
			cb.Dummy.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			cb.Dummy.Icon:SetAllPoints(cb.Icon)
		end
		
		cb.Dummy:Hide()
		
		cb.Dummy.anim = cb.Dummy:CreateAnimationGroup()
		local alphaOut = cb.Dummy.anim:CreateAnimation("Alpha")
		alphaOut:SetChange(-1)
		alphaOut:SetDuration(1)
		alphaOut:SetOrder(0)

		cb:SetScript("OnShow", function()
			if cb.Dummy.anim:IsPlaying() then cb.Dummy.anim:Stop() end
			cb.Dummy:Hide()
		end)

		cb.Dummy.anim:SetScript("OnFinished", function() cb.Dummy:Hide() end)
		
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, _, unit, spell, rank)
			if UnitIsUnit(unit, self.unit) and not cb.castIsChanneled then
				oUF_Hank.PostCastSucceeded(cb, spell)
			end
		end)
		
		-- Shield dummy
		cb.Shield = cb:CreateTexture(nil, "BACKGROUND")

		cb.PostCastStart = oUF_Hank.PostCastStart
		cb.PostChannelStart = oUF_Hank.PostChannelStart
		cb.PostCastStop = oUF_Hank.PostCastStop
		cb.PostChannelStop = oUF_Hank.PostChannelStop

		self.Castbar = cb
	end

	-- Initial size
	if unit == "player" then
		self:SetSize(175, 50)
	elseif  unit == "target" or unit == "focus" then
		self:SetSize(250, 50)
	elseif unit== "pet" or unit == "targettarget" or unit == "targettargettarget" or unit == "focustarget" then
		self:SetSize(125, 16)
	elseif unit:find("boss") then
		self:SetSize(250, 50)
	end
	
end

-- custom modifications hooks --------------------------

local modList

for modName, modHooks in pairs(oUF_Hank_hooks) do

	local modErr = false
	local numHooks = 0
	
	for k, v in pairs(modHooks) do
		numHooks = numHooks + 1
		local success, ret = pcall(hooksecurefunc, oUF_Hank, k, v)
		if not success then
			modErr = true
			DEFAULT_CHAT_FRAME:AddMessage("oUF_Hank: Couldn't create hook for function " .. k .. "() in |cFFFF5033" .. modName .. "|r: \"" .. ret .. "\"", cfg.colors.text[1], cfg.colors.text[2], cfg.colors.text[3])
		end
	end
	
	if numHooks > 0 then
		if not modErr then
			modList = (modList or "") .. "|cFFFFFFFF" .. modName .. "|r, "
		else
			modList = (modList or "") .. "|cFFFF5033" .. modName .. " (see errors)|r, "
		end
	end
	
end

if modList then
	DEFAULT_CHAT_FRAME:AddMessage("oUF_Hank: Applied custom modifications: " .. strsub(modList, 1, -3), cfg.colors.text[1], cfg.colors.text[2], cfg.colors.text[3])
	modList = nil
end

-- Frame creation --------------------------------

oUF:RegisterStyle("Hankv3", oUF_Hank.sharedStyle)
oUF:SetActiveStyle("Hankv3")
oUF:Spawn("player", "oUF_player"):SetPoint("RIGHT", UIParent, "CENTER", -cfg.FrameMargin[1], -cfg.FrameMargin[2])
oUF:Spawn("pet", "oUF_pet"):SetPoint("BOTTOMRIGHT", oUF_player, "TOPRIGHT")
oUF:Spawn("target", "oUF_target"):SetPoint("LEFT", UIParent, "CENTER", cfg.FrameMargin[1], -cfg.FrameMargin[2])
oUF:Spawn("targettarget", "oUF_ToT"):SetPoint("BOTTOMLEFT", oUF_target, "TOPLEFT")
oUF:Spawn("targettargettarget", "oUF_ToTT"):SetPoint("BOTTOMLEFT", oUF_ToT, "TOPLEFT")
oUF:Spawn("focus", "oUF_focus"):SetPoint("CENTER", UIParent, "CENTER", -cfg.FocusFrameMargin[1], -cfg.FocusFrameMargin[2])
oUF:Spawn("focustarget", "oUF_ToF"):SetPoint("BOTTOMLEFT", oUF_focus, "TOPLEFT", 0, 5)

for i = 1, MAX_BOSS_FRAMES do
	oUF:Spawn("boss" .. i, "oUF_boss" .. i):SetPoint("RIGHT", UIParent, cfg.BossFrameMargin[1], -55 * (i - 1) - cfg.BossFrameMargin[2])
	_G["oUF_boss" .. i]:SetScale(cfg.FrameScale * cfg.BossFrameScale)
end

oUF_player:SetScale(cfg.FrameScale)
oUF_pet:SetScale(cfg.FrameScale)
oUF_target:SetScale(cfg.FrameScale)
oUF_ToT:SetScale(cfg.FrameScale)
oUF_ToTT:SetScale(cfg.FrameScale)
oUF_focus:SetScale(cfg.FrameScale * cfg.FocusFrameScale)
if cfg.FocusFrameScale <= 0.7 then
	oUF_ToF:SetScale(cfg.FrameScale * cfg.FocusFrameScale * 1.25)
else
	oUF_ToF:SetScale(cfg.FrameScale * cfg.FocusFrameScale)
end

if cfg.HideParty then oUF_Hank.HideParty() end
if cfg.Castbar then oUF_Hank.AdjustMirrorBars() end

if cfg.RangeFade and not IsAddOnLoaded("oUF_SpellRange") then
	DEFAULT_CHAT_FRAME:AddMessage("oUF_Hank: Please download and install oUF_SpellRange before enabling range checks!", cfg.colors.text[1], cfg.colors.text[2], cfg.colors.text[3])
elseif cfg.TotemBar and not IsAddOnLoaded("oUF_TotemBar") then
	DEFAULT_CHAT_FRAME:AddMessage("oUF_Hank: Please download and install oUF_TotemBar before enabling the totem bar!", cfg.colors.text[1], cfg.colors.text[2], cfg.colors.text[3])
end

-- Call for custom_modifications
oUF_Hank.PostSpawnFrames(oUF_Hank)
