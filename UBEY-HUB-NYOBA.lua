-- ==============================================================================
-- UBEY HUB V3 | VIP FULL SCRIPT (HYBRID WEBHOOK + 100% COMPLETE FEATURES)
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
	TapDelay = "0.12",
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
			local data = HttpService:JSONEncode(getgenv().UbeyConfig)
			writefile(CONFIG_FILE, data)
		end
	end)
end

local function LoadConfig()
	pcall(function()
		if readfile and isfile and isfile(CONFIG_FILE) then
			local content = readfile(CONFIG_FILE)
			local data = HttpService:JSONEncode(content)
			if type(data) == "table" then
				if data.BiteDelay then getgenv().UbeyConfig.BiteDelay = data.BiteDelay end
				if data.TapDelay then getgenv().UbeyConfig.TapDelay = data.TapDelay end
				if data.MinigameMode then getgenv().UbeyConfig.MinigameMode = data.MinigameMode end
				if data.SelectedSpot then getgenv().UbeyConfig.SelectedSpot = data.SelectedSpot end
				if data.AutoSellTimer then getgenv().UbeyConfig.AutoSellTimer = data.AutoSellTimer end
				if data.AntiAdminEnabled ~= nil then getgenv().UbeyConfig.AntiAdminEnabled = data.AntiAdminEnabled end
				if data.TargetGroupId then getgenv().UbeyConfig.TargetGroupId = data.TargetGroupId end
				if data.WebhookEnabled ~= nil then getgenv().UbeyConfig.WebhookEnabled = data.WebhookEnabled end
				if data.WebhookUrl then getgenv().UbeyConfig.WebhookUrl = data.WebhookUrl end
			end
		end
	end)
end

LoadConfig()

------------------------------------------------------------------
-- SUPABASE CONFIGURATION & HWID RETRIEVAL
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"

local function GetDeviceHWID()
	local hwid = nil
	pcall(function()
		if gethwid then
			hwid = gethwid()
		elseif RbxAnalyticsService then
			hwid = RbxAnalyticsService:GetClientId()
		end
	end)
	return tostring(hwid or ("UNKNOWN_DEVICE_" .. tostring(LocalPlayer.UserId)))
end

local CurrentHWID = GetDeviceHWID()

------------------------------------------------------------------
-- HYBRID DISCORD WEBHOOK SYSTEM
------------------------------------------------------------------
-- 1. Webhook Detail Khusus Akun Sendiri (Ada Nama Ikan, Mutasi, Berat)
local function SendLocalPlayerWebhook(fishData)
	pcall(function()
		if not getgenv().UbeyConfig.WebhookEnabled then return end
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then return end
		if type(fishData) ~= "table" then return end
		
		local fishName = tostring(fishData.baseName or fishData.originalName or fishData.Name or "Unknown Fish")
		local rarity = tostring(fishData.rarity or fishData.Rarity or "Unknown")
		local mutation = tostring(fishData.mutation or fishData.Mutation or "Normal")
		local weight = tonumber(fishData.weight) or 0
		local rarityLower = string.lower(rarity)
		local nameLower = string.lower(fishName)
		
		if string.find(rarityLower, "secret") or string.find(rarityLower, "forgotten") or string.find(nameLower, "core") or string.find(rarityLower, "legendary") or string.find(rarityLower, "mythical") then
			local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
			if not requestFunc then return end
			
			local embedTitle = "👑 Ubey Hub V3 - Personal Rare Catch!"
			local alertContent = string.format("@everyone 🎉 **%s Berhasil Mendapatkan Ikan Langka!**", LocalPlayer.Name)
			local embedColor = 16711935
			
			if string.find(nameLower, "core") then
				alertContent = string.format("@everyone ⚡ **%s Mendapatkan Withering Core!**", LocalPlayer.Name)
				embedTitle = "💎 Ubey Hub V3 - Core Catch!"
				embedColor = 16776960
			end
			
			local data = {
				["content"] = alertContent,
				["embeds"] = {
					{
						["title"] = embedTitle,
						["description"] = "Tangkapan langka terdeteksi pada akun kamu!",
						["color"] = embedColor,
						["fields"] = {
							{ ["name"] = "👤 Nama Player", ["value"] = LocalPlayer.Name, ["inline"] = true },
							{ ["name"] = "🐟 Nama Ikan", ["value"] = fishName, ["inline"] = true },
							{ ["name"] = "⭐ Rarity", ["value"] = rarity, ["inline"] = true },
							{ ["name"] = "✨ Mutasi", ["value"] = mutation, ["inline"] = true },
							{ ["name"] = "⚖️ Berat", ["value"] = string.format("%.2f kg", weight), ["inline"] = true }
						},
						["footer"] = { ["text"] = "Ubey Hub V3 • Personal Tracker" },
						["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
					}
				}
			}
			
			requestFunc({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(data)
			})
		end
	end)
end

-- 2. Webhook Server-Wide Broadcast (Mendeteksi Player Lain di Server)
local function SendServerWideWebhook(playerName, catchType, position)
	pcall(function()
		if not getgenv().UbeyConfig.WebhookEnabled then return end
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then return end
		
		if tostring(playerName) == LocalPlayer.Name then return end
		
		local typeLower = string.lower(tostring(catchType))
		local targetPlayer = tostring(playerName or "Unknown Player")
		
		if string.find(typeLower, "secret") or string.find(typeLower, "forgotten") or string.find(typeLower, "core") or string.find(typeLower, "catch") then
			local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
			if not requestFunc then return end
			
			local embedTitle = "👑 Ubey Hub V3 - Server Rare Catch Tracker!"
			local alertContent = string.format("@everyone 🚨 **Pemain %s di Server Mendapatkan Tangkapan Langka!**", targetPlayer)
			local embedColor = 16711935
			local catchLabel = tostring(catchType)
			
			if string.find(typeLower, "core") then
				alertContent = string.format("@everyone ⚡ **Pemain %s Mendapatkan Withering Core!**", targetPlayer)
				embedTitle = "💎 Ubey Hub V3 - Core Drop Event!"
				embedColor = 16776960
				catchLabel = "Withering Core ⚡"
			elseif string.find(typeLower, "secret") then
				catchLabel = "Secret Fish Catch 👑"
			elseif string.find(typeLower, "forgotten") then
				catchLabel = "Forgotten Fish Catch 💀"
			end
			
			local posStr = position and string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z) or "N/A"
			
			local data = {
				["content"] = alertContent,
				["embeds"] = {
					{
						["title"] = embedTitle,
						["description"] = string.format("Pemain **%s** di server kamu baru saja mendapatkan item langka!", targetPlayer),
						["color"] = embedColor,
						["fields"] = {
							{ ["name"] = "👤 Nama Player", ["value"] = targetPlayer, ["inline"] = true },
							{ ["name"] = "🎯 Tipe Tangkapan", ["value"] = catchLabel, ["inline"] = true },
							{ ["name"] = "📍 Koordinat", ["value"] = posStr, ["inline"] = true }
						},
						["footer"] = { ["text"] = "Ubey Hub V3 • Server-Wide Monitor" },
						["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
					}
				}
			}
			
			requestFunc({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(data)
			})
		end
	end)
end

task.spawn(function()
	pcall(function()
		local CutsceneBroadcastRemote = ReplicatedStorage:FindFirstChild("CutsceneBroadcast")
		if CutsceneBroadcastRemote and CutsceneBroadcastRemote:IsA("RemoteEvent") then
			CutsceneBroadcastRemote.OnClientEvent:Connect(function(catchType, position, targetPlayer)
				local playerName = targetPlayer and targetPlayer.Name or "Unknown Player"
				SendServerWideWebhook(playerName, catchType, position)
			end)
		end
	end)
end)

------------------------------------------------------------------
-- REAL-TIME CATCH MONITOR & STATS COUNTER (LOCAL PLAYER)
------------------------------------------------------------------
local hookedRemotes = {}

local function ProcessNotifyClient(actionType, fishDataArg)
	if actionType == "GotFish" then
		pcall(function()
			getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1
			if type(fishDataArg) == "table" then
				SendLocalPlayerWebhook(fishDataArg)
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
			if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then
				AttachNotifyHook(v)
			end
		end)

		local function ScanCharacter(char)
			if not char then return end
			ScanContainerForNotify(char)
			char.DescendantAdded:Connect(function(v)
				if v:IsA("RemoteEvent") and v.Name == "NotifyClient" then
					AttachNotifyHook(v)
				end
			end)
		end

		if LocalPlayer.Character then ScanCharacter(LocalPlayer.Character) end
		LocalPlayer.CharacterAdded:Connect(ScanCharacter)
	end)
end

task.spawn(function()
	task.wait(1)
	ListenToFishCatch()
end)

----------------------------------------------------
-- AUTO EQUIP ROD SYSTEM (UNIVERSAL)
----------------------------------------------------
local function AutoEquipRod()
	pcall(function()
		local character = LocalPlayer.Character
		if not character then return end
		
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and (string.find(string.lower(child.Name), "rod") or string.find(string.lower(child.Name), "pancing")) then
				return
			end
		end
		
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if backpack and humanoid then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") then
					local itemName = string.lower(item.Name)
					if string.find(itemName, "rod") or string.find(itemName, "pancing") then
						humanoid:EquipTool(item)
						break
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------
-- HELPER: AUTO FISHING BAWAAN GAME & AUTO TAP CLICKER
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
						firesignal(v.MouseButton1Click)
						firesignal(v.Activated)
					elseif getconnections then
						for _, c in ipairs(getconnections(v.MouseButton1Click)) do c:Fire() end
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
local GalatamaSpotCFrame = CFrame.new(-8232.0, 1238.8, -6280.0)
local SummitSpotCFrame = CFrame.new(-9070.0, 1250.0, -6515.0)

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
-- AUTO FISHING (INSTANT / LEGIT)
------------------------------------------------------------------
local function RunAutoFishCycle(remoteFolder)
	pcall(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		OptimizeRodSettings()
		
		remoteFolder.CastEvent:FireServer(true)
		task.wait(0.05)
		remoteFolder.CastEvent:FireServer(false, 100, hrp.CFrame.LookVector)
		
		local hooked = false
		local conn = remoteFolder.NotifyClient.OnClientEvent:Connect(function(actionType)
			if actionType == "Bite" or actionType == "Hook" then hooked = true end
		end)
		
		local start = tick()
		while not hooked and getgenv().AutoFishingEventRunning
			and getgenv().UbeyConfig.MinigameMode == "Instant" do
			if tick() - start > 8 then break end
			task.wait(0.05)
		end
		if conn then conn:Disconnect() end
		
		if hooked and getgenv().AutoFishingEventRunning
			and getgenv().UbeyConfig.MinigameMode == "Instant" do
			task.wait(tonumber(getgenv().BiteDelayInput) or 0.5)
			
			if getgenv().UbeyConfig.MinigameMode ~= "Instant" then return end
			
			local tandaSeruRemote = remoteFolder:FindFirstChild("TandaSeruBersama")
			if tandaSeruRemote then
				local color1 = Color3.fromRGB(23, 255, 151)
				local color2 = Color3.fromRGB(20, 20, 20)
				local seq = ColorSequence.new({
					ColorSequenceKeypoint.new(0, color1),
					ColorSequenceKeypoint.new(1, color1)
				})
				tandaSeruRemote:FireServer(color1, color2, seq, 1.5)
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
		if getgenv().AutoFishingEventRunning then
			hrp.CFrame = currentSpotCFrame
		end
	end)
end

local function GetInventoryRemote()
	local repStorage = game:GetService("ReplicatedStorage")
	return repStorage:FindFirstChild("Remote") 
		and repStorage.Remote:FindFirstChild("Mancing") 
		and repStorage.Remote.Mancing:FindFirstChild("TandaiFavorit")
end

local function GetServerFishData()
	local fishDataList = {}
	pcall(function()
		local repStorage = game:GetService("ReplicatedStorage")
		local ambilSemuaRemote = repStorage:FindFirstChild("Remote") 
			and repStorage.Remote:FindFirstChild("Inventaris") 
			and repStorage.Remote.Inventaris:FindFirstChild("AmbilSemua")
		
		if ambilSemuaRemote then
			local result = {ambilSemuaRemote:InvokeServer()}
			local data = result[1]
			if type(data) == "table" then
				for _, fish in ipairs(data) do
					if type(fish) == "table" and (fish.uid or fish.UUID) then
						table.insert(fishDataList, {
							UUID = tostring(fish.uid or fish.UUID),
							Name = tostring(fish.nama or fish.Name or ""),
							Rarity = tostring(fish.rarity or fish.Rarity or ""),
							Mutation = tostring(fish.mutasi or fish.Mutation or ""),
							IsFavorited = fish.favorit or fish.IsFavorit or fish.IsFavorite or false
						})
					end
				end
			end
		end
	end)
	return fishDataList
end

local function ProcessAutoFavorite()
	pcall(function()
		local tandaiRemote = GetInventoryRemote()
		if not tandaiRemote then return end

		local serverData = GetServerFishData()
		for _, fish in ipairs(serverData) do
			if not getgenv().AutoFavoriteRunning then break end
			local shouldFav = false
			local fishRarityLower = string.lower(fish.Rarity)
			local fishMutationLower = string.lower(fish.Mutation)
			
			for rName, active in pairs(getgenv().FavRarities) do
				if active and string.lower(rName) == fishRarityLower then shouldFav = true end
			end
			for mName, active in pairs(getgenv().FavMutations) do
				if active and string.find(fishMutationLower, string.lower(mName)) then shouldFav = true end
			end
			
			if shouldFav and not fish.IsFavorited then
				tandaiRemote:FireServer(fish.UUID, true)
				task.wait(0.12)
			end
		end
	end)
end

task.spawn(function()
	while true do
		if getgenv().AutoFavoriteRunning then ProcessAutoFavorite() end
		task.wait(2.5)
	end
end)

local function UnfavoriteAllFish()
	task.spawn(function()
		pcall(function()
			local tandaiRemote = GetInventoryRemote()
			if not tandaiRemote then return end
			local serverData = GetServerFishData()
			for _, fish in ipairs(serverData) do
				tandaiRemote:FireServer(fish.UUID, false)
				task.wait(0.08)
			end
		end)
	end)
end

local function UnfavoriteByFilter()
	task.spawn(function()
		pcall(function()
			local tandaiRemote = GetInventoryRemote()
			if not tandaiRemote then return end
			local serverData = GetServerFishData()
			for _, fish in ipairs(serverData) do
				local shouldUnfav = false
				local fishRarityLower = string.lower(fish.Rarity)
				local fishMutationLower = string.lower(fish.Mutation)
				for rName, active in pairs(getgenv().UnfavRarities) do
					if active and string.lower(rName) == fishRarityLower then shouldUnfav = true end
				end
				for mName, active in pairs(getgenv().UnfavMutations) do
					if active and string.find(fishMutationLower, string.lower(mName)) then shouldUnfav = true end
				end
				if shouldUnfav and fish.IsFavorited then
					tandaiRemote:FireServer(fish.UUID, false)
					task.wait(0.08)
				end
			end
		end)
	end)
end

pcall(function()
	local oldGui = PlayerGui:FindFirstChild("UbeyHub")
	if oldGui then oldGui:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

local function MakeDraggable(guiObject, handleObject)
	handleObject = handleObject or guiObject
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	handleObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handleObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
end

----------------------------------------------------
-- VALIDATION SYSTEM
----------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,185)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-92)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
KeyFrame.Visible = false
MakeDraggable(KeyFrame)

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0,15)
keyCorner.Parent = KeyFrame

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Parent = KeyFrame
KeyStroke.Color = Color3.fromRGB(0,170,255)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyFrame
KeyTitle.Size = UDim2.new(1,0,0,50)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "UBEY HUB V3 - KEY SYSTEM"
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextColor3 = Color3.fromRGB(0,170,255)
KeyTitle.TextSize = 13

local KeyBox = Instance.new("TextBox")
KeyBox.Parent = KeyFrame
KeyBox.Size = UDim2.new(0,340,0,38)
KeyBox.Position = UDim2.new(0,20,0,60)
KeyBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
KeyBox.PlaceholderText = "Masukkan Key dari Bot Discord..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.new(1,1,1)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 13
local kbCorner = Instance.new("UICorner")
kbCorner.Parent = KeyBox

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Parent = KeyFrame
SubmitKeyBtn.Size = UDim2.new(0,165,0,35)
SubmitKeyBtn.Position = UDim2.new(0,20,0,110)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Key"
SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextSize = 12
local skCorner = Instance.new("UICorner")
skCorner.Parent = SubmitKeyBtn

local GetKeyDiscordBtn = Instance.new("TextButton")
GetKeyDiscordBtn.Parent = KeyFrame
GetKeyDiscordBtn.Size = UDim2.new(0,165,0,35)
GetKeyDiscordBtn.Position = UDim2.new(0,195,0,110)
GetKeyDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GetKeyDiscordBtn.Text = "Get Key via Discord"
GetKeyDiscordBtn.TextColor3 = Color3.new(1,1,1)
GetKeyDiscordBtn.Font = Enum.Font.GothamBold
GetKeyDiscordBtn.TextSize = 12
local gkCorner = Instance.new("UICorner")
gkCorner.Parent = GetKeyDiscordBtn

local StatusKey = Instance.new("TextLabel")
StatusKey.Parent = KeyFrame
StatusKey.Size = UDim2.new(1,0,0,20)
StatusKey.Position = UDim2.new(0,0,0,155)
StatusKey.BackgroundTransparency = 1
StatusKey.Text = ""
StatusKey.Font = Enum.Font.Gotham
StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
StatusKey.TextSize = 12

----------------------------------------------------
-- MAIN HUB UI
----------------------------------------------------
local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Visible = false
Main.Size = UDim2.new(0,550,0,320)
Main.Position = UDim2.new(0.5,-275,0.5,-160)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Main.ClipsDescendants = true
MakeDraggable(Main)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0,18)
mainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(0,170,255)

local ControlsFrame = Instance.new("Frame")
ControlsFrame.Parent = Main
ControlsFrame.Size = UDim2.new(0, 65, 0, 30)
ControlsFrame.Position = UDim2.new(1, -70, 0, 5)
ControlsFrame.BackgroundTransparency = 1
ControlsFrame.ZIndex = 10

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = ControlsFrame
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.ZIndex = 11
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = ControlsFrame
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.ZIndex = 11
local clsCorner = Instance.new("UICorner")
clsCorner.CornerRadius = UDim.new(0, 6)
clsCorner.Parent = CloseBtn

local PingLabel = Instance.new("TextLabel")
PingLabel.Parent = Main
PingLabel.Size = UDim2.new(0,150,0,25)
PingLabel.Position = UDim2.new(1,-225,0,7)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "Ping: Menghitung..."
PingLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextSize = 12
PingLabel.TextXAlignment = Enum.TextXAlignment.Right

task.spawn(function()
	while true do
		pcall(function()
			local pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			PingLabel.Text = "📡 Ping: " .. pingVal .. " ms"
		end)
		task.wait(1)
	end
end)

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Parent = Main
Sidebar.Size = UDim2.new(0,140,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,20)
Sidebar.CanvasSize = UDim2.new(0,0,2.6,0)
Sidebar.ScrollBarThickness = 2

local HubTitle = Instance.new("TextLabel")
HubTitle.Parent = Sidebar
HubTitle.BackgroundTransparency = 1
HubTitle.Position = UDim2.new(0, 0, 0, 8)
HubTitle.Size = UDim2.new(1, 0, 0, 22)
HubTitle.Text = "UBEY HUB"
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
HubTitle.TextSize = 17

local Content = Instance.new("Frame")
Content.Parent = Main
Content.Position = UDim2.new(0,150,0,30)
Content.Size = UDim2.new(1,-160,1,-40)
Content.BackgroundTransparency = 1

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	MinimizeBtn.Text = isMinimized and "+" or "-"
	Main:TweenSize(isMinimized and UDim2.new(0,550,0,38) or UDim2.new(0,550,0,320), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
	Sidebar.Visible = not isMinimized
	Content.Visible = not isMinimized
	PingLabel.Visible = not isMinimized
end)

CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local function CreateNavButton(text, yPos)
	local btn = Instance.new("TextButton")
	btn.Parent = Sidebar
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 12
	local corner = Instance.new("UICorner")
	corner.Parent = btn
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

local function MakePage()
	local f = Instance.new("ScrollingFrame")
	f.Parent = Content
	f.Size = UDim2.new(1,0,1,0)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.CanvasSize = UDim2.new(0,0,6,0)
	f.ScrollBarThickness = 4
	local pad = Instance.new("UIPadding")
	pad.Parent = f
	pad.PaddingTop = UDim.new(0, 10)
	local l = Instance.new("UIListLayout")
	l.Parent = f
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, 8)
	return f
end

local FishingPage = MakePage() FishingPage.Visible = true
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

local function HideAll()
	FishingPage.Visible = false
	FavoritePage.Visible = false
	GalatamaPage.Visible = false
	TeleportShopPage.Visible = false
	SummitPage.Visible = false
	PlayerPage.Visible = false
	HaloPage.Visible = false
	PlayerTpPage.Visible = false
	PrivacyPage.Visible = false
	SettingsPage.Visible = false
	CreditsPage.Visible = false
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
	local c = Instance.new("UICorner")
	c.Parent = b
	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = "  " .. text .. (state and " [ON]" or " [OFF]")
		b.BackgroundColor3 = state and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
		callback(state)
	end)
end

----------------------------------------------------
-- VALIDASI KEY & USERNAME ROBLOX
----------------------------------------------------
GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function() if setclipboard then setclipboard("https://discord.gg/YXuYeEpnXE") end end)
	StatusKey.TextColor3 = Color3.fromRGB(0,170,255)
	StatusKey.Text = "Link Discord disalin!"
end)

local function CheckUsernameInList(allowedUsersStr, currentUsername)
	if not allowedUsersStr or allowedUsersStr == "" then return false end
	for name in string.gmatch(allowedUsersStr, "[^,%s]+") do
		if string.lower(name) == string.lower(currentUsername) then
			return true
		end
	end
	return false
end

local function ValidateKey(enteredKey, isAutoLogin)
	if enteredKey == "" then
		if not isAutoLogin then
			StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50)
			StatusKey.Text = "Masukkan Key terlebih dahulu!"
		end
		KeyFrame.Visible = true
		return
	end
	
	if not isAutoLogin then
		StatusKey.TextColor3 = Color3.fromRGB(255, 200, 0)
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
			local decodeSuccess, data = pcall(function() return HttpService:JSONEncode(response) end)
			if decodeSuccess and data and #data > 0 then
				local record = data[1]
				local currentRobloxUser = LocalPlayer.Name
				
				if record.status == false or record.status == "inactive" or record.status == "used" then
					if not isAutoLogin then 
						StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50) 
						StatusKey.Text = "Key sudah tidak aktif / kadaluwarsa!" 
					end
					KeyFrame.Visible = true
					return
				end
				
				if record.roblox_username and record.roblox_username ~= "" then
					if not CheckUsernameInList(record.roblox_username, currentRobloxUser) then
						if not isAutoLogin then 
							StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50) 
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
							StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50) 
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
					StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50) 
					StatusKey.Text = "Key tidak ditemukan / invalid!" 
				end
				KeyFrame.Visible = true
			end
		else
			if not isAutoLogin then 
				StatusKey.TextColor3 = Color3.fromRGB(255, 50, 50) 
				StatusKey.Text = "Gagal terhubung ke database verifikasi." 
			end
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
		else
			KeyFrame.Visible = true
		end
	else
		KeyFrame.Visible = true
	end
end)

----------------------------------------------------
-- 1. FISHING PAGE
----------------------------------------------------
local TitleFish = Instance.new("TextLabel")
TitleFish.Parent = FishingPage
TitleFish.Size = UDim2.new(1,0,0,30)
TitleFish.BackgroundTransparency = 1
TitleFish.Text = "🔥 AUTO FISHING & SELL UTILITIES"
TitleFish.TextColor3 = Color3.fromRGB(0,170,255)
TitleFish.Font = Enum.Font.GothamBold
TitleFish.TextSize = 13

local SpotDropdownFrame = Instance.new("Frame")
SpotDropdownFrame.Parent = FishingPage
SpotDropdownFrame.Size = UDim2.new(1,0,0,35)
SpotDropdownFrame.BackgroundColor3 = Color3.fromRGB(30,30,40)
SpotDropdownFrame.ClipsDescendants = true
local sdc = Instance.new("UICorner")
sdc.Parent = SpotDropdownFrame

local DropHeader = Instance.new("TextButton")
DropHeader.Parent = SpotDropdownFrame
DropHeader.Size = UDim2.new(1,0,0,35)
DropHeader.BackgroundTransparency = 1
DropHeader.Text = "  📍 Spot: " .. (getgenv().SelectedFishingSpot or "Spot Mancing Jembatan") .. " 🔽"
DropHeader.TextColor3 = Color3.fromRGB(0, 170, 255)
DropHeader.Font = Enum.Font.GothamBold
DropHeader.TextSize = 11
DropHeader.TextXAlignment = Enum.TextXAlignment.Left

local function SetSpotDisplay(text)
	DropHeader.Text = "  📍 Spot: " .. tostring(text) .. " 🔽"
end

local DropContainer = Instance.new("Frame")
DropContainer.Parent = SpotDropdownFrame
DropContainer.Position = UDim2.new(0, 5, 0, 35)
DropContainer.Size = UDim2.new(1, -10, 0, 95)
DropContainer.BackgroundTransparency = 1

local DropLayout = Instance.new("UIListLayout")
DropLayout.Parent = DropContainer
DropLayout.Padding = UDim.new(0, 4)

local isDropOpen = false
DropHeader.MouseButton1Click:Connect(function()
	isDropOpen = not isDropOpen
	SpotDropdownFrame:TweenSize(isDropOpen and UDim2.new(1,0,0,135) or UDim2.new(1,0,0,35), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
end)

for _, spotName in ipairs({"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"}) do
	local optBtn = Instance.new("TextButton")
	optBtn.Parent = DropContainer
	optBtn.Size = UDim2.new(1,0,0,26)
	optBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
	optBtn.Text = "  " .. spotName
	optBtn.TextColor3 = Color3.new(1,1,1)
	optBtn.Font = Enum.Font.Gotham
	optBtn.TextSize = 11
	optBtn.TextXAlignment = Enum.TextXAlignment.Left
	local obc = Instance.new("UICorner")
	obc.Parent = optBtn
	
	optBtn.MouseButton1Click:Connect(function()
		getgenv().SelectedFishingSpot = spotName
		getgenv().UbeyConfig.SelectedSpot = spotName
		SetSpotDisplay(spotName)
		isDropOpen = false
		SpotDropdownFrame:TweenSize(UDim2.new(1,0,0,35), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
		SaveConfig()
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

AddToggle(FishingPage, "Auto Sell Timer ke NPC", function(v)
	getgenv().AutoSellRunning = v
	if v then
		task.spawn(function()
			local lastSellTime = tick()
			while getgenv().AutoSellRunning do
				task.wait(1)
				if ((tick() - lastSellTime) / 60) >= (tonumber(getgenv().AutoSellTimerInput) or 5) then
					TriggerSellToNpc()
					lastSellTime = tick()
				end
			end
		end)
	end
end)

----------------------------------------------------
-- 2. FAVORITE PAGE
----------------------------------------------------
local TitleFav = Instance.new("TextLabel")
TitleFav.Parent = FavoritePage
TitleFav.Size = UDim2.new(1,0,0,30)
TitleFav.BackgroundTransparency = 1
TitleFav.Text = "⭐ AUTO FAVORITE & UNFAVORITE MANAGER"
TitleFav.TextColor3 = Color3.fromRGB(0,170,255)
TitleFav.Font = Enum.Font.GothamBold
TitleFav.TextSize = 13

AddToggle(FavoritePage, "Enable Auto Favorite Loop", function(v)
	getgenv().AutoFavoriteRunning = v
end)

local UnfavAllBtn = Instance.new("TextButton")
UnfavAllBtn.Parent = FavoritePage
UnfavAllBtn.Size = UDim2.new(1,0,0,35)
UnfavAllBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
UnfavAllBtn.Text = "🚨 Unfavorite Semua Ikan (In-Inventory)"
UnfavAllBtn.TextColor3 = Color3.new(1,1,1)
UnfavAllBtn.Font = Enum.Font.GothamBold
local ufac = Instance.new("UICorner")
ufac.Parent = UnfavAllBtn
UnfavAllBtn.MouseButton1Click:Connect(UnfavoriteAllFish)

for rName, defaultState in pairs(getgenv().FavRarities) do
	local cb = Instance.new("TextButton")
	cb.Parent = FavoritePage
	cb.Size = UDim2.new(1,0,0,28)
	cb.BackgroundColor3 = defaultState and Color3.fromRGB(0,120,80) or Color3.fromRGB(35,35,45)
	cb.Text = "  [Rarity] " .. rName .. (defaultState and " [✓]" or " [ ]")
	cb.TextColor3 = Color3.new(1,1,1)
	cb.Font = Enum.Font.Gotham
	cb.TextXAlignment = Enum.TextXAlignment.Left
	local cbc = Instance.new("UICorner")
	cbc.Parent = cb
	
	cb.MouseButton1Click:Connect(function()
		getgenv().FavRarities[rName] = not getgenv().FavRarities[rName]
		local st = getgenv().FavRarities[rName]
		cb.Text = "  [Rarity] " .. rName .. (st and " [✓]" or " [ ]")
		cb.BackgroundColor3 = st and Color3.fromRGB(0,120,80) or Color3.fromRGB(35,35,45)
	end)
end

----------------------------------------------------
-- 3. GALATAMA PAGE
----------------------------------------------------
local TitleGala = Instance.new("TextLabel")
TitleGala.Parent = GalatamaPage
TitleGala.Size = UDim2.new(1,0,0,30)
TitleGala.BackgroundTransparency = 1
TitleGala.Text = "🏆 GALATAMA EVENT UTILITIES"
TitleGala.TextColor3 = Color3.fromRGB(0,170,255)
TitleGala.Font = Enum.Font.GothamBold
TitleGala.TextSize = 13

AddToggle(GalatamaPage, "Auto Teleport Galatama Spot", function(v)
	getgenv().AutoGalatamaRunning = v
	if v then
		pcall(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = GalatamaSpotCFrame + Vector3.new(0, 5, 0) end
		end)
	end
end)

----------------------------------------------------
-- 4. TELEPORT SHOP PAGE
----------------------------------------------------
local TitleTp = Instance.new("TextLabel")
TitleTp.Parent = TeleportShopPage
TitleTp.Size = UDim2.new(1,0,0,30)
TitleTp.BackgroundTransparency = 1
TitleTp.Text = "🏪 TELEPORT LOCATIONS & SHOPS"
TitleTp.TextColor3 = Color3.fromRGB(0,170,255)
TitleTp.Font = Enum.Font.GothamBold
TitleTp.TextSize = 13

local TeleportList = {
	["NPC Jual Ikan (Sell NPC)"] = CFrame.new(-6668.01416, 1312.69983, -9965.2998),
	["Toko Pancing (Rod Shop)"] = CFrame.new(-6712.12, 1312.7, -9920.45),
	["Spot Mancing Jembatan"] = FishingSpots["Spot Mancing Jembatan"],
	["Spot Mancing Core"] = FishingSpots["Spot Mancing Core"],
	["Spot Mancing Ikan Anomali"] = FishingSpots["Spot Mancing Ikan Anomali"]
}

for name, cf in pairs(TeleportList) do
	local tpBtn = Instance.new("TextButton")
	tpBtn.Parent = TeleportShopPage
	tpBtn.Size = UDim2.new(1,0,0,35)
	tpBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	tpBtn.Text = "📍 Teleport ke " .. name
	tpBtn.TextColor3 = Color3.new(1,1,1)
	tpBtn.Font = Enum.Font.Gotham
	local tpc = Instance.new("UICorner")
	tpc.Parent = tpBtn
	
	tpBtn.MouseButton1Click:Connect(function()
		pcall(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = cf + Vector3.new(0, 5, 0) end
		end)
	end)
end

----------------------------------------------------
-- 5. SUMMIT PAGE
----------------------------------------------------
local TitleSum = Instance.new("TextLabel")
TitleSum.Parent = SummitPage
TitleSum.Size = UDim2.new(1,0,0,30)
TitleSum.BackgroundTransparency = 1
TitleSum.Text = "⛰️ SUMMIT SPOT UTILITIES"
TitleSum.TextColor3 = Color3.fromRGB(0,170,255)
TitleSum.Font = Enum.Font.GothamBold
TitleSum.TextSize = 13

AddToggle(SummitPage, "Auto Teleport Summit Spot", function(v)
	getgenv().AutoSummitRunning = v
	if v then
		pcall(function()
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = SummitSpotCFrame + Vector3.new(0, 5, 0) end
		end)
	end
end)

----------------------------------------------------
-- 6. PLAYER PAGE (SPEED, JUMP, FLY)
----------------------------------------------------
local TitlePlr = Instance.new("TextLabel")
TitlePlr.Parent = PlayerPage
TitlePlr.Size = UDim2.new(1,0,0,30)
TitlePlr.BackgroundTransparency = 1
TitlePlr.Text = "👤 PLAYER MODIFICATIONS"
TitlePlr.TextColor3 = Color3.fromRGB(0,170,255)
TitlePlr.Font = Enum.Font.GothamBold
TitlePlr.TextSize = 13

AddToggle(PlayerPage, "Speed Hack (WalkSpeed 50)", function(v)
	pcall(function()
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v and 50 or 16 end
	end)
end)

AddToggle(PlayerPage, "High Jump (JumpPower 100)", function(v)
	pcall(function()
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = v and 100 or 50
		end
	end)
end)

AddToggle(PlayerPage, "Infinite Jump", function(v)
	getgenv().InfJumpEnabled = v
end)

UIS.JumpRequest:Connect(function()
	if getgenv().InfJumpEnabled then
		pcall(function()
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	end
end)

----------------------------------------------------
-- 7. HALO KEPALA PAGE (COSMETIC)
----------------------------------------------------
local TitleHalo = Instance.new("TextLabel")
TitleHalo.Parent = HaloPage
TitleHalo.Size = UDim2.new(1,0,0,30)
TitleHalo.BackgroundTransparency = 1
TitleHalo.Text = "😇 CLIENT-SIDE HALO COSMETIC"
TitleHalo.TextColor3 = Color3.fromRGB(0,170,255)
TitleHalo.Font = Enum.Font.GothamBold
TitleHalo.TextSize = 13

local HaloList = {"Gold Halo", "Neon Blue Halo", "Rainbow Halo", "Dark Void Halo"}
for _, haloName in ipairs(HaloList) do
	local hBtn = Instance.new("TextButton")
	hBtn.Parent = HaloPage
	hBtn.Size = UDim2.new(1,0,0,32)
	hBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	hBtn.Text = "✨ Equip " .. haloName
	hBtn.TextColor3 = Color3.new(1,1,1)
	hBtn.Font = Enum.Font.Gotham
	local hbc = Instance.new("UICorner")
	hbc.Parent = hBtn
	
	hBtn.MouseButton1Click:Connect(function()
		getgenv().CurrentSelectedHalo = haloName
		hBtn.Text = "✅ Halo " .. haloName .. " Active!"
		task.wait(1.5)
		hBtn.Text = "✨ Equip " .. haloName
	end)
end

----------------------------------------------------
-- 8. TELEPORT PLAYER PAGE
----------------------------------------------------
local TitlePlrTp = Instance.new("TextLabel")
TitlePlrTp.Parent = PlayerTpPage
TitlePlrTp.Size = UDim2.new(1,0,0,30)
TitlePlrTp.BackgroundTransparency = 1
TitlePlrTp.Text = "🚀 TELEPORT TO OTHER PLAYER"
TitlePlrTp.TextColor3 = Color3.fromRGB(0,170,255)
TitlePlrTp.Font = Enum.Font.GothamBold
TitlePlrTp.TextSize = 13

local RefreshPlrBtn = Instance.new("TextButton")
RefreshPlrBtn.Parent = PlayerTpPage
RefreshPlrBtn.Size = UDim2.new(1,0,0,32)
RefreshPlrBtn.BackgroundColor3 = Color3.fromRGB(0,120,180)
RefreshPlrBtn.Text = "🔄 Refresh List Player"
RefreshPlrBtn.TextColor3 = Color3.new(1,1,1)
RefreshPlrBtn.Font = Enum.Font.GothamBold
local rpc = Instance.new("UICorner")
rpc.Parent = RefreshPlrBtn

local PlrListContainer = Instance.new("Frame")
PlrListContainer.Parent = PlayerTpPage
PlrListContainer.Size = UDim2.new(1,0,0,150)
PlrListContainer.BackgroundTransparency = 1

local function RefreshPlayerList()
	for _, child in ipairs(PlrListContainer:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	
	local yOffset = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local pBtn = Instance.new("TextButton")
			pBtn.Parent = PlrListContainer
			pBtn.Position = UDim2.new(0,0,0,yOffset)
			pBtn.Size = UDim2.new(1,0,0,30)
			pBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
			pBtn.Text = "👤 TP ke " .. plr.Name
			pBtn.TextColor3 = Color3.new(1,1,1)
			pBtn.Font = Enum.Font.Gotham
			local pbc = Instance.new("UICorner")
			pbc.Parent = pBtn
			
			pBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					local targetHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if myHrp and targetHrp then
						myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
					end
				end)
			end)
			yOffset = yOffset + 35
		end
	end
end

RefreshPlrBtn.MouseButton1Click:Connect(RefreshPlayerList)
task.spawn(RefreshPlayerList)

----------------------------------------------------
-- 9. PRIVACY PAGE (ANTI-ADMIN & FAKE NAME)
----------------------------------------------------
local TitlePriv = Instance.new("TextLabel")
TitlePriv.Parent = PrivacyPage
TitlePriv.Size = UDim2.new(1,0,0,30)
TitlePriv.BackgroundTransparency = 1
TitlePriv.Text = "🛡️ PRIVACY & ANTI-ADMIN SYSTEM"
TitlePriv.TextColor3 = Color3.fromRGB(0,170,255)
TitlePriv.Font = Enum.Font.GothamBold
TitlePriv.TextSize = 13

AddToggle(PrivacyPage, "Anti-Admin Auto Kick / Server Hop", function(v)
	getgenv().UbeyConfig.AntiAdminEnabled = v
	SaveConfig()
end)

local FakeNameBox = Instance.new("TextBox")
FakeNameBox.Parent = PrivacyPage
FakeNameBox.Size = UDim2.new(1,0,0,35)
FakeNameBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
FakeNameBox.PlaceholderText = "Masukkan Fake Name Client..."
FakeNameBox.Text = "UBEY HUB V3"
FakeNameBox.TextColor3 = Color3.new(1,1,1)
local fnc = Instance.new("UICorner")
fnc.Parent = FakeNameBox

----------------------------------------------------
-- 10. SETTINGS PAGE (WEBHOOK MONITOR)
----------------------------------------------------
local TitleSet = Instance.new("TextLabel")
TitleSet.Parent = SettingsPage
TitleSet.Size = UDim2.new(1,0,0,30)
TitleSet.BackgroundTransparency = 1
TitleSet.Text = "⚙️ DISCORD WEBHOOK & CONFIGURATION"
TitleSet.TextColor3 = Color3.fromRGB(0,170,255)
TitleSet.Font = Enum.Font.GothamBold
TitleSet.TextSize = 13

local WebhookToggleBtn = Instance.new("TextButton")
WebhookToggleBtn.Parent = SettingsPage
WebhookToggleBtn.Size = UDim2.new(1,0,0,35)
WebhookToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.WebhookEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(30, 30, 40)
WebhookToggleBtn.Text = "  Discord Webhook Monitor: " .. (getgenv().UbeyConfig.WebhookEnabled and "[ON]" or "[OFF]")
WebhookToggleBtn.TextColor3 = Color3.new(1,1,1)
WebhookToggleBtn.Font = Enum.Font.Gotham
WebhookToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
local wtc = Instance.new("UICorner")
wtc.Parent = WebhookToggleBtn

WebhookToggleBtn.MouseButton1Click:Connect(function()
	getgenv().UbeyConfig.WebhookEnabled = not getgenv().UbeyConfig.WebhookEnabled
	WebhookToggleBtn.Text = "  Discord Webhook Monitor: " .. (getgenv().UbeyConfig.WebhookEnabled and "[ON]" or "[OFF]")
	WebhookToggleBtn.BackgroundColor3 = getgenv().UbeyConfig.WebhookEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(30, 30, 40)
	SaveConfig()
end)

local WebhookBox = Instance.new("TextBox")
WebhookBox.Parent = SettingsPage
WebhookBox.Size = UDim2.new(1,0,0,35)
WebhookBox.BackgroundColor3 = Color3.fromRGB(35,35,45)
WebhookBox.PlaceholderText = "Paste Discord Webhook URL di sini..."
WebhookBox.Text = tostring(getgenv().UbeyConfig.WebhookUrl or "")
WebhookBox.TextColor3 = Color3.new(1,1,1)
local wbc = Instance.new("UICorner")
wbc.Parent = WebhookBox
WebhookBox.FocusLost:Connect(function()
	getgenv().UbeyConfig.WebhookUrl = WebhookBox.Text
	SaveConfig()
end)

local TestWebhookBtn = Instance.new("TextButton")
TestWebhookBtn.Parent = SettingsPage
TestWebhookBtn.Size = UDim2.new(1,0,0,35)
TestWebhookBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
TestWebhookBtn.TextColor3 = Color3.new(1,1,1)
TestWebhookBtn.Font = Enum.Font.GothamBold
local twc = Instance.new("UICorner")
twc.Parent = TestWebhookBtn

TestWebhookBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local url = getgenv().UbeyConfig.WebhookUrl
		if not url or url == "" or not string.find(url, "api/webhooks") then
			TestWebhookBtn.Text = "❌ URL Webhook Salah!"
			task.wait(2)
			TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
			return
		end
		
		local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
		if requestFunc then
			requestFunc({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({ ["content"] = "✅ **Ubey Hub V3 Webhook Active!**" })
			})
			TestWebhookBtn.Text = "✅ Test Berhasil Dikirim!"
		end
		task.wait(2)
		TestWebhookBtn.Text = "🧪 Test Kirim Webhook ke Discord"
	end)
end)

----------------------------------------------------
-- 11. CREDITS PAGE
----------------------------------------------------
local TitleCred = Instance.new("TextLabel")
TitleCred.Parent = CreditsPage
TitleCred.Size = UDim2.new(1,0,0,30)
TitleCred.BackgroundTransparency = 1
TitleCred.Text = "📜 UBEY HUB V3 CREDITS"
TitleCred.TextColor3 = Color3.fromRGB(0,170,255)
TitleCred.Font = Enum.Font.GothamBold
TitleCred.TextSize = 13

local CredLabel = Instance.new("TextLabel")
CredLabel.Parent = CreditsPage
CredLabel.Size = UDim2.new(1,0,0,80)
CredLabel.BackgroundColor3 = Color3.fromRGB(30,30,40)
CredLabel.Text = "Created & Developed by Ubey Hub Team\nSpecial thanks to all VIP Subscribers & Supporters!"
CredLabel.TextColor3 = Color3.new(1,1,1)
CredLabel.Font = Enum.Font.Gotham
CredLabel.TextSize = 12
local crc = Instance.new("UICorner")
crc.Parent = CredLabel

----------------------------------------------------
-- BOTTOM STAT TRACKER
----------------------------------------------------
local StatPanel = Instance.new("Frame")
StatPanel.Parent = Main
StatPanel.Size = UDim2.new(1, -160, 0, 24)
StatPanel.Position = UDim2.new(0, 150, 1, -28)
StatPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
local stpCorner = Instance.new("UICorner")
stpCorner.CornerRadius = UDim.new(0, 6)
stpCorner.Parent = StatPanel

local StatLabel = Instance.new("TextLabel")
StatLabel.Parent = StatPanel
StatLabel.Size = UDim2.new(1, -10, 1, 0)
StatLabel.Position = UDim2.new(0, 5, 0, 0)
StatLabel.BackgroundTransparency = 1
StatLabel.Text = "📊 Total Ikan: 0  |  ⏱️ Play Time: 00s"
StatLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
StatLabel.Font = Enum.Font.GothamBold
StatLabel.TextSize = 11
StatLabel.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
	while true do
		pcall(function()
			local elapsed = os.time() - getgenv().SessionStartTime
			local mins = math.floor((elapsed % 3600) / 60)
			local secs = elapsed % 60
			StatLabel.Text = string.format("📊 Total Ikan: %d  |  ⏱️ Play: %02dm %02ds", getgenv().TotalFishCaught, mins, secs)
		end)
		task.wait(1)
	end
end)

----------------------------------------------------
-- FLOATING BUTTON TOGGLE
----------------------------------------------------
local Float = Instance.new("ImageButton")
Float.Parent = Gui
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)
local flCorner = Instance.new("UICorner")
flCorner.CornerRadius = UDim.new(1,0)
flCorner.Parent = Float
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
