-- OmniRal

local MainUIController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

local DeviceController = require(StarterPlayer.StarterPlayerScripts.Source.General.DeviceController)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local VisualService = Remotes.VisualService
local DataService = Remotes.Client.DataService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MainUIController.Menu = "None"

local LocalPlayer = Players.LocalPlayer
local Gui = StarterGui.MainGui

local Assets = ReplicatedStorage.Assets

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function SetupGui()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MainUIController.SetCharacter()
    if not LocalPlayer.Character then return end
end

function MainUIController.RunHeartbeat(DeltaTime: number)
	if not DeltaTime then return end
end

function MainUIController.UpdateAllUI()

end

function MainUIController:Init()

end

function MainUIController:Deferred()
    SetupGui()

    DeviceController.CurrentDevice:Connect(function()
        print("Main UI Controller Device ", DeviceController.CurrentDevice:Get())
    end)

	Utility.CheckRemotesLoaded({"DataService"})
	DataService = Remotes.Client.DataService

	DataService.FullDataUpdate:Connect(function()
		task.defer(function() MainUIController.UpdateAllUI() end)
	end)

	DataService.MultiDataUpdate:Connect(function(UpdateList: {[string]: any})
		task.defer(function() 
			for Entry, Value in UpdateList do
				if not Entry or not Value then return end
				--[[if Entry == "Skills" then
					MainMenuUI.UpdateSkills()
					PushChargeBarUI.UpdateDivBars()
				elseif Entry == "PVPMode" then
					PVPSwitch.Button:SetAttribute("On", Value)

				elseif Entry == "Trophies" then
					MainMenuUI.UpdateStuff_Trophies()
				end]]
				return
			end
		end)
	end)

	DataService.SingleDataUpdate:Connect(function(Index, Value: any)
        task.defer(function()
            --local PData = PlayerInfo.Data

            if typeof(Index) == "string" then
				--if Index == "PVPMode" then PVPSwitch.Button:SetAttribute("On", Value) end
				return

            elseif typeof(Index) == "table" then
                if Index[#Index] == "ChargePower" then
                    --PushChargeBarUI.UpdateDivBars()
					return
                end
            end
        end)
    end)

    DataService.GiveAddXP:Connect(function(ThisMuch: number)
        PlayerInfo.AddXP += ThisMuch
    end)

    RunService.Heartbeat:Connect(function(DeltaTime: number)
        MainUIController.RunHeartbeat(DeltaTime)
    end)
end

return MainUIController