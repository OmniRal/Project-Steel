-- OmniRal

local LightingController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Types
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LightingTypes = require(ReplicatedStorage.Source.ClientModules.LightingController.LightingTypes)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------`

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------`
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Store specific lighting settings here with an attached name
-- Easy access
local SavedLightingSettings: {[string]: LightingTypes.LightingSetting} = {

}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function LoadLightingSettings()
	for _, Module in script:GetChildren() do
		if not Module:IsA("ModuleScript") then continue end
		SavedLightingSettings[Module.Name] = require(Module) :: LightingTypes.LightingSetting
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function LightingController.GetSetting(ThisSetting: string): LightingTypes.LightingSetting
	return SavedLightingSettings[ThisSetting]
end

-- Change lighting to a specific setting
-- @TransitionTime = If it should tween it
function LightingController.Set(NewSetting: LightingTypes.LightingSetting, TransitionTime: number?)
	if not NewSetting then return end
	for Name, Data in NewSetting do
		local Object = Lighting -- Handle the Lighting object itself

		if Name ~= "Lighting" then
			-- Handle objects inside Lighting
			Object = Lighting:FindFirstChild(Name)
			if not Object then warn(Name, " does not exist in Lighting!"); continue end
		end

		if not Object then continue end

		local TweenList: {[string]: any} = {}

		for Property, Value in Data do
			if not Property or Value == nil then continue end
			if not Object[Property] then warn(Property, " is not a property of ", Name); continue end
			if typeof(Value) ~= "boolean" then
				if TransitionTime then 
					TweenList[Property] = Value
				else
					Object[Property] = Value
				end
			else
				Object[Property] = Value
			end
		end

		if not TransitionTime then continue end
		TweenService:Create(Object, TweenInfo.new(TransitionTime, Enum.EasingStyle.Linear), TweenList):Play()
	end
end

function LightingController:Init()
	LoadLightingSettings()
	
	task.delay(3, function()
		LightingController.Set(SavedLightingSettings["TheGrid"], 1)
	end)
end

return table.freeze(LightingController)