
-- ==============================================================================
-- UBEY HUB V3 | FISHALL EDITION
-- Sistem key tetap divalidasi di Supabase Edge Function (verify-key).
-- Tab: Fishing (FishAll), Player, TP Player, Privacy, Settings, Credits
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local RS = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ====== PENGATURAN TAMPILAN ======
local HUB_TITLE = "UBEY HUB"
local HUB_DISCORD = "discord.gg/YXuYeEpnXE"
local DISCORD_LINK = "https://discord.gg/YXuYeEpnXE"
local LOGO_ASSET = "rbxassetid://90770802417381"
-- ================================================

-- ====== SERVER VERIFIKASI ======
local FUNCTION_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/functions/v1/verify-key"
local SUPABASE_ANON_KEY = "sb_publishable_rMWL7Qrjw9iG0c29vGZ0bw_O3swXT6n"
local HEARTBEAT_INTERVAL = 120 -- detik
-- ================================

getgenv().TotalFishCaught = 0
getgenv().SessionStartTime = os.time()

------------------------------------------------------------------
-- SESSION
------------------------------------------------------------------
local Session = {token = nil, key = nil, expiresAt = 0}

local function IsVerified()
	return Session.token ~= nil and os.time() < Session.expiresAt
end

local Hooks = {} -- diisi modul fishing (StopFish)

local function StopAll()
	getgenv().HideNameRunning = false
	if Hooks.StopFish then pcall(Hooks.StopFish) end
end

local Lock -- didefinisikan setelah GUI dibuat

------------------------------------------------------------------
-- CONFIG & FILE SAVE
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHubV3_IY_Config.json"
local KEY_FILE = "UbeyHubV3_SavedKey.txt"

local function DefaultConfig()
	return {
		AntiAdminEnabled = false, TargetGroupId = "0",
		FishDistance = 30, FishMaxBite = 0
	}
end
getgenv().UbeyConfig = DefaultConfig()

local function SaveConfig()
	pcall(function()
		if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().UbeyConfig)) end
	end)
end

local function LoadConfig()
	pcall(function()
		if readfile and isfile and isfile(CONFIG_FILE) then
			local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
			if ok and type(data) == "table" then
				for k, _ in pairs(DefaultConfig()) do
					if data[k] ~= nil then getgenv().UbeyConfig[k] = data[k] end
				end
			end
		end
	end)
end

local function ResetConfig()
	pcall(function()
		getgenv().UbeyConfig = DefaultConfig()
		if delfile and isfile then
			if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
			if isfile(KEY_FILE) then delfile(KEY_FILE) end
		end
	end)
end

LoadConfig()

------------------------------------------------------------------
-- HWID & REQUEST
------------------------------------------------------------------
local function GetDeviceHWID()
	local hwid = nil
	pcall(function()
		if gethwid then hwid = gethwid()
		elseif RbxAnalyticsService then hwid = RbxAnalyticsService:GetClientId() end
	end)
	return tostring(hwid or ("UNKNOWN_DEVICE_" .. tostring(LocalPlayer.UserId)))
end
local CurrentHWID = GetDeviceHWID()

local function GetRequestFunc()
	return (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
end

local function CallServer(body)
	local req = GetRequestFunc()
	if not req then return nil, "Executor tidak mendukung request HTTP." end
	local ok, res = pcall(req, {
		Url = FUNCTION_URL, Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["apikey"] = SUPABASE_ANON_KEY,
			["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY
		},
		Body = HttpService:JSONEncode(body)
	})
	if not ok or not res then return nil, "Gagal terhubung ke server verifikasi." end
	local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body or "") end)
	if not ok2 or type(data) ~= "table" then return nil, "Respon server tidak valid." end
	return data
end

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

getgenv().HideNameRunning = false
getgenv().AntiAFKRunning = false
getgenv().FakeNameInput = "UBEY HUB"

-- ==============================================================================
-- GUI SETUP
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
	Size = UDim2.new(0, 400, 0, 262), Position = UDim2.new(0.5, -200, 0.5, -131),
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

local StatusKey = Label(KeyFrame, "", 12, C.bad, Enum.Font.Gotham, UDim2.new(0, 20, 0, 188), UDim2.new(1, -40, 0, 22), Enum.TextXAlignment.Center)

local Disclosure = Label(KeyFrame, "Saat verifikasi, username Roblox & ID perangkat (HWID) dikirim ke server untuk mengikat key ke akunmu.",
	10, C.sub, Enum.Font.Gotham, UDim2.new(0, 20, 0, 214), UDim2.new(1, -40, 0, 36), Enum.TextXAlignment.Center)
Disclosure.TextWrapped = true
Disclosure.TextTruncate = Enum.TextTruncate.None

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

-- Ping, jumlah ikan, playtime
task.spawn(function()
	while true do
		pcall(function()
			local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			local elapsed = os.time() - getgenv().SessionStartTime
			local h, m, s = math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60
			local t = h > 0 and string.format("%dh %02dm", h, m) or string.format("%02dm %02ds", m, s)
			StatLabel.Text = string.format("📡 %d ms  |  🐟 %d  |  ⏱ %s", ping, getgenv().TotalFishCaught, t)
		end)
		task.wait(1)
	end
end)

-- Lock: cabut sesi, hentikan semua fitur, kembali ke layar key
Lock = function(msg)
	Session.token, Session.key, Session.expiresAt = nil, nil, 0
	StopAll()
	pcall(function()
		Main.Visible = false
		KeyFrame.Visible = true
		StatusKey.TextColor3 = C.bad
		StatusKey.Text = msg or ""
	end)
end

-- Anti-tamper: kalau layar key dihapus, matikan semuanya
task.spawn(function()
	while true do
		task.wait(2)
		if not KeyFrame or not KeyFrame.Parent then
			Session.token, Session.key, Session.expiresAt = nil, nil, 0
			StopAll()
			if Main and Main.Parent then Main:Destroy() end
			break
		end
	end
end)

-- Heartbeat: server bisa mencabut key kapan saja
task.spawn(function()
	while true do
		task.wait(HEARTBEAT_INTERVAL)
		if Session.token then
			local data = CallServer({
				action = "heartbeat", key = Session.key, token = Session.token,
				hwid = CurrentHWID, username = LocalPlayer.Name
			})
			if data and data.ok then
				Session.token = data.token or Session.token
				Session.expiresAt = os.time() + (tonumber(data.ttl) or 300) + 60
			elseif data and data.ok == false then
				Lock(data.reason or "Sesi key dicabut oleh server.")
			end
			if Session.token and os.time() >= Session.expiresAt then
				Lock("Sesi kedaluwarsa, verifikasi ulang.")
			end
		end
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
	if desc and desc ~= "" then
		Label(card, title, 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, 12, 0, 8), UDim2.new(1, -rightPad, 0, 18))
		Label(card, desc, 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 12, 0, 27), UDim2.new(1, -rightPad, 0, 18))
	else
		Label(card, title, 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, 12, 0, 0), UDim2.new(1, -rightPad, 1, 0))
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
		if not IsVerified() then
			state = false
			render()
			return
		end
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
	b.MouseButton1Click:Connect(function()
		if not IsVerified() then return end
		task.spawn(cb, b)
	end)
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

-- Tombol  [-]  nilai  [+]  (dipakai untuk Jarak & Maks Gigit)
function UI.Stepper(page, title, onMinus, onPlus)
	local card = Card(page)
	CardText(card, title, "", 170)
	local function mk(text, x)
		local b = New("TextButton", {
			Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, x, 0.5, -15),
			BackgroundColor3 = C.off, Text = text, TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold, TextSize = 16
		}, card)
		Round(b, 8)
		return b
	end
	local minus, plus = mk("-", -150), mk("+", -44)
	local val = Label(card, "", 12, C.text, Enum.Font.GothamBold, UDim2.new(1, -118, 0, 0), UDim2.new(0, 70, 1, 0), Enum.TextXAlignment.Center)
	minus.MouseButton1Click:Connect(function() if IsVerified() then onMinus() end end)
	plus.MouseButton1Click:Connect(function() if IsVerified() then onPlus() end end)
	return val
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
local FishingPage = UI.Tab("Fishing", "🎣")
local PlayerPage = UI.Tab("Player", "⚡")
local PlayerTpPage = UI.Tab("TP Player", "👥")
local PrivacyPage = UI.Tab("Privacy", "🛡️")
local SettingsPage = UI.Tab("Settings", "⚙️")
local CreditsPage = UI.Tab("Credits", "💎")

------------------------------------------------------------------
-- KEY VALIDATION (server-side)
------------------------------------------------------------------
GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	local ok = pcall(function() setclipboard(DISCORD_LINK) end)
	StatusKey.TextColor3 = ok and C.accent or C.bad
	StatusKey.Text = ok and "Link Discord disalin!" or ("Buka manual: " .. DISCORD_LINK)
end)

local validating = false
local function ValidateKey(enteredKey, isAutoLogin)
	enteredKey = tostring(enteredKey or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if validating then return end
	if enteredKey == "" then
		if not isAutoLogin then
			StatusKey.TextColor3 = C.bad
			StatusKey.Text = "Masukkan Key terlebih dahulu!"
		end
		KeyFrame.Visible = true
		return
	end
	validating = true
	if not isAutoLogin then
		StatusKey.TextColor3 = C.warn
		StatusKey.Text = "Memeriksa validasi akun & key..."
	end

	task.spawn(function()
		local data, err = CallServer({
			action = "verify", key = enteredKey, hwid = CurrentHWID,
			username = LocalPlayer.Name, userId = LocalPlayer.UserId, placeId = game.PlaceId
		})
		validating = false

		if not data then
			if not isAutoLogin then StatusKey.TextColor3 = C.bad; StatusKey.Text = err or "Gagal verifikasi." end
			KeyFrame.Visible = true
			return
		end
		if not data.ok or type(data.token) ~= "string" then
			if not isAutoLogin then StatusKey.TextColor3 = C.bad; StatusKey.Text = tostring(data.reason or "Key tidak valid!") end
			KeyFrame.Visible = true
			return
		end

		Session.token = data.token
		Session.key = enteredKey
		Session.expiresAt = os.time() + (tonumber(data.ttl) or 300) + 60

		pcall(function() if writefile then writefile(KEY_FILE, enteredKey) end end)
		StatusKey.Text = ""
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
-- 1. FISHING PAGE  (FishAll)
-- Auto cast lewat StartFishing, cutscene dimatikan, posisi lempar
-- di depan karakter, batas waktu gigit, hitung ikan/menit.
------------------------------------------------------------------
local Fish = {
	running = false, busy = false, attempt = 5000,
	lastCast = os.clock(), count = 0, t0 = os.clock(),
	dur = "-", csOk = false, ready = false
}
local CastDelay = 0.05
local Distance = math.clamp(tonumber(getgenv().UbeyConfig.FishDistance) or 30, 5, 120)
local MaxBite = math.clamp(tonumber(getgenv().UbeyConfig.FishMaxBite) or 0, 0, 30)
local StartRemote, EventRemote
local TgFish, DistLbl, BiteLbl, InfoLbl

local function GetTarget()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local flat = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
	local front = hrp.Position + flat.Unit * Distance

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	params.IgnoreWater = false

	local hit = workspace:Raycast(front + Vector3.new(0, 50, 0), Vector3.new(0, -150, 0), params)
	if hit then return hit.Position end
	return Vector3.new(front.X, hrp.Position.Y - 3, front.Z)
end

local function GetRod()
	local char = LocalPlayer.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	if tool then return tool.Name end
	return "belum equip"
end

local function FishRender()
	if not InfoLbl then return end
	DistLbl.Text = tostring(Distance)
	BiteLbl.Text = MaxBite == 0 and "off" or (MaxBite .. " dtk")
	local mins = math.max((os.clock() - Fish.t0) / 60, 0.01)
	InfoLbl.Text = string.format("Pancingan: %s\nCutscene: %s\nIkan: %d (%.1f/menit)\nWaktu gigit: %s dtk",
		GetRod(), Fish.csOk and "mati" or "GAGAL", Fish.count, Fish.count / mins, Fish.dur)
end

local function FishCast()
	if not Fish.running or Fish.busy or not IsVerified() then return end
	if not StartRemote then return end
	local target = GetTarget()
	if not target then return end
	Fish.busy = true
	Fish.attempt = Fish.attempt + 1
	Fish.lastCast = os.clock()
	StartRemote:FireServer(Fish.attempt, target)
end

Hooks.StopFish = function()
	Fish.running = false
	Fish.busy = false
	getgenv().AutoFishRunning = false
	if TgFish then TgFish.Set(false) end
end

UI.Section(FishingPage, "AUTO FISHING")

TgFish = UI.Toggle(FishingPage, "Auto Fishing", "Auto lempar & tarik ikan.", false, function(v)
	if v and not (StartRemote and EventRemote) then
		TgFish.Set(false)
		warn("[Ubey] Remote FishingSystem belum ketemu.")
		return
	end
	Fish.running = v
	getgenv().AutoFishRunning = v
	if v then
		Fish.busy = false
		Fish.t0, Fish.count = os.clock(), 0
		FishCast()
	end
	FishRender()
end)

DistLbl = UI.Stepper(FishingPage, "Jarak Depan",
	function()
		Distance = math.max(5, Distance - 5)
		getgenv().UbeyConfig.FishDistance = Distance
		SaveConfig(); FishRender()
	end,
	function()
		Distance = math.min(120, Distance + 5)
		getgenv().UbeyConfig.FishDistance = Distance
		SaveConfig(); FishRender()
	end)

BiteLbl = UI.Stepper(FishingPage, "Maks Waktu Gigit",
	function()
		MaxBite = math.max(0, MaxBite - 1)
		getgenv().UbeyConfig.FishMaxBite = MaxBite
		SaveConfig(); FishRender()
	end,
	function()
		MaxBite = math.min(30, MaxBite + 1)
		getgenv().UbeyConfig.FishMaxBite = MaxBite
		SaveConfig(); FishRender()
	end)

do
	local card = Card(FishingPage, 96)
	InfoLbl = Label(card, "", 12, Color3.fromRGB(180, 200, 255), Enum.Font.Code,
		UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 1, -16))
	InfoLbl.TextWrapped = true
	InfoLbl.TextTruncate = Enum.TextTruncate.None
	InfoLbl.TextYAlignment = Enum.TextYAlignment.Top
end
FishRender()

-- Sambungkan ke remote game (di thread terpisah supaya GUI tidak tertahan)
task.spawn(function()
	local fs = RS:WaitForChild("FishingSystem", 20)
	local R = fs and fs:WaitForChild("Remotes", 20)
	StartRemote = R and R:WaitForChild("StartFishing", 20)
	EventRemote = R and R:WaitForChild("FishingEvent", 20)
	if not (StartRemote and EventRemote) then
		warn("[Ubey] FishingSystem/Remotes tidak ketemu.")
		return
	end

	Fish.csOk = pcall(function()
		local m = require(LocalPlayer.PlayerScripts.FishingSystem.CatchCutsceneController)
		m.Play = function() end
		m.IsPlaying = function() return false end
		if m.Stop then m.Stop() end
	end)
	Fish.ready = true

	EventRemote.OnClientEvent:Connect(function(d)
		if typeof(d) ~= "table" then return end

		if d.Kind == "State" and d.State == "Fishing" then
			local dur = tonumber(d.DurationSeconds) or 0
			Fish.dur = string.format("%.2f", dur)
			if Fish.running and MaxBite > 0 and dur > MaxBite then
				Fish.busy = false
				task.wait(0.2)
				FishCast()
			end
		end
		if d.Kind == "Terminal" and d.State == "Caught" then
			Fish.count = Fish.count + 1
			getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1
		end

		if Fish.running then
			if d.Kind == "StartResult" then
				Fish.busy = false
				if not d.Accepted then task.wait(0.3); FishCast() end
			elseif d.Kind == "Terminal" or (d.Kind == "State" and d.State == "Idle") then
				Fish.busy = false
				task.wait(CastDelay)
				FishCast()
			end
		end
		FishRender()
	end)
end)

-- Watchdog kalau macet
task.spawn(function()
	while task.wait(1) do
		if Fish.running and not IsVerified() then
			Hooks.StopFish()
		elseif Fish.running and os.clock() - Fish.lastCast > 14 then
			Fish.busy = false
			FishCast()
		end
		FishRender()
	end
end)

------------------------------------------------------------------
-- 2. PLAYER PAGE
------------------------------------------------------------------
UI.Section(PlayerPage, "PLAYER SETTINGS")
UI.Input(PlayerPage, "WalkSpeed", "Kecepatan jalan karakter", "", "50", function(t)
	local num = tonumber(t)
	if num and IsVerified() then
		pcall(function()
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = num end
		end)
	end
end)

UI.Toggle(PlayerPage, "Anti-AFK", "Cegah kick karena idle.", false, function(v) getgenv().AntiAFKRunning = v end)
LocalPlayer.Idled:Connect(function()
	if getgenv().AntiAFKRunning then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end
end)

------------------------------------------------------------------
-- 3. TP PLAYER PAGE
------------------------------------------------------------------
local RefreshPlayerBtn = New("TextButton", {
	Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Color3.fromRGB(0, 100, 180),
	Text = "🔄 Refresh / Scan Pemain", TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 12
}, PlayerTpPage)
Round(RefreshPlayerBtn, 8)

local PlayerListContainer = New("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 210), BackgroundTransparency = 1,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3
}, PlayerTpPage)
New("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, PlayerListContainer)

local function ScanAndDisplayPlayers()
	for _, child in ipairs(PlayerListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local pBtn = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(35, 35, 45),
				Text = "👤 " .. plr.Name .. " (" .. plr.DisplayName .. ")",
				TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 11
			}, PlayerListContainer)
			Round(pBtn, 8)
			pBtn.MouseButton1Click:Connect(function()
				if not IsVerified() then return end
				pcall(function()
					local hrpTarget = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if hrpTarget and myHrp then myHrp.CFrame = hrpTarget.CFrame + Vector3.new(0, 5, 0) end
				end)
			end)
		end
	end
end

RefreshPlayerBtn.MouseButton1Click:Connect(function()
	if not IsVerified() then return end
	ScanAndDisplayPlayers()
end)
task.spawn(function() task.wait(2); ScanAndDisplayPlayers() end)

------------------------------------------------------------------
-- 4. PRIVACY & ANTI-ADMIN
------------------------------------------------------------------
local function EscPat(s) return (tostring(s):gsub("%p", "%%%0")) end
local function EscRep(s) return (tostring(s):gsub("%%", "%%%%")) end

-- BillboardGui di workspace yang menempel ke karakter kita (papan nama di atas kepala)
local extraBillboards = {}
local function ScanBillboards()
	extraBillboards = {}
	local char = LocalPlayer.Character
	if not char then return end
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BillboardGui") then
			local ad = v.Adornee
			if ad and ad:IsDescendantOf(char) then table.insert(extraBillboards, v) end
		end
	end
end

local function HideNameStep()
	local fake = tostring(getgenv().FakeNameInput or "UBEY HUB")
	local names = {LocalPlayer.DisplayName, LocalPlayer.Name}

	local function fix(lbl)
		local txt = lbl.Text
		if txt == "" or string.find(txt, fake, 1, true) then return end
		local new = txt
		for _, n in ipairs(names) do
			if n ~= "" and string.find(new, n, 1, true) then
				new = string.gsub(new, EscPat(n), EscRep(fake))
			end
		end
		if new ~= txt then lbl.Text = new end
	end

	local function scan(root)
		for _, o in ipairs(root:GetDescendants()) do
			if o:IsA("TextLabel") or o:IsA("TextButton") then fix(o) end
		end
	end

	local char = LocalPlayer.Character
	if char then
		scan(char)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	end
	for _, bb in ipairs(extraBillboards) do
		if bb.Parent then scan(bb) end
	end
	for _, o in ipairs(PlayerGui:GetDescendants()) do
		if (o:IsA("TextLabel") or o:IsA("TextButton")) and not o:IsDescendantOf(Gui) then fix(o) end
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(2)
	if getgenv().HideNameRunning then pcall(ScanBillboards) end
end)

UI.Section(PrivacyPage, "PRIVACY & ANTI-ADMIN")
UI.Input(PrivacyPage, "Nama Samaran", "Dipakai saat Privacy Mode aktif", "UBEY HUB", "UBEY HUB", function(t)
	getgenv().FakeNameInput = t
end)

UI.Toggle(PrivacyPage, "Privacy Mode (Hide Name)", "Samarkan nama di atas kepala, HUD, dan karakter.", false, function(v)
	if v and not IsVerified() then return end
	getgenv().HideNameRunning = v
	if v then
		task.spawn(function()
			pcall(ScanBillboards)
			while getgenv().HideNameRunning do
				if not IsVerified() then getgenv().HideNameRunning = false; break end
				pcall(HideNameStep)
				task.wait(0.7)
			end
		end)
	end
end)

local GroupBox
GroupBox = UI.Input(PrivacyPage, "Group ID Admin", "ID grup game ini (0 = nonaktif)", getgenv().UbeyConfig.TargetGroupId, "0", function(t)
	local n = math.max(0, math.floor(tonumber(t) or 0))
	getgenv().UbeyConfig.TargetGroupId = tostring(n)
	GroupBox.Text = tostring(n)
	SaveConfig()
end)

UI.Toggle(PrivacyPage, "Anti-Admin Protect", "Pindah server otomatis jika admin grup masuk.", getgenv().UbeyConfig.AntiAdminEnabled, function(v)
	getgenv().UbeyConfig.AntiAdminEnabled = v
	SaveConfig()
end)

local function CheckPlayerIsAdmin(player)
	local gid = tonumber(getgenv().UbeyConfig.TargetGroupId) or 0
	if gid <= 0 then return false end
	local ok, rank = pcall(function() return player:GetRankInGroup(gid) end)
	return ok and rank and rank > 1
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		task.spawn(function()
			task.wait(1.5)
			if IsVerified() and getgenv().UbeyConfig.AntiAdminEnabled and CheckPlayerIsAdmin(player) then
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end
		end)
	end
end)

------------------------------------------------------------------
-- 5. SETTINGS
------------------------------------------------------------------
UI.Section(SettingsPage, "SETTINGS & PERFORMANCE")

UI.Button(SettingsPage, "Anti-Lag", "Matikan bayangan & partikel untuk naikkan FPS.", "Aktifkan", function(btn)
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 999999
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled = false end
		end
		btn.Text = "Aktif ✓"
	end)
end)

local BlackScreenGui = nil
local bsToggle
bsToggle = UI.Toggle(SettingsPage, "Black Screen (Battery Saver)", "Layar hitam hemat baterai. Sentuh layar untuk kembali.", false, function(v)
	if v then
		if not BlackScreenGui then
			BlackScreenGui = New("ScreenGui", {Name = "UbeyBlackScreen", DisplayOrder = 999999, IgnoreGuiInset = true, ResetOnSpawn = false}, PlayerGui)
			local frame = New("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(2, 2, 5)}, BlackScreenGui)
			Label(frame, "🌙 " .. HUB_TITLE .. " - BATTERY SAVER AKTIF\n(Sentuh layar untuk kembali)", 13, C.accent, Enum.Font.GothamBold,
				UDim2.new(0, 0, 0.45, 0), UDim2.new(1, 0, 0, 60), Enum.TextXAlignment.Center).TextWrapped = true
			frame.InputBegan:Connect(function()
				BlackScreenGui.Enabled = false
				bsToggle.Set(false)
			end)
		else
			BlackScreenGui.Enabled = true
		end
	elseif BlackScreenGui then
		BlackScreenGui.Enabled = false
	end
end)

UI.Section(SettingsPage, "KONFIGURASI", C.warn)
UI.Button(SettingsPage, "Simpan Konfigurasi", "Simpan semua pengaturan ke file.", "Simpan", function(btn)
	SaveConfig()
	Flash(btn, "Tersimpan ✓", true)
end, C.good)

UI.Button(SettingsPage, "Reset Konfigurasi & Clear Key", "Hapus config dan key tersimpan.", "Reset", function(btn)
	ResetConfig()
	KeyBox.Text = ""
	Flash(btn, "Direset ✓", true)
	task.wait(0.5)
	Lock("Key dihapus. Masukkan key lagi.")
end, Color3.fromRGB(180, 50, 50))

------------------------------------------------------------------
-- 6. CREDITS
------------------------------------------------------------------
UI.Section(CreditsPage, "CREDITS")
UI.Button(CreditsPage, "Created By UBEY", "Terima kasih sudah memakai " .. HUB_TITLE .. ".", "Discord", function(btn)
	pcall(function() if setclipboard then setclipboard(DISCORD_LINK) end end)
	Flash(btn, "Link disalin ✓", true)
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
	if not IsVerified() then
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)
