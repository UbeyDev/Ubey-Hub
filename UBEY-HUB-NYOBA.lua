-- ==============================================================================
-- UBEY HUB V3 | VIP FULL SCRIPT (LEGIT = AUTO BAWAAN GAME + AUTO TAP / INSTANT)
-- PATCHED: Anti-Lag / Ping Stabil (idle loops, event-based, memory-leak fixed)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- STAT TRACKER GLOBAL VARIABLES
------------------------------------------------------------------
getgenv().TotalFishCaught = 0
getgenv().SessionStartTime = os.time()

------------------------------------------------------------------
-- CONFIGURATION & FILE SAVE SYSTEM
------------------------------------------------------------------
local CONFIG_FILE = "UbeyHubV3_Config.json"
local KEY_FILE = "UbeyHubV3_SavedKey.txt"

getgenv().UbeyConfig = {
	BiteDelay = "0.5",
	TapDelay = "0.15",
	MinigameMode = "Legit",
	SelectedSpot = "Spot Mancing Jembatan",
	AutoSellTimer = "5",
	AntiAdminEnabled = false,
	TargetGroupId = 7019573,
	WebhookEnabled = false,
	WebhookUrl = ""
}

local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().UbeyConfig))
		end
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

local function ResetConfig()
	pcall(function()
		getgenv().UbeyConfig = {
			BiteDelay = "0.5", TapDelay = "0.15", MinigameMode = "Legit",
			SelectedSpot = "Spot Mancing Jembatan", AutoSellTimer = "5",
			AntiAdminEnabled = false, TargetGroupId = 7019573,
			WebhookEnabled = false, WebhookUrl = ""
		}
		if delfile and isfile then
			if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
			if isfile(KEY_FILE) then delfile(KEY_FILE) end
		end
	end)
end

LoadConfig()

------------------------------------------------------------------
-- SUPABASE CONFIGURATION & HWID
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"

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
-- DISCORD WEBHOOK
------------------------------------------------------------------
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
			Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				["content"] = "@everyone 🚨 **FISH SECRET / FORGOTTEN CATCH!**",
				["embeds"] = {{
					["title"] = "👑 Ubey Hub V3 - Secret & Forgotten Tracker!",
					["description"] = "Pemain **" .. LocalPlayer.Name .. "** baru saja mendapatkan ikan langka!",
					["color"] = 16711935,
					["fields"] = {
						{ ["name"] = "🐟 Nama Ikan", ["value"] = tostring(fishName or "Unknown"), ["inline"] = true },
						{ ["name"] = "⭐ Rarity", ["value"] = tostring(fishRarity or "Common"), ["inline"] = true },
						{ ["name"] = "🧬 Mutasi", ["value"] = tostring(fishMutation or "Normal"), ["inline"] = true },
						{ ["name"] = "🏆 Grade", ["value"] = tostring(fishGrade or "N/A"), ["inline"] = true },
						{ ["name"] = "⚖️ Berat", ["value"] = tostring(fishWeight or "0") .. " kg", ["inline"] = true },
						{ ["name"] = "🎲 Chance", ["value"] = tostring(fishChance or "N/A"), ["inline"] = true }
					},
					["footer"] = { ["text"] = "Ubey Hub V3 • Secret & Forgotten Notification" },
					["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
				}}
			})
		})
	end)
end

------------------------------------------------------------------
-- NOTIFY HOOK (PATCHED: no memory leak, no periodic rescan)
------------------------------------------------------------------
local hookedConnections = {}
local hookedRemotes = {}

local function ProcessNotifyClient(actionType, fishDataArg)
	if actionType == "Bite" or actionType == "Hook" then
		getgenv()._ubeyHooked = true
	end
	if actionType == "GotFish" then
		pcall(function()
			getgenv().TotalFishCaught = (getgenv().TotalFishCaught or 0) + 1
			if type(fishDataArg) == "table" then
				local name = fishDataArg.baseName or fishDataArg.originalName or "Unknown Fish"
				if name ~= "Unknown Fish" and name ~= "" then
					SendFilteredWebhook(name, fishDataArg.rarity, fishDataArg.mutation,
						fishDataArg.grade, fishDataArg.weight, fishDataArg.chance)
				end
			end
		end)
	end
end

local function AttachNotifyHook(remote)
	if remote and remote:IsA("RemoteEvent") and not hookedRemotes[remote] then
		hookedRemotes[remote] = true
		local conn = remote.OnClientEvent:Connect(ProcessNotifyClient)
		hookedConnections[remote] = conn
		-- cleanup otomatis saat remote di-destroy
		remote.Destroying:Connect(function()
			if hookedConnections[remote] then
				hookedConnections[remote]:Disconnect()
				hookedConnections[remote] = nil
			end
			hookedRemotes[remote] = nil
		end)
	end
end

local function ScanContainerForNotify(container)
	if not container then return end
	for _, v in ipairs(container:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then
			AttachNotifyHook(v)
		end
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
		local char = LocalPlayer.Character
		if not char then return end
		for _, c in ipairs(char:GetChildren()) do
			if c:IsA("Tool") and (string.find(string.lower(c.Name), "rod") or string.find(string.lower(c.Name), "pancing")) then
				return
			end
		end
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if backpack and hum then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") then
					local n = string.lower(item.Name)
					if string.find(n, "rod") or string.find(n, "pancing") then
						hum:EquipTool(item); break
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------
-- GAME AUTO FISHING HELPERS
------------------------------------------------------------------
local function EnableGameAutoFishing(state)
	if state == nil then state = true end
	local fired = false
	pcall(function()
		local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing")
		local r = mancing and (mancing:FindFirstChild("Auto") or mancing:FindFirstChild("AutoFishing"))
		if r and r:IsA("RemoteEvent") then r:FireServer(state); fired = true end
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
					if firesignal then firesignal(v.MouseButton1Click); firesignal(v.Activated)
					elseif getconnections then
						for _, c in ipairs(getconnections(v.MouseButton1Click)) do c:Fire() end
					end
					return
				end
			end
		end
	end)
end

-- PATCHED: pakai VirtualUser (1 call) supaya ringan
local function PerformTapClicker()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	local pos = getgenv().TapPosition or Vector2.new(vp.X * 0.85, vp.Y * 0.5)
	pcall(function() VirtualUser:ClickButton1(pos) end)
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
-- GLOBAL STATE
------------------------------------------------------------------
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
getgenv().KeyVerified = false
getgenv().AutoDetectCoreEvent = false
getgenv().LoopSpotEnabled = false
getgenv().SpotLoopConfig = {
	["Spot Mancing Jembatan"] = { Enabled = false, Timer = "10" },
	["Spot Mancing Core"] = { Enabled = false, Timer = "10" },
	["Spot Mancing Ikan Anomali"] = { Enabled = false, Timer = "10" }
}
getgenv().AutoFavoriteRunning = false
getgenv().FavRarities = {
	["Common"] = false, ["UnCommon"] = false, ["Rare"] = false, ["Epic"] = false,
	["Legendary"] = true, ["Mythical"] = true, ["Secret"] = true, ["Forgotten"] = true
}
getgenv().FavMutations = {
	["Galaxy"] = false, ["Corrupt"] = false, ["Gemstone"] = false, ["Ghost"] = false,
	["Lightning"] = false, ["Fairy Dust"] = true, ["Gold"] = false, ["Midnight"] = false,
	["Radioactive"] = false, ["Stone"] = false, ["Holographic"] = false, ["Albino"] = false,
	["Sandy"] = false, ["Cosmic"] = false, ["Normal"] = false, ["Elemental"] = false,
	["Festive"] = false, ["8-Bit"] = false, ["Bloodmoon"] = false, ["Abyssal"] = false,
	["Strawberry"] = false, ["Void"] = false, ["Cupid"] = false
}
getgenv().UnfavRarities = {
	["Common"] = false, ["UnCommon"] = false, ["Rare"] = false, ["Epic"] = false,
	["Legendary"] = false, ["Mythical"] = false, ["Secret"] = false, ["Forgotten"] = false
}
getgenv().UnfavMutations = {
	["Galaxy"] = false, ["Corrupt"] = false, ["Gemstone"] = false, ["Ghost"] = false,
	["Lightning"] = false, ["Fairy Dust"] = false, ["Gold"] = false, ["Midnight"] = false,
	["Radioactive"] = false, ["Stone"] = false, ["Holographic"] = false, ["Albino"] = false,
	["Sandy"] = false, ["Cosmic"] = false, ["Normal"] = false, ["Elemental"] = false,
	["Festive"] = false, ["8-Bit"] = false, ["Bloodmoon"] = false, ["Abyssal"] = false,
	["Strawberry"] = false, ["Void"] = false, ["Cupid"] = false
}

local FishingSpots = {
	["Spot Mancing Jembatan"] = CFrame.new(-6783.74756, 1322.81006, -9757.34473, 0.0899723172, -9.34088291e-08, 0.995944262, 1.76120434e-08, 1, 9.21981638e-08, -0.995944262, 9.24533072e-09, 0.0899723172),
	["Spot Mancing Core"] = CFrame.new(-9069.33887, 1250.32092, -6510.3374, 0.99812746, -7.96398965e-08, -0.0611686334, 8.05492206e-08, 1, 1.24000188e-08, 0.0611686334, -1.73038845e-08, 0.99812746),
	["Spot Mancing Ikan Anomali"] = CFrame.new(-8199.52832, 1238.83752, -6278.13135, -0.999144316, 1.1644854e-08, -0.0413601957, 1.63464247e-08, 1, -1.13335595e-07, 0.0413601957, -1.13914709e-07, -0.999144316)
}

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

------------------------------------------------------------------
-- ROD SETTINGS
------------------------------------------------------------------
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
		local rod = GetEquippedRod()
		local s = rod and rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Settings")
		local m = s and s:FindFirstChild("EnableMiniGame")
		if m then m.Value = true end
	end)
end

------------------------------------------------------------------
-- AUTO FISHING CYCLE (PATCHED: no new listener per cycle, higher poll)
------------------------------------------------------------------
local function RunAutoFishCycle(remoteFolder)
	pcall(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		OptimizeRodSettings()
		remoteFolder.CastEvent:FireServer(true)
		task.wait(0.05)
		remoteFolder.CastEvent:FireServer(false, 100, hrp.CFrame.LookVector)

		getgenv()._ubeyHooked = false
		local start = tick()
		while not getgenv()._ubeyHooked and getgenv().AutoFishingEventRunning
			and getgenv().UbeyConfig.MinigameMode == "Instant" do
			if tick() - start > 6 then break end
			task.wait(0.15)
		end
		getgenv()._ubeyHooked = false

		if getgenv().AutoFishingEventRunning and getgenv().UbeyConfig.MinigameMode == "Instant" then
			task.wait(tonumber(getgenv().BiteDelayInput) or 0.5)
			if getgenv().UbeyConfig.MinigameMode ~= "Instant" then return end
			local ts = remoteFolder:FindFirstChild("TandaSeruBersama")
			if ts then
				local c1 = Color3.fromRGB(23, 255, 151)
				local c2 = Color3.fromRGB(20, 20, 20)
				ts:FireServer(c1, c2, ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c1) }), 1.5)
			end
			task.wait(0.1)
			if getgenv().UbeyConfig.MinigameMode ~= "Instant" then return end
			remoteFolder.MiniGame:FireServer(true)
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
				task.wait(math.max(tonumber(getgenv().UbeyConfig.TapDelay) or 0.15, 0.12))
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
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local cur = hrp.CFrame
		hrp.CFrame = NpcSellCFrame + Vector3.new(0, 5, 0)
		task.wait(0.8)
		local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing")
		local jual = mancing and mancing:FindFirstChild("JualSemua")
		if jual then jual:InvokeServer() end
		task.wait(0.8)
		if getgenv().AutoFishingEventRunning then hrp.CFrame = cur end
	end)
end

local function GetInventoryRemote()
	local rs = ReplicatedStorage
	return rs:FindFirstChild("Remote") and rs.Remote:FindFirstChild("Mancing") and rs.Remote.Mancing:FindFirstChild("TandaiFavorit")
end

local function GetServerFishData()
	local list = {}
	pcall(function()
		local rs = ReplicatedStorage
		local ambil = rs:FindFirstChild("Remote") and rs.Remote:FindFirstChild("Inventaris") and rs.Remote.Inventaris:FindFirstChild("AmbilSemua")
		if ambil then
			local res = {ambil:InvokeServer()}
			local data = res[1]
			if type(data) == "table" then
				for _, f in ipairs(data) do
					if type(f) == "table" and (f.uid or f.UUID) then
						table.insert(list, {
							UUID = tostring(f.uid or f.UUID),
							Name = tostring(f.nama or f.Name or ""),
							Rarity = tostring(f.rarity or f.Rarity or ""),
							Mutation = tostring(f.mutasi or f.Mutation or ""),
							IsFavorited = f.favorit or f.IsFavorit or f.IsFavorite or false
						})
					end
				end
			end
		end
	end)
	return list
end

local function ProcessAutoFavorite()
	pcall(function()
		local tandai = GetInventoryRemote()
		if not tandai then return end
		for _, fish in ipairs(GetServerFishData()) do
			if not getgenv().AutoFavoriteRunning then break end
			local should = false
			local rl = string.lower(fish.Rarity)
			local ml = string.lower(fish.Mutation)
			for r, a in pairs(getgenv().FavRarities) do if a and string.lower(r) == rl then should = true end end
			for m, a in pairs(getgenv().FavMutations) do if a and string.find(ml, string.lower(m)) then should = true end end
			if should and not fish.IsFavorited then
				tandai:FireServer(fish.UUID, true)
				task.wait(0.12)
			end
		end
	end)
end

-- PATCHED: idle kalau OFF
task.spawn(function()
	while true do
		if getgenv().AutoFavoriteRunning then
			ProcessAutoFavorite()
			task.wait(2.5)
		else
			task.wait(1.5)
		end
	end
end)

local function UnfavoriteAllFish()
	task.spawn(function()
		pcall(function()
			local tandai = GetInventoryRemote()
			if not tandai then return end
			for _, fish in ipairs(GetServerFishData()) do
				tandai:FireServer(fish.UUID, false)
				task.wait(0.08)
			end
		end)
	end)
end

local function UnfavoriteByFilter()
	task.spawn(function()
		pcall(function()
			local tandai = GetInventoryRemote()
			if not tandai then return end
			for _, fish in ipairs(GetServerFishData()) do
				local u = false
				local rl = string.lower(fish.Rarity)
				local ml = string.lower(fish.Mutation)
				for r, a in pairs(getgenv().UnfavRarities) do if a and string.lower(r) == rl then u = true end end
				for m, a in pairs(getgenv().UnfavMutations) do if a and string.find(ml, string.lower(m)) then u = true end end
				if u and fish.IsFavorited then
					tandai:FireServer(fish.UUID, false)
					task.wait(0.08)
				end
			end
		end)
	end)
end

pcall(function() local g = PlayerGui:FindFirstChild("UbeyHub"); if g then g:Destroy() end end)

------------------------------------------------------------------
-- GUI
------------------------------------------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

local function MakeDraggable(o, h)
	h = h or o
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local d = input.Position - dragStart
		o.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
	h.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = o.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	h.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
end

------------------------------------------------------------------
-- KEY SYSTEM UI
------------------------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,185)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-92)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
KeyFrame.Visible = false
MakeDraggable(KeyFrame)
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0,15)
local KeyStroke = Instance.new("UIStroke", KeyFrame)
KeyStroke.Color = Color3.fromRGB(0,170,255)

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.Size = UDim2.new(1,0,0,50); KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "UBEY HUB V3 - HWID KEY SYSTEM"
KeyTitle.Font = Enum.Font.GothamBold; KeyTitle.TextColor3 = Color3.fromRGB(0,170,255); KeyTitle.TextSize = 14

local KeyBox = Instance.new("TextBox", KeyFrame)
KeyBox.Size = UDim2.new(0,340,0,38); KeyBox.Position = UDim2.new(0,20,0,60)
KeyBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
KeyBox.PlaceholderText = "Masukkan Key dari Bot Discord..."
KeyBox.Text = ""; KeyBox.TextColor3 = Color3.new(1,1,1)
KeyBox.Font = Enum.Font.Gotham; KeyBox.TextSize = 13
Instance.new("UICorner", KeyBox)

local SubmitKeyBtn = Instance.new("TextButton", KeyFrame)
SubmitKeyBtn.Size = UDim2.new(0,165,0,35); SubmitKeyBtn.Position = UDim2.new(0,20,0,110)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Perangkat"; SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold; SubmitKeyBtn.TextSize = 12
Instance.new("UICorner", SubmitKeyBtn)

local GetKeyDiscordBtn = Instance.new("TextButton", KeyFrame)
GetKeyDiscordBtn.Size = UDim2.new(0,165,0,35); GetKeyDiscordBtn.Position = UDim2.new(0,195,0,110)
GetKeyDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GetKeyDiscordBtn.Text = "Get Key via Discord"; GetKeyDiscordBtn.TextColor3 = Color3.new(1,1,1)
GetKeyDiscordBtn.Font = Enum.Font.GothamBold; GetKeyDiscordBtn.TextSize = 12
Instance.new("UICorner", GetKeyDiscordBtn)

local StatusKey = Instance.new("TextLabel", KeyFrame)
StatusKey.Size = UDim2.new(1,0,0,20); StatusKey.Position = UDim2.new(0,0,0,155)
StatusKey.BackgroundTransparency = 1; StatusKey.Text = ""
StatusKey.Font = Enum.Font.Gotham; StatusKey.TextColor3 = Color3.fromRGB(255,50,50); StatusKey.TextSize = 12

------------------------------------------------------------------
-- MAIN GUI
------------------------------------------------------------------
local Main = Instance.new("Frame", Gui)
Main.Visible = false
Main.Size = UDim2.new(0,550,0,320)
Main.Position = UDim2.new(0.5,-275,0.5,-160)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Main.ClipsDescendants = true
MakeDraggable(Main)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(0,170,255)

local ControlsFrame = Instance.new("Frame", Main)
ControlsFrame.Size = UDim2.new(0, 65, 0, 30)
ControlsFrame.Position = UDim2.new(1, -70, 0, 5)
ControlsFrame.BackgroundTransparency = 1; ControlsFrame.ZIndex = 10

local ControlLayout = Instance.new("UIListLayout", ControlsFrame)
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ControlLayout.Padding = UDim.new(0, 5)

local MinimizeBtn = Instance.new("TextButton", ControlsFrame)
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MinimizeBtn.Text = "-"; MinimizeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.TextSize = 18; MinimizeBtn.ZIndex = 11
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", ControlsFrame)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "×"; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18; CloseBtn.ZIndex = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local PingLabel = Instance.new("TextLabel", Main)
PingLabel.Size = UDim2.new(0,150,0,25); PingLabel.Position = UDim2.new(1,-225,0,7)
PingLabel.BackgroundTransparency = 1; PingLabel.Text = "Ping: Menghitung..."
PingLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
PingLabel.Font = Enum.Font.GothamBold; PingLabel.TextSize = 12
PingLabel.TextXAlignment = Enum.TextXAlignment.Right

-- PATCHED: hanya update saat GUI keliatan
task.spawn(function()
	while true do
		if Main.Visible then
			pcall(function()
				local pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				PingLabel.Text = "📡 Ping: " .. pingVal .. " ms"
			end)
			task.wait(1)
		else
			task.wait(2)
		end
	end
end)

local Sidebar = Instance.new("ScrollingFrame", Main)
Sidebar.Size = UDim2.new(0,140,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,20)
Sidebar.CanvasSize = UDim2.new(0,0,2.6,0)
Sidebar.ScrollBarThickness = 2
Instance.new("UICorner", Sidebar)

local HubTitle = Instance.new("TextLabel", Sidebar)
HubTitle.BackgroundTransparency = 1; HubTitle.Position = UDim2.new(0, 0, 0, 8)
HubTitle.Size = UDim2.new(1, 0, 0, 22)
HubTitle.Text = "UBEY HUB"; HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextColor3 = Color3.fromRGB(0, 170, 255); HubTitle.TextSize = 17

local HubSubTitle = Instance.new("TextLabel", Sidebar)
HubSubTitle.BackgroundTransparency = 1; HubSubTitle.Position = UDim2.new(0, 0, 0, 32)
HubSubTitle.Size = UDim2.new(1, 0, 0, 18)
HubSubTitle.Text = "👑 Premium"; HubSubTitle.Font = Enum.Font.GothamBold
HubSubTitle.TextColor3 = Color3.fromRGB(255, 215, 0); HubSubTitle.TextSize = 12

local Content = Instance.new("Frame", Main)
Content.Position = UDim2.new(0,150,0,30)
Content.Size = UDim2.new(1,-160,1,-40)
Content.BackgroundTransparency = 1

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	MinimizeBtn.Text = isMinimized and "+" or "-"
	Main:TweenSize(isMinimized and UDim2.new(0,550,0,38) or UDim2.new(0,550,0,320),
		Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
	Sidebar.Visible = not isMinimized
	Content.Visible = not isMinimized
	PingLabel.Visible = not isMinimized
end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local function CreateNavButton(text, yPos)
	local btn = Instance.new("TextButton", Sidebar)
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	btn.Text = text; btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12
	Instance.new("UICorner", btn)
	return btn
end

local HomeBtn = CreateNavButton("Fishing & Sell", 60)
local FavoriteBtn = CreateNavButton("⭐ Favorite", 95)
local GalatamaBtn = CreateNavButton("Galatama", 130)
local TeleportShopBtn = CreateNavButton("Teleport Shop", 165)
local SummitBtn = CreateNavButton("Summit", 200)
local PlayerMenuBtn = CreateNavButton("Player", 235)
local HaloMenuBtn = CreateNavButton("Halo Kepala", 270)
local PlayerTpBtn = CreateNavButton("Teleport Player", 305)
local PrivacyBtn = CreateNavButton("Privacy", 340)
local SettingsBtn = CreateNavButton("Settings", 375)
local CreditsBtn = CreateNavButton("Credits", 410)
local LarpBtn = CreateNavButton("🎭 Larp", 445)

local function MakePage()
	local f = Instance.new("ScrollingFrame", Content)
	f.Size = UDim2.new(1,0,1,0); f.BackgroundTransparency = 1
	f.Visible = false; f.CanvasSize = UDim2.new(0,0,6,0); f.ScrollBarThickness = 4
	local pad = Instance.new("UIPadding", f)
	pad.PaddingTop = UDim.new(0, 10)
	local l = Instance.new("UIListLayout", f)
	l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 8)
	return f
end

local FishingPage = MakePage(); FishingPage.Visible = true
local FavoritePage = MakePage()
local GalatamaPage = MakePage()
local TeleportShopPage = MakePage()
local SummitPage = MakePage()
local PlayerPage = MakePage()
local HaloPage = MakePage()
local PlayerTpPage = MakePage()
local PrivacyPage = MakePage()
local SettingsPage = MakePage()
local CreditsPage = MakePage()
local LarpPage = MakePage()

local function HideAll()
	for _, p in ipairs({FishingPage, FavoritePage, GalatamaPage, TeleportShopPage, SummitPage,
		PlayerPage, HaloPage, PlayerTpPage, PrivacyPage, SettingsPage, CreditsPage, LarpPage}) do
		p.Visible = false
	end
end

HomeBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
FavoriteBtn.MouseButton1Click:Connect(function() HideAll(); FavoritePage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
TeleportShopBtn.MouseButton1Click:Connect(function() HideAll(); TeleportShopPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerMenuBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
HaloMenuBtn.MouseButton1Click:Connect(function() HideAll(); HaloPage.Visible = true end)
PlayerTpBtn.MouseButton1Click:Connect(function() HideAll(); PlayerTpPage.Visible = true end)
PrivacyBtn.MouseButton1Click:Connect(function() HideAll(); PrivacyPage.Visible = true end)
SettingsBtn.MouseButton1Click:Connect(function() HideAll(); SettingsPage.Visible = true end)
CreditsBtn.MouseButton1Click:Connect(function() HideAll(); CreditsPage.Visible = true end)
LarpBtn.MouseButton1Click:Connect(function() HideAll(); LarpPage.Visible = true end)

local function AddToggle(parent, text, callback)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(1,0,0,35)
	b.BackgroundColor3 = Color3.fromRGB(30,30,40)
	b.Text = "  " .. text .. " [OFF]"
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.Gotham; b.TextSize = 13
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

------------------------------------------------------------------
-- KEY VALIDATION
------------------------------------------------------------------
GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function() if setclipboard then setclipboard("https://discord.gg/YXuYeEpnXE") end end)
	StatusKey.TextColor3 = Color3.fromRGB(0,170,255)
	StatusKey.Text = "Link Discord disalin!"
end)

local function ValidateKey(enteredKey, isAutoLogin)
	if enteredKey == "" then
		if not isAutoLogin then
			StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
			StatusKey.Text = "Masukkan key terlebih dahulu!"
		end
		KeyFrame.Visible = true
		return
	end
	if not isAutoLogin then
		StatusKey.TextColor3 = Color3.fromRGB(255,200,0)
		StatusKey.Text = "Memeriksa HWID & Key ke Server..."
	end
	task.spawn(function()
		local requestFunc = syn and syn.request or http and http.request or request
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({
					Url = SUPABASE_URL .. enteredKey, Method = "GET",
					Headers = { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY, ["Content-Type"] = "application/json" }
				})
				return res.Body
			else
				return HttpService:GetAsync(SUPABASE_URL .. HttpService:UrlEncode(enteredKey), false,
					{ ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY })
			end
		end)
		if success and response then
			local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
			if ok and data and #data > 0 then
				local r = data[1]
				if r.status == false or r.status == "inactive" or r.status == "used" then
					if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Key sudah tidak aktif!" end
					KeyFrame.Visible = true; return
				end
				if r.hwid_value and r.hwid_value ~= "" and r.hwid_value ~= CurrentHWID then
					if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Key terikat di perangkat lain!" end
					KeyFrame.Visible = true; return
				end
				pcall(function() if writefile then writefile(KEY_FILE, enteredKey) end end)
				getgenv().KeyVerified = true
				KeyFrame.Visible = false
				Main.Visible = true
			else
				if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Key Salah atau Tidak Ditemukan!" end
				KeyFrame.Visible = true
			end
		else
			if not isAutoLogin then StatusKey.TextColor3 = Color3.fromRGB(255,50,50) StatusKey.Text = "Gagal terhubung ke database." end
			KeyFrame.Visible = true
		end
	end)
end

SubmitKeyBtn.MouseButton1Click:Connect(function() ValidateKey(KeyBox.Text, false) end)
task.spawn(function()
	if readfile and isfile and isfile(KEY_FILE) then
		local savedKey = readfile(KEY_FILE)
		if savedKey and savedKey ~= "" then
			KeyBox.Text = savedKey
			ValidateKey(savedKey, true)
		else KeyFrame.Visible = true end
	else KeyFrame.Visible = true end
end)

------------------------------------------------------------------
-- 1. FISHING PAGE
------------------------------------------------------------------
local TitleFish = Instance.new("TextLabel", FishingPage)
TitleFish.Size = UDim2.new(1,0,0,30); TitleFish.BackgroundTransparency = 1
TitleFish.Text = "🔥 AUTO FISHING & SELL UTILITIES"
TitleFish.TextColor3 = Color3.fromRGB(0,170,255)
TitleFish.Font = Enum.Font.GothamBold; TitleFish.TextSize = 13

local SpotDropdownFrame = Instance.new("Frame", FishingPage)
SpotDropdownFrame.Size = UDim2.new(1,0,0,35)
SpotDropdownFrame.BackgroundColor3 = Color3.fromRGB(30,30,40)
SpotDropdownFrame.ClipsDescendants = true
Instance.new("UICorner", SpotDropdownFrame)

local DropHeader = Instance.new("TextButton", SpotDropdownFrame)
DropHeader.Size = UDim2.new(1,0,0,35); DropHeader.BackgroundTransparency = 1
DropHeader.Text = "  📍 Spot: " .. (getgenv().SelectedFishingSpot or "Spot Mancing Jembatan") .. " 🔽"
DropHeader.TextColor3 = Color3.fromRGB(0, 170, 255)
DropHeader.Font = Enum.Font.GothamBold; DropHeader.TextSize = 11
DropHeader.TextXAlignment = Enum.TextXAlignment.Left

local function SetSpotDisplay(t) DropHeader.Text = "  📍 Spot: " .. tostring(t) .. " 🔽" end

local DropContainer = Instance.new("Frame", SpotDropdownFrame)
DropContainer.Position = UDim2.new(0, 5, 0, 35)
DropContainer.Size = UDim2.new(1, -10, 0, 95)
DropContainer.BackgroundTransparency = 1
local DropLayout = Instance.new("UIListLayout", DropContainer)
DropLayout.Padding = UDim.new(0, 4)

local isDropOpen = false
DropHeader.MouseButton1Click:Connect(function()
	isDropOpen = not isDropOpen
	SpotDropdownFrame:TweenSize(isDropOpen and UDim2.new(1,0,0,135) or UDim2.new(1,0,0,35),
		Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
end)

for _, name in ipairs({"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}) do
	local opt = Instance.new("TextButton", DropContainer)
	opt.Size = UDim2.new(1,0,0,26)
	opt.BackgroundColor3 = Color3.fromRGB(40,40,50)
	opt.Text = "  " .. name
	opt.TextColor3 = Color3.new(1,1,1); opt.Font = Enum.Font.Gotham
	opt.TextSize = 11; opt.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", opt)
	opt.MouseButton1Click:Connect(function()
		getgenv().SelectedFishingSpot = name
		getgenv().UbeyConfig.SelectedSpot = name
		SetSpotDisplay(name)
		isDropOpen = false
		SpotDropdownFrame:TweenSize(UDim2.new(1,0,0,35), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
		SaveConfig()
	end)
end

local ModeDropdownFrame = Instance.new("Frame", FishingPage)
ModeDropdownFrame.Size = UDim2.new(1,0,0,35)
ModeDropdownFrame.BackgroundColor3 = Color3.fromRGB(30,30,40)
ModeDropdownFrame.ClipsDescendants = true
Instance.new("UICorner", ModeDropdownFrame)

local ModeDropHeader = Instance.new("TextButton", ModeDropdownFrame)
ModeDropHeader.Size = UDim2.new(1,0,0,35); ModeDropHeader.BackgroundTransparency = 1
ModeDropHeader.Text = "  🎮 Mode Fishing: " .. (getgenv().UbeyConfig.MinigameMode or "Legit") .. " 🔽"
ModeDropHeader.TextColor3 = Color3.fromRGB(255, 200, 0)
ModeDropHeader.Font = Enum.Font.GothamBold; ModeDropHeader.TextSize = 11
ModeDropHeader.TextXAlignment = Enum.TextXAlignment.Left

local ModeDropContainer = Instance.new("Frame", ModeDropdownFrame)
ModeDropContainer.Position = UDim2.new(0, 5, 0, 35)
ModeDropContainer.Size = UDim2.new(1, -10, 0, 60)
ModeDropContainer.BackgroundTransparency = 1
local ModeDropLayout = Instance.new("UIListLayout", ModeDropContainer)
ModeDropLayout.Padding = UDim.new(0, 4)

local isModeDropOpen = false
ModeDropHeader.MouseButton1Click:Connect(function()
	isModeDropOpen = not isModeDropOpen
	ModeDropdownFrame:TweenSize(isModeDropOpen and UDim2.new(1,0,0,100) or UDim2.new(1,0,0,35),
		Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
end)

for _, m in ipairs({
	{ Name = "Legit Fishing (Auto Bawaan + Tap-Tap)", Value = "Legit" },
	{ Name = "Instant Fishing (Bypass Cepat)", Value = "Instant" }
}) do
	local opt = Instance.new("TextButton", ModeDropContainer)
	opt.Size = UDim2.new(1,0,0,26)
	opt.BackgroundColor3 = Color3.fromRGB(40,40,50)
	opt.Text = "  " .. m.Name
	opt.TextColor3 = Color3.new(1,1,1); opt.Font = Enum.Font.Gotham
	opt.TextSize = 11; opt.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", opt)
	opt.MouseButton1Click:Connect(function()
		local old = getgenv().UbeyConfig.MinigameMode
		getgenv().UbeyConfig.MinigameMode = m.Value
		ModeDropHeader.Text = "  🎮 Mode Fishing: " .. m.Value .. " 🔽"
		isModeDropOpen = false
		ModeDropdownFrame:TweenSize(UDim2.new(1,0,0,35), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
		SaveConfig()
		if old ~= m.Value then
			task.spawn(function()
				local was = getgenv().AutoFishingEventRunning
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
				if was and getgenv().AutoFishingEventRunning then StartFishingLoop() end
			end)
		end
	end)
end

AddToggle(FishingPage, "Smart Auto Fishing + Teleport", function(v)
	getgenv().AutoFishingEventRunning = v
	if v then
		pcall(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)
			if hrp then hrp.CFrame = FishingSpots[getgenv().SelectedFishingSpot] + Vector3.new(0, 5, 0) end
		end)
		StartFishingLoop()
	end
end)

AddToggle(FishingPage, "Smart Auto Fishing (Di Tempat Saja)", function(v)
	getgenv().AutoFishingEventRunning = v
	if v then StartFishingLoop() end
end)

local BiteDelayBox = Instance.new("TextBox", FishingPage)
BiteDelayBox.Size = UDim2.new(1,0,0,35)
BiteDelayBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
BiteDelayBox.PlaceholderText = "Bite Delay (Detik, Cth: 0.5) - Mode Instant"
BiteDelayBox.Text = tostring(getgenv().UbeyConfig.BiteDelay)
BiteDelayBox.TextColor3 = Color3.new(1,1,1)
BiteDelayBox.Font = Enum.Font.Gotham; BiteDelayBox.TextSize = 12
Instance.new("UICorner", BiteDelayBox)
BiteDelayBox.FocusLost:Connect(function()
	getgenv().BiteDelayInput = BiteDelayBox.Text
	getgenv().UbeyConfig.BiteDelay = BiteDelayBox.Text
	SaveConfig()
end)

local TapDelayBox = Instance.new("TextBox", FishingPage)
TapDelayBox.Size = UDim2.new(1,0,0,35)
TapDelayBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
TapDelayBox.PlaceholderText = "Jeda Tap (Detik, Cth: 0.15) - Mode Legit"
TapDelayBox.Text = tostring(getgenv().UbeyConfig.TapDelay or "0.15")
TapDelayBox.TextColor3 = Color3.new(1,1,1)
TapDelayBox.Font = Enum.Font.Gotham; TapDelayBox.TextSize = 12
Instance.new("UICorner", TapDelayBox)
TapDelayBox.FocusLost:Connect(function()
	getgenv().UbeyConfig.TapDelay = TapDelayBox.Text
	SaveConfig()
end)

-- PATCHED: sell timer 1s -> 5s
AddToggle(FishingPage, "Auto Sell Timer ke NPC", function(v)
	getgenv().AutoSellRunning = v
	if v then
		task.spawn(function()
			local lastSellTime = tick()
			while getgenv().AutoSellRunning do
				task.wait(5)
				if ((tick() - lastSellTime) / 60) >= (tonumber(getgenv().AutoSellTimerInput) or 5) then
					TriggerSellToNpc()
					lastSellTime = tick()
				end
			end
		end)
	end
end)

local SellTimerBox = Instance.new("TextBox", FishingPage)
SellTimerBox.Size = UDim2.new(1,0,0,35)
SellTimerBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
SellTimerBox.PlaceholderText = "Jeda Waktu Jual (Menit, Cth: 5)"
SellTimerBox.Text = tostring(getgenv().UbeyConfig.AutoSellTimer)
SellTimerBox.TextColor3 = Color3.new(1,1,1)
SellTimerBox.Font = Enum.Font.Gotham; SellTimerBox.TextSize = 12
Instance.new("UICorner", SellTimerBox)
SellTimerBox.FocusLost:Connect(function()
	getgenv().AutoSellTimerInput = SellTimerBox.Text
	getgenv().UbeyConfig.AutoSellTimer = SellTimerBox.Text
	SaveConfig()
end)

local TitleLoop = Instance.new("TextLabel", FishingPage)
TitleLoop.Size = UDim2.new(1,0,0,25); TitleLoop.BackgroundTransparency = 1
TitleLoop.Text = "⏳ ROTASI AUTO SPOT MANCING (TIMER)"
TitleLoop.TextColor3 = Color3.fromRGB(0,255,170)
TitleLoop.Font = Enum.Font.GothamBold; TitleLoop.TextSize = 13

AddToggle(FishingPage, "Aktifkan Loop Spot Mancing (Timer)", function(v) getgenv().LoopSpotEnabled = v end)

local function CreateSpotTimerSetting(parent, spotName)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(1,0,0,35)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,40)
	Instance.new("UICorner", frame)
	local toggleBtn = Instance.new("TextButton", frame)
	toggleBtn.Size = UDim2.new(0.65,0,1,0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = "  " .. spotName .. " [OFF]"
	toggleBtn.TextColor3 = Color3.new(1,1,1)
	toggleBtn.Font = Enum.Font.Gotham; toggleBtn.TextSize = 11
	toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
	local timeBox = Instance.new("TextBox", frame)
	timeBox.Size = UDim2.new(0.3, -5, 0, 25)
	timeBox.Position = UDim2.new(0.7, 0, 0, 5)
	timeBox.BackgroundColor3 = Color3.fromRGB(45,45,55)
	timeBox.Text = getgenv().SpotLoopConfig[spotName].Timer
	timeBox.PlaceholderText = "Menit"
	timeBox.TextColor3 = Color3.fromRGB(0,170,255)
	timeBox.Font = Enum.Font.GothamBold; timeBox.TextSize = 11
	Instance.new("UICorner", timeBox)
	toggleBtn.MouseButton1Click:Connect(function()
		local cur = not getgenv().SpotLoopConfig[spotName].Enabled
		getgenv().SpotLoopConfig[spotName].Enabled = cur
		toggleBtn.Text = "  " .. spotName .. (cur and " [ON]" or " [OFF]")
		toggleBtn.TextColor3 = cur and Color3.fromRGB(0,255,150) or Color3.new(1,1,1)
	end)
	timeBox.FocusLost:Connect(function() getgenv().SpotLoopConfig[spotName].Timer = timeBox.Text end)
end

CreateSpotTimerSetting(FishingPage, "Spot Mancing Jembatan")
CreateSpotTimerSetting(FishingPage, "Spot Mancing Core")
CreateSpotTimerSetting(FishingPage, "Spot Mancing Ikan Anomali")

-- PATCHED: idle saat OFF
task.spawn(function()
	local spotOrder = {"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}
	while true do
		if getgenv().LoopSpotEnabled and not getgenv().AutoDetectCoreEvent then
			for _, name in ipairs(spotOrder) do
				local cfg = getgenv().SpotLoopConfig[name]
				if getgenv().LoopSpotEnabled and cfg and cfg.Enabled then
					getgenv().SelectedFishingSpot = name
					SetSpotDisplay(name)
					pcall(function()
						local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						if hrp and FishingSpots[name] then hrp.CFrame = FishingSpots[name] + Vector3.new(0, 5, 0) end
					end)
					local duration = (tonumber(cfg.Timer) or 10) * 60
					local timerStart = tick()
					while getgenv().LoopSpotEnabled and cfg.Enabled and (tick() - timerStart < duration) do
						task.wait(1)
					end
				end
			end
			task.wait(1)
		else
			task.wait(2)
		end
	end
end)

------------------------------------------------------------------
-- MULTI-SELECT DROPDOWN
------------------------------------------------------------------
local function CreateMultiSelectDropdown(parent, titleText, optionsTable, targetStateTable)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1,0,0,40)
	container.BackgroundColor3 = Color3.fromRGB(30,30,40)
	container.ClipsDescendants = true
	Instance.new("UICorner", container)

	local header = Instance.new("TextButton", container)
	header.Size = UDim2.new(1,0,0,40); header.BackgroundTransparency = 1
	header.Text = "  " .. titleText
	header.TextColor3 = Color3.new(1,1,1)
	header.Font = Enum.Font.GothamMedium; header.TextSize = 12
	header.TextXAlignment = Enum.TextXAlignment.Left

	local countLabel = Instance.new("TextLabel", header)
	countLabel.Size = UDim2.new(0,120,1,0); countLabel.Position = UDim2.new(1,-130,0,0)
	countLabel.BackgroundTransparency = 1
	countLabel.TextColor3 = Color3.fromRGB(0,170,255)
	countLabel.Font = Enum.Font.GothamBold; countLabel.TextSize = 11
	countLabel.TextXAlignment = Enum.TextXAlignment.Right

	local holder = Instance.new("Frame", container)
	holder.Position = UDim2.new(0,5,0,40)
	holder.Size = UDim2.new(1,-10,0,0)
	holder.BackgroundTransparency = 1
	local listL = Instance.new("UIListLayout", holder)
	listL.SortOrder = Enum.SortOrder.LayoutOrder; listL.Padding = UDim.new(0, 4)

	local itemButtons = {}
	local function UpdateSummary()
		local c = 0
		for _, a in pairs(targetStateTable) do if a then c = c + 1 end end
		if c == 0 then countLabel.Text = "None 🔽"
		elseif c == #optionsTable then countLabel.Text = "All (" .. c .. ") 🔽"
		else countLabel.Text = c .. " Selected 🔽" end
	end

	local saBtn = Instance.new("TextButton", holder)
	saBtn.Size = UDim2.new(1,0,0,28)
	saBtn.BackgroundColor3 = Color3.fromRGB(0,150,120)
	saBtn.Text = "  ⚡ SELECT ALL / UNSELECT ALL"
	saBtn.TextColor3 = Color3.new(1,1,1); saBtn.Font = Enum.Font.GothamBold
	saBtn.TextSize = 11; saBtn.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", saBtn)
	local all = false
	saBtn.MouseButton1Click:Connect(function()
		all = not all
		for _, opt in ipairs(optionsTable) do targetStateTable[opt] = all end
		for n, b in pairs(itemButtons) do
			b.BackgroundColor3 = all and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
			b.Text = "  " .. n .. (all and "  [✓]" or "  [ ]")
		end
		UpdateSummary(); SaveConfig()
	end)

	for _, optName in ipairs(optionsTable) do
		local opt = Instance.new("TextButton", holder)
		opt.Size = UDim2.new(1,0,0,28)
		opt.BackgroundColor3 = targetStateTable[optName] and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
		opt.Text = "  " .. optName .. (targetStateTable[optName] and "  [✓]" or "  [ ]")
		opt.TextColor3 = Color3.new(1,1,1); opt.Font = Enum.Font.Gotham
		opt.TextSize = 11; opt.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UICorner", opt)
		itemButtons[optName] = opt
		opt.MouseButton1Click:Connect(function()
			targetStateTable[optName] = not targetStateTable[optName]
			opt.BackgroundColor3 = targetStateTable[optName] and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,50)
			opt.Text = "  " .. optName .. (targetStateTable[optName] and "  [✓]" or "  [ ]")
			UpdateSummary(); SaveConfig()
		end)
	end
	UpdateSummary()
	local isOpen = false
	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		container:TweenSize(isOpen and UDim2.new(1,0,0, 45 + ((#optionsTable + 1) * 32)) or UDim2.new(1,0,0,40),
			Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
	end)
end

------------------------------------------------------------------
-- 2. FAVORITE PAGE
------------------------------------------------------------------
local TitleFav = Instance.new("TextLabel", FavoritePage)
TitleFav.Size = UDim2.new(1,0,0,25); TitleFav.BackgroundTransparency = 1
TitleFav.Text = "⭐ AUTO FAVORITE FILTER"
TitleFav.TextColor3 = Color3.fromRGB(0,170,255)
TitleFav.Font = Enum.Font.GothamBold; TitleFav.TextSize = 13

AddToggle(FavoritePage, "AUTO FAVORITE", function(v) getgenv().AutoFavoriteRunning = v end)

local rarityList = {"Common", "UnCommon", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Forgotten"}
local mutationList = {
	"Galaxy", "Corrupt", "Gemstone", "Ghost", "Lightning", "Fairy Dust",
	"Gold", "Midnight", "Radioactive", "Stone", "Holographic", "Albino", "Sandy", "Cosmic",
	"Elemental", "Festive", "8-Bit", "Bloodmoon", "Abyssal", "Strawberry", "Void", "Cupid"
}

CreateMultiSelectDropdown(FavoritePage, "Fav Filter Rarity", rarityList, getgenv().FavRarities)
CreateMultiSelectDropdown(FavoritePage, "Fav Filter Mutasi", mutationList, getgenv().FavMutations)

local TitleUnfav = Instance.new("TextLabel", FavoritePage)
TitleUnfav.Size = UDim2.new(1,0,0,25); TitleUnfav.BackgroundTransparency = 1
TitleUnfav.Text = "🗑️ UNFAVORITE FILTER SETTINGS"
TitleUnfav.TextColor3 = Color3.fromRGB(255,100,100)
TitleUnfav.Font = Enum.Font.GothamBold; TitleUnfav.TextSize = 13

CreateMultiSelectDropdown(FavoritePage, "Unfav Filter Rarity", rarityList, getgenv().UnfavRarities)
CreateMultiSelectDropdown(FavoritePage, "Unfav Filter Mutasi", mutationList, getgenv().UnfavMutations)

local UnfavFilterBtn = Instance.new("TextButton", FavoritePage)
UnfavFilterBtn.Size = UDim2.new(1,0,0,38)
UnfavFilterBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 30)
UnfavFilterBtn.Text = "🎯 UNFAVORITE BY FILTER"
UnfavFilterBtn.TextColor3 = Color3.new(1,1,1)
UnfavFilterBtn.Font = Enum.Font.GothamBold; UnfavFilterBtn.TextSize = 12
Instance.new("UICorner", UnfavFilterBtn)
UnfavFilterBtn.MouseButton1Click:Connect(UnfavoriteByFilter)

local UnfavBtn = Instance.new("TextButton", FavoritePage)
UnfavBtn.Size = UDim2.new(1,0,0,38)
UnfavBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
UnfavBtn.Text = "🚨 UNFAVORITE ALL FISH"
UnfavBtn.TextColor3 = Color3.new(1,1,1)
UnfavBtn.Font = Enum.Font.GothamBold; UnfavBtn.TextSize = 12
Instance.new("UICorner", UnfavBtn)
UnfavBtn.MouseButton1Click:Connect(UnfavoriteAllFish)

------------------------------------------------------------------
-- 3. GALATAMA PAGE
------------------------------------------------------------------
local TitleGal = Instance.new("TextLabel", GalatamaPage)
TitleGal.Size = UDim2.new(1,0,0,30); TitleGal.BackgroundTransparency = 1
TitleGal.Text = "🏆 GALATAMA & CORE EVENT UTILITIES"
TitleGal.TextColor3 = Color3.fromRGB(0,170,255)
TitleGal.Font = Enum.Font.GothamBold; TitleGal.TextSize = 13

local TpGalBtn = Instance.new("TextButton", GalatamaPage)
TpGalBtn.Size = UDim2.new(1,0,0,35)
TpGalBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
TpGalBtn.Text = "📍 Teleport ke Galatama"
TpGalBtn.TextColor3 = Color3.new(1,1,1)
TpGalBtn.Font = Enum.Font.GothamBold; TpGalBtn.TextSize = 13
Instance.new("UICorner", TpGalBtn)
TpGalBtn.MouseButton1Click:Connect(function()
	pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-8008.12744, 1227.96838, -6091.92627) + Vector3.new(0, 5, 0) end)
end)

AddToggle(GalatamaPage, "Aktifkan Auto Join Galatama", function(v)
	getgenv().AutoGalatamaRunning = v
	if v then
		task.spawn(function()
			while getgenv().AutoGalatamaRunning do
				pcall(function()
					local g = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Glatama") and ReplicatedStorage.Remote.Glatama:FindFirstChild("Ikut")
					if g then g:InvokeServer() end
				end)
				task.wait(10)
			end
		end)
	end
end)

local TitleCoreEvent = Instance.new("TextLabel", GalatamaPage)
TitleCoreEvent.Size = UDim2.new(1,0,0,25); TitleCoreEvent.BackgroundTransparency = 1
TitleCoreEvent.Text = "💎 AUTO DETECT WITHERING CORE EVENT"
TitleCoreEvent.TextColor3 = Color3.fromRGB(255,200,0)
TitleCoreEvent.Font = Enum.Font.GothamBold; TitleCoreEvent.TextSize = 13

AddToggle(GalatamaPage, "Auto Teleport Saat Event Core Berlangsung", function(v) getgenv().AutoDetectCoreEvent = v end)

local SavedPreviousSpot, IsAtCoreEvent = nil, false

task.spawn(function()
	while true do
		if getgenv().AutoDetectCoreEvent then
			pcall(function()
				local m = tonumber(os.date("%M"))
				local isEvent = (m >= 0 and m <= 10)
				if isEvent then
					if not IsAtCoreEvent then SavedPreviousSpot = getgenv().SelectedFishingSpot; IsAtCoreEvent = true end
					getgenv().SelectedFishingSpot = "Spot Mancing Core"
					SetSpotDisplay("Spot Mancing Core (⚡ Event Core)")
					local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					local cf = FishingSpots["Spot Mancing Core"]
					if hrp and cf and (hrp.Position - cf.Position).Magnitude > 20 then
						hrp.CFrame = cf + Vector3.new(0, 5, 0)
					end
				else
					if IsAtCoreEvent then
						IsAtCoreEvent = false
						if SavedPreviousSpot and FishingSpots[SavedPreviousSpot] then
							getgenv().SelectedFishingSpot = SavedPreviousSpot
							SetSpotDisplay(SavedPreviousSpot)
							local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
							if hrp and FishingSpots[SavedPreviousSpot] then
								hrp.CFrame = FishingSpots[SavedPreviousSpot] + Vector3.new(0, 5, 0)
							end
						end
					end
				end
			end)
			task.wait(5)
		else
			task.wait(3)
		end
	end
end)

------------------------------------------------------------------
-- 4. TELEPORT SHOP
------------------------------------------------------------------
local TitleShop = Instance.new("TextLabel", TeleportShopPage)
TitleShop.Size = UDim2.new(1,0,0,30); TitleShop.BackgroundTransparency = 1
TitleShop.Text = "🛒 TELEPORT TO SHOPS & NPCS"
TitleShop.TextColor3 = Color3.fromRGB(0,170,255)
TitleShop.Font = Enum.Font.GothamBold; TitleShop.TextSize = 13

local function AddShopBtn(name, cf)
	local b = Instance.new("TextButton", TeleportShopPage)
	b.Size = UDim2.new(1,0,0,35)
	b.BackgroundColor3 = Color3.fromRGB(35,35,45)
	b.Text = "📍 Teleport ke " .. name
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamMedium; b.TextSize = 12
	Instance.new("UICorner", b)
	b.MouseButton1Click:Connect(function()
		pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = cf + Vector3.new(0, 5, 0) end)
	end)
end

AddShopBtn("Tempat Jual Ikan", CFrame.new(-6668.79785, 1312.69983, -9964.06152))
AddShopBtn("Skin Shop", CFrame.new(-6639.45947, 1312.69983, -9947.36133))
AddShopBtn("Pet Shop", CFrame.new(-6640.44092, 1312.69983, -9917.93652))
AddShopBtn("Upgrade Pet", CFrame.new(-6637.85156, 1312.69983, -9886.52441))
AddShopBtn("Rod Shop", CFrame.new(-6638.09521, 1312.69983, -9857.41797))
AddShopBtn("Title Shop", CFrame.new(-6667.0249, 1312.69983, -9843.66113))

------------------------------------------------------------------
-- 5. SUMMIT PAGE (PATCHED: watchdog idle 2s saat OFF)
------------------------------------------------------------------
local TitleSum = Instance.new("TextLabel", SummitPage)
TitleSum.Size = UDim2.new(1,0,0,30); TitleSum.BackgroundTransparency = 1
TitleSum.Text = "⛰️ AUTO SUMMIT FARM (INSTANT TP)"
TitleSum.TextColor3 = Color3.fromRGB(0,170,255)
TitleSum.Font = Enum.Font.GothamBold; TitleSum.TextSize = 13

getgenv().SummitDelay = 1
getgenv().SummitCpHeight = 1.5
getgenv().SummitUseRemote = false
getgenv().SummitHeight = 6

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

AddToggle(SummitPage, "Auto Summit Loop (Instant TP)", function(v)
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

local function AddSummitBox(ph, def, onChange)
	local b = Instance.new("TextBox", SummitPage)
	b.Size = UDim2.new(1,0,0,35)
	b.BackgroundColor3 = Color3.fromRGB(35,35,45)
	b.PlaceholderText = ph; b.Text = tostring(def)
	b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Gotham; b.TextSize = 12
	Instance.new("UICorner", b)
	b.FocusLost:Connect(function()
		local n = tonumber(b.Text)
		if n then onChange(n) end
	end)
end

AddSummitBox("Tinggi di titik Tengah (Cth: 6)", 6, function(n) getgenv().SummitHeight = n end)
AddSummitBox("Tinggi di titik Cp (Cth: 1.5)", 1.5, function(n) getgenv().SummitCpHeight = n end)
AddToggle(SummitPage, "Pakai Remote Checkpoint (opsional)", function(v) getgenv().SummitUseRemote = v end)
AddSummitBox("Jeda di tiap Cp (detik, Cth: 1)", 1, function(n) getgenv().SummitDelay = math.max(n, 0) end)

getgenv().SummitRunId = 0
getgenv().SummitLoopCount = 0
getgenv().SummitRecoverCount = 0

local SummitState = { index = 1, last = tick() }

local SummitStatusLabel = Instance.new("TextLabel", SummitPage)
SummitStatusLabel.Size = UDim2.new(1,0,0,25); SummitStatusLabel.BackgroundTransparency = 1
SummitStatusLabel.Text = "Status: Idle"
SummitStatusLabel.TextColor3 = Color3.fromRGB(0,255,170)
SummitStatusLabel.Font = Enum.Font.GothamBold; SummitStatusLabel.TextSize = 11
SummitStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local function SetSummitStatus(text)
	SummitStatusLabel.Text = string.format("Status: %s | Putaran: %d | Recovery: %d",
		tostring(text), getgenv().SummitLoopCount, getgenv().SummitRecoverCount)
end

local function SummitTick() SummitState.last = tick() end

local function GetLiveCharacter()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum and hum.Health > 0 then return hrp, hum end
	return nil
end

local function WaitForLiveCharacter(alive, maxWait)
	local w = 0
	while alive() and w < maxWait do
		local hrp, hum = GetLiveCharacter()
		if hrp then return hrp, hum end
		SummitTick(); task.wait(0.25); w = w + 0.25
	end
	return nil
end

local function StreamAroundBounded(pos, maxWait)
	local done = false
	task.spawn(function()
		pcall(function() LocalPlayer:RequestStreamAroundAsync(pos, 2) end)
		done = true
	end)
	local t = 0
	while not done and t < maxWait do task.wait(0.05); t = t + 0.05 end
end

local function TouchCheckpoint(cpNumber, approxCF, alive)
	local part, w = nil, 0
	while alive() and w < 2 do
		local folder = Workspace:FindFirstChild("Checkpoint")
		part = folder and folder:FindFirstChild("Checkpoint " .. tostring(cpNumber))
		if part and part:IsA("BasePart") then break end
		part = nil; task.wait(0.2); w = w + 0.2
	end
	local hrp = GetLiveCharacter()
	if not hrp or not alive() then return end
	if not part then hrp.CFrame = approxCF; task.wait(0.1); return end
	local standPos = part.Position + Vector3.new(0, (part.Size.Y / 2) + 2, 0)
	hrp.CFrame = CFrame.new(standPos)
	hrp.AssemblyLinearVelocity = Vector3.zero
	if firetouchinterest then
		pcall(function()
			firetouchinterest(hrp, part, 0)
			task.wait(0.05)
			firetouchinterest(hrp, part, 1)
		end)
	end
end

local function DoSummitPoint(point, alive)
	local hrp = GetLiveCharacter()
	if not hrp then return false end
	local cpIndex = string.match(point[1], "^Cp(%d+)$")
	local height = cpIndex and (tonumber(getgenv().SummitCpHeight) or 1.5) or (tonumber(getgenv().SummitHeight) or 6)
	StreamAroundBounded(point[2].Position, 1.5)
	hrp = GetLiveCharacter()
	if not hrp or not alive() then return false end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = point[2] + Vector3.new(0, height, 0)
	if cpIndex then
		TouchCheckpoint(tonumber(cpIndex), point[2], alive)
		task.wait(math.max(tonumber(getgenv().SummitDelay) or 1, 0))
		if getgenv().SummitUseRemote and alive() then
			pcall(function()
				local cpR = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Checkpoint") and ReplicatedStorage.Remote.Checkpoint:FindFirstChild("TpToCheckpoint")
				if cpR then cpR:FireServer(tonumber(cpIndex)) end
			end)
		end
		task.wait(0.1)
	else
		task.wait(0.15)
	end
	return GetLiveCharacter() ~= nil
end

local function SummitReturnToBase(alive)
	local hrp = GetLiveCharacter()
	if hrp and alive() then
		hrp.CFrame = CFrame.new(-6766.44629, 1320.69983, -10083.8037) + Vector3.new(0, 5, 0)
		task.wait(0.8)
		hrp = GetLiveCharacter()
		if hrp and alive() then
			hrp.CFrame = CFrame.new(-6834.84912, 1313.24744, -9902.42285) + Vector3.new(0, 5, 0)
		end
	end
end

local function SummitWorker(runId, startIndex)
	local function alive() return getgenv().AutoSummitRunning and getgenv().SummitRunId == runId end
	local i = startIndex or 1
	local fails = 0
	while alive() do
		local point = SummitPoints[i]
		if not point then
			SetSummitStatus("Kembali ke base"); SummitTick()
			SummitReturnToBase(alive)
			getgenv().SummitLoopCount = getgenv().SummitLoopCount + 1
			i = 1; fails = 0; SummitState.index = 1
			SummitTick(); task.wait(0.3)
		else
			SummitState.index = i; SummitTick(); SetSummitStatus(point[1])
			if not GetLiveCharacter() then
				SetSummitStatus("Menunggu respawn")
				WaitForLiveCharacter(alive, 15)
				task.wait(1)
			else
				local ok, res = pcall(DoSummitPoint, point, alive)
				if ok and res then i = i + 1; fails = 0
				else
					fails = fails + 1
					if fails >= 3 then i = i + 1; fails = 0 end
					task.wait(0.5)
				end
				SummitTick()
			end
		end
	end
end

-- PATCHED: idle 2s saat OFF
task.spawn(function()
	local wasRunning = false
	local lastRecoverIndex, sameIndexCount = nil, 0
	while true do
		local running = getgenv().AutoSummitRunning
		if running then
			if not wasRunning then
				getgenv().SummitRunId = getgenv().SummitRunId + 1
				SummitState.index = 1; SummitTick()
				lastRecoverIndex, sameIndexCount = nil, 0
				task.spawn(SummitWorker, getgenv().SummitRunId, 1)
			else
				local stall = 8 + (tonumber(getgenv().SummitDelay) or 1)
				if tick() - SummitState.last > stall then
					getgenv().SummitRecoverCount = getgenv().SummitRecoverCount + 1
					if SummitState.index == lastRecoverIndex then sameIndexCount = sameIndexCount + 1
					else lastRecoverIndex = SummitState.index; sameIndexCount = 1 end
					if sameIndexCount >= 2 then
						pcall(function()
							local _, hum = GetLiveCharacter()
							if hum then hum.Health = 0 end
						end)
						sameIndexCount = 0
					end
					getgenv().SummitRunId = getgenv().SummitRunId + 1
					SummitTick()
					SetSummitStatus("Recovery di titik " .. tostring(SummitState.index))
					task.spawn(SummitWorker, getgenv().SummitRunId, SummitState.index)
				end
			end
			task.wait(1)
		else
			if wasRunning then SetSummitStatus("Idle") end
			task.wait(2)
		end
		wasRunning = running
	end
end)

------------------------------------------------------------------
-- 6. PLAYER PAGE
------------------------------------------------------------------
local TitlePly = Instance.new("TextLabel", PlayerPage)
TitlePly.Size = UDim2.new(1,0,0,30); TitlePly.BackgroundTransparency = 1
TitlePly.Text = "⚡ PLAYER SETTINGS & VISUALS"
TitlePly.TextColor3 = Color3.fromRGB(0,170,255)
TitlePly.Font = Enum.Font.GothamBold; TitlePly.TextSize = 13

local SpeedBox = Instance.new("TextBox", PlayerPage)
SpeedBox.Size = UDim2.new(1,0,0,35)
SpeedBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
SpeedBox.PlaceholderText = "Ketik WalkSpeed (Cth: 50)"
SpeedBox.Text = ""; SpeedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", SpeedBox)
SpeedBox.FocusLost:Connect(function()
	local n = tonumber(SpeedBox.Text)
	if n then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = n end) end
end)

AddToggle(PlayerPage, "Anti-AFK", function(v) getgenv().AntiAFKRunning = v end)
LocalPlayer.Idled:Connect(function()
	if getgenv().AntiAFKRunning then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0,0))
	end
end)

local HeadlessBtn = Instance.new("TextButton", PlayerPage)
HeadlessBtn.Size = UDim2.new(1,0,0,35)
HeadlessBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
HeadlessBtn.Text = "👻 Enable Headless"
HeadlessBtn.TextColor3 = Color3.new(1,1,1)
HeadlessBtn.Font = Enum.Font.GothamBold; HeadlessBtn.TextSize = 13
Instance.new("UICorner", HeadlessBtn)
HeadlessBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
		if head then
			head.Transparency = 1
			for _, c in ipairs(head:GetChildren()) do if c:IsA("Decal") then c.Transparency = 1 end end
		end
	end)
end)

local FireRgbBtn = Instance.new("TextButton", PlayerPage)
FireRgbBtn.Size = UDim2.new(1,0,0,35)
FireRgbBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 200)
FireRgbBtn.Text = "🔥🌈 Auto RGB Fire: [OFF]"
FireRgbBtn.TextColor3 = Color3.new(1,1,1)
FireRgbBtn.Font = Enum.Font.GothamBold; FireRgbBtn.TextSize = 13
Instance.new("UICorner", FireRgbBtn)

local autoRgbActive = false
FireRgbBtn.MouseButton1Click:Connect(function()
	autoRgbActive = not autoRgbActive
	FireRgbBtn.Text = "🔥🌈 Auto RGB Fire: " .. (autoRgbActive and "[ON]" or "[OFF]")
	FireRgbBtn.BackgroundColor3 = autoRgbActive and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(150, 0, 200)
	pcall(function()
		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
		if head then
			local fire = head:FindFirstChild("UbeyHeadFire")
			if autoRgbActive and not fire then
				fire = Instance.new("Fire")
				fire.Name = "UbeyHeadFire"; fire.Size = 5; fire.Heat = 15; fire.Parent = head
			elseif not autoRgbActive and fire then
				fire:Destroy()
			end
		end
	end)
end)

-- PATCHED: idle lebih panjang saat OFF
task.spawn(function()
	local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,100,255),
		Color3.fromRGB(255,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(0,255,255)}
	local idx = 1
	while true do
		if autoRgbActive then
			pcall(function()
				local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
				local fire = head and head:FindFirstChild("UbeyHeadFire")
				if fire then
					idx = idx % #colors + 1
					fire.Color = colors[idx]
					fire.SecondaryColor = colors[(idx % #colors) + 1]
				end
			end)
			task.wait(1)
		else
			task.wait(2)
		end
	end
end)

------------------------------------------------------------------
-- LARP PAGE
------------------------------------------------------------------
local TitleLarp = Instance.new("TextLabel", LarpPage)
TitleLarp.Size = UDim2.new(1,0,0,30); TitleLarp.BackgroundTransparency = 1
TitleLarp.Text = "🎭 LARP & EFEK KARAKTER (CLIENT-SIDE)"
TitleLarp.TextColor3 = Color3.fromRGB(0,170,255)
TitleLarp.Font = Enum.Font.GothamBold; TitleLarp.TextSize = 13

local LarpStatus = Instance.new("TextLabel", LarpPage)
LarpStatus.Size = UDim2.new(1,0,0,20); LarpStatus.BackgroundTransparency = 1
LarpStatus.Text = "Status: siap"; LarpStatus.TextColor3 = Color3.fromRGB(0,255,170)
LarpStatus.Font = Enum.Font.GothamBold; LarpStatus.TextSize = 11
LarpStatus.TextXAlignment = Enum.TextXAlignment.Left

local function SetLarpStatus(t) LarpStatus.Text = "Status: " .. tostring(t) end

local function LarpButton(text, color, cb)
	local b = Instance.new("TextButton", LarpPage)
	b.Size = UDim2.new(1,0,0,35)
	b.BackgroundColor3 = color
	b.Text = text; b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold; b.TextSize = 12
	Instance.new("UICorner", b)
	b.MouseButton1Click:Connect(cb)
	return b
end

local KORBLOX_ID = 139607718
local HEADLESS_ID = 134082579

local LarpState = { Hats = {} }
local OriginalDesc = nil

local function LarpHasState()
	for k, v in pairs(LarpState) do
		if k == "Hats" then if #v > 0 then return true end
		elseif v then return true end
	end
	return false
end

local function ApplyLarp()
	local ok, err = pcall(function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		assert(hum, "Humanoid tidak ditemukan")
		if not OriginalDesc then OriginalDesc = hum:GetAppliedDescription() end
		local desc = hum:GetAppliedDescription()
		for _, slot in ipairs({"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg","Face"}) do
			if LarpState[slot] then desc[slot] = LarpState[slot] end
		end
		if #LarpState.Hats > 0 then
			local existing, list = {}, {}
			for id in string.gmatch(desc.HatAccessory or "", "%d+") do
				existing[id] = true; table.insert(list, id)
			end
			for _, id in ipairs(LarpState.Hats) do
				local s = tostring(id)
				if not existing[s] then table.insert(list, s) end
			end
			desc.HatAccessory = table.concat(list, ",")
		end
		hum:ApplyDescription(desc)
	end)
	if ok then SetLarpStatus("✅ diterapkan") else SetLarpStatus("⚠️ gagal: " .. tostring(err)) end
	return ok
end

local function HideRightLegFallback()
	pcall(function()
		local char = LocalPlayer.Character
		if not char then return end
		for _, n in ipairs({"RightUpperLeg","RightLowerLeg","RightFoot","Right Leg"}) do
			local p = char:FindFirstChild(n)
			if p and p:IsA("BasePart") then p.Transparency = 1 end
		end
	end)
end

local function ResetLarp()
	for k in pairs(LarpState) do LarpState[k] = nil end
	LarpState.Hats = {}
	pcall(function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and OriginalDesc then hum:ApplyDescription(OriginalDesc) end
		local head = char and char:FindFirstChild("Head")
		if head then
			head.Transparency = 0
			for _, d in ipairs(head:GetChildren()) do if d:IsA("Decal") then d.Transparency = 0 end end
		end
		for _, n in ipairs({"RightUpperLeg","RightLowerLeg","RightFoot","Right Leg"}) do
			local p = char and char:FindFirstChild(n)
			if p and p:IsA("BasePart") then p.Transparency = 0 end
		end
	end)
	OriginalDesc = nil
	SetLarpStatus("🔄 direset")
end

LarpButton("🦴 Korblox Deathspeaker (Kaki Kanan)", Color3.fromRGB(0,100,180), function()
	LarpState.RightLeg = KORBLOX_ID
	if not ApplyLarp() then HideRightLegFallback() end
end)
LarpButton("💀 Headless Horseman (Kepala)", Color3.fromRGB(0,100,180), function()
	LarpState.Head = HEADLESS_ID
	if not ApplyLarp() then
		pcall(function()
			local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
			if head then
				head.Transparency = 1
				for _, d in ipairs(head:GetChildren()) do if d:IsA("Decal") then d.Transparency = 1 end end
			end
		end)
	end
end)
LarpButton("👑 Korblox + Headless (Combo)", Color3.fromRGB(150,0,200), function()
	LarpState.RightLeg = KORBLOX_ID; LarpState.Head = HEADLESS_ID; ApplyLarp()
end)

local LarpSlots = {"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg","Face","Hat"}
local larpSlotIndex = 6

local SlotBtn
SlotBtn = LarpButton("Slot: " .. LarpSlots[larpSlotIndex] .. " ▶", Color3.fromRGB(35,35,45), function()
	larpSlotIndex = larpSlotIndex % #LarpSlots + 1
	SlotBtn.Text = "Slot: " .. LarpSlots[larpSlotIndex] .. " ▶"
end)

local LarpIdBox = Instance.new("TextBox", LarpPage)
LarpIdBox.Size = UDim2.new(1,0,0,35)
LarpIdBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
LarpIdBox.PlaceholderText = "Isi ID aset katalog lalu tekan Enter"
LarpIdBox.Text = ""; LarpIdBox.TextColor3 = Color3.new(1,1,1)
LarpIdBox.Font = Enum.Font.Gotham; LarpIdBox.TextSize = 12
Instance.new("UICorner", LarpIdBox)
LarpIdBox.FocusLost:Connect(function()
	local id = tonumber(LarpIdBox.Text)
	if not id then SetLarpStatus("⚠️ ID harus angka"); return end
	local slot = LarpSlots[larpSlotIndex]
	if slot == "Hat" then table.insert(LarpState.Hats, id) else LarpState[slot] = id end
	ApplyLarp(); LarpIdBox.Text = ""
end)

LarpButton("🧹 Reset Semua Larp", Color3.fromRGB(180,50,50), ResetLarp)

local LarpEffectsTitle = Instance.new("TextLabel", LarpPage)
LarpEffectsTitle.Size = UDim2.new(1,0,0,25); LarpEffectsTitle.BackgroundTransparency = 1
LarpEffectsTitle.Text = "✨ EFEK KARAKTER"
LarpEffectsTitle.TextColor3 = Color3.fromRGB(255,200,0)
LarpEffectsTitle.Font = Enum.Font.GothamBold; LarpEffectsTitle.TextSize = 13

local LarpEffects = { Aura = false, Sparkles = false, Smoke = false, ForceField = false }
local OriginalMaterials = setmetatable({}, { __mode = "k" })

local function RefreshEffects()
	pcall(function()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not char or not hrp then return end
		local aura = char:FindFirstChild("UbeyAura")
		if LarpEffects.Aura and not aura then
			aura = Instance.new("Highlight")
			aura.Name = "UbeyAura"; aura.FillTransparency = 0.55
			aura.OutlineColor = Color3.new(1,1,1); aura.Parent = char
		elseif not LarpEffects.Aura and aura then aura:Destroy() end
		local sp = hrp:FindFirstChild("UbeySparkles")
		if LarpEffects.Sparkles and not sp then
			sp = Instance.new("Sparkles"); sp.Name = "UbeySparkles"; sp.Parent = hrp
		elseif not LarpEffects.Sparkles and sp then sp:Destroy() end
		local sm = hrp:FindFirstChild("UbeySmoke")
		if LarpEffects.Smoke and not sm then
			sm = Instance.new("Smoke"); sm.Name = "UbeySmoke"
			sm.Size = 3; sm.Opacity = 0.3; sm.Color = Color3.fromRGB(120,120,140); sm.Parent = hrp
		elseif not LarpEffects.Smoke and sm then sm:Destroy() end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				if LarpEffects.ForceField then
					if OriginalMaterials[p] == nil then OriginalMaterials[p] = p.Material end
					p.Material = Enum.Material.ForceField
				elseif OriginalMaterials[p] ~= nil then
					p.Material = OriginalMaterials[p]; OriginalMaterials[p] = nil
				end
			end
		end
	end)
end

AddToggle(LarpPage, "🌈 Aura Glow RGB", function(v) LarpEffects.Aura = v; RefreshEffects() end)
AddToggle(LarpPage, "✨ Sparkles", function(v) LarpEffects.Sparkles = v; RefreshEffects() end)
AddToggle(LarpPage, "🌫️ Smoke", function(v) LarpEffects.Smoke = v; RefreshEffects() end)
AddToggle(LarpPage, "🔮 Body ForceField", function(v) LarpEffects.ForceField = v; RefreshEffects() end)

-- PATCHED: 0.1s -> 0.15s + idle
task.spawn(function()
	while true do
		if LarpEffects.Aura then
			pcall(function()
				local aura = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("UbeyAura")
				if aura then aura.FillColor = Color3.fromHSV((tick() % 5) / 5, 1, 1) end
			end)
			task.wait(0.15)
		else
			task.wait(0.5)
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	OriginalDesc = nil
	task.wait(2)
	if LarpHasState() then ApplyLarp() end
	RefreshEffects()
end)

------------------------------------------------------------------
-- HALO PAGE
------------------------------------------------------------------
local TitleHalo = Instance.new("TextLabel", HaloPage)
TitleHalo.Size = UDim2.new(1,0,0,30); TitleHalo.BackgroundTransparency = 1
TitleHalo.Text = "👑 HALO & AKSESORIS KEPALA"
TitleHalo.TextColor3 = Color3.fromRGB(0,170,255)
TitleHalo.Font = Enum.Font.GothamBold; TitleHalo.TextSize = 13

local function ApplyHaloToCharacter(haloName)
	getgenv().CurrentSelectedHalo = haloName
	pcall(function()
		local char = LocalPlayer.Character
		local head = char and char:FindFirstChild("Head")
		if not head then return end
		for _, v in ipairs(head:GetChildren()) do if v.Name == "CustomPlayerHalo" then v:Destroy() end end
		local folder = ReplicatedStorage:FindFirstChild("HaloKenyal")
		if folder then
			local model = folder:FindFirstChild(haloName)
			if model then
				local clone = model:Clone()
				clone.Name = "CustomPlayerHalo"
				local primary = clone:FindFirstChild("Handle") or clone:FindFirstChild("Antenna") or clone:FindFirstChildWhichIsA("BasePart")
				clone.Parent = head
				for _, d in ipairs(clone:GetDescendants()) do
					if d:IsA("BasePart") then d.Anchored = false; d.CanCollide = false; d.Massless = true
					elseif d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
				end
				if primary then
					primary.CFrame = head.CFrame * CFrame.new(0, 1.3, 0)
					local w = Instance.new("WeldConstraint")
					w.Part0 = head; w.Part1 = primary; w.Parent = primary
				end
			end
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if getgenv().CurrentSelectedHalo then ApplyHaloToCharacter(getgenv().CurrentSelectedHalo) end
end)

pcall(function()
	local folder = ReplicatedStorage:FindFirstChild("HaloKenyal")
	if folder then
		local clearBtn = Instance.new("TextButton", HaloPage)
		clearBtn.Size = UDim2.new(1,0,0,32)
		clearBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
		clearBtn.Text = "❌ Lepas Aksesoris Kepala"
		clearBtn.TextColor3 = Color3.new(1,1,1)
		clearBtn.Font = Enum.Font.GothamBold; clearBtn.TextSize = 12
		Instance.new("UICorner", clearBtn)
		clearBtn.MouseButton1Click:Connect(function()
			getgenv().CurrentSelectedHalo = nil
			pcall(function()
				local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
				if head then for _, v in ipairs(head:GetChildren()) do if v.Name == "CustomPlayerHalo" then v:Destroy() end end end
			end)
		end)
		for _, item in ipairs(folder:GetChildren()) do
			local name = item.Name
			local b = Instance.new("TextButton", HaloPage)
			b.Size = UDim2.new(1,0,0,32)
			b.BackgroundColor3 = Color3.fromRGB(35,35,45)
			b.Text = "👑 " .. name; b.TextColor3 = Color3.new(1,1,1)
			b.Font = Enum.Font.GothamMedium; b.TextSize = 12
			Instance.new("UICorner", b)
			b.MouseButton1Click:Connect(function() ApplyHaloToCharacter(name) end)
		end
	end
end)

------------------------------------------------------------------
-- TELEPORT PLAYER PAGE
------------------------------------------------------------------
local TitleTpPly = Instance.new("TextLabel", PlayerTpPage)
TitleTpPly.Size = UDim2.new(1,0,0,30); TitleTpPly.BackgroundTransparency = 1
TitleTpPly.Text = "👥 TELEPORT TO OTHER PLAYERS"
TitleTpPly.TextColor3 = Color3.fromRGB(0,170,255)
TitleTpPly.Font = Enum.Font.GothamBold; TitleTpPly.TextSize = 13

local RefreshPlayerBtn = Instance.new("TextButton", PlayerTpPage)
RefreshPlayerBtn.Size = UDim2.new(1,0,0,35)
RefreshPlayerBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
RefreshPlayerBtn.Text = "🔄 Refresh / Scan Pemain"
RefreshPlayerBtn.TextColor3 = Color3.new(1,1,1)
RefreshPlayerBtn.Font = Enum.Font.GothamBold; RefreshPlayerBtn.TextSize = 12
Instance.new("UICorner", RefreshPlayerBtn)

local PlayerListContainer = Instance.new("ScrollingFrame", PlayerTpPage)
PlayerListContainer.Size = UDim2.new(1,0,0,210)
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.CanvasSize = UDim2.new(0,0,2,0)
PlayerListContainer.ScrollBarThickness = 3
local LL = Instance.new("UIListLayout", PlayerListContainer)
LL.SortOrder = Enum.SortOrder.LayoutOrder; LL.Padding = UDim.new(0, 5)

local function ScanAndDisplayPlayers()
	for _, c in ipairs(PlayerListContainer:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local pBtn = Instance.new("TextButton", PlayerListContainer)
			pBtn.Size = UDim2.new(1,0,0,32)
			pBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
			pBtn.Text = "👤 " .. plr.Name .. " (" .. plr.DisplayName .. ")"
			pBtn.TextColor3 = Color3.new(1,1,1)
			pBtn.Font = Enum.Font.GothamMedium; pBtn.TextSize = 11
			Instance.new("UICorner", pBtn)
			pBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if tHrp and myHrp then myHrp.CFrame = tHrp.CFrame + Vector3.new(0, 5, 0) end
				end)
			end)
		end
	end
end

RefreshPlayerBtn.MouseButton1Click:Connect(ScanAndDisplayPlayers)
task.spawn(function() task.wait(2); ScanAndDisplayPlayers() end)

------------------------------------------------------------------
-- PRIVACY & ANTI-ADMIN
------------------------------------------------------------------
local TitlePrv = Instance.new("TextLabel", PrivacyPage)
TitlePrv.Size = UDim2.new(1,0,0,30); TitlePrv.BackgroundTransparency = 1
TitlePrv.Text = "🛡️ PRIVACY & ANTI-ADMIN"
TitlePrv.TextColor3 = Color3.fromRGB(0,170,255)
TitlePrv.Font = Enum.Font.GothamBold; TitlePrv.TextSize = 13

local FakeNameBox = Instance.new("TextBox", PrivacyPage)
FakeNameBox.Size = UDim2.new(1,0,0,35)
FakeNameBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
FakeNameBox.PlaceholderText = "Nama Samaran (Cth: UBEY HUB)"
FakeNameBox.Text = "UBEY HUB"; FakeNameBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", FakeNameBox)
FakeNameBox.FocusLost:Connect(function() getgenv().FakeNameInput = FakeNameBox.Text end)

-- PATCHED: idle 2s saat OFF
AddToggle(PrivacyPage, "Privacy Mode (Hide Name)", function(v)
	getgenv().HideNameRunning = v
	if v then
		task.spawn(function()
			while getgenv().HideNameRunning do
				pcall(function()
					local fakeName = getgenv().FakeNameInput or "UBEY HUB"
					local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
					if head then
						for _, c in ipairs(head:GetDescendants()) do
							if c:IsA("TextLabel") or c:IsA("TextMesh") then
								local t = c.Text
								if string.find(t, LocalPlayer.Name) or string.find(t, LocalPlayer.DisplayName) then
									c.Text = fakeName
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

local AntiAdminBtn = Instance.new("TextButton", PrivacyPage)
AntiAdminBtn.Size = UDim2.new(1,0,0,35)
AntiAdminBtn.BackgroundColor3 = getgenv().UbeyConfig.AntiAdminEnabled and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(30, 30, 40)
AntiAdminBtn.Text = "  Anti-Admin Protect (MPG Group): " .. (getgenv().UbeyConfig.AntiAdminEnabled and "[ON]" or "[OFF]")
AntiAdminBtn.TextColor3 = Color3.new(1,1,1)
AntiAdminBtn.Font = Enum.Font.Gotham
AntiAdminBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", AntiAdminBtn)
AntiAdminBtn.MouseButton1Click:Connect(function()
	getgenv().UbeyConfig.AntiAdminEnabled = not getgenv().UbeyConfig.AntiAdminEnabled
	local active = getgenv().UbeyConfig.AntiAdminEnabled
	AntiAdminBtn.Text = "  Anti-Admin Protect (MPG Group): " .. (active and "[ON]" or "[OFF]")
	AntiAdminBtn.BackgroundColor3 = active and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(30, 30, 40)
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

------------------------------------------------------------------
-- SETTINGS PAGE
------------------------------------------------------------------
local TitleSet = Instance.new("TextLabel", SettingsPage)
TitleSet.Size = UDim2.new(1,0,0,30); TitleSet.BackgroundTransparency = 1
TitleSet.Text = "⚙️ SETTINGS & PERFORMANCE BOOST"
TitleSet.TextColor3 = Color3.fromRGB(0,170,255)
TitleSet.Font = Enum.Font.GothamBold; TitleSet.TextSize = 13

local AntiLagBtn = Instance.new("TextButton", SettingsPage)
AntiLagBtn.Size = UDim2.new(1,0,0,35)
AntiLagBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
AntiLagBtn.Text = "⚡ Aktifkan Anti-Lag (Boost FPS)"
AntiLagBtn.TextColor3 = Color3.new(1,1,1)
AntiLagBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AntiLagBtn)
AntiLagBtn.MouseButton1Click:Connect(function()
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 999999
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled = false end
		end
		AntiLagBtn.Text = "⚡ Anti-Lag Aktif!"
	end)
end)

local BlackScreenGui = nil
local BlackScreenToggleBtn = Instance.new("TextButton", SettingsPage)
BlackScreenToggleBtn.Size = UDim2.new(1,0,0,35)
BlackScreenToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
BlackScreenToggleBtn.Text = "  📱 Black Screen (Battery Saver): [OFF]"
BlackScreenToggleBtn.TextColor3 = Color3.new(1,1,1)
BlackScreenToggleBtn.Font = Enum.Font.Gotham
BlackScreenToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", BlackScreenToggleBtn)

local isBlackScreen = false
BlackScreenToggleBtn.MouseButton1Click:Connect(function()
	isBlackScreen = not isBlackScreen
	BlackScreenToggleBtn.Text = "  📱 Black Screen (Battery Saver): " .. (isBlackScreen and "[ON]" or "[OFF]")
	BlackScreenToggleBtn.BackgroundColor3 = isBlackScreen and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(30, 30, 40)
	if isBlackScreen then
		if not BlackScreenGui then
			BlackScreenGui = Instance.new("ScreenGui")
			BlackScreenGui.Name = "UbeyBlackScreen"
			BlackScreenGui.Parent = PlayerGui
			BlackScreenGui.DisplayOrder = 999999
			BlackScreenGui.IgnoreGuiInset = true
			local frame = Instance.new("Frame", BlackScreenGui)
			frame.Size = UDim2.new(1,0,1,0)
			frame.BackgroundColor3 = Color3.fromRGB(2, 2, 5)
			local txt = Instance.new("TextLabel", frame)
			txt.Size = UDim2.new(1,0,0,60); txt.Position = UDim2.new(0,0,0.45,0)
			txt.BackgroundTransparency = 1
			txt.Text = "🌙 UBEY HUB V3 - BATTERY SAVER ACTIVE\n(Sentuh Layar Untuk Kembali)"
			txt.TextColor3 = Color3.fromRGB(0, 170, 255)
			txt.Font = Enum.Font.GothamBold; txt.TextSize = 13
			frame.InputBegan:Connect(function()
				isBlackScreen = false
				BlackScreenToggleBtn.Text = "  📱 Black Screen (Battery Saver): [OFF]"
				BlackScreenToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
				BlackScreenGui.Enabled = false
			end)
		else
			BlackScreenGui.Enabled = true
		end
	else
		if BlackScreenGui then BlackScreenGui.Enabled = false end
	end
end)

local WebhookToggleBtn = Instance.new("TextButton", SettingsPage)
WebhookToggleBtn.Size = UDim2.new(1,0,0,35)
WebhookToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.WebhookEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(30, 30, 40)
WebhookToggleBtn.Text = "  Webhook Secret & Forgotten: " .. (getgenv().UbeyConfig.WebhookEnabled and "[ON]" or "[OFF]")
WebhookToggleBtn.TextColor3 = Color3.new(1,1,1)
WebhookToggleBtn.Font = Enum.Font.Gotham
WebhookToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", WebhookToggleBtn)
WebhookToggleBtn.MouseButton1Click:Connect(function()
	getgenv().UbeyConfig.WebhookEnabled = not getgenv().UbeyConfig.WebhookEnabled
	WebhookToggleBtn.Text = "  Webhook Secret & Forgotten: " .. (getgenv().UbeyConfig.WebhookEnabled and "[ON]" or "[OFF]")
	WebhookToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.WebhookEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(30, 30, 40)
	SaveConfig()
end)

local WebhookBox = Instance.new("TextBox", SettingsPage)
WebhookBox.Size = UDim2.new(1,0,0,35)
WebhookBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
WebhookBox.PlaceholderText = "Paste Discord Webhook URL di sini..."
WebhookBox.Text = tostring(getgenv().UbeyConfig.WebhookUrl or "")
WebhookBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", WebhookBox)
WebhookBox.FocusLost:Connect(function()
	getgenv().UbeyConfig.WebhookUrl = WebhookBox.Text
	SaveConfig()
end)

local TestWebhookBtn = Instance.new("TextButton", SettingsPage)
TestWebhookBtn.Size = UDim2.new(1,0,0,35)
TestWebhookBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
TestWebhookBtn.TextColor3 = Color3.new(1,1,1)
TestWebhookBtn.Font = Enum.Font.GothamBold; TestWebhookBtn.TextSize = 13
Instance.new("UICorner", TestWebhookBtn)
TestWebhookBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then
			TestWebhookBtn.Text = "❌ URL Webhook Salah / Belum Diisi!"
			task.wait(2); TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"; return
		end
		local req = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
		if req then
			req({
				Url = url, Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({
					["content"] = "✅ **Ubey Hub V3 Webhook Test Berhasil!** Koneksi ke Discord normal."
				})
			})
			TestWebhookBtn.Text = "✅ Pesan Test Berhasil Dikirim!"
		else
			TestWebhookBtn.Text = "❌ Executor Tidak Mendukung Request!"
		end
		task.wait(2); TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
	end)
end)

local SaveConfigBtn = Instance.new("TextButton", SettingsPage)
SaveConfigBtn.Size = UDim2.new(1,0,0,35)
SaveConfigBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
SaveConfigBtn.Text = "💾 Simpan Konfigurasi"
SaveConfigBtn.TextColor3 = Color3.new(1,1,1)
SaveConfigBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", SaveConfigBtn)
SaveConfigBtn.MouseButton1Click:Connect(function()
	SaveConfig()
	SaveConfigBtn.Text = "✅ Config Berhasil Disimpan!"
	task.wait(1.5); SaveConfigBtn.Text = "💾 Simpan Konfigurasi"
end)

local ResetConfigBtn = Instance.new("TextButton", SettingsPage)
ResetConfigBtn.Size = UDim2.new(1,0,0,35)
ResetConfigBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ResetConfigBtn.Text = "🔄 Reset Konfigurasi & Clear Key"
ResetConfigBtn.TextColor3 = Color3.new(1,1,1)
ResetConfigBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ResetConfigBtn)
ResetConfigBtn.MouseButton1Click:Connect(function()
	ResetConfig()
	ResetConfigBtn.Text = "🔄 Config Direset!"
	task.wait(1.5); ResetConfigBtn.Text = "🔄 Reset Konfigurasi & Clear Key"
end)

local CredLbl = Instance.new("TextLabel", CreditsPage)
CredLbl.Size = UDim2.new(1,0,1,0); CredLbl.BackgroundTransparency = 1
CredLbl.Text = "Created By UBEY"; CredLbl.TextColor3 = Color3.new(1,1,1)
CredLbl.Font = Enum.Font.GothamBold; CredLbl.TextSize = 20

------------------------------------------------------------------
-- SESSION STAT PANEL
------------------------------------------------------------------
local StatPanel = Instance.new("Frame", Main)
StatPanel.Size = UDim2.new(1, -160, 0, 24)
StatPanel.Position = UDim2.new(0, 150, 1, -28)
StatPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
StatPanel.BorderSizePixel = 0
Instance.new("UICorner", StatPanel).CornerRadius = UDim.new(0, 6)

local StatLabel = Instance.new("TextLabel", StatPanel)
StatLabel.Size = UDim2.new(1, -10, 1, 0)
StatLabel.Position = UDim2.new(0, 5, 0, 0)
StatLabel.BackgroundTransparency = 1
StatLabel.Text = "📊 Total Ikan: 0  |  ⏱️ Play Time: 00s"
StatLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
StatLabel.Font = Enum.Font.GothamBold; StatLabel.TextSize = 11
StatLabel.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
	while true do
		if Main.Visible then
			pcall(function()
				local e = os.time() - getgenv().SessionStartTime
				local h, m, s = math.floor(e/3600), math.floor((e%3600)/60), e%60
				local ts
				if h > 0 then ts = string.format("%02dh %02dm %02ds", h, m, s)
				elseif m > 0 then ts = string.format("%02dm %02ds", m, s)
				else ts = string.format("%02ds", s) end
				StatLabel.Text = string.format("📊 Total Ikan: %d  |  ⏱️ Play: %s", getgenv().TotalFishCaught or 0, ts)
			end)
			task.wait(1)
		else
			task.wait(2)
		end
	end
end)

------------------------------------------------------------------
-- FLOATING BUTTON
------------------------------------------------------------------
local Float = Instance.new("ImageButton", Gui)
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)
Instance.new("UICorner", Float).CornerRadius = UDim.new(1,0)
MakeDraggable(Float)

Float.MouseButton1Click:Connect(function()
	if not getgenv().KeyVerified then
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)
