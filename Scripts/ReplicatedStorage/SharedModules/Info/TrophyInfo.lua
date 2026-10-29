-- OmniRal

local TrophyInfo = {} :: {
	[string]: {
		DisplayName: string, 
		Icon: number, -- Icon for the badge
		BadgeID: number, -- Roblox badge ID
		Description: string, -- The description for this trophy (same as the badge description)

		ScoreNeeded: number?, -- If the player needs a specific amount of a certain score to make progress
		TimesToComplete: number, -- How many times an action needs to be done to get this trophy
		RewardType: "None" | "Coins", 
		RewardAmount: any, -- How many coins or other stuff should the player receive
		DisplayProgress: boolean,
	}
}

TrophyInfo.PushNPCs_5 = {
	DisplayName = "Pushed 5",
	Icon = 101686338045377,
	BadgeID = 192131054738749,
	Description = "Push 5 unique NPCs.",

	TimesToComplete = 5,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

return TrophyInfo