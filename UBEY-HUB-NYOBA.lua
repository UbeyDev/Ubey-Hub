-- ==============================================================================
-- UBEY HUB | AUTO FISHING + AUTO SUMMIT + USERNAME KEY SYSTEM
-- [SECURITY FIXED] Local Variable Key + Loop Protection + New GUI
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
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [SECURITY FIX] Variabel lokal, tidak bisa diubah via console getgenv()
local IsKeyVerified = false

-- ====== PENGATURAN TAMPILAN (EDIT DI SINI) ======
local HUB_TITLE = "UBEY HUB"
local HUB_DISCORD = "discord.gg/YXuYeEpnXE"
local DISCORD_LINK = "https://discord.gg/YXuYeEpnXE"
local LOGO_ASSET = "rbxassetid://90770802417381"
-- ================================================

------------------------------------------------------------------
-- ⚙️ CONFIG & FILE SAVE
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHub_Config.json"
local KEY_FILE = "UbeyHub_SavedKey.txt"

getgenv().UbeyConfig = {
	WaitTime = 4.0,
	LoopDelay = 0.1,
	AutoSellTimer = "5",
}

local function SaveConfig()
	pcall(function()
		if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().UbeyConfig)) end
	end)
end

local function LoadConfig()
	pcall(function()
		if readfile and isfile and isfile(CONFIG_FILE) then
			local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
			if type(data) == "table" then
				for k, v in pairs(data) do
					if getgenv().UbeyConfig[k] ~= nil then getgenv().UbeyConfig[k] = v end
				end
			end
		end
	end)
end
LoadConfig()

getgenv().AutoFishingRunning = false
getgenv().AutoSellRunning = false
getgenv().AutoSummitRunning = false
getgenv().TotalFishCaught = 0
getgenv().TotalSummitRun = 0
getgenv().SessionStartTime = os.time()

pcall(function() GuiService:SetGameplayPausedNotificationEnabled(false) end)

------------------------------------------------------------------
-- SUPABASE KEY SYSTEM & USERNAME VALIDATION
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_rMWL7Qrjw9iG0c29vGZ0bw_O3swXT6n"

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
-- HELPER: FISHING LOGIC
------------------------------------------------------------------
local function GetEquippedRodName()
	local char = LocalPlayer.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then return tool.Name end
	end
	return nil
end

local function TriggerSellAll()
	pcall(function()
		local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
		local sellRemote = fs and fs:FindFirstChild("SellFish")
		if sellRemote then sellRemote:FireServer() end
	end)
end

task.spawn(function()
	local FS = ReplicatedStorage:WaitForChild("FishingSystem", 10)
	if not FS then return end
	
	local CastReplication = FS:WaitForChild("CastReplication")
	local CleanupCast = FS:WaitForChild("CleanupCast")
	local FishGiver = FS:WaitForChild("FishGiver")

	while true do
		if getgenv().AutoFishingRunning and IsKeyVerified then
			pcall(function()
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local currentRod = GetEquippedRodName()

				if root and currentRod then
					local pPos = root.Position
					local castVec = pPos + (root.CFrame.LookVector * 15)
					local hookVec = castVec - Vector3.new(0, 8, 0)

					CleanupCast:FireServer()
					task.wait(0.05)
					CastReplication:FireServer(castVec, Vector3.new(0, 5, 24), currentRod, 90)
					task.wait(tonumber(getgenv().UbeyConfig.WaitTime) or 4.0)
					FishGiver:FireServer({ hookPosition = hookVec, powerPercent = 0 })
					task.wait(0.1)
					CleanupCast:FireServer()
					getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1
				end
			end)
			task.wait(tonumber(getgenv().UbeyConfig.LoopDelay) or 0.1)
		else
			task.wait(0.5)
		end
	end
end)

------------------------------------------------------------------
-- HELPER: SUMMIT LOGIC (WAYPOINT + TIMER BYPASS)
------------------------------------------------------------------
local waypoints = {
	Vector3.new(-4.2, 16.3, 886.5),
	Vector3.new(-176.9, 79.6, 1907.9),
	Vector3.new(0.5, 131.2, 2793.1),
	Vector3.new(-1107.6, 362.1, 3266.3),
	Vector3.new(-1236.0, 504.5, 3828.8),
	Vector3.new(-1754.2, 730.9, 4525.4),
	Vector3.new(-1814.4, 746.4, 5568.2),
	Vector3.new(-2882.8, 740.9, 6129.6),
	Vector3.new(-3485.3, 740.2, 6524.1),
	Vector3.new(-3071.4, 794.4, 7228.8),
	Vector3.new(-2916.1, 835.4, 7965.9),
	Vector3.new(-2932.0, 849.1, 8838.7),
	Vector3.new(-3510.9, 1021.1, 9350.6),
	Vector3.new(-3472.3, 1021.8, 10147.4),
	Vector3.new(-3613.4, 1022.4, 10852.6),
	Vector3.new(-3849.1, 1048.2, 11692.4),
	Vector3.new(-4051.8, 1115.9, 12606.3),
	Vector3.new(-3995.3, 1197.4, 13586.2),
	Vector3.new(-4306.6, 1276.0, 14465.3),
	Vector3.new(-4564.7, 1295.0, 15327.3),
	Vector3.new(-4747.6, 1323.8, 16335.5),
	Vector3.new(-4821.9, 1366.9, 17051.8),
	Vector3.new(-5133.6, 1531.3, 17596.4),
	Vector3.new(-5339.5, 1631.6, 18276.7),
	Vector3.new(-5362.9, 1737.9, 19296.5),
	Vector3.new(-5376.3, 1761.7, 19944.1),
	Vector3.new(-5593.8, 1890.4, 20588.2),
	Vector3.new(-5700.9, 1975.2, 21045.2),
	Vector3.new(-6024.9, 1977.4, 21183.8),
	Vector3.new(-6633.9, 2048.1, 21482.6),
	Vector3.new(-6634.3, 2230.0, 22351.3),
}

task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning and IsKeyVerified then
			pcall(function()
				local permisiFolder = workspace:FindFirstChild("permisi")
				local basecampFolder = workspace:FindFirstChild("BASECAMP")
				local touchedList = {}

				local function checkAndTouchCP()
					if not permisiFolder then return end
					for _, part in ipairs(permisiFolder:GetChildren()) do
						if part:IsA("BasePart") and not touchedList[part] then
							touchedList[part] = true
							if firetouchinterest then
								local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
								if hrp then
									firetouchinterest(hrp, part, 0)
									task.wait(0.05)
									firetouchinterest(hrp, part, 1)
								end
							end
						end
					end
				end

				local function tpToBasecamp()
					if basecampFolder then
						local tpPart2 = basecampFolder:FindFirstChild("TeleportPart2")
						local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						if tpPart2 and hrp then
							hrp.CFrame = tpPart2.CFrame
							if firetouchinterest then
								firetouchinterest(hrp, tpPart2, 0)
								task.wait(0.1)
								firetouchinterest(hrp, tpPart2, 1)
							end
						end
					end
				end

				local function safeTeleport(targetPos)
					local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if not hrp then return end
					pcall(function()
						LocalPlayer:RequestStreamAroundAsync(targetPos)
					end)
					hrp.CFrame = CFrame.new(targetPos)
				end

				touchedList = {}
				
				for index, pos in ipairs(waypoints) do
					if not getgenv().AutoSummitRunning or not IsKeyVerified then break end
					
					safeTeleport(pos)
					
					local timer = 0
					while timer < 8 and getgenv().AutoSummitRunning do
						checkAndTouchCP()
						task.wait(0.5)
						timer = timer + 0.5
					end
				end
				
				if getgenv().AutoSummitRunning then
					getgenv().TotalSummitRun = getgenv().TotalSummitRun + 1
					task.wait(3)
					tpToBasecamp()
					task.wait(3)
				end
			end)
			task.wait(1)
		else
			task.wait(0.5)
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

-- ==============================================================================
--                                  NEW GUI (UBEY STYLE)
-- ==============================================================================
pcall(function()
	local old = PlayerGui:FindFirstChild("UbeyHub")
	if old then old:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

local C = {
	bg = Color3.fromRGB(9, 12, 26), side = Color3.fromRGB(13, 17, 36),
	card = Color3.fromRGB(15, 21, 44), line = Color3.fromRGB(30, 42, 90),
	accent = Color3.fromRGB(45, 95, 255), off = Color3.fromRGB(32, 44, 105),
	text = Color3.fromRGB(240, 243, 255), sub = Color3.fromRGB(150, 160, 195),
	good = Color3.fromRGB(0, 230, 150), bad = Color3.fromRGB(255, 80, 80),
	warn = Color3.fromRGB(255, 200, 0)
}

local function New(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function Round(o, r) return New("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function Label(parent, text, size, color, font, pos, sz, align)
	return New("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size, TextColor3 = color,
		Font = font, Position = pos or UDim2.new(), Size = sz or UDim2.new(1, 0, 1, 0),
		TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
	}, parent)
end

local function MakeDraggable(obj, handle)
	handle = handle or obj
	local dragging, dragInput, dragStart, startPos, moved
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart, startPos = input.Position, obj.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local d = input.Position - dragStart
			if d.Magnitude > 6 then moved = true end
			obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	return function() return moved end
end

------------------------------------------------------------------
-- KEY FRAME
------------------------------------------------------------------
local KeyFrame = New("Frame", {
	Size = UDim2.new(0, 400, 0, 230), Position = UDim2.new(0.5, -200, 0.5, -115),
	BackgroundColor3 = C.bg, Visible = false
}, Gui)
Round(KeyFrame, 14)
New("UIStroke", {Color = C.line, Thickness = 1.5}, KeyFrame)
MakeDraggable(KeyFrame)

Label(KeyFrame, HUB_TITLE .. " • Key System", 16, C.text, Enum.Font.GothamBold, UDim2.new(0, 20, 0, 14), UDim2.new(1, -40, 0, 22))
Label(KeyFrame, HUB_DISCORD, 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 20, 0, 36), UDim2.new(1, -40, 0, 16))
Label(KeyFrame, "Masukkan key dari bot Discord untuk melanjutkan.", 12, C.sub, Enum.Font.Gotham, UDim2.new(0, 20, 0, 62), UDim2.new(1, -40, 0, 18))

local KeyBox = New("TextBox", {
	Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 88),
	BackgroundColor3 = C.card, PlaceholderText = "Paste key di sini...", PlaceholderColor3 = C.sub,
	Text = "", TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false
}, KeyFrame)
Round(KeyBox, 10)
New("UIStroke", {Color = C.line}, KeyBox)

local SubmitKeyBtn = New("TextButton", {
	Size = UDim2.new(0.5, -26, 0, 38), Position = UDim2.new(0, 20, 0, 140),
	BackgroundColor3 = C.accent, Text = "Verifikasi Key", TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 13
}, KeyFrame)
Round(SubmitKeyBtn, 10)

local GetKeyDiscordBtn = New("TextButton", {
	Size = UDim2.new(0.5, -26, 0, 38), Position = UDim2.new(0.5, 6, 0, 140),
	BackgroundColor3 = Color3.fromRGB(88, 101, 242), Text = "Get Key (Discord)", TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 13
}, KeyFrame)
Round(GetKeyDiscordBtn, 10)

local StatusKey = Label(KeyFrame, "", 12, C.bad, Enum.Font.Gotham, UDim2.new(0, 20, 0, 190), UDim2.new(1, -40, 0, 22), Enum.TextXAlignment.Center)

------------------------------------------------------------------
-- MAIN WINDOW
------------------------------------------------------------------
local WIN_W, WIN_H = 580, 340
local Main = New("Frame", {
	Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
	BackgroundColor3 = C.bg, Visible = false, ClipsDescendants = true
}, Gui)
Round(Main, 14)
New("UIStroke", {Color = C.line, Thickness = 1.5}, Main)

local Header = New("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1}, Main)
MakeDraggable(Main, Header)
Label(Header, HUB_TITLE, 15, C.text, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 5), UDim2.new(0, 110, 0, 20))
Label(Header, "PREMIUM", 10, C.warn, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 23), UDim2.new(0, 110, 0, 14))
Label(Header, HUB_DISCORD, 10, C.sub, Enum.Font.Gotham, UDim2.new(0, 112, 0, 0), UDim2.new(0, 130, 1, 0))

local StatLabel = Label(Header, "📡 -- ms", 11, C.accent, Enum.Font.GothamBold, UDim2.new(0, 245, 0, 0), UDim2.new(1, -330, 1, 0), Enum.TextXAlignment.Right)

local MinimizeBtn = New("TextButton", {
	Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -78, 0, 6), BackgroundTransparency = 1,
	Text = "—", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16
}, Header)
local CloseBtn = New("TextButton", {
	Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -42, 0, 6), BackgroundTransparency = 1,
	Text = "✕", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16
}, Header)

local Body = New("Frame", {Size = UDim2.new(1, 0, 1, -42), Position = UDim2.new(0, 0, 0, 42), BackgroundTransparency = 1}, Main)

local Sidebar = New("ScrollingFrame", {
	Size = UDim2.new(0, 150, 1, -10), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
	ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0
}, Body)
New("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)

New("Frame", {Size = UDim2.new(0, 2, 1, -24), Position = UDim2.new(0, 166, 0, 4), BackgroundColor3 = C.accent, BorderSizePixel = 0}, Body)

local Content = New("Frame", {Size = UDim2.new(1, -186, 1, 0), Position = UDim2.new(0, 178, 0, 0), BackgroundTransparency = 1}, Body)
local PageTitle = Label(Content, "", 19, C.text, Enum.Font.GothamBold, UDim2.new(0, 2, 0, 0), UDim2.new(1, 0, 0, 30))
local PagesHolder = New("Frame", {Size = UDim2.new(1, 0, 1, -44), Position = UDim2.new(0, 0, 0, 38), BackgroundTransparency = 1}, Content)

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	Body.Visible = not isMinimized
	TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
		Size = UDim2.new(0, WIN_W, 0, isMinimized and 42 or WIN_H)
	}):Play()
end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

task.spawn(function()
	while true do
		pcall(function()
			local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			local elapsed = os.time() - getgenv().SessionStartTime
			local h, m, s = math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60
			local t = h > 0 and string.format("%dh %02dm", h, m) or string.format("%02dm %02ds", m, s)
			StatLabel.Text = string.format("📡 %d ms | 🎣 %d | ⛰️ %d | ⏱ %s", ping, getgenv().TotalFishCaught, getgenv().TotalSummitRun, t)
		end)
		task.wait(1)
	end
end)

------------------------------------------------------------------
-- UI LIBRARY
------------------------------------------------------------------
local UI = {}
local Tabs = {}

function UI.Tab(name, icon)
	local btn = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.card, BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "", LayoutOrder = #Tabs + 1
	}, Sidebar)
	Round(btn, 10)
	local bar = New("Frame", {Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = C.accent, Visible = false, BorderSizePixel = 0}, btn)
	Round(bar, 2)
	Label(btn, icon, 15, C.text, Enum.Font.Gotham, UDim2.new(0, 12, 0, 0), UDim2.new(0, 24, 1, 0), Enum.TextXAlignment.Center)
	local lbl = Label(btn, name, 12, C.sub, Enum.Font.GothamMedium, UDim2.new(0, 42, 0, 0), UDim2.new(1, -46, 1, 0))

	local page = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	}, PagesHolder)
	New("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
	New("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8)}, page)

	local tab = {Button = btn, Bar = bar, Label = lbl, Page = page, Name = name}
	table.insert(Tabs, tab)

	btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(Tabs) do
			local on = (t == tab)
			t.Page.Visible = on
			t.Bar.Visible = on
			t.Button.BackgroundTransparency = on and 0 or 1
			t.Label.TextColor3 = on and C.text or C.sub
		end
		PageTitle.Text = name
	end)
	if #Tabs == 1 then
		page.Visible, bar.Visible = true, true
		btn.BackgroundTransparency = 0
		lbl.TextColor3 = C.text
		PageTitle.Text = name
	end
	return page
end

local function Card(page, h)
	local f = New("Frame", {Size = UDim2.new(1, -4, 0, h or 54), BackgroundColor3 = C.card}, page)
	Round(f, 10)
	New("UIStroke", {Color = C.line, Thickness = 1}, f)
	return f
end

local function CardText(card, title, desc, rightPad)
	Label(card, title, 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, 12, 0, 8), UDim2.new(1, -rightPad, 0, 18))
	if desc and desc ~= "" then
		Label(card, desc, 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 12, 0, 27), UDim2.new(1, -rightPad, 0, 18))
	end
end

function UI.Section(page, text, color)
	return Label(page, text, 12, color or C.accent, Enum.Font.GothamBold, nil, UDim2.new(1, -4, 0, 22))
end

function UI.Toggle(page, title, desc, default, cb)
	local card = Card(page)
	CardText(card, title, desc, 80)
	local sw = New("TextButton", {
		Text = "", AutoButtonColor = false, Size = UDim2.new(0, 44, 0, 22),
		Position = UDim2.new(1, -56, 0.5, -11), BackgroundColor3 = C.off
	}, card)
	Round(sw, 11)
	local knob = New("Frame", {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = C.accent}, sw)
	Round(knob, 8)
	local state = default and true or false
	local function render()
		local ti = TweenInfo.new(0.15)
		TweenService:Create(knob, ti, {
			Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
			BackgroundColor3 = state and Color3.new(1, 1, 1) or C.accent
		}):Play()
		TweenService:Create(sw, ti, {BackgroundColor3 = state and C.accent or C.off}):Play()
	end
	render()
	sw.MouseButton1Click:Connect(function()
		state = not state
		render()
		task.spawn(cb, state)
	end)
	return {Set = function(v) state = v and true or false; render() end}
end

function UI.Button(page, title, desc, btnText, cb, color)
	local card = Card(page)
	CardText(card, title, desc, 130)
	local b = New("TextButton", {
		Size = UDim2.new(0, 104, 0, 30), Position = UDim2.new(1, -116, 0.5, -15),
		BackgroundColor3 = color or C.accent, Text = btnText, TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd
	}, card)
	Round(b, 8)
	b.MouseButton1Click:Connect(function() task.spawn(cb, b) end)
	return b, card
end

function UI.Input(page, title, desc, default, placeholder, cb)
	local card = Card(page)
	CardText(card, title, desc, 140)
	local box = New("TextBox", {
		Size = UDim2.new(0, 112, 0, 30), Position = UDim2.new(1, -124, 0.5, -15),
		BackgroundColor3 = C.bg, Text = tostring(default or ""), PlaceholderText = placeholder or "",
		PlaceholderColor3 = C.sub, TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false
	}, card)
	Round(box, 8)
	New("UIStroke", {Color = C.line}, box)
	box.FocusLost:Connect(function() cb(box.Text) end)
	return box
end

local function Flash(btn, text, ok)
	local old = btn.Text
	local oldColor = btn.BackgroundColor3
	btn.Text = text
	btn.BackgroundColor3 = ok and C.good or C.bad
	task.wait(1.8)
	btn.Text = old
	btn.BackgroundColor3 = oldColor
end

------------------------------------------------------------------
-- TABS
------------------------------------------------------------------
local FishingPage = UI.Tab("Fishing & Sell", "🎣")
local SummitPage = UI.Tab("Summit Farm", "⛰️")
local SettingsPage = UI.Tab("Settings", "⚙️")
local CreditsPage = UI.Tab("Credits", "💎")

------------------------------------------------------------------
-- KEY VALIDATION (SECURE)
------------------------------------------------------------------
GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	local ok = pcall(function() setclipboard(DISCORD_LINK) end)
	StatusKey.TextColor3 = ok and C.accent or C.bad
	StatusKey.Text = ok and "Link Discord disalin!" or ("Buka manual: " .. DISCORD_LINK)
end)

local function CheckUsernameInList(allowedUsersStr, currentUsername)
	if not allowedUsersStr or allowedUsersStr == "" then return false end
	for name in string.gmatch(allowedUsersStr, "[^,%s]+") do
		if string.lower(name) == string.lower(currentUsername) then return true end
	end
	return false
end

local function KeyFail(isAutoLogin, msg)
	if not isAutoLogin then
		StatusKey.TextColor3 = C.bad
		StatusKey.Text = msg
	end
	KeyFrame.Visible = true
end

local function PatchKey(requestFunc, key, body)
	pcall(function()
		if requestFunc then
			requestFunc({
				Url = SUPABASE_URL .. HttpService:UrlEncode(key), Method = "PATCH",
				Headers = {
					["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
					["Content-Type"] = "application/json"
				},
				Body = HttpService:JSONEncode(body)
			})
		end
	end)
end

local function ValidateKey(enteredKey, isAutoLogin)
	if enteredKey == "" then
		KeyFail(isAutoLogin, "Masukkan Key terlebih dahulu!")
		return
	end
	if not isAutoLogin then
		StatusKey.TextColor3 = C.warn
		StatusKey.Text = "Memeriksa validasi akun & key..."
	end

	task.spawn(function()
		local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({
					Url = SUPABASE_URL .. HttpService:UrlEncode(enteredKey), Method = "GET",
					Headers = {
						["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
						["Content-Type"] = "application/json"
					}
				})
				return res.Body
			else
				return HttpService:GetAsync(SUPABASE_URL .. HttpService:UrlEncode(enteredKey), false, {
					["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY
				})
			end
		end)

		if not (success and response) then
			KeyFail(isAutoLogin, "Gagal terhubung ke database verifikasi.")
			return
		end

		local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
		if not (ok and data and #data > 0) then
			KeyFail(isAutoLogin, "Key tidak ditemukan / invalid!")
			return
		end

		local record = data[1]
		local currentUser = LocalPlayer.Name

		-- Cek Status Key (Lebih Aman)
		local statusStr = tostring(record.status):lower()
		if record.status == false or statusStr == "inactive" or statusStr == "used" or statusStr == "false" then
			KeyFail(isAutoLogin, "Key sudah tidak aktif / kadaluwarsa!")
			return
		end

		-- Cek Username
		if record.roblox_username and record.roblox_username ~= "" then
			if not CheckUsernameInList(record.roblox_username, currentUser) then
				KeyFail(isAutoLogin, "Username (" .. currentUser .. ") tidak terdaftar!")
				return
			end
		else
			PatchKey(requestFunc, enteredKey, {roblox_username = currentUser})
		end

		-- Cek HWID
		if record.hwid_value and record.hwid_value ~= "" then
			if record.hwid_value ~= CurrentHWID then
				KeyFail(isAutoLogin, "Key terikat di perangkat (HWID) lain!")
				return
			end
		else
			PatchKey(requestFunc, enteredKey, {hwid_value = CurrentHWID})
		end

		pcall(function() if writefile then writefile(KEY_FILE, enteredKey) end end)
		IsKeyVerified = true -- [SECURITY FIX]
		KeyFrame.Visible = false
		Main.Visible = true
	end)
end

SubmitKeyBtn.MouseButton1Click:Connect(function() ValidateKey(KeyBox.Text, false) end)

task.spawn(function()
	if readfile and isfile and isfile(KEY_FILE) then
		local savedKey = readfile(KEY_FILE)
		if savedKey and savedKey ~= "" then
			KeyBox.Text = savedKey
			ValidateKey(savedKey, true)
			return
		end
	end
	KeyFrame.Visible = true
end)

------------------------------------------------------------------
-- PAGE 1: FISHING
------------------------------------------------------------------
UI.Section(FishingPage, "AUTO FISHING")

local infoCard = Card(FishingPage, 45)
local infoLbl = Label(infoCard, "⚠️ Pastikan kamu sudah memegang (equip) pancingan!\nScript akan mendeteksi nama rod secara otomatis.", 11, C.warn, Enum.Font.Gotham, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 1, -16))
infoLbl.TextWrapped = true
infoLbl.TextYAlignment = Enum.TextYAlignment.Center

UI.Toggle(FishingPage, "Auto Fishing", "Memancing secara otomatis (Dynamic Rod).", false, function(v)
	if v and not IsKeyVerified then return end -- [SECURITY FIX]
	getgenv().AutoFishingRunning = v
end)

UI.Toggle(FishingPage, "Auto Sell Ikan", "Jual semua ikan secara otomatis via timer.", false, function(v)
	if v and not IsKeyVerified then return end -- [SECURITY FIX]
	getgenv().AutoSellRunning = v
	if v then
		task.spawn(function()
			local lastSell = tick()
			while getgenv().AutoSellRunning do
				if not IsKeyVerified then getgenv().AutoSellRunning = false; break end -- [SECURITY FIX]
				task.wait(1)
				if ((tick() - lastSell) / 60) >= (tonumber(getgenv().UbeyConfig.AutoSellTimer) or 5) then
					TriggerSellAll()
					lastSell = tick()
				end
			end
		end)
	end
end)

UI.Input(FishingPage, "Jeda Jual", "Waktu jeda auto sell (Menit)", tostring(getgenv().UbeyConfig.AutoSellTimer), "5", function(t)
	local val = tonumber(t)
	if val then
		getgenv().UbeyConfig.AutoSellTimer = tostring(val)
		SaveConfig()
	end
end)

UI.Section(FishingPage, "PENGATURAN FISHING (DETIK)", C.good)
UI.Input(FishingPage, "Wait Time", "Jeda tunggu ikan (Detik)", tostring(getgenv().UbeyConfig.WaitTime), "4.0", function(t)
	local val = tonumber(t)
	if val then
		getgenv().UbeyConfig.WaitTime = val
		SaveConfig()
	end
end)

UI.Input(FishingPage, "Loop Delay", "Jeda antar cast (Detik)", tostring(getgenv().UbeyConfig.LoopDelay), "0.1", function(t)
	local val = tonumber(t)
	if val then
		getgenv().UbeyConfig.LoopDelay = val
		SaveConfig()
	end
end)

------------------------------------------------------------------
-- PAGE 2: SUMMIT FARM
------------------------------------------------------------------
UI.Section(SummitPage, "AUTO SUMMIT FARM")

local sumInfoCard = Card(SummitPage, 45)
local sumInfoLbl = Label(sumInfoCard, "⚠️ Otomatis mendaki via Waypoint (31 Titik) & Bypass Timer.\nJangan bergerak selama Auto Summit ON.", 11, C.warn, Enum.Font.Gotham, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 1, -16))
sumInfoLbl.TextWrapped = true
sumInfoLbl.TextYAlignment = Enum.TextYAlignment.Center

UI.Toggle(SummitPage, "Auto Climb Summit (Loop)", "Mendaki gunung secara otomatis tanpa henti.", false, function(v)
	if v and not IsKeyVerified then return end -- [SECURITY FIX]
	getgenv().AutoSummitRunning = v
end)

------------------------------------------------------------------
-- PAGE 3: SETTINGS
------------------------------------------------------------------
UI.Section(SettingsPage, "OPTIMASI")
UI.Button(SettingsPage, "Anti-Lag", "Matikan bayangan untuk menaikkan FPS.", "Aktifkan", function(btn)
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 999999
		Flash(btn, "Aktif ✓", true)
	end)
end)

------------------------------------------------------------------
-- PAGE 4: CREDITS
------------------------------------------------------------------
UI.Section(CreditsPage, "INFORMASI")
UI.Button(CreditsPage, "Created By UBEY", "Terima kasih sudah memakai hub ini.", "Discord", function(btn)
	local ok = pcall(function() setclipboard(DISCORD_LINK) end)
	Flash(btn, ok and "Disalin ✓" or "Gagal", ok)
end, Color3.fromRGB(88, 101, 242))

------------------------------------------------------------------
-- FLOATING LOGO
------------------------------------------------------------------
local Float = New("ImageButton", {
	Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 20, 0, 120),
	Image = LOGO_ASSET, BackgroundColor3 = C.bg, AutoButtonColor = false, ZIndex = 50
}, Gui)
Round(Float, 30)
New("UIStroke", {Color = C.accent, Thickness = 2}, Float)
local floatMoved = MakeDraggable(Float)

Float.MouseButton1Click:Connect(function()
	if floatMoved() then return end
	if not IsKeyVerified then
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)
