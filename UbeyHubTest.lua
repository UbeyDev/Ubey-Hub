-- ==============================================================================
-- UBEY HUB V3 | Custom GUI + Full Features (Fishing, Galatama, Summit, Player)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- AUTO RECONNECT SYSTEM
------------------------------------------------------------------
task.spawn(function()
	pcall(function()
		CoreGui.ChildAdded:Connect(function(child)
			if child.Name == "ErrorPrompt" or child.Name == "DisconnectPrompt" then
				task.wait(1)
				pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end)
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
	if setclipboard then setclipboard("https://discord.gg/aCbAWe9PYB") end
end)

-- GLOBAL STATES & LOGIC
getgenv().AutoFishingRunning = false
getgenv().BiteDelay = 0.5
getgenv().AutoGalatamaRunning = false
getgenv().AutoSummitRunning = false
getgenv().AntiAFKRunning = false

local function GetRod()
	local char = Player.Character
	if char then
		local rod = char:FindFirstChild("Withering Rod") or Player.Backpack:FindFirstChild("Withering Rod")
		if rod and not char:FindFirstChild("Withering Rod") and char:FindFirstChildOfClass("Humanoid") then
			char.Humanoid:EquipTool(rod)
			task.wait(0.3)
		end
		return char:FindFirstChild("Withering Rod")
	end
end

local function OptimizeRod()
	pcall(function()
		local rod = GetRod()
		if rod and rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Settings") then
			if rod.Mechanics.Settings:FindFirstChild("Time_before_getfish") then
				rod.Mechanics.Settings.Time_before_getfish.Value = 0.05
			end
			if rod.Mechanics.Settings:FindFirstChild("EnableMiniGame") then
				rod.Mechanics.Settings.EnableMiniGame.Value = false
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

-- Tombol Sidebar (Dihasilkan dari kustomisasimu)
local HomeBtn = Instance.new("TextButton")
HomeBtn.Parent = Sidebar
HomeBtn.Position = UDim2.new(0,10,0,70)
HomeBtn.Size = UDim2.new(1,-20,0,30)
HomeBtn.Text = "Fishing"
HomeBtn.TextColor3 = Color3.new(1,1,1)
HomeBtn.Font = Enum.Font.GothamMedium
HomeBtn.TextSize = 13

local GalatamaBtn = HomeBtn:Clone()
GalatamaBtn.Parent = Sidebar
GalatamaBtn.Position = UDim2.new(0,10,0,110)
GalatamaBtn.Text = "Galatama"

local SummitBtn = HomeBtn:Clone()
SummitBtn.Parent = Sidebar
SummitBtn.Position = UDim2.new(0,10,0,150)
SummitBtn.Text = "Summit"

local PlayerMenuBtn = HomeBtn:Clone()
PlayerMenuBtn.Parent = Sidebar
PlayerMenuBtn.Position = UDim2.new(0,10,0,190)
PlayerMenuBtn.Text = "Player"

local SettingsBtn = HomeBtn:Clone()
SettingsBtn.Parent = Sidebar
SettingsBtn.Position = UDim2.new(0,10,0,230)
SettingsBtn.Text = "Settings"

local CreditsBtn = HomeBtn:Clone()
CreditsBtn.Parent = Sidebar
CreditsBtn.Position = UDim2.new(0,10,0,270)
CreditsBtn.Text = "Credits"

for _,v in ipairs({HomeBtn, GalatamaBtn, SummitBtn, PlayerMenuBtn, SettingsBtn, CreditsBtn}) do
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
	f.CanvasSize = UDim2.new(0,0,2,0)
	f.ScrollBarThickness = 4
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
local SettingsPage = MakePage()
local CreditsPage = MakePage()

local function HideAll()
	FishingPage.Visible = false
	GalatamaPage.Visible = false
	SummitPage.Visible = false
	PlayerPage.Visible = false
	SettingsPage.Visible = false
	CreditsPage.Visible = false
end

HomeBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerMenuBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
SettingsBtn.MouseButton1Click:Connect(function() HideAll(); SettingsPage.Visible = true end)
CreditsBtn.MouseButton1Click:Connect(function() HideAll(); CreditsPage.Visible = true end)

-- FUNGSI PEMBUAT TOMBOL FITUR DALAM HALAMAN
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

-- ISI FITUR FISHING
AddToggle(FishingPage, "Smart Auto Fishing", function(v)
	getgenv().AutoFishingRunning = v
	if v then
		OptimizeRod()
		task.spawn(function()
			while getgenv().AutoFishingRunning do
				pcall(function()
					local rod = GetRod()
					if rod and rod:FindFirstChild("Mechanics") then
						OptimizeRod()
						local remoteFolder = rod.Mechanics:FindFirstChild("Remotes")
						if remoteFolder then
							remoteFolder.CastEvent:FireServer(false, 100, Player.Character.HumanoidRootPart.CFrame.LookVector)
							task.wait(0.05)
							local hooked = false
							local conn
							conn = remoteFolder.NotifyClient.OnClientEvent:Connect(function(action)
								if action == "Bite" then hooked = true if conn then conn:Disconnect() end end
							end)
							local start = tick()
							while not hooked and getgenv().AutoFishingRunning do
								if tick() - start > 10 then break end
								task.wait(0.05)
							end
							if conn then conn:Disconnect() end
							if hooked and getgenv().AutoFishingRunning then
								task.wait(getgenv().BiteDelay)
								remoteFolder.MiniGame:FireServer(true)
								task.wait(0.3)
							end
						end
					else task.wait(1) end
				end)
				task.wait(0.1)
			end
		end)
	end
end)

-- ISI FITUR GALATAMA
AddToggle(GalatamaPage, "Auto Join Galatama", function(v)
	getgenv().AutoGalatamaRunning = v
	if v then
		task.spawn(function()
			while getgenv().AutoGalatamaRunning do
				pcall(function()
					local ikut = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Glatama") and ReplicatedStorage.Remote.Glatama:FindFirstChild("Ikut")
					if ikut then ikut:InvokeServer() end
				end)
				task.wait(10)
			end
		end)
	end
end)

-- ISI FITUR SUMMIT
AddToggle(SummitPage, "Auto Summit Loop", function(v)
	getgenv().AutoSummitRunning = v
end)
task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			pcall(function()
				local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
				local tpCP = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Checkpoint") and ReplicatedStorage.Remote.Checkpoint:FindFirstChild("TpToCheckpoint")
				if hrp and tpCP then
					for i = 1, 20 do
						if not getgenv().AutoSummitRunning then break end
						pcall(function() tpCP:FireServer(i) end)
						task.wait(0.1)
					end
					hrp.CFrame = CFrame.new(-6766.44, 1312.69, -10083.80)
					task.wait(1)
				end
			end)
		end
		task.wait(0.5)
	end
end)

-- ISI FITUR PLAYER (WalkSpeed & Anti-AFK)
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
	if num then pcall(function() Player.Character.Humanoid.WalkSpeed = num end) end
end)

AddToggle(PlayerPage, "Anti-AFK", function(v)
	getgenv().AntiAFKRunning = v
end)
Player.Idled:Connect(function()
	if getgenv().AntiAFKRunning then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0,0))
	end
end)

-- SETTINGS PAGE
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

-- CREDITS PAGE
local CredLbl = Instance.new("TextLabel")
CredLbl.Parent = CreditsPage
CredLbl.Size = UDim2.new(1,0,1,0)
CredLbl.BackgroundTransparency = 1
CredLbl.Text = "Created By UBEY"
CredLbl.TextColor3 = Color3.new(1,1,1)
CredLbl.Font = Enum.Font.GothamBold
CredLbl.TextSize = 20

----------------------------------------------------
-- KEY VERIFY (Koneksi Supabase)
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
