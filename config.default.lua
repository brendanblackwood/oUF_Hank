oUF_Hank_config = {

-- Abbreviate names longer than n characters. Set to false to disable.
AbbreviateNames = 20,

--------------- Frame positioning and scaling ---------------
-------------------------------------------------------------

-- Scale of all frames (1.0 = 100%)
FrameScale = 1.0,
-- Focus frame scale (size of focus frame = FrameScale * FocusFrameScale)
FocusFrameScale = 0.6,
-- Margin for player / target frames (x, y from the center of the screen)
FrameMargin = {200, 300},
-- Vertical margin for focus frame (from the center of the screen)
FocusFrameMargin = {0, 300},
-- Margin for boss frames (x, y from the right edge)
BossFrameMargin = {-10, -480},
-- Boss frame scale (size of boss frame = FrameScale * BossFrameScale)
BossFrameScale = 0.8,
-- Hide Blizzard party frames (true/false)
HideParty = true,

-- For more positioning possibilities download oUF_MovableFrames
-- http://www.wowinterface.com/downloads/info15425-oUF_MovableFrames.html

-------------------------- Colors ---------------------------
-------------------------------------------------------------

-- RGB values (red / 255, green / 255, blue / 255)
-- e.g. Bright purple = RGB: 255, 0, 255 = 1, 0, 1
--      Medium green = RGB: 0, 128, 0 = 0, 0.5, 0

colors = setmetatable({
	-- Color for: General text and highlighted auras
	text = {1, 0.65, 0.16},
	-- Shadow color for small and medium sized text
	textShadow = {0.25, 0.25, 0.25, 0.75},
	-- Power types
	power = setmetatable({
		AMMOSLOT = {0.8, 0.6, 0},
		ENERGY = {1, 1, 0},
		FOCUS = {1, 0.5, 0.25},
		FUEL = {0, 0.55, 0.5},
		HAPPINESS = {0, 1, 1},
		MANA = {0.31, 0.45, 0.63},
		RAGE = {0.69, 0.31, 0.31},
		RUNIC_POWER = {0, 0.82, 1},
		SOUL_SHARDS = {0.83, 0.6, 1},
		HOLY_POWER = {1, 1, 0.4},
		ECLIPSE = {
			SOLAR = {1, 1, 0.3},
			LUNAR = {0.3, 1, 1},
		},
	}, {__index = oUF.colors.power}),

	runes = setmetatable({
		-- Blood
		{0.81, 0.26, 0.1},
		-- Unholy
		{0.17, 0.8, 0.38},
		-- Frost
		{0.17, 0.73, 0.8},
		-- Death
		{0.89, 0.17, 0.8},
	}, {__index = oUF.colors.runes}),
	totems = {
		-- Fire
		{0.81, 0.26, 0.1},
		-- Earth
		{0.8, 0.72, 0.29},
		-- Water
		{0.17, 0.5, 1},
		-- Air
		{0.17, 0.73, 0.8},
	},
	castbar = {
		-- Bar fill
		bar = {1, 0.65, 0.16},
		-- Text color
		text = {1, 1, 1},
		-- Failed cast (stopped, interrupted)
		castFail = {1, 0.31, 0.2},
		-- Successful cast
		castSuccess = {0.85, 1.00, 0.20},
		-- Latency bar
		latency = {1, 0.31, 0.2},
		-- Latency bar text
		latencyText = {0.7, 0.7, 0.7, 0.8},
		-- Uninterruptible enemy spell border
		noInterrupt = {1, 0.31, 0.2},
	}
}, {__index = oUF.colors}),

--------------------------- Fonts ---------------------------
-------------------------------------------------------------

-- See http://www.wowwiki.com/API_Font_SetFont for details

-- Please note: Big percentage numbers are textures and cannot be changed this way
-- If you use fontain (http://www.wowace.com/addons/fontain/), please change "UFFonts" under "Single font overrides"

-- Target name
FontStyleBig = {"Interface\\AddOns\\oUF_Hank\\fonts\\din1451e.ttf", 28, "THICKOUTLINE"},
-- Power, absolute health
FontStyleMedium = {"Interface\\AddOns\\oUF_Hank\\fonts\\din1451e.ttf", 16},
-- ToT, TToT, pet
FontStyleSmall = {"Interface\\AddOns\\oUF_Hank\\fonts\\din1451e.ttf", 14},
-- Castbar: Time text, focus spell name
CastBarBig = {"Interface\\AddOns\\oUF_Hank\\fonts\\tahoma.ttf", 15},
-- Castbar: Spell name (player, target)
CastBarMedium = {"Interface\\AddOns\\oUF_Hank\\fonts\\tahoma.ttf", 9},
-- Castbar: Latency
CastBarSmall = {"Interface\\AddOns\\oUF_Hank\\fonts\\tahoma.ttf", 8},

---------------------- Castbar ------------------------------
-------------------------------------------------------------

-- Use castbar (true/false)
Castbar = true,
-- Dimensions (width, height)
CastbarSize = {110, 32},
-- Castbar offsets (x, y)
CastbarMargin = {0, 0},
CastbarFocusMargin = {0, 0},
-- Show cast icon (true/false)
CastbarIcon = true,
-- Bar fill texture
CastbarTexture = "Interface\\AddOns\\oUF_Hank\\textures\\flat.blp",
-- Border texture
CastbarBorderTexture = "Interface\\AddOns\\oUF_Hank\\textures\\2px_glow.blp",
-- Background and latency texture
CastbarBackdropTexture = "Interface\\AddOns\\oUF_Hank\\textures\\flat.blp",

----------------------- Status icons ------------------------
-------------------------------------------------------------

-- Visibility and order of player status icons (combination of the following placeholders)
-- C: Combat
-- R: Rested
-- P: PvP
-- M: Loot master
-- A: Assistant
-- L: Leader
StatusIcons = "CRAL",

---------------------- Aura appearance ----------------------
-------------------------------------------------------------

-- Buff icon size (in pixels)
BuffSize = 18,
-- Debuff icon size (in pixels)
DebuffSize = 22,
-- Space between auras
AuraSpacing = 8,
-- Border texture. Set to false to disable. This layout also supports ButtonFacade.
AuraBorder = "Interface\\AddOns\\oUF_Hank\\textures\\borders\\dark_2.blp",
-- Aura mouseover zoom (1.0 = 100%)
AuraMagnification = 2.0,
-- Color for highlighted auras (RGB value)
-- Set to {1, 1, 1} for original colors
AuraStickyColor = {1, 0.65, 0.16},
-- Show or hide auras on the player frame (experimental)
PlayerBuffs = false,

----------------------- Aura filters ------------------------
-------------------------------------------------------------

-- Aura settings for target
AurasTARGET = {
	-- Maximum number of buffs shown
	MaxBuffs = 32,
	-- Maximum number of debuffs shown
	MaxDebuffs = 40,

	-- Set to true, these kinds of auras will *ALWAYS* be shown and are colored.
	-- Overrides white- and blacklists (see below)!
	StickyAuras = {
		-- Buffs casted by player on friendly units (true/false)
		myBuffs = true,
		-- Debuffs afflicted by player on hostile units (true/false)
		myDebuffs = true,
		-- Debuffs afflicted by player's pet on hostile units (true/false)
		petDebuffs = true,
		-- Debuffs on friendly units that you can cure (true/false)
		curableDebuffs = true,
		-- Buffs a hostile unit casted on itself (true/false)
		enemySelfBuffs = true,
	},

	-- All non-sticky auras (see above) will be filtered using the following method ("BLACKLIST" / "WHITELIST")
	-- Leave empty to not filter at all
	FilterMethod = {
		Buffs = "",
		Debuffs = "",
	},

	-- If the filter method is set to "BLACKLIST" the following auras will be hidden (unless sticky)
	BlackList = {
		"Essence of Wintergrasp",
		"Honorless Target",
		"Drinking",
		"Ghost",
		-- etc.
	},

	-- If the filter method is set to "WHITELIST" only (unless sticky) the following auras will be shown
	WhiteList = {
		"Heroism",
		"Mark of the Fallen Champion",
		-- etc.
	},
},

-- Aura settings for focus
-- Please refer to the explanations above
AurasFOCUS = {
	MaxBuffs = 32,
	MaxDebuffs = 40,

	StickyAuras = {
		myBuffs = true,
		myDebuffs = true,
		petDebuffs = false,
		curableDebuffs = true,
		enemySelfBuffs = true,
	},

	FilterMethod = {
		Buffs = "WHITELIST",
		Debuffs = "WHITELIST",
	},

	BlackList = {
	},

	WhiteList = {
	},
},

-- Aura settings for player
-- These will only work if PlayerBuffs = true
AurasPLAYER = {
	MaxBuffs = 4,
	MaxDebuffs = 4,

	StickyAuras = {
		myBuffs = true,
		myDebuffs = true,
		petDebuffs = false,
		curableDebuffs = true,
		enemySelfBuffs = true,
	},

	FilterMethod = {
		Buffs = "WHITELIST",
		Debuffs = "BLACKLIST",
	},

	BlackList = {
	},

	WhiteList = {
	},
},

--------------------- Additional Power ----------------------
-------------------------------------------------------------

-- Show additional power on player frame (true/false)
AdditionalPower = true,

--------------------- Threat indicator ----------------------
-------------------------------------------------------------

-- Show threat status on target and focus (true/false)
ShowThreat = true,
-- Color threat status (true/false)
ColorThreat = true,

--------------------- Exp / Reputation ----------------------
-------------------------------------------------------------

-- Show experience or reputation progress on player frame hover (true/false)
ShowXP = true,
-- Delay before experience information appears (in seconds)
DelayXP = 1.5,

----------------------- Range fading ------------------------
-------------------------------------------------------------

-- Requires oUF_SpellRange plugin!
-- http://www.wowinterface.com/downloads/info12839-oUFSpellRange.html

-- Range fading (true/false)
RangeFade = true,
-- Out of range opacity (0.0 - 1.0)
RangeFadeOpacity = 0.6,

------------------------ Totem bar --------------------------
-------------------------------------------------------------

-- Requires oUF TotemBar plugin!
-- http://www.wowinterface.com/downloads/info13714-oUF_TotemBar.html

-- Display totem bar (true/false)
TotemBar = true,
-- Destroy totems on click at totem bar, destroy all totem via shift-click (true/false)
ClickToDestroy = true,

}
