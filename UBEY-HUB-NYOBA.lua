-- ==============================================================================
-- UBEY HUB V3 | BLUE EDITION (FULL LOGIC + MODERN GUI)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- === TEMA WARNA (BLUE THEME) ===
local Theme = {
	Bg           = Color3.fromRGB(12, 15, 22),
	Sidebar      = Color3.fromRGB(18, 22, 32),
	TopBar       = Color3.fromRGB(15, 18, 26),
	Accent       = Color3.fromRGB(0, 150, 255),
	AccentDark   = Color3.fromRGB(0, 90, 170),
	Text         = Color3.fromRGB(235, 240, 245),
	TextMuted    = Color3.fromRGB(130, 140, 155),
	Line         = Color3.fromRGB(35, 42, 58),
	Card         = Color3.fromRGB(24, 30, 44),
	CardHover    = Color3.fromRGB(32, 40, 58),
	SwitchOff    = Color3.fromRGB(45, 52, 68),
	Success      = Color3.fromRGB(0, 200, 120),
	Danger       = Color3.fromRGB(220, 60, 60),
}

-- === HELPER FUNCTIONS ===
local function Create(instance, props, children)
	local obj = Instance.new(instance)
	for k, v in pairs(props or {}) do obj[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = obj end
	return obj
end

local function Corner(radius, parent)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function Stroke(color, thickness, parent)
	return Create("UIStroke", { Color = color, Thickness = thickness, Parent = parent })
end

local function MakeDraggable(frame, handle)
	handle = handle or frame
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
end

-- === CONFIG & FILE SYSTEM ===
local CONFIG_FILE = "UbeyHubV3_Config.json"
local KEY_FILE = "UbeyHubV3_SavedKey.txt"

getgenv().UbeyConfig = {
	BiteDelay = "0.5", TapDelay = "0.12", MinigameMode = "Legit",
	SelectedSpot = "Spot Mancing Jembatan", AutoSellTimer = "5",
	AntiAdminEnabled = false, TargetGroupId = 7019573,
	WebhookEnabled = false, WebhookUrl = ""
}

local function SaveConfig()
	pcall(function() if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().UbeyConfig)) end end)
end
local function LoadConfig()
	pcall(function()
		if readfile and isfile and isfile(CONFIG_FILE) then
			local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
			if type(data) == "table" then for k, v in pairs(data) do if getgenv().UbeyConfig[k] ~= nil then getgenv().UbeyConfig[k] = v end end end
		end
	end)
end
local function ResetConfig()
	pcall(function()
		getgenv().UbeyConfig = { BiteDelay = "0.5", TapDelay = "0.12", MinigameMode = "Legit", SelectedSpot = "Spot Mancing Jembatan", AutoSellTimer = "5", AntiAdminEnabled = false, TargetGroupId = 7019573, WebhookEnabled = false, WebhookUrl = "" }
		if delfile and isfile then if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end; if isfile(KEY_FILE) then delfile(KEY_FILE) end end
	end)
end
LoadConfig()

-- === SUPABASE & HWID ===
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"
local function GetDeviceHWID()
	local hwid = nil
	pcall(function() if gethwid then hwid = gethwid() elseif RbxAnalyticsService then hwid = RbxAnalyticsService:GetClientId() end end)
	return tostring(hwid or ("UNKNOWN_DEVICE_" .. tostring(LocalPlayer.UserId)))
end
local CurrentHWID = GetDeviceHWID()

-- === WEBHOOK ===
local function SendFilteredWebhook(fishName, fishRarity, fishMutation, fishGrade, fishWeight, fishChance)
	pcall(function()
		if not getgenv().UbeyConfig.WebhookEnabled then return end
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then return end
		local rar = string.lower(tostring(fishRarity or ""))
		if rar ~= "secret" and rar ~= "forgotten" then return end
		local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
		if not requestFunc then return end
		requestFunc({
			Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({ ["content"] = "@everyone 🚨 **FISH SECRET / FORGOTTEN CATCH!**",
				["embeds"] = {{ ["title"] = "👑 Ubey Hub V3 - Secret & Forgotten Tracker!", ["description"] = "Pemain **" .. LocalPlayer.Name .. "** baru saja mendapatkan ikan langka!", ["color"] = 3447003,
					["fields"] = { { ["name"] = "🐟 Nama", ["value"] = tostring(fishName or "Unknown"), ["inline"] = true }, { ["name"] = "⭐ Rarity", ["value"] = tostring(fishRarity or "Common"), ["inline"] = true }, { ["name"] = "🧬 Mutasi", ["value"] = tostring(fishMutation or "Normal"), ["inline"] = true } },
					["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") }} }) })
	end)
end

-- === REAL-TIME CATCH MONITOR ===
getgenv().TotalFishCaught = 0
getgenv().SessionStartTime = os.time()
local hookedRemotes = {}

local function ProcessNotifyClient(actionType, fishDataArg)
	if actionType == "GotFish" then
		pcall(function()
			getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1
			if type(fishDataArg) == "table" then
				local name = fishDataArg.baseName or fishDataArg.originalName or "Unknown Fish"
				if name ~= "Unknown Fish" and name ~= "" then SendFilteredWebhook(name, fishDataArg.rarity, fishDataArg.mutation, fishDataArg.grade, fishDataArg.weight, fishDataArg.chance) end
			end
		end)
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
	for _, v in ipairs(container:GetDescendants()) do if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then AttachNotifyHook(v) end end
end

local function ListenToFishCatch()
	pcall(function()
		ScanContainerForNotify(ReplicatedStorage)
		ReplicatedStorage.DescendantAdded:Connect(function(v) if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then AttachNotifyHook(v) end end)
		local function ScanCharacter(char) if not char then return end; ScanContainerForNotify(char); char.DescendantAdded:Connect(function(v) if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then AttachNotifyHook(v) end end) end
		if LocalPlayer.Character then ScanCharacter(LocalPlayer.Character) end
		LocalPlayer.CharacterAdded:Connect(ScanCharacter)
	end)
end
task.spawn(function() task.wait(1); ListenToFishCatch() end)

-- === FISHING HELPERS ===
local function AutoEquipRod()
	pcall(function()
		local char = LocalPlayer.Character; if not char then return end
		for _, c in ipairs(char:GetChildren()) do if c:IsA("Tool") and (string.find(string.lower(c.Name), "rod") or string.find(string.lower(c.Name), "pancing")) then return end end
		local backpack = LocalPlayer:FindFirstChild("Backpack"); local hum = char:FindFirstChildOfClass("Humanoid")
		if backpack and hum then for _, item in ipairs(backpack:GetChildren()) do if item:IsA("Tool") then local n = string.lower(item.Name); if string.find(n, "rod") or string.find(n, "pancing") then hum:EquipTool(item); break end end end end
	end)
end

local function EnableGameAutoFishing(state)
	if state == nil then state = true end; local fired = false
	pcall(function() local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing"); local r = mancing and (mancing:FindFirstChild("Auto") or mancing:FindFirstChild("AutoFishing")); if r and r:IsA("RemoteEvent") then r:FireServer(state); fired = true end end)
	return fired
end

local function ClickGameAutoButton()
	pcall(function()
		local hub = PlayerGui:FindFirstChild("UbeyHub")
		for _, v in ipairs(PlayerGui:GetDescendants()) do
			if (v:IsA("TextButton") or v:IsA("ImageButton")) and not (hub and v:IsDescendantOf(hub)) then
				local n = string.lower(v.Name); local t = v:IsA("TextButton") and string.lower(v.Text) or ""
				if string.find(n, "auto") or string.find(t, "auto") then
					if firesignal then firesignal(v.MouseButton1Click); firesignal(v.Activated) elseif getconnections then for _, c in ipairs(getconnections(v.MouseButton1Click)) do c:Fire() end end
					return
				end
			end
		end
	end)
end

local function PerformTapClicker()
	local cam = Workspace.CurrentCamera; local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	local pos = getgenv().TapPosition or Vector2.new(vp.X * 0.85, vp.Y * 0.5)
	local ok = pcall(function() VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1); task.wait(0.02); VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1) end)
	if not ok then pcall(function() VirtualUser:ClickButton1(pos) end) end
end

-- === GLOBAL STATES ===
getgenv().AutoFishingEventRunning = false; getgenv().BiteDelayInput = getgenv().UbeyConfig.BiteDelay; getgenv().SelectedFishingSpot = getgenv().UbeyConfig.SelectedSpot
getgenv().AutoSellRunning = false; getgenv().AutoSellTimerInput = getgenv().UbeyConfig.AutoSellTimer
getgenv().AutoGalatamaRunning = false; getgenv().AutoSummitRunning = false; getgenv().AntiAFKRunning = false
getgenv().HideNameRunning = false; getgenv().FakeNameInput = "UBEY HUB"; getgenv().CurrentSelectedHalo = nil; getgenv().KeyVerified = false; getgenv().AutoDetectCoreEvent = false
getgenv().LoopSpotEnabled = false
getgenv().SpotLoopConfig = { ["Spot Mancing Jembatan"] = { Enabled = false, Timer = "10" }, ["Spot Mancing Core"] = { Enabled = false, Timer = "10" }, ["Spot Mancing Ikan Anomali"] = { Enabled = false, Timer = "10" } }
getgenv().AutoFavoriteRunning = false
getgenv().FavRarities = { ["Common"] = false, ["UnCommon"] = false, ["Rare"] = false, ["Epic"] = false, ["Legendary"] = true, ["Mythical"] = true, ["Secret"] = true, ["Forgotten"] = true }
getgenv().FavMutations = { ["Galaxy"] = false, ["Corrupt"] = false, ["Gemstone"] = false, ["Ghost"] = false, ["Lightning"] = false, ["Fairy Dust"] = true, ["Gold"] = false, ["Midnight"] = false, ["Radioactive"] = false, ["Stone"] = false, ["Holographic"] = false, ["Albino"] = false, ["Sandy"] = false, ["Cosmic"] = false, ["Normal"] = false, ["Elemental"] = false, ["Festive"] = false, ["8-Bit"] = false, ["Bloodmoon"] = false, ["Abyssal"] = false, ["Strawberry"] = false, ["Void"] = false, ["Cupid"] = false }
getgenv().UnfavRarities = { ["Common"] = false, ["UnCommon"] = false, ["Rare"] = false, ["Epic"] = false, ["Legendary"] = false, ["Mythical"] = false, ["Secret"] = false, ["Forgotten"] = false }
getgenv().UnfavMutations = { ["Galaxy"] = false, ["Corrupt"] = false, ["Gemstone"] = false, ["Ghost"] = false, ["Lightning"] = false, ["Fairy Dust"] = false, ["Gold"] = false, ["Midnight"] = false, ["Radioactive"] = false, ["Stone"] = false, ["Holographic"] = false, ["Albino"] = false, ["Sandy"] = false, ["Cosmic"] = false, ["Normal"] = false, ["Elemental"] = false, ["Festive"] = false, ["8-Bit"] = false, ["Bloodmoon"] = false, ["Abyssal"] = false, ["Strawberry"] = false, ["Void"] = false, ["Cupid"] = false }

local FishingSpots = {
	["Spot Mancing Jembatan"] = CFrame.new(-6783.74756, 1322.81006, -9757.34473, 0.0899723172, -9.34088291e-08, 0.995944262, 1.76120434e-08, 1, 9.21981638e-08, -0.995944262, 9.24533072e-09, 0.0899723172),
	["Spot Mancing Core"] = CFrame.new(-9069.33887, 1250.32092, -6510.3374, 0.99812746, -7.96398965e-08, -0.0611686334, 8.05492206e-08, 1, 1.24000188e-08, 0.0611686334, -1.73038845e-08, 0.99812746),
	["Spot Mancing Ikan Anomali"] = CFrame.new(-8199.52832, 1238.83752, -6278.13135, -0.999144316, 1.1644854e-08, -0.0413601957, 1.63464247e-08, 1, -1.13335595e-07, 0.0413601957, -1.13914709e-07, -0.999144316)
}
local NpcSellCFrame = CFrame.new(-6668.01416, 1312.69983, -9965.2998, 0.999977231, 1.08366018e-08, -0.00675115408, -1.09201403e-08, 1, -1.2337189e-08, 0.00675115408, 1.24106316e-08, 0.999977231)

local function GetEquippedRod() local char = LocalPlayer.Character; if not char then return nil end; local rod = char:FindFirstChild("Withering Rod"); if rod then return rod end; for _, c in ipairs(char:GetChildren()) do if c:IsA("Tool") and c:FindFirstChild("Mechanics") then return c end end; return nil end
local OriginalRodValues = {}
local function OptimizeRodSettings() pcall(function() local rod = GetEquippedRod(); local s = rod and rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Settings"); if not s then return end; local t = s:FindFirstChild("Time_before_getfish"); if t then if OriginalRodValues[t] == nil then OriginalRodValues[t] = t.Value end; t.Value = 0.05 end; local m = s:FindFirstChild("EnableMiniGame"); if m then if OriginalRodValues[m] == nil then OriginalRodValues[m] = m.Value end; m.Value = false end end) end
local function RestoreRodSettings() pcall(function() for inst, val in pairs(OriginalRodValues) do if inst and inst.Parent then inst.Value = val end; OriginalRodValues[inst] = nil end; local rod = GetEquippedRod(); local s = rod and rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Settings"); local m = s and s:FindFirstChild("EnableMiniGame"); if m then m.Value = true end end) end
local function RunAutoFishCycle(remoteFolder)
	pcall(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		OptimizeRodSettings(); remoteFolder.CastEvent:FireServer(true); task.wait(0.05); remoteFolder.CastEvent:FireServer(false, 100, hrp.CFrame.LookVector)
		local hooked = false; local conn = remoteFolder.NotifyClient.OnClientEvent:Connect(function(actionType) if actionType == "Bite" or actionType == "Hook" then hooked = true end end)
		local start = tick()
		while not hooked and getgenv().AutoFishingEventRunning and getgenv().UbeyConfig.MinigameMode == "Instant" do if tick() - start > 8 then break end; task.wait(0.05) end
		if conn then conn:Disconnect() end
		if hooked and getgenv().AutoFishingEventRunning and getgenv().UbeyConfig.MinigameMode == "Instant" then
			task.wait(tonumber(getgenv().BiteDelayInput) or 0.5); if getgenv().UbeyConfig.MinigameMode ~= "Instant" then return end
			local ts = remoteFolder:FindFirstChild("TandaSeruBersama"); if ts then local c1 = Color3.fromRGB(23, 255, 151); ts:FireServer(c1, Color3.fromRGB(20,20,20), ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(1,c1)}), 1.5) end
			task.wait(0.1); if getgenv().UbeyConfig.MinigameMode ~= "Instant" then return end
			remoteFolder.MiniGame:FireServer(true); task.wait(0.3)
		end
	end)
end

getgenv().FishLoopId = 0
local function StartFishingLoop()
	getgenv().FishLoopId = getgenv().FishLoopId + 1; local myId = getgenv().FishLoopId
	task.spawn(function()
		local lastAuto, clickedGui, restored = 0, false, false
		while getgenv().AutoFishingEventRunning and getgenv().FishLoopId == myId do
			local mode = getgenv().UbeyConfig.MinigameMode or "Legit"
			AutoEquipRod()
			if mode == "Legit" then
				if not restored then restored = true; RestoreRodSettings(); lastAuto = 0 end
				if tick() - lastAuto > 10 then lastAuto = tick(); local viaRemote = EnableGameAutoFishing(true); if not viaRemote and not clickedGui then clickedGui = true; ClickGameAutoButton() end end
				PerformTapClicker(); task.wait(math.max(tonumber(getgenv().UbeyConfig.TapDelay) or 0.12, 0.12))
			else
				restored = false
				pcall(function() local rod = GetEquippedRod(); local rf = rod and rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Remotes"); if rf then RunAutoFishCycle(rf) else task.wait(1) end end)
				task.wait(0.1)
			end
		end
		if getgenv().FishLoopId == myId and (getgenv().UbeyConfig.MinigameMode or "Legit") == "Legit" then EnableGameAutoFishing(false) end
	end)
end
local function TriggerSellToNpc()
	pcall(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		local cur = hrp.CFrame; hrp.CFrame = NpcSellCFrame + Vector3.new(0, 5, 0); task.wait(0.8)
		local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing"); local jual = mancing and mancing:FindFirstChild("JualSemua"); if jual then jual:InvokeServer() end
		task.wait(0.8); if getgenv().AutoFishingEventRunning then hrp.CFrame = cur end
	end)
end
local function GetInventoryRemote() return ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing") and ReplicatedStorage.Remote.Mancing:FindFirstChild("TandaiFavorit") end
local function GetServerFishData()
	local list = {}
	pcall(function() local ambil = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Inventaris") and ReplicatedStorage.Remote.Inventaris:FindFirstChild("AmbilSemua"); if ambil then local res = {ambil:InvokeServer()}; if type(res[1]) == "table" then for _, f in ipairs(res[1]) do if type(f) == "table" and (f.uid or f.UUID) then table.insert(list, { UUID = tostring(f.uid or f.UUID), Rarity = tostring(f.rarity or f.Rarity or ""), Mutation = tostring(f.mutasi or f.Mutation or ""), IsFavorited = f.favorit or f.IsFavorit or f.IsFavorite or false }) end end end end end)
	return list
end
local function ProcessAutoFavorite()
	pcall(function()
		local tandai = GetInventoryRemote(); if not tandai then return end
		for _, fish in ipairs(GetServerFishData()) do
			if not getgenv().AutoFavoriteRunning then break end
			local should = false; local rl = string.lower(fish.Rarity); local ml = string.lower(fish.Mutation)
			for r, a in pairs(getgenv().FavRarities) do if a and string.lower(r) == rl then should = true end end
			for m, a in pairs(getgenv().FavMutations) do if a and string.find(ml, string.lower(m)) then should = true end end
			if should and not fish.IsFavorited then tandai:FireServer(fish.UUID, true); task.wait(0.12) end
		end
	end)
end
task.spawn(function() while true do if getgenv().AutoFavoriteRunning then ProcessAutoFavorite() end; task.wait(2.5) end end)
local function UnfavoriteAllFish() task.spawn(function() pcall(function() local t = GetInventoryRemote(); if not t then return end; for _, f in ipairs(GetServerFishData()) do t:FireServer(f.UUID, false); task.wait(0.08) end end) end) end
local function UnfavoriteByFilter() task.spawn(function() pcall(function() local t = GetInventoryRemote(); if not t then return end; for _, f in ipairs(GetServerFishData()) do local u = false; local rl = string.lower(f.Rarity); local ml = string.lower(f.Mutation); for r, a in pairs(getgenv().UnfavRarities) do if a and string.lower(r) == rl then u = true end end; for m, a in pairs(getgenv().UnfavMutations) do if a and string.find(ml, string.lower(m)) then u = true end end; if u and f.IsFavorited then t:FireServer(f.UUID, false); task.wait(0.08) end end end) end) end

-- === SUMMIT LOGIC ===
getgenv().SummitDelay = 1; getgenv().SummitCpHeight = 1.5; getgenv().SummitUseRemote = false; getgenv().SummitHeight = 6
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
local function SetPlatformStand(state) pcall(function() local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand = state end end) end
task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			pcall(function()
				local midHeight = tonumber(getgenv().SummitHeight) or 6; local cpHeight = tonumber(getgenv().SummitCpHeight) or 1.5
				for _, point in ipairs(SummitPoints) do
					if not getgenv().AutoSummitRunning then break end
					local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not hrp then break end
					local cpIndex = string.match(point[1], "^Cp(%d+)$"); local height = cpIndex and cpHeight or midHeight
					pcall(function() LocalPlayer:RequestStreamAroundAsync(point[2].Position, 3) end)
					hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; hrp.CFrame = point[2] + Vector3.new(0, height, 0)
					if not getgenv().AutoSummitRunning then break end
					if cpIndex then
						local part; local waited = 0
						while getgenv().AutoSummitRunning and waited < 2 do local folder = workspace:FindFirstChild("Checkpoint"); part = folder and folder:FindFirstChild("Checkpoint " .. tostring(cpIndex)); if part and part:IsA("BasePart") then break end; part = nil; task.wait(0.2); waited = waited + 0.2 end
						hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						if hrp and getgenv().AutoSummitRunning then
							if not part then hrp.CFrame = point[2] + Vector3.new(0, height, 0); task.wait(0.1) else
								local standPos = part.Position + Vector3.new(0, (part.Size.Y / 2) + 2, 0); hrp.CFrame = CFrame.new(standPos); hrp.AssemblyLinearVelocity = Vector3.zero
								if firetouchinterest then pcall(function() firetouchinterest(hrp, part, 0); task.wait(0.05); firetouchinterest(hrp, part, 1) end) end
							end
						end
						task.wait(tonumber(getgenv().SummitDelay) or 1)
						if getgenv().SummitUseRemote then pcall(function() local cpRemote = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Checkpoint") and ReplicatedStorage.Remote.Checkpoint:FindFirstChild("TpToCheckpoint"); if cpRemote then cpRemote:FireServer(tonumber(cpIndex)) end end) end
						task.wait(0.1)
					else task.wait(0.15) end
				end
				local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp and getgenv().AutoSummitRunning then hrp.CFrame = CFrame.new(-6766.44629, 1320.69983, -10083.8037) + Vector3.new(0, 5, 0); task.wait(0.8); hrp.CFrame = CFrame.new(-6834.84912, 1313.24744, -9902.42285) + Vector3.new(0, 5, 0) end
			end)
			task.wait(0.3)
		else task.wait(0.5) end
	end
end)

-- === HALO LOGIC ===
local function ApplyHaloToCharacter(haloName)
	getgenv().CurrentSelectedHalo = haloName
	pcall(function()
		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"); if not head then return end
		for _, v in ipairs(head:GetChildren()) do if v.Name == "CustomPlayerHalo" then v:Destroy() end end
		local folder = ReplicatedStorage:FindFirstChild("HaloKenyal")
		if folder then local model = folder:FindFirstChild(haloName); if model then local clone = model:Clone(); clone.Name = "CustomPlayerHalo"; local primary = clone:FindFirstChild("Handle") or clone:FindFirstChild("Antenna") or clone:FindFirstChildWhichIsA("BasePart"); clone.Parent = head; for _, d in ipairs(clone:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = false; d.CanCollide = false; d.Massless = true elseif d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end end; if primary then primary.CFrame = head.CFrame * CFrame.new(0, 1.3, 0); local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = primary; w.Parent = primary end end end
	end)
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); if getgenv().CurrentSelectedHalo then ApplyHaloToCharacter(getgenv().CurrentSelectedHalo) end end)

-- ==============================================================================
-- GUI BARU (BLUE EDITION MODERN)
-- ==============================================================================
pcall(function() local old = PlayerGui:FindFirstChild("UbeyHub"); if old then old:Destroy() end end)
local Gui = Create("ScreenGui", { Name = "UbeyHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = PlayerGui })

-- Floating Button
local Float = Create("ImageButton", { Name = "FloatBtn", Parent = Gui, Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 20, 0, 120), BackgroundColor3 = Theme.Bg, Image = "rbxassetid://90770802417381", AutoButtonColor = false, BorderSizePixel = 0 })
Corner(30, Float); Stroke(Theme.Accent, 2, Float); MakeDraggable(Float)

-- Main Frame
local Main = Create("Frame", { Name = "Main", Parent = Gui, Size = UDim2.new(0, 620, 0, 380), Position = UDim2.new(0.5, -310, 0.5, -190), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Visible = false })
Corner(12, Main); Stroke(Theme.Line, 1, Main); MakeDraggable(Main)

-- Top Bar
local TopBar = Create("Frame", { Parent = Main, Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Theme.TopBar, BorderSizePixel = 0 }); Corner(12, TopBar)
Create("TextLabel", { Parent = TopBar, Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = "UBEY HUB", Font = Enum.Font.GothamBold, TextColor3 = Theme.Accent, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left })
Create("Frame", { Parent = TopBar, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Line, BorderSizePixel = 0 })

-- Search Bar
local SearchBar = Create("Frame", { Parent = TopBar, Size = UDim2.new(0, 180, 0, 26), Position = UDim2.new(1, -240, 0, 8), BackgroundColor3 = Theme.Card, BorderSizePixel = 0 }); Corner(6, SearchBar)
Create("TextLabel", { Parent = SearchBar, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = "🔍", Font = Enum.Font.Gotham, TextColor3 = Theme.TextMuted, TextSize = 12 })
Create("TextBox", { Parent = SearchBar, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 26, 0, 0), BackgroundTransparency = 1, PlaceholderText = "Search features...", Text = "", Font = Enum.Font.Gotham, TextColor3 = Theme.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, PlaceholderColor3 = Theme.TextMuted })

-- Min & Close
local MinBtn = Create("TextButton", { Parent = TopBar, Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -55, 0, 8), BackgroundColor3 = Theme.Card, Text = "−", Font = Enum.Font.GothamBold, TextColor3 = Theme.Text, TextSize = 16, BorderSizePixel = 0, AutoButtonColor = false }); Corner(6, MinBtn)
local CloseBtn = Create("TextButton", { Parent = TopBar, Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -25, 0, 8), BackgroundColor3 = Theme.Danger, Text = "×", Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1,1,1), TextSize = 16, BorderSizePixel = 0, AutoButtonColor = false }); Corner(6, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Sidebar
local Sidebar = Create("Frame", { Parent = Main, Size = UDim2.new(0, 180, 1, -42), Position = UDim2.new(0, 0, 0, 42), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0 }); Corner(12, Sidebar)
local ProfileFrame = Create("Frame", { Parent = Sidebar, Size = UDim2.new(1, -20, 0, 60), Position = UDim2.new(0, 10, 0, 12), BackgroundTransparency = 1 })
local AvatarFrame = Create("Frame", { Parent = ProfileFrame, Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 0, 0, 8), BackgroundColor3 = Theme.Card, BorderSizePixel = 0 }); Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = AvatarFrame })
Create("ImageLabel", { Parent = AvatarFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150" })
Create("TextLabel", { Parent = ProfileFrame, Size = UDim2.new(1, -55, 0, 18), Position = UDim2.new(0, 55, 0, 10), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
Create("TextLabel", { Parent = ProfileFrame, Size = UDim2.new(1, -55, 0, 16), Position = UDim2.new(0, 55, 0, 28), BackgroundTransparency = 1, Text = "👑 Premium User", Font = Enum.Font.Gotham, TextColor3 = Theme.Accent, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left })
Create("Frame", { Parent = Sidebar, Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 0, 80), BackgroundColor3 = Theme.Line, BorderSizePixel = 0 })

local MenuScroll = Create("ScrollingFrame", { Parent = Sidebar, Size = UDim2.new(1, -10, 1, -90), Position = UDim2.new(0, 5, 0, 88), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentDark, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y })
Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = MenuScroll })

local pages, navBtns = {}, {}
local function CreatePage(name)
	local p = Create("ScrollingFrame", { Parent = Main, Name = name, Size = UDim2.new(1, -200, 1, -60), Position = UDim2.new(0, 190, 0, 50), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.AccentDark, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = p })
	Create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 20), Parent = p })
	pages[name] = p; return p
end
local function ShowPage(name)
	for _, p in pairs(pages) do p.Visible = false end
	if pages[name] then pages[name].Visible = true end
	for n, b in pairs(navBtns) do
		if n == name then b.BackgroundColor3 = Theme.Accent; b.TextLabel.TextColor3 = Color3.new(1,1,1); b.IconLabel.TextColor3 = Color3.new(1,1,1)
		else b.BackgroundColor3 = Theme.Sidebar; b.TextLabel.TextColor3 = Theme.TextMuted; b.IconLabel.TextColor3 = Theme.TextMuted end
	end
end
local function NavButton(icon, label, pageName)
	local btn = Create("TextButton", { Parent = MenuScroll, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Sidebar, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }); Corner(6, btn)
	local iconLbl = Create("TextLabel", { Parent = btn, Size = UDim2.new(0, 26, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1, Text = icon, Font = Enum.Font.Gotham, TextColor3 = Theme.TextMuted, TextSize = 13, Name = "IconLabel" })
	local textLbl = Create("TextLabel", { Parent = btn, Size = UDim2.new(1, -35, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamMedium, TextColor3 = Theme.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Name = "TextLabel" })
	btn.MouseEnter:Connect(function() if pages[pageName] and pages[pageName].Visible then return end; btn.BackgroundColor3 = Theme.CardHover end)
	btn.MouseLeave:Connect(function() if pages[pageName] and pages[pageName].Visible then return end; btn.BackgroundColor3 = Theme.Sidebar end)
	btn.MouseButton1Click:Connect(function() ShowPage(pageName) end)
	navBtns[pageName] = btn; return btn
end

CreatePage("Fishing"); CreatePage("Favorite"); CreatePage("Galatama"); CreatePage("Teleport")
CreatePage("Summit"); CreatePage("Player"); CreatePage("Halo"); CreatePage("Privacy")
CreatePage("Settings"); CreatePage("Credits")

NavButton("🎣", "Fishing & Sell", "Fishing"); NavButton("⭐", "Favorite", "Favorite"); NavButton("🏆", "Galatama", "Galatama")
NavButton("🛒", "Teleport Shop", "Teleport"); NavButton("⛰️", "Summit", "Summit"); NavButton("⚡", "Player", "Player")
NavButton("👑", "Halo Kepala", "Halo"); NavButton("🛡️", "Privacy", "Privacy"); NavButton("⚙️", "Settings", "Settings"); NavButton("📝", "Credits", "Credits")

-- Komponen UI Builder
local function SectionTitle(parent, text) Create("TextLabel", { Parent = parent, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "── " .. text .. " ──", Font = Enum.Font.GothamBold, TextColor3 = Theme.Accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }) end
local function ToggleSwitch(parent, label, defaultOn, callback)
	local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Card, BorderSizePixel = 0 }); Corner(6, row)
	Create("TextLabel", { Parent = row, Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = label, Font = Enum.Font.Gotham, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
	local track = Create("Frame", { Parent = row, Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = defaultOn and Theme.Accent or Theme.SwitchOff, BorderSizePixel = 0 }); Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local knob = Create("Frame", { Parent = track, Size = UDim2.new(0, 18, 0, 18), Position = defaultOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 }); Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local state = defaultOn
	local function setState(on) state = on; track.BackgroundColor3 = on and Theme.Accent or Theme.SwitchOff; knob:TweenPosition(on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.15, true); if callback then callback(on) end end
	track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setState(not state) end end)
	row.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setState(not state) end end)
end
local function SettingRow(parent, label, valueText, callback)
	local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Card, BorderSizePixel = 0 }); Corner(6, row)
	Create("TextLabel", { Parent = row, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = label, Font = Enum.Font.Gotham, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
	local valBox = Create("TextBox", { Parent = row, Size = UDim2.new(0, 140, 0, 26), Position = UDim2.new(1, -152, 0.5, -13), BackgroundColor3 = Theme.TopBar, Text = tostring(valueText), Font = Enum.Font.Gotham, TextColor3 = Theme.Accent, TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false }); Corner(4, valBox); Stroke(Theme.Line, 1, valBox)
	if callback then valBox.FocusLost:Connect(function() callback(valBox.Text) end) end
	return valBox
end
local function AddButton(parent, label, color, callback)
	local btn = Create("TextButton", { Parent = parent, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = color or Theme.Accent, Text = label, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1,1,1), TextSize = 12, BorderSizePixel = 0, AutoButtonColor = true }); Corner(6, btn)
	if callback then btn.MouseButton1Click:Connect(callback) end
	return btn
end
local function CreateMultiSelect(parent, title, optionsTbl, stateTbl)
	local container = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Card, ClipsDescendants = true, BorderSizePixel = 0 }); Corner(6, container)
	local header = Create("TextButton", { Parent = container, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "  " .. title, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
	local countLabel = Create("TextLabel", { Parent = header, Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(1, -130, 0, 0), BackgroundTransparency = 1, TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right })
	local holder = Create("Frame", { Parent = container, Position = UDim2.new(0, 5, 0, 40), Size = UDim2.new(1, -10, 0, 0), BackgroundTransparency = 1 })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	local itemBtns = {}
	local function UpdateSummary() local c = 0; for _, a in pairs(stateTbl) do if a then c = c + 1 end end; if c == 0 then countLabel.Text = "None 🔽" elseif c == #optionsTbl then countLabel.Text = "All (" .. c .. ") 🔽" else countLabel.Text = c .. " Selected 🔽" end end
	local saBtn = Create("TextButton", { Parent = holder, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.Success, Text = "  ⚡ SELECT ALL / UNSELECT ALL", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }); Corner(4, saBtn)
	local all = false
	saBtn.MouseButton1Click:Connect(function() all = not all; for _, opt in ipairs(optionsTbl) do stateTbl[opt] = all end; for n, b in pairs(itemBtns) do b.BackgroundColor3 = all and Theme.Accent or Theme.Background; b.Text = "  " .. n .. (all and "  [✓]" or "  [ ]") end; UpdateSummary(); SaveConfig() end)
	for _, optName in ipairs(optionsTbl) do
		local opt = Create("TextButton", { Parent = holder, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = stateTbl[optName] and Theme.Accent or Theme.Background, Text = "  " .. optName .. (stateTbl[optName] and "  [✓]" or "  [ ]"), TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }); Corner(4, opt)
		itemBtns[optName] = opt
		opt.MouseButton1Click:Connect(function() stateTbl[optName] = not stateTbl[optName]; opt.BackgroundColor3 = stateTbl[optName] and Theme.Accent or Theme.Background; opt.Text = "  " .. optName .. (stateTbl[optName] and "  [✓]" or "  [ ]"); UpdateSummary(); SaveConfig() end)
	end
	UpdateSummary()
	local isOpen = false
	header.MouseButton1Click:Connect(function() isOpen = not isOpen; container:TweenSize(isOpen and UDim2.new(1, 0, 0, 45 + ((#optionsTbl + 1) * 32)) or UDim2.new(1, 0, 0, 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true) end)
end

-- ==============================================================================
-- ISI HALAMAN (LENGKAP)
-- ==============================================================================

-- 1. FISHING
SectionTitle(pages.Fishing, "FISHING SETTINGS")
local SpotDrop = AddButton(pages.Fishing, "📍 Spot: " .. getgenv().SelectedFishingSpot, Theme.Card)
SpotDrop.MouseButton1Click:Connect(function()
	local spots = {"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}
	local curIdx = 1
	for i, v in ipairs(spots) do if v == getgenv().SelectedFishingSpot then curIdx = i end end
	curIdx = curIdx % #spots + 1; getgenv().SelectedFishingSpot = spots[curIdx]; SpotDrop.Text = "📍 Spot: " .. getgenv().SelectedFishingSpot; getgenv().UbeyConfig.SelectedSpot = getgenv().SelectedFishingSpot; SaveConfig()
end)
local ModeDrop = AddButton(pages.Fishing, "🎮 Mode: " .. getgenv().UbeyConfig.MinigameMode, Theme.Card)
ModeDrop.MouseButton1Click:Connect(function()
	local modes = {"Legit", "Instant"}; local curIdx = 1
	for i, v in ipairs(modes) do if v == getgenv().UbeyConfig.MinigameMode then curIdx = i end end
	curIdx = curIdx % #modes + 1; getgenv().UbeyConfig.MinigameMode = modes[curIdx]; ModeDrop.Text = "🎮 Mode: " .. getgenv().UbeyConfig.MinigameMode; SaveConfig()
end)
ToggleSwitch(pages.Fishing, "Auto Fishing + Teleport", false, function(v) getgenv().AutoFishingEventRunning = v; if v then pcall(function() local hrp = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5); if hrp then hrp.CFrame = FishingSpots[getgenv().SelectedFishingSpot] + Vector3.new(0, 5, 0) end end); StartFishingLoop() end end)
ToggleSwitch(pages.Fishing, "Auto Fishing (Stay)", false, function(v) getgenv().AutoFishingEventRunning = v; if v then StartFishingLoop() end end)
SettingRow(pages.Fishing, "Bite Delay (detik)", getgenv().UbeyConfig.BiteDelay, function(v) getgenv().BiteDelayInput = v; getgenv().UbeyConfig.BiteDelay = v; SaveConfig() end)
SettingRow(pages.Fishing, "Tap Delay (detik)", getgenv().UbeyConfig.TapDelay, function(v) getgenv().UbeyConfig.TapDelay = v; SaveConfig() end)

SectionTitle(pages.Fishing, "AUTO SELL SYSTEM")
ToggleSwitch(pages.Fishing, "Auto Sell ke NPC", false, function(v) getgenv().AutoSellRunning = v; if v then task.spawn(function() local last = tick(); while getgenv().AutoSellRunning do task.wait(5); if ((tick() - last) / 60) >= (tonumber(getgenv().AutoSellTimerInput) or 5) then TriggerSellToNpc(); last = tick() end end) end end)
SettingRow(pages.Fishing, "Jeda Jual (menit)", getgenv().UbeyConfig.AutoSellTimer, function(v) getgenv().AutoSellTimerInput = v; getgenv().UbeyConfig.AutoSellTimer = v; SaveConfig() end)

SectionTitle(pages.Fishing, "SPOT ROTATION")
ToggleSwitch(pages.Fishing, "Aktifkan Loop Spot", false, function(v) getgenv().LoopSpotEnabled = v end)
local function CreateSpotTimerSetting(parent, spotName)
	local frame = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Theme.Card, BorderSizePixel = 0 }); Corner(6, frame)
	local toggleBtn = Create("TextButton", { Parent = frame, Size = UDim2.new(0.65, 0, 1, 0), BackgroundTransparency = 1, Text = "  " .. spotName .. " [OFF]", TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left })
	local timeBox = Create("TextBox", { Parent = frame, Size = UDim2.new(0.3, -5, 0, 25), Position = UDim2.new(0.7, 0, 0, 5), BackgroundColor3 = Theme.Background, Text = getgenv().SpotLoopConfig[spotName].Timer, PlaceholderText = "Menit", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0 }); Corner(4, timeBox)
	toggleBtn.MouseButton1Click:Connect(function() local cur = not getgenv().SpotLoopConfig[spotName].Enabled; getgenv().SpotLoopConfig[spotName].Enabled = cur; toggleBtn.Text = "  " .. spotName .. (cur and " [ON]" or " [OFF]"); toggleBtn.TextColor3 = cur and Theme.Accent or Theme.Text end)
	timeBox.FocusLost:Connect(function() getgenv().SpotLoopConfig[spotName].Timer = timeBox.Text end)
end
CreateSpotTimerSetting(pages.Fishing, "Spot Mancing Jembatan"); CreateSpotTimerSetting(pages.Fishing, "Spot Mancing Core"); CreateSpotTimerSetting(pages.Fishing, "Spot Mancing Ikan Anomali")
task.spawn(function() local order = {"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}; while true do if getgenv().LoopSpotEnabled and not getgenv().AutoDetectCoreEvent then for _, name in ipairs(order) do local cfg = getgenv().SpotLoopConfig[name]; if getgenv().LoopSpotEnabled and cfg and cfg.Enabled then getgenv().SelectedFishingSpot = name; pcall(function() local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp and FishingSpots[name] then hrp.CFrame = FishingSpots[name] + Vector3.new(0, 5, 0) end end); local dur = (tonumber(cfg.Timer) or 10) * 60; local start = tick(); while getgenv().LoopSpotEnabled and cfg.Enabled and (tick() - start < dur) do task.wait(1) end end end task.wait(1) else task.wait(2) end end end)

-- 2. FAVORITE
SectionTitle(pages.Favorite, "AUTO FAVORITE")
ToggleSwitch(pages.Favorite, "Aktifkan Auto Favorite", false, function(v) getgenv().AutoFavoriteRunning = v end)
CreateMultiSelect(pages.Favorite, "Fav Filter Rarity", {"Common", "UnCommon", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Forgotten"}, getgenv().FavRarities)
CreateMultiSelect(pages.Favorite, "Fav Filter Mutasi", {"Galaxy", "Corrupt", "Gemstone", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Holographic", "Albino", "Sandy", "Cosmic", "Elemental", "Festive", "8-Bit", "Bloodmoon", "Abyssal", "Strawberry", "Void", "Cupid"}, getgenv().FavMutations)
SectionTitle(pages.Favorite, "UNFAVORITE FILTER")
CreateMultiSelect(pages.Favorite, "Unfav Filter Rarity", {"Common", "UnCommon", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Forgotten"}, getgenv().UnfavRarities)
CreateMultiSelect(pages.Favorite, "Unfav Filter Mutasi", {"Galaxy", "Corrupt", "Gemstone", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Holographic", "Albino", "Sandy", "Cosmic", "Elemental", "Festive", "8-Bit", "Bloodmoon", "Abyssal", "Strawberry", "Void", "Cupid"}, getgenv().UnfavMutations)
AddButton(pages.Favorite, "🎯 UNFAVORITE BY FILTER", Color3.fromRGB(200, 100, 30), UnfavoriteByFilter)
AddButton(pages.Favorite, "🚨 UNFAVORITE ALL", Theme.Danger, UnfavoriteAllFish)

-- 3. GALATAMA
SectionTitle(pages.Galatama, "GALATAMA")
AddButton(pages.Galatama, "📍 Teleport ke Galatama", Theme.Accent, function() pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-8008.12744, 1227.96838, -6091.92627) + Vector3.new(0, 5, 0) end) end)
ToggleSwitch(pages.Galatama, "Auto Join Galatama", false, function(v) getgenv().AutoGalatamaRunning = v; if v then task.spawn(function() while getgenv().AutoGalatamaRunning do pcall(function() local g = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Glatama") and ReplicatedStorage.Remote.Glatama:FindFirstChild("Ikut"); if g then g:InvokeServer() end end); task.wait(10) end end) end end)
SectionTitle(pages.Galatama, "CORE EVENT")
ToggleSwitch(pages.Galatama, "Auto Teleport Saat Event Core", false, function(v) getgenv().AutoDetectCoreEvent = v end)
local SavedPreviousSpot, IsAtCoreEvent = nil, false
task.spawn(function() while true do if getgenv().AutoDetectCoreEvent then pcall(function() local m = tonumber(os.date("%M")); local isEvent = (m >= 0 and m <= 10); if isEvent then if not IsAtCoreEvent then SavedPreviousSpot = getgenv().SelectedFishingSpot; IsAtCoreEvent = true end; getgenv().SelectedFishingSpot = "Spot Mancing Core"; local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local cf = FishingSpots["Spot Mancing Core"]; if hrp and cf and (hrp.Position - cf.Position).Magnitude > 20 then hrp.CFrame = cf + Vector3.new(0, 5, 0) end else if IsAtCoreEvent then IsAtCoreEvent = false; if SavedPreviousSpot and FishingSpots[SavedPreviousSpot] then getgenv().SelectedFishingSpot = SavedPreviousSpot; local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp and FishingSpots[SavedPreviousSpot] then hrp.CFrame = FishingSpots[SavedPreviousSpot] + Vector3.new(0, 5, 0) end end end end end); task.wait(5) else task.wait(3) end end end)

-- 4. TELEPORT
SectionTitle(pages.Teleport, "TELEPORT TO NPC")
local function AddTpBtn(name, cf) AddButton(pages.Teleport, "📍 " .. name, Theme.Card, function() pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = cf + Vector3.new(0, 5, 0) end) end) end
AddTpBtn("Tempat Jual Ikan", CFrame.new(-6668.79785, 1312.69983, -9964.06152)); AddTpBtn("Skin Shop", CFrame.new(-6639.45947, 1312.69983, -9947.36133)); AddTpBtn("Pet Shop", CFrame.new(-6640.44092, 1312.69983, -9917.93652)); AddTpBtn("Rod Shop", CFrame.new(-6638.09521, 1312.69983, -9857.41797))

-- 5. SUMMIT
SectionTitle(pages.Summit, "AUTO SUMMIT")
ToggleSwitch(pages.Summit, "Auto Summit Loop", false, function(v) getgenv().AutoSummitRunning = v; if not v then SetPlatformStand(false) end end)
SettingRow(pages.Summit, "Tinggi Tengah", "6", function(v) getgenv().SummitHeight = tonumber(v) or 6 end)
SettingRow(pages.Summit, "Tinggi Checkpoint", "1.5", function(v) getgenv().SummitCpHeight = tonumber(v) or 1.5 end)
ToggleSwitch(pages.Summit, "Pakai Remote Checkpoint", false, function(v) getgenv().SummitUseRemote = v end)
SettingRow(pages.Summit, "Jeda Checkpoint", "1", function(v) getgenv().SummitDelay = math.max(tonumber(v) or 1, 0) end)

-- 6. PLAYER
SectionTitle(pages.Player, "PLAYER SETTINGS")
SettingRow(pages.Player, "WalkSpeed", "16", function(v) local n = tonumber(v); if n then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = n end) end end)
ToggleSwitch(pages.Player, "Anti-AFK", false, function(v) getgenv().AntiAFKRunning = v end)
LocalPlayer.Idled:Connect(function() if getgenv().AntiAFKRunning then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0,0)) end end)
AddButton(pages.Player, "👻 Enable Headless", Theme.Accent, function() pcall(function() local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"); if head then head.Transparency = 1; for _, c in ipairs(head:GetChildren()) do if c:IsA("Decal") then c.Transparency = 1 end end end end) end)
local autoRgbActive = false
local RgbBtn = AddButton(pages.Player, "🔥🌈 Auto RGB Fire: [OFF]", Color3.fromRGB(150, 0, 200), function()
	autoRgbActive = not autoRgbActive
	RgbBtn.Text = "🔥🌈 Auto RGB Fire: " .. (autoRgbActive and "[ON]" or "[OFF]")
	RgbBtn.BackgroundColor3 = autoRgbActive and Theme.Success or Color3.fromRGB(150, 0, 200)
	pcall(function() local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"); if head then local fire = head:FindFirstChild("UbeyHeadFire"); if autoRgbActive and not fire then fire = Instance.new("Fire"); fire.Name = "UbeyHeadFire"; fire.Size = 5; fire.Heat = 15; fire.Parent = head elseif not autoRgbActive and fire then fire:Destroy() end end end)
end)
task.spawn(function() local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,100,255), Color3.fromRGB(255,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(0,255,255)}; local idx = 1; while true do if autoRgbActive then pcall(function() local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"); local fire = head and head:FindFirstChild("UbeyHeadFire"); if fire then idx = idx % #colors + 1; fire.Color = colors[idx]; fire.SecondaryColor = colors[(idx % #colors) + 1] end end); task.wait(1) else task.wait(2) end end end)

-- 7. HALO
SectionTitle(pages.Halo, "HALO KEPALA")
pcall(function()
	local folder = ReplicatedStorage:FindFirstChild("HaloKenyal")
	if folder then
		AddButton(pages.Halo, "❌ Lepas Aksesoris", Theme.Danger, function() getgenv().CurrentSelectedHalo = nil; pcall(function() local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"); if head then for _, v in ipairs(head:GetChildren()) do if v.Name == "CustomPlayerHalo" then v:Destroy() end end end end) end)
		for _, item in ipairs(folder:GetChildren()) do AddButton(pages.Halo, "👑 " .. item.Name, Theme.Card, function() ApplyHaloToCharacter(item.Name) end) end
	end
end)

-- 8. PRIVACY
SectionTitle(pages.Privacy, "PRIVACY")
SettingRow(pages.Privacy, "Nama Samaran", "UBEY HUB", function(v) getgenv().FakeNameInput = v end)
ToggleSwitch(pages.Privacy, "Privacy Mode", false, function(v) getgenv().HideNameRunning = v; if v then task.spawn(function() while getgenv().HideNameRunning do pcall(function() local fakeName = getgenv().FakeNameInput or "UBEY HUB"; local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"); if head then for _, c in ipairs(head:GetDescendants()) do if c:IsA("TextLabel") or c:IsA("TextMesh") then local t = c.Text; if string.find(t, LocalPlayer.Name) or string.find(t, LocalPlayer.DisplayName) then c.Text = fakeName end end end end end); task.wait(1) end end) end end)
ToggleSwitch(pages.Privacy, "Anti-Admin Protect", getgenv().UbeyConfig.AntiAdminEnabled, function(v) getgenv().UbeyConfig.AntiAdminEnabled = v; SaveConfig() end)
Players.PlayerAdded:Connect(function(player) if player ~= LocalPlayer then task.spawn(function() task.wait(1.5); if getgenv().UbeyConfig.AntiAdminEnabled then local ok, rank = pcall(function() return player:GetRankInGroup(getgenv().UbeyConfig.TargetGroupId or 7019573) end); if ok and rank and rank > 1 then TeleportService:Teleport(game.PlaceId, LocalPlayer) end end end) end end)

-- 9. SETTINGS
SectionTitle(pages.Settings, "PERFORMANCE")
AddButton(pages.Settings, "⚡ Anti-Lag (Boost FPS)", Theme.Accent, function() pcall(function() Lighting.GlobalShadows = false; Lighting.FogEnd = 999999; for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled = false end end end) end)
local BlackScreenGui = nil; local isBlackScreen = false
local BSBtn = AddButton(pages.Settings, "📱 Black Screen (Battery Saver): [OFF]", Theme.Card, function()
	isBlackScreen = not isBlackScreen; BSBtn.Text = "📱 Black Screen (Battery Saver): " .. (isBlackScreen and "[ON]" or "[OFF]"); BSBtn.BackgroundColor3 = isBlackScreen and Theme.Success or Theme.Card
	if isBlackScreen then
		if not BlackScreenGui then BlackScreenGui = Instance.new("ScreenGui"); BlackScreenGui.Name = "UbeyBlackScreen"; BlackScreenGui.Parent = PlayerGui; BlackScreenGui.DisplayOrder = 999999; BlackScreenGui.IgnoreGuiInset = true; local frame = Instance.new("Frame", BlackScreenGui); frame.Size = UDim2.new(1,0,1,0); frame.BackgroundColor3 = Color3.fromRGB(2,2,5); local txt = Instance.new("TextLabel", frame); txt.Size = UDim2.new(1,0,0,60); txt.Position = UDim2.new(0,0,0.45,0); txt.BackgroundTransparency = 1; txt.Text = "🌙 UBEY HUB - BATTERY SAVER ACTIVE\n(Sentuh Layar Untuk Kembali)"; txt.TextColor3 = Theme.Accent; txt.Font = Enum.Font.GothamBold; txt.TextSize = 13; frame.InputBegan:Connect(function() isBlackScreen = false; BSBtn.Text = "📱 Black Screen (Battery Saver): [OFF]"; BSBtn.BackgroundColor3 = Theme.Card; BlackScreenGui.Enabled = false end) else BlackScreenGui.Enabled = true end
	else if BlackScreenGui then BlackScreenGui.Enabled = false end end
end)
SectionTitle(pages.Settings, "WEBHOOK")
SettingRow(pages.Settings, "Webhook URL", getgenv().UbeyConfig.WebhookUrl, function(v) getgenv().UbeyConfig.WebhookUrl = v; SaveConfig() end)
ToggleSwitch(pages.Settings, "Aktifkan Webhook Secret", getgenv().UbeyConfig.WebhookEnabled, function(v) getgenv().UbeyConfig.WebhookEnabled = v; SaveConfig() end)
AddButton(pages.Settings, "🧪 Test Webhook", Theme.Accent, function()
	pcall(function() local url = getgenv().UbeyConfig.WebhookUrl; if not url or url == "" or not string.find(url, "api/webhooks") then return end; local req = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request); if req then req({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode({ ["content"] = "✅ **Ubey Hub V3 Webhook Test Berhasil!**" }) }) end end)
end)
SectionTitle(pages.Settings, "CONFIG")
AddButton(pages.Settings, "💾 Simpan Config", Theme.Success, function() SaveConfig() end)
AddButton(pages.Settings, "🔄 Reset Config", Theme.Danger, function() ResetConfig() end)

-- 10. CREDITS
Create("TextLabel", { Parent = pages.Credits, Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = "UBEY HUB V3", Font = Enum.Font.GothamBold, TextColor3 = Theme.Accent, TextSize = 24 })
Create("TextLabel", { Parent = pages.Credits, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Created by UBEY", Font = Enum.Font.Gotham, TextColor3 = Theme.TextMuted, TextSize = 13 })

-- ==============================================================================
-- STAT PANEL (BOTTOM)
-- ==============================================================================
local StatPanel = Create("Frame", { Parent = Main, Size = UDim2.new(1, -200, 0, 24), Position = UDim2.new(0, 190, 1, -28), BackgroundColor3 = Theme.TopBar, BorderSizePixel = 0 }); Corner(6, StatPanel)
local StatLabel = Create("TextLabel", { Parent = StatPanel, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = "📊 Total Ikan: 0  |  ⏱️ Play Time: 00s", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left })
task.spawn(function() while true do pcall(function() local e = os.time() - getgenv().SessionStartTime; local h, m, s = math.floor(e/3600), math.floor((e%3600)/60), e%60; local ts; if h > 0 then ts = string.format("%02dh %02dm %02ds", h, m, s) elseif m > 0 then ts = string.format("%02dm %02ds", m, s) else ts = string.format("%02ds", s) end; StatLabel.Text = string.format("📊 Total Ikan: %d  |  ⏱️ Play: %s", getgenv().TotalFishCaught or 0, ts) end); task.wait(1) end end)

-- ==============================================================================
-- KEY SYSTEM UI (BLUE EDITION)
-- ==============================================================================
local KeyFrame = Create("Frame", { Parent = Gui, Size = UDim2.new(0, 380, 0, 200), Position = UDim2.new(0.5, -190, 0.5, -100), BackgroundColor3 = Theme.Bg, Visible = false, BorderSizePixel = 0 })
Corner(12, KeyFrame); Stroke(Theme.Accent, 1, KeyFrame); MakeDraggable(KeyFrame)
Create("TextLabel", { Parent = KeyFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "UBEY HUB - VERIFICATION", Font = Enum.Font.GothamBold, TextColor3 = Theme.Accent, TextSize = 14 })
local KeyBox = Create("TextBox", { Parent = KeyFrame, Size = UDim2.new(0, 340, 0, 38), Position = UDim2.new(0, 20, 0, 50), BackgroundColor3 = Theme.Card, PlaceholderText = "Masukkan License Key...", Text = "", TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, BorderSizePixel = 0 })
Corner(8, KeyBox)
local SubmitKeyBtn = Create("TextButton", { Parent = KeyFrame, Size = UDim2.new(0, 165, 0, 35), Position = UDim2.new(0, 20, 0, 100), BackgroundColor3 = Theme.Accent, Text = "Verifikasi", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0 })
Corner(8, SubmitKeyBtn)
local GetKeyDiscordBtn = Create("TextButton", { Parent = KeyFrame, Size = UDim2.new(0, 165, 0, 35), Position = UDim2.new(0, 195, 0, 100), BackgroundColor3 = Color3.fromRGB(88, 101, 242), Text = "Get Key", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0 })
Corner(8, GetKeyDiscordBtn)
local StatusKey = Create("TextLabel", { Parent = KeyFrame, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 150), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextColor3 = Theme.Danger, TextSize = 12 })

-- KEY VALIDATION LOGIC
local function ValidateKey(enteredKey, isAutoLogin)
	if enteredKey == "" then if not isAutoLogin then StatusKey.TextColor3 = Theme.Danger; StatusKey.Text = "Masukkan key!" end; KeyFrame.Visible = true; return end
	if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,200,0); StatusKey.Text = "Memeriksa HWID..." end
	task.spawn(function()
		local requestFunc = syn and syn.request or http and http.request or request
		local success, response = pcall(function() if requestFunc then return requestFunc({ Url = SUPABASE_URL .. enteredKey, Method = "GET", Headers = { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY, ["Content-Type"] = "application/json" } }).Body else return HttpService:GetAsync(SUPABASE_URL .. HttpService:UrlEncode(enteredKey), false, { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY }) end end)
		if success and response then
			local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
			if ok and data and #data > 0 then
				local r = data[1]
				if r.status == false or r.status == "inactive" or r.status == "used" then if not isAutoLogin then StatusKey.TextColor3 = Theme.Danger; StatusKey.Text = "Key tidak aktif!" end; KeyFrame.Visible = true; return end
				if r.hwid_value and r.hwid_value ~= "" and r.hwid_value ~= CurrentHWID then if not isAutoLogin then StatusKey.TextColor3 = Theme.Danger; StatusKey.Text = "Key terikat di perangkat lain!" end; KeyFrame.Visible = true; return end
				pcall(function() if writefile then writefile(KEY_FILE, enteredKey) end end); getgenv().KeyVerified = true; KeyFrame.Visible = false; Main.Visible = true
			else if not isAutoLogin then StatusKey.TextColor3 = Theme.Danger; StatusKey.Text = "Key Salah!" end; KeyFrame.Visible = true end
		else if not isAutoLogin then StatusKey.TextColor3 = Theme.Danger; StatusKey.Text = "Gagal ke database." end; KeyFrame.Visible = true end
	end)
end
SubmitKeyBtn.MouseButton1Click:Connect(function() ValidateKey(KeyBox.Text, false) end)
GetKeyDiscordBtn.MouseButton1Click:Connect(function() pcall(function() if setclipboard then setclipboard("https://discord.gg/YXuYeEpnXE") end end); StatusKey.TextColor3 = Theme.Accent; StatusKey.Text = "Link disalin!" end)
task.spawn(function() if readfile and isfile and isfile(KEY_FILE) then local savedKey = readfile(KEY_FILE); if savedKey and savedKey ~= "" then KeyBox.Text = savedKey; ValidateKey(savedKey, true) else KeyFrame.Visible = true end else KeyFrame.Visible = true end end)

-- FLOAT BTN TOGGLE
Float.MouseButton1Click:Connect(function()
	if not getgenv().KeyVerified then KeyFrame.Visible = not KeyFrame.Visible; Main.Visible = false
	else Main.Visible = not Main.Visible; KeyFrame.Visible = false end
end)

ShowPage("Fishing")
print("UBEY HUB V3 | BLUE EDITION FULL LOADED SUCCESSFULLY!")
