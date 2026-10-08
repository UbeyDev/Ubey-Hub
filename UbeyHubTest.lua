local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

pcall(function()
	PlayerGui:FindFirstChild("UbeyHub"):Destroy()
end)

-- AUTO RECONNECT & SUPABASE KEY CONFIG
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

-- GLOBAL STATES
getgenv().AutoFishingRunning = false
getgenv().BiteDelay = 0.5
getgenv().AutoGalatamaRunning = false
getgenv().AutoSummitRunning = false
getgenv().AntiAFKRunning = false

local FishingSpots = {
	["Jembatan"] = CFrame.new(-6783.74, 1322.81, -9757.34),
	["Core"] = CFrame.new(-9069.33, 1250.32, -6510.33)
}

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

-- GUI SETUP (Sesuai Desain Polosmu yang Rapih)
local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

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

TweenService:Create(KeyFrame, TweenInfo.new(0.4,Enum.EasingStyle.Back), {Size = UDim2.new(0,360,0,240)}):Play()

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
Instance.new("UICorner", Box)

local Submit = Instance.new("TextButton")
Submit.Parent = KeyFrame
Submit.Position = UDim2.new(0.1,0,0,180)
Submit.Size = UDim2.new(0.8,0,0,35)
Submit.Text = "VERIFY KEY"
Submit.BackgroundColor3 = Color3.fromRGB(0,170,255)
Submit.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Submit)

----------------------------------------------------
-- MAIN HUB & PAGES
----------------------------------------------------
local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Visible = false
Main.Size = UDim2.new(0,550,0,320)
Main.Position = UDim2.new(0.5,-275,0.5,-160)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(0,170,255)

local Sidebar = Instance.new("Frame")
Sidebar.Parent = Main
Sidebar.Size = UDim2.new(0,140,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,20)
Instance.new("UICorner", Sidebar)

local HubTitle = Instance.new("TextLabel")
HubTitle.Parent = Sidebar
HubTitle.BackgroundTransparency = 1
HubTitle.Size = UDim2.new(1,0,0,60)
HubTitle.Text = "UBEY HUB"
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextColor3 = Color3.fromRGB(0,170,255)
HubTitle.TextSize = 20

local function MakeSidebarBtn(name, y)
	local btn = Instance.new("TextButton")
	btn.Parent = Sidebar
	btn.Position = UDim2.new(0,10,0,y)
	btn.Size = UDim2.new(1,-20,0,32)
	btn.Text = name
	btn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	Instance.new("UICorner", btn)
	return btn
end

local FishingBtn = MakeSidebarBtn("Fishing", 70)
local GalatamaBtn = MakeSidebarBtn("Galatama", 110)
local SummitBtn = MakeSidebarBtn("Summit", 150)
local PlayerBtn = MakeSidebarBtn("Player", 190)
local SettingsBtn = MakeSidebarBtn("Settings", 230)
local CreditsBtn = MakeSidebarBtn("Credits", 270)

local Content = Instance.new("ScrollingFrame")
Content.Parent = Main
Content.Position = UDim2.new(0,150,0,10)
Content.Size = UDim2.new(1,-160,1,-20)
Content.BackgroundTransparency = 1
Content.CanvasSize = UDim2.new(0,0,1.5,0)
Content.ScrollBarThickness = 4

local UIList = Instance.new("UIListLayout")
UIList.Parent = Content
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)

local function MakePage()
	local f = Instance.new("Frame")
	f.Parent = Content
	f.Size = UDim2.new(1,0,1,0)
	f.BackgroundTransparency = 1
	f.Visible = false
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

FishingBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
SettingsBtn.MouseButton1Click:Connect(function() HideAll(); SettingsPage.Visible = true end)
CreditsBtn.MouseButton1Click:Connect(function() HideAll(); CreditsPage.Visible = true end)

-- ISI HALAMAN FITUR (Fungsional)
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
		b.Text = "  " .. text .. (state and " [ON]" else " [OFF]")
		b.BackgroundColor3 = state and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
		callback(state)
	end)
end

-- Fishing Page Content
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
						rod.Mechanics.Remotes.CastEvent:FireServer(false, 100, Player.Character.HumanoidRootPart.CFrame.LookVector)
						task.wait(0.05)
						local hooked = false
						local conn
						conn = rod.Mechanics.Remotes.NotifyClient.OnClientEvent:Connect(function(action)
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
							rod.Mechanics.Remotes.MiniGame:FireServer(true)
							task.wait(0.3)
						end
					else task.wait(1) end
				end)
				task.wait(0.1)
			end
		end)
	end
end)

-- Galatama Page Content
AddToggle(GalatamaPage, "Auto Join Galatama", function(v)
	getgenv().AutoGalatamaRunning = v
	if v then
		task.spawn(function()
			while getgenv().AutoGalatamaRunning do
				pcall(function() ReplicatedStorage.Remote.Glatama.Ikut:InvokeServer() end)
				task.wait(10)
			end
		end)
	end
end)

-- Summit Page Content
AddToggle(SummitPage, "Auto Summit Loop", function(v)
	getgenv().AutoSummitRunning = v
end)
task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			pcall(function()
				local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					for i = 1, 20 do
						if not getgenv().AutoSummitRunning then break end
						pcall(function() ReplicatedStorage.Remote.Checkpoint.TpToCheckpoint:FireServer(i) end)
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

-- Player Page Content
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

-- Settings & Credits Page
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
-- KEY VERIFY
----------------------------------------------------
Submit.MouseButton1Click:Connect(function()
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
-- FLOATING BUTTON & DRAG MOBILE
----------------------------------------------------
local Float = Instance.new("ImageButton")
Float.Parent = Gui
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)
Instance.new("UICorner", Float).CornerRadius = UDim.new(1,0)

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
		Float.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UIS.TouchEnded:Connect(function()
	dragging = false
end)
