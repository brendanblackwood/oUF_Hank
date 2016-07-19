local cfg = oUF_Hank_config

-- Shorten health and power numbers
local function valShort(value)
	if(value >= 1e6) then
		return ("%.2f"):format(value / 1e6):gsub("%.?0+$", "") .. "m"
	elseif(value >= 1e4) then
		return ("%.1f"):format(value / 1e3):gsub("%.?0+$", "") .. "k"
	else
		return value
	end
end

local function Abbreviate(string)
	if not string then return "" end -- Prevent boss encounter errors
	return (cfg.AbbreviateNames and string.len(string) > cfg.AbbreviateNames) and string.gsub(string, "%s?(.[\128-\191]*)%S+%s", "%1. ") or string
end

-- "Ravenholdt: 1234 / 12k", "XP: 12k/1.67m (10.3% R)"
oUF.Tags.Events["xpRep"] = "PLAYER_XP_UPDATE UPDATE_EXHAUSTION UNIT_LEVEL UPDATE_FACTION CHAT_MSG_COMBAT_FACTION_CHANGE"
oUF.Tags.Methods["xpRep"] = function(unit)
	local faction, lvl, min, max, val = GetWatchedFactionInfo()
	if faction then
		local color = oUF.colors.reaction[lvl] or cfg.colors.text
		return ("|cFF%.2x%.2x%.2x%s: %s/%s|r"):format(color[1] * 255, color[2] * 255, color[3] * 255, faction, val - min, valShort(max - min))
	else
		if GetXPExhaustion() then
			return ("XP: %s/%s (%.1f%% R)"):format(valShort(UnitXP("player")), valShort(UnitXPMax("player")), (GetXPExhaustion() or 0) / UnitXPMax("player") * 100)
		else
			return ("XP: %s/%s"):format(valShort(UnitXP("player")), valShort(UnitXPMax("player")))
		end
	end
end

-- "163.5k/1.32m"
oUF.Tags.Events["hpDetailed"] = oUF.Tags.Events["curhp"] .. " " .. oUF.Tags.Events["maxhp"]
oUF.Tags.Methods["hpDetailed"] = function(unit)
	return ("%s/%s"):format(valShort(UnitHealth(unit)), valShort(UnitHealthMax(unit)))
end

-- "23.5k/40.9k"
oUF.Tags.Events["ppDetailed"] = oUF.Tags.Events["curpp"] .. " " .. oUF.Tags.Events["maxpp"]
oUF.Tags.Methods["ppDetailed"] = function(unit)
	local _, pType = UnitPowerType(unit)
	local color = cfg.colors.power[pType] or cfg.colors.power["FUEL"]
	return ("|cFF%.2x%.2x%.2x%s/%s|r"):format(color[1] * 255, color[2] * 255, color[3] * 255, valShort(UnitPower(unit)), valShort(UnitPowerMax(unit)))
end

-- "23.5k/40.9k"
oUF.Tags.Events["apDetailed"] = oUF.Tags.Events["curpp"] .. " " .. oUF.Tags.Events["maxpp"]
oUF.Tags.Methods["apDetailed"] = function(unit)
	local pType = ADDITIONAL_POWER_BAR_NAME
	local color = cfg.colors.power[pType] or cfg.colors.power["FUEL"]
	return ("|cFF%.2x%.2x%.2x%s/%s|r"):format(color[1] * 255, color[2] * 255, color[3] * 255, valShort(UnitPower(unit, ADDITIONAL_POWER_BAR_INDEX)), valShort(UnitPowerMax(unit, ADDITIONAL_POWER_BAR_INDEX)))
end

-- "<Afk>Hankthetank"
oUF.Tags.Events["statusName"] = "UNIT_NAME_UPDATE PLAYER_FLAGS_CHANGED UNIT_FACTION INSTANCE_ENCOUNTER_ENGAGE_UNIT"
oUF.Tags.Methods["statusName"] = function(unit)
	local flags, color
	local name = Abbreviate(UnitName(unit))

	if UnitIsPlayer(unit) then
		flags = UnitIsAFK(unit) and "<Away>" or UnitIsDND(unit) and "<Busy>"
		if GetRealmName(unit) ~= GetRealmName("player") then
			name = name .. "*"
		end
		local _, class = UnitClass(unit)
		color = class and oUF.colors.class[class]
	else
		if UnitIsEnemy(unit, "player") then
			if UnitIsTapDenied(unit) then
				color = oUF.colors.tapped
			else
				color = oUF.colors.reaction[1]
			end
		else
			color = oUF.colors.reaction[UnitReaction(unit, "player") or 5] -- 5: Exception for Party Pets (nil)
		end
	end
	return ("|cFF%.2x%.2x%.2x%s%s|r"):format(color[1] * 255, color[2] * 255, color[3] * 255, flags or "", name)
end

-- "Hankthetank", "You"
oUF.Tags.Events["smartName"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["smartName"] = function(unit)
	if UnitIsUnit(unit, "player") or (UnitIsUnit(unit, "vehicle") and UnitHasVehicleUI("player")) then
		if unit == "targettarget" and UnitIsEnemy("target", "player") or unit == "targettargettarget" and UnitIsEnemy("targettarget", "player") then
			local color = oUF.colors.reaction[1]
			return ("|cFF%.2x%.2x%.2xYou|r"):format(color[1] * 255, color[2] * 255, color[3] * 255)
		else
			return "You"
		end
	else
		return Abbreviate(UnitName(unit))
	end
end

-- Either pet or player name when using a vehicle
oUF.Tags.Events["petName"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["petName"] = function(unit)
	if UnitHasVehicleUI("player") then
		return Abbreviate(UnitName("player"))
	elseif UnitName("pet") then
		return Abbreviate(UnitName("pet"))
	else
		return ""
	end
end

oUF.Tags.Events["threatPerc"] = "UNIT_THREAT_SITUATION_UPDATE"
oUF.Tags.Methods["threatPerc"] = function(unit)
	local _, _, scaledPercent, _, _ = UnitDetailedThreatSituation("player", unit)
	if scaledPercent then
		if cfg.ColorThreat then
			return ("|| |cFF%.2x%.2x%.2x%d%%|r"):format(255 * 0.75 * scaledPercent / 100, 255 * 0.75 - (255 * 0.75 * scaledPercent / 100), 0, scaledPercent)
		else
			return ("|| %d%%"):format(scaledPercent)
		end
	else
		return ""
	end
end

-- "You @89% « SomeTank", "SomeDD @95% « You"
oUF.Tags.Events["threatBoss"] = "UNIT_THREAT_LIST_UPDATE"
oUF.Tags.Methods["threatBoss"] = function(unit)
	if GetNumGroupMembers() > 0 or GetNumSubgroupMembers() > 0 then
		local prefix, num = GetNumGroupMembers() > 0 and "raid" or "party", GetNumGroupMembers() > 0 and GetNumGroupMembers() or GetNumSubgroupMembers()
		local isTanking, _, _, scaledPercent = UnitDetailedThreatSituation("player", unit)
		if isTanking then
			local highestThreat, highestThreatUnit = 0, nil
			for i = 1, num do
				local _, _, scaledPercent = UnitDetailedThreatSituation(prefix .. i, unit)
				if not UnitIsUnit(prefix .. i, "player") and (scaledPercent or 0) > highestThreat then
					highestThreat = scaledPercent
					highestThreatUnit = prefix .. i
				end
				local _, _, scaledPercent = UnitDetailedThreatSituation(prefix .. "pet" .. i, unit)
				if (scaledPercent or 0) > highestThreat then
					highestThreat = scaledPercent
					highestThreatUnit = prefix .. "pet" .. i
				end
			end
			if highestThreatUnit == nil then
				return "You"
			else
				if cfg.ColorThreat then
					return ("%s @|cFF%.2x%.2x%.2x%d%%|r \194\171 You"):format(UnitName(highestThreatUnit), 255 * 0.75 * (highestThreat or 0) / 100, 255 * 0.75 - (255 * 0.75 * (highestThreat or 0) / 100), 0, highestThreat or 0)
				else
					return ("%s @%d%% \194\171 You"):format(UnitName(highestThreatUnit), highestThreat or 0)
				end
			end
		else
			for i = 1, num do
				local isTanking = UnitDetailedThreatSituation(prefix .. i, unit)
				if isTanking then
					if cfg.ColorThreat then
						return ("You @|cFF%.2x%.2x%.2x%d%%|r \194\171 %s"):format(255 * 0.75 * (scaledPercent or 0) / 100, 255 * 0.75 - (255 * 0.75 * (scaledPercent or 0) / 100), 0, scaledPercent or 0, UnitName(prefix .. i))
					else
						return ("You @%d%% \194\171 %s"):format(scaledPercent or 0, UnitName(prefix .. i))
					end
				end
				isTanking = UnitDetailedThreatSituation(prefix .. "pet" .. i, unit)
				if isTanking then
					if cfg.ColorThreat then
						return ("You @|cFF%.2x%.2x%.2x%d%%|r \194\171 %s"):format(255 * 0.75 * (scaledPercent or 0) / 100, 255 * 0.75 - (255 * 0.75 * (scaledPercent or 0) / 100), 0, scaledPercent or 0, UnitName(prefix .. "pet" .. i))
					else
						return ("You @%d%% \194\171 %s"):format(scaledPercent or 0, UnitName(prefix .. "pet" .. i))
					end
				end
			end
			return ""
		end
	elseif UnitName("pet") then
		-- Solo with pet
		local isTanking, _, _, scaledPercentPlayer = UnitDetailedThreatSituation("player", unit)
		local _, _, _, scaledPercentPet = UnitDetailedThreatSituation("pet", unit)
		if isTanking then
			if cfg.ColorThreat then
				return ("%s @|cFF%.2x%.2x%.2x%d%%|r \194\171 You"):format(UnitName("pet"), 255 * 0.75 * (scaledPercentPet or 0) / 100, 255 * 0.75 - (255 * 0.75 * (scaledPercentPet or 0) / 100), 0, scaledPercentPet or 0)
			else
				return ("%s @%d%% \194\171 You"):format(UnitName("pet"), scaledPercentPet or 0)
			end
		else
			if cfg.ColorThreat then
				return ("You @|cFF%.2x%.2x%.2x%d%%|r \194\171 %s"):format(255 * 0.75 * (scaledPercentPlayer or 0) / 100, 255 * 0.75 - (255 * 0.75 * (scaledPercentPlayer or 0) / 100), 0, scaledPercentPlayer or 0, UnitName("pet"))
			else
				return ("You @%d%% \194\171 %s"):format(scaledPercentPlayer or 0, UnitName("pet"))
			end
		end
	else
		return ""
	end
end

-- We need this for oUF to update certain tags properly
for _, event in pairs({ "UPDATE_FACTION", "CHAT_MSG_COMBAT_FACTION_CHANGE", "INSTANCE_ENCOUNTER_ENGAGE_UNIT" }) do
	oUF.Tags.SharedEvents[event] = true
end
