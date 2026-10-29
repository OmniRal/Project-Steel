-- OmniRal

local DataService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
--local MarketplaceService = game:GetService("MarketplaceService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local ProductInfo = require(ReplicatedStorage.Source.SharedModules.Info.ProductInfo)
--local ShopInfo = require(ReplicatedStorage.Source.SharedModules.Info.ShopInfo)

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)

local ProfileService = require(ServerScriptService.Source.ProfileService)
local LeaderboardService = require(ServerScriptService.Source.ServerModules.Top.LeaderboardService)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

local TrophyInfo = require(ReplicatedStorage.Source.SharedModules.Info.TrophyInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LEADERBOARD_STATS_REFRESH_RATE = 3

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DataService.ProfileReady = false
DataService.ServiceReady = false

local ProfileTemplate = {
	LogInTimes = 0,
	LoggedInDuration = 0,
	LastLoggedIn = 0,
	
	PlayStats = {
		PlayTime = 0,
		Pushes = 0,
		NPCPushes = 0,
		PlayerPushes = 0,
		TimeNotPushed = 0,
		HighestScore = 0,
		RobuxSpent = 0,
	},
	
	XP = 0,
	Level = 1,
	Points = 0,
	
	Settings = {
		MusicVolume = 1,
		VoiceoversVolume = 1,
		SoundFXVolume = 1,
	},

	Trophies = {},
}

local ProfileStore = ProfileService.GetProfileStore('OmniBlot_ProjectSteel_Alpha_1', ProfileTemplate)
local Profiles = {}

local UpgradeSkillRequests: {[Player]: boolean} = {}

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



--[[function DataService.Client:GetIndex(...)
return DataService:GetIndex(...)
end]]

-- Make an item in the players data no longer new
local function RequestNotNew(Player: Player, ItemDestination: {string}): boolean
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	if not PData then return false end

	local GotItem = PData
	for n, Sub in ipairs(ItemDestination) do
		if not GotItem[Sub] then return false end
		if n ~= #ItemDestination then continue end
		if GotItem.New == nil then return false end
		GotItem.New = false
		break
	end

	return true
end

local function RequestChangeSetting(Player: Player, ThisSetting: string, Value: any): boolean
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	if not PData then return false end

	if PData.Settings[ThisSetting] == nil then return false end

	local Success = false
	if ThisSetting == "DisplayMinutes" and typeof(Value) == "boolean" then
		PData.Settings[ThisSetting] = Value; Success = true
	end

	if string.find(ThisSetting, "Volume") and typeof(Value) == "number" then
		PData.Settings[ThisSetting] = Value; Success = true
	end

	return Success, PData.Settings[ThisSetting]
end

local function SavePlayerLeaderstats(Player: Player, OtherPData: {}?)
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data or OtherPData
	if not PData then return end

	for Key, Value in PData.PlayStats do
		if Key == "PlayTime" then continue end -- Ignore these ones
		LeaderboardService.UpdateStat(Player, Key, Value)
	end
end

local function PlayerAdded(Player)
	while not DataService.ProfileReady or not DataService.ServiceReady do
		task.wait()
	end
	
	Player:SetAttribute("Joined", os.time())
	
	local Profile = ProfileStore:LoadProfileAsync("Player_" .. Player.UserId)
	print("Loaded profile : ", Profile)
	if Profile ~= nil then
		Profile:AddUserId(Player.UserId) -- GDPR compliance
		Profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		--print("R: ", profile)
		Profile:ListenToRelease(function()
			Profiles[Player] = nil
			-- The profile could"ve been loaded on another Roblox server:
			Player:Kick("Could not load player data (1)")
		end)
		
		if Player:IsDescendantOf(Players) == true then
			Profiles[Player] = Profile
			-- A profile has been successfully loaded:
			Profile.Data.LogInTimes += 1
			Profile.Data.LastLoggedIn = os.time()
			
			Profile.Data.TimerStartedAt = Workspace:GetServerTimeNow()
			
			Player:SetAttribute("DataLoaded", true)
			Remotes.Server.DataService.FullDataUpdate:Fire(Player, Profiles[Player].Data)
		else
			-- Player left before the profile loaded:
			Profile:Release()
		end
	else
		-- The profile couldn"t be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		Player:Kick("Could not load player data (2)")
	end
end

local function PlayerRemoving(Player: Player)
	local Profile = Profiles[Player]
	if not Profile then return end
	local PData = Profiles[Player].Data

	local Joined = Player:GetAttribute("Joined")
	
	PData.LoggedInDuration += os.time() - Joined

	SavePlayerLeaderstats(Player, PData)
	Profile:Release()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DataService.GetProfileTable(Player: Player, Specific: string?)
	-- Make sure all the data is ready
	if not DataService.ServiceReady then
		while not DataService.ServiceReady do
			task.wait()
		end
	end

	if not Profiles[Player] then
		while Profiles[Player] == nil do
			task.wait()
		end
	end

	if (not Specific) or (Specific and not Profiles[Player].Data[Specific]) then
		return Profiles[Player].Data
	else
		-- Return only a specific bit of data
		return Profiles[Player].Data[Specific]
	end
end

function DataService.GetIndex(Player: Player, Index: string): boolean | number | string | {}
	DataService.WaitForPlayerDataLoaded(Player)
	return Profiles[Player].Data[Index]
end

function DataService.SetIndex(Player: Player, Index: string | {}, Value: string? | number? | boolean? | {}?, DoNotSendUpdate: boolean?)
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	
	if typeof(Index) == "string" then
		PData[Index] = Value
	else
		local ThisData = PData
		for n = 1, #Index - 1 do
			ThisData = ThisData[Index[n]]
		end
		ThisData[Index[#Index]] = Value
	end
	
	if DoNotSendUpdate then return end
	Remotes.Server.DataService.SingleDataUpdate:Fire(Player, Index, Value)
end

function DataService.IncrementIndex(Player: Player, Index: string | {}, Increment: number, DoNotSendUpdate: boolean?)
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	
	if Index == "XP" then
		local NewLevel = PData.Level
		local CurrentXP = PData.XP + Increment
		
		-- Check what the new level will be based on how much xp
		for _ = PData.Level, SharedGlobalValues.MaxLevel do
			local XPNeededToLevelUp = Utility.LevelXPCurve.CalculateXPNeeded(PData.Level)
			if CurrentXP >= XPNeededToLevelUp then
				CurrentXP -= XPNeededToLevelUp
				NewLevel += 1
			else
				break
			end
		end
		
		if NewLevel >= SharedGlobalValues.MaxLevel then
			CurrentXP = 0
		end
		
		local UpdateList = {}
		
		if PData.Level < NewLevel then
			PData.Level = NewLevel
			PData.SkillPoints += 1
			
			UpdateList["Level"] = NewLevel
			UpdateList["SkillPoints"] = PData.SkillPoints
		end
		
		PData.XP = CurrentXP
		
		Remotes.Server.DataService.MultiDataUpdate:Fire(Player, UpdateList)
		Remotes.Server.DataService.GiveAddXP:Fire(Player, Increment)
		return
	end
	
	if typeof(Index) == "string" then
		PData[Index] += Increment
	else
		local ThisData = PData
		for n = 1, #Index - 1 do
			ThisData = ThisData[Index[n]]
		end
		ThisData[Index[#Index]] += Increment
	end
	
	if DoNotSendUpdate then return end
	Remotes.Server.DataService.SingleDataUpdate:Fire(Player, Index, PData[Index])
end

-- Incrememnt progress on a trophy
function DataService.UpdateTrophyProgress(Player: Player, TrophyName: string, By: number): boolean
	local PData = Profiles[Player].Data
    local ThisInfo = TrophyInfo[TrophyName]
	
    PData.Trophies[TrophyName].Progress = math.clamp(PData.Trophies[TrophyName].Progress + By, 0, ThisInfo.TimesToComplete)
	
    if PData.Trophies[TrophyName].Progress < ThisInfo.TimesToComplete then return false end
	
	-- Goal reached; save that the player has the trophy
    local CurrentTime = os.date("*t")
    PData.Trophies[TrophyName].Complete = true
    PData.Trophies[TrophyName].Date = CurrentTime.year .. ":" .. CurrentTime.month .. ":" .. CurrentTime.day .. ":" .. CurrentTime.hour .. ":" .. CurrentTime.min

	return true
end

-- Save that the player has claimed the reward from a trophy, and give the reward
function DataService.ClaimTrophyReward(Player: Player, TrophyName: string)
	local PData = Profiles[Player].Data
    PData.Trophies[TrophyName].RewardClaimed = true
end

function DataService.WaitForPlayerDataLoaded(Player)
	if Player:GetAttribute("DataLoaded") then return end
	Player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

function DataService:Init()
	Remotes.Server:CreateToClient("FullDataUpdate", {"table"}, "Reliable")
	Remotes.Server:CreateToClient("SingleDataUpdate", {"string | table", "any"}, "Reliable")
	Remotes.Server:CreateToClient("MultiDataUpdate", {"table"}, "Reliable")
	Remotes.Server:CreateToClient("GiveAddXP", {"number"}, "Reliable")
	Remotes.Server:CreateToClient("Notify", {"string", "...any"}, "Reliable")
	
	Remotes.Server:CreateToServer("RequestNotNew", {"table"}, "Returns", function(Player: Player, ItemDestination: {string}) RequestNotNew(Player, ItemDestination) end)
	Remotes.Server:CreateToServer("RequestChangeSetting", {"string", "any"}, "Returns", function(Player: Player, ThisSetting: string, Value: any) return RequestChangeSetting(Player, ThisSetting, Value) end)
	
	--[[for WeaponName, W_Info in pairs(WeaponInfo) do
	local WeaponUnlocked = false
	if W_Info.UnlockedBy == "Default" then
		WeaponUnlocked = true
	end 
	
	local Skins = {}
	for SkinName, S_Info in pairs(W_Info.Skins) do
		local SkinUnlocked = false
		if S_Info.UnlockedBy == "Default" then
			SkinUnlocked = true
		end
		Skins[SkinName] = {Unlocked = SkinUnlocked, Date = "2023:" .. RNG:NextInteger(1, 12) .. ":30:" .. RNG:NextInteger(1, 23) .. ":00", IsNew = true}
	end
	
	ProfileTemplate.Weapons[WeaponName] = {Unlocked = WeaponUnlocked, Date = "2024:" .. RNG:NextInteger(1, 12) .. ":30:" .. RNG:NextInteger(1, 23) .. ":00", IsNew = true, Skins = Skins, EquippedSuit = "Default"}
	
	ProfileTemplate.Stats.Weapons[WeaponName] = {
	TimePlayed = {Seconds = 0, Minutes = 0, Hours = 0, Days = 0},
	Kills = 0,
	Assists = 0,
	}
	end]]

	for TrophyName, _ in TrophyInfo do
        ProfileTemplate.Trophies[TrophyName] = {
			Complete = false, 
			Date = "2024:" .. RNG:NextInteger(1, 12) .. ":30:" .. RNG:NextInteger(1, 23) .. ":00", -- Test 
			Progress = 0, 
			RewardClaimed = false
		}
    end

	self.ProfileReady = true
end

function DataService:Deferred()
	self.ServiceReady = true

	task.spawn(function()
		while true do
			task.wait(LEADERBOARD_STATS_REFRESH_RATE)

			for _, Player in Players:GetPlayers() do
				if not Player then continue end
				SavePlayerLeaderstats(Player)
			end

			for _, Board in CollectionService:GetTagged("Leaderboard") do
				if not Board then continue end
				if Board:GetAttribute("Stat") == nil then continue end
				LeaderboardService.UpdateBoard(Board:GetAttribute("Stat"), 10, Board)
			end
		end
	end)
end

function DataService.PlayerAdded(Player: Player)
	task.spawn(function()
		PlayerAdded(Player)
		SavePlayerLeaderstats(Player)
	end)
end

function DataService.PlayerRemoving(Player: Player)
	task.spawn(function()
		PlayerRemoving(Player)
	end)
end

return DataService
