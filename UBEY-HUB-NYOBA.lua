-- ==============================================================================
-- UBEY HUB V3 | INFINITE YIELD FE EDITION
-- Sistem key tetap divalidasi di Supabase Edge Function (verify-key).
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

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

local function StopAll()
	getgenv().AutoFishRunning = false
	getgenv().HideNameRunning = false
end

local Lock -- didefinisikan setelah GUI dibuat

------------------------------------------------------------------
-- CONFIG & FILE SAVE
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHubV3_IY_Config.json"
local KEY_FILE = "UbeyHubV3_SavedKey.txt"

local function DefaultConfig()
	return {
		Power = "0.92", ReelDelay = "0", CastDelay = "0.3", BiteTimeout = "15",
		AutoAnim = true, AutoOK = true, AutoEquip = true,
		AntiAdminEnabled = false, TargetGroupId = "0"
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

local function Num(key)
	return tonumber(getgenv().UbeyConfig[key]) or tonumber(DefaultConfig()[key]) or 0
end

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

------------------------------------------------------------------
-- FISHING CORE (Cast / Reel / Server)
------------------------------------------------------------------
getgenv().AutoFishRunning = false
getgenv().HideNameRunning = false
getgenv().AntiAFKRunning = false
getgenv().FakeNameInput = "UBEY HUB"
getgenv().FishLoopId = 0

local function GetRemote(name)
	for _, v in ipairs(game:GetDescendants()) do
		if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
	end
end

local function Fire(r, ...)
	if r:IsA("RemoteEvent") then r:FireServer(...) else r:InvokeServer(...) end
end

local bitten = false
local reelId, failedId = 0, -1

-- Dengarkan event dari server: "Bite" = ikan menggigit, "Failed" = tangkapan gagal
task.spawn(function()
	for _, v in ipairs(game:GetDescendants()) do
		if v.Name == "Server" and v:IsA("RemoteEvent") then
			v.OnClientEvent:Connect(function(evt)
				if evt == "Bite" then
					bitten = true
				elseif evt == "Failed" then
					failedId = reelId
				end
			end)
		end
	end
end)

-- Animasi lempar / tunggu / tarik
local ANIM_FOLDER
for _, v in ipairs(game:GetDescendants()) do
	if v.Name == "Fishing" and v:FindFirstChild("CastingAnimation") then
		ANIM_FOLDER = v
		break
	end
end

local currentTrack
local function StopAnim()
	if currentTrack then pcall(function() currentTrack:Stop(0.1) end) end
	currentTrack = nil
end

local function PlayAnim(name, looped)
	if not getgenv().UbeyConfig.AutoAnim then return end
	StopAnim()
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local anim = ANIM_FOLDER and ANIM_FOLDER:FindFirstChild(name)
	if not (animator and anim) then return end
	local ok, tr = pcall(function() return animator:LoadAnimation(anim) end)
	if ok and tr then
		tr.Looped = looped or false
		tr:Play(0.1)
		currentTrack = tr
	end
end

local function AutoEquipRod()
	pcall(function()
		local character = LocalPlayer.Character
		if not character then return end
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and string.find(string.lower(child.Name), "rod") then return end
		end
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if backpack and humanoid then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and string.find(string.lower(item.Name), "rod") then
					humanoid:EquipTool(item)
					break
				end
			end
		end
	end)
end

local TgFish
local function StartFishingLoop()
	getgenv().FishLoopId = getgenv().FishLoopId + 1
	local myId = getgenv().FishLoopId
	task.spawn(function()
		local Cast, Reel = GetRemote("Cast"), GetRemote("Reel")
		if not (Cast and Reel) then
			getgenv().AutoFishRunning = false
			if TgFish then TgFish.Set(false) end
			return
		end
		while getgenv().AutoFishRunning and getgenv().FishLoopId == myId do
			if not IsVerified() then getgenv().AutoFishRunning = false; break end
			if getgenv().UbeyConfig.AutoEquip then AutoEquipRod() end

			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				bitten = false
				local look = hrp.CFrame.LookVector
				local dir = Vector3.new(look.X, 0, look.Z).Unit
				PlayAnim("CastingAnimation")
				pcall(Fire, Cast, dir, math.clamp(Num("Power"), 0, 1))
				task.delay(0.7, function()
					if getgenv().AutoFishRunning and getgenv().FishLoopId == myId and not bitten then
						PlayAnim("WaitingAnimation", true)
					end
				end)

				local t, timeout = 0, Num("BiteTimeout")
				while not bitten and t < timeout and getgenv().AutoFishRunning and getgenv().FishLoopId == myId do
					task.wait(0.05)
					t = t + 0.05
				end

				if bitten and getgenv().AutoFishRunning and getgenv().FishLoopId == myId then
					local rd = Num("ReelDelay")
					if rd > 0 then task.wait(rd) end
					PlayAnim("PullingAnimation")
					reelId = reelId + 1
					local id = reelId
					pcall(Fire, Reel, true)
					-- hitung ikan: dianggap berhasil jika tidak ada "Failed" dalam 1.5 detik
					task.delay(1.5, function()
						if failedId ~= id then
							getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1
						end
					end)
				end
			end
			task.wait(Num("CastDelay"))
		end
		if getgenv().FishLoopId == myId then StopAnim() end
	end)
end

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
-- AUTO OK (popup Naik Level)
------------------------------------------------------------------
local function IsVisibleGui(o)
	local cur = o
	while cur and cur ~= game do
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		if cur:IsA("ScreenGui") and not cur.Enabled then return false end
		cur = cur.Parent
	end
	return true
end

local function ClickGuiButton(btn)
	local fired = false
	if getconnections then
		for _, sig in ipairs({"MouseButton1Click", "Activated"}) do
			if not fired then
				local okc, list = pcall(getconnections, btn[sig])
				if okc and list then
					for _, c in ipairs(list) do
						if pcall(function() c:Fire() end) then fired = true end
					end
				end
			end
		end
	end
	if not fired and firesignal then
		fired = pcall(firesignal, btn.MouseButton1Click)
	end
	if not fired then
		local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2 + GuiService:GetGuiInset()
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
		task.wait(0.05)
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
	end
end

local function FindLevelUpOK()
	for _, o in ipairs(PlayerGui:GetDescendants()) do
		if o:IsA("TextLabel") or o:IsA("TextButton") then
			local txt = string.upper(o.Text)
			if (txt:find("NAIK LEVEL") or txt:find("LEVEL UP")) and IsVisibleGui(o) then
				local root = o:FindFirstAncestorOfClass("ScreenGui")
				if root and root ~= Gui then
					for _, b in ipairs(root:GetDescendants()) do
						if (b:IsA("TextButton") or b:IsA("TextLabel"))
							and string.upper(b.Text) == "OK" and IsVisibleGui(b) then
							local btn = b:IsA("GuiButton") and b or b:FindFirstAncestorWhichIsA("GuiButton")
							if not btn and b.Parent then
								btn = b.Parent:FindFirstChildWhichIsA("GuiButton", true)
							end
							if btn then return btn end
						end
					end
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		if IsVerified() and getgenv().UbeyConfig.AutoOK then
			local btn = FindLevelUpOK()
			if btn then
				pcall(ClickGuiButton, btn)
				task.wait(1.5)
			end
		end
		task.wait(1)
	end
end)

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
-- 1. FISHING PAGE
------------------------------------------------------------------
UI.Section(FishingPage, "AUTO FISHING")

TgFish = UI.Toggle(FishingPage, "Auto Fishing", "Cast → tunggu Bite → Reel, berulang otomatis.", false, function(v)
	if v and not IsVerified() then return end
	getgenv().AutoFishRunning = v
	if v then
		StartFishingLoop()
	else
		getgenv().FishLoopId = getgenv().FishLoopId + 1
		StopAnim()
	end
end)

local function NumInput(key, title, desc, minV, maxV)
	local box
	box = UI.Input(FishingPage, title, desc, getgenv().UbeyConfig[key], tostring(DefaultConfig()[key]), function(t)
		local n = math.clamp(tonumber(t) or tonumber(DefaultConfig()[key]), minV, maxV)
		getgenv().UbeyConfig[key] = tostring(n)
		box.Text = tostring(n)
		SaveConfig()
	end)
end

NumInput("Power", "Power Cast", "0 - 1 (default 0.92)", 0, 1)
NumInput("ReelDelay", "Jeda Reel", "Detik setelah Bite (0 = instan)", 0, 5)
NumInput("CastDelay", "Jeda Cast", "Detik sebelum lempar lagi", 0, 5)
NumInput("BiteTimeout", "Timeout Bite", "Detik, lempar ulang jika tidak ada Bite", 3, 60)

UI.Toggle(FishingPage, "Animasi Lempar", "Putar animasi cast, tunggu, dan tarik.", getgenv().UbeyConfig.AutoAnim, function(v)
	getgenv().UbeyConfig.AutoAnim = v
	if not v then StopAnim() end
	SaveConfig()
end)

UI.Toggle(FishingPage, "Auto Equip Rod", "Pegang pancingan otomatis jika belum dipegang.", getgenv().UbeyConfig.AutoEquip, function(v)
	getgenv().UbeyConfig.AutoEquip = v
	SaveConfig()
end)

UI.Toggle(FishingPage, "Auto OK Level Up", "Tekan OK otomatis saat popup Naik Level muncul.", getgenv().UbeyConfig.AutoOK, function(v)
	getgenv().UbeyConfig.AutoOK = v
	SaveConfig()
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
UI.Section(PrivacyPage, "PRIVACY & ANTI-ADMIN")
UI.Input(PrivacyPage, "Nama Samaran", "Dipakai saat Privacy Mode aktif", "UBEY HUB", "UBEY HUB", function(t)
	getgenv().FakeNameInput = t
end)

UI.Toggle(PrivacyPage, "Privacy Mode (Hide Name)", "Ganti nama di atas kepala dengan nama samaran.", false, function(v)
	if v and not IsVerified() then return end
	getgenv().HideNameRunning = v
	if v then
		task.spawn(function()
			while getgenv().HideNameRunning do
				if not IsVerified() then getgenv().HideNameRunning = false; break end
				pcall(function()
					local fakeName = getgenv().FakeNameInput or "UBEY HUB"
					local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
					if head then
						for _, child in ipairs(head:GetDescendants()) do
							if child:IsA("TextLabel") or child:IsA("TextMesh") then
								local txt = child.Text
								if string.find(txt, LocalPlayer.Name) or string.find(txt, LocalPlayer.DisplayName) then
									child.Text = fakeName
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
