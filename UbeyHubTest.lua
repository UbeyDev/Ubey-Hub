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

print("[UBEY DEBUG] 1. Layanan utama dimuat.")

pcall(function()
	PlayerGui:FindFirstChild("UbeyHub"):Destroy()
end)

-- SUPABASE KEY CONFIG
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
				Headers = {["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " + SUPABASE_KEY}
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

print("[UBEY DEBUG] 2. Key system siap.")

-- GUI UTAMA (Persis seperti GUI Polosmu)
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
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0,18)

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

print("[UBEY DEBUG] 3. GUI Key berhasil dibuat.")

-- MAIN HUB
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

FishingBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
SettingsBtn.MouseButton1Click:Connect(function() HideAll(); SettingsPage.Visible = true end)
CreditsBtn.MouseButton1Click:Connect(function() HideAll(); CreditsPage.Visible = true end)

print("[UBEY DEBUG] 4. Sidebar dan halaman berhasil dimuat.")

-- TOMBOL VERIFIKASI KEY
Submit.MouseButton1Click:Connect(function()
	if validateKey(Box.Text) then
		KeyFrame.Visible = false
		Blur.Visible = false
		Main.Visible = true
		print("[UBEY DEBUG] Key benar, Hub dibuka.")
	else
		Submit.Text = "KEY SALAH"
		task.wait(1)
		Submit.Text = "VERIFY KEY"
	end
end)

-- FLOATING BUTTON & DRAG
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

print("[UBEY DEBUG] 5. Script sukses berjalan sepenuhnya tanpa error!")
