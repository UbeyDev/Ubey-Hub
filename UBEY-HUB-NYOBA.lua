-- ==============================================================================
-- UBEY HUB V3 | FINAL HWID BINDING & AUTO-LOGIN SYSTEM (PREMIUM EDITION)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- CONFIGURATION & FILE SAVE SYSTEM
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHubV3_Config.json"
local KEY_FILE = "UbeyHubV3_SavedKey.txt"

getgenv().UbeyConfig = {
	BiteDelay = "0.5",
	SelectedSpot = "Spot Mancing Jembatan",
	AutoSellTimer = "5",
	AutoExecuteEnabled = true,
	AntiAdminEnabled = false,
	TargetGroupId = 7019573
}

local function SaveConfig()
	pcall(function()
		if writefile then
			local data = HttpService:JSONEncode(getgenv().UbeyConfig)
			writefile(CONFIG_FILE, data)
		end
	end)
end

local function LoadConfig()
	pcall(function()
		if readfile and isfile and isfile(CONFIG_FILE) then
			local content = readfile(CONFIG_FILE)
			local data = HttpService:JSONDecode(content)
			if data then
				if data.BiteDelay then getgenv().UbeyConfig.BiteDelay = data.BiteDelay end
				if data.SelectedSpot then getgenv().UbeyConfig.SelectedSpot = data.SelectedSpot end
				if data.AutoSellTimer then getgenv().UbeyConfig.AutoSellTimer = data.AutoSellTimer end
				if data.AutoExecuteEnabled ~= nil then getgenv().UbeyConfig.AutoExecuteEnabled = data.AutoExecuteEnabled end
				if data.AntiAdminEnabled ~= nil then getgenv().UbeyConfig.AntiAdminEnabled = data.AntiAdminEnabled end
				if data.TargetGroupId then getgenv().UbeyConfig.TargetGroupId = data.TargetGroupId end
			end
		end
	end)
end

local function ResetConfig()
	pcall(function()
		getgenv().UbeyConfig = {
			BiteDelay = "0.5",
			SelectedSpot = "Spot Mancing Jembatan",
			AutoSellTimer = "5",
			AutoExecuteEnabled = true,
			AntiAdminEnabled = false,
			TargetGroupId = 7019573
		}
		if delfile and isfile then
			if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
			if isfile(KEY_FILE) then delfile(KEY_FILE) end
		end
	end)
end

LoadConfig()

------------------------------------------------------------------
-- SUPABASE CONFIGURATION & HWID RETRIEVAL
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"

local function GetDeviceHWID()
	local hwid = nil
	pcall(function()
		if gethwid then
			hwid = gethwid()
		elseif RbxAnalyticsService then
			hwid = RbxAnalyticsService:GetClientId()
		end
	end)
	return hwid or "UNKNOWN_DEVICE_" .. LocalPlayer.UserId
end

local CurrentHWID = GetDeviceHWID()

------------------------------------------------------------------
-- AUTO RECONNECT & CONDITIONAL AUTO EXECUTE
------------------------------------------------------------------
task.spawn(function()
	pcall(function()
		CoreGui.ChildAdded:Connect(function(child)
			if child.Name == "ErrorPrompt" or child.Name == "DisconnectPrompt" then
				task.wait(1)
				pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
			end
		end)
	end)
end)

pcall(function()
	if queue_on_teleport and getgenv().UbeyConfig.AutoExecuteEnabled then
		queue_on_teleport([[
			task.wait(3)
			loadstring(game:HttpGet("https://raw.githubusercontent.com/UbeyDev/Ubey-Hub/refs/heads/main/UBEY-HUB-NYOBA.lua"))()
		]])
	end
end)

pcall(function()
	if setclipboard then
		setclipboard("https://discord.gg/YXuYeEpnXE")
	elseif toclipboard then
		toclipboard("https://discord.gg/YXuYeEpnXE")
	end
end)

-- GLOBAL STATES & LOGIC
getgenv().AutoFishingEventRunning = false
getgenv().BiteDelayInput = getgenv().UbeyConfig.BiteDelay
getgenv().SelectedFishingSpot = getgenv().UbeyConfig.SelectedSpot
getgenv().AutoSellRunning = false
getgenv().AutoSellTimerInput = getgenv().UbeyConfig.AutoSellTimer
getgenv().AutoGalatamaRunning = false
getgenv().AutoSummitRunning = false
getgenv().AntiAFKRunning = false
getgenv().HideNameRunning = false
getgenv().FakeNameInput = "UBEY HUB"
getgenv().CurrentSelectedHalo = nil
getgenv().KeyVerified = false

-- AUTO FAVORITE STATES
getgenv().AutoFavoriteRunning = false
getgenv().FavRarities = {
	["Common"] = false, ["UnCommon"] = false, ["Rare"] = false, ["Epic"] = false,
	["Legendary"] = true, ["Mythical"] = true, ["Secret"] = true, ["Forgotten"] = true
}

getgenv().FavMutations = {
	["Galaxy"] = false, ["Corrupt"] = false, ["Gemstone"] = false, ["Ghost"] = false,
	["Lightning"] = false, ["Fairy Dust"] = true, ["Gold"] = false, ["Midnight"] = false,
	["Radioactive"] = false, ["Stone"] = false, ["Holographic"] = false, ["Albino"] = false,
	["Sandy"] = false, ["Cosmic"] = false, ["Normal"] = false, ["Elemental"] = false,
	["Festive"] = false, ["8-Bit"] = false, ["Bloodmoon"] = false, ["Abyssal"] = false,
	["Strawberry"] = false, ["Void"] = false, ["Cupid"] = false
}

-- AUTO UNFAVORITE FILTER STATES
getgenv().UnfavRarities = {
	["Common"] = false, ["UnCommon"] = false, ["Rare"] = false, ["Epic"] = false,
	["Legendary"] = false, ["Mythical"] = false, ["Secret"] = false, ["Forgotten"] = false
}

getgenv().UnfavMutations = {
	["Galaxy"] = false, ["Corrupt"] = false, ["Gemstone"] = false, ["Ghost"] = false,
	["Lightning"] = false, ["Fairy Dust"] = false, ["Gold"] = false, ["Midnight"] = false,
	["Radioactive"] = false, ["Stone"] = false, ["Holographic"] = false, ["Albino"] = false,
	["Sandy"] = false, ["Cosmic"] = false, ["Normal"] = false, ["Elemental"] = false,
	["Festive"] = false, ["8-Bit"] = false, ["Bloodmoon"] = false, ["Abyssal"] = false,
	["Strawberry"] = false, ["Void"] = false, ["Cupid"] = false
}

-- DATA KOORDINAT SPOT & SHOP
local FishingSpots = {
	["Spot Mancing Jembatan"] = CFrame.new(-6783.74756, 1322.81006, -9757.34473, 0.0899723172, -9.34088291e-08, 0.995944262, 1.76120434e-08, 1, 9.21981638e-08, -0.995944262, 9.24533072e-09, 0.0899723172),
	["Spot Mancing Core"] = CFrame.new(-9069.33887, 1250.32092, -6510.3374, 0.99812746, -7.96398965e-08, -0.0611686334, 8.05492206e-08, 1, 1.24000188e-08, 0.0611686334, -1.73038845e-08, 0.99812746),
	["Spot Mancing Ikan Anomali"] = CFrame.new(-8199.52832, 1238.83752, -6278.13135, -0.999144316, 1.1644854e-08, -0.0413601957, 1.63464247e-08, 1, -1.13335595e-07, 0.0413601957, -1.13914709e-07, -0.999144316)
}

local NpcSellCFrame = CFrame.new(-6668.01416, 1312.69983, -9965.2998, 0.999977231, 1.08366018e-08, -0.00675115408, -1.09201403e-08, 1, -1.2337189e-08, 0.00675115408, 1.24106316e-08, 0.999977231)

local function OptimizeRodSettings()
	pcall(function()
		local character = LocalPlayer.Character
		local rod = character and character:FindFirstChild("Withering Rod")
		if rod then
			local settingsFolder = rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Settings")
			if settingsFolder then
				local timeSetting = settingsFolder:FindFirstChild("Time_before_getfish")
				if timeSetting then timeSetting.Value = 0.05 end
				local enableMiniGame = settingsFolder:FindFirstChild("EnableMiniGame")
				if enableMiniGame then enableMiniGame.Value = false end
			end
		end
	end)
end

local function TriggerSellToNpc()
	pcall(function()
		local character = LocalPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		local currentSpotCFrame = hrp.CFrame
		hrp.CFrame = NpcSellCFrame
		task.wait(0.8)
		
		local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing")
		local jualSemua = mancing and mancing:FindFirstChild("JualSemua")
		if jualSemua then
			jualSemua:InvokeServer()
		end
		task.wait(0.8)
		
		if getgenv().AutoFishingEventRunning then
			hrp.CFrame = currentSpotCFrame
		end
	end)
end

-- ==============================================================================
-- LOGIKA PARSER AMBILSEMUA SERVER DATA
-- ==============================================================================
local function GetInventoryRemote()
	local repStorage = game:GetService("ReplicatedStorage")
	return repStorage:FindFirstChild("Remote") 
		and repStorage.Remote:FindFirstChild("Mancing") 
		and repStorage.Remote.Mancing:FindFirstChild("TandaiFavorit")
end

local function GetServerFishData()
	local fishDataList = {}
	pcall(function()
		local repStorage = game:GetService("ReplicatedStorage")
		local ambilSemuaRemote = repStorage:FindFirstChild("Remote") 
			and repStorage.Remote:FindFirstChild("Inventaris") 
			and repStorage.Remote.Inventaris:FindFirstChild("AmbilSemua")
		
		if ambilSemuaRemote then
			local result = {ambilSemuaRemote:InvokeServer()}
			local data = result[1]
			
			if type(data) == "table" then
				if #data == 0 then
					for _, outer in pairs(data) do
						if type(outer) == "table" then
							for _, fish in pairs(outer) do
								if type(fish) == "table" and (fish.uid or fish.UUID) then
									table.insert(fishDataList, {
										UUID = tostring(fish.uid or fish.UUID),
										Name = tostring(fish.nama or fish.Name or ""),
										Rarity = tostring(fish.rarity or fish.Rarity or ""),
										Mutation = tostring(fish.mutasi or fish.Mutation or ""),
										IsFavorited = fish.favorit or fish.IsFavorit or fish.IsFavorite or false
									})
								end
							end
						end
					end
				else
					for _, fish in ipairs(data) do
						if type(fish) == "table" and (fish.uid or fish.UUID) then
							table.insert(fishDataList, {
								UUID = tostring(fish.uid or fish.UUID),
								Name = tostring(fish.nama or fish.Name or ""),
								Rarity = tostring(fish.rarity or fish.Rarity or ""),
								Mutation = tostring(fish.mutasi or fish.Mutation or ""),
								IsFavorited = fish.favorit or fish.IsFavorit or fish.IsFavorite or false
							})
						end
					end
				end
			end
		end
	end)
	return fishDataList
end

local function ProcessAutoFavorite()
	pcall(function()
		local tandaiRemote = GetInventoryRemote()
		if not tandaiRemote then return end

		local serverData = GetServerFishData()
		for _, fish in ipairs(serverData) do
			if not getgenv().AutoFavoriteRunning then break end
			
			local shouldFav = false
			local fishRarityLower = string.lower(fish.Rarity)
			local fishMutationLower = string.lower(fish.Mutation)
			
			for rName, active in pairs(getgenv().FavRarities) do
				if active and string.find(fishRarityLower, string.lower(rName)) then
					shouldFav = true
				end
			end
			
			for mName, active in pairs(getgenv().FavMutations) do
				if active and string.find(fishMutationLower, string.lower(mName)) then
					shouldFav = true
				end
			end
			
			if shouldFav and not fish.IsFavorited then
				tandaiRemote:FireServer(fish.UUID, true)
				task.wait(0.12)
			end
		end
	end)
end

task.spawn(function()
	while true do
		if getgenv().AutoFavoriteRunning then
			ProcessAutoFavorite()
		end
		task.wait(2.5)
	end
end)

-- UNFAVORITE ALL
local function UnfavoriteAllFish()
	task.spawn(function()
		pcall(function()
			local tandaiRemote = GetInventoryRemote()
			if not tandaiRemote then return end

			local serverData = GetServerFishData()
			for _, fish in ipairs(serverData) do
				tandaiRemote:FireServer(fish.UUID, false)
				task.wait(0.08)
			end
		end)
	end)
end

-- UNFAVORITE BY SPECIFIC UNFAV FILTER
local function UnfavoriteByFilter()
	task.spawn(function()
		pcall(function()
			local tandaiRemote = GetInventoryRemote()
			if not tandaiRemote then return end

			local serverData = GetServerFishData()
			for _, fish in ipairs(serverData) do
				local shouldUnfav = false
				local fishRarityLower = string.lower(fish.Rarity)
				local fishMutationLower = string.lower(fish.Mutation)
				
				for rName, active in pairs(getgenv().UnfavRarities) do
					if active and string.find(fishRarityLower, string.lower(rName)) then
						shouldUnfav = true
					end
				end
				
				for mName, active in pairs(getgenv().UnfavMutations) do
					if active and string.find(fishMutationLower, string.lower(mName)) then
						shouldUnfav = true
					end
				end
				
				if shouldUnfav and fish.IsFavorited then
					tandaiRemote:FireServer(fish.UUID, false)
					task.wait(0.08)
				end
			end
		end)
	end)
end

pcall(function()
	PlayerGui:FindFirstChild("UbeyHub"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

----------------------------------------------------
-- KEY SYSTEM UI
----------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,185)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-92)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
KeyFrame.Visible = false

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0,15)
KeyCorner.Parent = KeyFrame

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Parent = KeyFrame
KeyStroke.Color = Color3.fromRGB(0,170,255)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyFrame
KeyTitle.Size = UDim2.new(1,0,0,50)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "UBEY HUB V3 - HWID KEY SYSTEM"
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextColor3 = Color3.fromRGB(0,170,255)
KeyTitle.TextSize = 14

local KeyBox = Instance.new("TextBox")
KeyBox.Parent = KeyFrame
KeyBox.Size = UDim2.new(0,340,0,38)
KeyBox.Position = UDim2.new(0,20,0,60)
KeyBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
KeyBox.PlaceholderText = "Masukkan Key dari Bot Discord..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.new(1,1,1)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 13
Instance.new("UICorner", KeyBox)

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Parent = KeyFrame
SubmitKeyBtn.Size = UDim2.new(0,165,0,35)
SubmitKeyBtn.Position = UDim2.new(0,20,0,110)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Perangkat"
SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextSize = 12
Instance.new("UICorner", SubmitKeyBtn)

local GetKeyDiscordBtn = Instance.new("TextButton")
GetKeyDiscordBtn.Parent = KeyFrame
GetKeyDiscordBtn.Size = UDim2.new(0,165,0,35)
GetKeyDiscordBtn.Position = UDim2.new(0,195,0,110)
GetKeyDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GetKeyDiscordBtn.Text = "Get Key via Discord"
GetKeyDiscordBtn.TextColor3 = Color3.new(1,1,1)
GetKeyDiscordBtn.Font = Enum.Font.GothamBold
GetKeyDiscordBtn.TextSize = 12
Instance.new("UICorner", GetKeyDiscordBtn)

local StatusKey = Instance.new("TextLabel")
StatusKey.Parent = KeyFrame
StatusKey.Size = UDim2.new(1,0,0,20)
StatusKey.Position = UDim2.new(0,0,0,155)
StatusKey.BackgroundTransparency = 1
StatusKey.Text = ""
StatusKey.Font = Enum.Font.Gotham
StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
StatusKey.TextSize = 12

----------------------------------------------------
-- MAIN HUB
----------------------------------------------------
local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Visible = false
Main.Size = UDim2.new(0,550,0,320)
Main.Position = UDim2.new(0.5,-275,0.5,-160)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,18)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(0,170,255)

local PingLabel = Instance.new("TextLabel")
PingLabel.Parent = Main
PingLabel.Size = UDim2.new(0,200,0,25)
PingLabel.Position = UDim2.new(1,-210,0,5)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "Ping: Menghitung..."
PingLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextSize = 12
PingLabel.TextXAlignment = Enum.TextXAlignment.Right

task.spawn(function()
	while true do
		pcall(function()
			local pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			PingLabel.Text = "📡 Ping: " .. pingVal .. " ms"
			if pingVal < 150 then
				PingLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			elseif pingVal < 300 then
				PingLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
			else
				PingLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			end
		end)
		task.wait(1)
	end
end)

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Parent = Main
Sidebar.Size = UDim2.new(0,140,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,20)
Sidebar.CanvasSize = UDim2.new(0,0,2.6,0)
Sidebar.ScrollBarThickness = 2

local SideCorner = Instance.new("UICorner")
SideCorner.Parent = Sidebar

local HubTitle = Instance.new("TextLabel")
HubTitle.Parent = Sidebar
HubTitle.BackgroundTransparency = 1
HubTitle.Position = UDim2.new(0, 0, 0, 8)
HubTitle.Size = UDim2.new(1, 0, 0, 22)
HubTitle.Text = "UBEY HUB"
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
HubTitle.TextSize = 17

local HubSubTitle = Instance.new("TextLabel")
HubSubTitle.Parent = Sidebar
HubSubTitle.BackgroundTransparency = 1
HubSubTitle.Position = UDim2.new(0, 0, 0, 32)
HubSubTitle.Size = UDim2.new(1, 0, 0, 18)
HubSubTitle.Text = "👑 Premium"
HubSubTitle.Font = Enum.Font.GothamBold
HubSubTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
HubSubTitle.TextSize = 12

local HomeBtn = Instance.new("TextButton")
HomeBtn.Parent = Sidebar
HomeBtn.Position = UDim2.new(0,10,0,60)
HomeBtn.Size = UDim2.new(1,-20,0,28)
HomeBtn.Text = "Fishing & Sell"
HomeBtn.TextColor3 = Color3.new(1,1,1)
HomeBtn.Font = Enum.Font.GothamMedium
HomeBtn.TextSize = 12

local FavoriteBtn = HomeBtn:Clone()
FavoriteBtn.Parent = Sidebar
FavoriteBtn.Position = UDim2.new(0,10,0,95)
FavoriteBtn.Text = "⭐ Favorite"

local GalatamaBtn = HomeBtn:Clone()
GalatamaBtn.Parent = Sidebar
GalatamaBtn.Position = UDim2.new(0,10,0,130)
GalatamaBtn.Text = "Galatama"

local TeleportShopBtn = HomeBtn:Clone()
TeleportShopBtn.Parent = Sidebar
TeleportShopBtn.Position = UDim2.new(0,10,0,165)
TeleportShopBtn.Text = "Teleport Shop"

local SummitBtn = HomeBtn:Clone()
SummitBtn.Parent = Sidebar
SummitBtn.Position = UDim2.new(0,10,0,200)
SummitBtn.Text = "Summit"

local PlayerMenuBtn = HomeBtn:Clone()
PlayerMenuBtn.Parent = Sidebar
PlayerMenuBtn.Position = UDim2.new(0,10,0,235)
PlayerMenuBtn.Text = "Player"

local HaloMenuBtn = HomeBtn:Clone()
HaloMenuBtn.Parent = Sidebar
HaloMenuBtn.Position = UDim2.new(0,10,0,270)
HaloMenuBtn.Text = "Halo Kepala"

local PlayerTpBtn = HomeBtn:Clone()
PlayerTpBtn.Parent = Sidebar
PlayerTpBtn.Position = UDim2.new(0,10,0,305)
PlayerTpBtn.Text = "Teleport Player"

local PrivacyBtn = HomeBtn:Clone()
PrivacyBtn.Parent = Sidebar
PrivacyBtn.Position = UDim2.new(0,10,0,340)
PrivacyBtn.Text = "Privacy"

local SettingsBtn = HomeBtn:Clone()
SettingsBtn.Parent = Sidebar
SettingsBtn.Position = UDim2.new(0,10,0,375)
SettingsBtn.Text = "Settings"

local CreditsBtn = HomeBtn:Clone()
CreditsBtn.Parent = Sidebar
CreditsBtn.Position = UDim2.new(0,10,0,410)
CreditsBtn.Text = "Credits"

for _,v in ipairs({HomeBtn, FavoriteBtn, GalatamaBtn, TeleportShopBtn, SummitBtn, PlayerMenuBtn, HaloMenuBtn, PlayerTpBtn, PrivacyBtn, SettingsBtn, CreditsBtn}) do
	v.BackgroundColor3 = Color3.fromRGB(35,35,45)
	local c = Instance.new("UICorner")
	c.Parent = v
end

local Content = Instance.new("Frame")
Content.Parent = Main
Content.Position = UDim2.new(0,150,0,30)
Content.Size = UDim2.new(1,-160,1,-40)
Content.BackgroundTransparency = 1

local function MakePage()
	local f = Instance.new("ScrollingFrame")
	f.Parent = Content
	f.Size = UDim2.new(1,0,1,0)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.CanvasSize = UDim2.new(0,0,6,0)
	f.ScrollBarThickness = 4
	
	local pad = Instance.new("UIPadding")
	pad.Parent = f
	pad.PaddingTop = UDim.new(0, 10)
	
	local l = Instance.new("UIListLayout")
	l.Parent = f
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, 8)
	return f
end

local FishingPage = MakePage() FishingPage.Visible = true
local FavoritePage = MakePage()
local GalatamaPage = MakePage()
local TeleportShopPage = MakePage()
local SummitPage = MakePage()
local PlayerPage = MakePage()
local HaloPage = MakePage()
local PlayerTpPage = MakePage()
local PrivacyPage = MakePage()
local SettingsPage = MakePage()
local CreditsPage = MakePage()

local function HideAll()
	FishingPage.Visible = false
	FavoritePage.Visible = false
	GalatamaPage.Visible = false
	TeleportShopPage.Visible = false
	SummitPage.Visible = false
	PlayerPage.Visible = false
	HaloPage.Visible = false
	PlayerTpPage.Visible = false
	PrivacyPage.Visible = false
	SettingsPage.Visible = false
	CreditsPage.Visible = false
end

HomeBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
FavoriteBtn.MouseButton1Click:Connect(function() HideAll(); FavoritePage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
TeleportShopBtn.MouseButton1Click:Connect(function() HideAll(); TeleportShopPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerMenuBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
HaloMenuBtn.MouseButton1Click:Connect(function() HideAll(); HaloPage.Visible = true end)
PlayerTpBtn.MouseButton1Click:Connect(function() HideAll(); PlayerTpPage.Visible = true end)
PrivacyBtn.MouseButton1Click:Connect(function() HideAll(); PrivacyPage.Visible = true end)
SettingsBtn.MouseButton1Click:Connect(function() HideAll(); SettingsPage.Visible = true end)
CreditsBtn.MouseButton1Click:Connect(function() HideAll(); CreditsPage.Visible = true end)

local function AddToggle(parent, text, callback)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Size = UDim2.new(1,0,0,35)
	b.BackgroundColor3 = Color3.fromRGB(30,30,40)
	b.Text = "  " .. text .. " [OFF]"
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", b)
	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = "  " .. text .. (state and " [ON]" or " [OFF]")
		b.BackgroundColor3 = state and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
		callback(state)
	end)
end

----------------------------------------------------
-- VERIFICATION & HWID CHECK LOGIC
----------------------------------------------------
GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function()
		if setclipboard then setclipboard("https://discord.gg/YXuYeEpnXE") end
	end)
	StatusKey.TextColor3 = Color3.fromRGB(0,170,255)
	StatusKey.Text = "Link Discord disalin!"
end)

local function ValidateKey(enteredKey, isAutoLogin)
	if enteredKey == "" then
		if not isAutoLogin then
			StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
			StatusKey.Text = "Masukkan key terlebih dahulu!"
		end
		KeyFrame.Visible = true
		return
	end
	
	if not isAutoLogin then
		StatusKey.TextColor3 = Color3.fromRGB(255,200,0)
		StatusKey.Text = "Memeriksa HWID & Key ke Server..."
	end
	
	task.spawn(function()
		local requestFunc = syn and syn.request or http and http.request or request
		
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({
					Url = SUPABASE_URL .. enteredKey,
					Method = "GET",
					Headers = {
						["apikey"] = SUPABASE_ANON_KEY,
						["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
						["Content-Type"] = "application/json"
					}
				})
				return res.Body
			else
				return HttpService:GetAsync(SUPABASE_URL .. HttpService:UrlEncode(enteredKey), false, {
					["apikey"] = SUPABASE_ANON_KEY,
					["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY
				})
			end
		end)
		
		if success and response then
			local decodeSuccess, data = pcall(function()
				return HttpService:JSONDecode(response)
			end)
			
			if decodeSuccess and data and #data > 0 then
				local record = data[1]
				local keyStatus = record.status
				local savedHwid = record.hwid_value
				
				if keyStatus == false or keyStatus == "inactive" or keyStatus == "used" then
					if not isAutoLogin then
						StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
						StatusKey.Text = "Key sudah tidak aktif!"
					end
					if isfile and isfile(KEY_FILE) then delfile(KEY_FILE) end
					KeyFrame.Visible = true
					return
				end
				
				if savedHwid and savedHwid ~= "" and savedHwid ~= CurrentHWID then
					if not isAutoLogin then
						StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
						StatusKey.Text = "Key terikat di perangkat lain! Silakan Reset HWID."
					end
					if isfile and isfile(KEY_FILE) then delfile(KEY_FILE) end
					KeyFrame.Visible = true
					return
				end
				
				pcall(function()
					if writefile then
						writefile(KEY_FILE, enteredKey)
					end
				end)
				
				getgenv().KeyVerified = true
				KeyFrame.Visible = false
				Main.Visible = true
			else
				if not isAutoLogin then
					StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
					StatusKey.Text = "Key Salah atau Tidak Ditemukan!"
				end
				if isfile and isfile(KEY_FILE) then delfile(KEY_FILE) end
				KeyFrame.Visible = true
			end
		else
			if not isAutoLogin then
				StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
				StatusKey.Text = "Gagal terhubung ke database."
			end
			KeyFrame.Visible = true
		end
	end)
end

SubmitKeyBtn.MouseButton1Click:Connect(function()
	ValidateKey(KeyBox.Text, false)
end)

task.spawn(function()
	if readfile and isfile and isfile(KEY_FILE) then
		local savedKey = readfile(KEY_FILE)
		if savedKey and savedKey ~= "" then
			KeyBox.Text = savedKey
			ValidateKey(savedKey, true)
		else
			KeyFrame.Visible = true
		end
	else
		KeyFrame.Visible = true
	end
end)

----------------------------------------------------
-- 1. FISHING & SELL PAGE (SISTEM AUTO FISHING BARU)
----------------------------------------------------
local TitleFish = Instance.new("TextLabel")
TitleFish.Parent = FishingPage
TitleFish.Size = UDim2.new(1,0,0,30)
TitleFish.BackgroundTransparency = 1
TitleFish.Text = "🔥 AUTO FISHING & SELL UTILITIES"
TitleFish.TextColor3 = Color3.fromRGB(0,170,255)
TitleFish.Font = Enum.Font.GothamBold
TitleFish.TextSize = 13

local SpotLabel = Instance.new("TextLabel")
SpotLabel.Parent = FishingPage
SpotLabel.Size = UDim2.new(1,0,0,25)
SpotLabel.BackgroundTransparency = 1
SpotLabel.Text = "Pilih Lokasi: " .. getgenv().SelectedFishingSpot
SpotLabel.TextColor3 = Color3.new(1,1,1)
SpotLabel.Font = Enum.Font.Gotham
SpotLabel.TextSize = 12

local ChangeSpotBtn = Instance.new("TextButton")
ChangeSpotBtn.Parent = FishingPage
ChangeSpotBtn.Size = UDim2.new(1,0,0,32)
ChangeSpotBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
ChangeSpotBtn.Text = "Ganti Spot (Jembatan -> Core -> Anomali)"
ChangeSpotBtn.TextColor3 = Color3.new(1,1,1)
ChangeSpotBtn.Font = Enum.Font.GothamMedium
ChangeSpotBtn.TextSize = 12
Instance.new("UICorner", ChangeSpotBtn)

local spotList = {"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}
local spotIndex = 1
for i, v in ipairs(spotList) do
	if v == getgenv().SelectedFishingSpot then spotIndex = i end
end

ChangeSpotBtn.MouseButton1Click:Connect(function()
	spotIndex = spotIndex % #spotList + 1
	getgenv().SelectedFishingSpot = spotList[spotIndex]
	SpotLabel.Text = "Pilih Lokasi: " .. getgenv().SelectedFishingSpot
	getgenv().UbeyConfig.SelectedSpot = getgenv().SelectedFishingSpot
	SaveConfig()
end)

AddToggle(FishingPage, "Smart Auto Fishing + Teleport", function(v)
	getgenv().AutoFishingEventRunning = v
	if v then
		pcall(function()
			local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			local targetCFrame = FishingSpots[getgenv().SelectedFishingSpot]
			if hrp and targetCFrame then
				hrp.CFrame = targetCFrame
			end
		end)
		
		OptimizeRodSettings()
		task.spawn(function()
			while getgenv().AutoFishingEventRunning do
				pcall(function()
					local rod = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Withering Rod")
					if rod and rod:FindFirstChild("Mechanics") then
						local remoteFolder = rod.Mechanics:FindFirstChild("Remotes")
						if remoteFolder then
							OptimizeRodSettings()
							local hrp = LocalPlayer.Character.HumanoidRootPart
							remoteFolder.CastEvent:FireServer(false, 100, hrp.CFrame.LookVector)
							
							task.wait(0.05)
							local hooked = false
							local conn
							conn = remoteFolder.NotifyClient.OnClientEvent:Connect(function(actionType)
								if actionType == "Bite" then
									hooked = true
									if conn then conn:Disconnect() end
								end
							end)
							
							local start = tick()
							while not hooked and getgenv().AutoFishingEventRunning do
								if tick() - start > 10 then break end
								task.wait(0.05)
							end
							if conn then conn:Disconnect() end
							
							if hooked and getgenv().AutoFishingEventRunning then
								local currentDelay = tonumber(getgenv().BiteDelayInput) or 0.5
								task.wait(currentDelay)
								remoteFolder.MiniGame:FireServer(true)
								task.wait(0.3)
							end
						end
					else
						task.wait(1)
					end
				end)
				task.wait(0.1)
			end
		end)
	end
end)

AddToggle(FishingPage, "Smart Auto Fishing (Di Tempat Saja)", function(v)
	getgenv().AutoFishingEventRunning = v
	if v then
		OptimizeRodSettings()
		task.spawn(function()
			while getgenv().AutoFishingEventRunning do
				pcall(function()
					local rod = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Withering Rod")
					if rod and rod:FindFirstChild("Mechanics") then
						local remoteFolder = rod.Mechanics:FindFirstChild("Remotes")
						if remoteFolder then
							OptimizeRodSettings()
							local hrp = LocalPlayer.Character.HumanoidRootPart
							remoteFolder.CastEvent:FireServer(false, 100, hrp.CFrame.LookVector)
							
							task.wait(0.05)
							local hooked = false
							local conn
							conn = remoteFolder.NotifyClient.OnClientEvent:Connect(function(actionType)
								if actionType == "Bite" then
									hooked = true
									if conn then conn:Disconnect() end
								end
							end)
							
							local start = tick()
							while not hooked and getgenv().AutoFishingEventRunning do
								if tick() - start > 10 then break end
								task.wait(0.05)
							end
							if conn then conn:Disconnect() end
							
							if hooked and getgenv().AutoFishingEventRunning then
								local currentDelay = tonumber(getgenv().BiteDelayInput) or 0.5
								task.wait(currentDelay)
								remoteFolder.MiniGame:FireServer(true)
								task.wait(0.3)
							end
						end
					else
						task.wait(1)
					end
				end)
				task.wait(0.1)
			end
		end)
	end
end)

local BiteDelayBox = Instance.new("TextBox")
BiteDelayBox.Parent = FishingPage
BiteDelayBox.Size = UDim2.new(1,0,0,35)
BiteDelayBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
BiteDelayBox.PlaceholderText = "Bite Delay (Detik, Cth: 0.5)"
BiteDelayBox.Text = tostring(getgenv().UbeyConfig.BiteDelay)
BiteDelayBox.TextColor3 = Color3.new(1,1,1)
BiteDelayBox.Font = Enum.Font.Gotham
BiteDelayBox.TextSize = 12
Instance.new("UICorner", BiteDelayBox)
BiteDelayBox.FocusLost:Connect(function()
	getgenv().BiteDelayInput = BiteDelayBox.Text
	getgenv().UbeyConfig.BiteDelay = BiteDelayBox.Text
	SaveConfig()
end)

AddToggle(FishingPage, "Auto Sell Timer ke NPC", function(v)
	getgenv().AutoSellRunning = v
	if v then
		task.spawn(function()
			local lastSellTime = tick()
			while getgenv().AutoSellRunning do
				task.wait(1)
				local elapsedMinutes = (tick() - lastSellTime) / 60
				local targetMinutes = tonumber(getgenv().AutoSellTimerInput) or 5
				if elapsedMinutes >= targetMinutes then
					TriggerSellToNpc()
					lastSellTime = tick()
				end
			end
		end)
	end
end)

local SellTimerBox = Instance.new("TextBox")
SellTimerBox.Parent = FishingPage
SellTimerBox.Size = UDim2.new(1,0,0,35)
SellTimerBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
SellTimerBox.PlaceholderText = "Jeda Waktu Jual (Menit, Cth: 5)"
SellTimerBox.Text = tostring(getgenv().UbeyConfig.AutoSellTimer)
SellTimerBox.TextColor3 = Color3.new(1,1,1)
SellTimerBox.Font = Enum.Font.Gotham
SellTimerBox.TextSize = 12
Instance.new("UICorner", SellTimerBox)
SellTimerBox.FocusLost:Connect(function()
	getgenv().AutoSellTimerInput = SellTimerBox.Text
	getgenv().UbeyConfig.AutoSellTimer = SellTimerBox.Text
	SaveConfig()
end)

----------------------------------------------------
-- 2. FAVORITE PAGE (AUTO FAVORITE & UNFAVORITE)
----------------------------------------------------
local TitleFav = Instance.new("TextLabel")
TitleFav.Parent = FavoritePage
TitleFav.Size = UDim2.new(1,0,0,25)
TitleFav.BackgroundTransparency = 1
TitleFav.Text = "⭐ AUTO FAVORITE FILTER"
TitleFav.TextColor3 = Color3.fromRGB(0,170,255)
TitleFav.Font = Enum.Font.GothamBold
TitleFav.TextSize = 13

AddToggle(FavoritePage, "AUTO FAVORITE", function(v)
	getgenv().AutoFavoriteRunning = v
end)

local function CreateMultiSelectDropdown(parent, titleText, optionsTable, targetStateTable)
	local container = Instance.new("Frame")
	container.Parent = parent
	container.Size = UDim2.new(1,0,0,40)
	container.BackgroundColor3 = Color3.fromRGB(30,30,40)
	container.ClipsDescendants = true
	Instance.new("UICorner", container)

	local header = Instance.new("TextButton")
	header.Parent = container
	header.Size = UDim2.new(1,0,0,40)
	header.BackgroundTransparency = 1
	header.Text = "  " .. titleText
	header.TextColor3 = Color3.new(1,1,1)
	header.Font = Enum.Font.GothamMedium
	header.TextSize = 12
	header.TextXAlignment = Enum.TextXAlignment.Left

	local countLabel = Instance.new("TextLabel")
	countLabel.Parent = header
	countLabel.Size = UDim2.new(0,120,1,0)
	countLabel.Position = UDim2.new(1,-130,0,0)
	countLabel.BackgroundTransparency = 1
	countLabel.TextColor3 = Color3.fromRGB(0,170,255)
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextSize = 11
	countLabel.TextXAlignment = Enum.TextXAlignment.Right

	local optionsHolder = Instance.new("Frame")
	optionsHolder.Parent = container
	optionsHolder.Position = UDim2.new(0,5,0,40)
	optionsHolder.Size = UDim2.new(1,-10,0,0)
	optionsHolder.BackgroundTransparency = 1

	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = optionsHolder
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)

	local itemButtons = {}

	local function UpdateSummary()
		local selectedCount = 0
		for _, active in pairs(targetStateTable) do
			if active then selectedCount = selectedCount + 1 end
		end
		if selectedCount == 0 then
			countLabel.Text = "None 🔽"
		elseif selectedCount == #optionsTable then
			countLabel.Text = "All (" .. selectedCount .. ") 🔽"
		else
			countLabel.Text = selectedCount .. " Selected 🔽"
		end
	end

	local selectAllBtn = Instance.new("TextButton")
	selectAllBtn.Parent = optionsHolder
	selectAllBtn.Size = UDim2.new(1,0,0,28)
	selectAllBtn.BackgroundColor3 = Color3.fromRGB(0,150,120)
	selectAllBtn.Text = "  ⚡ SELECT ALL / UNSELECT ALL"
	selectAllBtn.TextColor3 = Color3.new(1,1,1)
	selectAllBtn.Font = Enum.Font.GothamBold
	selectAllBtn.TextSize = 11
	selectAllBtn.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", selectAllBtn)

	local allState = false
	selectAllBtn.MouseButton1Click:Connect(function()
		allState = not allState
		for _, optName in ipairs(optionsTable) do
			targetStateTable[optName] = allState
		end
		for optName, btn in pairs(itemButtons) do
			btn.BackgroundColor3 = allState and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
			btn.Text = "  " .. optName .. (allState and "  [✓]" or "  [ ]")
		end
		UpdateSummary()
	end)

	for _, optName in ipairs(optionsTable) do
		local optBtn = Instance.new("TextButton")
		optBtn.Parent = optionsHolder
		optBtn.Size = UDim2.new(1,0,0,28)
		optBtn.BackgroundColor3 = targetStateTable[optName] and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
		optBtn.Text = "  " .. optName .. (targetStateTable[optName] and "  [✓]" or "  [ ]")
		optBtn.TextColor3 = Color3.new(1,1,1)
		optBtn.Font = Enum.Font.Gotham
		optBtn.TextSize = 11
		optBtn.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UICorner", optBtn)

		itemButtons[optName] = optBtn

		optBtn.MouseButton1Click:Connect(function()
			targetStateTable[optName] = not targetStateTable[optName]
			optBtn.BackgroundColor3 = targetStateTable[optName] and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
			optBtn.Text = "  " .. optName .. (targetStateTable[optName] and "  [✓]" or "  [ ]")
			UpdateSummary()
		end)
	end

	UpdateSummary()

	local isOpen = false
	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		local totalHeight = 45 + ((#optionsTable + 1) * 32)
		container:TweenSize(
			isOpen and UDim2.new(1,0,0,totalHeight) or UDim2.new(1,0,0,40),
			Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true
		)
	end)
end

local rarityList = {"Common", "UnCommon", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Forgotten"}
local mutationList = {
	"Galaxy", "Corrupt", "Gemstone", "Ghost", "Lightning", "Fairy Dust", 
	"Gold", "Midnight", "Radioactive", "Stone", "Holographic", "Albino", "Sandy", "Cosmic",
	"Elemental", "Festive", "8-Bit", "Bloodmoon", "Abyssal", "Strawberry", "Void", "Cupid"
}

CreateMultiSelectDropdown(FavoritePage, "Fav Filter Rarity", rarityList, getgenv().FavRarities)
CreateMultiSelectDropdown(FavoritePage, "Fav Filter Mutasi", mutationList, getgenv().FavMutations)

local DividerFav = Instance.new("Frame")
DividerFav.Parent = FavoritePage
DividerFav.Size = UDim2.new(1,0,0,2)
DividerFav.BackgroundColor3 = Color3.fromRGB(50,50,65)

local TitleUnfav = Instance.new("TextLabel")
TitleUnfav.Parent = FavoritePage
TitleUnfav.Size = UDim2.new(1,0,0,25)
TitleUnfav.BackgroundTransparency = 1
TitleUnfav.Text = "🗑️ UNFAVORITE FILTER SETTINGS"
TitleUnfav.TextColor3 = Color3.fromRGB(255,100,100)
TitleUnfav.Font = Enum.Font.GothamBold
TitleUnfav.TextSize = 13

CreateMultiSelectDropdown(FavoritePage, "Unfav Filter Rarity", rarityList, getgenv().UnfavRarities)
CreateMultiSelectDropdown(FavoritePage, "Unfav Filter Mutasi", mutationList, getgenv().UnfavMutations)

local UnfavFilterBtn = Instance.new("TextButton")
UnfavFilterBtn.Parent = FavoritePage
UnfavFilterBtn.Size = UDim2.new(1,0,0,38)
UnfavFilterBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 30)
UnfavFilterBtn.Text = "🎯 UNFAVORITE BY FILTER (Rarity/Mutasi Diatas)"
UnfavFilterBtn.TextColor3 = Color3.new(1,1,1)
UnfavFilterBtn.Font = Enum.Font.GothamBold
UnfavFilterBtn.TextSize = 12
Instance.new("UICorner", UnfavFilterBtn)

UnfavFilterBtn.MouseButton1Click:Connect(function()
	UnfavFilterBtn.Text = "⌛ Processing Unfav Filter..."
	UnfavoriteByFilter()
	task.wait(1.5)
	UnfavFilterBtn.Text = "🎯 UNFAVORITE BY FILTER (Rarity/Mutasi Diatas)"
end)

local UnfavBtn = Instance.new("TextButton")
UnfavBtn.Parent = FavoritePage
UnfavBtn.Size = UDim2.new(1,0,0,38)
UnfavBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
UnfavBtn.Text = "🚨 UNFAVORITE ALL FISH (Semua Ikan)"
UnfavBtn.TextColor3 = Color3.new(1,1,1)
UnfavBtn.Font = Enum.Font.GothamBold
UnfavBtn.TextSize = 12
Instance.new("UICorner", UnfavBtn)

UnfavBtn.MouseButton1Click:Connect(function()
	UnfavBtn.Text = "⌛ Process Unfavoriting All..."
	UnfavoriteAllFish()
	task.wait(1.5)
	UnfavBtn.Text = "🚨 UNFAVORITE ALL FISH (Semua Ikan)"
end)

----------------------------------------------------
-- 3. GALATAMA PAGE
----------------------------------------------------
local TitleGal = Instance.new("TextLabel")
TitleGal.Parent = GalatamaPage
TitleGal.Size = UDim2.new(1,0,0,30)
TitleGal.BackgroundTransparency = 1
TitleGal.Text = "🏆 GALATAMA AUTO JOIN & TELEPORT"
TitleGal.TextColor3 = Color3.fromRGB(0,170,255)
TitleGal.Font = Enum.Font.GothamBold
TitleGal.TextSize = 13

local TeleportGalatamaBtn = Instance.new("TextButton")
TeleportGalatamaBtn.Parent = GalatamaPage
TeleportGalatamaBtn.Size = UDim2.new(1,0,0,35)
TeleportGalatamaBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
TeleportGalatamaBtn.Text = "📍 Teleport ke Galatama"
TeleportGalatamaBtn.TextColor3 = Color3.new(1,1,1)
TeleportGalatamaBtn.Font = Enum.Font.GothamBold
TeleportGalatamaBtn.TextSize = 13
Instance.new("UICorner", TeleportGalatamaBtn)

TeleportGalatamaBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local character = LocalPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(-8008.12744, 1227.96838, -6091.92627, 1, 5.81026569e-08, -1.99986468e-12, -5.81026569e-08, 1, -2.64906923e-08, 1.99832555e-12, 2.64906923e-08, 1)
		end
	end)
end)

AddToggle(GalatamaPage, "Aktifkan Auto Join Galatama", function(v)
	getgenv().AutoGalatamaRunning = v
	if v then
		task.spawn(function()
			while getgenv().AutoGalatamaRunning do
				pcall(function()
					local glatamaFolder = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Glatama")
					local ikutRemote = glatamaFolder and glatamaFolder:FindFirstChild("Ikut")
					if ikutRemote then
						ikutRemote:InvokeServer()
					end
				end)
				task.wait(10)
			end
		end)
	end
end)

----------------------------------------------------
-- 4. TELEPORT SHOP PAGE
----------------------------------------------------
local TitleShop = Instance.new("TextLabel")
TitleShop.Parent = TeleportShopPage
TitleShop.Size = UDim2.new(1,0,0,30)
TitleShop.BackgroundTransparency = 1
TitleShop.Text = "🛒 TELEPORT TO SHOPS & NPCS"
TitleShop.TextColor3 = Color3.fromRGB(0,170,255)
TitleShop.Font = Enum.Font.GothamBold
TitleShop.TextSize = 13

local function AddShopTeleportBtn(parent, name, cf)
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.Size = UDim2.new(1,0,0,35)
	btn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	btn.Text = "📍 Teleport ke " .. name
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 12
	Instance.new("UICorner", btn)
	
	btn.MouseButton1Click:Connect(function()
		pcall(function()
			local character = LocalPlayer.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = cf
			end
		end)
	end)
end

AddShopTeleportBtn(TeleportShopPage, "Tempat Jual Ikan", CFrame.new(-6668.79785, 1312.69983, -9964.06152, 0.987391293, 3.72071405e-08, 0.158298522, -5.17625871e-08, 1, 8.78264004e-08, -0.158298522, -9.49129628e-08, 0.987391293))
AddShopTeleportBtn(TeleportShopPage, "Skin Shop", CFrame.new(-6639.45947, 1312.69983, -9947.36133, 0.168582469, 1.05222426e-07, -0.985687554, -6.35753779e-08, 1, 9.58769633e-08, 0.985687554, 4.65022865e-08, 0.168582469))
AddShopTeleportBtn(TeleportShopPage, "Pet Shop", CFrame.new(-6640.44092, 1312.69983, -9917.93652, 0.0638339892, -2.53899041e-10, -0.997960508, 9.77985887e-11, 1, -2.48162269e-10, 0.997960508, -8.17579407e-11, 0.0638339892))
AddShopTeleportBtn(TeleportShopPage, "Upgrade Pet", CFrame.new(-6637.85156, 1312.69983, -9886.52441, 0.123627231, -2.69338489e-08, -0.992328703, 3.78244884e-08, 1, -2.24297771e-08, 0.992328703, -3.47613955e-08, 0.123627231))
AddShopTeleportBtn(TeleportShopPage, "Rod Shop", CFrame.new(-6638.09521, 1312.69983, -9857.41797, 0.0285888873, -6.18125018e-09, -0.999591231, -1.27718458e-09, 1, -6.22030605e-09, 0.999591231, 1.45449419e-09, 0.0285888873))
AddShopTeleportBtn(TeleportShopPage, "Title Shop", CFrame.new(-6667.0249, 1312.69983, -9843.66113, -0.98894012, 4.00152409e-08, -0.148315206, 5.70598111e-08, 1, -1.10666292e-07, 0.148315206, -1.17905181e-07, -0.98894012))

----------------------------------------------------
-- 5. SUMMIT PAGE
----------------------------------------------------
local TitleSum = Instance.new("TextLabel")
TitleSum.Parent = SummitPage
TitleSum.Size = UDim2.new(1,0,0,30)
TitleSum.BackgroundTransparency = 1
TitleSum.Text = "⛰️ AUTO SUMMIT FARM"
TitleSum.TextColor3 = Color3.fromRGB(0,170,255)
TitleSum.Font = Enum.Font.GothamBold
TitleSum.TextSize = 13

local summitCFrame = CFrame.new(-6766.44629, 1320.69983, -10083.8037, -0.993305981, 1.64907146e-08, 0.115513086, 1.58947078e-08, 1, -6.08075279e-09, -0.115513086, -4.20400115e-09, -0.993305981)
local bcCFrame = CFrame.new(-6834.84912, 1313.24744, -9902.42285, -1, 0, 0, 0, 1, 0, 0, 0, -1)

AddToggle(SummitPage, "Auto Summit Loop", function(v)
	getgenv().AutoSummitRunning = v
end)

task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			pcall(function()
				local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local hrp = character:WaitForChild("HumanoidRootPart", 5)
				local humanoid = character:WaitForChild("Humanoid", 5)
				
				if hrp and humanoid then
					local cpFolder = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Checkpoint")
					local tpCP = cpFolder and cpFolder:FindFirstChild("TpToCheckpoint")
					
					for i = 1, 20 do
						if not getgenv().AutoSummitRunning then break end
						if tpCP then tpCP:FireServer(i) end
						task.wait(0.2)
					end
					
					if getgenv().AutoSummitRunning then
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						
						hrp.CFrame = summitCFrame
						
						hrp.Anchored = true
						task.wait(0.5)
						hrp.Anchored = false
						
						task.wait(2.5)
					end
					
					if getgenv().AutoSummitRunning then
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						hrp.CFrame = bcCFrame
						task.wait(1)
					end
				end
			end)
			task.wait(0.5)
		else
			task.wait(0.5)
		end
	end
end)

----------------------------------------------------
-- 6. PLAYER PAGE
----------------------------------------------------
local TitlePly = Instance.new("TextLabel")
TitlePly.Parent = PlayerPage
TitlePly.Size = UDim2.new(1,0,0,30)
TitlePly.BackgroundTransparency = 1
TitlePly.Text = "⚡ PLAYER SETTINGS & VISUALS"
TitlePly.TextColor3 = Color3.fromRGB(0,170,255)
TitlePly.Font = Enum.Font.GothamBold
TitlePly.TextSize = 13

local SpeedBox = Instance.new("TextBox")
SpeedBox.Parent = PlayerPage
SpeedBox.Size = UDim2.new(1,0,0,35)
SpeedBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
SpeedBox.PlaceholderText = "Ketik WalkSpeed (Cth: 50)"
SpeedBox.Text = ""
SpeedBox.TextColor3 = Color3.new(1,1,1)
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.TextSize = 13
Instance.new("UICorner", SpeedBox)
SpeedBox.FocusLost:Connect(function()
	local num = tonumber(SpeedBox.Text)
	if num then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = num end) end
end)

AddToggle(PlayerPage, "Anti-AFK", function(v)
	getgenv().AntiAFKRunning = v
end)
LocalPlayer.Idled:Connect(function()
	if getgenv().AntiAFKRunning then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0,0))
	end
end)

local HeadlessBtn = Instance.new("TextButton")
HeadlessBtn.Parent = PlayerPage
HeadlessBtn.Size = UDim2.new(1,0,0,35)
HeadlessBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
HeadlessBtn.Text = "👻 Enable Headless"
HeadlessBtn.TextColor3 = Color3.new(1,1,1)
HeadlessBtn.Font = Enum.Font.GothamBold
HeadlessBtn.TextSize = 13
Instance.new("UICorner", HeadlessBtn)

HeadlessBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local char = LocalPlayer.Character
		if char then
			local head = char:FindFirstChild("Head")
			if head then
				head.Transparency = 1
				for _, child in ipairs(head:GetChildren()) do
					if child:IsA("Decal") then
						child.Transparency = 1
					end
				end
			end
		end
	end)
end)

local FireRgbBtn = Instance.new("TextButton")
FireRgbBtn.Parent = PlayerPage
FireRgbBtn.Size = UDim2.new(1,0,0,35)
FireRgbBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 200)
FireRgbBtn.Text = "🔥🌈 Auto RGB Fire: [OFF]"
FireRgbBtn.TextColor3 = Color3.new(1,1,1)
FireRgbBtn.Font = Enum.Font.GothamBold
FireRgbBtn.TextSize = 13
Instance.new("UICorner", FireRgbBtn)

local autoRgbActive = false

FireRgbBtn.MouseButton1Click:Connect(function()
	autoRgbActive = not autoRgbActive
	FireRgbBtn.Text = "🔥🌈 Auto RGB Fire: " .. (autoRgbActive and "[ON]" or "[OFF]")
	FireRgbBtn.BackgroundColor3 = autoRgbActive and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(150, 0, 200)
	
	pcall(function()
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("Head") then
			local head = char.Head
			local fire = head:FindFirstChild("UbeyHeadFire")
			if autoRgbActive and not fire then
				fire = Instance.new("Fire")
				fire.Name = "UbeyHeadFire"
				fire.Size = 5
				fire.Heat = 15
				fire.Parent = head
			elseif not autoRgbActive and fire then
				fire:Destroy()
			end
		end
	end)
end)

task.spawn(function()
	local colors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 100, 255),
		Color3.fromRGB(255, 0, 255),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 255, 255)
	}
	local index = 1
	while true do
		if autoRgbActive then
			pcall(function()
				local char = LocalPlayer.Character
				if char and char:FindFirstChild("Head") then
					local fire = char.Head:FindFirstChild("UbeyHeadFire")
					if fire then
						index = index % #colors + 1
						fire.Color = colors[index]
						fire.SecondaryColor = colors[(index % #colors) + 1]
					end
				end
			end)
		end
		task.wait(1)
	end
end)

----------------------------------------------------
-- 7. HALO PAGE
----------------------------------------------------
local TitleHalo = Instance.new("TextLabel")
TitleHalo.Parent = HaloPage
TitleHalo.Size = UDim2.new(1,0,0,30)
TitleHalo.BackgroundTransparency = 1
TitleHalo.Text = "👑 HALO & AKSESORIS KEPALA"
TitleHalo.TextColor3 = Color3.fromRGB(0,170,255)
TitleHalo.Font = Enum.Font.GothamBold
TitleHalo.TextSize = 13

local function ApplyHaloToCharacter(haloName)
	getgenv().CurrentSelectedHalo = haloName
	pcall(function()
		local character = LocalPlayer.Character
		local head = character and character:FindFirstChild("Head")
		if not head then return end
		
		for _, v in ipairs(head:GetChildren()) do
			if v.Name == "CustomPlayerHalo" then
				v:Destroy()
			end
		end
		
		local haloSourceFolder = ReplicatedStorage:FindFirstChild("HaloKenyal")
		if haloSourceFolder then
			local targetHaloModel = haloSourceFolder:FindFirstChild(haloName)
			if targetHaloModel then
				local cloneModel = targetHaloModel:Clone()
				cloneModel.Name = "CustomPlayerHalo"
				
				local primaryPart = cloneModel:FindFirstChild("Handle") or cloneModel:FindFirstChild("Antenna") or cloneModel:FindFirstChildWhichIsA("BasePart")
				
				cloneModel.Parent = head
				
				for _, desc in ipairs(cloneModel:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Anchored = false
						desc.CanCollide = false
						desc.Massless = true
					elseif desc:IsA("Script") or desc:IsA("LocalScript") then
						desc:Destroy()
					end
				end
				
				if primaryPart then
					primaryPart.CFrame = head.CFrame * CFrame.new(0, 1.3, 0)
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = head
					weld.Part1 = primaryPart
					weld.Parent = primaryPart
				end
			end
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(1)
	if getgenv().CurrentSelectedHalo then
		ApplyHaloToCharacter(getgenv().CurrentSelectedHalo)
	end
end)

pcall(function()
	local haloSourceFolder = ReplicatedStorage:FindFirstChild("HaloKenyal")
	if haloSourceFolder then
		local clearHaloBtn = Instance.new("TextButton")
		clearHaloBtn.Parent = HaloPage
		clearHaloBtn.Size = UDim2.new(1,0,0,32)
		clearHaloBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
		clearHaloBtn.Text = "❌ Lepas Aksesoris Kepala"
		clearHaloBtn.TextColor3 = Color3.new(1,1,1)
		clearHaloBtn.Font = Enum.Font.GothamBold
		clearHaloBtn.TextSize = 12
		Instance.new("UICorner", clearHaloBtn)
		
		clearHaloBtn.MouseButton1Click:Connect(function()
			getgenv().CurrentSelectedHalo = nil
			pcall(function()
				local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
				if head then
					for _, v in ipairs(head:GetChildren()) do
						if v.Name == "CustomPlayerHalo" then v:Destroy() end
					end
				end
			end)
		end)
		
		for _, haloItem in ipairs(haloSourceFolder:GetChildren()) do
			local name = haloItem.Name
			local haloBtn = Instance.new("TextButton")
			haloBtn.Parent = HaloPage
			haloBtn.Size = UDim2.new(1,0,0,32)
			haloBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
			haloBtn.Text = "👑 " .. name
			haloBtn.TextColor3 = Color3.new(1,1,1)
			haloBtn.Font = Enum.Font.GothamMedium
			haloBtn.TextSize = 12
			Instance.new("UICorner", haloBtn)
			
			haloBtn.MouseButton1Click:Connect(function()
				ApplyHaloToCharacter(name)
			end)
		end
	end
end)

----------------------------------------------------
-- 8. TELEPORT PLAYER PAGE
----------------------------------------------------
local TitleTpPly = Instance.new("TextLabel")
TitleTpPly.Parent = PlayerTpPage
TitleTpPly.Size = UDim2.new(1,0,0,30)
TitleTpPly.BackgroundTransparency = 1
TitleTpPly.Text = "👥 TELEPORT TO OTHER PLAYERS"
TitleTpPly.TextColor3 = Color3.fromRGB(0,170,255)
TitleTpPly.Font = Enum.Font.GothamBold
TitleTpPly.TextSize = 13

local RefreshPlayerBtn = Instance.new("TextButton")
RefreshPlayerBtn.Parent = PlayerTpPage
RefreshPlayerBtn.Size = UDim2.new(1,0,0,35)
RefreshPlayerBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
RefreshPlayerBtn.Text = "🔄 Refresh / Scan Pemain di Server"
RefreshPlayerBtn.TextColor3 = Color3.new(1,1,1)
RefreshPlayerBtn.Font = Enum.Font.GothamBold
RefreshPlayerBtn.TextSize = 12
Instance.new("UICorner", RefreshPlayerBtn)

local PlayerListContainer = Instance.new("ScrollingFrame")
PlayerListContainer.Parent = PlayerTpPage
PlayerListContainer.Size = UDim2.new(1,0,0,210)
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.CanvasSize = UDim2.new(0,0,2,0)
PlayerListContainer.ScrollBarThickness = 3

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = PlayerListContainer
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 5)

local function ScanAndDisplayPlayers()
	for _, child in ipairs(PlayerListContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local pBtn = Instance.new("TextButton")
			pBtn.Parent = PlayerListContainer
			pBtn.Size = UDim2.new(1,0,0,32)
			pBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
			pBtn.Text = "👤 " .. plr.Name .. " (" .. plr.DisplayName .. ")"
			pBtn.TextColor3 = Color3.new(1,1,1)
			pBtn.Font = Enum.Font.GothamMedium
			pBtn.TextSize = 11
			Instance.new("UICorner", pBtn)
			
			pBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local char = plr.Character
					local hrpTarget = char and char:FindFirstChild("HumanoidRootPart")
					local myChar = LocalPlayer.Character
					local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
					
					if hrpTarget and myHrp then
						myHrp.CFrame = hrpTarget.CFrame + Vector3.new(0, 3, 0)
					end
				end)
			end)
		end
	end
end

RefreshPlayerBtn.MouseButton1Click:Connect(function()
	ScanAndDisplayPlayers()
end)

task.spawn(function()
	task.wait(2)
	ScanAndDisplayPlayers()
end)

----------------------------------------------------
-- 9. PRIVACY & ANTI-ADMIN PAGE
----------------------------------------------------
local TitlePrv = Instance.new("TextLabel")
TitlePrv.Parent = PrivacyPage
TitlePrv.Size = UDim2.new(1,0,0,30)
TitlePrv.BackgroundTransparency = 1
TitlePrv.Text = "🛡️ PRIVACY & ANTI-ADMIN"
TitlePrv.TextColor3 = Color3.fromRGB(0,170,255)
TitlePrv.Font = Enum.Font.GothamBold
TitlePrv.TextSize = 13

local FakeNameBox = Instance.new("TextBox")
FakeNameBox.Parent = PrivacyPage
FakeNameBox.Size = UDim2.new(1,0,0,35)
FakeNameBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
FakeNameBox.PlaceholderText = "Nama Samaran (Cth: UBEY HUB)"
FakeNameBox.Text = "UBEY HUB"
FakeNameBox.TextColor3 = Color3.new(1,1,1)
FakeNameBox.Font = Enum.Font.Gotham
FakeNameBox.TextSize = 12
Instance.new("UICorner", FakeNameBox)
FakeNameBox.FocusLost:Connect(function()
	getgenv().FakeNameInput = FakeNameBox.Text
end)

AddToggle(PrivacyPage, "Privacy Mode (Hide Name & Summit)", function(v)
	getgenv().HideNameRunning = v
	if v then
		task.spawn(function()
			while getgenv().HideNameRunning do
				pcall(function()
					local fakeName = getgenv().FakeNameInput or "UBEY HUB"
					local character = LocalPlayer.Character
					if character then
						local head = character:FindFirstChild("Head")
						if head then
							for _, child in ipairs(head:GetDescendants()) do
								if child:IsA("TextLabel") or child:IsA("TextMesh") then
									local txt = child.Text
									if string.find(txt, LocalPlayer.Name) or string.find(txt, LocalPlayer.DisplayName) then
										child.Text = fakeName
									elseif string.find(string.lower(txt), "summit") or (tonumber(txt) ~= nil and tonumber(txt) > 0) then
										child.Text = ""
									end
								end
							end
						end
					end
				end)
				task.wait(1)
			end
		end)
	end
end)

local AntiAdminToggleBtn = Instance.new("TextButton")
AntiAdminToggleBtn.Parent = PrivacyPage
AntiAdminToggleBtn.Size = UDim2.new(1,0,0,35)
AntiAdminToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.AntiAdminEnabled and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(30, 30, 40)
AntiAdminToggleBtn.Text = "  Anti-Admin Protect (MPG Group): " .. (getgenv().UbeyConfig.AntiAdminEnabled and "[ON]" or "[OFF]")
AntiAdminToggleBtn.TextColor3 = Color3.new(1,1,1)
AntiAdminToggleBtn.Font = Enum.Font.Gotham
AntiAdminToggleBtn.TextSize = 13
AntiAdminToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", AntiAdminToggleBtn)

AntiAdminToggleBtn.MouseButton1Click:Connect(function()
	getgenv().UbeyConfig.AntiAdminEnabled = not getgenv().UbeyConfig.AntiAdminEnabled
	local active = getgenv().UbeyConfig.AntiAdminEnabled
	AntiAdminToggleBtn.Text = "  Anti-Admin Protect (MPG Group): " .. (active and "[ON]" or "[OFF]")
	AntiAdminToggleBtn.BackgroundColor3 = active and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(30, 30, 40)
	SaveConfig()
end)

local function CheckPlayerIsAdmin(player)
	local groupId = getgenv().UbeyConfig.TargetGroupId or 7019573
	local success, rank = pcall(function()
		return player:GetRankInGroup(groupId)
	end)
	
	if success and rank then
		if rank > 1 then
			return true
		end
	end
	return false
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		task.spawn(function()
			task.wait(1.5)
			if getgenv().UbeyConfig.AntiAdminEnabled then
				if CheckPlayerIsAdmin(player) then
					warn("🚨 [ANTI-ADMIN]: Staff MPG Community terdeteksi join: " .. player.Name)
					game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
				end
			end
		end)
	end
end)

task.spawn(function()
	task.wait(2)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and getgenv().UbeyConfig.AntiAdminEnabled then
			if CheckPlayerIsAdmin(player) then
				warn("🚨 [ANTI-ADMIN]: Staff MPG Community sudah ada di server: " .. player.Name)
				game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
			end
		end
	end
end)

----------------------------------------------------
-- 10. SETTINGS, CONFIG & CREDITS PAGE
----------------------------------------------------
local TitleSet = Instance.new("TextLabel")
TitleSet.Parent = SettingsPage
TitleSet.Size = UDim2.new(1,0,0,30)
TitleSet.BackgroundTransparency = 1
TitleSet.Text = "⚙️ SETTINGS & CONFIGURATION"
TitleSet.TextColor3 = Color3.fromRGB(0,170,255)
TitleSet.Font = Enum.Font.GothamBold
TitleSet.TextSize = 13

local AntiLagBtn = Instance.new("TextButton")
AntiLagBtn.Parent = SettingsPage
AntiLagBtn.Size = UDim2.new(1,0,0,35)
AntiLagBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
AntiLagBtn.Text = "⚡ Aktifkan Extreme Anti-Lag (AFK Mode)"
AntiLagBtn.TextColor3 = Color3.new(1,1,1)
AntiLagBtn.Font = Enum.Font.GothamBold
AntiLagBtn.TextSize = 12
Instance.new("UICorner", AntiLagBtn)

AntiLagBtn.MouseButton1Click:Connect(function()
	pcall(function()
		-- Pengaturan Lighting Ekstrem
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 999999
		Lighting.Brightness = 1
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

		pcall(function()
			for _, v in ipairs(Lighting:GetChildren()) do
				if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
					v.Enabled = false
				end
			end
		end)

		-- Pembersihan Workspace & Material Objek
		for _, v in ipairs(Workspace:GetDescendants()) do
			pcall(function()
				if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Explosion") then
					v:Destroy()
				elseif v:IsA("BasePart") then
					v.Material = Enum.Material.SmoothPlastic
					v.Reflectance = 0
					v.CastShadow = false
				elseif v:IsA("Decal") or v:IsA("Texture") then
					v:Destroy()
				end
			end)
		end

		-- Matikan Dekorasi Terrain / Rumput & Air
		pcall(function()
			local terrain = Workspace:FindFirstChildOfClass("Terrain")
			if terrain then
				terrain.WaterWaveSize = 0
				terrain.WaterWaveSpeed = 0
				terrain.WaterTransparency = 1
				terrain.WaterReflectance = 0
				pcall(function()
					sethiddenproperty(terrain, "Decoration", false)
				end)
			end
		end)

		-- Pantau objek baru agar otomatis dibersihkan saat AFK lama
		Workspace.DescendantAdded:Connect(function(v)
			pcall(function()
				if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
					v:Destroy()
				elseif v:IsA("BasePart") then
					v.Material = Enum.Material.SmoothPlastic
					v.Reflectance = 0
					v.CastShadow = false
				elseif v:IsA("Decal") or v:IsA("Texture") then
					v:Destroy()
				end
			end)
		end)

		-- Task berkala untuk membersihkan memori (Garbage Collector)
		task.spawn(function()
			while true do
				pcall(function()
					game:GetService("ContentProvider"):PreloadAsync({})
					if gcinfo then
						-- Membantu stabilitas memori HP saat AFK berjam-jam
					end
				end)
				task.wait(60)
			end
		end)

		AntiLagBtn.Text = "⚡ Extreme Anti-Lag Aktif (Safe for AFK!)"
		AntiLagBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	end)
end)

local AutoExecToggleBtn = Instance.new("TextButton")
AutoExecToggleBtn.Parent = SettingsPage
AutoExecToggleBtn.Size = UDim2.new(1,0,0,35)
AutoExecToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.AutoExecuteEnabled and Color3.fromRGB(0, 100, 180) or Color3.fromRGB(30, 30, 40)
AutoExecToggleBtn.Text = "  Auto Execute (Teleport): " .. (getgenv().UbeyConfig.AutoExecuteEnabled and "[ON]" or "[OFF]")
AutoExecToggleBtn.TextColor3 = Color3.new(1,1,1)
AutoExecToggleBtn.Font = Enum.Font.Gotham
AutoExecToggleBtn.TextSize = 13
AutoExecToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", AutoExecToggleBtn)

AutoExecToggleBtn.MouseButton1Click:Connect(function()
	getgenv().UbeyConfig.AutoExecuteEnabled = not getgenv().UbeyConfig.AutoExecuteEnabled
	AutoExecToggleBtn.Text = "  Auto Execute (Teleport): " .. (getgenv().UbeyConfig.AutoExecuteEnabled and "[ON]" or "[OFF]")
	AutoExecToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.AutoExecuteEnabled and Color3.fromRGB(0, 100, 180) or Color3.fromRGB(30, 30, 40)
	SaveConfig()
end)

local SaveConfigBtn = Instance.new("TextButton")
SaveConfigBtn.Parent = SettingsPage
SaveConfigBtn.Size = UDim2.new(1,0,0,35)
SaveConfigBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
SaveConfigBtn.Text = "💾 Simpan Konfigurasi (Save Config)"
SaveConfigBtn.TextColor3 = Color3.new(1,1,1)
SaveConfigBtn.Font = Enum.Font.GothamBold
SaveConfigBtn.TextSize = 13
Instance.new("UICorner", SaveConfigBtn)

SaveConfigBtn.MouseButton1Click:Connect(function()
	SaveConfig()
	SaveConfigBtn.Text = "✅ Config Berhasil Disimpan!"
	task.wait(1.5)
	SaveConfigBtn.Text = "💾 Simpan Konfigurasi (Save Config)"
end)

local ResetConfigBtn = Instance.new("TextButton")
ResetConfigBtn.Parent = SettingsPage
ResetConfigBtn.Size = UDim2.new(1,0,0,35)
ResetConfigBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ResetConfigBtn.Text = "🔄 Reset Konfigurasi & Clear Key"
ResetConfigBtn.TextColor3 = Color3.new(1,1,1)
ResetConfigBtn.Font = Enum.Font.GothamBold
ResetConfigBtn.TextSize = 13
Instance.new("UICorner", ResetConfigBtn)

ResetConfigBtn.MouseButton1Click:Connect(function()
	ResetConfig()
	ResetConfigBtn.Text = "🔄 Config & Key Direset!"
	task.wait(1.5)
	ResetConfigBtn.Text = "🔄 Reset Konfigurasi & Clear Key"
end)

local TheCloseBtn = Instance.new("TextButton")
TheCloseBtn.Parent = SettingsPage
TheCloseBtn.Size = UDim2.new(1,0,0,35)
TheCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
TheCloseBtn.Text = "Tutup / Hide UI"
TheCloseBtn.TextColor3 = Color3.new(1,1,1)
TheCloseBtn.Font = Enum.Font.GothamBold
TheCloseBtn.TextSize = 13
Instance.new("UICorner", TheCloseBtn)
TheCloseBtn.MouseButton1Click:Connect(function() Main.Visible = fals
