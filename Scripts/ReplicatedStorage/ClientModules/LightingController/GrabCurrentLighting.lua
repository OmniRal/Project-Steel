-- OmniRal

local GrabCurrentLighting = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LOG_PREFIX = "[GrabCurrentLighting]"

-- Numbers are rounded to 4 decimal places, so you never get stuff like 0.30000001192
local ROUND_FACTOR = 10 ^ 4

-- Never let a setting overwrite the types module that lives in the same folder!
local PROTECTED_NAMES = {
	LightingTypes = true,
}

-- The order the sections are written out in
local CAPTURE_ORDER = { "Lighting", "Atmosphere", "Bloom", "Blur", "ColorCorrection", "DepthOfField", "SunRays" }

-- Section name -> the class to look for inside of Lighting
-- (The "Lighting" section is the Lighting service itself, so it's not listed here)
local CLASS_NAMES = {
	Atmosphere = "Atmosphere",
	Bloom = "BloomEffect",
	Blur = "BlurEffect",
	ColorCorrection = "ColorCorrectionEffect",
	DepthOfField = "DepthOfFieldEffect",
	SunRays = "SunRaysEffect",
}

-- Keep these in sync with LightingTypes.LightingSetting!
local PROPERTIES: { [string]: { string } } = {
	Lighting = {
		"Ambient",
		"Brightness",
		"ColorShift_Bottom",
		"ColorShift_Top",
		"EnvironmentDiffuseScale",
		"EnvironmentSpecularScale",
		"OutdoorAmbient",
		"ClockTime",
		"GeographicLatitude",
		"ExposureCompensation",
	},
	Atmosphere = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" },
	Bloom = { "Enabled", "Intensity", "Size", "Threshold" },
	Blur = { "Enabled", "Size" },
	ColorCorrection = { "Enabled", "Brightness", "Contrast", "Saturation", "TintColor" },
	DepthOfField = { "Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity" },
	SunRays = { "Enabled", "Intensity", "Spread" },
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Types
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Finds ReplicatedStorage.Source.ClientModules.LightingController, warns if any part of the path is missing
local function GetFolder(): Instance?
	local Source = ReplicatedStorage:FindFirstChild("Source")
	local ClientModules = Source and Source:FindFirstChild("ClientModules")
	local Folder = ClientModules and ClientModules:FindFirstChild("LightingController")

	if not Folder then
		warn(`{LOG_PREFIX} Could not find ReplicatedStorage.Source.ClientModules.LightingController!`)
	end

	return Folder
end

-- Turns a property value into the text that goes in the generated module
local function FormatValue(PropertyName: string, Value: any): string
	local ValueType = typeof(Value)

	if ValueType == "Color3" then
		return `Color3.fromRGB({math.round(Value.R * 255)}, {math.round(Value.G * 255)}, {math.round(Value.B * 255)})`
	elseif ValueType == "number" then
		return tostring(math.round(Value * ROUND_FACTOR) / ROUND_FACTOR)
	elseif ValueType == "boolean" then
		return tostring(Value)
	end

	warn(`{LOG_PREFIX} {PropertyName} has an unexpected value type ({ValueType}). Writing it as-is, double check it!`)
	return tostring(Value)
end

-- Builds the text for one section (ex: Bloom = { ... },). Returns nil if the instance couldn't be found.
local function BuildSection(SectionName: string): string?
	local Target: Instance? = if SectionName == "Lighting" then Lighting else Lighting:FindFirstChildOfClass(CLASS_NAMES[SectionName])

	if not Target then
		warn(`{LOG_PREFIX} Could not find {SectionName} in Lighting. Skipping it!`)
		return nil
	end

	local Lines = { `\t{SectionName} = \{` }

	for _, PropertyName in PROPERTIES[SectionName] do
		local Success, Value = pcall(function()
			return (Target :: any)[PropertyName]
		end)

		if not Success then
			warn(`{LOG_PREFIX} Could not read {SectionName}.{PropertyName}. Skipping it!`)
			continue
		end

		table.insert(Lines, `\t\t{PropertyName} = {FormatValue(`{SectionName}.{PropertyName}`, Value)},`)
	end

	table.insert(Lines, "\t},")

	return table.concat(Lines, "\n")
end

-- Builds the full source of the generated module
local function BuildSource(): string
	local Sections = {}

	for _, SectionName in CAPTURE_ORDER do
		local Section = BuildSection(SectionName)
		if Section then
			table.insert(Sections, Section)
		end
	end

	return table.concat({
		"-- Generated by GrabCurrentLighting",
		"",
		"local LightingTypes = require(script.Parent.LightingTypes)",
		"",
		"local Setting: LightingTypes.LightingSetting = {",
		table.concat(Sections, "\n\n"),
		"}",
		"",
		"return Setting",
		"",
	}, "\n")
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- What the command calls
-- @SettingName: If this exists, the grabber will apply the changes to the existing lighting setting. If that does NOT exist, make a new one!
function GrabCurrentLighting.Run(SettingName: string)
	if type(SettingName) ~= "string" or SettingName == "" then
		warn(`{LOG_PREFIX} Missing SettingName! Usage: Run("Dusk")`)
		return
	end

	if PROTECTED_NAMES[SettingName] then
		warn(`{LOG_PREFIX} "{SettingName}" is a protected name and can't be used for a lighting setting!`)
		return
	end

	local Folder = GetFolder()
	if not Folder then
		return
	end

	local ThisSetting = Folder:FindFirstChild(SettingName)
	if ThisSetting and not ThisSetting:IsA("ModuleScript") then
		warn(`{LOG_PREFIX} "{SettingName}" already exists, but it's a {ThisSetting.ClassName}, not a ModuleScript. Nothing was changed!`)
		return
	end

	-- Build the source first, so nothing is created if something goes wrong above
	local Source = BuildSource()

	local IsNew = false
	if not ThisSetting then
		ThisSetting = Instance.new("ModuleScript")
		ThisSetting.Name = SettingName
		ThisSetting.Parent = Folder
		IsNew = true
	end

	(ThisSetting :: ModuleScript).Source = Source

	print(`{LOG_PREFIX} {if IsNew then "Created" else "Updated"} lighting setting "{SettingName}"!`)
end

return GrabCurrentLighting