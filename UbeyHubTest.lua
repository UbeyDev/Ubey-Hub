-- ==============================================================================
-- UBEY HUB V3 | Custom GUI + Perfect Padding on All Pages
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- AUTO RECONNECT SYSTEM
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

-- SUPABASE CONFIG
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co"
local SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3d3h2ZW14ZXp0Zml5dXVyaHJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzMTAwMDIsImV4cCI6MjEwNjg4NjAwMn0.IQNQXBvOHyovn-fahzGR-yAt34-72LG6dyVtUJAa92c"

local function validateKey(inputKey)
	local isValid = false
	pcall(function()
		local url = SUPABASE_URL .. "/rest/v1/Ubey_Project?key_value=eq." .. HttpService:UrlEncode(inputKey)
		local request = (syn and syn.request) or (http and http.request) or http_request or request
		if request then
			local res = request({
				Url = url, Method = "GET",
				Headers = {["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " .. SUPABASE_KEY}
			})
			if res and res.StatusCode == 200 then
				local data = HttpService:JSONDecode(res.Body)
				if data and #data > 0 then isValid = true end
			end
		end
	end)
	if inputKey == "UBEY_FREE" then isValid = true end
	return isValid
end

pcall(function()
	if setclipboard then
		setclipboard("https://discord.gg/aCbAWe9PYB")
	elseif toclipboard then
		toclipboard("https://discord.gg/aCbAWe9PYB")
	end
end)

-- GLOBAL STATES & LOGIC
getgenv().AutoFishingEventRunning = false
getgenv().BiteDelayInput = "0.5"
getgenv().SelectedFishingSpot = "Spot Mancing Jembatan"
getgenv().AutoSellRunning = false
getgenv().AutoSellTimerInput = "5"
getgenv().AutoGalatamaRunning = false
getgenv().AutoSummitRunning = false
getgenv().AntiAFKRunning = false
getgenv().HideNameRunning = false
getgenv().FakeNameInput = "UBEY HUB"

-- DATA KOORDINAT SPOT & NPC
local FishingSpots = {
	["Spot Mancing Jembatan"] = CFrame.new(-6783.74756, 1322.81006, -9757.34473, 0.0899723172, -9.34088291e-08, 0.995944262, 1.76120434e-08, 1, 9.21981638e-08, -0.995944262, 9.24533072e-09, 0.0899723172),
	["Spot Mancing Core"] = CFrame.new(-9069.33887, 1250.32092, -6510.3374, 0.99812746, -7.96398965e-08, -0.0611686334, 8.05492206e-08, 1, 1.24000188e-08, 0.0611686334, -1.73038845e-08, 0.99812746),
	["Spot Mancing Ikan Anomali"] = CFrame.new(-8199.52832, 1238.83752, -6278.13135, -0.999144316, 1.1644854e-08, -0.0413601957, 1.63464247e-08, 1, -1.13335595e-07, 0.0413601957, -1.13914709e-07, -0.999144316)
}

local NpcSellCFrame = CFrame.new(-6668.01416, 1312.69983, -9965.2998, 0.999977231, 1.08366018e-08, -0.00675115408, -1.09201403e-08, 1, -1.2337189e-08, 0.00675115408, 1.24106316e-08, 0.999977231)

local function GetRod()
	local character = LocalPlayer.Character
	if character then
		local rodInHand = character:FindFirstChild("Withering Rod")
		if rodInHand then
			return rodInHand
		else
			local rodInBackpack = LocalPlayer.Backpack:FindFirstChild("Withering Rod")
			if rodInBackpack and character:FindFirstChildOfClass("Humanoid") then
				character.Humanoid:EquipTool(rodInBackpack)
				task.wait(0.3)
				return character:FindFirstChild("Withering Rod")
			end
		end
	end
	return nil
end

local function OptimizeRodSettings()
	pcall(function()
		local rod = GetRod()
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
-- KEY SYSTEM GUI
----------------------------------------------------
local Blur = Instance.new("Frame")
Blur.Parent = Gui
Blur.Size = UDim2.new(1,0,1,0)
Blur.BackgroundColor3 = Color3.fromRGB(0,0,0)
Blur.BackgroundTransparency = 0.35

local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,0,0,0)
KeyFrame.Position = UDim2.new(0.5,-180,0.5,-120)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,18)
Corner.Parent = KeyFrame

local Stroke = Instance.new("UIStroke")
Stroke.Parent = KeyFrame
Stroke.Color = Color3.fromRGB(0,170,255)
Stroke.Thickness = 2

TweenService:Create(
	KeyFrame,
	TweenInfo.new(0.4,Enum.EasingStyle.Back),
	{Size = UDim2.new(0,360,0,240)}
):Play()

local Logo = Instance.new("ImageLabel")
Logo.Parent = KeyFrame
Logo.BackgroundTransparency = 1
Logo.Position = UDim2.new(0.5,-35,0,10)
Logo.Size = UDim2.new(0,70,0,70)
Logo.Image = "rbxassetid://90770802417381"

local Title = Instance.new("TextLabel")
Title.Parent = KeyFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0,0,0,85)
Title.Size = UDim2.new(1,0,0,30)
Title.Text = "UBEY HUB V3"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 22

local Box = Instance.new("TextBox")
Box.Parent = KeyFrame
Box.Position = UDim2.new(0.1,0,0,130)
Box.Size = UDim2.new(0.8,0,0,40)
Box.BackgroundColor3 = Color3.fromRGB(35,35,45)
Box.PlaceholderText = "Masukkan Key..."
Box.Text = ""
Box.TextColor3 = Color3.fromRGB(255,255,255)

local BoxCorner = Instance.new("UICorner")
BoxCorner.Parent = Box

local Submit = Instance.new("TextButton")
Submit.Parent = KeyFrame
Submit.Position = UDim2.new(0.1,0,0,180)
Submit.Size = UDim2.new(0.8,0,0,35)
Submit.Text = "VERIFY KEY"
Submit.BackgroundColor3 = Color3.fromRGB(0,170,255)
Submit.TextColor3 = Color3.new(1,1,1)

local SubmitCorner = Instance.new("UICorner")
SubmitCorner.Parent = Submit

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

local Sidebar = Instance.new("Frame")
Sidebar.Parent = Main
Sidebar.Size = UDim2.new(0,140,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,20)

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

-- Tombol Sidebar
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

local SummitBtn = HomeBtn:Clone()
SummitBtn.Parent = Sidebar
SummitBtn.Position = UDim2.new(0,10,0,135)
SummitBtn.Text = "Summit"

local PlayerMenuBtn = HomeBtn:Clone()
PlayerMenuBtn.Parent = Sidebar
PlayerMenuBtn.Position = UDim2.new(0,10,0,170)
PlayerMenuBtn.Text = "Player"

local PrivacyBtn = HomeBtn:Clone()
PrivacyBtn.Parent = Sidebar
PrivacyBtn.Position = UDim2.new(0,10,0,205)
PrivacyBtn.Text = "Privacy"

local SettingsBtn = HomeBtn:Clone()
SettingsBtn.Parent = Sidebar
SettingsBtn.Position = UDim2.new(0,10,0,240)
SettingsBtn.Text = "Settings"

local CreditsBtn = HomeBtn:Clone()
CreditsBtn.Parent = Sidebar
CreditsBtn.Position = UDim2.new(0,10,0,275)
CreditsBtn.Text = "Credits"

for _,v in ipairs({HomeBtn, GalatamaBtn, SummitBtn, PlayerMenuBtn, PrivacyBtn, SettingsBtn, CreditsBtn}) do
	v.BackgroundColor3 = Color3.fromRGB(35,35,45)
	local c = Instance.new("UICorner")
	c.Parent = v
end

local Content = Instance.new("Frame")
Content.Parent = Main
Content.Position = UDim2.new(0,150,0,10)
Content.Size = UDim2.new(1,-160,1,-20)
Content.BackgroundTransparency = 1

local function MakePage()
	local f = Instance.new("ScrollingFrame")
	f.Parent = Content
	f.Size = UDim2.new(1,0,1,0)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.CanvasSize = UDim2.new(0,0,3,0)
	f.ScrollBarThickness = 4
	
	-- Menambahkan padding atas di setiap halaman agar tidak terlalu naik
	local pad = Instance.new("UIPadding")
	pad.Parent = f
	pad.PaddingTop = UDim.new(0, 15)
	
	local l = Instance.new("UIListLayout")
	l.Parent = f
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, 8)
	return f
end

local FishingPage = MakePage() FishingPage.Visible = true
local GalatamaPage = MakePage()
local SummitPage = MakePage()
local PlayerPage = MakePage()
local PrivacyPage = MakePage()
local SettingsPage = MakePage()
local CreditsPage = MakePage()

local function HideAll()
	FishingPage.Visible = false
	GalatamaPage.Visible = false
	SummitPage.Visible = false
	PlayerPage.Visible = false
	PrivacyPage.Visible = false
	SettingsPage.Visible = false
	CreditsPage.Visible = false
end

HomeBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerMenuBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
PrivacyBtn.MouseButton1Click:Connect(function() HideAll(); PrivacyPage.Visible = true end)
SettingsBtn.MouseButton1Click:Connect(function() HideAll(); SettingsPage.Visible = true end)
CreditsBtn.MouseButton1Click:Connect(function() HideAll(); CreditsPage.Visible = true end)

-- FUNGSI PEMBUAT TOMBOL TOGGLE
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
SpotLabel.Text = "Pilih Lokasi: Spot Mancing Jembatan"
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
ChangeSpotBtn.MouseButton1Click:Connect(function()
	spotIndex = spotIndex % #spotList + 1
	getgenv().SelectedFishingSpot = spotList[spotIndex]
	SpotLabel.Text = "Pilih Lokasi: " .. getgenv().SelectedFishingSpot
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
					local rod = GetRod()
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
					local rod = GetRod()
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
BiteDelayBox.Text = "0.5"
BiteDelayBox.TextColor3 = Color3.new(1,1,1)
BiteDelayBox.Font = Enum.Font.Gotham
BiteDelayBox.TextSize = 12
Instance.new("UICorner", BiteDelayBox)
BiteDelayBox.FocusLost:Connect(function()
	getgenv().BiteDelayInput = BiteDelayBox.Text
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
SellTimerBox.Text = "5"
SellTimerBox.TextColor3 = Color3.new(1,1,1)
SellTimerBox.Font = Enum.Font.Gotham
SellTimerBox.TextSize = 12
Instance.new("UICorner", SellTimerBox)
SellTimerBox.FocusLost:Connect(function()
	getgenv().AutoSellTimerInput = SellTimerBox.Text
end)

----------------------------------------------------
-- 2. GALATAMA PAGE
----------------------------------------------------
local TitleGal = Instance.new("TextLabel")
TitleGal.Parent = GalatamaPage
TitleGal.Size = UDim2.new(1,0,0,30)
TitleGal.BackgroundTransparency = 1
TitleGal.Text = "🏆 GALATAMA AUTO JOIN"
TitleGal.TextColor3 = Color3.fromRGB(0,170,255)
TitleGal.Font = Enum.Font.GothamBold
TitleGal.TextSize = 13

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
-- 3. SUMMIT PAGE
----------------------------------------------------
local TitleSum = Instance.new("TextLabel")
TitleSum.Parent = SummitPage
TitleSum.Size = UDim2.new(1,0,0,30)
TitleSum.BackgroundTransparency = 1
TitleSum.Text = "⛰️ AUTO SUMMIT FARM"
TitleSum.TextColor3 = Color3.fromRGB(0,170,255)
TitleSum.Font = Enum.Font.GothamBold
TitleSum.TextSize = 13

AddToggle(SummitPage, "Auto Summit Loop", function(v)
	getgenv().AutoSummitRunning = v
end)
task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			pcall(function()
				local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local hrp = character:WaitForChild("HumanoidRootPart", 5)
				local cpFolder = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Checkpoint")
				local tpCP = cpFolder and cpFolder:FindFirstChild("TpToCheckpoint")
				if hrp and tpCP then
					for i = 1, 20 do
						if not getgenv().AutoSummitRunning then break end
						pcall(function() tpCP:FireServer(i) end)
						task.wait(0.1)
					end
					hrp.CFrame = CFrame.new(-6766.44629, 1312.69983, -10083.8037)
					task.wait(1)
				end
			end)
		end
		task.wait(0.5)
	end
end)

----------------------------------------------------
-- 4. PLAYER PAGE
----------------------------------------------------
local TitlePly = Instance.new("TextLabel")
TitlePly.Parent = PlayerPage
TitlePly.Size = UDim2.new(1,0,0,30)
TitlePly.BackgroundTransparency = 1
TitlePly.Text = "⚡ PLAYER SETTINGS"
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

----------------------------------------------------
-- 5. PRIVACY PAGE
----------------------------------------------------
local TitlePrv = Instance.new("TextLabel")
TitlePrv.Parent = PrivacyPage
TitlePrv.Size = UDim2.new(1,0,0,30)
TitlePrv.BackgroundTransparency = 1
TitlePrv.Text = "🛡️ PRIVACY & CREATOR MODE"
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

----------------------------------------------------
-- 6. SETTINGS & CREDITS PAGE
----------------------------------------------------
local TitleSet = Instance.new("TextLabel")
TitleSet.Parent = SettingsPage
TitleSet.Size = UDim2.new(1,0,0,30)
TitleSet.BackgroundTransparency = 1
TitleSet.Text = "⚙️ SETTINGS HUB"
TitleSet.TextColor3 = Color3.fromRGB(0,170,255)
TitleSet.Font = Enum.Font.GothamBold
TitleSet.TextSize = 13

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = SettingsPage
CloseBtn.Size = UDim2.new(1,0,0,35)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
CloseBtn.Text = "Tutup / Hide UI"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
Instance.new("UICorner", CloseBtn)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local CredLbl = Instance.new("TextLabel")
CredLbl.Parent = CreditsPage
CredLbl.Size = UDim2.new(1,0,1,0)
CredLbl.BackgroundTransparency = 1
CredLbl.Text = "Created By UBEY"
CredLbl.TextColor3 = Color3.new(1,1,1)
CredLbl.Font = Enum.Font.GothamBold
CredLbl.TextSize = 20

----------------------------------------------------
-- KEY VERIFY (Supabase)
----------------------------------------------------
Submit.MouseButton1Click:Connect(function()
	Submit.Text = "MEMERIKSA..."
	if validateKey(Box.Text) then
		KeyFrame.Visible = false
		Blur.Visible = false
		Main.Visible = true
	else
		Submit.Text = "KEY SALAH"
		task.wait(1)
		Submit.Text = "VERIFY KEY"
	end
end)

----------------------------------------------------
-- FLOATING BUTTON HP & DRAG
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

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Parent = Float
FloatStroke.Color = Color3.fromRGB(0,170,255)

local Open = true
Float.MouseButton1Click:Connect(function()
	Open = not Open
	Main.Visible = Open
end)

local dragging = false
local dragStart, startPos

Float.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Float.Position
	end
end)

UIS.TouchMoved:Connect(function(input)
	if dragging then
		local delta = input.Position - dragStart
		Float.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.TouchEnded:Connect(function()
	dragging = false
end)
