-- ==============================================================================
-- UBEY HUB V3 | Final Complete Version (Supabase, Ping, Anti-Lag, Shop, Config, Anti-Admin, Summit, Galatama, Headless, Fire RGB, Custom Title & Secure Key System)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- CONFIGURATION & FILE SAVE SYSTEM
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHubV3_Config.json"

getgenv().UbeyConfig = {
	BiteDelay = "0.5",
	SelectedSpot = "Spot Mancing Jembatan",
	AutoSellTimer = "5",
	AutoExecuteEnabled = true,
	AntiAdminEnabled = false,
	TargetGroupId = 7019573,
	CustomTitleText = "UBEY HUB V3"
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
				if data.CustomTitleText then getgenv().UbeyConfig.CustomTitleText = data.CustomTitleText end
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
			CustomTitleText = "UBEY HUB V3"
		}
		if delfile and isfile and isfile(CONFIG_FILE) then
			delfile(CONFIG_FILE)
		end
	end)
end

LoadConfig()

------------------------------------------------------------------
-- SUPABASE CONFIGURATION
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"

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
			loadstring(game:HttpGet("LINK_GITHUB_ATAU_KODE_KAMU"))()
		]])
	end
end)

pcall(function()
	if setclipboard then
		setclipboard("https://discord.gg/aCbAWe9PYB")
	elseif toclipboard then
		toclipboard("https://discord.gg/aCbAWe9PYB")
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
getgenv().CustomTitleActive = false
getgenv().CustomTitleInputText = getgenv().UbeyConfig.CustomTitleText
getgenv().KeyVerified = false

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

pcall(function()
	PlayerGui:FindFirstChild("UbeyHub"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

----------------------------------------------------
-- KEY SYSTEM UI (SUPABASE INTEGRATION)
----------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,220)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-110)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
KeyFrame.Visible = true

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
KeyTitle.Text = "UBEY HUB V3 - KEY SYSTEM"
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextColor3 = Color3.fromRGB(0,170,255)
KeyTitle.TextSize = 15

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
SubmitKeyBtn.Position = UDim2.new(0,20,0,115)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Key"
SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextSize = 13
Instance.new("UICorner", SubmitKeyBtn)

local GetKeyDiscordBtn = Instance.new("TextButton")
GetKeyDiscordBtn.Parent = KeyFrame
GetKeyDiscordBtn.Size = UDim2.new(0,165,0,35)
GetKeyDiscordBtn.Position = UDim2.new(0,195,0,115)
GetKeyDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GetKeyDiscordBtn.Text = "Get Key via Bot Discord"
GetKeyDiscordBtn.TextColor3 = Color3.new(1,1,1)
GetKeyDiscordBtn.Font = Enum.Font.GothamBold
GetKeyDiscordBtn.TextSize = 12
Instance.new("UICorner", GetKeyDiscordBtn)

local FreeKeyBackupBtn = Instance.new("TextButton")
FreeKeyBackupBtn.Parent = KeyFrame
FreeKeyBackupBtn.Size = UDim2.new(0,340,0,30)
FreeKeyBackupBtn.Position = UDim2.new(0,20,0,160)
FreeKeyBackupBtn.BackgroundColor3 = Color3.fromRGB(45,45,55)
FreeKeyBackupBtn.Text = "Gunakan Free Key (UBEY_FREE)"
FreeKeyBackupBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
FreeKeyBackupBtn.Font = Enum.Font.GothamMedium
FreeKeyBackupBtn.TextSize = 12
Instance.new("UICorner", FreeKeyBackupBtn)

local StatusKey = Instance.new("TextLabel")
StatusKey.Parent = KeyFrame
StatusKey.Size = UDim2.new(1,0,0,20)
StatusKey.Position = UDim2.new(0,0,0,195)
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
Sidebar.CanvasSize = UDim2.new(0,0,2.2,0)
Sidebar.ScrollBarThickness = 2

local SideCorner = Instance.new("UICorner")
SideCorner.Parent = Sidebar

local HubTitle = Instance.new("TextLabel")
HubTitle.Parent = Sidebar
HubTitle.BackgroundTransparency = 1
HubTitle.Size = UDim2.new(1,0,0,60)
HubTitle.Text = "UBEY HUB"
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextColor3 = Color3.fromRGB(0,170,255)
HubTitle.TextSize = 20

local HomeBtn = Instance.new("TextButton")
HomeBtn.Parent = Sidebar
HomeBtn.Position = UDim2.new(0,10,0,65)
HomeBtn.Size = UDim2.new(1,-20,0,28)
HomeBtn.Text = "Fishing & Sell"
HomeBtn.TextColor3 = Color3.new(1,1,1)
HomeBtn.Font = Enum.Font.GothamMedium
HomeBtn.TextSize = 12

local GalatamaBtn = HomeBtn:Clone()
GalatamaBtn.Parent = Sidebar
GalatamaBtn.Position = UDim2.new(0,10,0,100)
GalatamaBtn.Text = "Galatama"

local TeleportShopBtn = HomeBtn:Clone()
TeleportShopBtn.Parent = Sidebar
TeleportShopBtn.Position = UDim2.new(0,10,0,135)
TeleportShopBtn.Text = "Teleport Shop"

local SummitBtn = HomeBtn:Clone()
SummitBtn.Parent = Sidebar
SummitBtn.Position = UDim2.new(0,10,0,170)
SummitBtn.Text = "Summit"

local PlayerMenuBtn = HomeBtn:Clone()
PlayerMenuBtn.Parent = Sidebar
PlayerMenuBtn.Position = UDim2.new(0,10,0,205)
PlayerMenuBtn.Text = "Player"

local HaloMenuBtn = HomeBtn:Clone()
HaloMenuBtn.Parent = Sidebar
HaloMenuBtn.Position = UDim2.new(0,10,0,240)
HaloMenuBtn.Text = "Halo Kepala"

local TitleMenuBtn = HomeBtn:Clone()
TitleMenuBtn.Parent = Sidebar
TitleMenuBtn.Position = UDim2.new(0,10,0,275)
TitleMenuBtn.Text = "Custom Title"

local PrivacyBtn = HomeBtn:Clone()
PrivacyBtn.Parent = Sidebar
PrivacyBtn.Position = UDim2.new(0,10,0,310)
PrivacyBtn.Text = "Privacy"

local SettingsBtn = HomeBtn:Clone()
SettingsBtn.Parent = Sidebar
SettingsBtn.Position = UDim2.new(0,10,0,345)
SettingsBtn.Text = "Settings"

local CreditsBtn = HomeBtn:Clone()
CreditsBtn.Parent = Sidebar
CreditsBtn.Position = UDim2.new(0,10,0,380)
CreditsBtn.Text = "Credits"

for _,v in ipairs({HomeBtn, GalatamaBtn, TeleportShopBtn, SummitBtn, PlayerMenuBtn, HaloMenuBtn, TitleMenuBtn, PrivacyBtn, SettingsBtn, CreditsBtn}) do
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
local GalatamaPage = MakePage()
local TeleportShopPage = MakePage()
local SummitPage = MakePage()
local PlayerPage = MakePage()
local HaloPage = MakePage()
local TitlePage = MakePage()
local PrivacyPage = MakePage()
local SettingsPage = MakePage()
local CreditsPage = MakePage()

local function HideAll()
	FishingPage.Visible = false
	GalatamaPage.Visible = false
	TeleportShopPage.Visible = false
	SummitPage.Visible = false
	PlayerPage.Visible = false
	HaloPage.Visible = false
	TitlePage.Visible = false
	PrivacyPage.Visible = false
	SettingsPage.Visible = false
	CreditsPage.Visible = false
end

HomeBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
TeleportShopBtn.MouseButton1Click:Connect(function() HideAll(); TeleportShopPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerMenuBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
HaloMenuBtn.MouseButton1Click:Connect(function() HideAll(); HaloPage.Visible = true end)
TitleMenuBtn.MouseButton1Click:Connect(function() HideAll(); TitlePage.Visible = true end)
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
-- SUPABASE VERIFICATION
----------------------------------------------------
FreeKeyBackupBtn.MouseButton1Click:Connect(function()
	KeyBox.Text = "UBEY_FREE"
	pcall(function()
		if setclipboard then setclipboard("UBEY_FREE") end
	end)
	StatusKey.TextColor3 = Color3.fromRGB(0,255,100)
	StatusKey.Text = "Free Key (UBEY_FREE) disalin!"
end)

GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function()
		if setclipboard then setclipboard("https://discord.gg/aCbAWe9PYB") end
	end)
	StatusKey.TextColor3 = Color3.fromRGB(0,170,255)
	StatusKey.Text = "Link Discord disalin! Dapatkan key dari bot Discord."
end)

SubmitKeyBtn.MouseButton1Click:Connect(function()
	local enteredKey = KeyBox.Text
	if enteredKey == "" then
		StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
		StatusKey.Text = "Masukkan key terlebih dahulu!"
		return
	end
	
	if enteredKey == "UBEY_FREE" then
		getgenv().KeyVerified = true
		KeyFrame.Visible = false
		Main.Visible = true
		return
	end
	
	StatusKey.TextColor3 = Color3.fromRGB(255,200,0)
	StatusKey.Text = "Mengecek key ke database Supabase..."
	
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
				
				if keyStatus == false or keyStatus == "inactive" or keyStatus == "used" then
					StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
					StatusKey.Text = "Key sudah tidak aktif / sudah digunakan!"
					return
				end
				
				StatusKey.TextColor3 = Color3.fromRGB(0,255,100)
				StatusKey.Text = "Key Valid! Membuka Hub..."
				task.wait(1)
				getgenv().KeyVerified = true
				KeyFrame.Visible = false
				Main.Visible = true
			else
				StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
				StatusKey.Text = "Key Salah atau Belum Dibuat oleh Bot Discord!"
			end
		else
			StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
			StatusKey.Text = "Gagal terhubung ke server Supabase."
		end
	end)
end)

----------------------------------------------------
-- 1. FISHING & SELL PAGE
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
-- 2. GALATAMA PAGE
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
-- 3. TELEPORT SHOP PAGE
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
-- 4. SUMMIT PAGE (DENGAN ANTI-TEMBUS & JEDA DI PUNCAK)
----------------------------------------------------
local TitleSum = Instance.new("TextLabel")
TitleSum.Parent = SummitPage
TitleSum.Size = UDim2.new(1,0,0,30)
TitleSum.BackgroundTransparency = 1
TitleSum.Text = "⛰️ AUTO SUMMIT FARM"
TitleSum.TextColor3 = Color3.fromRGB(0,170,255)
TitleSum.Font = Enum.Font.GothamBold
TitleSum.TextSize = 13

-- Ketinggian sumbu Y dinaikkan sedikit (+5) agar aman tidak tembus tanah
local summitCFrame = CFrame.new(-6766.44629, 1317.69983, -10083.8037, -0.993305981, 1.64907146e-08, 0.115513086, 1.58947078e-08, 1, -6.08075279e-09, -0.115513086, -4.20400115e-09, -0.993305981)
local bcCFrame = CFrame.new(-6834.84912, 1310.24744, -9902.42285, -1, 0, 0, 0, 1, 0, 0, 0, -1)

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
					
					-- 1. Teleport lewat checkpoint berurutan
					for i = 1, 20 do
						if not getgenv().AutoSummitRunning then break end
						if tpCP then tpCP:FireServer(i) end
						task.wait(0.1)
					end
					
					-- 2. Teleport ke puncak utama
					if getgenv().AutoSummitRunning then
						hrp.CFrame = summitCFrame
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						
						-- Jeda berhenti sejenak di puncak agar hitungan summit sukses dicatat game
						task.wait(2.5) 
					end
					
					-- 3. Kembali ke base camp
					if getgenv().AutoSummitRunning then
						hrp.CFrame = bcCFrame
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						task.wait(0.8)
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
-- 5. PLAYER PAGE
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
-- 6. HALO PAGE
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
-- 7. CUSTOM TITLE PAGE (TITLE DI ATAS KEPALA)
----------------------------------------------------
local TitleHeadLbl = Instance.new("TextLabel")
TitleHeadLbl.Parent = TitlePage
TitleHeadLbl.Size = UDim2.new(1,0,0,30)
TitleHeadLbl.BackgroundTransparency = 1
TitleHeadLbl.Text = "✨ CUSTOM TITLE DI ATAS KEPALA"
TitleHeadLbl.TextColor3 = Color3.fromRGB(0,170,255)
TitleHeadLbl.Font = Enum.Font.GothamBold
TitleHeadLbl.TextSize = 13

local TitleInputBox = Instance.new("TextBox")
TitleInputBox.Parent = TitlePage
TitleInputBox.Size = UDim2.new(1,0,0,35)
TitleInputBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
TitleInputBox.PlaceholderText = "Ketik Teks Title (Cth: UBEY HUB V3)"
TitleInputBox.Text = getgenv().UbeyConfig.CustomTitleText
TitleInputBox.TextColor3 = Color3.new(1,1,1)
TitleInputBox.Font = Enum.Font.Gotham
TitleInputBox.TextSize = 12
Instance.new("UICorner", TitleInputBox)

TitleInputBox.FocusLost:Connect(function()
	getgenv().CustomTitleInputText = TitleInputBox.Text
	getgenv().UbeyConfig.CustomTitleText = TitleInputBox.Text
	SaveConfig()
end)

local function ApplyCustomTitle()
	pcall(function()
		local char = LocalPlayer.Character
		local head = char and char:FindFirstChild("Head")
		if not head then return end
		
		for _, v in ipairs(head:GetChildren()) do
			if v.Name == "UbeyCustomTitleBillboard" then
				v:Destroy()
			end
		end
		
		if not getgenv().CustomTitleActive then return end
		
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "UbeyCustomTitleBillboard"
		billboard.Parent = head
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 2.8, 0)
		billboard.AlwaysOnTop = true
		
		local txtLabel = Instance.new("TextLabel")
		txtLabel.Parent = billboard
		txtLabel.Size = UDim2.new(1, 0, 1, 0)
		txtLabel.BackgroundTransparency = 1
		txtLabel.Text = getgenv().CustomTitleInputText or "UBEY HUB V3"
		txtLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
		txtLabel.TextStrokeTransparency = 0
		txtLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		txtLabel.Font = Enum.Font.GothamBold
		txtLabel.TextSize = 18
	end)
end

AddToggle(TitlePage, "Aktifkan Custom Title di Kepala", function(v)
	getgenv().CustomTitleActive = v
	ApplyCustomTitle()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(1.5)
	if getgenv().CustomTitleActive then
		ApplyCustomTitle()
	end
end)

----------------------------------------------------
-- 8. PRIVACY & ANTI-ADMIN PAGE
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
-- 9. SETTINGS, CONFIG & CREDITS PAGE
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
AntiLagBtn.Text = "⚡ Aktifkan Anti-Lag (Boost FPS)"
AntiLagBtn.TextColor3 = Color3.new(1,1,1)
AntiLagBtn.Font = Enum.Font.GothamBold
AntiLagBtn.TextSize = 13
Instance.new("UICorner", AntiLagBtn)

AntiLagBtn.MouseButton1Click:Connect(function()
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 999999
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
				v.Enabled = false
			elseif v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
				v.Reflectance = 0
			end
		end
		
		AntiLagBtn.Text = "⚡ Anti-Lag Aktif (Boosted!)"
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
ResetConfigBtn.Text = "🔄 Reset Konfigurasi (Reset Config)"
ResetConfigBtn.TextColor3 = Color3.new(1,1,1)
ResetConfigBtn.Font = Enum.Font.GothamBold
ResetConfigBtn.TextSize = 13
Instance.new("UICorner", ResetConfigBtn)

ResetConfigBtn.MouseButton1Click:Connect(function()
	ResetConfig()
	ResetConfigBtn.Text = "🔄 Config Direset! (Restart Game)"
	task.wait(1.5)
	ResetConfigBtn.Text = "🔄 Reset Konfigurasi (Reset Config)"
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
TheCloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local CredLbl = Instance.new("TextLabel")
CredLbl.Parent = CreditsPage
CredLbl.Size = UDim2.new(1,0,1,0)
CredLbl.BackgroundTransparency = 1
CredLbl.Text = "Created By UBEY"
CredLbl.TextColor3 = Color3.new(1,1,1)
CredLbl.Font = Enum.Font.GothamBold
CredLbl.TextSize = 20

----------------------------------------------------
-- FLOATING BUTTON HP & DRAG (SECURE LOGIC)
----------------------------------------------------
local Float = Instance.new("ImageButton")
Float.Parent = Gui
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1,0)
FloatCorner.Parent = Float

Float.MouseButton1Click:Connect(function()
	if not getgenv().KeyVerified then
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)

local dragging = false
local dragStart, startPos

Float.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, Float.Position
	end
end)

UIS.TouchMoved:Connect(function(input)
	if dragging then
		local delta = input.Position - dragStart
		Float.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UIS.TouchEnded:Connect(function()
	dragging = false
end)
