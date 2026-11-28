-- ==============================================================================
-- UBEY HUB V4 | PASAR HUTAN
-- GUI + sistem key dari Ubey Hub V4, isi script = Pasar Hutan v6.6
-- Key divalidasi di Supabase Edge Function (verify-key).
-- Opsional: set getgenv().UbeyHubLoader = 'loadstring(...)()' sebelum execute
-- supaya Auto Lapak bisa lanjut otomatis setelah pindah server.
--
-- v6.6:
--  * Kebun: lahan kecil/besar dipisah (bibit, tanam, siram, panen), lahan kecil
--    tanam 1 titik di tengah, jumlah lahan besar otomatis, mode gerak Instan/Jalan,
--    tombol teleport ke lahan.
--  * Peternakan: Auto Tetaskan Telur, Auto Ambil Anak Ayam, perbaikan Gosok Babi.
--  * Masak: Auto Panggang mengisi antrean sampai 3 babi.
--  * Tab Event (muncul saat event): Auto Kumpul Kepingan Salju.
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

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ====== TAMPILAN ======
local HUB_TITLE = "UBEY HUB"
local HUB_DISCORD = "discord.gg/YXuYeEpnXE"
local DISCORD_LINK = "https://discord.gg/YXuYeEpnXE"
local LOGO_ASSET = "rbxassetid://90770802417381"

-- ====== SERVER VERIFIKASI ======
local FUNCTION_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/functions/v1/verify-key"
local SUPABASE_ANON_KEY = "sb_publishable_rMWL7Qrjw9iG0c29vGZ0bw_O3swXT6n"
local HEARTBEAT_INTERVAL = 120

getgenv().SessionStartTime = os.time()

------------------------------------------------------------------
-- SESSION
------------------------------------------------------------------
local Session = {token = nil, key = nil, expiresAt = 0}

local function IsVerified()
	return Session.token ~= nil and os.time() < Session.expiresAt
end

-- semua flag fitur Pasar Hutan (dimatikan saat key dicabut / Stop Semua)
local ToggleSetters = {}
local ALL_FLAGS = {
	"AutoSemuaFarmActive", "KepitingFarmActive", "GagakFarmActive", "DupaFarmActive", "KemenyanFarmActive",
	"MelatiFarmActive", "JamurFarmActive", "PohonFarmActive", "BatuFarmActive", "AutoTuyulLiarActive",
	"AutoAyamActive", "AutoTetasActive", "AutoAnakAyamActive", "AutoSapiActive", "AutoBabiActive",
	"AutoGosokBabiActive", "AutoKlaimNgepetActive",
	"AutoTanamKecilActive", "AutoTanamBesarActive", "AutoSiramKecilActive", "AutoSiramBesarActive",
	"AutoPanenKecilActive", "AutoPanenBesarActive",
	"AutoKelolaLapakActive", "AutoMasakActive",
	"AutoOlahActive", "AutoPanggangActive", "AutoRepairActive", "AutoLatihPetActive", "AntiPetirActive",
	"AutoSaljuActive", "BatuBesiMode", "GagakOwlMode",
}

local function StopAll()
	for _, f in ipairs(ALL_FLAGS) do
		getgenv()[f] = false
		local s = ToggleSetters[f]
		if s then pcall(s, false) end
	end
end

local Lock
local OnVerified = function() end

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHubV4_PasarHutan_Config.json"
local KEY_FILE = "UbeyHubV3_SavedKey.txt"

local function DefaultConfig()
	return {WaterDuration = "2", MoveMode = "instan", SaljuMode = "instan"}
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
		getgenv().WaterDuration = 2
		if delfile and isfile then
			if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
			if isfile(KEY_FILE) then delfile(KEY_FILE) end
		end
	end)
end

LoadConfig()
getgenv().WaterDuration = tonumber(getgenv().UbeyConfig.WaterDuration) or 2

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

-- ==============================================================================
-- GUI SETUP
-- ==============================================================================
local function GetGuiParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	return PlayerGui
end
local GuiParent = GetGuiParent()

pcall(function()
	for _, p in ipairs({GuiParent, PlayerGui}) do
		local old = p:FindFirstChild("UbeyHub")
		if old then old:Destroy() end
	end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
Gui.Parent = GuiParent

local C = {
	bg = Color3.fromRGB(9, 12, 26), side = Color3.fromRGB(13, 17, 36),
	card = Color3.fromRGB(15, 21, 44), line = Color3.fromRGB(30, 42, 90),
	accent = Color3.fromRGB(45, 95, 255), off = Color3.fromRGB(32, 44, 105),
	text = Color3.fromRGB(240, 243, 255), sub = Color3.fromRGB(150, 160, 195),
	good = Color3.fromRGB(0, 230, 150), bad = Color3.fromRGB(255, 80, 80),
	warn = Color3.fromRGB(255, 200, 0), row = Color3.fromRGB(22, 30, 62)
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

local DRAG_THRESHOLD = 15

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
			if d.Magnitude > DRAG_THRESHOLD then moved = true end
			if moved then
				obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end)
	return function() return moved end
end

------------------------------------------------------------------
-- KEY FRAME
------------------------------------------------------------------
local KeyFrame = New("Frame", {
	Size = UDim2.new(0, 400, 0, 262), Position = UDim2.new(0.5, -200, 0.5, -131),
	BackgroundColor3 = C.bg, Visible = false, Active = true
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
local WIN_W, WIN_H = 580, 370
local Main = New("Frame", {
	Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
	BackgroundColor3 = C.bg, Visible = false, ClipsDescendants = true, Active = true
}, Gui)
Round(Main, 14)
New("UIStroke", {Color = C.line, Thickness = 1.5}, Main)

local Header = New("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1}, Main)
MakeDraggable(Main, Header)
Label(Header, HUB_TITLE, 15, C.text, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 5), UDim2.new(0, 110, 0, 20))
Label(Header, "PASAR HUTAN", 10, C.warn, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 23), UDim2.new(0, 110, 0, 14))
Label(Header, HUB_DISCORD, 10, C.sub, Enum.Font.Gotham, UDim2.new(0, 112, 0, 0), UDim2.new(0, 130, 1, 0))
local StatLabel = Label(Header, "📡 -- ms", 11, C.accent, Enum.Font.GothamBold, UDim2.new(0, 245, 0, 0), UDim2.new(1, -330, 1, 0), Enum.TextXAlignment.Right)

local MinimizeBtn = New("TextButton", {
	Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, -80, 0, 4), BackgroundTransparency = 1,
	Text = "—", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16
}, Header)
local CloseBtn = New("TextButton", {
	Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, -44, 0, 4), BackgroundTransparency = 1,
	Text = "✕", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16
}, Header)

local Body = New("Frame", {Size = UDim2.new(1, 0, 1, -42), Position = UDim2.new(0, 0, 0, 42), BackgroundTransparency = 1}, Main)

-- sidebar bisa discroll (tab Event muncul saat ada event, jadi total tab bisa 10)
local Sidebar = New("ScrollingFrame", {
	Size = UDim2.new(0, 150, 1, -10), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
	ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
	ScrollingEnabled = true
}, Body)
New("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)

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

-- Ping | waktu main
task.spawn(function()
	while true do
		pcall(function()
			local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			local elapsed = os.time() - getgenv().SessionStartTime
			local h, m, s = math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60
			local t = h > 0 and string.format("%dh %02dm", h, m) or string.format("%02dm %02ds", m, s)
			StatLabel.Text = string.format("📡 %d ms  |  ⏱ %s", ping, t)
		end)
		task.wait(1)
	end
end)

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

-- Anti-tamper
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

-- Heartbeat
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

local function SelectTab(tab)
	for _, t in ipairs(Tabs) do
		local on = (t == tab)
		t.Page.Visible = on
		t.Bar.Visible = on
		t.Button.BackgroundTransparency = on and 0 or 1
		t.Label.TextColor3 = on and C.text or C.sub
	end
	PageTitle.Text = tab.Name
end
UI.SelectTab = SelectTab

function UI.Tab(name, icon)
	local btn = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.card, BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "", LayoutOrder = #Tabs + 1
	}, Sidebar)
	Round(btn, 10)
	local bar = New("Frame", {Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = C.accent, Visible = false, BorderSizePixel = 0}, btn)
	Round(bar, 2)
	Label(btn, icon, 14, C.text, Enum.Font.Gotham, UDim2.new(0, 12, 0, 0), UDim2.new(0, 24, 1, 0), Enum.TextXAlignment.Center)
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

	btn.MouseButton1Click:Connect(function() SelectTab(tab) end)
	if #Tabs == 1 then
		page.Visible, bar.Visible = true, true
		btn.BackgroundTransparency = 0
		lbl.TextColor3 = C.text
		PageTitle.Text = name
	end
	return page, tab
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
	CardText(card, title, desc, 90)
	local sw = New("TextButton", {
		Text = "", AutoButtonColor = false, Size = UDim2.new(0, 52, 0, 26),
		Position = UDim2.new(1, -64, 0.5, -13), BackgroundColor3 = C.off
	}, card)
	Round(sw, 13)
	local knob = New("Frame", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = C.accent}, sw)
	Round(knob, 10)
	local state = default and true or false
	local function render()
		local ti = TweenInfo.new(0.15)
		TweenService:Create(knob, ti, {
			Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
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
		Size = UDim2.new(0, 104, 0, 34), Position = UDim2.new(1, -116, 0.5, -17),
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
		Size = UDim2.new(0, 112, 0, 34), Position = UDim2.new(1, -124, 0.5, -17),
		BackgroundColor3 = C.bg, Text = tostring(default or ""), PlaceholderText = placeholder or "",
		PlaceholderColor3 = C.sub, TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false
	}, card)
	Round(box, 8)
	New("UIStroke", {Color = C.line}, box)
	box.FocusLost:Connect(function() cb(box.Text) end)
	return box
end

-- pilihan segmen (mis. SIANG | MALAM)
function UI.Segment(page, title, options, get, set)
	local card = Card(page, 66)
	Label(card, title, 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 18))
	local row = New("Frame", {Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 28), BackgroundColor3 = C.bg}, card)
	Round(row, 8)
	local btns = {}
	local n = #options
	local function render()
		local cur = get()
		for key, b in pairs(btns) do
			local on = (key == cur)
			b.BackgroundColor3 = on and C.accent or C.bg
			b.TextColor3 = on and Color3.new(1, 1, 1) or C.sub
		end
	end
	for i, o in ipairs(options) do
		local b = New("TextButton", {
			Size = UDim2.new(1 / n, -4, 1, -4), Position = UDim2.new((i - 1) / n, 2, 0, 2),
			BackgroundColor3 = C.bg, Text = o.text, Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = C.sub, AutoButtonColor = false, BorderSizePixel = 0
		}, row)
		Round(b, 6)
		btns[o.key] = b
		b.MouseButton1Click:Connect(function() set(o.key) render() end)
	end
	render()
	return render
end

-- kartu status beberapa baris: obj.Set(nomorBaris, teks)
function UI.Status(page, lines)
	local card = New("Frame", {
		Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card
	}, page)
	Round(card, 10)
	New("UIStroke", {Color = C.line}, card)
	New("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)
	}, card)
	local lbl = New("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Text = "Siap.", TextSize = 11, TextColor3 = C.text, Font = Enum.Font.Gotham, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top
	}, card)
	local texts = {}
	for i = 1, lines do texts[i] = "" end
	local obj = {}
	obj.Set = function(i, t)
		texts[i] = tostring(t or "")
		local out = {}
		for _, s in ipairs(texts) do if s ~= "" then table.insert(out, s) end end
		lbl.Text = table.concat(out, "\n")
	end
	return obj
end

-- daftar yang bisa discroll dan dipilih
function UI.List(page, height, rowH)
	local card = Card(page, height)
	local sf = New("ScrollingFrame", {
		Size = UDim2.new(1, -12, 1, -12), Position = UDim2.new(0, 6, 0, 6), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y
	}, card)
	New("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
	local obj = {Frame = card, _y = 0}
	obj.Clear = function()
		obj._y = sf.CanvasPosition.Y
		for _, c in ipairs(sf:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
	end
	obj.Add = function(text, selected, onClick, rich, h, dim)
		local b = New("TextButton", {
			Size = UDim2.new(1, -6, 0, h or rowH or 26), BackgroundColor3 = selected and C.accent or C.row,
			Text = text, RichText = rich and true or false, TextColor3 = selected and Color3.new(1, 1, 1) or (dim and C.sub or C.text),
			Font = Enum.Font.GothamMedium, TextSize = rich and 10 or 11, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true, AutoButtonColor = true, BorderSizePixel = 0
		}, sf)
		Round(b, 6)
		New("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6)}, b)
		b.MouseButton1Click:Connect(function() onClick() end)
		return b
	end
	obj.Done = function()
		local y = obj._y
		task.defer(function() pcall(function() sf.CanvasPosition = Vector2.new(0, y) end) end)
	end
	return obj
end

-- beberapa tombol sejajar dalam satu kartu
function UI.Buttons(page, defs)
	local card = Card(page, 46)
	local n = #defs
	for i, d in ipairs(defs) do
		local b = New("TextButton", {
			Size = UDim2.new(1 / n, -8, 1, -12), Position = UDim2.new((i - 1) / n, 4, 0, 6),
			BackgroundColor3 = d.color or C.accent, Text = d.text, TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold, TextSize = 10, TextWrapped = true, AutoButtonColor = true, BorderSizePixel = 0
		}, card)
		Round(b, 8)
		b.MouseButton1Click:Connect(function()
			if not IsVerified() then return end
			task.spawn(d.cb, b)
		end)
	end
	return card
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
local KebunPage = UI.Tab("Kebun", "🌱")
local FarmPage = UI.Tab("Auto Farm", "⛏️")
local TernakPage = UI.Tab("Peternakan", "🐔")
local LapakPage = UI.Tab("Lapak", "🏪")
local MasakPage = UI.Tab("Masak", "🍳")
local TuyulPage = UI.Tab("Tuyul & Pet", "👻")
local EventPage, EventTab = UI.Tab("Event", "❄️")
EventTab.Button.Visible = false -- hanya muncul saat event aktif
local PlayerPage = UI.Tab("Player", "⚡")
local SettingsPage = UI.Tab("Settings", "⚙️")
local CreditsPage = UI.Tab("Credits", "💎")

------------------------------------------------------------------
-- KEY VALIDATION
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
		pcall(OnVerified)
	end)
end

SubmitKeyBtn.MouseButton1Click:Connect(function() ValidateKey(KeyBox.Text, false) end)

task.spawn(function()
	task.wait(1) -- beri waktu modul Pasar Hutan selesai dimuat
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
-- PASAR HUTAN | CORE (dipakai semua tab)
------------------------------------------------------------------
local H = {
	Total = 0, Returning = false, PetirDanger = false, JamurReturning = false,
	PohonSize = "semua", BatuSize = "semua", Harvested = 0, WalkSpeed = 22, PromptMode = "hold",
	SaljuWalk = (getgenv().UbeyConfig.SaljuMode == "jalan"),
}
local Q = {
	Kepiting = 0, Gagak = 0, Dupa = 0, Kemenyan = 0, Melati = 0, Jamur = 0, Pohon = 0, Batu = 0,
	Ayam = 0, Sapi = 0, Babi = 0, Ngepet = 0, Lapak = 0, Tuyul = 0, Dapur = 0, Olah = 0, Panggang = 0,
	Tetas = 0, Anak = 0, Salju = 0,
}
local FARM_FLAGS = {
	"AutoSemuaFarmActive", "KepitingFarmActive", "GagakFarmActive", "DupaFarmActive", "KemenyanFarmActive",
	"MelatiFarmActive", "JamurFarmActive", "PohonFarmActive", "BatuFarmActive", "AutoTuyulLiarActive",
	"AutoSaljuActive",
}
local ANIMAL_FLAGS = {
	"AutoAyamActive", "AutoTetasActive", "AutoAnakAyamActive", "AutoSapiActive", "AutoBabiActive",
	"AutoGosokBabiActive", "AutoKlaimNgepetActive",
}
local ACTIVE_FLAGS = { -- Gagak sengaja tidak masuk (sama seperti script asli)
	"AutoSemuaFarmActive", "KepitingFarmActive", "DupaFarmActive", "KemenyanFarmActive", "MelatiFarmActive",
	"JamurFarmActive", "PohonFarmActive", "BatuFarmActive", "AutoAyamActive", "AutoTetasActive",
	"AutoAnakAyamActive", "AutoSapiActive", "AutoBabiActive",
	"AutoGosokBabiActive", "AutoKlaimNgepetActive", "AutoTuyulLiarActive", "AutoSaljuActive",
}

do
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local VIM = game:GetService("VirtualInputManager")
	local PPS = game:GetService("ProximityPromptService")

	-- setiap kali execute, loop lama otomatis berhenti
	getgenv().UbeyPHRunId = (getgenv().UbeyPHRunId or 0) + 1
	local RUN = getgenv().UbeyPHRunId
	for _, c in ipairs(getgenv().UbeyPHConns or {}) do pcall(function() c:Disconnect() end) end
	local Conns = {}
	getgenv().UbeyPHConns = Conns

	H.RS = RS
	H.Run = function() return getgenv().UbeyPHRunId == RUN end
	H.Conn = function(c) table.insert(Conns, c) return c end

	for _, f in ipairs(ALL_FLAGS) do getgenv()[f] = false end
	getgenv().PH_Repairing = false
	getgenv().AutoTarikSisaFase = true
	getgenv().BabiPakanPilihan = getgenv().BabiPakanPilihan or "auto"
	getgenv().PanggangBabiKg = getgenv().PanggangBabiKg or "auto"
	getgenv().BatuIronBase = nil
	getgenv().AntiAFKRunning = true

	----------------------------------------------------------------
	-- REMOTE
	----------------------------------------------------------------
	H.R = {}
	local remoteMap = {}
	local function Find(names)
		for _, n in ipairs(names) do
			local k = string.lower(n)
			if remoteMap[k] then return remoteMap[k] end
		end
		for key, inst in pairs(remoteMap) do
			for _, n in ipairs(names) do
				if string.find(key, string.lower(n)) then return inst end
			end
		end
		return nil
	end
	H.Find = Find
	local REG_NAMES = {
		Rak = "RakAksi", Lapak = "LapakAksi", Tanam = "Tanam", Panen = "Panen", Pet = "PetCmd",
		Stove = "CookStove", StovePoll = "CookQueuePoll", OlahStart = "OlahMulai", OlahPoll = "OlahPoll",
		Petir = "Petir", SaleFx = "SaleFx", Tempa = "TempaAksi",
	}
	local FALLBACK = {
		Rak = {"r60fc0f14c95948a1b8f424b0c87c9ae4", "rakaksi", "rak"},
		Lapak = {"rf1cca891fcc741358fad82b58785b3b9", "lapakaksi", "lapak"},
		Tanam = {"r253d6aea043740e6a58d3993f00a778a", "tanam"},
		Panen = {"re21f8e95de624bfaae4b4c6918f08a57", "panen"},
		Pet = {"r7af0f7737fc845cc97af22d6032eeca5", "petcmd"},
		Stove = {"r8d5a4dd477db4290a641760b60794296", "cookstove"},
		StovePoll = {"r48d79ce5b49e413e9e43439fb4e52236", "cookqueuepoll"},
		OlahStart = {"rfa2c229485a548c0a0122bd19f578e40", "olahmulai"},
		OlahPoll = {"rafad8eca2ca6493ab24ac83fe78b2993", "olahpoll"},
		Petir = {"rdbc34f083ba248a198c5af3d8ece430f", "petir"},
		SaleFx = {"re1c6efd0e0244e8d8996c1e0552e3c45", "salefx"},
		Tempa = {"r029eb117e7d9434591e601adc512a5cd", "tempaaksi"},
	}
	function H.LoadRemotes()
		pcall(function()
			local reg = RS:WaitForChild("RemoteRegistry", 3)
			if not reg then return end
			local mod = require(reg)
			if type(mod) == "table" then
				for k, v in pairs(mod) do
					if typeof(v) == "Instance" then remoteMap[string.lower(tostring(k))] = v end
				end
			end
			local getter = mod.get or mod.cari
			if getter then
				for key, nm in pairs(REG_NAMES) do
					pcall(function()
						local r = getter(nm)
						if typeof(r) == "Instance" then H.R[key] = r end
					end)
				end
				if getupvalues then
					pcall(function()
						for _, up in ipairs(getupvalues(getter)) do
							if type(up) == "table" then
								for k, v in pairs(up) do
									if typeof(v) == "Instance" then remoteMap[string.lower(tostring(k))] = v
									elseif type(v) == "string" and typeof(k) == "Instance" then remoteMap[string.lower(tostring(v))] = k end
								end
							end
						end
					end)
				end
			end
		end)
		for _, d in ipairs(RS:GetDescendants()) do
			if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then remoteMap[string.lower(d.Name)] = d end
		end
		for key, names in pairs(FALLBACK) do
			if not H.R[key] then H.R[key] = Find(names) end
		end
	end
	H.LoadRemotes()

	H.GC = nil
	pcall(function() H.GC = require(RS:WaitForChild("GameConfig", 3)) end)

	----------------------------------------------------------------
	-- KARAKTER & ALAT
	----------------------------------------------------------------
	function H.Char()
		local ch = LocalPlayer.Character
		if not ch then return nil, nil end
		return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
	end
	function H.Live()
		local hrp, hum = H.Char()
		if hrp and hum and hum.Health > 0 then return hrp, hum end
		return nil, nil
	end
	function H.FindTool(name)
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		return (bp and bp:FindFirstChild(name)) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name))
	end
	function H.Clean(s)
		s = tostring(s or "")
		s = s:gsub("%s*[xX]%s*%d+", "")
		s = s:gsub("%s*%(%d+%)", "")
		s = s:gsub("%s*%[%d+%]", "")
		s = s:gsub("^%s+", "")
		s = s:gsub("%s+$", "")
		return s
	end

	local function ToolOk(t)
		if t:GetAttribute("Rusak") == true then return false end
		local d = t:GetAttribute("Dur")
		if type(d) == "number" and d <= 0 then return false end
		return true
	end
	local function ToolScore(t)
		local d, m = t:GetAttribute("Dur"), t:GetAttribute("DurMaks")
		local frac = (type(d) == "number" and type(m) == "number" and m > 0) and (d / m) or 0
		return (tonumber(t:GetAttribute("Tier")) or 0) * 1e6 + (tonumber(t:GetAttribute("Damage")) or 0) * 1e3
			+ (tonumber(t:GetAttribute("Mutu")) or 0) * 10 + (tonumber(t:GetAttribute("Tingkat")) or 0) + frac * 0.5
	end
	function H.BestTool(cat)
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		local ch = LocalPlayer.Character
		local list = {}
		local function scan(c)
			if not c then return end
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("AlatTambang") and t:GetAttribute("Jenis") == cat then table.insert(list, t) end
			end
		end
		scan(ch)
		scan(bp)
		if #list > 0 then
			local best, bs = nil, -math.huge
			local fb, fs = nil, -math.huge
			for _, t in ipairs(list) do
				local s = ToolScore(t)
				if ToolOk(t) then
					if s > bs then best, bs = t, s end
				elseif s > fs then fb, fs = t, s end
			end
			return best or fb
		end
		local kw = (cat == "Pohon") and "kapak" or "beliung"
		local function byName(c)
			if not c then return nil end
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") and t.Name:lower():find(kw) then return t end
			end
			return nil
		end
		return byName(ch) or byName(bp)
	end
	function H.EquipBest(cat)
		local _, hum = H.Live()
		if not hum then return false end
		local t = H.BestTool(cat)
		if not t then return false end
		if t.Parent ~= LocalPlayer.Character then
			hum:EquipTool(t)
			task.wait(0.2)
		end
		return t.Parent == LocalPlayer.Character
	end

	----------------------------------------------------------------
	-- GERAK
	----------------------------------------------------------------
	function H.ClearFly()
		local hrp = H.Char()
		if hrp then
			local a = hrp:FindFirstChild("FlyLockPos")
			if a then a:Destroy() end
			local g = hrp:FindFirstChild("FlyLockGyro")
			if g then g:Destroy() end
		end
		local _, hum = H.Live()
		if hum and hum.PlatformStand then hum.PlatformStand = false end
	end
	function H.WalkCtx()
		return getgenv().JamurFarmActive == true or getgenv().MelatiFarmActive == true or H.JamurReturning == true
			or (getgenv().AutoSaljuActive == true and H.SaljuWalk == true)
	end
	function H.FlyFloat(on)
		if H.WalkCtx() then on = false end
		H.ClearFly()
		local hrp = H.Char()
		if not hrp then return end
		local f = hrp:FindFirstChild("FlyFloat")
		if on then
			if not f then
				f = Instance.new("BodyVelocity")
				f.Name = "FlyFloat"
				f.MaxForce = Vector3.new(9e8, 9e8, 9e8)
				f.Parent = hrp
			end
			f.Velocity = Vector3.zero
			hrp.AssemblyLinearVelocity = Vector3.zero
		elseif f then
			f:Destroy()
		end
	end
	function H.AnyActive()
		for _, f in ipairs(ACTIVE_FLAGS) do
			if getgenv()[f] then return true end
		end
		return false
	end

	H.Conn(RunService.Stepped:Connect(function()
		if not H.Run() or H.WalkCtx() or not (H.AnyActive() or H.Returning) then return end
		local ch = LocalPlayer.Character
		if not ch then return end
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
		end
	end))

	function H.WalkToRaw(target, cancel, radius)
		radius = radius or 3.5
		local hrp, hum = H.Live()
		if not hrp or not hum then return false end
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {LocalPlayer.Character}
		local ray = workspace:Raycast(target + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), rp)
		local goal = ray and (ray.Position + Vector3.new(0, 0.5, 0)) or target
		local function dist()
			local h = H.Live()
			if not h then return math.huge end
			local d = h.Position - goal
			return Vector3.new(d.X, 0, d.Z).Magnitude
		end
		local function cancelled() return not H.Run() or (cancel and cancel()) or false end
		local speed = math.max(hum.WalkSpeed, 8)
		local deadline = tick() + math.clamp((hrp.Position - goal).Magnitude / speed * 2 + 8, 10, 120)
		local PFS = game:GetService("PathfindingService")
		local attempts = 0
		while dist() > radius and tick() < deadline and attempts < 6 do
			if cancelled() then return false end
			attempts += 1
			local h = H.Live()
			if not h then return false end
			local path = PFS:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
			local ok = pcall(function() path:ComputeAsync(h.Position, goal) end)
			local wps
			if ok and path.Status == Enum.PathStatus.Success then
				wps = path:GetWaypoints()
			else
				wps = {{Position = goal, Action = Enum.PathWaypointAction.Walk}}
			end
			local stuck = false
			for i, wp in ipairs(wps) do
				if i == 1 and #wps > 1 then continue end
				if cancelled() then return false end
				if dist() <= radius then break end
				local h2, hm2 = H.Live()
				if not h2 then return false end
				if wp.Action == Enum.PathWaypointAction.Jump then hm2.Jump = true end
				hm2:MoveTo(wp.Position)
				local t0, lastPos, lastMove = tick(), h2.Position, tick()
				while (tick() - t0) < 4 and tick() < deadline do
					task.wait(0.1)
					if cancelled() then return false end
					local h3 = H.Live()
					if not h3 then return false end
					local dd = h3.Position - wp.Position
					if Vector3.new(dd.X, 0, dd.Z).Magnitude < 3 then break end
					if dist() <= radius then break end
					if (h3.Position - lastPos).Magnitude > 0.6 then
						lastPos, lastMove = h3.Position, tick()
					elseif (tick() - lastMove) > 1.2 then
						hm2.Jump = true
						stuck = true
						break
					end
				end
				if stuck then break end
			end
		end
		local reached = dist() <= (radius + 1.5)
		local h, hm = H.Live()
		if h and hm then hm:MoveTo(h.Position) end
		return reached
	end
	function H.WalkTo(target, cancel, radius)
		local _, hum = H.Live()
		local orig = hum and hum.WalkSpeed
		if hum and orig and H.WalkSpeed > orig then hum.WalkSpeed = H.WalkSpeed end
		local ok, res = pcall(H.WalkToRaw, target, cancel, radius)
		if hum and orig then
			pcall(function() if hum.Parent then hum.WalkSpeed = orig end end)
		end
		if not ok then
			warn("[WalkTo] " .. tostring(res))
			return false
		end
		return res
	end
	function H.MoveNear(pos, cancel, walk)
		if walk then return H.WalkTo(pos, cancel, 3.5) end
		local hrp = H.Live()
		if not hrp then return false end
		hrp.CFrame = CFrame.new(pos)
		task.wait(0.15)
		return true
	end
	function H.TeleportTo(pos, cancel, walk)
		if walk then return H.WalkTo(pos, cancel) end
		local hrp = H.Live()
		if not hrp then return false end
		local from = hrp.Position
		local d = (from - pos).Magnitude
		if d <= 25 then
			hrp.CFrame = CFrame.new(pos)
			return true
		end
		local steps = math.ceil(d / 25)
		for i = 1, steps do
			if cancel and cancel() then return false end
			hrp = H.Live()
			if not hrp then return false end
			hrp.CFrame = CFrame.new(from:Lerp(pos, i / steps))
			task.wait(0.08)
		end
		hrp = H.Live()
		if hrp then hrp.CFrame = CFrame.new(pos) end
		return true
	end

	function H.Fire(prompt, hold)
		if not (prompt and prompt.Parent and prompt.Enabled) then return end
		local d = hold or prompt.HoldDuration or 1.1
		if H.PromptMode == "fire" and fireproximityprompt then
			pcall(fireproximityprompt, prompt, d + 0.1)
			task.wait(0.2)
		elseif H.PromptMode == "vim" then
			pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
			task.wait(d + 0.05)
			pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
		else
			pcall(function()
				prompt:InputHoldBegin()
				task.wait(d + 0.05)
				prompt:InputHoldEnd()
			end)
		end
	end

	-- pantau prompt yang sedang tampil (dipakai untuk menambang batu)
	local shown = setmetatable({}, {__mode = "k"})
	H.Conn(PPS.PromptShown:Connect(function(p) shown[p] = true end))
	H.Conn(PPS.PromptHidden:Connect(function(p) shown[p] = nil end))
	local function WaitShown(p, t)
		local t0 = tick()
		while tick() - t0 < t do
			if shown[p] then return true end
			if not p.Parent or not p.Enabled then return false end
			task.wait(0.05)
		end
		return shown[p] == true
	end
	function H.EnsurePrompt(p)
		if WaitShown(p, 1.3) then return true end
		local hrp = H.Live()
		local pos = p.Parent and (p.Parent:IsA("Attachment") and p.Parent.WorldPosition or (p.Parent:IsA("BasePart") and p.Parent.Position))
		if hrp and pos then
			local flat = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
			local diff = hrp.Position - flat
			local d = diff.Magnitude
			if d > 4.5 then
				local back = math.max(4, d * 0.7)
				hrp.CFrame = CFrame.lookAt(flat + diff.Unit * back, flat)
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end
		return WaitShown(p, 1.0)
	end

	-- kamera khusus saat menambang batu
	local function RestoreCam()
		local s = getgenv().PH_CamSaved
		if not s then return end
		pcall(function()
			LocalPlayer.CameraMinZoomDistance = 0.5
			LocalPlayer.CameraMaxZoomDistance = s.maxZ
			LocalPlayer.CameraMinZoomDistance = s.minZ
			LocalPlayer.DevCameraOcclusionMode = s.occ
		end)
		getgenv().PH_CamSaved = nil
	end
	RestoreCam()
	H.RestoreCam = RestoreCam
	function H.LockCam()
		pcall(function()
			if not getgenv().PH_CamSaved then
				getgenv().PH_CamSaved = {
					occ = LocalPlayer.DevCameraOcclusionMode,
					minZ = LocalPlayer.CameraMinZoomDistance,
					maxZ = LocalPlayer.CameraMaxZoomDistance,
				}
			end
			LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
			LocalPlayer.CameraMinZoomDistance = 0.5
			LocalPlayer.CameraMaxZoomDistance = 14
			LocalPlayer.CameraMinZoomDistance = 14
		end)
	end
	function H.FaceRock(rock)
		local hrp = H.Live()
		if not hrp or not rock or not rock.Parent then return end
		local target = Vector3.new(rock.Position.X, hrp.Position.Y, rock.Position.Z)
		local diff = target - hrp.Position
		if diff.Magnitude < 0.5 then return end
		if hrp.CFrame.LookVector:Dot(diff.Unit) < 0.98 then hrp.CFrame = CFrame.lookAt(hrp.Position, target) end
	end

	----------------------------------------------------------------
	-- PLOT, PANEN, NODE
	----------------------------------------------------------------
	function H.Plot()
		local folder = workspace:FindFirstChild("Plot") or workspace:FindFirstChild("Plots")
		if not folder then return nil, nil end
		local uid = LocalPlayer.UserId
		for _, p in ipairs(folder:GetChildren()) do
			local lahan = p:FindFirstChild("Lahan1") or p:FindFirstChild("Lahan")
			if (lahan and (lahan:GetAttribute("Owner") == uid or lahan:GetAttribute("OwnerId") == uid))
				or p:GetAttribute("Owner") == uid or p:GetAttribute("OwnerUserId") == uid or p.Name:find(tostring(uid)) then
				return p, lahan
			end
		end
		return nil, nil
	end

	local harvestLast = setmetatable({}, {__mode = "k"})
	function H.Harvest(plant)
		local rem = H.R.Panen
		if not rem then return end
		if not (plant and plant.Parent) or plant:GetAttribute("Ready") ~= true then return end
		local now = tick()
		if harvestLast[plant] and (now - harvestLast[plant]) < 0.6 then return end
		harvestLast[plant] = now
		rem:FireServer(plant)
		task.delay(0.3, function()
			if not plant.Parent or plant:GetAttribute("Ready") ~= true then H.Harvested += 1 end
		end)
	end

	function H.NodeOk(n)
		return n and n.item and n.item.Parent ~= nil and n.prompt and n.prompt.Parent ~= nil and n.prompt.Enabled
	end

	function H.FetchBahan(query, cool)
		local folder = workspace:FindFirstChild("SpawnBahan")
		local hrp = H.Char()
		if not folder or not hrp then return {} end
		local out, now = {}, tick()
		for _, p in ipairs(folder:GetChildren()) do
			if p:IsA("BasePart") and string.find(string.lower(p.Name), query, 1, true) then
				local vis = p:FindFirstChild("BahanVisual")
				local prm = vis and vis:FindFirstChild("AmbilPrompt", true)
				if prm and prm.Enabled and (not cool[p] or now > cool[p]) then
					table.insert(out, {item = p, prompt = prm, pos = p.Position, dist = (hrp.Position - p.Position).Magnitude})
				end
			end
		end
		table.sort(out, function(a, b) return a.dist < b.dist end)
		return out
	end

	function H.FetchCraft(jenis, sizeKey, cool)
		local folder = workspace:FindFirstChild("BahanCraft")
		local hrp = H.Char()
		if not folder or not hrp then return {} end
		local out, now = {}, tick()
		for _, m in ipairs(folder:GetChildren()) do
			local jn = m:GetAttribute("Jenis")
			if not jn then jn = m.Name:lower():find("batu") and "Batu" or "Pohon" end
			local lname = m.Name:lower()
			local sizeOk = true
			if sizeKey == "besar" then sizeOk = lname:find("besar") ~= nil
			elseif sizeKey == "kecil" then sizeOk = lname:find("kecil") ~= nil
			elseif sizeKey == "sedang" then sizeOk = lname:find("sedang") ~= nil end
			if jn == jenis and sizeOk and not m:GetAttribute("Tumbang") then
				local prm = m:FindFirstChildWhichIsA("ProximityPrompt", true)
				local part = (prm and prm.Parent:IsA("BasePart") and prm.Parent)
					or (prm and prm.Parent:IsA("Attachment") and prm.Parent.Parent:IsA("BasePart") and prm.Parent.Parent)
					or m:FindFirstChildWhichIsA("BasePart", true)
				if prm and prm.Enabled and part and (not cool[m] or now > cool[m]) then
					local ppos = prm.Parent:IsA("Attachment") and prm.Parent.WorldPosition or part.Position
					local pos
					if jn == "Batu" then
						local rp = part.Position
						local off = math.max(part.Size.X, part.Size.Z) * 0.5 + 3.0
						local dir = hrp.Position - rp
						dir = Vector3.new(dir.X, 0, dir.Z)
						dir = (dir.Magnitude < 0.1) and Vector3.new(0, 0, 1) or dir.Unit
						local base = rp + dir * off
						local rq = RaycastParams.new()
						rq.FilterType = Enum.RaycastFilterType.Exclude
						rq.FilterDescendantsInstances = {workspace.BahanCraft, LocalPlayer.Character}
						local hit = workspace:Raycast(base + Vector3.new(0, 15, 0), Vector3.new(0, -60, 0), rq)
						local y = hit and (hit.Position.Y + 3.0) or (part.Position.Y - part.Size.Y * 0.5 + 3.0)
						pos = Vector3.new(base.X, y, base.Z)
					else
						pos = ppos
					end
					table.insert(out, {item = m, prompt = prm, part = part, pos = pos, dist = (hrp.Position - ppos).Magnitude})
				end
			end
		end
		table.sort(out, function(a, b) return a.dist < b.dist end)
		return out
	end

	function H.IronCount()
		local n = 0
		local function scan(c)
			if not c then return end
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemId") == "BijiBesi" then n += (t:GetAttribute("Count") or 1) end
			end
		end
		scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
		scan(LocalPlayer.Character)
		return n
	end

	-- hanya satu mode aktif: mulai farm -> farm lain mati; mulai farm -> ternak mati
	local function Off(f)
		getgenv()[f] = false
		local s = ToggleSetters[f]
		if s then pcall(s, false) end
	end
	function H.Exclusive(flag)
		local isFarm = table.find(FARM_FLAGS, flag) ~= nil
		local isAnimal = table.find(ANIMAL_FLAGS, flag) ~= nil
		if not (isFarm or isAnimal) then return end
		for _, f in ipairs(FARM_FLAGS) do
			if f ~= flag and getgenv()[f] then Off(f) end
		end
		if isFarm then
			for _, f in ipairs(ANIMAL_FLAGS) do
				if getgenv()[f] then Off(f) end
			end
		end
	end
	H.Off = Off
end

-- toggle yang terhubung ke flag getgenv()
local function FlagToggle(page, title, desc, flag, after, fly)
	local t = UI.Toggle(page, title, desc, false, function(v)
		if v and not IsVerified() then return end
		getgenv()[flag] = v
		if v then
			H.Exclusive(flag)
		elseif fly and not H.AnyActive() and not H.Returning then
			H.FlyFloat(false)
		end
		if after then after(v) end
	end)
	ToggleSetters[flag] = t.Set
	return t
end

------------------------------------------------------------------
-- TAB KEBUN (lahan kecil & lahan besar dipisah)
------------------------------------------------------------------
do
	local RS = H.RS
	local selected = {kecil = nil, besar = nil}
	local harvestAllBusy = false
	local BIG_FALLBACK = {Apel = true, Jeruk = true, Kopi = true, Pisang = true}
	local PlantCatalog = nil
	pcall(function() PlantCatalog = require(RS:WaitForChild("PlantCatalog", 3)) end)
	local KS = {panen = false, tanam = false}
	local bigTpIdx = 0

	local function WalkMode() return getgenv().UbeyConfig.MoveMode == "jalan" end
	local function anySiram() return getgenv().AutoSiramKecilActive or getgenv().AutoSiramBesarActive end
	local function anyTanam() return getgenv().AutoTanamKecilActive or getgenv().AutoTanamBesarActive end
	local function anyPanen() return getgenv().AutoPanenKecilActive or getgenv().AutoPanenBesarActive end

	local function IsBig(key)
		local p = PlantCatalog and PlantCatalog.Plants and PlantCatalog.Plants[key]
		if p and p.potType then return p.potType == "PotBesar" end
		return BIG_FALLBACK[key] == true
	end
	local function IsSeed(t)
		return t:IsA("Tool") and (t:GetAttribute("IsSeed") or t:GetAttribute("PlantType") or t.Name:lower():find("bibit"))
	end
	local function SeedKey(t)
		local pt = t:GetAttribute("PlantType")
		if pt then return tostring(pt) end
		return H.Clean(t.Name)
	end
	local function ScanSeeds()
		local map, list = {}, {}
		local function scan(c)
			if not c then return end
			for _, t in ipairs(c:GetChildren()) do
				if IsSeed(t) then
					local key = SeedKey(t)
					local cnt = t:GetAttribute("Count") or tonumber(t.Name:match("%d+")) or 1
					local e = map[key]
					if not e then
						local clean = t:GetAttribute("PlantType") and tostring(t:GetAttribute("PlantType")) or key
						clean = clean:gsub("^[Bb]ibit%s*", "")
						e = {key = key, cleanName = clean, count = 0, big = IsBig(key)}
						map[key] = e
						table.insert(list, e)
					end
					e.count += cnt
				end
			end
		end
		scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
		scan(LocalPlayer.Character)
		table.sort(list, function(a, b) return a.cleanName:lower() < b.cleanName:lower() end)
		return list
	end
	local function FindSeed(key)
		local ch = LocalPlayer.Character
		if ch then
			for _, t in ipairs(ch:GetChildren()) do
				if IsSeed(t) and SeedKey(t) == key then return t end
			end
		end
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				if IsSeed(t) and SeedKey(t) == key then return t end
			end
		end
		return nil
	end
	local function EquipSeed(key)
		local _, hum = H.Live()
		if not hum then return nil end
		local tool = FindSeed(key)
		if not tool then return nil end
		if tool.Parent ~= LocalPlayer.Character then
			hum:UnequipTools()
			task.wait(0.1)
			tool = FindSeed(key)
			if not tool then return nil end
			hum:EquipTool(tool)
			task.wait(0.25)
		end
		local cur = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
		if cur and IsSeed(cur) and SeedKey(cur) == key then return cur end
		return nil
	end
	local function CountPlants(lahan)
		local small, big = 0, 0
		for _, p in ipairs(lahan.Tanaman:GetChildren()) do
			if p:GetAttribute("Besar") == true then big += 1 else small += 1 end
		end
		return small, big
	end
	-- lahan kecil: satu titik di tengah lahan (siram cukup 1x per panen)
	local function CenterPoint(part)
		return part.CFrame:PointToWorldSpace(Vector3.new(0, part.Size.Y / 2, 0))
	end
	-- lahan besar: jumlah kotak otomatis sesuai yang dimiliki player
	local function BigPlots(plot)
		local folder = plot and plot:FindFirstChild("LahanBesar")
		local out = {}
		if not folder then return out end
		for _, p in ipairs(folder:GetChildren()) do
			local n = tonumber(p.Name:match("%d+"))
			local mesh = p:FindFirstChildWhichIsA("MeshPart", true)
			if n and mesh then
				table.insert(out, {n = n, key = "b" .. n, spot = Vector3.new(mesh.Position.X, mesh.Position.Y + mesh.Size.Y / 2, mesh.Position.Z)})
			end
		end
		table.sort(out, function(a, b) return a.n < b.n end)
		return out
	end
	local function BigOccupied(lahan, spot)
		for _, p in ipairs(lahan.Tanaman:GetChildren()) do
			if p:GetAttribute("Besar") == true then
				local d = p:GetPivot().Position - spot
				if Vector3.new(d.X, 0, d.Z).Magnitude < 5 then return true end
			end
		end
		return false
	end

	----------------------------------------------------------------
	-- UI: BIBIT (2 kotak: lahan kecil & lahan besar)
	----------------------------------------------------------------
	UI.Section(KebunPage, "BIBIT LAHAN KECIL")
	local hdrK = UI.Status(KebunPage, 1)
	hdrK.Set(1, "Memuat...")
	local listK = UI.List(KebunPage, 100)
	UI.Section(KebunPage, "BIBIT LAHAN BESAR")
	local hdrB = UI.Status(KebunPage, 1)
	hdrB.Set(1, "Memuat...")
	local listB = UI.List(KebunPage, 100)

	local RefreshSeeds
	local function FillList(kind, hdr, lst, all)
		local list = {}
		for _, e in ipairs(all) do
			if e.big == (kind == "besar") then table.insert(list, e) end
		end
		lst.Clear()
		local label = (kind == "besar") and "lahan besar" or "lahan kecil"
		if #list == 0 then
			selected[kind] = nil
			hdr.Set(1, "Tidak ada bibit " .. label .. " di tas")
			lst.Done()
			return
		end
		local found
		for _, e in ipairs(list) do
			if e.key == selected[kind] then found = e end
		end
		if selected[kind] and not found then selected[kind] = nil end
		if not selected[kind] and #list == 1 then
			selected[kind] = list[1].key
			found = list[1]
		end
		if found then hdr.Set(1, "Ditanam: " .. found.cleanName) else hdr.Set(1, "Pilih bibit " .. label .. ":") end
		for _, e in ipairs(list) do
			lst.Add(e.cleanName .. " (x" .. e.count .. ")", e.key == selected[kind], function()
				selected[kind] = e.key
				RefreshSeeds()
			end)
		end
		lst.Done()
	end
	RefreshSeeds = function()
		local all = ScanSeeds()
		FillList("kecil", hdrK, listK, all)
		FillList("besar", hdrB, listB, all)
	end
	H.RefreshSeeds = RefreshSeeds

	----------------------------------------------------------------
	-- UI: TANAM / SIRAM / PANEN (dipisah per jenis lahan)
	----------------------------------------------------------------
	UI.Section(KebunPage, "TANAM")
	FlagToggle(KebunPage, "Auto Tanam Lahan Kecil", "Tanam 1 bibit di titik tengah lahan.", "AutoTanamKecilActive")
	FlagToggle(KebunPage, "Auto Tanam Lahan Besar", "Tanam di semua kotak lahan besarmu.", "AutoTanamBesarActive")

	UI.Section(KebunPage, "SIRAM")
	FlagToggle(KebunPage, "Auto Siram Lahan Kecil", "Siram tanaman lahan kecil yang airnya hampir habis.", "AutoSiramKecilActive")
	FlagToggle(KebunPage, "Auto Siram Lahan Besar", "Siram tanaman lahan besar yang airnya hampir habis.", "AutoSiramBesarActive")
	UI.Segment(KebunPage, "Durasi Siram", {
		{key = 2.0, text = "2.0s"}, {key = 2.5, text = "2.5s"}, {key = 3.0, text = "3.0s"},
		{key = 3.5, text = "3.5s"}, {key = 4.0, text = "4.0s"},
	}, function() return getgenv().WaterDuration end, function(k)
		getgenv().WaterDuration = k
		getgenv().UbeyConfig.WaterDuration = tostring(k)
		SaveConfig()
	end)

	UI.Section(KebunPage, "PANEN")
	FlagToggle(KebunPage, "Auto Panen Lahan Kecil", "Panen tanaman lahan kecil yang sudah siap.", "AutoPanenKecilActive")
	FlagToggle(KebunPage, "Auto Panen Lahan Besar", "Panen tanaman lahan besar yang sudah siap.", "AutoPanenBesarActive")

	local function HarvestNow(kind, btn)
		if harvestAllBusy then return end
		local _, lahan = H.Plot()
		if not lahan or not lahan:FindFirstChild("Tanaman") then Flash(btn, "Lahan tidak ada", false) return end
		harvestAllBusy = true
		for _, p in ipairs(lahan.Tanaman:GetChildren()) do
			if (p:GetAttribute("Besar") == true) == (kind == "besar") then
				H.Harvest(p)
				task.wait(0.1)
			end
		end
		harvestAllBusy = false
		Flash(btn, "Selesai ✓", true)
	end
	UI.Buttons(KebunPage, {
		{text = "PANEN SEKARANG\n(LAHAN KECIL)", color = C.accent, cb = function(b) HarvestNow("kecil", b) end},
		{text = "PANEN SEKARANG\n(LAHAN BESAR)", color = C.good, cb = function(b) HarvestNow("besar", b) end},
	})

	----------------------------------------------------------------
	-- UI: LOKASI (teleport / jalan)
	----------------------------------------------------------------
	UI.Section(KebunPage, "LOKASI KEBUN")
	UI.Segment(KebunPage, "Mode Gerak (Tanam / Siram / Panen)", {
		{key = "instan", text = "TELEPORT INSTAN"}, {key = "jalan", text = "JALAN KAKI"},
	}, function() return getgenv().UbeyConfig.MoveMode end, function(k)
		getgenv().UbeyConfig.MoveMode = k
		SaveConfig()
	end)

	local function GoManual(pos)
		if not H.Live() then return false end
		if WalkMode() then return H.WalkTo(pos, nil, 3.5) end
		local hrp = H.Live()
		if not hrp then return false end
		hrp.CFrame = CFrame.new(pos)
		return true
	end
	local tpBusy = false
	UI.Buttons(KebunPage, {
		{text = "KE LAHAN\nKECIL", color = C.accent, cb = function(btn)
			if tpBusy then return end
			local _, lahan = H.Plot()
			if not lahan then Flash(btn, "Lahan tidak ada", false) return end
			tpBusy = true
			GoManual(lahan.Position + Vector3.new(0, lahan.Size.Y / 2 + 3, 0))
			tpBusy = false
			Flash(btn, "Sampai ✓", true)
		end},
		{text = "KE LAHAN\nBESAR", color = C.good, cb = function(btn)
			if tpBusy then return end
			local plot = H.Plot()
			local bigs = BigPlots(plot)
			if #bigs == 0 then Flash(btn, "Tidak ada lahan besar", false) return end
			bigTpIdx = (bigTpIdx % #bigs) + 1
			local target = bigs[bigTpIdx]
			tpBusy = true
			GoManual(target.spot + Vector3.new(0, 3, 0))
			tpBusy = false
			Flash(btn, "Lahan besar #" .. target.n .. " ✓", true)
		end},
	})

	local kebunInfo = UI.Status(KebunPage, 1)
	kebunInfo.Set(1, "Kecil: 0/1 | Besar: 0/0 | Siap Panen: 0\nDipanen: 0 Hasil")

	----------------------------------------------------------------
	-- LOOP PANEN: kecil langsung, besar didatangi satu per satu
	----------------------------------------------------------------
	task.spawn(function()
		local function harvestBig(list)
			local t0 = tick()
			while KS.tanam and (tick() - t0) < 2 and H.Run() do task.wait(0.05) end
			KS.panen = true
			local hrp = H.Live()
			local saved = hrp and hrp.CFrame
			local ok, err = pcall(function()
				for _, p in ipairs(list) do
					if not H.Run() or not getgenv().AutoPanenBesarActive or H.AnyActive() or H.Returning then break end
					if p.Parent and p:GetAttribute("Ready") == true then
						local h = H.Live()
						if not h then break end
						if H.MoveNear(p:GetPivot().Position + Vector3.new(0, 3, 0), function()
							return not getgenv().AutoPanenBesarActive or H.AnyActive() or H.Returning
						end, WalkMode()) then
							task.wait(0.1)
							H.Harvest(p)
							task.wait(0.15)
						end
					end
				end
				if saved and not anySiram() and not anyTanam() then
					if WalkMode() then
						H.WalkTo(saved.Position, function()
							return not getgenv().AutoPanenBesarActive or anySiram() or anyTanam()
						end, 3)
					else
						local h = H.Live()
						if h then h.CFrame = saved end
					end
				end
			end)
			KS.panen = false
			if not ok then warn("[AutoPanen Besar] " .. tostring(err)) end
		end
		local lahan = nil
		while H.Run() do
			task.wait(0.2)
			if not anyPanen() or H.AnyActive() or H.Returning or harvestAllBusy then continue end
			if not (lahan and lahan.Parent) then
				local _, l = H.Plot()
				lahan = l
			end
			local tan = lahan and lahan:FindFirstChild("Tanaman")
			if not tan then continue end
			local bigList = {}
			for _, pl in ipairs(tan:GetChildren()) do
				if not H.Run() or not anyPanen() or H.AnyActive() or H.Returning then break end
				if pl:GetAttribute("Ready") == true then
					if pl:GetAttribute("Besar") == true then
						if getgenv().AutoPanenBesarActive then table.insert(bigList, pl) end
					elseif getgenv().AutoPanenKecilActive then
						H.Harvest(pl)
						task.wait(0.05)
					end
				end
			end
			if #bigList > 0 and H.Run() and getgenv().AutoPanenBesarActive and not H.AnyActive() and not H.Returning then
				harvestBig(bigList)
			end
		end
	end)

	----------------------------------------------------------------
	-- LOOP SIRAM + TANAM
	----------------------------------------------------------------
	task.spawn(function()
		local waterCool = setmetatable({}, {__mode = "k"})
		local plantCool = {}
		local smallBlock = nil

		local function waterWanted(plant)
			if plant:GetAttribute("Besar") == true then return getgenv().AutoSiramBesarActive == true end
			return getgenv().AutoSiramKecilActive == true
		end

		-- tanam untuk satu jenis lahan ("kecil" / "besar"); true jika ada yang berhasil ditanam
		local function PlantKind(kind, plot, lahan)
			local flag = (kind == "besar") and "AutoTanamBesarActive" or "AutoTanamKecilActive"
			local seed = selected[kind]
			if not (getgenv()[flag] and seed and H.R.Tanam) then return false end
			if H.AnyActive() or H.Returning then return false end
			if not FindSeed(seed) then return false end
			local spots = {}
			if kind == "besar" then
				for _, bp in ipairs(BigPlots(plot)) do
					if not BigOccupied(lahan, bp.spot) then table.insert(spots, {key = bp.key, spot = bp.spot, big = true}) end
				end
			elseif not (smallBlock and tick() < smallBlock) then
				if (CountPlants(lahan)) < 1 then
					table.insert(spots, {key = "k1", spot = CenterPoint(lahan)})
				end
			end
			local planted = false
			for _, sp in ipairs(spots) do
				if not H.Run() or not getgenv()[flag] or H.AnyActive() or H.Returning then break end
				if not FindSeed(seed) then break end
				while KS.panen and H.Run() do task.wait(0.05) end
				local blocked = plantCool[sp.key] and tick() < plantCool[sp.key]
				if not blocked then
					KS.tanam = true
					if not EquipSeed(seed) then break end
					if not H.Live() then break end
					if not H.MoveNear(sp.spot + Vector3.new(0, 3, 0), function()
						return not getgenv()[flag] or KS.panen
					end, WalkMode()) then
						break
					end
					if not EquipSeed(seed) then break end
					local before = #lahan.Tanaman:GetChildren()
					H.R.Tanam:FireServer(sp.spot)
					planted = true
					task.wait(0.5)
					if #lahan.Tanaman:GetChildren() <= before then
						if sp.big then
							plantCool[sp.key] = tick() + 30
						else
							smallBlock = tick() + 8
							break
						end
					end
				end
				KS.tanam = false
			end
			KS.tanam = false
			return planted
		end

		while H.Run() do
			task.wait(1.2)
			if H.AnyActive() or H.Returning then continue end
			local plot, lahan = H.Plot()
			if not lahan or not lahan:FindFirstChild("Tanaman") then
				kebunInfo.Set(1, "Plot / Lahan milikmu tidak ditemukan")
				continue
			end
			local ready = 0
			for _, p in ipairs(lahan.Tanaman:GetChildren()) do
				if p:GetAttribute("Ready") == true then ready += 1 end
			end
			local small, big = CountPlants(lahan)
			kebunInfo.Set(1, string.format("Kecil: %d/1 | Besar: %d/%d | Siap Panen: %d\nDipanen: %d Hasil", small, big, #BigPlots(plot), ready, H.Harvested))

			if anySiram() then
				local can = H.FindTool("PenyiramTanaman")
				if can then
					for _, plant in ipairs(lahan.Tanaman:GetChildren()) do
						if not H.Run() or H.AnyActive() or H.Returning or not anySiram() then break end
						while KS.panen and H.Run() do task.wait(0.05) end
						local water = plant:GetAttribute("AirSisa")
						local need = plant.Parent and waterWanted(plant) and plant:GetAttribute("Ready") ~= true
							and water ~= nil and water <= 25 and (not waterCool[plant] or tick() > waterCool[plant])
						if need then
							local h, hm = H.Live()
							if not h then break end
							hm:EquipTool(can)
							task.wait(0.2)
							h, hm = H.Live()
							if not h then break end
							if not H.MoveNear(plant:GetPivot().Position + Vector3.new(0, 2, 0), function()
								return not anySiram() or KS.panen
							end, WalkMode()) then continue end
							can:Activate()
							local t0 = tick()
							local interrupted = false
							while (tick() - t0) < getgenv().WaterDuration do
								if KS.panen then interrupted = true break end
								if not H.Run() or not anySiram() or H.AnyActive() or H.Returning or not H.Live() then break end
								task.wait(0.1)
							end
							can:Deactivate()
							if not interrupted then waterCool[plant] = tick() + 10 end
							task.wait(0.2)
						end
					end
				end
			end

			if anyTanam() and not H.AnyActive() and not H.Returning then
				local a = PlantKind("kecil", plot, lahan)
				local b = PlantKind("besar", plot, lahan)
				if a or b then RefreshSeeds() end
			end
		end
	end)
end

------------------------------------------------------------------
-- TAB AUTO FARM
------------------------------------------------------------------
do
	local RunService = game:GetService("RunService")
	local VIM = game:GetService("VirtualInputManager")
	local PFS = game:GetService("PathfindingService")

	local LABEL = {
		Kepiting = "Kepiting", Gagak = "Gagak", Dupa = "Dupa", Kemenyan = "Kemenyan", Melati = "Melati",
		Jamur = "Jamur Kuburan", Pohon = "Kayu", Batu = "Batu",
	}
	local Counters = {}
	local semuaStatus
	local semuaCounter

	-- kartu toggle + status (baris 1 = status, baris 2 = counter)
	local function FarmUI(name, title, flag, extraLines)
		local st
		FlagToggle(FarmPage, title, nil, flag, function(v)
			if not v and st then st.Set(1, "Status: Berhenti") end
		end, true)
		st = UI.Status(FarmPage, 2 + (extraLines or 0))
		st.Set(1, "Status: Siap (OFF)")
		st.Set(2, "Terkumpul: 0 " .. LABEL[name])
		local obj = {st = st}
		obj.status = function(t) st.Set(1, t) end
		obj.counter = function(t) st.Set(2, t) end
		Counters[name] = obj.counter
		return obj
	end

	local SIZE_OPTS = {{key = "semua", text = "SEMUA"}, {key = "besar", text = "BESAR"}, {key = "kecil", text = "KECIL"}}

	----------------------------------------------------------------
	-- AUTO FARM SEMUA
	----------------------------------------------------------------
	UI.Section(FarmPage, "AUTO FARM SEMUA")
	do
		local st
		FlagToggle(FarmPage, "Auto Farm Semua", "Kep > Dupa > Kem > Melati > Jamur", "AutoSemuaFarmActive", function(v)
			if not v and st then st.Set(1, "Status: Berhenti") end
		end, true)
		st = UI.Status(FarmPage, 2)
		st.Set(1, "Status: Siap (OFF)")
		st.Set(2, "Total Terkumpul: 0 Item")
		semuaStatus = function(t) st.Set(1, t) end
		semuaCounter = function(t) st.Set(2, t) end
	end

	UI.Section(FarmPage, "FARM BAHAN (TELEPORT)")
	local UIKep = FarmUI("Kepiting", "Auto Farm Kepiting", "KepitingFarmActive")
	local UIDupa = FarmUI("Dupa", "Auto Farm Dupa", "DupaFarmActive")
	local UIKem = FarmUI("Kemenyan", "Auto Farm Kemenyan", "KemenyanFarmActive")

	UI.Section(FarmPage, "FARM JALAN KAKI")
	local UIMelati = FarmUI("Melati", "Auto Farm Melati", "MelatiFarmActive")
	local UIJamur = FarmUI("Jamur", "Auto Farm Jamur Kuburan", "JamurFarmActive")
	local UIGagak = FarmUI("Gagak", "Auto Farm Gagak (jalan kaki)", "GagakFarmActive")
	FlagToggle(FarmPage, "Pakai Owl Staff", "Terbang +-30 stud/dtk (staff harus ada di tas).", "GagakOwlMode")

	UI.Section(FarmPage, "FARM POHON & BATU")
	local UIPohon = FarmUI("Pohon", "Auto Farm Pohon", "PohonFarmActive")
	UI.Segment(FarmPage, "Ukuran Pohon", SIZE_OPTS, function() return H.PohonSize end, function(k) H.PohonSize = k end)
	local UIBatu = FarmUI("Batu", "Auto Farm Batu", "BatuFarmActive", 1)
	UI.Segment(FarmPage, "Ukuran Batu", SIZE_OPTS, function() return H.BatuSize end, function(k) H.BatuSize = k end)
	UIBatu.st.Set(3, "Biji Besi: +0")
	FlagToggle(FarmPage, "Mode Biji Besi", "Fokus batu besar/sedang untuk biji besi.", "BatuBesiMode")

	----------------------------------------------------------------
	-- FARM GENERIK (bahan, kayu, batu, melati, jamur)
	----------------------------------------------------------------
	local function RunFarm(cfg)
		task.spawn(function()
			local cool = setmetatable({}, {__mode = "k"})
			local savedPos = nil
			local atHome = false
			local walk = (cfg.name == "Jamur" or cfg.name == "Melati")
			local function active()
				return H.Run() and getgenv()[cfg.flag] and not getgenv().PH_Repairing
			end
			local function goTo(pos, label)
				local hrp = H.Live()
				if not hrp then return end
				local d = (hrp.Position - pos).Magnitude
				H.FlyFloat(true)
				cfg.status((label or (walk and "Berjalan" or "Teleport")) .. " (" .. math.floor(d) .. " studs)...")
				return H.TeleportTo(pos, function() return not active() or not H.Live() end, walk)
			end
			while H.Run() do
				task.wait(0.15)
				if getgenv().PH_Repairing and getgenv()[cfg.flag] then
					cfg.status("Menunggu perbaikan alat...")
					task.wait(0.5)
					continue
				end
				if not getgenv()[cfg.flag] then
					if cfg.name == "Batu" then H.RestoreCam() end
					if savedPos then
						local sp = savedPos
						savedPos = nil
						local hrp = H.Live()
						if hrp and not H.AnyActive() and (hrp.Position - sp).Magnitude > 4 then
							H.Returning = true
							if walk then H.JamurReturning = true end
							H.FlyFloat(true)
							cfg.status("Kembali ke titik awal...")
							H.TeleportTo(sp, function() return not H.Run() or H.AnyActive() or not H.Live() end, walk)
							H.JamurReturning = false
							H.Returning = false
							if not H.AnyActive() then H.FlyFloat(false) end
							cfg.status("Status: Berhenti")
						end
					end
					atHome = false
					if not H.AnyActive() and not H.Returning then H.FlyFloat(false) end
					task.wait(0.5)
					continue
				end
				local hrp, hum = H.Live()
				if not hrp then task.wait(1) continue end
				if not savedPos then savedPos = hrp.Position end
				if cfg.toolCategory and not H.EquipBest(cfg.toolCategory) then
					cfg.status("Alat tidak ditemukan di tas!")
					task.wait(2)
					continue
				end
				if cfg.name == "Batu" and getgenv().BatuIronBase == nil then getgenv().BatuIronBase = H.IronCount() end
				cfg.status("Mencari " .. cfg.name .. "...")
				local nodes = cfg.fetch(cool)
				if #nodes == 0 then
					if not atHome and savedPos then
						if (hrp.Position - savedPos).Magnitude > 4 then
							goTo(savedPos, "Kembali ke titik awal")
							local h = H.Live()
							atHome = (h and (h.Position - savedPos).Magnitude <= 6) or false
						else
							atHome = true
						end
					end
					if active() then cfg.status("Semua " .. cfg.name:lower() .. " habis! Menunggu respawn...") end
					H.FlyFloat(false)
					task.wait(2.5)
					continue
				end
				atHome = false
				local node = nodes[1]
				local targetPos = (cfg.toolCategory == "Batu") and node.pos or (node.pos + Vector3.new(0, 1.6, 0))
				local reached = goTo(targetPos)
				hrp, hum = H.Live()
				if not active() or not hrp then continue end
				if reached == false and walk then
					cfg.status("Tidak terjangkau, lewati...")
					cool[node.item] = tick() + 9
					continue
				end
				if cfg.toolCategory == "Batu" then
					H.FlyFloat(false)
					H.LockCam()
					H.FaceRock(node.part)
				else
					H.FlyFloat(true)
				end
				task.wait(0.2)
				if not H.NodeOk(node) or node.item:GetAttribute("Tumbang") == true then
					cool[node.item] = tick() + 3
					continue
				end
				if cfg.toolCategory then
					H.EquipBest(cfg.toolCategory)
					task.wait(0.1)
				end
				local destroyed = false
				local t0 = tick()
				local maxWait = cfg.maxWait or 25
				local hold = node.prompt.HoldDuration or cfg.hold
				while active() and H.Live() and (tick() - t0) < maxWait do
					if node.item:GetAttribute("Tumbang") == true or not node.item.Parent or not node.prompt.Parent then
						destroyed = true
						break
					end
					if cfg.toolCategory == "Batu" then
						H.FaceRock(node.part)
						pcall(function() node.prompt.RequiresLineOfSight = false end)
						task.wait(0.05)
					end
					if node.prompt.Enabled then
						cfg.status((cfg.verb or "Mengambil") .. " " .. cfg.name .. "...")
						local okp = true
						if cfg.toolCategory == "Batu" then
							okp = H.EnsurePrompt(node.prompt)
							H.FaceRock(node.part)
						end
						if okp then
							H.Fire(node.prompt, hold)
						else
							cfg.status("Prompt batu tertutup, pakai cadangan...")
							if fireproximityprompt then pcall(fireproximityprompt, node.prompt) end
							task.wait(0.3)
						end
						task.wait(0.15)
					end
					if node.item:GetAttribute("Tumbang") == true or not node.item.Parent or not node.prompt.Parent then
						destroyed = true
						break
					end
					if cfg.waitDestroy then
						cfg.status("Menunggu " .. cfg.name:lower() .. " tumbang/hancur...")
						local w0 = tick()
						while not node.prompt.Enabled and (tick() - w0) < 2.5 do
							if node.item:GetAttribute("Tumbang") == true then destroyed = true break end
							task.wait(0.1)
						end
					else
						task.wait(0.35)
						destroyed = (not node.item.Parent) or (not node.prompt.Parent) or (not node.prompt.Enabled)
						break
					end
				end
				if destroyed then
					task.wait(0.3)
					Q[cfg.name] = (Q[cfg.name] or 0) + 1
					cfg.counter("Terkumpul: " .. Q[cfg.name] .. " " .. (LABEL[cfg.name] or cfg.name))
					if cfg.name == "Batu" and getgenv().BatuIronBase then
						local g = math.max(0, H.IronCount() - getgenv().BatuIronBase)
						UIBatu.st.Set(3, "Biji Besi: +" .. g)
					end
					cool[node.item] = tick() + (cfg.cooldown or 15)
				else
					cfg.status("Gagal interaksi, coba lagi...")
					cool[node.item] = tick() + 3
				end
				task.wait(0.2)
			end
		end)
	end

	RunFarm({flag = "KepitingFarmActive", name = "Kepiting", status = UIKep.status, counter = UIKep.counter,
		fetch = function(c) return H.FetchBahan("kepiting", c) end})
	RunFarm({flag = "DupaFarmActive", name = "Dupa", status = UIDupa.status, counter = UIDupa.counter,
		fetch = function(c) return H.FetchBahan("dupa", c) end})
	RunFarm({flag = "KemenyanFarmActive", name = "Kemenyan", status = UIKem.status, counter = UIKem.counter,
		fetch = function(c) return H.FetchBahan("kemenyan", c) end})
	RunFarm({flag = "MelatiFarmActive", name = "Melati", status = UIMelati.status, counter = UIMelati.counter,
		fetch = function(c) return H.FetchBahan("melati", c) end})
	RunFarm({flag = "JamurFarmActive", name = "Jamur", status = UIJamur.status, counter = UIJamur.counter,
		fetch = function(c) return H.FetchBahan("jamurkuburan", c) end})
	RunFarm({flag = "PohonFarmActive", name = "Pohon", verb = "Menebang", toolCategory = "Pohon",
		status = UIPohon.status, counter = UIPohon.counter, hold = 0.35, waitDestroy = true, maxWait = 25, cooldown = 25,
		fetch = function(c) return H.FetchCraft("Pohon", H.PohonSize, c) end})
	RunFarm({flag = "BatuFarmActive", name = "Batu", verb = "Menambang", toolCategory = "Batu",
		status = UIBatu.status, counter = UIBatu.counter, hold = 0.35, waitDestroy = true, maxWait = 25, cooldown = 25,
		fetch = function(c)
			if getgenv().BatuBesiMode then
				local l = H.FetchCraft("Batu", "besar", c)
				if #l == 0 then l = H.FetchCraft("Batu", "sedang", c) end
				return l
			end
			return H.FetchCraft("Batu", H.BatuSize, c)
		end})

	----------------------------------------------------------------
	-- AUTO FARM SEMUA (loop)
	----------------------------------------------------------------
	task.spawn(function()
		local CATS = {
			{category = "Kepiting", query = "kepiting"}, {category = "Dupa", query = "dupa"},
			{category = "Kemenyan", query = "kemenyan"}, {category = "Melati", query = "melati"},
			{category = "Jamur", query = "jamurkuburan"},
		}
		local cool = setmetatable({}, {__mode = "k"})
		local savedPos = nil
		local atHome = false
		local catIdx = 1
		local function active() return H.Run() and getgenv().AutoSemuaFarmActive end
		local function goTo(pos, label)
			local hrp = H.Live()
			if not hrp then return end
			local d = (hrp.Position - pos).Magnitude
			H.FlyFloat(true)
			semuaStatus((label or "Teleport") .. " (" .. math.floor(d) .. " studs)...")
			return H.TeleportTo(pos, function() return not active() or not H.Live() end)
		end
		local function goHome(pos)
			if not H.Run() or H.AnyActive() then return end
			local hrp = H.Live()
			if not hrp then return end
			local d = (hrp.Position - pos).Magnitude
			if d <= 4 then return end
			H.Returning = true
			H.FlyFloat(true)
			semuaStatus("Kembali ke titik awal (" .. math.floor(d) .. " studs)...")
			H.TeleportTo(pos, function() return not H.Run() or H.AnyActive() or not H.Live() end)
			H.Returning = false
			if not H.AnyActive() then H.FlyFloat(false) end
			semuaStatus("Status: Berhenti")
		end
		local function pickNext()
			for off = 0, #CATS - 1 do
				local idx = ((catIdx - 1 + off) % #CATS) + 1
				local c = CATS[idx]
				local nodes = H.FetchBahan(c.query, cool)
				if #nodes > 0 then
					catIdx = idx
					return c.category, nodes[1]
				end
			end
			return nil, nil
		end
		while H.Run() do
			task.wait(0.15)
			if not getgenv().AutoSemuaFarmActive then
				if savedPos then
					local sp = savedPos
					savedPos = nil
					goHome(sp)
				end
				atHome = false
				catIdx = 1
				task.wait(0.5)
				continue
			end
			local hrp = H.Live()
			if not hrp then task.wait(1) continue end
			if not savedPos then savedPos = hrp.Position end
			semuaStatus("Mencari " .. CATS[catIdx].category .. "...")
			local cat, node = pickNext()
			if not node then
				if not atHome and savedPos then
					if (hrp.Position - savedPos).Magnitude > 4 then
						goTo(savedPos, "Kembali ke titik awal")
						local h = H.Live()
						atHome = (h and (h.Position - savedPos).Magnitude <= 6) or false
					else
						atHome = true
					end
				end
				if active() then semuaStatus("Semua bahan habis! Menunggu respawn...") end
				H.FlyFloat(false)
				task.wait(2.5)
				continue
			end
			atHome = false
			goTo(node.pos + Vector3.new(0, 1.6, 0), "Teleport ke " .. cat)
			hrp = H.Live()
			if not active() or not hrp then continue end
			H.FlyFloat(true)
			task.wait(0.2)
			if not H.NodeOk(node) then
				cool[node.item] = tick() + 3
				continue
			end
			local ok = false
			local t0 = tick()
			local hold = node.prompt.HoldDuration
			while active() and H.Live() and (tick() - t0) < 10 do
				if not node.item.Parent or not node.prompt.Parent then ok = true break end
				if node.prompt.Enabled then
					semuaStatus("Mengambil " .. cat .. "...")
					H.Fire(node.prompt, hold)
					task.wait(0.15)
				end
				if not node.item.Parent or not node.prompt.Parent then ok = true break end
				task.wait(0.35)
				ok = (not node.item.Parent) or (not node.prompt.Parent) or (not node.prompt.Enabled)
				break
			end
			if ok then
				task.wait(0.3)
				Q[cat] = (Q[cat] or 0) + 1
				H.Total += 1
				if Counters[cat] then Counters[cat]("Terkumpul: " .. Q[cat] .. " " .. LABEL[cat]) end
				semuaCounter("Total Terkumpul: " .. H.Total .. " Item")
				cool[node.item] = tick() + 15
			else
				semuaStatus("Gagal interaksi, coba lagi...")
				cool[node.item] = tick() + 3
			end
			task.wait(0.2)
		end
	end)

	----------------------------------------------------------------
	-- GAGAK (jalan kaki / terbang dengan Owl Staff)
	----------------------------------------------------------------
	task.spawn(function()
		local cool = setmetatable({}, {__mode = "k"})
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local ow = {conn = nil, held = false, prevCam = nil, aim = nil, used = false, blockedUntil = 0}
		local function active() return H.Run() and getgenv().GagakFarmActive end
		local function say(t) UIGagak.status(t) end
		local function groundPos(p)
			rp.FilterDescendantsInstances = {LocalPlayer.Character}
			local r = workspace:Raycast(p, Vector3.new(0, -150, 0), rp)
			return r and r.Position or Vector3.new(p.X, p.Y - 7, p.Z)
		end
		local function isNear(node)
			local hrp = H.Live()
			if not hrp then return false end
			local reach = (node.prompt.MaxActivationDistance or 6) - 1.5
			return (hrp.Position - node.pos).Magnitude <= math.max(2, reach)
		end
		local function walkTo(goal, node)
			local hrp, hum = H.Live()
			if not hrp then return false end
			if isNear(node) then return true end
			local wps
			local path = PFS:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
			local ok = pcall(function() path:ComputeAsync(hrp.Position, goal) end)
			if ok and path.Status == Enum.PathStatus.Success then
				wps = path:GetWaypoints()
			else
				wps = {{Position = goal, Action = Enum.PathWaypointAction.Walk}}
			end
			for _, wp in ipairs(wps) do
				if not active() then return false end
				local h, hm = H.Live()
				if not h then return false end
				if wp.Action == Enum.PathWaypointAction.Jump then hm.Jump = true end
				hm:MoveTo(wp.Position)
				local t0, lastPos, lastMove = tick(), h.Position, tick()
				while active() do
					task.wait(0.1)
					local h2, hm2 = H.Live()
					if not h2 then return false end
					if isNear(node) then
						hm2:MoveTo(h2.Position)
						return true
					end
					if H.PetirDanger then
						say("Petir! Menunggu aman...")
						t0 = t0 + 0.1
						lastMove = tick()
					else
						local flat = Vector3.new(h2.Position.X - wp.Position.X, 0, h2.Position.Z - wp.Position.Z).Magnitude
						if flat < 3 then break end
						if (h2.Position - lastPos).Magnitude > 1 then
							lastPos, lastMove = h2.Position, tick()
						elseif tick() - lastMove > 1.5 then
							hm2.Jump = true
							hm2:MoveTo(wp.Position)
							if tick() - lastMove > 6 then return false end
						end
						if tick() - t0 > 12 then break end
					end
				end
			end
			return isNear(node)
		end
		local function hold(on)
			if ow.held == on then return end
			ow.held = on
			pcall(function() VIM:SendKeyEvent(on, Enum.KeyCode.W, false, game) end)
		end
		local function getStaff()
			local ch = LocalPlayer.Character
			local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
			return (ch and ch:FindFirstChild("OwlStaff")) or (bp and bp:FindFirstChild("OwlStaff"))
		end
		local function releaseAim()
			hold(false)
			if ow.conn then
				ow.conn:Disconnect()
				ow.conn = nil
			end
			ow.aim = nil
			if ow.prevCam then
				local cam = workspace.CurrentCamera
				cam.CameraType = (ow.prevCam == Enum.CameraType.Scriptable) and Enum.CameraType.Custom or ow.prevCam
				ow.prevCam = nil
			end
		end
		local function startAim()
			if ow.conn then return end
			local cam = workspace.CurrentCamera
			ow.prevCam = cam.CameraType
			cam.CameraType = Enum.CameraType.Scriptable
			ow.conn = RunService.RenderStepped:Connect(function()
				if not H.Run() then releaseAim() return end
				local hrp = H.Char()
				local aim = ow.aim
				if not hrp or not aim then return end
				local dir = aim - hrp.Position
				if dir.Magnitude < 0.1 then return end
				dir = dir.Unit
				if math.abs(dir.Y) > 0.999 then dir = (dir + Vector3.new(0.01, 0, 0)).Unit end
				local camPos = hrp.Position - dir * 12
				cam.CFrame = CFrame.lookAt(camPos, camPos + dir)
			end)
		end
		local function ensureOwl()
			local ch = LocalPlayer.Character
			local _, hum = H.Live()
			if not hum then return false end
			if LocalPlayer:GetAttribute("IsOwl") and ch:FindFirstChild("OwlStaff") then
				ow.used = true
				return true
			end
			local staff = getStaff()
			if not staff then return false end
			if staff.Parent ~= ch then
				hum:EquipTool(staff)
				task.wait(0.35)
			end
			if not LocalPlayer:GetAttribute("IsOwl") then
				staff:Activate()
				local t0 = tick()
				while tick() - t0 < 3 and not LocalPlayer:GetAttribute("IsOwl") do task.wait(0.1) end
			end
			local isOwl = LocalPlayer:GetAttribute("IsOwl") == true
			if isOwl then ow.used = true end
			return isOwl
		end
		local function stopOwl()
			releaseAim()
			if LocalPlayer:GetAttribute("IsOwl") then
				local _, hum = H.Live()
				if hum then hum:UnequipTools() end
				local t0 = tick()
				while tick() - t0 < 3 and LocalPlayer:GetAttribute("IsOwl") do task.wait(0.1) end
				task.wait(0.3)
			end
			ow.used = false
		end
		local function flyTo(node)
			if not ensureOwl() then return false end
			startAim()
			ow.aim = node.pos
			hold(true)
			local t0 = tick()
			local best, lastProgress = math.huge, tick()
			local stuckN = 0
			while active() and getgenv().GagakOwlMode do
				task.wait(0.05)
				local h = H.Live()
				if not h then return false end
				if not LocalPlayer:GetAttribute("IsOwl") then
					hold(false)
					if not ensureOwl() then return false end
					ow.aim = node.pos
					hold(true)
				end
				if H.PetirDanger then
					say("Petir! Menunggu aman...")
					hold(false)
					t0 = t0 + 0.05
					lastProgress = tick()
				else
					hold(true)
					local d = (h.Position - node.pos).Magnitude
					if d <= 4.5 then return true end
					if d < best - 1 then best, lastProgress = d, tick() end
					if tick() - lastProgress > 1.5 then
						stuckN += 1
						if stuckN > 3 then return false end
						say("Terhalang, naik dulu...")
						local flat = Vector3.new(node.pos.X - h.Position.X, 0, node.pos.Z - h.Position.Z)
						flat = (flat.Magnitude > 0.1) and (flat.Unit * 15) or Vector3.zero
						ow.aim = h.Position + Vector3.new(0, 40, 0) + flat
						task.wait(0.9)
						ow.aim = node.pos
						best, lastProgress = math.huge, tick()
					end
					if tick() - t0 > 30 then return false end
				end
			end
			return false
		end

		while H.Run() do
			task.wait(0.15)
			if not getgenv().GagakFarmActive then
				if ow.used or ow.conn then stopOwl() end
				task.wait(0.5)
				continue
			end
			local hrp, hum = H.Live()
			if not hrp then
				if ow.conn then releaseAim() end
				task.wait(1)
				continue
			end
			if hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) < 0.4 then
				H.Off("GagakFarmActive")
				stopOwl()
				say("Berhenti otomatis: HP rendah (" .. math.floor(hum.Health) .. ")")
				continue
			end
			if H.PetirDanger then
				hold(false)
				say("Petir! Menunggu aman...")
				task.wait(0.5)
				continue
			end
			say("Mencari Gagak...")
			local nodes = H.FetchBahan("gagak", cool)
			if #nodes == 0 then
				if ow.used or ow.conn then stopOwl() end
				say("Semua gagak habis! Menunggu respawn...")
				task.wait(2.5)
				continue
			end
			local node = nodes[1]
			local useOwl = getgenv().GagakOwlMode and tick() >= ow.blockedUntil
			if useOwl and not getStaff() then
				ow.blockedUntil = tick() + 30
				say("Owl Staff tidak ada di tas, jalan kaki 30 dtk")
				useOwl = false
			end
			if useOwl and not ensureOwl() then
				ow.blockedUntil = tick() + 30
				say("Owl Staff gagal aktif, jalan kaki 30 dtk")
				useOwl = false
			end
			if not useOwl and (ow.used or ow.conn) then stopOwl() end
			local reached
			if useOwl then
				say("Terbang ke Gagak (" .. math.floor(node.dist) .. " studs)...")
				reached = flyTo(node)
			else
				say("Jalan ke Gagak (" .. math.floor(node.dist) .. " studs)...")
				reached = walkTo(groundPos(node.pos) + Vector3.new(0, 3, 0), node)
			end
			if not active() then continue end
			if not reached or not H.NodeOk(node) then
				if useOwl then hold(false) end
				cool[node.item] = tick() + 3
				say("Gagal menjangkau, coba target lain...")
				continue
			end
			say("Mengambil Gagak...")
			H.Fire(node.prompt, node.prompt.HoldDuration or 0.5)
			task.wait(0.35)
			local done = (not node.item.Parent) or (not node.prompt.Parent) or (not node.prompt.Enabled)
			if done then
				Q.Gagak += 1
				H.Total += 1
				UIGagak.counter("Terkumpul: " .. Q.Gagak .. " Gagak")
				semuaCounter("Total Terkumpul: " .. H.Total .. " Item")
				cool[node.item] = tick() + 15
			else
				say("Gagal interaksi, coba lagi...")
				cool[node.item] = tick() + 3
			end
			task.wait(0.2)
		end
	end)
end

------------------------------------------------------------------
-- TAB PETERNAKAN (ayam, sapi, babi)
------------------------------------------------------------------
do
	local RS = H.RS
	local function Req(name)
		local ok, m = pcall(function() return require(RS:WaitForChild(name, 3)) end)
		return (ok and type(m) == "table") and m or nil
	end
	local AyamC, SapiC, BabiC = Req("AyamConfig"), Req("SapiConfig"), Req("BabiConfig")
	local FEED_AYAM = (AyamC and AyamC.Pakan and AyamC.Pakan.item) or "Jagung"
	local FEED_SAPI = (SapiC and SapiC.Pakan and SapiC.Pakan.item) or "Jagung"
	local PALUNG_CAP = (BabiC and BabiC.Palung and BabiC.Palung.Kapasitas) or 10
	local GOSOK_TIME = (BabiC and BabiC.Gosok and BabiC.Gosok.Lama) or 3
	local MIN_RAWATAN = 100
	local PAKAN = {}
	if BabiC and type(BabiC.Pakan) == "table" then
		for _, v in pairs(BabiC.Pakan) do
			if type(v) == "table" and v.itemId then table.insert(PAKAN, v) end
		end
		table.sort(PAKAN, function(a, b) return (a.mutu or 0) > (b.mutu or 0) end)
	end
	if #PAKAN == 0 then
		PAKAN = {
			{itemId = "SateKepiting", nama = "Sate Kepiting"}, {itemId = "PisangRajaRebus", nama = "Pisang Raja Rebus"},
			{itemId = "TumisKamboja", nama = "Tumis Kamboja"}, {itemId = "SateGagak", nama = "Sate Gagak"},
			{itemId = "JamurRebus", nama = "Jamur Rebus"},
		}
	end
	local KAND = {ayam = "KandangAyam", sapi = "KandangSapi", babi = "KandangBabi"}
	local LBL = {ayam = "Ayam", sapi = "Sapi", babi = "Babi"}
	local cool = setmetatable({}, {__mode = "k"})
	local A = {ayam = {}, sapi = {}, babi = {}}
	local noChange = setmetatable({}, {__mode = "k"})

	-- UI
	local function AnimalUI(key, title, flag)
		FlagToggle(TernakPage, title, nil, flag, function(v)
			local st = A[key].st
			if not st then return end
			if v then
				st.Set(1, "Status: Memantau kandang...")
			else
				local stillOn = false
				if key == "babi" then
					stillOn = getgenv().AutoBabiActive or getgenv().AutoGosokBabiActive or getgenv().AutoKlaimNgepetActive
				elseif key == "ayam" then
					stillOn = getgenv().AutoAyamActive or getgenv().AutoTetasActive or getgenv().AutoAnakAyamActive
				end
				if not stillOn then st.Set(1, "Status: Berhenti") end
			end
		end, true)
	end

	UI.Section(TernakPage, "KANDANG AYAM  |  Pakan + Telur + Tetas + Anak Ayam")
	AnimalUI("ayam", "Auto Ayam (Isi Pakan + Ambil Telur)", "AutoAyamActive")
	AnimalUI("ayam", "Auto Tetaskan Telur", "AutoTetasActive")
	AnimalUI("ayam", "Auto Ambil Anak Ayam", "AutoAnakAyamActive")
	A.ayam.st = UI.Status(TernakPage, 4)
	A.ayam.st.Set(1, "Status: Siap (OFF)")
	A.ayam.st.Set(2, "Kandang: Memindai...")
	A.ayam.st.Set(3, "Hasil Ayam: 0 Kali")
	A.ayam.st.Set(4, "Tetas: 0 Telur | Anak Ayam Diambil: 0 Ekor")

	UI.Section(TernakPage, "KANDANG SAPI  |  Isi Pakan + Susu")
	AnimalUI("sapi", "Auto Sapi", "AutoSapiActive")
	A.sapi.st = UI.Status(TernakPage, 3)
	A.sapi.st.Set(1, "Status: Siap (OFF)")
	A.sapi.st.Set(2, "Kandang: Memindai...")
	A.sapi.st.Set(3, "Hasil Sapi: 0 Kali")

	UI.Section(TernakPage, "KANDANG BABI  |  Palung + Gosok + Klaim")
	AnimalUI("babi", "Auto Babi (Isi Palung)", "AutoBabiActive")
	AnimalUI("babi", "Gosok Induk", "AutoGosokBabiActive")
	AnimalUI("babi", "Klaim Babi Ngepet", "AutoKlaimNgepetActive")
	getgenv().KlaimMinRawatan = getgenv().KlaimMinRawatan or 0
	UI.Input(TernakPage, "Min Rawatan Klaim (%)", "0 = klaim semua babi dewasa", tostring(getgenv().KlaimMinRawatan), "0", function(t)
		getgenv().KlaimMinRawatan = math.clamp(tonumber(t) or 0, 0, 100)
	end)
	local CheckPig = function() end
	local pigDiag
	UI.Button(TernakPage, "Cek Babi Terdekat", "Tampilkan status dewasa, rawatan, bersih.", "CEK", function() CheckPig() end, C.accent)
	pigDiag = UI.Status(TernakPage, 1)
	pigDiag.Set(1, "Cek Babi: belum dipakai")
	A.babi.st = UI.Status(TernakPage, 4)
	A.babi.st.Set(1, "Status: Siap (OFF)")
	A.babi.st.Set(2, "Kandang: Memindai...")
	A.babi.st.Set(3, "Hasil Babi: 0 Kali")
	A.babi.st.Set(4, "Klaim Ngepet: 0 Ekor")

	UI.Section(TernakPage, "PAKAN BABI (tap untuk pilih)")
	local pakanList = UI.List(TernakPage, 140)

	local function Say(jenis, text)
		local a = A[jenis]
		if a and a.st then a.st.Set(1, text) end
	end

	-- barang & tool
	local function FindToolBy(pred)
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		for _, holder in ipairs({LocalPlayer.Character, bp}) do
			if holder then
				for _, t in ipairs(holder:GetChildren()) do
					if t:IsA("Tool") and pred(t) then return t end
				end
			end
		end
		return nil
	end
	local function FindItem(id)
		return FindToolBy(function(t) return t:GetAttribute("ItemId") == id and not t:GetAttribute("IsSeed") end)
	end
	local function StockOf(id)
		local t = FindItem(id)
		if not t then return 0 end
		return tonumber(t.Name:match("[xX](%d+)%s*$")) or 1
	end
	local function EquipItem(tool)
		local _, hum = H.Live()
		if not hum or not tool or not tool.Parent then return false end
		if tool.Parent == LocalPlayer.Character then return true end
		hum:UnequipTools()
		task.wait(0.1)
		hum:EquipTool(tool)
		task.wait(0.35)
		return tool.Parent == LocalPlayer.Character
	end
	-- apakah sedang memegang pengosok (teks prompt babi baru bisa dipercaya saat memegangnya)
	local function HoldingBrush()
		local ch = LocalPlayer.Character
		local t = ch and ch:FindFirstChildOfClass("Tool")
		if not t then return false end
		local n = t.Name:lower()
		return n:find("pengosok") ~= nil or n:find("penggosok") ~= nil
	end
	local function PromptPos(p)
		local par = p.Parent
		if not par then return nil end
		if par:IsA("Attachment") then return par.WorldPosition end
		if par:IsA("BasePart") then return par.Position end
		if par:IsA("Model") then return par:GetPivot().Position end
		local bp = par:FindFirstChildWhichIsA("BasePart", true)
		return bp and bp.Position or nil
	end
	local function ReadFraction(p) -- "3/10" dari label di dekat prompt
		local par = p.Parent
		local lbl = par and par:FindFirstChild("TextLabel", true)
		if lbl and lbl:IsA("TextLabel") then
			local a, b = lbl.Text:match("(%d+)%s*/%s*(%d+)")
			if a and b then return tonumber(a), tonumber(b) end
		end
		return nil, nil
	end
	local function ObjectCount(p)
		return tonumber(p.ObjectText:match("[xX](%d+)%)"))
	end
	local function PalungCap(p)
		local lv = 1
		local m = p:FindFirstAncestorWhichIsA("Model")
		while m and m.Parent ~= workspace do m = m.Parent end
		local info = m and m:FindFirstChild("Info")
		local line = info and info:FindFirstChild("Baris1", true)
		if line and line:IsA("TextLabel") then lv = tonumber(line.Text:match("Lv%s*(%d+)")) or 1 end
		if BabiC and type(BabiC.KapasitasPalung) == "function" then
			local ok, cap = pcall(BabiC.KapasitasPalung, lv)
			if ok and tonumber(cap) then return tonumber(cap) end
		end
		return PALUNG_CAP
	end

	-- pesan server tentang babi (sabar / penuh / pakan lain)
	local lastMsg, lastMsgT = nil, 0
	for _, d in ipairs(RS:GetDescendants()) do
		if d:IsA("RemoteEvent") then
			pcall(function()
				H.Conn(d.OnClientEvent:Connect(function(p)
					if not H.Run() then return end
					if type(p) == "table" and p.kind == "babi" and type(p.text) == "string" then
						lastMsg, lastMsgT = p.text:lower(), tick()
					end
				end))
			end)
		end
	end

	local function BabiModel(inst)
		local x = inst
		while x and x ~= workspace do
			if x.Name:find("^Babi_") then return x end
			x = x.Parent
		end
		return nil
	end
	-- baca status babi dari semua label di modelnya (dewasa, rawatan, berat, bersih)
	local MIN_KG = 30
	pcall(function()
		local c = H.GC and H.GC.Panggang
		if c and tonumber(c.BeratMin) then MIN_KG = tonumber(c.BeratMin) end
	end)
	local function PigModel(p)
		local m = BabiModel(p)
		if m then return m end
		m = p:FindFirstAncestorWhichIsA("Model")
		while m and m.Parent and m.Parent ~= workspace do m = m.Parent end
		return m
	end
	local function PigInfo(p)
		local info = {texts = "", pct = nil, adult = nil, kg = nil, clean = nil, name = "Babi Ngepet"}
		local m = PigModel(p)
		if not m then return info end
		local parts = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text ~= "" then
				table.insert(parts, d.Text)
				if d.Name == "NamaLabel" then info.name = d.Text end
			end
		end
		info.texts = table.concat(parts, " | ")
		local low = info.texts:lower()
		info.pct = tonumber(low:match("rawatan%s*(%d+)%s*%%"))
		local kg = low:match("(%d+[%.,]?%d*)%s*kg")
		if kg then info.kg = tonumber((kg:gsub(",", "."))) end
		if low:find("belum dewasa") or low:find("anak babi") or low:find("bayi") or low:find("balita") then
			info.adult = false
		elseif low:find("dewasa") then
			info.adult = true
		elseif info.kg then
			info.adult = info.kg >= MIN_KG
		end
		for _, at in ipairs({"Dewasa", "IsDewasa", "Adult", "IsAdult"}) do
			local v = m:GetAttribute(at)
			if type(v) == "boolean" then info.adult = v end
		end
		if low:find("kotor") then info.clean = false
		elseif low:find("bersih") then info.clean = true end
		if m:GetAttribute("Kotor") == true then info.clean = false end
		if m:GetAttribute("Bersih") == true then info.clean = true end
		if info.pct and info.pct >= 100 then info.clean = true end
		return info
	end

	-- tampilan stok pakan babi
	local PAKAN_OPTS = {
		{key = "auto", short = "AUTO (TERBAIK)"}, {key = "SateKepiting", short = "KEPITING"},
		{key = "TumisKamboja", short = "KAMBOJA"}, {key = "PisangRajaRebus", short = "PISANG"},
		{key = "SateGagak", short = "GAGAK"}, {key = "JamurRebus", short = "JAMUR"},
	}
	local stock = {}
	local lastSig = ""
	local function RefreshPakan(force)
		local sig = tostring(getgenv().BabiPakanPilihan)
		for _, o in ipairs(PAKAN_OPTS) do
			if o.key ~= "auto" then
				stock[o.key] = StockOf(o.key)
				sig = sig .. o.key .. stock[o.key] .. ";"
			end
		end
		if sig == lastSig and not force then return end
		lastSig = sig
		pakanList.Clear()
		for _, o in ipairs(PAKAN_OPTS) do
			local label = o.short
			local empty = false
			if o.key ~= "auto" then
				local n = stock[o.key] or 0
				label = label .. "   " .. (n > 0 and ("x" .. n) or "habis")
				empty = n <= 0
			end
			local sel = (getgenv().BabiPakanPilihan or "auto") == o.key
			pakanList.Add(label, sel, function()
				if o.key ~= "auto" and (stock[o.key] or 0) <= 0 then
					Say("babi", "Pakan " .. o.short .. " tidak tersedia di tas")
					return
				end
				getgenv().BabiPakanPilihan = o.key
				Say("babi", "Pakan dipilih: " .. o.short)
				RefreshPakan(true)
			end, false, 24, empty)
		end
		pakanList.Done()
	end
	RefreshPakan(true)
	task.spawn(function()
		while H.Run() do
			task.wait(2)
			pcall(RefreshPakan, false)
		end
	end)

	local function PickItem(e)
		if e.role == "gosok" then
			local t = FindToolBy(function(x)
				local n = x.Name:lower()
				return n:find("pengosok") ~= nil or n:find("penggosok") ~= nil
			end)
			return t, "Pengosok"
		end
		if e.role == "pakan" then
			if e.jenis == "ayam" then return FindItem(FEED_AYAM), FEED_AYAM end
			if e.jenis == "sapi" then return FindItem(FEED_SAPI), FEED_SAPI end
			local pick = getgenv().BabiPakanPilihan or "auto"
			if pick ~= "auto" then
				local nm = pick
				for _, p in ipairs(PAKAN) do
					if p.itemId == pick then nm = p.nama or pick end
				end
				return FindItem(pick), nm
			end
			local want = e.palungNama and e.palungNama:lower()
			if want then
				for _, p in ipairs(PAKAN) do
					if (p.nama or ""):lower() == want then
						local t = FindItem(p.itemId)
						if t then return t, p.nama end
					end
				end
			end
			for _, p in ipairs(PAKAN) do
				local t = FindItem(p.itemId)
				if t then return t, p.nama end
			end
			return nil, "pakan babi"
		end
		return nil, nil
	end

	local function Kandangs(j)
		local out = {}
		local uid = tostring(LocalPlayer.UserId)
		local plot = H.Plot()
		local nm = KAND[j]
		for _, c in ipairs(workspace:GetChildren()) do
			if c.Name:find(nm) and (c.Name:find(uid) or (plot and c.Parent == plot)) then table.insert(out, c) end
		end
		if plot then
			for _, c in ipairs(plot:GetChildren()) do
				if c.Name:find(nm) and not table.find(out, c) then table.insert(out, c) end
			end
		end
		return out
	end

	local function Collect(jenis, flagParam)
		local out = {}
		local ks = Kandangs(jenis)
		A[jenis].st.Set(2, (#ks > 0) and ("Kandang terdeteksi: " .. #ks .. " bangunan") or "Kandang belum ditemukan di plot")
		for _, k in ipairs(ks) do
			for _, p in ipairs(k:GetDescendants()) do
				if p:IsA("ProximityPrompt") and p.Enabled and (not cool[p] or tick() > cool[p]) then
					local action, obj, nm = p.ActionText:lower(), p.ObjectText:lower(), p.Name:lower()
					local role, flag, palungNama, babiNama, persen
					if jenis == "babi" then
						if action:find("bawa") then
							-- prompt "Babi / Bawa" = babi sudah bersih (dipakai untuk klaim ngepet)
							if getgenv().AutoKlaimNgepetActive then
								local pi = PigInfo(p)
								local minPct = tonumber(getgenv().KlaimMinRawatan) or 0
								local ok = false
								if pi.adult == true then
									ok = (pi.pct == nil) or pi.pct >= minPct
								elseif pi.adult == nil then
									-- status dewasa tidak terbaca: pakai aturan lama (rawatan 100%)
									ok = pi.pct ~= nil and pi.pct >= math.max(minPct, MIN_RAWATAN)
								end
								if ok then
									role, flag = "klaim", "AutoKlaimNgepetActive"
									babiNama, persen = pi.name, pi.pct
								end
							end
						else
							local isTake = obj:find("bandar") or action:find("ambil")
							if not isTake then
								if action:find("gosok") or action:find("cuci") then
									-- prompt "Kotor / Gosok" = babi kotor. Bersih -> dilewati (tidak teleport/gosok)
									if getgenv().AutoGosokBabiActive and p:FindFirstAncestor("modelinduk") then
										local pi = PigInfo(p)
										if pi.clean == true or obj:find("bersih") then
											cool[p] = tick() + 30
										elseif HoldingBrush() and not obj:find("kotor") then
											-- sedang memegang pengosok, teksnya bisa dipercaya: bukan "Kotor" = bersih
											cool[p] = tick() + 30
										else
											role, flag = "gosok", "AutoGosokBabiActive"
										end
									end
								elseif obj:find("palung") or obj:find("tempat makan") or action:find("palung") or action:find("tuang") then
									if getgenv().AutoBabiActive then
										role, flag = "pakan", "AutoBabiActive"
										palungNama = p.ObjectText:match("%((.-)%s*[xX]%d+%)")
										local cur = ObjectCount(p)
										if cur and cur >= PalungCap(p) then
											cool[p] = tick() + 15
											role = nil
										end
									end
								end
							end
						end
					elseif jenis == "ayam" and action:find("tetas") then
						-- prompt "Sarang Tetas / Tetaskan"
						if getgenv().AutoTetasActive then role, flag = "tetas", "AutoTetasActive" end
					elseif jenis == "ayam" and action:find("anak") and action:find("ambil") then
						-- prompt "Anak Ayam ... / Ambil Anak Ayam"
						if getgenv().AutoAnakAyamActive then role, flag = "anak", "AutoAnakAyamActive" end
					else
						local isTake = action:find("ambil ayam") or action:find("ambil sapi")
						if not isTake and flagParam and getgenv()[flagParam] then
							if nm == "pakanprompt" or action:find("beri makan") then
								role = "pakan"
								local cur, cap = ReadFraction(p)
								if cur and cap and cur >= cap then
									cool[p] = tick() + 10
									role = nil
								end
							elseif nm == "ambilprompt" or action:find("ambil semua") then
								role = "panen"
							end
						end
						flag = flagParam
					end
					if role then
						local pos = PromptPos(p)
						if pos then
							table.insert(out, {
								prompt = p, pos = pos, role = role, jenis = jenis, flag = flag, palungNama = palungNama,
								babiNama = babiNama, persen = persen, text = p.ActionText .. " " .. p.ObjectText,
								actionText = p.ActionText, hold = p.HoldDuration or 0.4,
							})
						end
					end
				end
			end
		end
		local order = {anak = 0.5, panen = 1, tetas = 1.5, pakan = 2, klaim = 3, gosok = 4}
		table.sort(out, function(a, b)
			if a.role ~= b.role then return order[a.role] < order[b.role] end
			return a.text < b.text
		end)
		return out
	end

	CheckPig = function()
		local hrp = H.Live()
		local best, bd
		for _, k in ipairs(Kandangs("babi")) do
			for _, d in ipairs(k:GetDescendants()) do
				if d:IsA("ProximityPrompt") then
					local pos = PromptPos(d)
					if pos and hrp then
						local dist = (hrp.Position - pos).Magnitude
						if not bd or dist < bd then best, bd = d, dist end
					end
				end
			end
		end
		if not best then
			pigDiag.Set(1, "Cek Babi: tidak ada babi / prompt ditemukan")
			return
		end
		local pi = PigInfo(best)
		pigDiag.Set(1, string.format("Prompt: %s %s\nDewasa: %s | Rawatan: %s | Berat: %s | Bersih: %s\nTeks: %s",
			best.ActionText, best.ObjectText, tostring(pi.adult), tostring(pi.pct), tostring(pi.kg), tostring(pi.clean), pi.texts:sub(1, 220)))
	end

	local function Process(e)
		local ui = A[e.jenis]
		local flagName = e.flag
		local function stop() return not H.Run() or not getgenv()[flagName] or not H.Live() end
		if stop() then return false end
		local p = e.prompt
		if not p.Parent or not p.Enabled then return true end
		local item, itemName
		if e.role == "pakan" or e.role == "gosok" then
			item, itemName = PickItem(e)
			if not item then
				Say(e.jenis, "Tidak ada " .. tostring(itemName) .. " di tas")
				cool[p] = tick() + 20
				return true
			end
		end
		local pos = PromptPos(p) or e.pos
		local hrp = H.Live()
		local far = (not hrp) or (hrp.Position - pos).Magnitude > 8
		Say(e.jenis, "Menuju " .. e.text .. "...")
		H.FlyFloat(true)
		H.TeleportTo(pos + Vector3.new(0, 3, 0), stop)
		if stop() then return false end
		if far then task.wait(0.5) end
		if item then
			Say(e.jenis, "Pegang " .. tostring(itemName) .. "...")
			if not EquipItem(item) then
				cool[p] = tick() + 10
				return true
			end
			task.wait(0.2)
			if not p.Parent or not p.Enabled then return true end
		end
		local label = LBL[e.jenis]
		local function addCount(n)
			Q[label] += n
			ui.st.Set(3, "Hasil " .. label .. ": " .. Q[label] .. " Kali")
		end

		if e.role == "pakan" then
			local fails, fills, full = 0, 0, false
			local function stack()
				return (item and item.Parent) and (tonumber(item.Name:match("[xX](%d+)%s*$")) or 1) or 0
			end
			if e.jenis == "babi" then
				local cap = PalungCap(p)
				local sabar, otherFeed = 0, false
				for _ = 1, cap + 8 do
					if stop() then return false end
					if not p.Parent or not p.Enabled then break end
					local cur = ObjectCount(p) or 0
					if cur >= cap then full = true break end
					if not item or not item.Parent then
						item, itemName = PickItem(e)
						if not item then
							Say(e.jenis, "Pakan " .. tostring(itemName) .. " habis")
							break
						end
					end
					if not EquipItem(item) then break end
					Say(e.jenis, "Mengisi palung " .. tostring(itemName) .. " (" .. cur .. "/" .. cap .. ")")
					local before = stack()
					local t0 = tick()
					H.Fire(p, e.hold)
					local advanced, msg = false, nil
					while tick() - t0 < 2.0 do
						task.wait(0.15)
						local now = ObjectCount(p) or 0
						if now > cur or stack() < before then advanced = true break end
						if lastMsgT >= t0 then msg = lastMsg break end
					end
					if advanced then
						fills += 1
						fails, sabar = 0, 0
						task.wait(1.0)
					elseif msg and msg:find("sabar") then
						sabar += 1
						if sabar >= 5 then break end
						task.wait(1.3)
					elseif msg and msg:find("penuh") then
						full = true
						break
					elseif msg and (msg:find("pakan lain") or msg:find("beda")) then
						otherFeed = true
						break
					else
						fails += 1
						if fails >= 3 then break end
						task.wait(0.8)
					end
				end
				if otherFeed then
					Say(e.jenis, "Palung berisi pakan lain - tunggu habis / samakan pakan")
					cool[p] = tick() + 30
					if fills > 0 then addCount(fills) end
					task.wait(0.2)
					return true
				end
			else
				for _ = 1, 5 do
					if stop() then return false end
					if not p.Parent or not p.Enabled then break end
					local cur, cap = ReadFraction(p)
					if cur and cap and cur >= cap then full = true break end
					if not item or not item.Parent then
						item, itemName = PickItem(e)
						if not item then
							Say(e.jenis, "Pakan " .. tostring(itemName) .. " habis")
							break
						end
					end
					if not EquipItem(item) then break end
					Say(e.jenis, "Mengisi pakan " .. tostring(itemName) .. " (" .. tostring(cur or "?") .. "/" .. tostring(cap or "?") .. ")")
					H.Fire(p, e.hold)
					task.wait(0.6)
					fills += 1
					local after = (ReadFraction(p))
					if cur and after and after <= cur then
						fails += 1
						if fails >= 2 then break end
					else
						fails = 0
					end
				end
			end
			if fills > 0 then addCount(fills) end
			if full then
				Say(e.jenis, "Pakan penuh")
				cool[p] = tick() + 20
			elseif fails >= 2 or fills == 0 then
				cool[p] = tick() + 15
			else
				cool[p] = nil
			end
		elseif e.role == "tetas" or e.role == "anak" then
			-- Tetaskan telur di sarang / ambil anak ayam yang sudah menetas
			local isTetas = (e.role == "tetas")
			local lbl = isTetas and "Tetaskan telur" or "Ambil anak ayam"
			local _, hum = H.Live()
			if hum then hum:UnequipTools() end
			task.wait(far and 0.6 or 0.2)
			local ok = false
			for n = 1, 3 do
				if stop() then return false end
				if not p.Parent or not p.Enabled then ok = true break end
				-- anak ayam bisa bergerak: dekati lagi jika sudah menjauh
				local pos2 = PromptPos(p)
				local h2 = H.Live()
				if pos2 and h2 and (h2.Position - pos2).Magnitude > 6 then
					h2.CFrame = CFrame.new(pos2 + Vector3.new(0, 3, 0))
					task.wait(0.2)
				end
				Say(e.jenis, lbl .. " (percobaan " .. n .. ")...")
				H.Fire(p, e.hold)
				local t0 = tick()
				while tick() - t0 < 1.0 do
					task.wait(0.1)
					if not p.Parent or not p.Enabled or p.ActionText ~= e.actionText then ok = true break end
				end
				if ok then break end
				task.wait(0.3)
			end
			if ok then
				if isTetas then Q.Tetas += 1 else Q.Anak += 1 end
				ui.st.Set(4, "Tetas: " .. Q.Tetas .. " Telur | Anak Ayam Diambil: " .. Q.Anak .. " Ekor")
				Say(e.jenis, "Berhasil: " .. lbl)
				cool[p] = tick() + 3
			else
				Say(e.jenis, "Gagal: " .. lbl .. " (coba lagi nanti)")
				cool[p] = tick() + 15
			end
		elseif e.role == "klaim" then
			local nm = e.babiNama or "Babi Ngepet"
			local tStart = tick()
			local _, hum = H.Live()
			if hum then hum:UnequipTools() end
			task.wait(far and 1.0 or 0.3)
			local claimed = false
			for i = 1, 3 do
				if stop() then return false end
				if not p:IsDescendantOf(workspace) then claimed = true break end
				Say(e.jenis, string.format("Klaim %s%s - percobaan %d...", nm, e.persen and (" (Rawatan " .. e.persen .. "%)") or "", i))
				H.Fire(p, e.hold)
				local t0 = tick()
				while tick() - t0 < 1.5 do
					task.wait(0.1)
					if not p:IsDescendantOf(workspace) or not p.Enabled then claimed = true break end
				end
				if claimed then break end
				task.wait(0.4)
			end
			if claimed then
				Q.Ngepet += 1
				A.babi.st.Set(4, "Klaim Ngepet: " .. Q.Ngepet .. " Ekor")
				Say(e.jenis, "Berhasil klaim " .. nm .. " (masuk tas)")
				cool[p] = tick() + 3
			else
				local why = (lastMsgT >= tStart) and lastMsg or nil
				if why and why:find("dewasa") then
					Say(e.jenis, "Ditolak: " .. nm .. " belum dewasa (dilewati 2 menit)")
					cool[p] = tick() + 120
				else
					Say(e.jenis, "Gagal klaim " .. nm .. " (coba lagi nanti)")
					cool[p] = tick() + 20
				end
			end
		elseif e.role == "panen" then
			local before = (ReadFraction(p))
			local ok = false
			for n = 1, 3 do
				if stop() then return false end
				Say(e.jenis, "Ambil " .. p.ObjectText .. " (percobaan " .. n .. ")...")
				H.Fire(p, e.hold)
				local t0 = tick()
				while tick() - t0 < 0.8 do
					task.wait(0.1)
					local now = (ReadFraction(p))
					if not p.Enabled or (before and now and now < before) then ok = true break end
				end
				if ok then break end
				task.wait(0.3)
			end
			if ok then
				Say(e.jenis, "Berhasil ambil " .. p.ObjectText)
				addCount(1)
			end
			cool[p] = tick() + (ok and 3 or 8)
		elseif e.role == "gosok" then
			-- setelah memegang pengosok, baca ulang teks prompt:
			-- "Kotor / Gosok" -> gosok; selain itu (mis. "Babi / Bawa") -> sudah bersih, jangan digosok
			task.wait(0.25)
			if not p.Parent or not p.Enabled then return true end
			local at, ot = p.ActionText:lower(), p.ObjectText:lower()
			if not (at:find("gosok") and ot:find("kotor")) then
				cool[p] = tick() + 90
				Say(e.jenis, "Babi sudah bersih (prompt: " .. p.ActionText .. "), dilewati")
				return true
			end
			local before = PigInfo(p)
			Say(e.jenis, "Menggosok induk...")
			local t0 = tick()
			H.Fire(p, e.hold)
			task.wait(GOSOK_TIME + 0.5)
			local after = PigInfo(p)
			local msg = (lastMsgT >= t0) and lastMsg or nil
			local nowClean = (not p.Parent) or (not p.Enabled)
				or not (p.ActionText:lower():find("gosok") and p.ObjectText:lower():find("kotor"))
			if msg and msg:find("bersih") then
				cool[p] = tick() + 90
				Say(e.jenis, "Babi sudah bersih, dilewati")
			elseif nowClean or after.clean == true then
				addCount(1)
				cool[p] = tick() + 60
				Say(e.jenis, "Selesai digosok (bersih)")
			elseif after.texts == before.texts then
				noChange[p] = (noChange[p] or 0) + 1
				if noChange[p] >= 2 then
					noChange[p] = 0
					cool[p] = tick() + 120
					Say(e.jenis, "Tidak ada perubahan setelah digosok, dilewati 2 menit")
				else
					cool[p] = tick() + 6
				end
			else
				noChange[p] = 0
				addCount(1)
				cool[p] = tick() + 6
			end
		else
			Say(e.jenis, "Interaksi: " .. p.ActionText .. " " .. p.ObjectText .. "...")
			H.Fire(p, e.hold)
			task.wait(0.05)
			addCount(1)
			cool[p] = tick() + 6
		end
		task.wait(e.role == "panen" and 0.05 or 0.2)
		return true
	end

	task.spawn(function()
		while H.Run() do
			task.wait(0.4)
			local act = {
				ayam = getgenv().AutoAyamActive or getgenv().AutoTetasActive or getgenv().AutoAnakAyamActive,
				sapi = getgenv().AutoSapiActive,
				babi = getgenv().AutoBabiActive or getgenv().AutoGosokBabiActive or getgenv().AutoKlaimNgepetActive,
			}
			if not (act.ayam or act.sapi or act.babi) then
				task.wait(0.5)
				continue
			end
			if not H.Live() then continue end
			local queue = {}
			local flagFor = {ayam = "AutoAyamActive", sapi = "AutoSapiActive", babi = nil}
			for _, j in ipairs({"ayam", "sapi", "babi"}) do
				if act[j] then
					local list = Collect(j, flagFor[j])
					if #list == 0 then
						if j == "babi" and not getgenv().AutoBabiActive and not getgenv().AutoGosokBabiActive then
							Say(j, "Menunggu Babi Ngepet Rawatan " .. MIN_RAWATAN .. "%...")
						elseif j == "ayam" and not getgenv().AutoAyamActive then
							Say(j, "Menunggu telur siap ditetaskan / anak ayam menetas...")
						else
							Say(j, "Menunggu: pakan penuh / belum ada hasil...")
						end
					end
					for _, e in ipairs(list) do table.insert(queue, e) end
				end
			end
			if #queue == 0 then
				task.wait(1.0)
				continue
			end
			for _, e in ipairs(queue) do
				if not H.Run() or not H.Live() then break end
				if not getgenv()[e.flag] then continue end
				if not Process(e) then break end
			end
			local _, hm = H.Live()
			if hm then hm:UnequipTools() end
			H.FlyFloat(false)
			task.wait(0.3)
		end
	end)
end

------------------------------------------------------------------
-- TAB LAPAK
------------------------------------------------------------------
do
	local RS = H.RS
	local GC = H.GC
	getgenv().LapakPilihSiang = getgenv().LapakPilihSiang or {}
	getgenv().LapakPilihMalam = getgenv().LapakPilihMalam or {}

	-- resume setelah pindah server
	local stateFile = "UbeyPH_State_" .. tostring(LocalPlayer.UserId) .. ".json"
	local resumeState = nil
	if getgenv().UbeyPHResume then
		getgenv().UbeyPHResume = nil
		resumeState = getgenv().UbeyPHSavedState
		if not resumeState and isfile and readfile then
			pcall(function()
				if isfile(stateFile) then resumeState = HttpService:JSONDecode(readfile(stateFile)) end
			end)
		end
	end
	if resumeState then
		if type(resumeState.siang) == "table" and #resumeState.siang > 0 then getgenv().LapakPilihSiang = resumeState.siang end
		if type(resumeState.malam) == "table" and #resumeState.malam > 0 then getgenv().LapakPilihMalam = resumeState.malam end
		print("[Pasar Hutan] Resume setelah ganti server. Lapak:", resumeState.lapak and true or false)
	end
	H.ResumeLapak = (resumeState and resumeState.lapak) and true or false

	local pilih = {Siang = getgenv().LapakPilihSiang, Malam = getgenv().LapakPilihMalam}
	local viewPhase = (workspace:GetAttribute("Phase") == "Malam" or Lighting:GetAttribute("Phase") == "Malam") and "Malam" or "Siang"
	local names = {}
	local sold, income = 0, 0
	local capRak, capNampan = 15, 23

	-- fase mana saja yang cocok untuk tiap item (berdasarkan hantu di GameConfig)
	local phaseCache, siangOnly = {}, nil
	local function ComputeSiangOnly()
		local G = (GC and GC.Ghost) or {}
		local favMalam = {}
		for _, t in pairs(G.Types or {}) do
			if (t.fase or "malam") == "malam" and t.favorite then favMalam[t.favorite] = true end
		end
		for _, v in ipairs(G.DuaFase or {}) do favMalam[v] = true end
		local out = {}
		for _, t in pairs(G.Types or {}) do
			if t.fase == "siang" and type(t.only) == "table" then
				for _, it in ipairs(t.only) do
					if not favMalam[it] then out[it] = true end
				end
			end
		end
		return out
	end
	local function PhaseInfo(id)
		if phaseCache[id] then return phaseCache[id] end
		siangOnly = siangOnly or ComputeSiangOnly()
		local s, m = false, false
		for _, t in pairs(((GC and GC.Ghost) or {}).Types or {}) do
			local fase = t.fase or "malam"
			local ok
			if type(t.only) == "table" and #t.only > 0 then
				ok = table.find(t.only, id) ~= nil
			elseif fase == "malam" then
				ok = (not siangOnly[id]) or (type(t.boleh) == "table" and table.find(t.boleh, id) ~= nil)
			else
				ok = true
			end
			if ok then
				if fase == "siang" then s = true else m = true end
			end
		end
		phaseCache[id] = {Siang = s, Malam = m}
		return phaseCache[id]
	end
	local function Cocok(id, phase)
		if not (GC and GC.Ghost) then return true end
		local ok, res = pcall(function() return PhaseInfo(id)[phase] == true end)
		return (ok and res) or false
	end
	local function NamaItem(id) return names[id] or H.Clean(id) end
	local function BisaDitaruh(id)
		local items = GC and GC.Items
		if not items then return true end
		local it = items[id]
		return it ~= nil and it.jual == true
	end
	local function Jenis(id)
		local items = GC and GC.Items
		local it = items and items[id]
		return it and it.jenis or "rak"
	end

	local function ScanInventory()
		local inv = {}
		local items = (GC and GC.Items) or {}
		local function scan(c)
			if not c then return end
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") then
					local clean = H.Clean(t.Name)
					local id = t:GetAttribute("ItemId") or t:GetAttribute("Id") or t:GetAttribute("Item") or clean
					local lower = clean:lower()
					local special = t:GetAttribute("IsSeed") or t:GetAttribute("PlantType") or t:GetAttribute("AlatTambang")
						or lower:find("bibit") or lower:find("kapak") or lower:find("beliung") or lower:find("penyiram")
						or lower:find("payung") or lower:find("cangkul") or lower:find("pengosok") or lower:find("lantern") or lower:find("gerobak")
					if not special then
						local cfg = items[id] or items[clean]
						if cfg and cfg.jual == true then
							local key = (items[id] and id) or (items[clean] and clean) or id
							local cnt = tonumber(t:GetAttribute("Count")) or tonumber(t.Name:match("[xX]%s*(%d+)"))
								or tonumber(t.Name:match("%((%d+)%)")) or 1
							local harga = (cfg and cfg.harga) or t:GetAttribute("Harga") or 10
							inv[key] = inv[key] or {id = key, count = 0, harga = harga}
							inv[key].count += cnt
							names[key] = (cfg and cfg.display) or clean
						end
					end
				end
			end
		end
		scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
		scan(LocalPlayer.Character)
		return inv
	end

	local function Toggle(phase, id)
		local list = pilih[phase]
		local idx = table.find(list, id)
		if idx then table.remove(list, idx) else table.insert(list, id) end
	end

	local function Rows(phase)
		local sel = pilih[phase] or {}
		local inv = ScanInventory()
		local items = (GC and GC.Items) or {}
		local rows, inSel = {}, {}
		for i = #sel, 1, -1 do
			if not BisaDitaruh(sel[i]) then table.remove(sel, i) end
		end
		for idx, id in ipairs(sel) do
			inSel[id] = true
			local cfg = items[id]
			table.insert(rows, {
				id = id, sel = idx, count = inv[id] and inv[id].count or 0,
				harga = (cfg and cfg.harga) or (inv[id] and inv[id].harga) or 0,
			})
		end
		local rest = {}
		for id, e in pairs(inv) do
			if not inSel[id] and Cocok(id, phase) then table.insert(rest, e) end
		end
		table.sort(rest, function(a, b)
			local ca = Cocok(a.id, phase) and 1 or 0
			local cb = Cocok(b.id, phase) and 1 or 0
			if ca ~= cb then return ca > cb end
			if a.harga ~= b.harga then return (a.harga or 0) > (b.harga or 0) end
			return a.id < b.id
		end)
		for _, e in ipairs(rest) do table.insert(rows, {id = e.id, sel = nil, count = e.count, harga = e.harga}) end
		return rows
	end

	-- UI
	UI.Section(LapakPage, "AUTO KELOLA LAPAK / KIOS")
	local st
	FlagToggle(LapakPage, "Auto Kelola Lapak", "Isi & rotasi etalase kios otomatis.", "AutoKelolaLapakActive", function(v)
		if st then st.Set(1, v and "Status: Memulai kelola lapak..." or "Status: Berhenti") end
	end)
	st = UI.Status(LapakPage, 3)
	st.Set(1, "Status: Siap (OFF)")
	st.Set(2, "Etalase: 0/12 Slot | Terjual: 0 Barang")
	st.Set(3, "Pendapatan Sesi: 0 Koin")

	UI.Section(LapakPage, "ITEM AUTO RESTOK")
	local refreshSeg = UI.Segment(LapakPage, "Fase", {{key = "Siang", text = "SIANG"}, {key = "Malam", text = "MALAM"}},
		function() return viewPhase end, function(k)
			viewPhase = k
			H.RefreshLapak()
		end)
	local info = UI.Status(LapakPage, 1)
	local list = UI.List(LapakPage, 160)

	local function RefreshList()
		list.Clear()
		local rows = Rows(viewPhase)
		info.Set(1, string.format("%s: %d item dipilih | nomor = urutan restok", viewPhase:upper(), #(pilih[viewPhase] or {})))
		if #rows == 0 then info.Set(1, "Tidak ada item jual di tas untuk fase " .. viewPhase:lower()) end
		for _, r in ipairs(rows) do
			local sel = r.sel ~= nil
			local text = string.format("%s%s (%s)  x%d  |  %d koin", sel and ("[" .. r.sel .. "] ") or "", NamaItem(r.id), tostring(Jenis(r.id) or "?"), r.count, r.harga)
			list.Add(text, sel, function()
				Toggle(viewPhase, r.id)
				RefreshList()
			end, false, 24, (r.count <= 0 and not sel))
		end
		list.Done()
	end
	H.RefreshLapak = RefreshList

	UI.Buttons(LapakPage, {
		{text = "PILIH SEMUA", color = C.good, cb = function()
			for _, r in ipairs(Rows(viewPhase)) do
				if not r.sel and r.count > 0 then table.insert(pilih[viewPhase], r.id) end
			end
			RefreshList()
		end},
		{text = "KOSONGKAN", color = Color3.fromRGB(180, 50, 50), cb = function()
			table.clear(pilih[viewPhase])
			RefreshList()
		end},
		{text = "REFRESH", color = C.off, cb = function() RefreshList() end},
	})
	RefreshList()

	-- ganti fase otomatis mengikuti waktu game
	task.spawn(function()
		local lastP = workspace:GetAttribute("Phase")
		while H.Run() do
			task.wait(2.5)
			local p = workspace:GetAttribute("Phase") or Lighting:GetAttribute("Phase")
			if p and p ~= lastP then
				lastP = p
				if p == "Siang" or p == "Malam" then
					viewPhase = p
					refreshSeg()
				end
			end
			if Main.Visible and LapakPage.Visible then RefreshList() end
		end
	end)

	-- income dari event penjualan
	if H.R.SaleFx then
		H.Conn(H.R.SaleFx.OnClientEvent:Connect(function(d)
			if not H.Run() or type(d) ~= "table" then return end
			sold += 1
			income += tonumber(d.coin) or 0
			st.Set(3, string.format("Pendapatan Sesi: %d Koin", income))
		end))
	end

	-- kapasitas rak / nampan dari server
	task.spawn(function()
		while H.Run() do
			if H.R.Rak then
				pcall(function()
					local r = H.R.Rak:InvokeServer("info")
					if type(r) == "table" and r.ok then
						if tonumber(r.capRak) then capRak = tonumber(r.capRak) end
						if tonumber(r.capNampan) then capNampan = tonumber(r.capNampan) end
					end
				end)
			end
			task.wait(60)
		end
	end)

	-- kios milik pemain
	local kiosCache = nil
	local function FindKios()
		if kiosCache and kiosCache.Parent then return kiosCache end
		local uid = LocalPlayer.UserId
		local uids = tostring(uid)
		local fname = (GC and GC.Plot and GC.Plot.KiosFolderName) or "KiosAktif"
		local folder = workspace:FindFirstChild(fname)
		if folder then
			local m = folder:FindFirstChild("Kios_" .. LocalPlayer.Name)
			if m then kiosCache = m return m end
			for _, c in ipairs(folder:GetChildren()) do
				if c:IsA("Model") and (c:GetAttribute("OwnerUserId") == uid or c:GetAttribute("Owner") == uid or c.Name:find(uids)) then
					kiosCache = c
					return c
				end
			end
		end
		local plot = H.Plot()
		if plot then
			for _, d in ipairs(plot:GetDescendants()) do
				if d:IsA("Model") and (d:GetAttribute("OwnerUserId") == uid or d.Name:find("Kios") or d.Name:find("Lapak")) then
					kiosCache = d
					return d
				end
			end
		end
		for _, fn in ipairs({"Lapak", "Kios", "KiosAktif", "LapakPemain"}) do
			local f = workspace:FindFirstChild(fn)
			if f then
				for _, c in ipairs(f:GetChildren()) do
					if c:IsA("Model") and (c:GetAttribute("OwnerUserId") == uid or c.Name:find(uids) or c.Name:find(LocalPlayer.Name)) then
						kiosCache = c
						return c
					end
				end
			end
		end
		return nil
	end
	local function Slots(kios)
		local out = {}
		if not kios then return out end
		for _, d in ipairs(kios:GetDescendants()) do
			if d:IsA("Attachment") and d.Name:match("^slot%d+$") then table.insert(out, d) end
		end
		table.sort(out, function(a, b) return (tonumber(a.Name:match("%d+$")) or 0) < (tonumber(b.Name:match("%d+$")) or 0) end)
		return out
	end
	local function CallRak(...)
		local rem = H.R.Rak
		if not rem then return false, nil end
		local args = {...}
		local ok, res = pcall(function()
			if rem:IsA("RemoteFunction") then return rem:InvokeServer(unpack(args)) end
			rem:FireServer(unpack(args))
			return true
		end)
		if getgenv().LapakDebug then print("[Lapak Debug]", tostring(args[1]), tostring(args[2]), tostring(args[3]), ok, tostring(res)) end
		return ok, res
	end

	local lastPhase = nil
	local function Tick()
		if not getgenv().AutoKelolaLapakActive then return end
		if not H.Live() then st.Set(1, "Menunggu karakter respawn...") return end
		if not H.R.Rak or not H.R.Rak.Parent then
			pcall(H.LoadRemotes)
			if not H.R.Rak then
				st.Set(1, "Mencari Remote Rak Kios...")
				task.wait(1.5)
				return
			end
		end
		local kios = FindKios()
		if not kios then st.Set(1, "Mencari Kios di Plot...") task.wait(2) return end
		local slots = Slots(kios)
		if #slots == 0 then st.Set(1, "Mencari slot etalase kios...") task.wait(2) return end
		local phase = (workspace:GetAttribute("Phase") == "Malam" or Lighting:GetAttribute("Phase") == "Malam") and "Malam" or "Siang"
		local inv = ScanInventory()
		local order = {}
		for _, id in ipairs(pilih[phase] or {}) do
			if inv[id] and inv[id].count > 0 then table.insert(order, id) end
		end
		if #order == 0 then
			local other = (phase == "Malam") and "Siang" or "Malam"
			for _, id in ipairs(pilih[other] or {}) do
				if inv[id] and inv[id].count > 0 then table.insert(order, id) end
			end
		end
		if #order == 0 and #(pilih.Siang or {}) == 0 and #(pilih.Malam or {}) == 0 then
			local all = {}
			for _, e in pairs(inv) do
				if e.count > 0 then table.insert(all, e) end
			end
			table.sort(all, function(a, b)
				local ca = Cocok(a.id, phase) and 1 or 0
				local cb = Cocok(b.id, phase) and 1 or 0
				if ca ~= cb then return ca > cb end
				return (a.harga or 0) > (b.harga or 0)
			end)
			for _, e in ipairs(all) do table.insert(order, e.id) end
		end
		local inOrder = {}
		for _, id in ipairs(order) do inOrder[id] = true end
		local phaseChanged = (lastPhase ~= nil and lastPhase ~= phase)
		if phaseChanged then
			st.Set(1, string.format("Waktu berganti ke %s! Mengambil sisa barang lama...", phase))
			lastPhase = phase
		elseif not lastPhase then
			lastPhase = phase
		end

		local filled = 0
		local emptySlots, refill = {}, {}
		for _, slot in ipairs(slots) do
			if not H.Run() or not getgenv().AutoKelolaLapakActive then break end
			local item = slot:GetAttribute("Item")
			local stok = 0
			if item and slot:FindFirstChild("Stok") then
				local iv = slot.Stok:FindFirstChild(item)
				if iv and iv:IsA("IntValue") then stok = iv.Value end
			end
			local pull = false
			if getgenv().AutoTarikSisaFase and item and stok > 0 then
				if phaseChanged then
					if (not inOrder[item]) or (not Cocok(item, phase)) then pull = true end
				else
					if (not Cocok(item, phase)) and #order > 0 and (not inOrder[item]) then pull = true end
				end
			end
			if pull then
				st.Set(1, string.format("Tarik sisa %s dari %s (%s)...", NamaItem(item), slot.Name, phase))
				CallRak("ambil", slot.Name)
				task.wait(0.4)
				table.insert(emptySlots, slot)
			elseif item and stok > 0 then
				filled += 1
				local cfg = GC and GC.Items and GC.Items[item]
				local cap = (cfg and cfg.jenis == "rak") and capRak or capNampan
				if stok < cap and inv[item] and inv[item].count > 0 then
					table.insert(refill, {slot = slot, item = item, stok = stok, cap = cap})
				end
			else
				table.insert(emptySlots, slot)
			end
		end
		if phaseChanged then inv = ScanInventory() end

		for _, r in ipairs(refill) do
			if not H.Run() or not getgenv().AutoKelolaLapakActive then break end
			st.Set(1, string.format("Isi %s (%d/%d)...", NamaItem(r.item), r.stok, r.cap))
			local ok, res = CallRak("isi", r.slot.Name)
			if ok and type(res) == "table" and res.ok then
				local n = res.n or 1
				if inv[r.item] then inv[r.item].count = math.max(0, inv[r.item].count - n) end
			end
			task.wait(0.4)
		end

		if #order > 0 and #emptySlots > 0 then
			local rr = 1
			for _, slot in ipairs(emptySlots) do
				if not H.Run() or not getgenv().AutoKelolaLapakActive then break end
				local pickId = nil
				for _ = 1, #order do
					local id = order[rr]
					rr = (rr % #order) + 1
					if inv[id] and inv[id].count > 0 then pickId = id break end
				end
				if not pickId then break end
				st.Set(1, string.format("Taruh %s di %s...", NamaItem(pickId), slot.Name))
				local ok, res = CallRak("taruh", slot.Name, pickId)
				if ok and type(res) == "table" and res.ok then
					local n = res.n or 1
					inv[pickId].count = math.max(0, inv[pickId].count - n)
					filled += 1
				end
				task.wait(0.45)
			end
		end

		if #order == 0 and #emptySlots > 0 then
			st.Set(1, "Tidak ada barang di tas untuk restok")
		else
			st.Set(1, string.format("Memantau etalase (%d/%d Slot Terisi)", filled, #slots))
		end
		st.Set(2, string.format("Etalase: %d/%d Slot | Terjual: %d Barang", filled, #slots, sold))
	end

	task.spawn(function()
		while H.Run() and not (game:IsLoaded() and H.Live() and LocalPlayer:FindFirstChildOfClass("Backpack")) do task.wait(0.5) end
		if resumeState then task.wait(3) end
		while H.Run() do
			task.wait(3)
			if getgenv().AutoKelolaLapakActive then
				local ok, err = pcall(Tick)
				if not ok then
					warn("[Pasar Hutan] Error loop lapak (lanjut otomatis):", err)
					st.Set(1, "Error, mencoba lagi...")
				end
			end
		end
	end)

	-- simpan state + pasang auto-reload saat pindah server
	local lastJson, queued = "", false
	local function SaveState()
		local s = {lapak = getgenv().AutoKelolaLapakActive and true or false, siang = table.clone(pilih.Siang), malam = table.clone(pilih.Malam)}
		getgenv().UbeyPHSavedState = s
		local ok, js = pcall(function() return HttpService:JSONEncode(s) end)
		if ok and js ~= lastJson then
			lastJson = js
			if writefile then pcall(writefile, stateFile, js) end
		end
	end
	local function QueueReload()
		if queued then return end
		local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
		if not q then
			warn("[Pasar Hutan] Executor tidak mendukung queue_on_teleport - skrip tidak bisa auto-reload.")
			return
		end
		local loader = getgenv().UbeyHubLoader
		if not loader then
			warn("[Pasar Hutan] getgenv().UbeyHubLoader belum diset - Auto Lapak tidak lanjut otomatis setelah pindah server.")
			return
		end
		SaveState()
		queued = true
		pcall(q, "getgenv().UbeyPHResume = true\n" .. loader)
	end
	H.Conn(LocalPlayer.OnTeleport:Connect(function(s)
		if not H.Run() then return end
		if s == Enum.TeleportState.Started or s == Enum.TeleportState.InProgress then QueueReload() end
	end))
	task.spawn(function()
		while H.Run() do
			SaveState()
			task.wait(3)
		end
	end)
end

------------------------------------------------------------------
-- TAB MASAK (kompor, meja potong, pemangang)
------------------------------------------------------------------
local PG = {minKg = 30, bad = {}, porsi = 0}
do
	local RS = H.RS
	local NAMES = {
		DagingGagak = "Daging Gagak", JamurKuburan = "Jamur Kuburan", Kamboja = "Kamboja", KepitingSungai = "Kepiting Sungai",
		Dupa = "Dupa", Pisang = "Pisang", BubukKopi = "Bubuk Kopi", Kemenyan = "Kemenyan", Telur = "Telur", Cabai = "Cabai",
		Susu = "Susu", Kubis = "Kubis", Apel = "Apel", Jeruk = "Jeruk", AyamPotong = "Ayam Potong",
	}
	local MENUS = {
		{key = "SateKepiting", label = "Sate Kepiting", method = "Membakar", time = 90, ing = {{"KepitingSungai", 3}, {"Dupa", 1}}},
		{key = "KopiKemenyan", label = "Kopi Kemenyan", method = "Menyeduh", time = 90, ing = {{"BubukKopi", 1}, {"Kemenyan", 1}}},
		{key = "TumisKamboja", label = "Tumis Kamboja", method = "Menumis", time = 90, ing = {{"Kamboja", 1}}},
		{key = "PisangRebus", label = "Pisang Raja Rebus", method = "Merebus", time = 90, ing = {{"Pisang", 1}}},
		{key = "Rebus", label = "Jamur Rebus Kuburan", method = "Merebus", time = 60, ing = {{"JamurKuburan", 1}}},
		{key = "Bakar", label = "Sate Gagak", method = "Membakar", time = 60, ing = {{"DagingGagak", 1}}},
		{key = "MartabakGagak", label = "Martabak Telur Gagak", method = "Menggoreng", time = 90, ing = {{"Telur", 2}, {"DagingGagak", 1}, {"Cabai", 2}}},
		{key = "SotoKuburan", label = "Soto Jamur Kuburan", method = "Merebus", time = 120, ing = {{"Susu", 2}, {"JamurKuburan", 2}, {"Kubis", 1}}},
		{key = "EsTelerArwah", label = "Es Teler Arwah", method = "Meracik", time = 150, ing = {{"Apel", 1}, {"Jeruk", 2}, {"Susu", 1}}},
		{key = "IngkungSesajen", label = "Ingkung Ayam Sesajen", method = "Mengungkep", time = 180, ing = {{"AyamPotong", 1}, {"Susu", 1}, {"Pisang", 2}}},
	}
	local menuSel = "SateKepiting"
	local olahSel = "PotongGagak"

	local function CountItem(id)
		local n = 0
		local function scan(c)
			if not c then return end
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemId") == id then n += tonumber(t:GetAttribute("Count")) or 1 end
			end
		end
		scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
		scan(LocalPlayer.Character)
		return n
	end

	-- UI masak
	UI.Section(MasakPage, "AUTO MASAK (KOMPOR)")
	local cookSt
	FlagToggle(MasakPage, "Auto Masak", "Berdiri dekat kompor dulu, server menolak jika terlalu jauh.", "AutoMasakActive", function(v)
		cookSt.Set(1, v and "Status: Menuju kompor..." or "Status: Berhenti")
	end)
	cookSt = UI.Status(MasakPage, 3)
	cookSt.Set(1, "Status: Siap (OFF)")
	cookSt.Set(2, "Makanan Dimasak: 0 Porsi")
	cookSt.Set(3, "Menu dipilih: -")
	local menuList = UI.List(MasakPage, 230)
	local menuSig = ""
	local function RefreshMenus(force)
		local rows, sig = {}, menuSel
		for _, m in ipairs(MENUS) do
			local can = math.huge
			local parts = {}
			for _, ing in ipairs(m.ing) do
				local have = CountItem(ing[1])
				can = math.min(can, math.floor(have / ing[2]))
				local col = (have >= ing[2]) and C.good or C.bad
				table.insert(parts, string.format("<font color=\"#%s\">%dx %s (%d)</font>", col:ToHex(), ing[2], NAMES[ing[1]] or ing[1], have))
			end
			if can == math.huge then can = 0 end
			local txt = string.format("<b>%s</b>\n%s | %d detik | %s\n%s", m.label, m.method, m.time,
				can > 0 and ("Bisa masak: " .. can .. " porsi") or "Bahan belum cukup", table.concat(parts, "  "))
			table.insert(rows, {m = m, txt = txt})
			sig = sig .. txt
		end
		if sig == menuSig and not force then return end
		menuSig = sig
		menuList.Clear()
		for _, r in ipairs(rows) do
			local sel = (menuSel == r.m.key)
			if sel then cookSt.Set(3, "Menu dipilih: " .. r.m.label) end
			menuList.Add(r.txt, sel, function()
				menuSel = r.m.key
				RefreshMenus(true)
			end, true, 62)
		end
		menuList.Done()
	end
	RefreshMenus(true)
	H.RefreshMasak = RefreshMenus

	UI.Section(MasakPage, "AUTO OLAH (MEJA POTONG)")
	local olahSt
	FlagToggle(MasakPage, "Auto Olah", "Olah bahan mentah di meja potong.", "AutoOlahActive", function(v)
		olahSt.Set(1, v and "Status: Mengolah bahan..." or "Status: Berhenti")
	end)
	olahSt = UI.Status(MasakPage, 2)
	olahSt.Set(1, "Status: Siap (OFF)")
	olahSt.Set(2, "Bahan Diolah: 0 Kali")
	UI.Segment(MasakPage, "Bahan Olah", {
		{key = "PotongGagak", text = "GAGAK"}, {key = "PotongAyamKampung", text = "AYAM"}, {key = "GilingKopi", text = "KOPI"},
	}, function() return olahSel end, function(k) olahSel = k end)

	-- UI panggang
	UI.Section(MasakPage, "AUTO PANGGANG BABI (PEMANGANG)")
	local pgSt
	FlagToggle(MasakPage, "Auto Panggang", "Isi antrean sampai 3 babi (dewasa & tidak terkunci). Berdiri dekat pemangang.", "AutoPanggangActive", function(v)
		if v then PG.bad = {} end
		pgSt.Set(1, v and "Status: Menuju pemangang..." or "Status: Berhenti")
	end)
	pgSt = UI.Status(MasakPage, 3)
	pgSt.Set(1, "Status: Siap (OFF)")
	pgSt.Set(2, "Dipanggang: 0 Babi | 0 Porsi")
	pgSt.Set(3, "Babi dipilih: AUTO")
	local pgList = UI.List(MasakPage, 120)

	pcall(function()
		local c = require(RS:WaitForChild("GameConfig", 5)).Panggang
		if c and tonumber(c.BeratMin) then PG.minKg = tonumber(c.BeratMin) end
	end)
	local function IsBabi(t)
		return t:IsA("Tool") and t:GetAttribute("babiBerat") ~= nil
			and (t:GetAttribute("LokSumber") == "Babi Ngepet" or string.find(t.Name, "Babi Ngepet", 1, true) ~= nil)
	end
	local function ScanBabi()
		local out = {}
		local function scan(c)
			if not c then return end
			for _, t in ipairs(c:GetChildren()) do
				if IsBabi(t) then
					out[#out + 1] = {tool = t, kg = tonumber(t:GetAttribute("babiBerat")) or 0, locked = t:GetAttribute("babiKunci") == true, id = t:GetAttribute("idBabi") or t.Name}
				end
			end
		end
		scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
		scan(LocalPlayer.Character)
		table.sort(out, function(a, b) return a.kg < b.kg end)
		return out
	end
	local function Usable(b)
		local until_ = PG.bad[b.id]
		if until_ and tick() < until_ then return false end
		return b.kg >= PG.minKg and not b.locked
	end
	local function PickBabi()
		local want = getgenv().PanggangBabiKg
		local all = ScanBabi()
		for _, b in ipairs(all) do
			if Usable(b) and (want == "auto" or b.kg == want) then return b, all end
		end
		return nil, all
	end
	local pgSig = ""
	local function RefreshPg(force)
		local all = ScanBabi()
		local want = getgenv().PanggangBabiKg
		local groups, order = {}, {}
		for _, b in ipairs(all) do
			local k = b.kg .. (b.locked and "L" or "")
			if not groups[k] then
				groups[k] = {kg = b.kg, locked = b.locked, n = 0}
				order[#order + 1] = k
			end
			groups[k].n += 1
		end
		local sig = tostring(want) .. "|"
		for _, k in ipairs(order) do sig = sig .. k .. "x" .. groups[k].n .. "," end
		if sig ~= pgSig or force then
			pgSig = sig
			pgList.Clear()
			pgList.Add("AUTO (dewasa terringan)", want == "auto", function()
				getgenv().PanggangBabiKg = "auto"
				RefreshPg(true)
			end, false, 24)
			for _, k in ipairs(order) do
				local g = groups[k]
				local txt = g.kg .. " kg" .. (g.n > 1 and (" x" .. g.n) or "") .. (g.locked and " (kunci)" or "")
				local bad = g.locked or g.kg < PG.minKg
				pgList.Add(txt, want == g.kg and not g.locked, function()
					if g.locked then pgSt.Set(1, "Babi " .. g.kg .. " kg terkunci, buka kunci di tas dulu") return end
					if g.kg < PG.minKg then pgSt.Set(1, "Babi " .. g.kg .. " kg belum dewasa (min " .. PG.minKg .. " kg)") return end
					getgenv().PanggangBabiKg = g.kg
					RefreshPg(true)
				end, false, 24, bad)
			end
			pgList.Done()
		end
		if want == "auto" then
			pgSt.Set(3, "Babi dipilih: AUTO (dewasa terringan, min " .. PG.minKg .. " kg)")
		else
			local n = 0
			for _, b in ipairs(all) do
				if b.kg == want and Usable(b) then n += 1 end
			end
			pgSt.Set(3, string.format("Babi dipilih: %d kg (%s)", want, n > 0 and ("di tas: " .. n .. " ekor") or "tidak ada di tas"))
		end
	end
	RefreshPg(true)
	H.RefreshPg = RefreshPg

	-- cari kompor
	local STOVE_RANGE = 15
	local stoveObj, stoveT = nil, 0
	local function StoveWord(s, strict)
		s = string.lower(tostring(s or ""))
		if s == "" then return false end
		local words = strict and {"kompor", "stove", "masak", "cook"} or {"kompor", "stove", "pcook", "pmasak"}
		for _, w in ipairs(words) do
			if string.find(s, w, 1, true) then return true end
		end
		return false
	end
	local function PosOf(o)
		if not o then return nil end
		if o:IsA("Attachment") then return o.WorldPosition end
		if o:IsA("BasePart") then return o.Position end
		if o:IsA("Model") then return o:GetPivot().Position end
		local bp = o:FindFirstChildWhichIsA("BasePart", true)
		return bp and bp.Position or nil
	end
	local function FindKiosModel()
		local folder = workspace:FindFirstChild("KiosAktif")
		if not folder then return nil end
		local k = folder:FindFirstChild("Kios_" .. LocalPlayer.Name)
		if not k then
			for _, c in ipairs(folder:GetChildren()) do
				if c:GetAttribute("OwnerUserId") == LocalPlayer.UserId then k = c break end
			end
		end
		return k
	end
	local function ScanStove()
		local hrp = H.Live()
		local me = hrp and hrp.Position
		local ch = LocalPlayer.Character
		local best, bestD
		local function consider(o)
			if not o or (ch and o:IsDescendantOf(ch)) then return end
			local p = PosOf(o)
			if not p then return end
			local d = me and (me - p).Magnitude or 0
			if not bestD or d < bestD then best, bestD = o, d end
		end
		local function scanIn(root)
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("ProximityPrompt") then
					if StoveWord(d.ObjectText, true) or StoveWord(d.ActionText, true) then consider(d.Parent) end
				elseif d:IsA("Attachment") or d:IsA("BasePart") or d:IsA("Model") then
					if StoveWord(d.Name) then consider(d) end
				end
			end
		end
		local k = FindKiosModel()
		if k then
			scanIn(k)
			if best then return best end
		end
		scanIn(workspace)
		return best
	end
	local function StovePos()
		if stoveObj and stoveObj.Parent then
			local p = PosOf(stoveObj)
			if p then return p end
		end
		stoveObj = nil
		if tick() - stoveT < 10 then return nil end
		stoveT = tick()
		stoveObj = ScanStove()
		return PosOf(stoveObj)
	end
	local function GoStove()
		if getgenv().PH_Repairing then return false end
		local hrp = H.Live()
		if not hrp then return false end
		local p = StovePos()
		if not p then
			cookSt.Set(1, "Kompor tidak ditemukan, dekati kompor manual")
			return false
		end
		if (hrp.Position - p).Magnitude <= STOVE_RANGE then return true end
		cookSt.Set(1, "Menuju kompor...")
		local ok = H.TeleportTo(p + Vector3.new(0, 3, 0), function()
			return not H.Run() or not getgenv().AutoMasakActive or not H.Live()
		end)
		task.wait(0.5)
		return ok
	end

	task.spawn(function()
		while H.Run() do
			task.wait(2.0)
			local R = H.R
			if getgenv().AutoMasakActive and R.Stove and R.StovePoll then
				GoStove()
				local ok, res = pcall(function() return R.StovePoll:InvokeServer() end)
				if ok and type(res) == "table" and res.ok then
					local slots = res.slots or {}
					local maxQ = res.maxQueue or 3
					local free = maxQ - #slots
					if free > 0 then
						local made, err = 0, nil
						for _ = 1, free do
							cookSt.Set(1, "Memasak " .. menuSel .. " di Kompor...")
							local ok2, r2 = pcall(function() return R.Stove:InvokeServer(menuSel) end)
							if ok2 and type(r2) == "table" and r2.ok then
								made += 1
								Q.Dapur += 1
								cookSt.Set(2, "Makanan Dimasak: " .. Q.Dapur .. " Porsi")
								task.wait(0.3)
							else
								if ok2 and type(r2) == "table" then err = r2.err or r2.error or r2.msg or r2.reason end
								break
							end
						end
						if made > 0 then
							cookSt.Set(1, "Sukses memasak " .. menuSel .. " x" .. made .. "!")
						elseif err and string.find(string.lower(tostring(err)), "dekati", 1, true) then
							cookSt.Set(1, "Dekati kompor dulu")
							stoveObj, stoveT = nil, 0
						else
							cookSt.Set(1, "Bahan " .. menuSel .. " belum cukup di tas" .. (err and (" (" .. tostring(err) .. ")") or ""))
						end
					else
						cookSt.Set(1, "Antrian kompor penuh (" .. #slots .. "/" .. maxQ .. ")")
					end
				end
			end
			if getgenv().AutoOlahActive and R.OlahStart and R.OlahPoll then
				local ok, res = pcall(function() return R.OlahPoll:InvokeServer() end)
				if ok and type(res) == "table" and res.ok then
					olahSt.Set(1, "Mengolah " .. olahSel .. "...")
					local ok2, r2 = pcall(function() return R.OlahStart:InvokeServer(olahSel, 1) end)
					if ok2 and type(r2) == "table" and r2.ok then
						Q.Olah += 1
						olahSt.Set(2, "Bahan Diolah: " .. Q.Olah .. " Kali")
						olahSt.Set(1, "Berhasil mengolah " .. olahSel .. "!")
					else
						olahSt.Set(1, "Bahan olahan belum tersedia di tas")
					end
				end
			end
			task.wait(3.0)
		end
	end)

	-- panggang babi: antrean sampai 3 babi sekaligus
	do
		local RANGE = 8
		local MAX_ANTRE = 3
		local pkios, ppos, pprompt, pmem
		local notifs = {}
		local fails = 0
		local wasBusy = false
		local nextWait = 1.5
		local function Say(t) pgSt.Set(1, t) end

		local function FindPemangang()
			if pkios and pkios.Parent and ppos and ppos.Parent and pprompt and pprompt.Parent then return true end
			pkios, ppos, pprompt, pmem = nil, nil, nil, nil
			local k = FindKiosModel()
			if not k then return false end
			local at = k:FindFirstChild("pPangang", true)
			local pr = at and at:FindFirstChildWhichIsA("ProximityPrompt")
			if not pr then
				for _, d in ipairs(k:GetDescendants()) do
					if d:IsA("ProximityPrompt") and (d.Name == "PanggangPrompt" or d.ActionText == "Panggang Babi") then
						pr, at = d, d.Parent
						break
					end
				end
			end
			if not (at and pr) then return false end
			pkios, ppos, pprompt = k, at, pr
			pmem = k:FindFirstChild("Pemangang", true)
			return true
		end
		local function Busy()
			return pmem ~= nil and pmem.Parent ~= nil and pmem:GetAttribute("Memanggang") == true
		end
		local function LabelText(name)
			if not ppos then return nil end
			for _, d in ipairs(ppos:GetDescendants()) do
				if d:IsA("TextLabel") and d.Name == name and d.Text ~= "" then return d.Text end
			end
			return nil
		end
		-- jumlah babi di antrean pemangang, dibaca dari label "Antre: N babi"
		local function QueueCount()
			local t = LabelText("Antre")
			local n = t and tonumber(string.match(t, "(%d+)"))
			if n then return n end
			return Busy() and 1 or 0
		end

		-- tangkap notifikasi game (balasan server)
		task.spawn(function()
			local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
			local ng = pg and pg:WaitForChild("NotifGui", 10)
			if not ng then return end
			local function push(t)
				if not t or t == "" or t == "Notification Message" then return end
				local last = notifs[#notifs]
				if last and last.text == t and tick() - last.t < 0.6 then return end
				notifs[#notifs + 1] = {t = tick(), text = t}
				if #notifs > 30 then table.remove(notifs, 1) end
			end
			local function hook(l)
				H.Conn(l:GetPropertyChangedSignal("Text"):Connect(function() push(l.Text) end))
			end
			for _, d in ipairs(ng:GetDescendants()) do
				if d:IsA("TextLabel") then hook(d) end
			end
			H.Conn(ng.DescendantAdded:Connect(function(d)
				if d:IsA("TextLabel") then
					hook(d)
					task.delay(0.1, function() push(d.Text) end)
				end
			end))
		end)
		local function NotifSince(t0)
			local found
			for _, n in ipairs(notifs) do
				if n.t >= t0 then
					local l = string.lower(n.text)
					if string.find(l, "anggang", 1, true) or string.find(l, "dewasa", 1, true) or string.find(l, "dekat", 1, true)
						or string.find(l, "jauh", 1, true) or string.find(l, "babi", 1, true) then
						found = n.text
					end
				end
			end
			return found
		end
		local function GoPemangang()
			local hrp = H.Live()
			if not hrp then return false end
			local p = ppos.WorldPosition
			if (hrp.Position - p).Magnitude <= RANGE then return true end
			Say("Menuju pemangang...")
			local ok = H.TeleportTo(p + Vector3.new(0, 3, 4), function()
				return not H.Run() or not getgenv().AutoPanggangActive or not H.Live()
			end)
			task.wait(0.5)
			return ok
		end
		local function EquipBabi(b)
			local _, hum = H.Live()
			if not hum then return false end
			local t = b.tool
			if not t or not t.Parent then return false end
			if t.Parent == LocalPlayer.Character then return true end
			pcall(function() hum:EquipTool(t) end)
			for _ = 1, 15 do
				if t.Parent == LocalPlayer.Character then return true end
				task.wait(0.1)
			end
			return false
		end
		-- masukkan 1 babi ke antrean. Berhasil jika antrean bertambah / babi hilang dari tas / mulai memanggang
		local function Grill(b)
			local t0 = tick()
			local q0 = QueueCount()
			if not EquipBabi(b) then return false, "Gagal memegang babi " .. b.kg .. " kg" end
			task.wait(0.3)
			pcall(function() pprompt:InputHoldBegin() end)
			task.wait((pprompt.HoldDuration or 0.6) + 0.15)
			pcall(function() pprompt:InputHoldEnd() end)
			for _ = 1, 20 do
				task.wait(0.2)
				if QueueCount() > q0 or (q0 == 0 and Busy()) or (b.tool and b.tool.Parent == nil) then
					return true, NotifSince(t0)
				end
			end
			return false, NotifSince(t0)
		end

		local function Step()
			nextWait = 1.5
			if getgenv().PH_Repairing then return end
			if not FindPemangang() then Say("Pemangang tidak ditemukan (butuh Market Lv 6)") return end
			local busy = Busy()
			if busy then
				wasBusy = true
			elseif wasBusy then
				wasBusy = false
				Say("Panggangan selesai, lanjut babi berikutnya...")
			end
			local q = QueueCount()
			local sisa = LabelText("Sisa") or ""
			if q >= MAX_ANTRE then
				Say(string.format("Memanggang... %s | Antre: %d/%d (penuh)", sisa, q, MAX_ANTRE))
				return
			end
			local b = PickBabi()
			if not b then
				if busy or q > 0 then
					Say(string.format("Memanggang... %s | Antre: %d/%d | tidak ada babi lain di tas", sisa, q, MAX_ANTRE))
				else
					local w = getgenv().PanggangBabiKg
					Say(w == "auto" and ("Menunggu babi dewasa (min " .. PG.minKg .. " kg) di tas") or ("Babi " .. tostring(w) .. " kg habis / tidak ada di tas"))
				end
				return
			end
			if not GoPemangang() then return end
			Say(string.format("Memasukkan babi %d kg ke antrean (%d/%d)...", b.kg, q + 1, MAX_ANTRE))
			local ok, msg = Grill(b)
			if ok then
				fails = 0
				nextWait = 0.6 -- langsung isi slot antrean berikutnya
				Q.Panggang += 1
				local por = tonumber(string.match(tostring(msg or ""), "(%d+)%s*[Pp]orsi")) or 0
				PG.porsi += por
				pgSt.Set(2, "Dipanggang: " .. Q.Panggang .. " Babi | " .. PG.porsi .. " Porsi")
				Say(msg and ("Berhasil: " .. msg) or string.format("Babi %d kg masuk antrean (%d/%d)", b.kg, math.min(q + 1, MAX_ANTRE), MAX_ANTRE))
				return
			end
			local low = string.lower(tostring(msg or ""))
			if string.find(low, "dewasa", 1, true) then
				PG.bad[b.id] = tick() + 120
				Say("Ditolak: " .. tostring(msg))
			elseif string.find(low, "dekat", 1, true) or string.find(low, "jauh", 1, true) then
				pkios, ppos, pprompt, pmem = nil, nil, nil, nil
				Say("Dekati pemangang dulu")
			elseif string.find(low, "penuh", 1, true) or string.find(low, "antre", 1, true) or string.find(low, "antri", 1, true) then
				Say("Antrean pemangang penuh, menunggu...")
				nextWait = 3
			else
				fails += 1
				Say("Gagal memanggang: " .. tostring(msg or "tidak ada balasan") .. " (" .. fails .. "/4)")
				if fails >= 4 then
					PG.bad[b.id] = tick() + 120
					fails = 0
				end
			end
		end
		task.spawn(function()
			while H.Run() do
				task.wait(nextWait)
				if getgenv().AutoPanggangActive then
					local ok, err = pcall(Step)
					if not ok then
						warn("[Pasar Hutan] Auto Panggang error:", err)
						Say("Error: " .. tostring(err))
						task.wait(3)
					end
				else
					nextWait = 1.5
				end
			end
		end)
	end

	task.spawn(function()
		while H.Run() do
			task.wait(1.5)
			if Main.Visible and MasakPage.Visible then
				pcall(RefreshMenus, false)
				pcall(RefreshPg, false)
			end
		end
	end)
end

------------------------------------------------------------------
-- TAB TUYUL & PET
------------------------------------------------------------------
do
	UI.Section(TuyulPage, "AUTO SUAP TUYUL LIAR")
	local tSt
	FlagToggle(TuyulPage, "Auto Suap Tuyul Liar", "Dekati Tuyul Liar & beri Sate Kepiting.", "AutoTuyulLiarActive", function(v)
		tSt.Set(1, v and "Status: Menunggu Tuyul Liar muncul..." or "Status: Berhenti")
	end, true)
	tSt = UI.Status(TuyulPage, 2)
	tSt.Set(1, "Status: Siap (OFF)")
	tSt.Set(2, "Suap Berhasil: 0 Kali")

	UI.Section(TuyulPage, "SISTEM PET TUYUL")
	local pSt = UI.Status(TuyulPage, 2)
	pSt.Set(1, "Status Pet: Memeriksa...")
	pSt.Set(2, "Auto Latih melatih pet tiap 240 detik untuk EXP.")
	UI.Button(TuyulPage, "Panggil Pet", "Panggil pet tuyul ke sisimu.", "PANGGIL", function()
		if H.R.Pet then
			H.R.Pet:FireServer("panggil")
			pSt.Set(1, "Perintah: Memanggil pet tuyul...")
			task.delay(2, function() if H.Run() then pSt.Set(1, "Pet Tuyul: Siap") end end)
		end
	end, C.accent)
	FlagToggle(TuyulPage, "Auto Latih", "Latih pet otomatis tiap 240 detik.", "AutoLatihPetActive", function(v)
		if v and H.R.Pet then H.R.Pet:FireServer("latih") end
	end)
	UI.Button(TuyulPage, "Jaga Ternak", "Tugaskan pet menjaga peternakan.", "JAGA", function()
		if H.R.Pet then
			H.R.Pet:FireServer("ternak")
			pSt.Set(1, "Pet Tuyul ditugaskan: Jaga Peternakan!")
		end
	end, C.good)

	task.spawn(function()
		local lastTrain = 0
		while H.Run() do
			task.wait(1.0)
			if getgenv().AutoLatihPetActive and H.R.Pet then
				if (tick() - lastTrain) > 240 then
					pcall(function() H.R.Pet:FireServer("latih") end)
					lastTrain = tick()
					pSt.Set(1, "Pet Tuyul dilatih (EXP bertambah)!")
				end
			end
			if getgenv().AutoTuyulLiarActive then
				local model = workspace:FindFirstChild("TuyulLiar")
				if model and model:IsA("Model") then
					local prm = model:FindFirstChildWhichIsA("ProximityPrompt", true)
					local hrp = H.Live()
					if prm and prm.Enabled and hrp then
						tSt.Set(1, "Tuyul Liar Terdeteksi! Mendekat...")
						local pos = model:GetPivot().Position + Vector3.new(0, 1.5, 0)
						local sate = H.FindTool("SateKepiting") or H.FindTool("Sate Kepiting")
						if sate and LocalPlayer.Character then
							local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
							if hum and sate.Parent ~= LocalPlayer.Character then
								hum:EquipTool(sate)
								task.wait(0.2)
							end
						end
						H.FlyFloat(true)
						H.TeleportTo(pos, function() return not H.Run() or not getgenv().AutoTuyulLiarActive or not H.Live() end)
						tSt.Set(1, "Memberi Sate Kepiting ke Tuyul Liar...")
						H.Fire(prm, 0.35)
						task.wait(0.3)
						Q.Tuyul += 1
						tSt.Set(2, "Suap Berhasil: " .. Q.Tuyul .. " Kali")
						task.wait(1.5)
					end
				else
					tSt.Set(1, "Menunggu Tuyul Liar muncul di map...")
				end
			end
		end
	end)
end

------------------------------------------------------------------
-- AUTO PERBAIKI ALAT (di tab Auto Farm)
------------------------------------------------------------------
do
	local RS = H.RS
	local DUR_MIN = 100
	local cool = {}
	UI.Section(FarmPage, "AUTO PERBAIKI KAPAK & BELIUNG (Dur < 100)")
	local rSt
	FlagToggle(FarmPage, "Auto Perbaiki", "Jalan otomatis saat farm kayu/batu.", "AutoRepairActive", function(v)
		rSt.Set(1, v and "Status: Aktif (jalan saat farm kayu/batu)" or "Status: Berhenti")
	end)
	rSt = UI.Status(FarmPage, 2)
	rSt.Set(1, "Status: Siap (OFF)")
	rSt.Set(2, "Diperbaiki: 0 kali")
	local count = 0

	local function CraftPos()
		local folder = workspace:FindFirstChild("KiosAktif")
		if not folder then return nil end
		local k = folder:FindFirstChild("Kios_" .. LocalPlayer.Name)
		if not k then
			for _, c in ipairs(folder:GetChildren()) do
				if c:GetAttribute("OwnerUserId") == LocalPlayer.UserId then k = c break end
			end
		end
		local p = k and k:FindFirstChild("pCraft", true)
		if p and p:IsA("Attachment") then return p.WorldPosition end
		if p and p:IsA("BasePart") then return p.Position end
		return nil
	end
	local function NeedRepair()
		local out, now = {}, tick()
		local function scan(c)
			if not c then return end
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("AlatTambang") then
					local d, m = t:GetAttribute("Dur"), t:GetAttribute("DurMaks")
					if type(d) == "number" and type(m) == "number" and d < DUR_MIN and d < m and (not cool[t] or now > cool[t]) then
						table.insert(out, t)
					end
				end
			end
		end
		scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
		scan(LocalPlayer.Character)
		return out
	end
	local function AlatKey(t)
		local id = t:GetAttribute("AlatId")
		if id and tostring(id) ~= "" then return tostring(id) end
		return "toko:" .. tostring(t:GetAttribute("ToolName") or t.Name)
	end

	task.spawn(function()
		while H.Run() do
			task.wait(2)
			if not getgenv().AutoRepairActive then continue end
			if not (getgenv().PohonFarmActive or getgenv().BatuFarmActive) then
				rSt.Set(1, "Status: Siaga (jalan saat farm kayu/batu)")
				continue
			end
			local list = NeedRepair()
			if #list == 0 then
				rSt.Set(1, "Status: Alat aman (Dur >= " .. DUR_MIN .. ")")
				continue
			end
			local craft = CraftPos()
			local remote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("TempaAksi") or H.R.Tempa
			if not remote then
				pcall(H.LoadRemotes)
				remote = H.R.Tempa
			end
			if not craft or not remote then
				rSt.Set(1, not craft and "Meja Tempa kios tidak ditemukan" or "Remote TempaAksi tidak ditemukan")
				task.wait(5)
				continue
			end
			local hrp = H.Live()
			if not hrp then continue end
			local saved = hrp.Position
			local floatOn = hrp:FindFirstChild("FlyFloat") ~= nil
			getgenv().PH_Repairing = true
			local ok, err = pcall(function()
				task.wait(1.0)
				rSt.Set(1, "Menuju Meja Tempa...")
				local _, hum = H.Live()
				if hum then hum:UnequipTools() end
				H.FlyFloat(true)
				H.TeleportTo(craft + Vector3.new(0, 3, 0), function() return not H.Run() or not H.Live() end)
				task.wait(0.6)
				for _, tool in ipairs(list) do
					if not H.Run() then break end
					local nm = tostring(tool:GetAttribute("NamaTampil") or tool.Name)
					local dur = tonumber(tool:GetAttribute("Dur")) or 0
					local key = AlatKey(tool)
					rSt.Set(1, "Memperbaiki " .. nm .. " (" .. math.floor(dur) .. ")...")
					local s, res = pcall(function() return remote:InvokeServer({aksi = "perbaiki", kunci = key, darurat = false}) end)
					local good = s and type(res) == "table" and res.ok
					if not good and dur <= 0 then
						s, res = pcall(function() return remote:InvokeServer({aksi = "perbaiki", kunci = key, darurat = true}) end)
						good = s and type(res) == "table" and res.ok
					end
					if good then
						count += 1
						rSt.Set(2, "Diperbaiki: " .. count .. " kali")
						rSt.Set(1, "Berhasil memperbaiki " .. nm)
					else
						cool[tool] = tick() + 60
						local why = (s and type(res) == "table" and res.reason) or "gagal"
						rSt.Set(1, "Gagal " .. nm .. ": " .. tostring(why))
					end
					task.wait(0.5)
				end
				rSt.Set(1, "Kembali ke lokasi farm...")
				H.TeleportTo(saved, function() return not H.Run() or not H.Live() end)
				H.FlyFloat(floatOn)
			end)
			getgenv().PH_Repairing = false
			if not ok then
				warn("[Pasar Hutan] Auto Perbaiki error:", err)
				rSt.Set(1, "Error perbaikan, coba lagi...")
				task.wait(3)
			end
		end
	end)
end

------------------------------------------------------------------
-- TAB EVENT: KEPINGAN SALJU (tab hanya muncul saat event aktif)
------------------------------------------------------------------
do
	local FOLDER = "KepinganSaljuSaya"

	UI.Section(EventPage, "EVENT SALJU: KEPINGAN SALJU")
	local sSt
	FlagToggle(EventPage, "Auto Kumpul Kepingan Salju", "Dekati kepingan yang muncul, otomatis terklaim.", "AutoSaljuActive", function(v)
		if sSt then sSt.Set(1, v and "Status: Mencari kepingan salju..." or "Status: Berhenti") end
	end)
	sSt = UI.Status(EventPage, 3)
	sSt.Set(1, "Status: Siap (OFF)")
	sSt.Set(2, "Terkumpul sesi ini: 0 Kepingan")
	sSt.Set(3, "Kepingan di map: 0")
	UI.Segment(EventPage, "Mode Gerak", {
		{key = "instan", text = "TELEPORT"}, {key = "jalan", text = "JALAN KAKI"},
	}, function() return getgenv().UbeyConfig.SaljuMode end, function(k)
		getgenv().UbeyConfig.SaljuMode = k
		H.SaljuWalk = (k == "jalan")
		SaveConfig()
	end)

	-- daftar kepingan di folder event (model lain seperti SaljuKamera diabaikan)
	local function Flakes()
		local f = workspace:FindFirstChild(FOLDER)
		local out = {}
		if not f then return out, false end
		for _, m in ipairs(f:GetChildren()) do
			if m.Name:lower():find("kepingan") then
				local pos
				if m:IsA("Model") then pos = m:GetPivot().Position
				elseif m:IsA("BasePart") then pos = m.Position end
				if pos then table.insert(out, {item = m, pos = pos}) end
			end
		end
		return out, true
	end

	-- tampilkan / sembunyikan tab Event mengikuti ada-tidaknya event
	task.spawn(function()
		while H.Run() do
			local _, exists = Flakes()
			EventTab.Button.Visible = exists
			if not exists then
				if getgenv().AutoSaljuActive then H.Off("AutoSaljuActive") end
				if EventPage.Visible then UI.SelectTab(Tabs[1]) end
			end
			task.wait(2)
		end
	end)

	task.spawn(function()
		local cool = setmetatable({}, {__mode = "k"})
		local savedPos = nil
		local function active() return H.Run() and getgenv().AutoSaljuActive end
		local function gone(item) return (not item.Parent) or (not item:IsDescendantOf(workspace)) end

		while H.Run() do
			task.wait(0.2)
			if not getgenv().AutoSaljuActive then
				if savedPos then
					local sp = savedPos
					savedPos = nil
					local h = H.Live()
					if h and not H.AnyActive() and (h.Position - sp).Magnitude > 4 then
						H.Returning = true
						H.TeleportTo(sp, function() return not H.Run() or H.AnyActive() or not H.Live() end, H.SaljuWalk)
						H.Returning = false
					end
					sSt.Set(1, "Status: Berhenti")
				end
				task.wait(0.5)
				continue
			end
			local hrp = H.Live()
			if not hrp then task.wait(1) continue end
			if not savedPos then savedPos = hrp.Position end

			local flakes = Flakes()
			sSt.Set(3, "Kepingan di map: " .. #flakes)
			local now = tick()
			local best, bd
			for _, f in ipairs(flakes) do
				if not cool[f.item] or now > cool[f.item] then
					local d = (hrp.Position - f.pos).Magnitude
					if not bd or d < bd then best, bd = f, d end
				end
			end
			if not best then
				sSt.Set(1, "Menunggu kepingan salju muncul...")
				task.wait(1)
				continue
			end

			local item = best.item
			local walk = H.SaljuWalk
			sSt.Set(1, string.format("%s ke kepingan (%d studs)...", walk and "Berjalan" or "Teleport", math.floor(bd)))
			local cancel = function() return not active() or not H.Live() end
			local reached
			if walk then
				reached = H.WalkTo(best.pos, cancel, 2)
			else
				reached = H.TeleportTo(best.pos, cancel, false)
			end
			if not active() then continue end
			if reached == false then
				cool[item] = tick() + 5
				sSt.Set(1, "Tidak terjangkau, coba kepingan lain...")
				continue
			end

			-- cukup menyentuh kepingan: tunggu terklaim, bantu dengan touch jika perlu
			task.wait(0.25)
			if not gone(item) and firetouchinterest then
				local h2 = H.Live()
				if h2 then
					local parts = {}
					if item:IsA("BasePart") then table.insert(parts, item) end
					for _, d in ipairs(item:GetDescendants()) do
						if d:IsA("BasePart") then table.insert(parts, d) end
					end
					for _, part in ipairs(parts) do
						pcall(function()
							firetouchinterest(h2, part, 0)
							firetouchinterest(h2, part, 1)
						end)
					end
				end
			end
			local t0 = tick()
			while not gone(item) and tick() - t0 < 1.5 and active() do task.wait(0.1) end
			if gone(item) then
				Q.Salju += 1
				sSt.Set(2, "Terkumpul sesi ini: " .. Q.Salju .. " Kepingan")
				sSt.Set(1, "Kepingan terklaim!")
			else
				cool[item] = tick() + 5
				sSt.Set(1, "Belum terklaim, coba kepingan lain...")
			end
		end
	end)
end

------------------------------------------------------------------
-- TAB PLAYER (anti AFK, walkspeed, anti petir, teleport)
------------------------------------------------------------------
do
	local RunService = game:GetService("RunService")
	local RS = H.RS

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
	UI.Toggle(PlayerPage, "Anti-AFK", "Cegah kick karena idle.", true, function(v) getgenv().AntiAFKRunning = v end)
	LocalPlayer.Idled:Connect(function()
		if getgenv().AntiAFKRunning then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0, 0))
		end
	end)

	-- anti petir
	UI.Section(PlayerPage, "ANTI PETIR")
	local pSt
	FlagToggle(PlayerPage, "Anti Petir", "Saat hujan siang, menjauh otomatis dari titik sambaran. Payung membuat kebal.", "AntiPetirActive", function(v)
		if not v then pSt.Set(1, "Anti Petir: nonaktif") end
	end)
	pSt = UI.Status(PlayerPage, 1)
	local dodged = 0
	pSt.Set(1, "Menghindar: 0 kali")
	local radius = 9
	pcall(function() radius = require(RS:WaitForChild("SiangConfig", 2)).Hujan.BlastRadius or 9 end)
	radius += 6
	local dangers = {}
	local function HoldingUmbrella()
		local ch = LocalPlayer.Character
		local t = ch and ch:FindFirstChildOfClass("Tool")
		return t ~= nil and t.Name:lower():find("payung") ~= nil
	end
	if H.R.Petir then
		H.Conn(H.R.Petir.OnClientEvent:Connect(function(d)
			if not H.Run() or not getgenv().AntiPetirActive then return end
			if type(d) ~= "table" or not d.w or typeof(d.p) ~= "Vector3" then return end
			table.insert(dangers, {pos = d.p, untilT = tick() + (tonumber(d.t) or 1.35) + 0.5})
			pSt.Set(1, "Petir terdeteksi! Menghindar...")
		end))
	else
		pSt.Set(1, "Remote Petir tidak aktif / tidak ada")
	end
	H.Conn(RunService.Heartbeat:Connect(function()
		if not H.Run() then return end
		if #dangers == 0 then H.PetirDanger = false return end
		if not getgenv().AntiPetirActive then
			table.clear(dangers)
			H.PetirDanger = false
			return
		end
		H.PetirDanger = true
		local hrp = H.Live()
		if not hrp then return end
		local now = tick()
		for i = #dangers, 1, -1 do
			local d = dangers[i]
			if now > d.untilT then
				table.remove(dangers, i)
			elseif not HoldingUmbrella() then
				local diff = hrp.Position - d.pos
				if diff.Magnitude < radius then
					local flat = Vector3.new(diff.X, 0, diff.Z)
					local dir = (flat.Magnitude < 0.5) and Vector3.new(1, 0, 0) or flat.Unit
					hrp.CFrame = CFrame.new(Vector3.new(d.pos.X, hrp.Position.Y, d.pos.Z) + dir * (radius + 2))
					hrp.AssemblyLinearVelocity = Vector3.zero
					dodged += 1
					pSt.Set(1, "Menghindar: " .. dodged .. " kali")
				end
			end
		end
	end))
	task.spawn(function()
		while H.Run() do
			task.wait(1)
			if getgenv().AntiPetirActive and workspace:GetAttribute("Cuaca") == "Hujan" and workspace:GetAttribute("Phase") == "Siang" then
				local ch = LocalPlayer.Character
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 and not ch:FindFirstChildOfClass("Tool") then
					local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
					if bp then
						for _, t in ipairs(bp:GetChildren()) do
							if t:IsA("Tool") and t.Name:lower():find("payung") then
								hum:EquipTool(t)
								break
							end
						end
					end
				end
			end
		end
	end)

	-- teleport
	UI.Section(PlayerPage, "TELEPORT")
	local tpMode = "bertahap"
	local tpBusy = false
	local target = nil
	UI.Segment(PlayerPage, "Mode Teleport", {{key = "bertahap", text = "BERTAHAP"}, {key = "instan", text = "INSTAN"}},
		function() return tpMode end, function(k) tpMode = k end)

	local function GoTo(pos)
		local hrp = H.Live()
		if not hrp then return false end
		if tpMode == "instan" then
			hrp.CFrame = CFrame.new(pos)
		else
			H.FlyFloat(true)
			H.TeleportTo(pos)
			H.FlyFloat(false)
		end
		return true
	end

	UI.Button(PlayerPage, "NPC Pria Misterius", "Pasar Hutan, dekat lampu gantung pasar.", "TELEPORT", function(btn)
		if tpBusy then return end
		if not H.Live() then Flash(btn, "Belum siap", false) return end
		local pos = Vector3.new(1880.5, 114.5, 187.2)
		local npc = workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild("NpcMisterius")
		if npc and npc:IsA("BasePart") then pos = npc.Position + Vector3.new(0, 2, 0) end
		tpBusy = true
		GoTo(pos)
		tpBusy = false
		Flash(btn, "Sampai ✓", true)
	end, C.accent)

	local tpInfo = UI.Status(PlayerPage, 1)
	tpInfo.Set(1, "Pilih pemain dari daftar di bawah:")
	local plist = UI.List(PlayerPage, 130)
	local function RefreshPlayers()
		plist.Clear()
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then table.insert(others, p) end
		end
		table.sort(others, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
		if target and not target.Parent then target = nil end
		if #others == 0 then
			tpInfo.Set(1, "Tidak ada pemain lain di map")
			plist.Done()
			return
		end
		tpInfo.Set(1, target and ("Target: " .. target.DisplayName .. " (@" .. target.Name .. ")") or "Pilih pemain dari daftar di bawah:")
		for _, p in ipairs(others) do
			plist.Add(p.DisplayName .. " (@" .. p.Name .. ")", p == target, function()
				target = p
				RefreshPlayers()
			end, false, 24)
		end
		plist.Done()
	end
	RefreshPlayers()
	H.Conn(Players.PlayerAdded:Connect(function() task.wait(0.5) if H.Run() then RefreshPlayers() end end))
	H.Conn(Players.PlayerRemoving:Connect(function(p)
		if target == p then target = nil end
		task.wait(0.2)
		if H.Run() then RefreshPlayers() end
	end))

	UI.Button(PlayerPage, "Teleport ke Pemain", "Pindah ke pemain yang dipilih.", "TELEPORT", function(btn)
		if tpBusy then return end
		if not target or not target.Parent then Flash(btn, "Pilih pemain", false) return end
		local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if not tr then Flash(btn, "Tidak ada karakter", false) return end
		if not H.Live() then Flash(btn, "Belum siap", false) return end
		tpBusy = true
		GoTo(tr.Position + Vector3.new(0, 2.5, 0))
		tpBusy = false
		Flash(btn, "Sampai ✓", true)
	end, C.good)
end

------------------------------------------------------------------
-- BACKPACK EVENT, OnVerified
------------------------------------------------------------------
do
	local function Wire()
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:WaitForChild("Backpack", 10)
		if not bp then return end
		local function changed()
			task.wait(0.2)
			if not H.Run() then return end
			if H.RefreshSeeds then pcall(H.RefreshSeeds) end
			if Main.Visible and LapakPage.Visible and H.RefreshLapak then pcall(H.RefreshLapak) end
		end
		H.Conn(bp.ChildAdded:Connect(changed))
		H.Conn(bp.ChildRemoved:Connect(changed))
	end
	Wire()
	H.Conn(LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		if not H.Run() then return end
		Wire()
		if H.RefreshSeeds then pcall(H.RefreshSeeds) end
	end))
end

OnVerified = function()
	-- default Pasar Hutan: siram & panen (lahan kecil + besar) aktif setelah key valid
	for _, f in ipairs({"AutoSiramKecilActive", "AutoSiramBesarActive", "AutoPanenKecilActive", "AutoPanenBesarActive"}) do
		getgenv()[f] = true
		local s = ToggleSetters[f]
		if s then pcall(s, true) end
	end
	if H.ResumeLapak and not getgenv().AutoKelolaLapakActive then
		H.ResumeLapak = false
		getgenv().AutoKelolaLapakActive = true
		local s = ToggleSetters["AutoKelolaLapakActive"]
		if s then pcall(s, true) end
	end
end

------------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------------
UI.Section(SettingsPage, "SETTINGS & PERFORMANCE")

UI.Button(SettingsPage, "Stop Semua Fitur", "Matikan semua auto farm, kebun, ternak, dll.", "STOP", function(btn)
	StopAll()
	Flash(btn, "Dihentikan ✓", true)
end, Color3.fromRGB(180, 50, 50))

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
			BlackScreenGui = New("ScreenGui", {Name = "UbeyBlackScreen", DisplayOrder = 999999, IgnoreGuiInset = true, ResetOnSpawn = false}, GuiParent)
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
-- CREDITS
------------------------------------------------------------------
UI.Section(CreditsPage, "CREDITS")
UI.Button(CreditsPage, "Created By UBEY", "Terima kasih sudah memakai " .. HUB_TITLE .. ". Fitur Pasar Hutan by PemudaTampan.", "Discord", function(btn)
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

