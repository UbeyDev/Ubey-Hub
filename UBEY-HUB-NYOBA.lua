-- ==============================================================================
-- UBEY HUB V3 | FULL VIP PREMIUM SCRIPT (INSTANT TELEPORT SUMMIT VERSION)
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
	TargetGroupId = 7019573,
	WebhookEnabled = false,
	WebhookUrl = ""
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
			local data = HttpService:JSONEncode(content)
			if data then
				if data.BiteDelay then getgenv().UbeyConfig.BiteDelay = data.BiteDelay end
				if data.SelectedSpot then getgenv().UbeyConfig.SelectedSpot = data.SelectedSpot end
				if data.AutoSellTimer then getgenv().UbeyConfig.AutoSellTimer = data.AutoSellTimer end
				if data.AutoExecuteEnabled ~= nil then getgenv().UbeyConfig.AutoExecuteEnabled = data.AutoExecuteEnabled end
				if data.AntiAdminEnabled ~= nil then getgenv().UbeyConfig.AntiAdminEnabled = data.AntiAdminEnabled end
				if data.TargetGroupId then getgenv().UbeyConfig.TargetGroupId = data.TargetGroupId end
				if data.WebhookEnabled ~= nil then getgenv().UbeyConfig.WebhookEnabled = data.WebhookEnabled end
				if data.WebhookUrl then getgenv().UbeyConfig.WebhookUrl = data.WebhookUrl end
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
			TargetGroupId = 7019573,
			WebhookEnabled = false,
			WebhookUrl = ""
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
	return tostring(hwid or ("UNKNOWN_DEVICE_" .. tostring(LocalPlayer.UserId)))
end

local CurrentHWID = GetDeviceHWID()

------------------------------------------------------------------
-- DISCORD WEBHOOK SYSTEM (STRICT SECRET & FORGOTTEN ONLY)
------------------------------------------------------------------
local function SendFilteredWebhook(fishName, fishRarity, fishMutation, fishGrade, fishWeight, fishChance)
	pcall(function()
		if not getgenv().UbeyConfig.WebhookEnabled then return end
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then return end
		
		local targetName = tostring(fishName or "Unknown Fish")
		local targetRarity = tostring(fishRarity or "Common")
		local targetMutation = tostring(fishMutation or "Normal")
		local targetGrade = tostring(fishGrade or "N/A")
		local targetWeight = tostring(fishWeight or "0") .. " kg"
		local targetChance = tostring(fishChance or "N/A")
		
		local targetRarityLower = string.lower(targetRarity)
		
		if targetRarityLower == "secret" or targetRarityLower == "forgotten" then
			local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
			if not requestFunc then return end
			
			local data = {
				["content"] = "@everyone 🚨 **FISH SECRET / FORGOTTEN CATCH!**",
				["embeds"] = {
					{
						["title"] = "👑 Ubey Hub V3 - Secret & Forgotten Tracker!",
						["description"] = "Pemain **" .. LocalPlayer.Name .. "** baru saja mendapatkan ikan langka!",
						["color"] = 16711935,
						["fields"] = {
							{ ["name"] = "🐟 Nama Ikan", ["value"] = targetName, ["inline"] = true },
							{ ["name"] = "⭐ Rarity", ["value"] = targetRarity, ["inline"] = true },
							{ ["name"] = "🧬 Mutasi", ["value"] = targetMutation, ["inline"] = true },
							{ ["name"] = "🏆 Grade", ["value"] = targetGrade, ["inline"] = true },
							{ ["name"] = "⚖️ Berat (Weight)", ["value"] = targetWeight, ["inline"] = true },
							{ ["name"] = "🎲 Chance", ["value"] = targetChance, ["inline"] = true }
						},
						["footer"] = { ["text"] = "Ubey Hub V3 • Secret & Forgotten Notification" },
						["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
					}
				}
			}
			
			requestFunc({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(data)
			})
		end
	end)
end

------------------------------------------------------------------
-- REAL-TIME CATCH MONITOR
------------------------------------------------------------------
local hookedRemotes = {}

local function ProcessNotifyClient(actionType, fishDataArg)
	if actionType == "GotFish" and type(fishDataArg) == "table" then
		pcall(function()
			local name = fishDataArg.baseName or fishDataArg.originalName or "Unknown Fish"
			local rarity = fishDataArg.rarity or "Common"
			local mutation = fishDataArg.mutation or "Normal"
			local grade = fishDataArg.grade or "N/A"
			local weight = fishDataArg.weight or "0"
			local chance = fishDataArg.chance or "N/A"
			
			if name ~= "Unknown Fish" and name ~= "" then
				SendFilteredWebhook(name, rarity, mutation, grade, weight, chance)
			end
		end)
	end
end

local function AttachNotifyHook(remote)
	if remote and remote:IsA("RemoteEvent") and not hookedRemotes[remote] then
		hookedRemotes[remote] = true
		remote.OnClientEvent:Connect(ProcessNotifyClient)
	end
end

local function ListenToFishCatch()
	pcall(function()
		for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
			if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then
				AttachNotifyHook(v)
			end
		end

		local function ScanCharacter(char)
			if not char then return end
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then
					AttachNotifyHook(v)
				end
			end
			char.DescendantAdded:Connect(function(v)
				if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then
					AttachNotifyHook(v)
				end
			end)
		end

		if LocalPlayer.Character then ScanCharacter(LocalPlayer.Character) end
		LocalPlayer.CharacterAdded:Connect(ScanCharacter)
		
		ReplicatedStorage.DescendantAdded:Connect(function(v)
			if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then
				AttachNotifyHook(v)
			end
		end)
	end)
end

task.spawn(function()
	task.wait(1)
	ListenToFishCatch()
end)

------------------------------------------------------------------
-- AUTO RECONNECT & AUTO EXECUTE
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
			loadstring(game:HttpGet("https://raw.githubusercontent.com/UbeyDev/Ubey-Hub/refs/heads/main/UBEY-HUB-NYOBA.lua?v=" .. math.random(1, 100000)))()
		]])
	end
end)

-- GLOBAL STATES
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
getgenv().AutoDetectCoreEvent = false

getgenv().LoopSpotEnabled = false
getgenv().SpotLoopConfig = {
	["Spot Mancing Jembatan"] = { Enabled = false, Timer = "10" },
	["Spot Mancing Core"] = { Enabled = false, Timer = "10" },
	["Spot Mancing Ikan Anomali"] = { Enabled = false, Timer = "10" }
}

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

------------------------------------------------------------------
-- POST-UPDATE AUTO FISHING FUNCTION
------------------------------------------------------------------
local function RunAutoFishCycle(remoteFolder)
	pcall(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		OptimizeRodSettings()
		
		remoteFolder.CastEvent:FireServer(true)
		task.wait(0.05)
		remoteFolder.CastEvent:FireServer(false, 100, hrp.CFrame.LookVector)
		
		local hooked = false
		local conn = remoteFolder.NotifyClient.OnClientEvent:Connect(function(actionType)
			if actionType == "Bite" or actionType == "Hook" then hooked = true end
		end)
		
		local start = tick()
		while not hooked and getgenv().AutoFishingEventRunning do
			if tick() - start > 8 then break end
			task.wait(0.05)
		end
		if conn then conn:Disconnect() end
		
		if hooked and getgenv().AutoFishingEventRunning then
			task.wait(tonumber(getgenv().BiteDelayInput) or 0.5)
			
			local tandaSeruRemote = remoteFolder:FindFirstChild("TandaSeruBersama")
			if tandaSeruRemote then
				local color1 = Color3.fromRGB(23, 255, 151)
				local color2 = Color3.fromRGB(20, 20, 20)
				local seq = ColorSequence.new({
					ColorSequenceKeypoint.new(0, color1),
					ColorSequenceKeypoint.new(1, color1)
				})
				tandaSeruRemote:FireServer(color1, color2, seq, 1.5)
			end
			
			task.wait(0.1)
			remoteFolder.MiniGame:FireServer(true)
			task.wait(0.3)
		end
	end)
end

local function TriggerSellToNpc()
	pcall(function()
		local character = LocalPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local currentSpotCFrame = hrp.CFrame
		hrp.CFrame = NpcSellCFrame + Vector3.new(0, 5, 0)
		task.wait(0.8)
		local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing")
		local jualSemua = mancing and mancing:FindFirstChild("JualSemua")
		if jualSemua then jualSemua:InvokeServer() end
		task.wait(0.8)
		if getgenv().AutoFishingEventRunning then
			hrp.CFrame = currentSpotCFrame
		end
	end)
end

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
				if active and string.lower(rName) == fishRarityLower then shouldFav = true end
			end
			for mName, active in pairs(getgenv().FavMutations) do
				if active and string.find(fishMutationLower, string.lower(mName)) then shouldFav = true end
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
		if getgenv().AutoFavoriteRunning then ProcessAutoFavorite() end
		task.wait(2.5)
	end
end)

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
					if active and string.lower(rName) == fishRarityLower then shouldUnfav = true end
				end
				for mName, active in pairs(getgenv().UnfavMutations) do
					if active and string.find(fishMutationLower, string.lower(mName)) then shouldUnfav = true end
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
	local oldGui = PlayerGui:FindFirstChild("UbeyHub")
	if oldGui then oldGui:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

local function MakeDraggable(guiObject, handleObject)
	handleObject = handleObject or guiObject
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	handleObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handleObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
end

----------------------------------------------------
-- KEY SYSTEM UI
----------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,185)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-92)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
KeyFrame.Visible = false
MakeDraggable(KeyFrame)

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0,15)
keyCorner.Parent = KeyFrame

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
local kbCorner = Instance.new("UICorner")
kbCorner.Parent = KeyBox

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Parent = KeyFrame
SubmitKeyBtn.Size = UDim2.new(0,165,0,35)
SubmitKeyBtn.Position = UDim2.new(0,20,0,110)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Perangkat"
SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextSize = 12
local skCorner = Instance.new("UICorner")
skCorner.Parent = SubmitKeyBtn

local GetKeyDiscordBtn = Instance.new("TextButton")
GetKeyDiscordBtn.Parent = KeyFrame
GetKeyDiscordBtn.Size = UDim2.new(0,165,0,35)
GetKeyDiscordBtn.Position = UDim2.new(0,195,0,110)
GetKeyDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GetKeyDiscordBtn.Text = "Get Key via Discord"
GetKeyDiscordBtn.TextColor3 = Color3.new(1,1,1)
GetKeyDiscordBtn.Font = Enum.Font.GothamBold
GetKeyDiscordBtn.TextSize = 12
local gkCorner = Instance.new("UICorner")
gkCorner.Parent = GetKeyDiscordBtn

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
-- MAIN HUB UI
----------------------------------------------------
local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Visible = false
Main.Size = UDim2.new(0,550,0,320)
Main.Position = UDim2.new(0.5,-275,0.5,-160)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Main.ClipsDescendants = true
MakeDraggable(Main)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0,18)
mainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(0,170,255)

local ControlsFrame = Instance.new("Frame")
ControlsFrame.Parent = Main
ControlsFrame.Size = UDim2.new(0, 65, 0, 30)
ControlsFrame.Position = UDim2.new(1, -70, 0, 5)
ControlsFrame.BackgroundTransparency = 1
ControlsFrame.ZIndex = 10

local ControlLayout = Instance.new("UIListLayout")
ControlLayout.Parent = ControlsFrame
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ControlLayout.Padding = UDim.new(0, 5)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = ControlsFrame
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.ZIndex = 11
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = ControlsFrame
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.ZIndex = 11
local clsCorner = Instance.new("UICorner")
clsCorner.CornerRadius = UDim.new(0, 6)
clsCorner.Parent = CloseBtn

local PingLabel = Instance.new("TextLabel")
PingLabel.Parent = Main
PingLabel.Size = UDim2.new(0,150,0,25)
PingLabel.Position = UDim2.new(1,-225,0,7)
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
local sbCorner = Instance.new("UICorner")
sbCorner.Parent = Sidebar

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

local Content = Instance.new("Frame")
Content.Parent = Main
Content.Position = UDim2.new(0,150,0,30)
Content.Size = UDim2.new(1,-160,1,-40)
Content.BackgroundTransparency = 1

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	MinimizeBtn.Text = isMinimized and "+" or "-"
	Main:TweenSize(isMinimized and UDim2.new(0,550,0,38) or UDim2.new(0,550,0,320), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
	Sidebar.Visible = not isMinimized
	Content.Visible = not isMinimized
	PingLabel.Visible = not isMinimized
end)

CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local function CreateNavButton(text, yPos)
	local btn = Instance.new("TextButton")
	btn.Parent = Sidebar
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 12
	local corner = Instance.new("UICorner")
	corner.Parent = btn
	return btn
end

local HomeBtn = CreateNavButton("Fishing & Sell", 60)
local FavoriteBtn = CreateNavButton("⭐ Favorite", 95)
local GalatamaBtn = CreateNavButton("Galatama", 130)
local TeleportShopBtn = CreateNavButton("Teleport Shop", 165)
local SummitBtn = CreateNavButton("Summit", 200)
local PlayerMenuBtn = CreateNavButton("Player", 235)
local HaloMenuBtn = CreateNavButton("Halo Kepala", 270)
local PlayerTpBtn = CreateNavButton("Teleport Player", 305)
local PrivacyBtn = CreateNavButton("Privacy", 340)
local SettingsBtn = CreateNavButton("Settings", 375)
local CreditsBtn = CreateNavButton("Credits", 410)

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
	local c = Instance.new("UICorner")
	c.Parent = b
	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = "  " .. text .. (state and " [ON]" or " [OFF]")
		b.BackgroundColor3 = state and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
		callback(state)
	end)
end

----------------------------------------------------
-- KEY VALIDATION
----------------------------------------------------
GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function() if setclipboard then setclipboard("https://discord.gg/YXuYeEpnXE") end end)
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
					Headers = { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY, ["Content-Type"] = "application/json" }
				})
				return res.Body
			else
				return HttpService:GetAsync(SUPABASE_URL .. HttpService:UrlEncode(enteredKey), false, { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY })
			end
		end)
		
		if success and response then
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
			if decodeSuccess and data and #data > 0 then
				local record = data[1]
				if record.status == false or record.status == "inactive" or record.status == "used" then
					if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Key sudah tidak aktif!" end
					KeyFrame.Visible = true
					return
				end
				if record.hwid_value and record.hwid_value ~= "" and record.hwid_value ~= CurrentHWID then
					if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Key terikat di perangkat lain!" end
					KeyFrame.Visible = true
					return
				end
				pcall(function() if writefile then writefile(KEY_FILE, enteredKey) end end)
				getgenv().KeyVerified = true
				KeyFrame.Visible = false
				Main.Visible = true
			else
				if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Key Salah atau Tidak Ditemukan!" end
				KeyFrame.Visible = true
			end
		else
			if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Gagal terhubung ke database." end
			KeyFrame.Visible = true
		end
	end)
end

SubmitKeyBtn.MouseButton1Click:Connect(function() ValidateKey(KeyBox.Text, false) end)
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
-- 1. FISHING PAGE
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
SpotLabel.Text = "Lokasi Saat Ini: " .. getgenv().SelectedFishingSpot
SpotLabel.TextColor3 = Color3.new(1,1,1)
SpotLabel.Font = Enum.Font.Gotham
SpotLabel.TextSize = 12

local ChangeSpotBtn = Instance.new("TextButton")
ChangeSpotBtn.Parent = FishingPage
ChangeSpotBtn.Size = UDim2.new(1,0,0,32)
ChangeSpotBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
ChangeSpotBtn.Text = "Ganti Spot Manual"
ChangeSpotBtn.TextColor3 = Color3.new(1,1,1)
ChangeSpotBtn.Font = Enum.Font.GothamMedium
ChangeSpotBtn.TextSize = 12
local csCorner = Instance.new("UICorner")
csCorner.Parent = ChangeSpotBtn

local spotList = {"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}
local spotIndex = 1
ChangeSpotBtn.MouseButton1Click:Connect(function()
	spotIndex = spotIndex % #spotList + 1
	getgenv().SelectedFishingSpot = spotList[spotIndex]
	SpotLabel.Text = "Lokasi Saat Ini: " .. getgenv().SelectedFishingSpot
	getgenv().UbeyConfig.SelectedSpot = getgenv().SelectedFishingSpot
	SaveConfig()
end)

AddToggle(FishingPage, "Smart Auto Fishing + Teleport", function(v)
	getgenv().AutoFishingEventRunning = v
	if v then
		pcall(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)
			if hrp then hrp.CFrame = FishingSpots[getgenv().SelectedFishingSpot] + Vector3.new(0, 5, 0) end
		end)
		task.spawn(function()
			while getgenv().AutoFishingEventRunning do
				pcall(function()
					local rod = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Withering Rod")
					if rod and rod:FindFirstChild("Mechanics") then
						local remoteFolder = rod.Mechanics:FindFirstChild("Remotes")
						if remoteFolder then
							RunAutoFishCycle(remoteFolder)
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
		task.spawn(function()
			while getgenv().AutoFishingEventRunning do
				pcall(function()
					local rod = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Withering Rod")
					if rod and rod:FindFirstChild("Mechanics") then
						local remoteFolder = rod.Mechanics:FindFirstChild("Remotes")
						if remoteFolder then
							RunAutoFishCycle(remoteFolder)
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
local bdCorner = Instance.new("UICorner")
bdCorner.Parent = BiteDelayBox

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
				if ((tick() - lastSellTime) / 60) >= (tonumber(getgenv().AutoSellTimerInput) or 5) then
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
local stCorner = Instance.new("UICorner")
stCorner.Parent = SellTimerBox

SellTimerBox.FocusLost:Connect(function()
	getgenv().AutoSellTimerInput = SellTimerBox.Text
	getgenv().UbeyConfig.AutoSellTimer = SellTimerBox.Text
	SaveConfig()
end)

----------------------------------------------------
-- SYSTEM ROTASI / LOOP SPOT MANCING
----------------------------------------------------
local TitleLoop = Instance.new("TextLabel")
TitleLoop.Parent = FishingPage
TitleLoop.Size = UDim2.new(1,0,0,25)
TitleLoop.BackgroundTransparency = 1
TitleLoop.Text = "⏳ ROTASI AUTO SPOT MANCING (TIMER)"
TitleLoop.TextColor3 = Color3.fromRGB(0,255,170)
TitleLoop.Font = Enum.Font.GothamBold
TitleLoop.TextSize = 13

AddToggle(FishingPage, "Aktifkan Loop Spot Mancing (Timer)", function(v) getgenv().LoopSpotEnabled = v end)

local function CreateSpotTimerSetting(parent, spotName)
	local frame = Instance.new("Frame")
	frame.Parent = parent
	frame.Size = UDim2.new(1,0,0,35)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,40)
	local fc = Instance.new("UICorner")
	fc.Parent = frame

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Parent = frame
	toggleBtn.Size = UDim2.new(0.65,0,1,0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = "  " .. spotName .. " [OFF]"
	toggleBtn.TextColor3 = Color3.new(1,1,1)
	toggleBtn.Font = Enum.Font.Gotham
	toggleBtn.TextSize = 11
	toggleBtn.TextXAlignment = Enum.TextXAlignment.Left

	local timeBox = Instance.new("TextBox")
	timeBox.Parent = frame
	timeBox.Size = UDim2.new(0.3, -5, 0, 25)
	timeBox.Position = UDim2.new(0.7, 0, 0, 5)
	timeBox.BackgroundColor3 = Color3.fromRGB(45,45,55)
	timeBox.Text = getgenv().SpotLoopConfig[spotName].Timer
	timeBox.PlaceholderText = "Menit"
	timeBox.TextColor3 = Color3.fromRGB(0,170,255)
	timeBox.Font = Enum.Font.GothamBold
	timeBox.TextSize = 11
	local tc = Instance.new("UICorner")
	tc.Parent = timeBox

	toggleBtn.MouseButton1Click:Connect(function()
		local cur = not getgenv().SpotLoopConfig[spotName].Enabled
		getgenv().SpotLoopConfig[spotName].Enabled = cur
		toggleBtn.Text = "  " .. spotName .. (cur and " [ON]" or " [OFF]")
		toggleBtn.TextColor3 = cur and Color3.fromRGB(0,255,150) or Color3.new(1,1,1)
	end)

	timeBox.FocusLost:Connect(function() getgenv().SpotLoopConfig[spotName].Timer = timeBox.Text end)
end

CreateSpotTimerSetting(FishingPage, "Spot Mancing Jembatan")
CreateSpotTimerSetting(FishingPage, "Spot Mancing Core")
CreateSpotTimerSetting(FishingPage, "Spot Mancing Ikan Anomali")

task.spawn(function()
	local spotOrder = {"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}
	while true do
		if getgenv().LoopSpotEnabled and not getgenv().AutoDetectCoreEvent then
			for _, name in ipairs(spotOrder) do
				local cfg = getgenv().SpotLoopConfig[name]
				if getgenv().LoopSpotEnabled and cfg and cfg.Enabled then
					getgenv().SelectedFishingSpot = name
					SpotLabel.Text = "Lokasi Saat Ini: " .. name
					pcall(function()
						local character = LocalPlayer.Character
						local hrp = character and character:FindFirstChild("HumanoidRootPart")
						local targetCFrame = FishingSpots[name]
						if hrp and targetCFrame then hrp.CFrame = targetCFrame + Vector3.new(0, 5, 0) end
					end)
					local duration = (tonumber(cfg.Timer) or 10) * 60
					local timerStart = tick()
					while getgenv().LoopSpotEnabled and cfg.Enabled and (tick() - timerStart < duration) do
						task.wait(1)
					end
				end
			end
		end
		task.wait(1)
	end
end)

----------------------------------------------------
-- DROPDOWN BUILDER (UNIVERSAL MULTI-SELECT)
----------------------------------------------------
local function CreateMultiSelectDropdown(parent, titleText, optionsTable, targetStateTable)
	local container = Instance.new("Frame")
	container.Parent = parent
	container.Size = UDim2.new(1,0,0,40)
	container.BackgroundColor3 = Color3.fromRGB(30,30,40)
	container.ClipsDescendants = true
	local cc = Instance.new("UICorner")
	cc.Parent = container

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
		for _, active in pairs(targetStateTable) do if active then selectedCount = selectedCount + 1 end end
		if selectedCount == 0 then countLabel.Text = "None 🔽"
		elseif selectedCount == #optionsTable then countLabel.Text = "All (" .. selectedCount .. ") 🔽"
		else countLabel.Text = selectedCount .. " Selected 🔽" end
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
	local saCorner = Instance.new("UICorner")
	saCorner.Parent = selectAllBtn

	local allState = false
	selectAllBtn.MouseButton1Click:Connect(function()
		allState = not allState
		for _, optName in ipairs(optionsTable) do targetStateTable[optName] = allState end
		for optName, btn in pairs(itemButtons) do
			btn.BackgroundColor3 = allState and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
			btn.Text = "  " .. optName .. (allState and "  [✓]" or "  [ ]")
		end
		UpdateSummary()
		SaveConfig()
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
		local obc = Instance.new("UICorner")
		obc.Parent = optBtn

		itemButtons[optName] = optBtn

		optBtn.MouseButton1Click:Connect(function()
			targetStateTable[optName] = not targetStateTable[optName]
			optBtn.BackgroundColor3 = targetStateTable[optName] and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
			optBtn.Text = "  " .. optName .. (targetStateTable[optName] and "  [✓]" or "  [ ]")
			UpdateSummary()
			SaveConfig()
		end)
	end

	UpdateSummary()

	local isOpen = false
	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		container:TweenSize(isOpen and UDim2.new(1,0,0, 45 + ((#optionsTable + 1) * 32)) or UDim2.new(1,0,0,40), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
	end)
end

----------------------------------------------------
-- 2. FAVORITE PAGE
----------------------------------------------------
local TitleFav = Instance.new("TextLabel")
TitleFav.Parent = FavoritePage
TitleFav.Size = UDim2.new(1,0,0,25)
TitleFav.BackgroundTransparency = 1
TitleFav.Text = "⭐ AUTO FAVORITE FILTER"
TitleFav.TextColor3 = Color3.fromRGB(0,170,255)
TitleFav.Font = Enum.Font.GothamBold
TitleFav.TextSize = 13

AddToggle(FavoritePage, "AUTO FAVORITE", function(v) getgenv().AutoFavoriteRunning = v end)

local rarityList = {"Common", "UnCommon", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Forgotten"}
local mutationList = {
	"Galaxy", "Corrupt", "Gemstone", "Ghost", "Lightning", "Fairy Dust", 
	"Gold", "Midnight", "Radioactive", "Stone", "Holographic", "Albino", "Sandy", "Cosmic",
	"Elemental", "Festive", "8-Bit", "Bloodmoon", "Abyssal", "Strawberry", "Void", "Cupid"
}

CreateMultiSelectDropdown(FavoritePage, "Fav Filter Rarity", rarityList, getgenv().FavRarities)
CreateMultiSelectDropdown(FavoritePage, "Fav Filter Mutasi", mutationList, getgenv().FavMutations)

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
UnfavFilterBtn.Text = "🎯 UNFAVORITE BY FILTER"
UnfavFilterBtn.TextColor3 = Color3.new(1,1,1)
UnfavFilterBtn.Font = Enum.Font.GothamBold
UnfavFilterBtn.TextSize = 12
local ufc = Instance.new("UICorner")
ufc.Parent = UnfavFilterBtn
UnfavFilterBtn.MouseButton1Click:Connect(function() UnfavoriteByFilter() end)

local UnfavBtn = Instance.new("TextButton")
UnfavBtn.Parent = FavoritePage
UnfavBtn.Size = UDim2.new(1,0,0,38)
UnfavBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
UnfavBtn.Text = "🚨 UNFAVORITE ALL FISH"
UnfavBtn.TextColor3 = Color3.new(1,1,1)
UnfavBtn.Font = Enum.Font.GothamBold
UnfavBtn.TextSize = 12
local uac = Instance.new("UICorner")
uac.Parent = UnfavBtn
UnfavBtn.MouseButton1Click:Connect(function() UnfavoriteAllFish() end)

----------------------------------------------------
-- 3. GALATAMA PAGE (DENGAN AUTO DETEKSI CORE EVENT)
----------------------------------------------------
local TitleGal = Instance.new("TextLabel")
TitleGal.Parent = GalatamaPage
TitleGal.Size = UDim2.new(1,0,0,30)
TitleGal.BackgroundTransparency = 1
TitleGal.Text = "🏆 GALATAMA & CORE EVENT UTILITIES"
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
local tgc = Instance.new("UICorner")
tgc.Parent = TeleportGalatamaBtn
TeleportGalatamaBtn.MouseButton1Click:Connect(function()
	pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-8008.12744, 1227.96838, -6091.92627) + Vector3.new(0, 5, 0) end)
end)

AddToggle(GalatamaPage, "Aktifkan Auto Join Galatama", function(v)
	getgenv().AutoGalatamaRunning = v
	if v then
		task.spawn(function()
			while getgenv().AutoGalatamaRunning do
				pcall(function() 
					local galatamaRemote = ReplicatedStorage:FindFirstChild("Remote") 
						and ReplicatedStorage.Remote:FindFirstChild("Galatama") 
						and ReplicatedStorage.Remote.Galatama:FindFirstChild("Ikut")
					if galatamaRemote then
						galatamaRemote:InvokeServer() 
					end
				end)
				task.wait(10)
			end
		end)
	end
end)

local TitleCoreEvent = Instance.new("TextLabel")
TitleCoreEvent.Parent = GalatamaPage
TitleCoreEvent.Size = UDim2.new(1,0,0,25)
TitleCoreEvent.BackgroundTransparency = 1
TitleCoreEvent.Text = "💎 AUTO DETECT WITHERING CORE EVENT"
TitleCoreEvent.TextColor3 = Color3.fromRGB(255,200,0)
TitleCoreEvent.Font = Enum.Font.GothamBold
TitleCoreEvent.TextSize = 13

AddToggle(GalatamaPage, "Auto Teleport Saat Event Core Berlangsung", function(v) getgenv().AutoDetectCoreEvent = v end)

local SavedPreviousSpot = nil
local IsAtCoreEvent = false

task.spawn(function()
	while true do
		if getgenv().AutoDetectCoreEvent then
			pcall(function()
				local currentMinute = tonumber(os.date("%M"))
				local isEventTime = (currentMinute >= 0 and currentMinute <= 10)
				
				if isEventTime then
					if not IsAtCoreEvent then
						SavedPreviousSpot = getgenv().SelectedFishingSpot
						IsAtCoreEvent = true
					end
					getgenv().SelectedFishingSpot = "Spot Mancing Core"
					if SpotLabel then SpotLabel.Text = "Lokasi Saat Ini: Spot Mancing Core (⚡ JADWAL EVENT CORE AKTIF!)" end
					
					local character = LocalPlayer.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					local targetCFrame = FishingSpots["Spot Mancing Core"]
					if hrp and targetCFrame then
						if (hrp.Position - targetCFrame.Position).Magnitude > 20 then
							hrp.CFrame = targetCFrame + Vector3.new(0, 5, 0)
						end
					end
				else
					if IsAtCoreEvent then
						IsAtCoreEvent = false
						if SavedPreviousSpot and FishingSpots[SavedPreviousSpot] then
							getgenv().SelectedFishingSpot = SavedPreviousSpot
							if SpotLabel then SpotLabel.Text = "Lokasi Saat Ini: " .. SavedPreviousSpot .. " (Event Selesai, Kembali)" end
							
							local character = LocalPlayer.Character
							local hrp = character and character:FindFirstChild("HumanoidRootPart")
							local prevCFrame = FishingSpots[SavedPreviousSpot]
							if hrp and prevCFrame then
								hrp.CFrame = prevCFrame + Vector3.new(0, 5, 0)
							end
						end
					end
				end
			end)
		end
		task.wait(5)
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
	local c = Instance.new("UICorner")
	c.Parent = btn
	btn.MouseButton1Click:Connect(function() pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = cf + Vector3.new(0, 5, 0) end) end)
end

AddShopTeleportBtn(TeleportShopPage, "Tempat Jual Ikan", CFrame.new(-6668.79785, 1312.69983, -9964.06152))
AddShopTeleportBtn(TeleportShopPage, "Skin Shop", CFrame.new(-6639.45947, 1312.69983, -9947.36133))
AddShopTeleportBtn(TeleportShopPage, "Pet Shop", CFrame.new(-6640.44092, 1312.69983, -9917.93652))
AddShopTeleportBtn(TeleportShopPage, "Upgrade Pet", CFrame.new(-6637.85156, 1312.69983, -9886.52441))
AddShopTeleportBtn(TeleportShopPage, "Rod Shop", CFrame.new(-6638.09521, 1312.69983, -9857.41797))
AddShopTeleportBtn(TeleportShopPage, "Title Shop", CFrame.new(-6667.0249, 1312.69983, -9843.66113))

----------------------------------------------------
-- 5. SUMMIT PAGE (FIX: TOUCH INTEREST & CFrame ORDER)
----------------------------------------------------
local TitleSum = Instance.new("TextLabel")
TitleSum.Parent = SummitPage
TitleSum.Size = UDim2.new(1,0,0,30)
TitleSum.BackgroundTransparency = 1
TitleSum.Text = "⛰️ AUTO SUMMIT FARM (TOUCH FIXED)"
TitleSum.TextColor3 = Color3.fromRGB(0,170,255)
TitleSum.Font = Enum.Font.GothamBold
TitleSum.TextSize = 13

AddToggle(SummitPage, "Auto Summit Loop (Touch CFrame)", function(v) getgenv().AutoSummitRunning = v end)

-- Daftar CFrame Checkpoint 1 sampai 20
local SummitCheckpoints = {
	CFrame.new(464.5757, 444.6314, -8944.9775),
	CFrame.new(450.3757, 488.9970, -9572.0254),
	CFrame.new(394.5212, 628.9980, -10113.1602),
	CFrame.new(487.2241, 636.9980, -10685.8164),
	CFrame.new(1084.3728, 724.9941, -11160.0850),
	CFrame.new(970.9746, 732.9639, -11810.7012),
	CFrame.new(389.8508, 884.9980, -11839.1611),
	CFrame.new(-325.3976, 848.9980, -11735.5684),
	CFrame.new(-870.3784, 852.9980, -11735.9463),
	CFrame.new(-1280.0693, 856.9980, -12095.6299),
	CFrame.new(-1309.8514, 888.9980, -12831.5947),
	CFrame.new(-2315.5291, 912.9980, -12673.0791),
	CFrame.new(-2314.9072, 916.9980, -11851.2207),
	CFrame.new(-2444.2737, 960.9980, -11056.3330),
	CFrame.new(-3480.8328, 980.7667, -11012.4834),
	CFrame.new(-4226.6689, 1000.9980, -11014.9834),
	CFrame.new(-4654.7871, 1080.9979, -11664.6084),
	CFrame.new(-5544.4336, 1100.9979, -11648.8525),
	CFrame.new(-6764.3345, 1096.9979, -11507.0557),
	CFrame.new(-6745.1304, 1102.5760, -10796.0947)
}

local SummitPuncakCFrame = CFrame.new(-6766.44629, 1320.69983, -10083.8037)
local BaseCampCFrame = CFrame.new(-6834.84912, 1313.24744, -9902.42285)

-- Fungsi Pemicu Touch Interest Fisik
local function TouchCP(hrp, index, targetCFrame)
	hrp.CFrame = targetCFrame
	
	local cpNames = {"cp" .. index, "CP" .. index, "Checkpoint" .. index, "Checkpoint " .. index}
	local foundPart = nil
	for _, name in ipairs(cpNames) do
		local obj = workspace:FindFirstChild(name, true)
		if obj then
			foundPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
			if foundPart then break end
		end
	end
	
	if foundPart and firetouchinterest then
		firetouchinterest(hrp, foundPart, 0)
		task.wait(0.1)
		firetouchinterest(hrp, foundPart, 1)
	end
end

task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			pcall(function()
				local character = LocalPlayer.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart")
				
				if hrp then
					for i, cpCFrame in ipairs(SummitCheckpoints) do
						if not getgenv().AutoSummitRunning then break end
						
						-- Teleport & Trigger Touch
						TouchCP(hrp, i, cpCFrame)
						
						-- Jeda antar CP
						task.wait(0.8)
					end
					
					-- Teleport ke Puncak
					if getgenv().AutoSummitRunning then
						hrp.CFrame = SummitPuncakCFrame
						task.wait(3)
						-- Kembali ke BaseCamp
						hrp.CFrame = BaseCampCFrame
					end
				end
			end)
			task.wait(2)
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
local spc = Instance.new("UICorner")
spc.Parent = SpeedBox

SpeedBox.FocusLost:Connect(function()
	local num = tonumber(SpeedBox.Text)
	if num then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = num end) end
end)

AddToggle(PlayerPage, "Anti-AFK", function(v) getgenv().AntiAFKRunning = v end)
LocalPlayer.Idled:Connect(function()
	if getgenv().AntiAFKRunning then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0,0)) end
end)

local HeadlessBtn = Instance.new("TextButton")
HeadlessBtn.Parent = PlayerPage
HeadlessBtn.Size = UDim2.new(1,0,0,35)
HeadlessBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
HeadlessBtn.Text = "👻 Enable Headless"
HeadlessBtn.TextColor3 = Color3.new(1,1,1)
HeadlessBtn.Font = Enum.Font.GothamBold
HeadlessBtn.TextSize = 13
local hlc = Instance.new("UICorner")
hlc.Parent = HeadlessBtn

HeadlessBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
		if head then
			head.Transparency = 1
			for _, child in ipairs(head:GetChildren()) do if child:IsA("Decal") then child.Transparency = 1 end end
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
local frc = Instance.new("UICorner")
frc.Parent = FireRgbBtn

local autoRgbActive = false
FireRgbBtn.MouseButton1Click:Connect(function()
	autoRgbActive = not autoRgbActive
	FireRgbBtn.Text = "🔥🌈 Auto RGB Fire: " .. (autoRgbActive and "[ON]" or "[OFF]")
	FireRgbBtn.BackgroundColor3 = autoRgbActive and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(150, 0, 200)
	pcall(function()
		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
		if head then
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
	local colors = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 100, 255), Color3.fromRGB(255, 0, 255), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 255)}
	local index = 1
	while true do
		if autoRgbActive then
			pcall(function()
				local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
				local fire = head and head:FindFirstChild("UbeyHeadFire")
				if fire then
					index = index % #colors + 1
					fire.Color = colors[index]
					fire.SecondaryColor = colors[(index % #colors) + 1]
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
		for _, v in ipairs(head:GetChildren()) do if v.Name == "CustomPlayerHalo" then v:Destroy() end end
		local haloSourceFolder = ReplicatedStorage:FindFirstChild("HaloKenyal")
		if haloSourceFolder then
			local targetHaloModel = haloSourceFolder:FindFirstChild(haloName)
			if targetHaloModel then
				local cloneModel = targetHaloModel:Clone()
				cloneModel.Name = "CustomPlayerHalo"
				local primaryPart = cloneModel:FindFirstChild("Handle") or cloneModel:FindFirstChild("Antenna") or cloneModel:FindFirstChildWhichIsA("BasePart")
				cloneModel.Parent = head
				for _, desc in ipairs(cloneModel:GetDescendants()) do
					if desc:IsA("BasePart") then desc.Anchored = false desc.CanCollide = false desc.Massless = true
					elseif desc:IsA("Script") or desc:IsA("LocalScript") then desc:Destroy() end
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
	if getgenv().CurrentSelectedHalo then ApplyHaloToCharacter(getgenv().CurrentSelectedHalo) end
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
		local chc = Instance.new("UICorner")
		chc.Parent = clearHaloBtn
		
		clearHaloBtn.MouseButton1Click:Connect(function()
			getgenv().CurrentSelectedHalo = nil
			pcall(function()
				local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
				if head then for _, v in ipairs(head:GetChildren()) do if v.Name == "CustomPlayerHalo" then v:Destroy() end end end
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
			local hbc = Instance.new("UICorner")
			hbc.Parent = haloBtn
			haloBtn.MouseButton1Click:Connect(function() ApplyHaloToCharacter(name) end)
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
RefreshPlayerBtn.Text = "🔄 Refresh / Scan Pemain"
RefreshPlayerBtn.TextColor3 = Color3.new(1,1,1)
RefreshPlayerBtn.Font = Enum.Font.GothamBold
RefreshPlayerBtn.TextSize = 12
local rpc = Instance.new("UICorner")
rpc.Parent = RefreshPlayerBtn

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
	for _, child in ipairs(PlayerListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
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
			local pbc = Instance.new("UICorner")
			pbc.Parent = pBtn
			pBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local hrpTarget = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if hrpTarget and myHrp then myHrp.CFrame = hrpTarget.CFrame + Vector3.new(0, 5, 0) end
				end)
			end)
		end
	end
end

RefreshPlayerBtn.MouseButton1Click:Connect(ScanAndDisplayPlayers)
task.spawn(function() task.wait(2); ScanAndDisplayPlayers() end)

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
local fnc = Instance.new("UICorner")
fnc.Parent = FakeNameBox
FakeNameBox.FocusLost:Connect(function() getgenv().FakeNameInput = FakeNameBox.Text end)

AddToggle(PrivacyPage, "Privacy Mode (Hide Name)", function(v)
	getgenv().HideNameRunning = v
	if v then
		task.spawn(function()
			while getgenv().HideNameRunning do
				pcall(function()
					local fakeName = getgenv().FakeNameInput or "UBEY HUB"
					local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
					if head then
						for _, child in ipairs(head:GetDescendants()) do
							if child:IsA("TextLabel") or child:IsA("TextMesh") then
								local txt = child.Text
								if string.find(txt, LocalPlayer.Name) or string.find(txt, LocalPlayer.DisplayName) then child.Text = fakeName end
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
AntiAdminToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
local aac = Instance.new("UICorner")
aac.Parent = AntiAdminToggleBtn

AntiAdminToggleBtn.MouseButton1Click:Connect(function()
	getgenv().UbeyConfig.AntiAdminEnabled = not getgenv().UbeyConfig.AntiAdminEnabled
	local active = getgenv().UbeyConfig.AntiAdminEnabled
	AntiAdminToggleBtn.Text = "  Anti-Admin Protect (MPG Group): " .. (active and "[ON]" or "[OFF]")
	AntiAdminToggleBtn.BackgroundColor3 = active and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(30, 30, 40)
	SaveConfig()
end)

local function CheckPlayerIsAdmin(player)
	local success, rank = pcall(function() return player:GetRankInGroup(getgenv().UbeyConfig.TargetGroupId or 7019573) end)
	return success and rank and rank > 1
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		task.spawn(function()
			task.wait(1.5)
			if getgenv().UbeyConfig.AntiAdminEnabled and CheckPlayerIsAdmin(player) then
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end
		end)
	end
end)

----------------------------------------------------
-- 10. SETTINGS & WEBHOOK PAGE (SECRET & FORGOTTEN EXCLUSIVE)
----------------------------------------------------
local TitleSet = Instance.new("TextLabel")
TitleSet.Parent = SettingsPage
TitleSet.Size = UDim2.new(1,0,0,30)
TitleSet.BackgroundTransparency = 1
TitleSet.Text = "⚙️ SETTINGS & WEBHOOK SECRET / FORGOTTEN"
TitleSet.TextColor3 = Color3.fromRGB(0,170,255)
TitleSet.Font = Enum.Font.GothamBold
TitleSet.TextSize = 13

local AntiLagBtn = Instance.new("TextButton")
AntiLagBtn.Parent = SettingsPage
AntiLagBtn.Size = UDim2.new(1,0,0,35)
AntiLagBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
AntiLagBtn.Text = "⚡ Aktifkan Anti-Lag (Boost FPS)"
AntiLagBtn.TextColor3 = Color3.new(1,1,1)
AntiLagBtn.Font = Enum.Font.GothamBold
local alc = Instance.new("UICorner")
alc.Parent = AntiLagBtn
AntiLagBtn.MouseButton1Click:Connect(function()
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 999999
		for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled = false end end
		AntiLagBtn.Text = "⚡ Anti-Lag Aktif!"
	end)
end)

local WebhookToggleBtn = Instance.new("TextButton")
WebhookToggleBtn.Parent = SettingsPage
WebhookToggleBtn.Size = UDim2.new(1,0,0,35)
WebhookToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.WebhookEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(30, 30, 40)
WebhookToggleBtn.Text = "  Webhook Secret & Forgotten: " .. (getgenv().UbeyConfig.WebhookEnabled and "[ON]" or "[OFF]")
WebhookToggleBtn.TextColor3 = Color3.new(1,1,1)
WebhookToggleBtn.Font = Enum.Font.Gotham
WebhookToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
local wtc = Instance.new("UICorner")
wtc.Parent = WebhookToggleBtn

WebhookToggleBtn.MouseButton1Click:Connect(function()
	getgenv().UbeyConfig.WebhookEnabled = not getgenv().UbeyConfig.WebhookEnabled
	WebhookToggleBtn.Text = "  Webhook Secret & Forgotten: " .. (getgenv().UbeyConfig.WebhookEnabled and "[ON]" or "[OFF]")
	WebhookToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.WebhookEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(30, 30, 40)
	SaveConfig()
end)

local WebhookBox = Instance.new("TextBox")
WebhookBox.Parent = SettingsPage
WebhookBox.Size = UDim2.new(1,0,0,35)
WebhookBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
WebhookBox.PlaceholderText = "Paste Discord Webhook URL di sini..."
WebhookBox.Text = tostring(getgenv().UbeyConfig.WebhookUrl or "")
WebhookBox.TextColor3 = Color3.new(1,1,1)
local wbc = Instance.new("UICorner")
wbc.Parent = WebhookBox
WebhookBox.FocusLost:Connect(function()
	getgenv().UbeyConfig.WebhookUrl = WebhookBox.Text
	SaveConfig()
end)

local TestWebhookBtn = Instance.new("TextButton")
TestWebhookBtn.Parent = SettingsPage
TestWebhookBtn.Size = UDim2.new(1,0,0,35)
TestWebhookBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
TestWebhookBtn.TextColor3 = Color3.new(1,1,1)
TestWebhookBtn.Font = Enum.Font.GothamBold
TestWebhookBtn.TextSize = 13
local twc = Instance.new("UICorner")
twc.Parent = TestWebhookBtn

TestWebhookBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then
			TestWebhookBtn.Text = "❌ URL Webhook Salah / Belum Diisi!"
			task.wait(2)
			TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
			return
		end
		
		local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
		if requestFunc then
			requestFunc({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({
					["content"] = "✅ **Ubey Hub V3 Webhook Test Berhasil!** Koneksi ke Discord normal."
				})
			})
			TestWebhookBtn.Text = "✅ Pesan Test Berhasil Dikirim!"
		else
			TestWebhookBtn.Text = "❌ Executor Tidak Mendukung Request!"
		end
		task.wait(2)
		TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
	end)
end)

local SaveConfigBtn = Instance.new("TextButton")
SaveConfigBtn.Parent = SettingsPage
SaveConfigBtn.Size = UDim2.new(1,0,0,35)
SaveConfigBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
SaveConfigBtn.Text = "💾 Simpan Konfigurasi"
SaveConfigBtn.TextColor3 = Color3.new(1,1,1)
SaveConfigBtn.Font = Enum.Font.GothamBold
local scc = Instance.new("UICorner")
scc.Parent = SaveConfigBtn
SaveConfigBtn.MouseButton1Click:Connect(function()
	SaveConfig()
	SaveConfigBtn.Text = "✅ Config Berhasil Disimpan!"
	task.wait(1.5)
	SaveConfigBtn.Text = "💾 Simpan Konfigurasi"
end)

local ResetConfigBtn = Instance.new("TextButton")
ResetConfigBtn.Parent = SettingsPage
ResetConfigBtn.Size = UDim2.new(1,0,0,35)
ResetConfigBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ResetConfigBtn.Text = "🔄 Reset Konfigurasi & Clear Key"
ResetConfigBtn.TextColor3 = Color3.new(1,1,1)
ResetConfigBtn.Font = Enum.Font.GothamBold
local rcc = Instance.new("UICorner")
rcc.Parent = ResetConfigBtn
ResetConfigBtn.MouseButton1Click:Connect(function()
	ResetConfig()
	ResetConfigBtn.Text = "🔄 Config Direset!"
	task.wait(1.5)
	ResetConfigBtn.Text = "🔄 Reset Konfigurasi & Clear Key"
end)

local CredLbl = Instance.new("TextLabel")
CredLbl.Parent = CreditsPage
CredLbl.Size = UDim2.new(1,0,1,0)
CredLbl.BackgroundTransparency = 1
CredLbl.Text = "Created By UBEY"
CredLbl.TextColor3 = Color3.new(1,1,1)
CredLbl.Font = Enum.Font.GothamBold
CredLbl.TextSize = 20

----------------------------------------------------
-- FLOATING BUTTON
----------------------------------------------------
local Float = Instance.new("ImageButton")
Float.Parent = Gui
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)
local flCorner = Instance.new("UICorner")
flCorner.CornerRadius = UDim.new(1,0)
flCorner.Parent = Float
MakeDraggable(Float)

Float.MouseButton1Click:Connect(function()
	if not getgenv().KeyVerified then
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)
