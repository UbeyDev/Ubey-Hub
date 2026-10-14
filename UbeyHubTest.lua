-- ==============================================================================
-- UBEY HUB V3 | Cleaned & Fixed Version (Timeout 15s)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
-- SUPABASE CONFIGURATION
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project"
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"

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

-- GLOBAL STATES & LOGIC
getgenv().AutoFishingEventRunning = false
getgenv().BiteDelayInput = "0.6"
getgenv().KeyVerified = false

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

pcall(function()
	PlayerGui:FindFirstChild("UbeyHub"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

----------------------------------------------------
-- KEY SYSTEM UI (SUPABASE 24H + HWID LOCK VERIFICATION)
----------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,210)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-105)
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
KeyTitle.Size = UDim2.new(1,0,0,45)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "UBEY HUB V3 - KEY SYSTEM (24H + HWID)"
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextColor3 = Color3.fromRGB(0,170,255)
KeyTitle.TextSize = 14

local KeyBox = Instance.new("TextBox")
KeyBox.Parent = KeyFrame
KeyBox.Size = UDim2.new(0,340,0,38)
KeyBox.Position = UDim2.new(0,20,0,55)
KeyBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
KeyBox.PlaceholderText = "Masukkan Key dari Website / VIP..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.new(1,1,1)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 13
Instance.new("UICorner", KeyBox)

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Parent = KeyFrame
SubmitKeyBtn.Size = UDim2.new(0,165,0,35)
SubmitKeyBtn.Position = UDim2.new(0,20,0,105)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Key"
SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextSize = 13
Instance.new("UICorner", SubmitKeyBtn)

local GetKeyLinkBtn = Instance.new("TextButton")
GetKeyLinkBtn.Parent = KeyFrame
GetKeyLinkBtn.Size = UDim2.new(0,165,0,35)
GetKeyLinkBtn.Position = UDim2.new(0,195,0,105)
GetKeyLinkBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
GetKeyLinkBtn.Text = "Get Key (Copy Link)"
GetKeyLinkBtn.TextColor3 = Color3.new(1,1,1)
GetKeyLinkBtn.Font = Enum.Font.GothamBold
GetKeyLinkBtn.TextSize = 13
Instance.new("UICorner", GetKeyLinkBtn)

local StatusKey = Instance.new("TextLabel")
StatusKey.Parent = KeyFrame
StatusKey.Size = UDim2.new(1,0,0,25)
StatusKey.Position = UDim2.new(0,0,0,160)
StatusKey.BackgroundTransparency = 1
StatusKey.Text = ""
StatusKey.Font = Enum.Font.Gotham
StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
StatusKey.TextSize = 12

GetKeyLinkBtn.MouseButton1Click:Connect(function()
	pcall(function()
		if setclipboard then
			setclipboard("https://loot-link.com/s?Bk7mrnMx")
		elseif toclipboard then
			toclipboard("https://loot-link.com/s?Bk7mrnMx")
		end
	end)
	StatusKey.TextColor3 = Color3.fromRGB(0, 170, 255)
	StatusKey.Text = "Link Key disalin! Buka browser untuk melewati iklan."
end)

SubmitKeyBtn.MouseButton1Click:Connect(function()
	local enteredKey = KeyBox.Text
	if enteredKey == "" then
		StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
		StatusKey.Text = "Masukkan key terlebih dahulu!"
		return
	end
	
	StatusKey.TextColor3 = Color3.fromRGB(255,200,0)
	StatusKey.Text = "Mengecek key ke database Supabase..."
	
	task.spawn(function()
		local requestFunc = syn and syn.request or http and http.request or request
		local queryUrl = SUPABASE_URL .. "?key_value=eq." .. HttpService:UrlEncode(enteredKey)
		
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({
					Url = queryUrl,
					Method = "GET",
					Headers = {
						["apikey"] = SUPABASE_ANON_KEY,
						["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
						["Content-Type"] = "application/json"
					}
				})
				return res.Body
			else
				return HttpService:GetAsync(queryUrl, false, {
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
				
				if record.created_at and not string.match(enteredKey, "^UBEY%-VIP%-") then
					local year, month, day, hour, min, sec = record.created_at:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
					if year then
						local createdTime = os.time({
							year = tonumber(year), month = tonumber(month), day = tonumber(day),
							hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec)
						})
						
						-- DIPERBAIKI: Menggunakan UTC time (os.date("!*t")) agar tidak konflik zona waktu device user
						local currentTime = os.time(os.date("!*t"))
						local hoursPassed = os.difftime(currentTime, createdTime) / 3600
						
						if hoursPassed < 0 then
							hoursPassed = 0
						end
						
						if hoursPassed > 24 then
							StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50)
							StatusKey.Text = "Key sudah kedaluwarsa! (Dapatkan key baru)"
							return
						end
					end
				end

				local deviceHWID = game:GetService("RbxAnalyticsService"):GetClientId()
				
				if record.hwid == nil or record.hwid == "" or record.hwid == "null" then
					local patchUrl = SUPABASE_URL .. "?key_value=eq." .. HttpService:UrlEncode(enteredKey)
					pcall(function()
						if requestFunc then
							requestFunc({
								Url = patchUrl,
								Method = "PATCH",
								Headers = {
									["apikey"] = SUPABASE_ANON_KEY,
									["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
									["Content-Type"] = "application/json",
									["Prefer"] = "return=minimal"
								},
								Body = HttpService:JSONEncode({ hwid = deviceHWID })
							})
						end
					end)
				elseif record.hwid ~= deviceHWID then
					StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50)
					StatusKey.Text = "Key ini sudah terkunci di perangkat lain!"
					return
				end

				StatusKey.TextColor3 = Color3.fromRGB(0, 255, 100)
				StatusKey.Text = "Key Valid & HWID Terkunci! Membuka Hub..."
				task.wait(1)
				getgenv().KeyVerified = true
				KeyFrame.Visible = false
				Main.Visible = true
			else
				StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
				StatusKey.Text = "Key Salah atau Tidak Ditemukan!"
			end
		else
			StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
			StatusKey.Text = "Gagal terhubung ke server Supabase."
		end
	end)
end)

----------------------------------------------------
-- MAIN HUB UI
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
Sidebar.CanvasSize = UDim2.new(0,0,1.5,0)
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
HomeBtn.Text = "Fishing"
HomeBtn.TextColor3 = Color3.new(1,1,1)
HomeBtn.Font = Enum.Font.GothamMedium
HomeBtn.TextSize = 12

local PlayerMenuBtn = HomeBtn:Clone()
PlayerMenuBtn.Parent = Sidebar
PlayerMenuBtn.Position = UDim2.new(0,10,0,100)
PlayerMenuBtn.Text = "Player"

local PlayerTpBtn = HomeBtn:Clone()
PlayerTpBtn.Parent = Sidebar
PlayerTpBtn.Position = UDim2.new(0,10,0,135)
PlayerTpBtn.Text = "Teleport Player"

local SettingsBtn = HomeBtn:Clone()
SettingsBtn.Parent = Sidebar
SettingsBtn.Position = UDim2.new(0,10,0,170)
SettingsBtn.Text = "Settings"

local CreditsBtn = HomeBtn:Clone()
CreditsBtn.Parent = Sidebar
CreditsBtn.Position = UDim2.new(0,10,0,205)
CreditsBtn.Text = "Credits"

for _,v in ipairs({HomeBtn, PlayerMenuBtn, PlayerTpBtn, SettingsBtn, CreditsBtn}) do
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
	f.CanvasSize = UDim2.new(0,0,4,0)
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
local PlayerPage = MakePage()
local PlayerTpPage = MakePage()
local SettingsPage = MakePage()
local CreditsPage = MakePage()

local function HideAll()
	FishingPage.Visible = false
	PlayerPage.Visible = false
	PlayerTpPage.Visible = false
	SettingsPage.Visible = false
	CreditsPage.Visible = false
end

HomeBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
PlayerMenuBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
PlayerTpBtn.MouseButton1Click:Connect(function() HideAll(); PlayerTpPage.Visible = true end)
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
-- 1. FISHING PAGE
----------------------------------------------------
local TitleFish = Instance.new("TextLabel")
TitleFish.Parent = FishingPage
TitleFish.Size = UDim2.new(1,0,0,30)
TitleFish.BackgroundTransparency = 1
TitleFish.Text = "🔥 AUTO FISHING UTILITIES"
TitleFish.TextColor3 = Color3.fromRGB(0,170,255)
TitleFish.Font = Enum.Font.GothamBold
TitleFish.TextSize = 13

local function RunAutoFishingLogic()
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
						
						task.wait(0.1)
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
							if tick() - start > 15 then break end
							task.wait(0.1)
						end
						if conn then conn:Disconnect() end
						
						if hooked and getgenv().AutoFishingEventRunning then
							task.wait(1.3)
							remoteFolder.MiniGame:FireServer(true)
							task.wait(0.9)
						end
					end
				else
					task.wait(1.5)
				end
			end)
			task.wait(0.2)
		end
	end)
end

AddToggle(FishingPage, "Smart Auto Fishing (Di Tempat Saja)", function(v)
	getgenv().AutoFishingEventRunning = v
	if v then
		OptimizeRodSettings()
		RunAutoFishingLogic()
	end
end)

----------------------------------------------------
-- 2. PLAYER PAGE
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

----------------------------------------------------
-- 3. TELEPORT PLAYER PAGE
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
		if child:IsA("TextButton") then child:Destroy() end
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

RefreshPlayerBtn.MouseButton1Click:Connect(function() ScanAndDisplayPlayers() end)
task.spawn(function() task.wait(2); ScanAndDisplayPlayers() end)

----------------------------------------------------
-- 4. SETTINGS & CREDITS PAGE
----------------------------------------------------
local TitleSet = Instance.new("TextLabel")
TitleSet.Parent = SettingsPage
TitleSet.Size = UDim2.new(1,0,0,30)
TitleSet.BackgroundTransparency = 1
TitleSet.Text = "⚙️ SETTINGS & PERFORMANCE"
TitleSet.TextColor3 = Color3.fromRGB(0,170,255)
TitleSet.Font = Enum.Font.GothamBold
TitleSet.TextSize = 13

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
