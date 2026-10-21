-- ==============================================================================
-- UBEY HUB | AUTO FISHING (PURE INSTANT - MINIGAME BYPASS)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
-- ⚙️ PENGATURAN (HARDCODE) ⚙️
------------------------------------------------------------------
getgenv().UbeyConfig = {
	CastDelay = 0.25,   -- Delay setelah lempar kail
	MiniDelay = 0.30,   -- Delay minigame
	GiveDelay = 0.20,   -- Delay klaim ikan
	AutoSellTimer = "5",
	WebhookEnabled = false,
	WebhookUrl = ""
}

getgenv().AutoFishingRunning = false
getgenv().AutoSellRunning = false
getgenv().TotalFishCaught = 0
getgenv().SessionStartTime = os.time()

------------------------------------------------------------------
-- SUPABASE KEY SYSTEM
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"
local KEY_FILE = "UbeyHub_SavedKey.txt"

local function GetDeviceHWID()
	local hwid = nil
	pcall(function()
		if gethwid then hwid = gethwid()
		elseif RbxAnalyticsService then hwid = RbxAnalyticsService:GetClientId() end
	end)
	return tostring(hwid or ("UNKNOWN_DEVICE_" .. tostring(LocalPlayer.UserId)))
end
local CurrentHWID = GetDeviceHWID()

------------------------------------------------------------------
-- HELPER: FISHING LOGIC (DARI SCRIPT CONTOH)
------------------------------------------------------------------
local function GetEquippedRodName()
	local char = LocalPlayer.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then return tool.Name end
	end
	return "Basic Rod"
end

local function TriggerSellAll()
	pcall(function()
		local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
		local sellRemote = fs and fs:FindFirstChild("SellFish")
		if sellRemote then sellRemote:FireServer() end
	end)
end

task.spawn(function()
	while true do
		task.wait(0.1)
		
		if getgenv().AutoFishingRunning then
			pcall(function()
				local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local hrp = char:WaitForChild("HumanoidRootPart", 3)
				if not hrp then return end
				
				local FS = ReplicatedStorage:WaitForChild("FishingSystem", 3)
				if not FS then return end
				
				local cast = FS:FindFirstChild("CastReplication")
				local mini = FS:FindFirstChild("MinigameStarted") -- KUNCI UTAMANYA!
				local clean = FS:FindFirstChild("CleanupCast")
				local give = FS:FindFirstChild("FishGiver")
				local currentRod = GetEquippedRodName()
				
				local pos = hrp.Position + Vector3.new(0, 2, 0)
				local lookVec = hrp.CFrame.LookVector * 15
				local hook = pos + lookVec - Vector3.new(0, 5, 0)
				
				-- 1. Lempar Kail
				if cast then
					cast:FireServer(pos, Vector3.new(-24.72, 5, 3.71), currentRod, 100)
				end
				
				task.wait(getgenv().UbeyConfig.CastDelay)
				if not getgenv().AutoFishingRunning then return end
				
				-- 2. Minigame (Bypass)
				if mini then
					mini:FireServer({
						hookPosition = hook,
						power = 50
					})
				end
				
				task.wait(getgenv().UbeyConfig.MiniDelay)
				if not getgenv().AutoFishingRunning then return end
				
				-- 3. Cleanup Cast
				if clean then
					clean:FireServer()
				end
				
				task.wait(0.05)
				
				-- 4. Claim Ikan (FishGiver)
				if give then
					give:FireServer({
						hookPosition = hook,
						power = 50
					})
					getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1
				end
				
				task.wait(getgenv().UbeyConfig.GiveDelay)
			end)
		end
	end
end)

------------------------------------------------------------------
-- AUTO RECONNECT
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

------------------------------------------------------------------
-- DRAGGABLE HELPER
------------------------------------------------------------------
local function MakeDraggable(guiObject, handleObject)
	handleObject = handleObject or guiObject
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	handleObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handleObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
end

------------------------------------------------------------------
-- DESTROY OLD GUI
------------------------------------------------------------------
pcall(function()
	local oldGui = PlayerGui:FindFirstChild("UbeyHub")
	if oldGui then oldGui:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

------------------------------------------------------------------
-- KEY SYSTEM UI
------------------------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,185)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-92)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
KeyFrame.Visible = false
MakeDraggable(KeyFrame)

local keyCorner = Instance.new("UICorner") keyCorner.CornerRadius = UDim.new(0,15) keyCorner.Parent = KeyFrame
local KeyStroke = Instance.new("UIStroke") KeyStroke.Parent = KeyFrame KeyStroke.Color = Color3.fromRGB(0,170,255)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyFrame
KeyTitle.Size = UDim2.new(1,0,0,50)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "UBEY HUB - HWID KEY SYSTEM"
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
local kbCorner = Instance.new("UICorner") kbCorner.Parent = KeyBox

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Parent = KeyFrame
SubmitKeyBtn.Size = UDim2.new(0,165,0,35)
SubmitKeyBtn.Position = UDim2.new(0,20,0,110)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Perangkat"
SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextSize = 12
local skCorner = Instance.new("UICorner") skCorner.Parent = SubmitKeyBtn

local GetKeyDiscordBtn = Instance.new("TextButton")
GetKeyDiscordBtn.Parent = KeyFrame
GetKeyDiscordBtn.Size = UDim2.new(0,165,0,35)
GetKeyDiscordBtn.Position = UDim2.new(0,195,0,110)
GetKeyDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GetKeyDiscordBtn.Text = "Get Key via Discord"
GetKeyDiscordBtn.TextColor3 = Color3.new(1,1,1)
GetKeyDiscordBtn.Font = Enum.Font.GothamBold
GetKeyDiscordBtn.TextSize = 12
local gkCorner = Instance.new("UICorner") gkCorner.Parent = GetKeyDiscordBtn

local StatusKey = Instance.new("TextLabel")
StatusKey.Parent = KeyFrame
StatusKey.Size = UDim2.new(1,0,0,20)
StatusKey.Position = UDim2.new(0,0,0,155)
StatusKey.BackgroundTransparency = 1
StatusKey.Text = ""
StatusKey.Font = Enum.Font.Gotham
StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
StatusKey.TextSize = 12

------------------------------------------------------------------
-- MAIN HUB UI
------------------------------------------------------------------
local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Visible = false
Main.Size = UDim2.new(0,550,0,320)
Main.Position = UDim2.new(0.5,-275,0.5,-160)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Main.ClipsDescendants = true
MakeDraggable(Main)

local mainCorner = Instance.new("UICorner") mainCorner.CornerRadius = UDim.new(0,18) mainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke") MainStroke.Parent = Main MainStroke.Color = Color3.fromRGB(0,170,255)

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
local minCorner = Instance.new("UICorner") minCorner.CornerRadius = UDim.new(0, 6) minCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = ControlsFrame
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.ZIndex = 11
local clsCorner = Instance.new("UICorner") clsCorner.CornerRadius = UDim.new(0, 6) clsCorner.Parent = CloseBtn

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
local sbCorner = Instance.new("UICorner") sbCorner.Parent = Sidebar

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
	local corner = Instance.new("UICorner") corner.Parent = btn
	return btn
end

local FishingBtn = CreateNavButton("🎣 Fishing", 60)
local SettingsBtn = CreateNavButton("⚙️ Settings", 95)
local CreditsBtn = CreateNavButton("👑 Credits", 130)

local function MakePage()
	local f = Instance.new("ScrollingFrame")
	f.Parent = Content
	f.Size = UDim2.new(1,0,1,0)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.CanvasSize = UDim2.new(0,0,6,0)
	f.ScrollBarThickness = 4
	local pad = Instance.new("UIPadding") pad.Parent = f pad.PaddingTop = UDim.new(0, 10)
	local l = Instance.new("UIListLayout") l.Parent = f l.SortOrder = Enum.SortOrder.LayoutOrder l.Padding = UDim.new(0, 8)
	return f
end

local FishingPage = MakePage() FishingPage.Visible = true
local SettingsPage = MakePage()
local CreditsPage = MakePage()

local function HideAll()
	for _, pg in ipairs({FishingPage, SettingsPage, CreditsPage}) do pg.Visible = false end
end

FishingBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
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
	local c = Instance.new("UICorner") c.Parent = b
	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = "  " .. text .. (state and " [ON]" or " [OFF]")
		b.BackgroundColor3 = state and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
		callback(state)
	end)
end

------------------------------------------------------------------
-- KEY VALIDATION
------------------------------------------------------------------
GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function() if setclipboard then setclipboard("https://discord.gg/YXuYeEpnXE") end end)
	StatusKey.TextColor3 = Color3.fromRGB(0,170,255)
	StatusKey.Text = "Link Discord disalin!"
end)

local function ValidateKey(enteredKey, isAutoLogin)
	if enteredKey == "" then
		if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Masukkan key terlebih dahulu!" end
		KeyFrame.Visible = true; return
	end
	if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,200,0) StatusKey.Text = "Memeriksa HWID & Key ke Server..." end
	
	task.spawn(function()
		local requestFunc = syn and syn.request or http and http.request or request
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({
					Url = SUPABASE_URL .. enteredKey, Method = "GET",
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
					KeyFrame.Visible = true; return
				end
				if record.hwid_value and record.hwid_value ~= "" and record.hwid_value ~= CurrentHWID then
					if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Key terikat di perangkat lain!" end
					KeyFrame.Visible = true; return
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
		if savedKey and savedKey ~= "" then KeyBox.Text = savedKey; ValidateKey(savedKey, true)
		else KeyFrame.Visible = true end
	else KeyFrame.Visible = true end
end)

------------------------------------------------------------------
-- PAGE 1: FISHING
------------------------------------------------------------------
local TitleFish = Instance.new("TextLabel")
TitleFish.Parent = FishingPage
TitleFish.Size = UDim2.new(1,0,0,30)
TitleFish.BackgroundTransparency = 1
TitleFish.Text = "🎣 AUTO FISHING (PURE INSTANT)"
TitleFish.TextColor3 = Color3.fromRGB(0,170,255)
TitleFish.Font = Enum.Font.GothamBold
TitleFish.TextSize = 13

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = FishingPage
InfoLabel.Size = UDim2.new(1,0,0,40)
InfoLabel.BackgroundColor3 = Color3.fromRGB(30,30,40)
InfoLabel.Text = "Instan Sequence:\nCast -> Mini -> Clean -> Give."
InfoLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 11
local ilc = Instance.new("UICorner") ilc.Parent = InfoLabel

AddToggle(FishingPage, "Auto Fishing (Instant)", function(v)
	getgenv().AutoFishingRunning = v
end)

AddToggle(FishingPage, "Auto Sell Ikan (Timer)", function(v)
	getgenv().AutoSellRunning = v
	if v then
		task.spawn(function()
			local lastSell = tick()
			while getgenv().AutoSellRunning do
				task.wait(1)
				if ((tick() - lastSell) / 60) >= (tonumber(getgenv().UbeyConfig.AutoSellTimer) or 5) then
					TriggerSellAll()
					lastSell = tick()
				end
			end
		end)
	end
end)

------------------------------------------------------------------
-- PAGE 2: SETTINGS
------------------------------------------------------------------
local TitleSet = Instance.new("TextLabel")
TitleSet.Parent = SettingsPage
TitleSet.Size = UDim2.new(1,0,0,30)
TitleSet.BackgroundTransparency = 1
TitleSet.Text = "⚙️ SETTINGS"
TitleSet.TextColor3 = Color3.fromRGB(0,170,255)
TitleSet.Font = Enum.Font.GothamBold
TitleSet.TextSize = 13

local AntiLagBtn = Instance.new("TextButton")
AntiLagBtn.Parent = SettingsPage
AntiLagBtn.Size = UDim2.new(1,0,0,35)
AntiLagBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
AntiLagBtn.Text = "⚡ Aktifkan Anti-Lag"
AntiLagBtn.TextColor3 = Color3.new(1,1,1)
AntiLagBtn.Font = Enum.Font.GothamBold
local alc = Instance.new("UICorner") alc.Parent = AntiLagBtn
AntiLagBtn.MouseButton1Click:Connect(function()
	pcall(function() Lighting.GlobalShadows = false; Lighting.FogEnd = 999999; AntiLagBtn.Text = "⚡ Anti-Lag Aktif!" end)
end)

------------------------------------------------------------------
-- PAGE 3: CREDITS
------------------------------------------------------------------
local CredLbl = Instance.new("TextLabel")
CredLbl.Parent = CreditsPage
CredLbl.Size = UDim2.new(1,0,1,0)
CredLbl.BackgroundTransparency = 1
CredLbl.Text = "Created By UBEY"
CredLbl.TextColor3 = Color3.new(1,1,1)
CredLbl.Font = Enum.Font.GothamBold
CredLbl.TextSize = 20

------------------------------------------------------------------
-- STAT PANEL BAWAH
------------------------------------------------------------------
local StatPanel = Instance.new("Frame")
StatPanel.Parent = Main
StatPanel.Size = UDim2.new(1, -160, 0, 24)
StatPanel.Position = UDim2.new(0, 150, 1, -28)
StatPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
StatPanel.BorderSizePixel = 0
local stpCorner = Instance.new("UICorner") stpCorner.CornerRadius = UDim.new(0, 6) stpCorner.Parent = StatPanel

local StatLabel = Instance.new("TextLabel")
StatLabel.Parent = StatPanel
StatLabel.Size = UDim2.new(1, -10, 1, 0)
StatLabel.Position = UDim2.new(0, 5, 0, 0)
StatLabel.BackgroundTransparency = 1
StatLabel.Text = "📊 Fish: 0  |  ⏱️ 00s"
StatLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
StatLabel.Font = Enum.Font.GothamBold
StatLabel.TextSize = 11
StatLabel.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
	while true do
		pcall(function()
			local elapsed = os.time() - getgenv().SessionStartTime
			local hours = math.floor(elapsed / 3600)
			local mins = math.floor((elapsed % 3600) / 60)
			local secs = elapsed % 60
			local timeStr = ""
			if hours > 0 then timeStr = string.format("%02dh %02dm %02ds", hours, mins, secs)
			elseif mins > 0 then timeStr = string.format("%02dm %02ds", mins, secs)
			else timeStr = string.format("%02ds", secs) end
			StatLabel.Text = string.format("📊 Fish: %d  |  ⏱️ %s", getgenv().TotalFishCaught, timeStr)
		end)
		task.wait(1)
	end
end)

------------------------------------------------------------------
-- FLOATING BUTTON
------------------------------------------------------------------
local Float = Instance.new("ImageButton")
Float.Parent = Gui
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)
local flCorner = Instance.new("UICorner") flCorner.CornerRadius = UDim.new(1,0) flCorner.Parent = Float
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
