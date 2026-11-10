-- ==============================================================================
-- UBEY HUB | MERGED (GUI TEMPLATE + FULL FUNCTIONALITY)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ====== PENGATURAN ======
local HUB_TITLE = "UBEY HUB"
local HUB_SUBTITLE = "PREMIUM"
local HUB_DISCORD = "discord.gg/YXuYeEpnXE"
local LOGO_ASSET = "rbxassetid://90770802417381"
local WIN_W, WIN_H = 580, 370

local CONFIG_FILE = "UbeyHub_Config.json"
local KEY_FILE = "UbeyHub_SavedKey.txt"

local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_rMWL7Qrjw9iG0c29vGZ0bw_O3swXT6n"

-- ====== CONFIG ======
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
getgenv().KeyVerified = false

pcall(function() GuiService:SetGameplayPausedNotificationEnabled(false) end)

local function GetDeviceHWID()
	local hwid = nil
	pcall(function()
		if gethwid then hwid = gethwid()
		elseif RbxAnalyticsService then hwid = RbxAnalyticsService:GetClientId() end
	end)
	return tostring(hwid or ("UNKNOWN_DEVICE_" .. tostring(LocalPlayer.UserId)))
end
local CurrentHWID = GetDeviceHWID()

-- ====== FISHING LOGIC ======
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
		if getgenv().AutoFishingRunning then
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

-- ====== SUMMIT LOGIC ======
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
		if getgenv().AutoSummitRunning then
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
					pcall(function() LocalPlayer:RequestStreamAroundAsync(targetPos) end)
					hrp.CFrame = CFrame.new(targetPos)
				end

				touchedList = {}
				for _, pos in ipairs(waypoints) do
					if not getgenv().AutoSummitRunning then break end
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

-- ====== AUTO RECONNECT ======
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

-- ====== DESTROY OLD GUI ======
pcall(function()
	local old = PlayerGui:FindFirstChild("UbeyHub")
	if old then old:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 100
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

-- ====== KEY PAGE ======
local KeyFrame = New("Frame", {
	Size = UDim2.new(0, 400, 0, 240), Position = UDim2.new(0.5, -200, 0.5, -120),
	BackgroundColor3 = C.bg, Visible = false
}, Gui)
Round(KeyFrame, 14)
New("UIStroke", {Color = C.line, Thickness = 1.5}, KeyFrame)
MakeDraggable(KeyFrame)

Label(KeyFrame, HUB_TITLE, 16, C.text, Enum.Font.GothamBold, UDim2.new(0, 20, 0, 12), UDim2.new(1, -40, 0, 22))
Label(KeyFrame, HUB_SUBTITLE, 10, C.warn, Enum.Font.GothamBold, UDim2.new(0, 20, 0, 32), UDim2.new(1, -40, 0, 14))
Label(KeyFrame, "Masukkan key untuk melanjutkan.", 12, C.sub, Enum.Font.Gotham, UDim2.new(0, 20, 0, 62), UDim2.new(1, -40, 0, 18))

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

local GetKeyBtn = New("TextButton", {
	Size = UDim2.new(0.5, -26, 0, 38), Position = UDim2.new(0.5, 6, 0, 140),
	BackgroundColor3 = Color3.fromRGB(88, 101, 242), Text = "Get Key (Discord)", TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 13
}, KeyFrame)
Round(GetKeyBtn, 10)

local StatusKey = Label(KeyFrame, "", 11, C.bad, Enum.Font.Gotham, UDim2.new(0, 20, 0, 190), UDim2.new(1, -40, 0, 22), Enum.TextXAlignment.Center)

-- ====== MAIN WINDOW ======
local Main = New("Frame", {
	Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
	BackgroundColor3 = C.bg, Visible = false, ClipsDescendants = true
}, Gui)
Round(Main, 14)
New("UIStroke", {Color = C.line, Thickness = 1.5}, Main)

local Header = New("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1}, Main)
MakeDraggable(Main, Header)
Label(Header, HUB_TITLE, 15, C.text, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 5), UDim2.new(0, 110, 0, 20))
Label(Header, HUB_SUBTITLE, 10, C.warn, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 23), UDim2.new(0, 110, 0, 14))
Label(Header, HUB_DISCORD, 10, C.sub, Enum.Font.Gotham, UDim2.new(0, 130, 0, 0), UDim2.new(0, 160, 1, 0))

local PingLabel = Label(Header, "📡 -- ms", 11, C.good, Enum.Font.GothamBold, UDim2.new(0, 290, 0, 0), UDim2.new(1, -380, 1, 0), Enum.TextXAlignment.Right)

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
local PagesHolder = New("Frame", {Size = UDim2.new(1, 0, 1, -74), Position = UDim2.new(0, 0, 0, 38), BackgroundTransparency = 1}, Content)

local StatBar = New("Frame", {
	Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 1, -32),
	BackgroundColor3 = C.card, BorderSizePixel = 0
}, Content)
Round(StatBar, 8)
New("UIStroke", {Color = C.line, Thickness = 1}, StatBar)
local StatLabel = Label(StatBar, "📊 Fish: 0  |  ⛰️ Summit: 0  |  ⏱️ 00s", 11, C.accent, Enum.Font.GothamBold, UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0))

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	Body.Visible = not isMinimized
	TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
		Size = UDim2.new(0, WIN_W, 0, isMinimized and 42 or WIN_H)
	}):Play()
end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- ====== LIVE UPDATERS ======
task.spawn(function()
	while true do
		pcall(function()
			local pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			PingLabel.Text = "📡 " .. pingVal .. " ms"
		end)
		task.wait(1)
	end
end)

task.spawn(function()
	while true do
		pcall(function()
			local elapsed = os.time() - getgenv().SessionStartTime
			local hours = math.floor(elapsed / 3600)
			local mins = math.floor((elapsed % 3600) / 60)
			local secs = elapsed % 60
			local timeStr
			if hours > 0 then timeStr = string.format("%02dh %02dm %02ds", hours, mins, secs)
			elseif mins > 0 then timeStr = string.format("%02dm %02ds", mins, secs)
			else timeStr = string.format("%02ds", secs) end
			StatLabel.Text = string.format("📊 Fish: %d  |  ⛰️ Summit: %d  |  ⏱️ %s", getgenv().TotalFishCaught, getgenv().TotalSummitRun, timeStr)
		end)
		task.wait(1)
	end
end)

-- ====== KEY VALIDATION ======
local function CheckUsernameInList(allowedUsersStr, currentUsername)
	if not allowedUsersStr or allowedUsersStr == "" then return false end
	for name in string.gmatch(allowedUsersStr, "[^,%s]+") do
		if string.lower(name) == string.lower(currentUsername) then return true end
	end
	return false
end

local function ValidateKey(enteredKey, isAutoLogin)
	if enteredKey == "" then
		if not isAutoLogin then
			StatusKey.TextColor3 = C.bad
			StatusKey.Text = "Masukkan Key terlebih dahulu!"
		end
		KeyFrame.Visible = true
		return
	end

	if not isAutoLogin then
		StatusKey.TextColor3 = C.warn
		StatusKey.Text = "Memeriksa Validasi Akun & Key..."
	end

	task.spawn(function()
		local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({
					Url = SUPABASE_URL .. HttpService:UrlEncode(enteredKey),
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
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
			if decodeSuccess and data and #data > 0 then
				local record = data[1]
				local currentRobloxUser = LocalPlayer.Name

				if record.status == false or record.status == "inactive" or record.status == "used" then
					if not isAutoLogin then
						StatusKey.TextColor3 = C.bad
						StatusKey.Text = "Key sudah tidak aktif / kadaluwarsa!"
					end
					KeyFrame.Visible = true
					return
				end

				if record.roblox_username and record.roblox_username ~= "" then
					if not CheckUsernameInList(record.roblox_username, currentRobloxUser) then
						if not isAutoLogin then
							StatusKey.TextColor3 = C.bad
							StatusKey.Text = "Username (" .. currentRobloxUser .. ") tidak terdaftar!"
						end
						KeyFrame.Visible = true
						return
					end
				else
					pcall(function()
						if requestFunc then
							requestFunc({
								Url = SUPABASE_URL .. HttpService:UrlEncode(enteredKey),
								Method = "PATCH",
								Headers = {
									["apikey"] = SUPABASE_ANON_KEY,
									["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
									["Content-Type"] = "application/json"
								},
								Body = HttpService:JSONEncode({ roblox_username = currentRobloxUser })
							})
						end
					end)
				end

				if record.hwid_value and record.hwid_value ~= "" then
					if record.hwid_value ~= CurrentHWID then
						if not isAutoLogin then
							StatusKey.TextColor3 = C.bad
							StatusKey.Text = "Key terikat di perangkat (HWID) lain!"
						end
						KeyFrame.Visible = true
						return
					end
				else
					pcall(function()
						if requestFunc then
							requestFunc({
								Url = SUPABASE_URL .. HttpService:UrlEncode(enteredKey),
								Method = "PATCH",
								Headers = {
									["apikey"] = SUPABASE_ANON_KEY,
									["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
									["Content-Type"] = "application/json"
								},
								Body = HttpService:JSONEncode({ hwid_value = CurrentHWID })
							})
						end
					end)
				end

				pcall(function() if writefile then writefile(KEY_FILE, enteredKey) end end)
				getgenv().KeyVerified = true
				KeyFrame.Visible = false
				Main.Visible = true
			else
				if not isAutoLogin then
					StatusKey.TextColor3 = C.bad
					StatusKey.Text = "Key tidak ditemukan / invalid!"
				end
				KeyFrame.Visible = true
			end
		else
			if not isAutoLogin then
				StatusKey.TextColor3 = C.bad
				StatusKey.Text = "Gagal terhubung ke database."
			end
			KeyFrame.Visible = true
		end
	end)
end

SubmitKeyBtn.MouseButton1Click:Connect(function() ValidateKey(KeyBox.Text, false) end)
GetKeyBtn.MouseButton1Click:Connect(function()
	pcall(function() if setclipboard then setclipboard("https://" .. HUB_DISCORD) end end)
	StatusKey.TextColor3 = C.accent
	StatusKey.Text = "Link Discord disalin!"
end)

-- ====== UI COMPONENTS ======
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

	local tab = {Button = btn, Bar = bar, Label = lbl, Page = page}
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

-- ====== TABS ======
local TabFish = UI.Tab("Fishing", "🎣")
local TabSummit = UI.Tab("Summit", "⛰️")
local TabSettings = UI.Tab("Settings", "⚙️")
local TabCredits = UI.Tab("Credits", "👑")

-- FISHING TAB
UI.Section(TabFish, "AUTO FISHING")
UI.Toggle(TabFish, "Auto Fishing", "Equip rod dulu sebelum aktifkan.", false, function(v)
	getgenv().AutoFishingRunning = v
end)
UI.Toggle(TabFish, "Auto Sell Ikan", "Jual ikan otomatis per interval.", false, function(v)
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
UI.Input(TabFish, "Jeda Jual (Menit)", "Interval auto-sell dalam menit.", tostring(getgenv().UbeyConfig.AutoSellTimer), "5", function(text)
	local val = tonumber(text)
	if val then
		getgenv().UbeyConfig.AutoSellTimer = tostring(val)
		SaveConfig()
	end
end)

-- SUMMIT TAB
UI.Section(TabSummit, "AUTO SUMMIT")
UI.Toggle(TabSummit, "Auto Climb Summit", "Otomatis mendaki 31 waypoint + bypass timer.", false, function(v)
	getgenv().AutoSummitRunning = v
end)

-- SETTINGS TAB
UI.Section(TabSettings, "KONFIGURASI")
UI.Input(TabSettings, "Wait Time (detik)", "Jeda antara cast & ambil ikan.", tostring(getgenv().UbeyConfig.WaitTime), "4.0", function(text)
	local val = tonumber(text)
	if val then
		getgenv().UbeyConfig.WaitTime = val
		SaveConfig()
	end
end)
UI.Input(TabSettings, "Loop Delay (detik)", "Jeda antar loop fishing.", tostring(getgenv().UbeyConfig.LoopDelay), "0.1", function(text)
	local val = tonumber(text)
	if val then
		getgenv().UbeyConfig.LoopDelay = val
		SaveConfig()
	end
end)

UI.Section(TabSettings, "UTILITAS")
UI.Button(TabSettings, "Anti-Lag", "Matikan shadow & fog untuk performa.", "Aktifkan", function(btn)
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 999999
		btn.Text = "Aktif!"
	end)
end)
UI.Button(TabSettings, "Hapus Key Tersimpan", "Reset key yang tersimpan di perangkat.", "Hapus", function()
	pcall(function()
		if delfile and isfile and isfile(KEY_FILE) then delfile(KEY_FILE) end
	end)
end, Color3.fromRGB(180, 50, 50))

-- CREDITS TAB
UI.Section(TabCredits, "CREDITS")
local credCard = New("Frame", {Size = UDim2.new(1, -4, 0, 84), BackgroundColor3 = C.card}, TabCredits)
Round(credCard, 10)
New("UIStroke", {Color = C.line, Thickness = 1}, credCard)
Label(credCard, "UBEY HUB", 16, C.accent, Enum.Font.GothamBold, UDim2.new(0, 0, 0, 14), UDim2.new(1, 0, 0, 22), Enum.TextXAlignment.Center)
Label(credCard, "Created by UBEY", 12, C.text, Enum.Font.Gotham, UDim2.new(0, 0, 0, 38), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Center)
Label(credCard, HUB_DISCORD, 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 0, 0, 58), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Center)

-- ====== FLOATING LOGO ======
local Float = New("ImageButton", {
	Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 20, 0, 120),
	Image = LOGO_ASSET, BackgroundColor3 = C.bg, AutoButtonColor = false, ZIndex = 50
}, Gui)
Round(Float, 30)
New("UIStroke", {Color = C.accent, Thickness = 2}, Float)
local floatMoved = MakeDraggable(Float)

Float.MouseButton1Click:Connect(function()
	if floatMoved() then return end
	if not getgenv().KeyVerified then
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)

-- ====== AUTO LOGIN ======
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
