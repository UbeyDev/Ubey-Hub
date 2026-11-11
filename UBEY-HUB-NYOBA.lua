-- ==============================================================================
-- UBEY HUB V3 | NEW GUI + FORT KNOX SECURE KEY SYSTEM + FLOATING LOGO
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [SECURITY LAYER 1] Menyembunyikan Status Verifikasi di dalam Metatable rahasia
-- Orang tidak bisa sekadar mengetik "IsKeyVerified = true" di console
local SecureData = setmetatable({}, {
	__index = function(t, k)
		if k == "IsKeyVerified" then return rawget(t, "_verified") end
	end,
	__newindex = function(t, k, v)
		if k == "IsKeyVerified" then rawset(t, "_verified", v) end
	end
})
SecureData.IsKeyVerified = false

-- ====== PENGATURAN TAMPILAN ======
local HUB_TITLE = "UBEY HUB"
local HUB_DISCORD = "discord.gg/YXuYeEpnXE"
local DISCORD_LINK = "https://discord.gg/YXuYeEpnXE"
local LOGO_ASSET = "rbxassetid://90770802417381"
-- ================================================

getgenv().TotalFishCaught = 0
getgenv().SessionStartTime = os.time()

------------------------------------------------------------------
-- CONFIG & FILE SAVE
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHubV3_Config.json"
local KEY_FILE = "UbeyHubV3_SavedKey.txt"

local function DefaultConfig()
	return {
		BiteDelay = "0.5", TapDelay = "0.12", MinigameMode = "Legit",
		SelectedSpot = "Spot Mancing Core", AutoSellTimer = "5",
		AntiAdminEnabled = false, TargetGroupId = 7019573,
		WebhookEnabled = false, WebhookUrl = ""
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
		getgenv().BiteDelayInput = getgenv().UbeyConfig.BiteDelay
		getgenv().AutoSellTimerInput = getgenv().UbeyConfig.AutoSellTimer
		getgenv().SelectedFishingSpot = getgenv().UbeyConfig.SelectedSpot
		SecureData.IsKeyVerified = false
		if delfile and isfile then
			if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
			if isfile(KEY_FILE) then delfile(KEY_FILE) end
		end
	end)
end

LoadConfig()

------------------------------------------------------------------
-- SUPABASE & HWID
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

local function GetRequestFunc()
	return (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
end

------------------------------------------------------------------
-- DISCORD WEBHOOK
------------------------------------------------------------------
local function SendServerWideWebhook(playerName, catchType, position)
	pcall(function()
		if not getgenv().UbeyConfig.WebhookEnabled then return end
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then return end

		local typeLower = string.lower(tostring(catchType))
		local targetPlayer = tostring(playerName or "Unknown Player")

		if string.find(typeLower, "secret") or string.find(typeLower, "forgotten") or string.find(typeLower, "core") or string.find(typeLower, "mythical") then
			local requestFunc = GetRequestFunc()
			if not requestFunc then return end

			local embedTitle = "👑 Ubey Hub V3 - Server Rare Catch Tracker!"
			local alertContent = string.format("@everyone 🚨 **%s Berhasil Mendapatkan Tangkapan Langka!**", targetPlayer)
			local embedColor = 16711935

			if string.find(typeLower, "core") then
				alertContent = string.format("@everyone ⚡ **%s Mendapatkan Withering Core!**", targetPlayer)
				embedTitle = "💎 Ubey Hub V3 - Core Event Tracker!"
				embedColor = 16776960
			end

			local posStr = position and string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z) or "N/A"
			local data = {
				["content"] = alertContent,
				["embeds"] = {{
					["title"] = embedTitle,
					["description"] = string.format("Pemain **%s** di dalam server ini baru saja mendapatkan item spesial!", targetPlayer),
					["color"] = embedColor,
					["fields"] = {
						{ ["name"] = "👤 Nama Player", ["value"] = targetPlayer, ["inline"] = true },
						{ ["name"] = "🎯 Tipe Tangkapan", ["value"] = tostring(catchType), ["inline"] = true },
						{ ["name"] = "📍 Koordinat", ["value"] = posStr, ["inline"] = true }
					},
					["footer"] = { ["text"] = "Ubey Hub V3 • Server-Wide Broadcast Monitor" },
					["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
				}}
			}
			requestFunc({
				Url = url, Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(data)
			})
		end
	end)
end

task.spawn(function()
	pcall(function()
		local r = ReplicatedStorage:FindFirstChild("CutsceneBroadcast")
		if r and r:IsA("RemoteEvent") then
			r.OnClientEvent:Connect(function(catchType, position, targetPlayer)
				SendServerWideWebhook(targetPlayer and targetPlayer.Name or "Unknown Player", catchType, position)
			end)
		end
	end)
end)

------------------------------------------------------------------
-- CATCH MONITOR
------------------------------------------------------------------
local hookedRemotes = {}
local function ProcessNotifyClient(actionType)
	if type(actionType) ~= "string" then return end
	if actionType == "GotFish" then
		pcall(function() getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1 end)
	end
end

local function AttachNotifyHook(remote)
	if remote and remote:IsA("RemoteEvent") and not hookedRemotes[remote] then
		hookedRemotes[remote] = true
		remote.OnClientEvent:Connect(ProcessNotifyClient)
	end
end

local function ScanContainerForNotify(container)
	if not container then return end
	for _, v in ipairs(container:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then AttachNotifyHook(v) end
	end
end

local function ListenToFishCatch()
	pcall(function()
		ScanContainerForNotify(ReplicatedStorage)
		ReplicatedStorage.DescendantAdded:Connect(function(v)
			if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then AttachNotifyHook(v) end
		end)
		local function ScanCharacter(char)
			if not char then return end
			ScanContainerForNotify(char)
			char.DescendantAdded:Connect(function(v)
				if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then AttachNotifyHook(v) end
			end)
		end
		if LocalPlayer.Character then ScanCharacter(LocalPlayer.Character) end
		LocalPlayer.CharacterAdded:Connect(ScanCharacter)
	end)
end
task.spawn(function() task.wait(1); ListenToFishCatch() end)

------------------------------------------------------------------
-- AUTO EQUIP ROD
------------------------------------------------------------------
local function AutoEquipRod()
	pcall(function()
		local character = LocalPlayer.Character
		if not character then return end
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and (string.find(string.lower(child.Name), "rod") or string.find(string.lower(child.Name), "pancing")) then return end
		end
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if backpack and humanoid then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") then
					local n = string.lower(item.Name)
					if string.find(n, "rod") or string.find(n, "pancing") then
						humanoid:EquipTool(item)
						break
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------
-- AUTO FISHING & TAP CLICKER
------------------------------------------------------------------
local function EnableGameAutoFishing(state)
	if state == nil then state = true end
	local fired = false
	pcall(function()
		local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing")
		local r = mancing and (mancing:FindFirstChild("Auto") or mancing:FindFirstChild("AutoFishing"))
		if r and r:IsA("RemoteEvent") then
			r:FireServer(state)
			fired = true
		end
	end)
	return fired
end

local function ClickGameAutoButton()
	pcall(function()
		local hub = PlayerGui:FindFirstChild("UbeyHub")
		for _, v in ipairs(PlayerGui:GetDescendants()) do
			if (v:IsA("TextButton") or v:IsA("ImageButton")) and not (hub and v:IsDescendantOf(hub)) then
				local n = string.lower(v.Name)
				local t = v:IsA("TextButton") and string.lower(v.Text) or ""
				if string.find(n, "auto") or string.find(t, "auto") then
					if firesignal then
						pcall(function() firesignal(v.MouseButton1Click) end)
						if v.Activated then pcall(function() firesignal(v.Activated) end) end
					elseif getconnections then
						pcall(function() for _, c in ipairs(getconnections(v.MouseButton1Click)) do c:Fire() end end)
					end
					return
				end
			end
		end
	end)
end

local function PerformTapClicker()
	local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
	if isMobile then
		pcall(function()
			local char = LocalPlayer.Character
			local tool = char and char:FindFirstChildOfClass("Tool")
			if tool then tool:Activate() end
		end)
		return
	end
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	local mousePos = UIS:GetMouseLocation()
	local pos = (mousePos.X > 0 and mousePos.Y > 0) and mousePos or Vector2.new(vp.X * 0.5, vp.Y * 0.5)
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
		task.wait(0.02)
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
	end)
end

-- AUTO RECONNECT
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

-- GLOBAL STATES
getgenv().AutoFishingEventRunning = false
getgenv().BiteDelayInput = getgenv().UbeyConfig.BiteDelay
getgenv().SelectedFishingSpot = getgenv().UbeyConfig.SelectedSpot
getgenv().AutoSellRunning = false
getgenv().AutoSellTimerInput = getgenv().UbeyConfig.AutoSellTimer
getgenv().AutoGalatamaRunning = false
getgenv().AutoSummitRunning = false
getgenv().AntiAFKRunning = false
getgenv().HideNameRunning = false
getgenv().FakeNameInput = "UBEY HUB"
getgenv().CurrentSelectedHalo = nil
getgenv().AutoDetectCoreEvent = false

local FishingSpots = {
	["Spot Mancing Core"] = CFrame.new(-9069.33887, 1250.32092, -6510.3374, 0.99812746, -7.96398965e-08, -0.0611686334, 8.05492206e-08, 1, 1.24000188e-08, 0.0611686334, -1.73038845e-08, 0.99812746),
	["Spot Mancing Ikan Anomali"] = CFrame.new(-8199.52832, 1238.83752, -6278.13135, -0.999144316, 1.1644854e-08, -0.0413601957, 1.63464247e-08, 1, -1.13335595e-07, 0.0413601957, -1.13914709e-07, -0.999144316)
}
local SpotNames = {"Spot Mancing Core", "Spot Mancing Ikan Anomali"}

if not FishingSpots[getgenv().SelectedFishingSpot] then
	getgenv().SelectedFishingSpot = "Spot Mancing Core"
	getgenv().UbeyConfig.SelectedSpot = "Spot Mancing Core"
end

local NpcSellCFrame = CFrame.new(-6668.01416, 1312.69983, -9965.2998, 0.999977231, 1.08366018e-08, -0.00675115408, -1.09201403e-08, 1, -1.2337189e-08, 0.00675115408, 1.24106316e-08, 0.999977231)

local function GetEquippedRod()
	local char = LocalPlayer.Character
	if not char then return nil end
	local rod = char:FindFirstChild("Withering Rod")
	if rod then return rod end
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Tool") and c:FindFirstChild("Mechanics") then return c end
	end
	return nil
end

-- ROD SETTINGS
local OriginalRodValues = {}
local function OptimizeRodSettings()
	pcall(function()
		local rod = GetEquippedRod()
		local s = rod and rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Settings")
		if not s then return end
		local t = s:FindFirstChild("Time_before_getfish")
		if t then
			if OriginalRodValues[t] == nil then OriginalRodValues[t] = t.Value end
			t.Value = 0.05
		end
		local m = s:FindFirstChild("EnableMiniGame")
		if m then
			if OriginalRodValues[m] == nil then OriginalRodValues[m] = m.Value end
			m.Value = false
		end
	end)
end

local function RestoreRodSettings()
	pcall(function()
		for inst, val in pairs(OriginalRodValues) do
			if inst and inst.Parent then inst.Value = val end
			OriginalRodValues[inst] = nil
		end
	end)
end

local function RunAutoFishCycle(remoteFolder)
	if not remoteFolder then return end
	pcall(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local castEvt = remoteFolder:FindFirstChild("CastEvent")
		local notifyEvt = remoteFolder:FindFirstChild("NotifyClient")
		local miniEvt = remoteFolder:FindFirstChild("MiniGame")
		if not castEvt or not notifyEvt then return end
		OptimizeRodSettings()
		castEvt:FireServer(true)
		task.wait(0.05)
		castEvt:FireServer(false, 100, hrp.CFrame.LookVector)
		local hooked = false
		local conn = notifyEvt.OnClientEvent:Connect(function(actionType)
			if type(actionType) ~= "string" then return end
			if actionType == "Bite" or actionType == "Hook" then hooked = true end
		end)
		local start = tick()
		while not hooked and getgenv().AutoFishingEventRunning and getgenv().UbeyConfig.MinigameMode == "Instant" do
			if tick() - start > 8 then break end
			task.wait(0.05)
		end
		if conn then conn:Disconnect() end

		if hooked and getgenv().AutoFishingEventRunning and getgenv().UbeyConfig.MinigameMode == "Instant" then
			task.wait(tonumber(getgenv().BiteDelayInput) or 0.5)
			if getgenv().UbeyConfig.MinigameMode ~= "Instant" then return end
			local tandaSeruRemote = remoteFolder:FindFirstChild("TandaSeruBersama")
			if tandaSeruRemote then
				local color1 = Color3.fromRGB(23, 255, 151)
				local color2 = Color3.fromRGB(20, 20, 20)
				local seq = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color1)})
				tandaSeruRemote:FireServer(color1, color2, seq, 1.5)
			end
			task.wait(0.1)
			if getgenv().UbeyConfig.MinigameMode ~= "Instant" then return end
			if miniEvt then miniEvt:FireServer(true) end
			task.wait(0.3)
		end
	end)
end

getgenv().FishLoopId = 0
local function StartFishingLoop()
	getgenv().FishLoopId = getgenv().FishLoopId + 1
	local myId = getgenv().FishLoopId
	task.spawn(function()
		local lastAuto, clickedGui, restored = 0, false, false
		while getgenv().AutoFishingEventRunning and getgenv().FishLoopId == myId do
			if not SecureData.IsKeyVerified then getgenv().AutoFishingEventRunning = false; break end
			local mode = getgenv().UbeyConfig.MinigameMode or "Legit"
			AutoEquipRod()
			if mode == "Legit" then
				if not restored then
					restored = true
					RestoreRodSettings()
					lastAuto = 0
				end
				if tick() - lastAuto > 10 then
					lastAuto = tick()
					local viaRemote = EnableGameAutoFishing(true)
					if not viaRemote and not clickedGui then
						clickedGui = true
						ClickGameAutoButton()
					end
				end
				PerformTapClicker()
				task.wait(tonumber(getgenv().UbeyConfig.TapDelay) or 0.12)
			else
				restored = false
				pcall(function()
					local rod = GetEquippedRod()
					local rf = rod and rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Remotes")
					if rf then RunAutoFishCycle(rf) else task.wait(1) end
				end)
				task.wait(0.1)
			end
		end
		if getgenv().FishLoopId == myId and (getgenv().UbeyConfig.MinigameMode or "Legit") == "Legit" then
			EnableGameAutoFishing(false)
		end
	end)
end

local function TriggerSellToNpc()
	pcall(function()
		local character = LocalPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local currentSpotCFrame = hrp.CFrame
		hrp.CFrame = NpcSellCFrame + Vector3.new(0, 5, 0)
		task.wait(0.8)
		local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing")
		local jualSemua = mancing and mancing:FindFirstChild("JualSemua")
		if jualSemua then jualSemua:InvokeServer() end
		task.wait(0.8)
		if hrp and hrp.Parent then hrp.CFrame = currentSpotCFrame end
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
			StatLabel.Text = string.format("📡 %d ms  |  🐟 %d  |  ⏱ %s", ping, getgenv().TotalFishCaught, t)
		end)
		task.wait(1)
	end
end)

-- [SECURITY LAYER 2] ANTI-TAMPER (Jebakan Penghapus GUI)
-- Jika GUI Key atau GUI Utama dihapus paksa oleh hacker (Destroy), fitur otomatis mati & hancur.
task.spawn(function()
	while true do
		task.wait(2)
		if not KeyFrame or not KeyFrame.Parent then
			-- Seseorang menghapus GUI Key!
			SecureData.IsKeyVerified = false
			getgenv().AutoFishingEventRunning = false
			getgenv().AutoSummitRunning = false
			getgenv().AutoSellRunning = false
			if Main and Main.Parent then
				Main:Destroy() -- Hancurkan GUI utama agar tidak bisa dipakai
			end
			break
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

function UI.Dropdown(page, title, desc, options, current, onSelect)
	local card = Card(page)
	card.ClipsDescendants = true
	CardText(card, title, desc, 220)
	local head = New("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54)}, card)
	local val = Label(head, tostring(current) .. " ▾", 11, C.accent, Enum.Font.GothamBold, UDim2.new(1, -212, 0, 0), UDim2.new(0, 200, 1, 0), Enum.TextXAlignment.Right)
	local holder = New("Frame", {Position = UDim2.new(0, 8, 0, 58), Size = UDim2.new(1, -16, 0, #options * 30), BackgroundTransparency = 1}, card)
	New("UIListLayout", {Padding = UDim.new(0, 4)}, holder)
	local open = false
	local function setOpen(v)
		open = v
		TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
			Size = UDim2.new(1, -4, 0, open and (62 + #options * 30) or 54)
		}):Play()
	end
	head.MouseButton1Click:Connect(function() setOpen(not open) end)
	for _, opt in ipairs(options) do
		local o = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.bg, Text = "  " .. opt, TextColor3 = C.text,
			Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left
		}, holder)
		Round(o, 8)
		o.MouseButton1Click:Connect(function()
			val.Text = opt .. " ▾"
			setOpen(false)
			task.spawn(onSelect, opt)
		end)
	end
	return {SetValue = function(t) val.Text = tostring(t) .. " ▾" end}
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
-- TABS SETUP
------------------------------------------------------------------
local FishingPage = UI.Tab("Fishing & Sell", "🎣")
local GalatamaPage = UI.Tab("Galatama", "🏆")
local SummitPage = UI.Tab("Summit", "⛰️")
local PlayerPage = UI.Tab("Player", "⚡")
local HaloPage = UI.Tab("Halo", "👑")
local PlayerTpPage = UI.Tab("TP Player", "👥")
local PrivacyPage = UI.Tab("Privacy", "🛡️")
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
		local requestFunc = GetRequestFunc()
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
		local isActive = true 

		if record.status ~= nil then
			local s = tostring(record.status):lower()
			if s == "false" or s == "inactive" or s == "used" then isActive = false end
		elseif record.active ~= nil then
			local a = tostring(record.active):lower()
			if a == "false" or a == "inactive" or a == "used" then isActive = false end
		end

		if not isActive then
			KeyFail(isAutoLogin, "Key sudah tidak aktif / kadaluwarsa!")
			return
		end

		if record.roblox_username and record.roblox_username ~= "" then
			if not CheckUsernameInList(record.roblox_username, currentUser) then
				KeyFail(isAutoLogin, "Username (" .. currentUser .. ") tidak terdaftar pada key ini!")
				return
			end
		else
			PatchKey(requestFunc, enteredKey, {roblox_username = currentUser})
		end

		if record.hwid and record.hwid ~= "" then
			if record.hwid ~= CurrentHWID then
				KeyFail(isAutoLogin, "Key terikat di perangkat (HWID) lain!")
				return
			end
		else
			PatchKey(requestFunc, enteredKey, {hwid = CurrentHWID})
		end

		pcall(function() if writefile then writefile(KEY_FILE, enteredKey) end end)
		
		-- [SECURITY LAYER 3] Set Status Verifikasi
		SecureData.IsKeyVerified = true
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
UI.Section(FishingPage, "AUTO FISHING & SELL")

local SpotDD = UI.Dropdown(FishingPage, "Spot Mancing", "Lokasi teleport saat Smart Auto Fishing + Teleport",
	SpotNames, getgenv().SelectedFishingSpot or SpotNames[1], function(name)
		getgenv().SelectedFishingSpot = name
		getgenv().UbeyConfig.SelectedSpot = name
		SaveConfig()
	end)
local function SetSpotDisplay(text) SpotDD.SetValue(text) end

UI.Dropdown(FishingPage, "Mode Fishing", "Legit = auto bawaan + tap  |  Instant = bypass cepat",
	{"Legit", "Instant"}, getgenv().UbeyConfig.MinigameMode or "Legit", function(value)
		local oldMode = getgenv().UbeyConfig.MinigameMode
		getgenv().UbeyConfig.MinigameMode = value
		SaveConfig()
		if oldMode ~= value then
			task.spawn(function()
				local wasRunning = getgenv().AutoFishingEventRunning
				getgenv().FishLoopId = getgenv().FishLoopId + 1
				EnableGameAutoFishing(false)
				task.wait(0.6)
				RestoreRodSettings()
				pcall(function()
					local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum:UnequipTools() end
				end)
				task.wait(0.4)
				AutoEquipRod()
				if wasRunning and getgenv().AutoFishingEventRunning then StartFishingLoop() end
			end)
		end
	end)

UI.Toggle(FishingPage, "Smart Auto Fishing + Teleport", "Teleport ke spot terpilih lalu mulai memancing.", false, function(v)
	if v and not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	getgenv().AutoFishingEventRunning = v
	if v then
		pcall(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)
			if hrp then hrp.CFrame = FishingSpots[getgenv().SelectedFishingSpot] + Vector3.new(0, 5, 0) end
		end)
		StartFishingLoop()
	end
end)

UI.Toggle(FishingPage, "Smart Auto Fishing (Di Tempat)", "Memancing di posisi sekarang tanpa teleport.", false, function(v)
	if v and not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	getgenv().AutoFishingEventRunning = v
	if v then StartFishingLoop() end
end)

UI.Input(FishingPage, "Bite Delay", "Detik, mode Instant", getgenv().UbeyConfig.BiteDelay, "0.5", function(t)
	getgenv().BiteDelayInput = t
	getgenv().UbeyConfig.BiteDelay = t
	SaveConfig()
end)

UI.Input(FishingPage, "Jeda Tap", "Detik, mode Legit", getgenv().UbeyConfig.TapDelay or "0.12", "0.12", function(t)
	getgenv().UbeyConfig.TapDelay = t
	SaveConfig()
end)

UI.Toggle(FishingPage, "Auto Sell ke NPC", "Teleport ke NPC lalu jual semua ikan sesuai timer.", false, function(v)
	if v and not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	getgenv().AutoSellRunning = v
	if v then
		task.spawn(function()
			local lastSellTime = tick()
			while getgenv().AutoSellRunning do
				if not SecureData.IsKeyVerified then getgenv().AutoSellRunning = false; break end
				task.wait(1)
				if ((tick() - lastSellTime) / 60) >= (tonumber(getgenv().AutoSellTimerInput) or 5) then
					TriggerSellToNpc()
					lastSellTime = tick()
				end
			end
		end)
	end
end)

UI.Input(FishingPage, "Jeda Jual", "Menit", getgenv().UbeyConfig.AutoSellTimer, "5", function(t)
	getgenv().AutoSellTimerInput = t
	getgenv().UbeyConfig.AutoSellTimer = t
	SaveConfig()
end)

------------------------------------------------------------------
-- 2. GALATAMA PAGE
------------------------------------------------------------------
UI.Section(GalatamaPage, "GALATAMA & CORE EVENT")
UI.Button(GalatamaPage, "Teleport ke Galatama", "Pindah ke lokasi Galatama.", "Teleport", function()
	if not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-8008.12744, 1227.96838, -6091.92627) + Vector3.new(0, 5, 0) end)
end)

UI.Toggle(GalatamaPage, "Auto Join Galatama", "Ikut Galatama otomatis tiap 10 detik.", false, function(v)
	if v and not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	getgenv().AutoGalatamaRunning = v
	if v then
		task.spawn(function()
			while getgenv().AutoGalatamaRunning do
				if not SecureData.IsKeyVerified then getgenv().AutoGalatamaRunning = false; break end
				pcall(function()
					local r = ReplicatedStorage:FindFirstChild("Remote")
						and ReplicatedStorage.Remote:FindFirstChild("Glatama")
						and ReplicatedStorage.Remote.Glatama:FindFirstChild("Ikut")
					if r then r:InvokeServer() end
				end)
				task.wait(10)
			end
		end)
	end
end)

UI.Section(GalatamaPage, "AUTO DETECT WITHERING CORE EVENT", C.warn)
UI.Toggle(GalatamaPage, "Auto Teleport Saat Event Core", "Pindah ke Spot Core saat event berlangsung.", false, function(v) 
	if v and not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	getgenv().AutoDetectCoreEvent = v 
end)

local SavedPreviousSpot, IsAtCoreEvent = nil, false
task.spawn(function()
	while true do
		if getgenv().AutoDetectCoreEvent then
			pcall(function()
				if not SecureData.IsKeyVerified then getgenv().AutoDetectCoreEvent = false; return end -- [SECURE CHECK]
				local currentMinute = tonumber(os.date("%M"))
				local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if currentMinute <= 10 then
					if not IsAtCoreEvent then
						SavedPreviousSpot = getgenv().SelectedFishingSpot
						IsAtCoreEvent = true
					end
					getgenv().SelectedFishingSpot = "Spot Mancing Core"
					SetSpotDisplay("Spot Mancing Core (⚡ Event)")
					local target = FishingSpots["Spot Mancing Core"]
					if hrp and target and (hrp.Position - target.Position).Magnitude > 20 then
						hrp.CFrame = target + Vector3.new(0, 5, 0)
					end
				elseif IsAtCoreEvent then
					IsAtCoreEvent = false
					if SavedPreviousSpot and FishingSpots[SavedPreviousSpot] then
						getgenv().SelectedFishingSpot = SavedPreviousSpot
						SetSpotDisplay(SavedPreviousSpot)
						if hrp then hrp.CFrame = FishingSpots[SavedPreviousSpot] + Vector3.new(0, 5, 0) end
					end
				end
			end)
		end
		task.wait(5)
	end
end)

------------------------------------------------------------------
-- 3. SUMMIT PAGE
------------------------------------------------------------------
UI.Section(SummitPage, "AUTO SUMMIT FARM (INSTANT TP)")

local SUMMIT_DELAY = 1.5
local SUMMIT_CP_HEIGHT = 1.5
local SUMMIT_MID_HEIGHT = 6
local BC_CFRAME = CFrame.new(-6830.49854, 1315.599, -9845.91797, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local FINISH_CFRAME = CFrame.new(-6766.44629, 1320.69983, -10083.8037)

local SummitPoints = {
	{"Cp1", CFrame.new(464.845001, 452.719116, -8948.57227, 0.997986674, 0.00330765732, -0.063337639, 5.851164e-10, 0.998639166, 0.0521515608, 0.0634239465, -0.0520465635, 0.996628582)},
	{"Tengah 1", CFrame.new(474.590057, 447.956573, -9159.24023, 0.999968529, -0.000852574885, -0.00788716134, -1.21188393e-10, 0.994208276, -0.107470497, 0.0079331072, 0.107467115, 0.994176984)},
	{"Cp2", CFrame.new(451.694855, 499.646576, -9572.44434, 0.99949652, 0.000553500664, 0.0317238159, 1.04904453e-10, 0.999847829, -0.0174448304, -0.0317286439, 0.0174360462, 0.999344409)},
	{"Tengah 2", CFrame.new(445.483307, 621.606934, -9778.32324, 0.997986615, -0.0062114615, 0.0631198436, 2.39959358e-10, 0.995192885, 0.0979343653, -0.0634247363, -0.0977371857, 0.993189156)},
	{"Cp3", CFrame.new(397.967834, 639.463623, -10116.7002, 0.999716818, -0.000510056969, -0.02379141, 4.97792363e-11, 0.999770284, -0.0214337762, 0.0237968769, 0.0214277059, 0.999487162)},
	{"Tengah 3", CFrame.new(395.853546, 635.549683, -10386.791, 0.999716818, 0.00315287593, -0.0235871132, 5.91942884e-10, 0.991184175, 0.132491052, 0.0237969011, -0.132453531, 0.990903497)},
	{"Cp4", CFrame.new(489.159821, 642.277039, -10681.7002, -0.0475802682, 0.0602015518, -0.997051597, 1.55177843e-10, 0.998182118, 0.060269814, 0.998867393, 0.00286765373, -0.0474937744)},
	{"Tengah 4", CFrame.new(956.084595, 697.091187, -10802.7363, 0.795761228, -0.0310973153, -0.604811549, -1.72196937e-10, 0.99868077, -0.0513487086, 0.60561049, 0.0408613123, 0.794711471)},
	{"Cp5", CFrame.new(1086.91284, 731.401855, -11160.585, 0.998458445, 0.000272808335, 0.0555039383, 3.18766229e-11, 0.9999879, -0.00491505768, -0.0555046089, 0.00490748091, 0.998446345)},
	{"Tengah 5", CFrame.new(1057.28174, 733.071716, -11465.1123, 0.986154497, 0.0050284788, -0.165753007, 1.63842329e-09, 0.99954015, 0.030323239, 0.165829256, -0.0299033988, 0.985700965)},
	{"Cp6", CFrame.new(971.530334, 740.581787, -11810.3145, 0.126592144, -0.0387375578, 0.991198182, 2.35382769e-10, 0.99923718, 0.0390517339, -0.991954863, -0.00494364277, 0.126495585)},
	{"Tengah 6", CFrame.new(691.74884, 797.521545, -11823.7451, 0.0396752357, -0.102132671, 0.993979275, -7.48076157e-10, 0.99476254, 0.102213152, -0.999212623, -0.00405533146, 0.0394674353)},
	{"Cp7", CFrame.new(388.335876, 895.511658, -11840.2939, 0.0238173455, -0.0717899501, 0.997135341, -6.08690737e-11, 0.997418284, 0.07181032, -0.999716341, -0.0017103313, 0.0237558559)},
	{"Tengah 7", CFrame.new(49.462944, 888.104858, -11861.6387, -0.34944579, -0.19423911, 0.916601777, -3.19386761e-09, 0.978275597, 0.207308546, -0.936956584, 0.0724430978, -0.341854304)},
	{"Cp8", CFrame.new(-328.146729, 853.138916, -11739.3906, 0.00795334298, -0.0638618842, 0.99792707, -8.82961412e-11, 0.997958601, 0.0638639033, -0.99996835, -0.000507931632, 0.00793710724)},
	{"Tengah 8", CFrame.new(-586.720459, 854.341248, -11757.834, -0.0317074656, -0.143703595, 0.989112675, -3.78500481e-10, 0.989610255, 0.14377588, -0.999497175, 0.00455876859, -0.0313780345)},
	{"Cp9", CFrame.new(-873.571655, 857.913574, -11736.6006, -0.0475608706, -0.0613531955, 0.996982336, -8.74402217e-11, 0.998111844, 0.0614227057, -0.998868346, 0.00292131724, -0.0474710688)},
	{"Tengah 9", CFrame.new(-1278.78198, 862.183228, -11790.2275, 0.987442195, -0.0267404672, 0.155701235, 5.12804066e-09, 0.985570729, 0.169264019, -0.157980785, -0.167138427, 0.973194122)},
	{"Cp10", CFrame.new(-1282.57056, 863.854065, -12096.4014, 0.999212563, 5.95095444e-05, -0.0396771468, -1.05802248e-12, 0.999998868, 0.00149984262, 0.0396771915, -0.00149866159, 0.999211431)},
	{"Tengah 10", CFrame.new(-1163.88379, 880.556641, -12491.4229, 0.999716282, 0.00329811801, -0.0235888157, 4.36980556e-11, 0.990366638, 0.138470113, 0.0238182656, -0.138430834, 0.990085661)},
	{"Cp11", CFrame.new(-1314.84912, 896.930481, -12835.1504, -0.0317075849, -0.0382487178, 0.998765051, -2.9176847e-10, 0.999267519, 0.0382679589, -0.999497175, 0.00121338433, -0.0316843614)},
	{"Tengah 11", CFrame.new(-1935.85815, 918.891724, -12822.8037, 0.0555249788, -0.118038259, 0.991455495, 5.07237197e-10, 0.992987335, 0.118220635, -0.998457313, -0.0065641976, 0.0551356003)},
	{"Cp12", CFrame.new(-2322.29541, 919.173645, -12668.2285, -0.99745357, 0.00879278593, -0.0707743391, -2.61384775e-10, 0.992370784, 0.123289101, 0.0713184401, 0.122975156, -0.989843845)},
	{"Tengah 12", CFrame.new(-2335.94287, 919.825073, -12331.4092, -0.999212563, 0.000273454934, 0.0396762192, 4.04826658e-11, 0.999976277, -0.00689199753, -0.0396771617, -0.00688657025, -0.99918884)},
	{"Cp13", CFrame.new(-2311.24023, 923.90979, -11851.917, -0.99745059, -0.00294975913, 0.0712991208, -1.04126284e-10, 0.999145269, 0.0413362421, -0.0713601112, 0.0412308611, -0.996598065)},
	{"Tengah 13", CFrame.new(-2340.36206, 951.430298, -11351.1699, -0.999497175, 0.00360921631, -0.03150158, -6.74113487e-10, 0.993500471, 0.113827907, 0.0317076631, 0.113770671, -0.993000925)},
	{"Cp14", CFrame.new(-2448.27344, 964.254089, -11057.0312, 0.0476028472, -0.0647127628, 0.996767879, 3.43433559e-10, 0.997899175, 0.0647862107, -0.99886632, -0.00308400765, 0.0475028418)},
	{"Tengah 14", CFrame.new(-3044.74292, 981.493469, -11030.8037, 0.0238184482, -0.0852627605, 0.996073782, -5.87034976e-10, 0.996356428, 0.08528696, -0.999716282, -0.00203140359, 0.0237316638)},
	{"Cp15", CFrame.new(-3483.43945, 988.503296, -11013.0811, 0.0396763459, -0.0475526191, 0.998080432, -1.16498686e-10, 0.998866975, 0.0475900918, -0.999212563, -0.00188820099, 0.0396313891)},
	{"Tengah 15", CFrame.new(-3854.48242, 985.936829, -11009.2061, -0.0950342268, -0.142578945, 0.985210478, -2.72903367e-09, 0.989689827, 0.14322719, -0.995473981, 0.0136114825, -0.0940544084)},
	{"Cp16", CFrame.new(-4231.1875, 1006.55963, -11017.707, 0.0950784385, -0.0579245724, 0.993783116, -6.25444918e-10, 0.998305619, 0.0581881776, -0.995469809, -0.00553244166, 0.0949173421)},
	{"Tengah 16", CFrame.new(-4490.48242, 1038.65771, -11328.7051, 0.990922332, -0.00802882854, 0.134195656, -4.68678207e-10, 0.99821502, 0.0597224832, -0.134435624, -0.0591803417, 0.989153564)},
	{"Cp17", CFrame.new(-4655.4458, 1085.97107, -11667.3447, -0.110815927, 0.02199829, 0.993597448, 2.2579081e-11, 0.999755025, -0.0221346188, -0.993840933, -0.00245286827, -0.110788777)},
	{"Tengah 17", CFrame.new(-5027.59277, 1094.36035, -11674.2949, 0.0238194466, -0.060855411, 0.997862339, -6.60101834e-11, 0.998145521, 0.0608726814, -0.999716282, -0.00144995365, 0.0237752739)},
	{"Cp18", CFrame.new(-5545.39404, 1107.8219, -11650.6357, -0.00791138876, -0.0912490711, 0.99579668, -1.18666341e-10, 0.995827854, 0.0912519246, -0.999968708, 0.000721929304, -0.00787838083)},
	{"Tengah 18", CFrame.new(-6414.31885, 1107.92029, -11711.4941, 0.39367038, -0.111929558, 0.912411869, 1.31374795e-08, 0.992559373, 0.121761598, -0.91925168, -0.0479339212, 0.390741229)},
	{"Cp19", CFrame.new(-6766.26074, 1105.58411, -11503.3955, -0.999874473, 0.000155506685, -0.015843736, -2.90724042e-12, 0.999951839, 0.00981455389, 0.0158444997, 0.00981332175, -0.999826312)},
	{"Tengah 19", CFrame.new(-6762.13184, 1099.67126, -11186.042, -0.998868346, 0.00112270634, -0.0475471318, -5.17564568e-11, 0.999721348, 0.0236059148, 0.0475603864, 0.0235792007, -0.998589993)},
	{"Cp20", CFrame.new(-6746.04248, 1108.37537, -10794.8271, -0.993840754, 0.0067165764, -0.11061395, -6.0127392e-10, 0.998161554, 0.060609255, 0.110817678, 0.0602359474, -0.992013633)}
}

local function SetPlatformStand(state)
	pcall(function()
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = state end
	end)
end

local function SafeGetHRP()
	local char = LocalPlayer.Character
	if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
		local start = tick()
		while (tick() - start) < 10 do
			task.wait(0.5)
			char = LocalPlayer.Character
			if char and char.Parent and char:FindFirstChild("HumanoidRootPart") then
				return char.HumanoidRootPart
			end
		end
		return nil
	end
	return char.HumanoidRootPart
end

local _partCache = nil
local function RefreshPartCache()
	_partCache = {}
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Parent and not v:IsDescendantOf(LocalPlayer.Character) then
			table.insert(_partCache, v)
		end
	end
end

local function GetPartForPos(pos, isCp, cpNum)
	if isCp then
		local folder = workspace:FindFirstChild("Checkpoint")
		if folder then return folder:FindFirstChild("Checkpoint " .. tostring(cpNum)) end
		return nil
	end
	if not _partCache then RefreshPartCache() end
	local closest, dist = nil, 15
	for _, v in ipairs(_partCache) do
		if v.Parent then
			local d = (v.Position - pos).Magnitude
			if d < dist then closest, dist = v, d end
		end
	end
	return closest
end

local function SummitTeleportAndTouch(targetCF, label, isCp, cpNum)
	local hrp = SafeGetHRP()
	if not hrp then return end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = targetCF
	task.wait(0.3)

	local part = GetPartForPos(targetCF.Position, isCp, cpNum)
	if part and part:IsA("BasePart") then
		hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, part.Size.Y / 2 + 2, 0))
		task.wait(0.1)
		if firetouchinterest then
			pcall(function()
				firetouchinterest(hrp, part, 0)
				task.wait(0.05)
				firetouchinterest(hrp, part, 1)
			end)
		end
	end
end

UI.Toggle(SummitPage, "Auto Summit Loop (Instant TP)", "BC → Cp1-Cp20 → Finish → kembali ke BC, berulang.", false, function(v)
	if v and not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	getgenv().AutoSummitRunning = v
	if not v then
		SetPlatformStand(false)
		pcall(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		end)
	end
end)

task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			if not SecureData.IsKeyVerified then getgenv().AutoSummitRunning = false; SetPlatformStand(false); break end -- [SECURE CHECK]
			
			local success, err = pcall(function()
				SummitTeleportAndTouch(BC_CFRAME, "BC Start", false, nil)
				task.wait(0.8)

				for _, point in ipairs(SummitPoints) do
					if not getgenv().AutoSummitRunning then break end
					local name, cf = point[1], point[2]
					local cpIndexStr = string.match(name, "^Cp(%d+)$")
					local height = cpIndexStr and SUMMIT_CP_HEIGHT or SUMMIT_MID_HEIGHT

					SummitTeleportAndTouch(cf + Vector3.new(0, height, 0), name, cpIndexStr ~= nil, cpIndexStr)

					if cpIndexStr then
						pcall(function()
							local cpRemote = ReplicatedStorage:FindFirstChild("Remote")
								and ReplicatedStorage.Remote:FindFirstChild("Checkpoint")
								and ReplicatedStorage.Remote.Checkpoint:FindFirstChild("TpToCheckpoint")
							if cpRemote then cpRemote:FireServer(tonumber(cpIndexStr)) end
						end)
						task.wait(SUMMIT_DELAY)
					else
						task.wait(0.2)
					end
				end

				if not getgenv().AutoSummitRunning then return end
				SummitTeleportAndTouch(FINISH_CFRAME, "Finish", false, nil)
				task.wait(2)

				if not getgenv().AutoSummitRunning then return end
				SummitTeleportAndTouch(BC_CFRAME, "BC Return", false, nil)
				task.wait(1.5)
			end)
			if not success then
				print("[Ubey Summit] Error: " .. tostring(err))
				task.wait(2)
			end
			task.wait(0.3)
		else
			task.wait(0.5)
		end
	end
end)

------------------------------------------------------------------
-- 4. PLAYER PAGE
------------------------------------------------------------------
UI.Section(PlayerPage, "PLAYER SETTINGS & VISUALS")
UI.Input(PlayerPage, "WalkSpeed", "Kecepatan jalan karakter", "", "50", function(t)
	local num = tonumber(t)
	if num then
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
-- 5. HALO PAGE
------------------------------------------------------------------
local function ApplyHaloToCharacter(haloName)
	getgenv().CurrentSelectedHalo = haloName
	pcall(function()
		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
		if not head then return end
		for _, v in ipairs(head:GetChildren()) do if v.Name == "CustomPlayerHalo" then v:Destroy() end end
		local src = ReplicatedStorage:FindFirstChild("HaloKenyal")
		local model = src and src:FindFirstChild(haloName)
		if model then
			local clone = model:Clone()
			clone.Name = "CustomPlayerHalo"
			local primary = clone:FindFirstChild("Handle") or clone:FindFirstChild("Antenna") or clone:FindFirstChildWhichIsA("BasePart")
			clone.Parent = head
			for _, desc in ipairs(clone:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Anchored = false
					desc.CanCollide = false
					desc.Massless = true
				elseif desc:IsA("Script") or desc:IsA("LocalScript") then
					desc:Destroy()
				end
			end
			if primary then
				primary.CFrame = head.CFrame * CFrame.new(0, 1.3, 0)
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = head
				weld.Part1 = primary
				weld.Parent = primary
			end
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if getgenv().CurrentSelectedHalo then ApplyHaloToCharacter(getgenv().CurrentSelectedHalo) end
end)

pcall(function()
	local src = ReplicatedStorage:FindFirstChild("HaloKenyal")
	if src then
		UI.Button(HaloPage, "Lepas Aksesoris Kepala", "Hapus halo yang sedang dipakai.", "Lepas", function()
			getgenv().CurrentSelectedHalo = nil
			pcall(function()
				local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
				if head then
					for _, v in ipairs(head:GetChildren()) do
						if v.Name == "CustomPlayerHalo" then v:Destroy() end
					end
				end
			end)
		end, Color3.fromRGB(180, 40, 40))
		for _, item in ipairs(src:GetChildren()) do
			local name = item.Name
			UI.Button(HaloPage, name, "Pakai halo ini.", "Pakai", function() ApplyHaloToCharacter(name) end)
		end
	end
end)

------------------------------------------------------------------
-- 6. TP PLAYER PAGE
------------------------------------------------------------------
local RefreshPlayerBtn = New("TextButton", {
	Size = UDim2.new(1,0,0,35), BackgroundColor3 = Color3.fromRGB(0,100,180),
	Text = "🔄 Refresh / Scan Pemain", TextColor3 = Color3.new(1,1,1),
	Font = Enum.Font.GothamBold, TextSize = 12
}, PlayerTpPage)
Round(RefreshPlayerBtn, 8)

local PlayerListContainer = New("ScrollingFrame", {
	Size = UDim2.new(1,0,0,210), BackgroundTransparency = 1,
	CanvasSize = UDim2.new(0,0,2,0), ScrollBarThickness = 3
}, PlayerTpPage)
New("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, PlayerListContainer)

local function ScanAndDisplayPlayers()
	for _, child in ipairs(PlayerListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local pBtn = New("TextButton", {
				Size = UDim2.new(1,0,0,32), BackgroundColor3 = Color3.fromRGB(35,35,45),
				Text = "👤 " .. plr.Name .. " (" .. plr.DisplayName .. ")",
				TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamMedium, TextSize = 11
			}, PlayerListContainer)
			Round(pBtn, 8)
			pBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local hrpTarget = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if hrpTarget and myHrp then myHrp.CFrame = hrpTarget.CFrame + Vector3.new(0, 5, 0) end
				end)
			end)
		end
	end
end

RefreshPlayerBtn.MouseButton1Click:Connect(ScanAndDisplayPlayers)
task.spawn(function() task.wait(2); ScanAndDisplayPlayers() end)

------------------------------------------------------------------
-- 7. PRIVACY & ANTI-ADMIN
------------------------------------------------------------------
UI.Input(PrivacyPage, "Nama Samaran", "Dipakai saat Privacy Mode aktif", "UBEY HUB", "UBEY HUB", function(t)
	getgenv().FakeNameInput = t
end)

UI.Toggle(PrivacyPage, "Privacy Mode (Hide Name)", "Ganti nama di atas kepala dengan nama samaran.", false, function(v)
	if v and not SecureData.IsKeyVerified then return end -- [SECURE CHECK]
	getgenv().HideNameRunning = v
	if v then
		task.spawn(function()
			while getgenv().HideNameRunning do
				if not SecureData.IsKeyVerified then getgenv().HideNameRunning = false; break end -- [SECURE CHECK]
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

UI.Toggle(PrivacyPage, "Anti-Admin Protect (MPG Group)", "Pindah server otomatis jika admin grup masuk.", getgenv().UbeyConfig.AntiAdminEnabled, function(v)
	getgenv().UbeyConfig.AntiAdminEnabled = v
	SaveConfig()
end)

local function CheckPlayerIsAdmin(player)
	local ok, rank = pcall(function() return player:GetRankInGroup(getgenv().UbeyConfig.TargetGroupId or 7019573) end)
	return ok and rank and rank > 1
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		task.spawn(function()
			task.wait(1.5)
			if getgenv().UbeyConfig.AntiAdminEnabled and CheckPlayerIsAdmin(player) then
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end
		end)
	end
end)

task.spawn(function()
    task.wait(2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and getgenv().UbeyConfig.AntiAdminEnabled and CheckPlayerIsAdmin(p) then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
            break
        end
    end
end)

------------------------------------------------------------------
-- 8. SETTINGS & WEBHOOK
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

UI.Section(SettingsPage, "DISCORD WEBHOOK", C.good)
UI.Toggle(SettingsPage, "Webhook Server-Wide", "Kirim notifikasi tangkapan langka & Core.", getgenv().UbeyConfig.WebhookEnabled, function(v)
	getgenv().UbeyConfig.WebhookEnabled = v
	SaveConfig()
end)

UI.Input(SettingsPage, "Webhook URL", "Paste URL webhook Discord", tostring(getgenv().UbeyConfig.WebhookUrl or ""), "https://discord.com/api/webhooks/...", function(t)
	getgenv().UbeyConfig.WebhookUrl = t
	SaveConfig()
end)

UI.Button(SettingsPage, "Test Webhook", "Kirim pesan percobaan ke Discord.", "Kirim Test", function(btn)
	local url = getgenv().UbeyConfig.WebhookUrl
	if not url or url == "" or not string.find(url, "api/webhooks") then
		Flash(btn, "URL Salah!", false)
		return
	end
	local requestFunc = GetRequestFunc()
	if requestFunc then
		pcall(function()
			requestFunc({
				Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode({["content"] = "✅ **Ubey Hub V3 Server-Wide Webhook Test Berhasil!**"})
			})
		end)
		Flash(btn, "Terkirim ✓", true)
	else
		Flash(btn, "No Request!", false)
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
	local defaults = DefaultConfig()
	SpotDD.SetValue(defaults.SelectedSpot)
	getgenv().AutoFishingEventRunning = false
	getgenv().AutoSellRunning = false
	getgenv().AutoSummitRunning = false
	getgenv().AutoFavoriteRunning = false
	getgenv().LoopSpotEnabled = false
	Flash(btn, "Direset ✓", true)
	task.wait(1.5)
	Main.Visible = false
	KeyFrame.Visible = true
end, Color3.fromRGB(180, 50, 50))

------------------------------------------------------------------
-- 9. CREDITS
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
	if not SecureData.IsKeyVerified then -- [SECURE CHECK]
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)
