-- ==============================================================================
-- UBEY HUB | MERGED + FORT KNOX SECURITY (FISHING, SUMMIT, DAILY, COOKING)
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
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ====== PENGATURAN ======
local HUB_TITLE = "UBEY HUB"
local HUB_SUBTITLE = "PREMIUM"
local HUB_DISCORD = "discord.gg/YXuYeEpnXE"
local LOGO_ASSET = "rbxassetid://90770802417381"
local WIN_W, WIN_H = 580, 360

local CONFIG_FILE = "UbeyHub_Config.json"
local KEY_FILE = "UbeyHub_SavedKey.txt"

local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_rMWL7Qrjw9iG0c29vGZ0bw_O3swXT6n"

-- [SECURITY LAYER 1] Menyembunyikan Status Verifikasi di dalam Metatable rahasia
local SecureData = setmetatable({}, {
	__index = function(t, k)
		if k == "IsKeyVerified" then return rawget(t, "_verified") end
	end,
	__newindex = function(t, k, v)
		if k == "IsKeyVerified" then rawset(t, "_verified", v) end
	end
})
SecureData.IsKeyVerified = false

-- ====== CONFIG ======
getgenv().UbeyConfig = {
	WaitTime = 4.0,
	LoopDelay = 0.1,
	AutoSellTimer = "5",
	SellFoodMode = "Coins",
	SellFoodInterval = "5",
	LuckInterval = "15",
	LuckTier = "1",
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
getgenv().AutoDailyRunning = false
getgenv().AutoCookPipeline = false
getgenv().AntiAFKRunning = false
getgenv().AutoSellFoodRunning = false
getgenv().AutoLuckRunning = false
getgenv().TotalFishCaught = 0
getgenv().TotalSummitRun = 0
getgenv().SessionStartTime = os.time()

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

-- ====== FISHING ANIMATIONS ======
local FISH_ANIM = {
	Equipped = "rbxassetid://89604053251259",
	Pulling = "rbxassetid://123395663531909",
	Waiting = "rbxassetid://96286683902029",
}

local function PlayFishAnim(character, animId)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if ok and track then track:Play() end
	return track
end

task.spawn(function()
	local FS = ReplicatedStorage:WaitForChild("FishingSystem", 10)
	if not FS then return end
	local CastReplication = FS:WaitForChild("CastReplication")
	local CleanupCast = FS:WaitForChild("CleanupCast")
	local FishGiver = FS:WaitForChild("FishGiver")

	while true do
		if getgenv().AutoFishingRunning then
			if not SecureData.IsKeyVerified then getgenv().AutoFishingRunning = false; break end
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

					-- animasi menunggu pancingan selama WaitTime
					local waitTrack = PlayFishAnim(char, FISH_ANIM.Waiting)
					task.wait(tonumber(getgenv().UbeyConfig.WaitTime) or 4.0)
					if waitTrack then waitTrack:Stop() end

					-- animasi menarik sesaat sebelum ambil ikan
					local pullTrack = PlayFishAnim(char, FISH_ANIM.Pulling)
					FishGiver:FireServer({ hookPosition = hookVec, powerPercent = 0 })
					task.wait(0.4)
					if pullTrack then pullTrack:Stop() end

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

-- ====== AUTO DAILY LOGIN LOGIC ======
task.spawn(function()
	task.wait(5)
	while true do
		if getgenv().AutoDailyRunning then
			if not SecureData.IsKeyVerified then getgenv().AutoDailyRunning = false; break end
			pcall(function()
				local DailyReward = ReplicatedStorage:FindFirstChild("DailyReward")
				if DailyReward then
					DailyReward:InvokeServer("claim")
				end
			end)
		end
		task.wait(30)
	end
end)

-- ====== COOKING LOGIC ======
local CookData = { Menus = {}, Ingredients = {}, GrinderTime = {}, CookTime = {} }
pcall(function()
	local cfg = require(ReplicatedStorage.CookingSystem.FishCookingConfig)
	CookData.Menus = cfg.Menus or {}
	CookData.Ingredients = cfg.MenuIngredients or {}
	CookData.GrinderTime = cfg.GrinderTime or {}
	CookData.CookTime = cfg.CookTime or {}
end)
if #CookData.Menus == 0 then
	CookData.Menus = { { Id = "ikan_bakar", Rarity = "Common", Name = "Ikan Bakar" } }
	CookData.Ingredients = { ikan_bakar = { ["Bumbu Dapur"] = 1 } }
	CookData.GrinderTime = { Common = 2 }
	CookData.CookTime = { Common = 2 }
end

local CookCfg = {
	Index = 1, Amount = 6, BuyCap = 15, GrindSlots = 10, Interval = 10,
	FirePrompt = false, GrindRarity = { common = true }, GrindLimit = 6,
}

-- Menyimpan hasil giling terakhir (per rarity) untuk fitur Preview Hasil Masak
local LastGrindCounts = {}

local function CookRemote(folder, name)
	local f = ReplicatedStorage:FindFirstChild(folder)
	return f and f:FindFirstChild(name)
end

-- Data inventaris asli dari akun (ikan belum digiling, total daging, makanan jadi, dst.)
local LastInventorySnapshot = nil
local function GetInventorySnapshot()
	local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
	local invFolder = fs and fs:FindFirstChild("InventoryEvents")
	local invEvent = invFolder and invFolder:FindFirstChild("Inventory_GetData")
	if not invEvent then return nil end
	local ok, data = pcall(function() return invEvent:InvokeServer("Light") end)
	if ok and type(data) == "table" then return data end
	return nil
end

-- Jual semua makanan jadi. mode = "Coins" atau "Token" (Token = Diamond)
local function SellFoodRemote(mode)
	local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
	local invFolder = fs and fs:FindFirstChild("InventoryEvents")
	local sellEvent = invFolder and invFolder:FindFirstChild("Inventory_SellFood")
	if not sellEvent then return false end
	local ok = pcall(function() sellEvent:InvokeServer("All", mode) end)
	return ok
end

local function CurrentMenu() return CookData.Menus[CookCfg.Index] or CookData.Menus[1] end
local function IngredientText(menuId)
	local parts = {}
	for name, qty in pairs(CookData.Ingredients[menuId] or {}) do
		table.insert(parts, name .. " x" .. qty)
	end
	table.sort(parts)
	return table.concat(parts, ", ")
end

local StationCache = {}
local function GetHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end
local function PromptPos(p)
	local par = p.Parent
	if not par then return nil end
	if par:IsA("BasePart") then return par.Position end
	if par:IsA("Attachment") then return par.WorldPosition end
	if par:IsA("Model") then return par:GetPivot().Position end
	return nil
end
local function FindStation(key)
	local cached = StationCache[key]
	if cached and cached.Parent then return cached end
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local t = (d.ActionText .. " " .. d.ObjectText):lower()
			if t:find(key, 1, true) then
				StationCache[key] = d
				return d
			end
		end
	end
	return nil
end
local function GoToStation(key)
	local prompt = FindStation(key)
	local hrp = GetHRP()
	if not prompt or not hrp then return false end
	local pos = PromptPos(prompt)
	if not pos then return false end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	task.wait(0.6)
	if CookCfg.FirePrompt and fireproximityprompt then
		pcall(function() fireproximityprompt(prompt) end)
		task.wait(0.4)
	end
	return true
end
local function RunAtStations(fn)
	local hrp = GetHRP()
	local home = hrp and hrp.CFrame
	local ok, err = pcall(fn)
	if not ok then warn("[Cooking] " .. tostring(err)) end
	hrp = GetHRP()
	if hrp and home then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = home
	end
end

local function GetGrindList()
	local r = CookRemote("CookingSystem", "GrindList")
	if not r then return {} end
	local ok, res = pcall(function() return r:InvokeServer() end)
	if not ok or type(res) ~= "table" then return {} end
	local out = {}
	local function collect(t, depth)
		if type(t) ~= "table" or depth > 5 then return end
		local id = t.uniqueId or t.uniqueID or t.UniqueId
		if id then
			table.insert(out, { id = id, rarity = tostring(t.rarity or ""):lower(), name = t.name, fav = t.isFavorited == true })
			return
		end
		for _, v in pairs(t) do collect(v, depth + 1) end
	end
	collect(res, 0)
	return out
end

local function DumpGrindList()
	RunAtStations(function()
		GoToStation("giling")
		local r = CookRemote("CookingSystem", "GrindList")
		if not r then return end
		local ok, res = pcall(function() return r:InvokeServer() end)
		print("[GrindList] ok =", ok, "type =", typeof(res))
	end)
end

local RarityList = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Unknown", "Forgotten" }

local function MenusOfRarity(r)
	local out = {}
	for i, m in ipairs(CookData.Menus) do
		if m.Rarity == r then table.insert(out, i) end
	end
	return out
end

local function GrinderTimeOf(rarityLower)
	for _, R in ipairs(RarityList) do
		if R:lower() == rarityLower then return CookData.GrinderTime[R] or 2 end
	end
	return 2
end

local function GrindNow()
	local r = CookRemote("CookingSystem", "GrindRequest")
	if not r then return 0, {} end
	if not GoToStation("giling") then return 0, {} end
	local limit = math.max(1, tonumber(CookCfg.GrindLimit) or 6)
	local ids, counts = {}, {}
	for _, it in ipairs(GetGrindList()) do
		if it.id and not it.fav and CookCfg.GrindRarity[it.rarity] then
			table.insert(ids, it.id)
			counts[it.rarity] = (counts[it.rarity] or 0) + 1
			if #ids >= limit then break end
		end
	end
	local slots = math.max(1, tonumber(CookCfg.GrindSlots) or 10)
	for i = 1, #ids, slots do
		local chunk = {}
		for j = i, math.min(i + slots - 1, #ids) do table.insert(chunk, ids[j]) end
		pcall(function() r:FireServer(chunk) end)
		task.wait(1)
	end
	if #ids > 0 then
		local t = 1
		for rar, c in pairs(counts) do t = t + GrinderTimeOf(rar) * c end
		task.wait(t)
	end
	LastGrindCounts = counts
	return #ids, counts
end

local function BuyNow(item, total)
	local r = CookRemote("TokoEvents", "TokoBuy")
	if not r then return end
	local left = total
	local cap = math.max(1, tonumber(CookCfg.BuyCap) or 15)
	while left > 0 do
		local n = math.min(left, cap)
		pcall(function() r:InvokeServer(item, n) end)
		left = left - n
		task.wait(0.4)
	end
end

local function BuyForRecipe(amt)
	if not GoToStation("toko bahan") then return end
	local menu = CurrentMenu()
	amt = math.max(1, tonumber(amt) or tonumber(CookCfg.Amount) or 6)
	for name, qty in pairs(CookData.Ingredients[menu.Id] or {}) do
		BuyNow(name, qty * amt)
	end
end

local function CookNow(amt)
	local r = CookRemote("CookingSystem", "CookingCook")
	if not r then return end
	local menu = CurrentMenu()
	amt = math.max(1, tonumber(amt) or tonumber(CookCfg.Amount) or 6)
	BuyForRecipe(amt)
	if not GoToStation("resep") then return end
	pcall(function() r:FireServer(menu.Id, amt) end)
	task.wait((CookData.CookTime[menu.Rarity] or 2) * amt + 2)
end

local function GrindManual()
	local cnt = 0
	RunAtStations(function() cnt = GrindNow() end)
	return cnt
end
local function BuyManual() RunAtStations(function() BuyForRecipe() end) end
local function CookManual() RunAtStations(function() CookNow() end) end

-- Auto Cooking SENGAJA tidak memakai RunAtStations: fungsi itu selalu mengembalikan
-- karakter ke posisi awal setelah tiap siklus, yang justru bikin bolak-balik tidak perlu
-- saat mode auto dipakai terus-menerus. Di sini karakter dibiarkan tetap di area stasiun
-- antar siklus, supaya giling -> beli -> masak bisa langsung lanjut tanpa jeda posisi.
task.spawn(function()
	while true do
		if getgenv().AutoCookPipeline then
			if not SecureData.IsKeyVerified then getgenv().AutoCookPipeline = false; break end
			local ok, err = pcall(function()
				local _, counts = GrindNow()
				local have = counts[tostring(CurrentMenu().Rarity):lower()] or 0
				if have > 0 and getgenv().AutoCookPipeline and SecureData.IsKeyVerified then
					CookNow(math.min(have, tonumber(CookCfg.Amount) or 6))
				end
			end)
			if not ok then
				warn("[AutoCook] Error (diabaikan, lanjut siklus berikutnya): " .. tostring(err))
			end
			task.wait(tonumber(CookCfg.Interval) or 10)
		else
			task.wait(0.5)
		end
	end
end)

-- ====== SUMMIT LOGIC ======
local waypoints = {
	Vector3.new(-4.2, 16.3, 886.5), Vector3.new(-176.9, 79.6, 1907.9),
	Vector3.new(0.5, 131.2, 2793.1), Vector3.new(-1107.6, 362.1, 3266.3),
	Vector3.new(-1236.0, 504.5, 3828.8), Vector3.new(-1754.2, 730.9, 4525.4),
	Vector3.new(-1814.4, 746.4, 5568.2), Vector3.new(-2882.8, 740.9, 6129.6),
	Vector3.new(-3485.3, 740.2, 6524.1), Vector3.new(-3071.4, 794.4, 7228.8),
	Vector3.new(-2916.1, 835.4, 7965.9), Vector3.new(-2932.0, 849.1, 8838.7),
	Vector3.new(-3510.9, 1021.1, 9350.6), Vector3.new(-3472.3, 1021.8, 10147.4),
	Vector3.new(-3613.4, 1022.4, 10852.6), Vector3.new(-3849.1, 1048.2, 11692.4),
	Vector3.new(-4051.8, 1115.9, 12606.3), Vector3.new(-3995.3, 1197.4, 13586.2),
	Vector3.new(-4306.6, 1276.0, 14465.3), Vector3.new(-4564.7, 1295.0, 15327.3),
	Vector3.new(-4747.6, 1323.8, 16335.5), Vector3.new(-4821.9, 1366.9, 17051.8),
	Vector3.new(-5133.6, 1531.3, 17596.4), Vector3.new(-5339.5, 1631.6, 18276.7),
	Vector3.new(-5362.9, 1737.9, 19296.5), Vector3.new(-5376.3, 1761.7, 19944.1),
	Vector3.new(-5593.8, 1890.4, 20588.2), Vector3.new(-5700.9, 1975.2, 21045.2),
	Vector3.new(-6024.9, 1977.4, 21183.8), Vector3.new(-6633.9, 2048.1, 21482.6),
	Vector3.new(-6634.3, 2230.0, 22351.3),
}

task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			if not SecureData.IsKeyVerified then getgenv().AutoSummitRunning = false; break end
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

-- ====== LUCK GENERATOR LOGIC ======
local function BuyLuckGenerator(tier)
	local lg = ReplicatedStorage:FindFirstChild("LuckGenerator")
	local purchaseEvent = lg and lg:FindFirstChild("LuckGeneratorPurchase")
	if not purchaseEvent then return false end
	local ok = pcall(function() purchaseEvent:FireServer(tonumber(tier) or 1) end)
	return ok
end

task.spawn(function()
	while true do
		if getgenv().AutoLuckRunning then
			if not SecureData.IsKeyVerified then getgenv().AutoLuckRunning = false; break end
			BuyLuckGenerator(getgenv().UbeyConfig.LuckTier)
			local minutes = tonumber(getgenv().UbeyConfig.LuckInterval) or 15
			task.wait(math.max(minutes, 1) * 60)
		else
			task.wait(0.5)
		end
	end
end)

-- ====== AUTO SELL FOOD LOGIC ======
task.spawn(function()
	while true do
		if getgenv().AutoSellFoodRunning then
			if not SecureData.IsKeyVerified then getgenv().AutoSellFoodRunning = false; break end
			local mode = (getgenv().UbeyConfig.SellFoodMode == "Token") and "Token" or "Coins"
			SellFoodRemote(mode)
			local minutes = tonumber(getgenv().UbeyConfig.SellFoodInterval) or 5
			task.wait(math.max(minutes, 1) * 60)
		else
			task.wait(0.5)
		end
	end
end)

-- ====== SHOP: BEAN / PET / ROD (baca GUI toko asli yang sudah dibuat game) ======
-- Pet Shop & Rod Shop sudah punya GUI tersimpan di PlayerGui (PetShopGui, RodShopGui)
-- lengkap dengan gambar, harga, dan label "sudah dimiliki" -- jadi dibaca langsung
-- dari situ, bukan dari daftar hardcode, supaya otomatis ikut update kalau game
-- menambah item baru.

local function BuyBeanRemote(itemId)
	local ev = ReplicatedStorage:FindFirstChild("BeanbagShopEvent")
	if not ev then return false end
	return pcall(function() ev:FireServer("buy", itemId) end)
end

local function BuyPetRemote(itemId)
	local ev = ReplicatedStorage:FindFirstChild("PetShopEvent")
	if not ev then return false end
	return pcall(function() ev:FireServer("buy", itemId) end)
end

local function BuyRodRemote(itemId)
	local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
	local rodFolder = fs and fs:FindFirstChild("RodShopEvents")
	local ev = rodFolder and rodFolder:FindFirstChild("RequestPurchase")
	if not ev then return false end
	return pcall(function() ev:FireServer(itemId) end)
end

local function ScanPetShop()
	local gui = PlayerGui:FindFirstChild("PetShopGui")
	local list = gui and gui:FindFirstChild("OuterFrame") and gui.OuterFrame:FindFirstChild("PetList")
	if not list then return {} end
	local items = {}
	for _, card in ipairs(list:GetChildren()) do
		if card:IsA("Frame") and card.Name == "PetCard" then
			local imgFrame = card:FindFirstChild("ImageFrame")
			local petImg = imgFrame and imgFrame:FindFirstChild("PetImage")
			local nameLbl = card:FindFirstChild("PetName")
			local priceLbl = card:FindFirstChild("Price")
			local ownedLbl = card:FindFirstChild("OwnedLabel")
			table.insert(items, {
				Id = nameLbl and nameLbl.Text or card.Name,
				Name = nameLbl and nameLbl.Text or card.Name,
				Price = priceLbl and priceLbl.Text or nil,
				Image = petImg and petImg.Image or nil,
				OwnedLabel = ownedLbl,
			})
		end
	end
	return items
end

local function ScanRodShop()
	local gui = PlayerGui:FindFirstChild("RodShopGui")
	local scroll = gui and gui:FindFirstChild("MainFrame") and gui.MainFrame:FindFirstChild("ScrollFrame")
	if not scroll then return {} end
	local items = {}
	for _, card in ipairs(scroll:GetChildren()) do
		if card:IsA("Frame") and card:FindFirstChild("RodName") then
			local rodImg = card:FindFirstChild("RodImage")
			local nameLbl = card:FindFirstChild("RodName")
			local priceLbl = card:FindFirstChild("PriceLabel")
			local ownedLbl = card:FindFirstChild("OwnedLabel")
			table.insert(items, {
				Id = card.Name,
				Name = nameLbl and nameLbl.Text or card.Name,
				Price = priceLbl and priceLbl.Text or nil,
				Image = rodImg and rodImg.Image or nil,
				OwnedLabel = ownedLbl,
			})
		end
	end
	return items
end

-- Struktur GUI Beanbag Shop belum dipastikan (belum ada screenshot Explorer-nya),
-- jadi ini scan generik best-effort. Kalau daftarnya kosong/salah saat dites,
-- kirim screenshot Explorer BeanbagShopGui seperti punya Pet/Rod, nanti disesuaikan.
local function ScanBeanShop()
	local gui = PlayerGui:FindFirstChild("BeanbagShopGui")
	if not gui then return {} end
	local items = {}
	for _, card in ipairs(gui:GetDescendants()) do
		if card:IsA("Frame") and card:FindFirstChildWhichIsA("TextButton") and card:FindFirstChildWhichIsA("ImageLabel") then
			local nameLbl = card:FindFirstChild("BeanName") or card:FindFirstChild("Name")
			local priceLbl = card:FindFirstChild("Price") or card:FindFirstChild("PriceLabel")
			local imgObj = card:FindFirstChildWhichIsA("ImageLabel")
			table.insert(items, {
				Id = nameLbl and nameLbl.Text or card.Name,
				Name = nameLbl and nameLbl.Text or card.Name,
				Price = priceLbl and priceLbl.Text or nil,
				Image = imgObj and imgObj.Image or nil,
			})
		end
	end
	return items
end

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

local StatLabel = Label(Header, "📊 Fish: 0  |  ⛰️ Summit: 0  |  ⏱️ 00s", 11, C.accent, Enum.Font.GothamBold, UDim2.new(0, 130, 0, 0), UDim2.new(0, 260, 1, 0))

local PingLabel = Label(Header, "📡 -- ms", 11, C.good, Enum.Font.GothamBold, UDim2.new(0, 380, 0, 0), UDim2.new(1, -470, 1, 0), Enum.TextXAlignment.Right)

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

-- [SECURITY LAYER 2] ANTI-TAMPER (Jebakan Penghapus GUI)
task.spawn(function()
	while true do
		task.wait(2)
		if not KeyFrame or not KeyFrame.Parent then
			SecureData.IsKeyVerified = false
			getgenv().AutoFishingRunning = false
			getgenv().AutoSummitRunning = false
			getgenv().AutoSellRunning = false
			getgenv().AutoDailyRunning = false
			getgenv().AutoCookPipeline = false
			if Main and Main.Parent then Main:Destroy() end
			break
		end
	end
end)

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
				SecureData.IsKeyVerified = true
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
		if not SecureData.IsKeyVerified then
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
		if not SecureData.IsKeyVerified then return end
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

function UI.Picker(page, title, getOptions, getSelected, onSelect, getDesc)
	local card = Card(page, 54)
	card.ClipsDescendants = true
	Label(card, title, 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, 12, 0, 8), UDim2.new(1, -160, 0, 18))
	local descLbl = Label(card, "", 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 12, 0, 27), UDim2.new(1, -160, 0, 18))
	local btn = New("TextButton", {
		Size = UDim2.new(0, 132, 0, 30), Position = UDim2.new(1, -144, 0, 12),
		BackgroundColor3 = C.accent, Text = "Pilih ▾", TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd
	}, card)
	Round(btn, 8)
	local LIST_H = 124
	local list = New("ScrollingFrame", {
		Size = UDim2.new(1, -24, 0, LIST_H), Position = UDim2.new(0, 12, 0, 60),
		BackgroundColor3 = C.bg, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y
	}, card)
	Round(list, 8)
	New("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
	New("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8)}, list)

	local open = false
	local self = {}

	local function setOpen(v)
		open = v
		list.Visible = v
		card.Size = UDim2.new(1, -4, 0, v and (60 + LIST_H + 8) or 54)
	end

	function self.Refresh()
		local selected = getSelected()
		local opts = getOptions()
		for _, ch in ipairs(list:GetChildren()) do
			if ch:IsA("TextButton") then ch:Destroy() end
		end
		local selLabel = "Pilih"
		for i, o in ipairs(opts) do
			local isSel = (o.value == selected)
			if isSel then selLabel = o.label end
			local row = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, AutoButtonColor = false,
				BackgroundColor3 = isSel and C.accent or C.card, Text = o.label,
				TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
			}, list)
			Round(row, 6)
			New("UIPadding", {PaddingLeft = UDim.new(0, 10)}, row)
			row.MouseButton1Click:Connect(function()
				setOpen(false)
				onSelect(o.value)
			end)
		end
		btn.Text = selLabel .. " ▾"
		descLbl.Text = getDesc and getDesc() or ""
	end

	btn.MouseButton1Click:Connect(function() setOpen(not open) end)
	self.Refresh()
	return self
end

-- ====== TABS ======
local TabFish = UI.Tab("Fishing", "🎣")
local TabSummit = UI.Tab("Summit", "⛰️")
local TabDaily = UI.Tab("Daily", "📅") 
local TabCook = UI.Tab("Cooking", "🍳") 
local TabLuck = UI.Tab("Luck", "🍀")
local TabShop = UI.Tab("Shop", "🛒")
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
				if not SecureData.IsKeyVerified then getgenv().AutoSellRunning = false; break end
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
UI.Input(TabFish, "Wait Time (detik)", "Jeda antara cast & ambil ikan.", tostring(getgenv().UbeyConfig.WaitTime), "4.0", function(text)
	local val = tonumber(text)
	if val then
		getgenv().UbeyConfig.WaitTime = val
		SaveConfig()
	end
end)
UI.Input(TabFish, "Loop Delay (detik)", "Jeda antar loop fishing.", tostring(getgenv().UbeyConfig.LoopDelay), "0.1", function(text)
	local val = tonumber(text)
	if val then
		getgenv().UbeyConfig.LoopDelay = val
		SaveConfig()
	end
end)

-- SUMMIT TAB
UI.Section(TabSummit, "AUTO SUMMIT")
UI.Toggle(TabSummit, "Auto Climb Summit", "Otomatis mendaki 31 waypoint + bypass timer.", false, function(v)
	getgenv().AutoSummitRunning = v
end)

-- DAILY TAB
UI.Section(TabDaily, "AUTO DAILY LOGIN")
UI.Toggle(TabDaily, "Auto Claim Daily", "Klaim otomatis hadiah login harian.", false, function(v)
	getgenv().AutoDailyRunning = v
end)

-- COOKING TAB
-- ---------- LANGKAH 1: PILIH IKAN YANG AKAN DIGILING ----------
UI.Section(TabCook, "LANGKAH 1 — PILIH IKAN UNTUK DIGILING")
for _, R in ipairs(RarityList) do
	UI.Toggle(TabCook, "Giling " .. R, "Ikan " .. R .. " ikut digiling.", CookCfg.GrindRarity[R:lower()] == true, function(v)
		CookCfg.GrindRarity[R:lower()] = v or nil
	end)
end
UI.Input(TabCook, "Maks Ikan Sekali Giling", "Batas jumlah ikan per klik Giling.", CookCfg.GrindLimit, "6", function(t)
	local v = tonumber(t); if v and v >= 1 then CookCfg.GrindLimit = math.floor(v) end
end)
UI.Input(TabCook, "Slot Giling", "Samakan dengan upgrade slot giling kamu (awal 10).", CookCfg.GrindSlots, "10", function(t)
	local v = tonumber(t); if v and v >= 1 then CookCfg.GrindSlots = math.floor(v) end
end)

-- ---------- LANGKAH 2: PILIH RESEP YANG AKAN DIMASAK ----------
UI.Section(TabCook, "LANGKAH 2 — PILIH RESEP YANG DIMASAK")
local RarityPicker, RecipePicker
RarityPicker = UI.Picker(TabCook, "Rarity Masak / Daging",
	function()
		local o = {}
		for _, R in ipairs(RarityList) do table.insert(o, { label = R, value = R }) end
		return o
	end,
	function() return CurrentMenu().Rarity end,
	function(R)
		local list = MenusOfRarity(R)
		if #list > 0 then CookCfg.Index = list[1] end
		RarityPicker.Refresh()
		RecipePicker.Refresh()
	end,
	function() return "Pakai Daging " .. CurrentMenu().Rarity .. " (1 daging = 1 porsi)" end
)
RecipePicker = UI.Picker(TabCook, "Resep",
	function()
		local o = {}
		for _, idx in ipairs(MenusOfRarity(CurrentMenu().Rarity)) do
			local m = CookData.Menus[idx]
			table.insert(o, { label = m.Name, value = idx })
		end
		return o
	end,
	function() return CookCfg.Index end,
	function(idx)
		CookCfg.Index = idx
		RecipePicker.Refresh()
	end,
	function() return "Bahan: " .. IngredientText(CurrentMenu().Id) .. " /porsi" end
)
UI.Input(TabCook, "Jumlah Porsi", "Porsi sekali masak (= jumlah daging yang dipakai).", CookCfg.Amount, "6", function(t)
	local v = tonumber(t); if v and v >= 1 then CookCfg.Amount = math.floor(v) end
end)
UI.Input(TabCook, "Kapasitas Beli", "Samakan dengan upgrade kapasitas toko kamu (awal 15).", CookCfg.BuyCap, "15", function(t)
	local v = tonumber(t); if v and v >= 1 then CookCfg.BuyCap = math.floor(v) end
end)

-- ---------- CEK KESIAPAN: STATUS STASIUN ----------
UI.Section(TabCook, "CEK KESIAPAN — STATUS STASIUN")
local StationStatusCard = Card(TabCook, 96)
local StationStatusText = Label(
	StationStatusCard,
	"Tekan tombol 'Cek Status Stasiun' untuk memeriksa.",
	11, C.sub, Enum.Font.Gotham,
	UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 1, -16)
)
StationStatusText.TextWrapped = true
local function RefreshStationStatus()
	local gilingFound = FindStation("giling") ~= nil
	local tokoFound = FindStation("toko bahan") ~= nil
	local resepFound = FindStation("resep") ~= nil
	StationStatusText.Text = string.format(
		"Stasiun Giling: %s\nStasiun Toko Bahan: %s\nStasiun Resep: %s",
		gilingFound and "Ditemukan ✓" or "Tidak Ditemukan ✗ (dekati sekali secara manual dulu)",
		tokoFound and "Ditemukan ✓" or "Tidak Ditemukan ✗ (dekati sekali secara manual dulu)",
		resepFound and "Ditemukan ✓" or "Tidak Ditemukan ✗ (dekati sekali secara manual dulu)"
	)
end
UI.Button(TabCook, "Cek Status Stasiun", "Pastikan ketiga stasiun ✓ sebelum pakai fitur Auto.", "Cek", function()
	RefreshStationStatus()
end)

-- ---------- PREVIEW HASIL MASAK ----------
UI.Section(TabCook, "PREVIEW HASIL MASAK")
local PreviewCard = Card(TabCook, 190)
local PreviewText = Label(
	PreviewCard,
	"Giling dulu, lalu tekan salah satu tombol di bawah.",
	11, C.sub, Enum.Font.Gotham,
	UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 1, -16)
)
PreviewText.TextWrapped = true

local function RenderPreviewMasak()
	local menu = CurrentMenu()
	local rarityLower = tostring(menu.Rarity):lower()
	local sessionMeat = LastGrindCounts[rarityLower] or 0
	local target = tonumber(CookCfg.Amount) or 6
	local canCookNow = math.min(sessionMeat, target)

	local liveLines = "Belum dicek — tekan 'Cek Inventaris (Live)'."
	if LastInventorySnapshot then
		liveLines = string.format(
			"Ikan belum digiling: %d\nTotal Daging (semua rarity): %d\nMakanan sudah jadi: %d",
			LastInventorySnapshot.FishCount or 0,
			LastInventorySnapshot.MeatCount or 0,
			LastInventorySnapshot.FoodCount or 0
		)
	end

	PreviewText.Text = string.format(
		"Resep dipilih: %s (%s)\n\n[DARI AKUN - LIVE]\n%s\n\n[SESI INI - ESTIMASI GILING]\nDaging %s siap pakai: %d\nBisa langsung dimasak: %d dari target %d porsi",
		menu.Name, menu.Rarity, liveLines, menu.Rarity, sessionMeat, canCookNow, target
	)
end

UI.Button(TabCook, "Refresh Preview (Cepat)", "Update dari hasil giling sesi ini, tanpa cek server.", "Refresh", function()
	RenderPreviewMasak()
end)
UI.Button(TabCook, "Cek Inventaris (Live)", "Ambil data asli dari akun: ikan, daging, dan makanan.", "Cek", function(btn)
	btn.Text = "..."
	local data = GetInventorySnapshot()
	if data then
		LastInventorySnapshot = data
		RenderPreviewMasak()
		btn.Text = "Cek"
	else
		btn.Text = "Gagal"
		task.wait(1.5)
		btn.Text = "Cek"
	end
end)

-- ---------- LANGKAH 3: JALANKAN MANUAL (urut sesuai proses sebenarnya) ----------
UI.Section(TabCook, "LANGKAH 3 — JALANKAN MANUAL")
UI.Button(TabCook, "1. Giling Ikan", "Giling ikan sesuai rarity yang dipilih di Langkah 1.", "Giling", function(btn)
	btn.Text = "..."
	local n = GrindManual()
	btn.Text = n .. " ikan"
	RenderPreviewMasak()
	task.wait(2)
	btn.Text = "Giling"
end)
UI.Button(TabCook, "2. Beli Bahan", "Beli bahan sesuai resep & porsi di Langkah 2.", "Beli", function(btn)
	btn.Text = "..."
	BuyManual()
	btn.Text = "Selesai"
	task.wait(2)
	btn.Text = "Beli"
end)
UI.Button(TabCook, "3. Masak Sekarang", "Beli ulang bahan lalu langsung masak.", "Masak", function(btn)
	btn.Text = "Memasak..."
	CookManual()
	btn.Text = "Masak"
end)

-- ---------- LANGKAH 4: OTOMATIS ----------
UI.Section(TabCook, "LANGKAH 4 — OTOMATIS (ULANGI SENDIRI)")
UI.Toggle(TabCook, "Auto Giling + Masak", "Mengulang Giling → Masak terus-menerus sesuai jeda di bawah.", false, function(v)
	getgenv().AutoCookPipeline = v
end)
UI.Input(TabCook, "Jeda Siklus (detik)", "Jeda antar satu putaran Auto Giling + Masak.", CookCfg.Interval, "10", function(t)
	local v = tonumber(t); if v then CookCfg.Interval = v end
end)

-- ---------- AUTO JUAL MAKANAN ----------
UI.Section(TabCook, "AUTO JUAL MAKANAN", C.good)
local SellModePicker = UI.Picker(TabCook, "Jual Untuk",
	function()
		return {
			{ label = "Koin", value = "Coins" },
			{ label = "Diamond (Token)", value = "Token" },
		}
	end,
	function() return getgenv().UbeyConfig.SellFoodMode end,
	function(mode)
		getgenv().UbeyConfig.SellFoodMode = mode
		SaveConfig()
		SellModePicker.Refresh()
	end,
	function() return "Semua makanan jadi akan dijual dengan mode ini." end
)
UI.Toggle(TabCook, "Auto Jual Makanan", "Jual semua makanan jadi otomatis per interval.", false, function(v)
	getgenv().AutoSellFoodRunning = v
end)
UI.Input(TabCook, "Jeda Jual (Menit)", "Interval auto jual makanan dalam menit.", getgenv().UbeyConfig.SellFoodInterval, "5", function(t)
	local val = tonumber(t)
	if val and val > 0 then
		getgenv().UbeyConfig.SellFoodInterval = tostring(val)
		SaveConfig()
	end
end)
UI.Button(TabCook, "Jual Sekarang (Manual)", "Jual semua makanan jadi sesuai mode yang dipilih di atas.", "Jual", function(btn)
	btn.Text = "..."
	local mode = (getgenv().UbeyConfig.SellFoodMode == "Token") and "Token" or "Coins"
	local ok = SellFoodRemote(mode)
	btn.Text = ok and "Terjual ✓" or "Gagal"
	task.wait(1.5)
	btn.Text = "Jual"
end)

-- ---------- PENGATURAN LANJUTAN (jarang dipakai, dikumpulkan di bawah) ----------
UI.Section(TabCook, "PENGATURAN LANJUTAN", C.warn)
UI.Toggle(TabCook, "Trigger Prompt", "Aktifkan HANYA jika giling/masak gagal: tekan tombol E stasiun otomatis.", false, function(v)
	CookCfg.FirePrompt = v
end)
UI.Button(TabCook, "Upgrade Kapasitas Toko", "+5 kapasitas beli, biaya 1.000.000 koin.", "Upgrade", function()
	local r = CookRemote("TokoEvents", "TokoUpgrade")
	if r then
		local ok, res = pcall(function() return r:InvokeServer() end)
		print("[TokoUpgrade]", ok, res)
	end
end, C.bad)
UI.Button(TabCook, "Upgrade Slot Giling", "+5 slot giling, biaya 25 juta (belum teruji).", "Upgrade", function()
	local r = CookRemote("CookingSystem", "GrindUpgrade")
	if r then
		local ok, res = pcall(function() return r:InvokeServer() end)
		print("[GrindUpgrade]", ok, res)
	end
end, C.bad)

-- LUCK TAB
UI.Section(TabLuck, "LUCK GENERATOR")
UI.Toggle(TabLuck, "Auto Beli Luck Generator", "Beli ulang otomatis setiap kali durasinya habis.", false, function(v)
	getgenv().AutoLuckRunning = v
end)
UI.Input(TabLuck, "Interval Beli Ulang (Menit)", "Samakan dengan durasi Luck Generator (biasanya 15 menit).", getgenv().UbeyConfig.LuckInterval, "15", function(t)
	local val = tonumber(t)
	if val and val > 0 then
		getgenv().UbeyConfig.LuckInterval = tostring(val)
		SaveConfig()
	end
end)
UI.Input(TabLuck, "Tipe Generator (ID)", "ID tier Luck Generator yang dibeli (default 1).", getgenv().UbeyConfig.LuckTier, "1", function(t)
	local val = tonumber(t)
	if val then
		getgenv().UbeyConfig.LuckTier = tostring(math.floor(val))
		SaveConfig()
	end
end)
UI.Button(TabLuck, "Beli Sekarang (Manual)", "Beli Luck Generator satu kali.", "Beli", function(btn)
	btn.Text = "..."
	local ok = BuyLuckGenerator(getgenv().UbeyConfig.LuckTier)
	btn.Text = ok and "Terbeli ✓" or "Gagal"
	task.wait(1.5)
	btn.Text = "Beli"
end)

-- SHOP TAB (Bean / Pet / Rod)
-- Daftar, gambar, dan harga diambil LANGSUNG dari GUI toko asli game (PetShopGui /
-- RodShopGui) saat tab ini dibuka, jadi otomatis akurat tanpa perlu di-update manual
-- kalau game menambah item baru. Kalau daftar kosong, berarti GUI toko itu belum
-- pernah termuat -- buka toko itu sekali secara manual di game, lalu tekan Refresh.

local function BuildShopItemCard(container, item, buyFn)
	local card = Card(container, 60)
	local hasImage = item.Image ~= nil and item.Image ~= ""
	if hasImage then
		local icon = New("ImageLabel", {
			Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 8, 0.5, -22),
			BackgroundColor3 = C.bg, Image = item.Image, ScaleType = Enum.ScaleType.Fit
		}, card)
		Round(icon, 8)
		New("UIStroke", {Color = C.line, Thickness = 1}, icon)
	end
	local textX = hasImage and 60 or 12
	Label(card, item.Name or "???", 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, textX, 0, 8), UDim2.new(1, -textX - 110, 0, 18))
	if item.Price then
		Label(card, "Harga: " .. tostring(item.Price), 11, C.sub, Enum.Font.Gotham, UDim2.new(0, textX, 0, 27), UDim2.new(1, -textX - 110, 0, 18))
	end
	local buyBtn = New("TextButton", {
		Size = UDim2.new(0, 90, 0, 30), Position = UDim2.new(1, -100, 0.5, -15),
		BackgroundColor3 = C.accent, Text = "Beli", TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 12
	}, card)
	Round(buyBtn, 8)
	buyBtn.MouseButton1Click:Connect(function()
		if not SecureData.IsKeyVerified then return end
		task.spawn(buyFn, item, buyBtn)
	end)
end

local function CreateShopSection(page, sectionTitle, scanFn, buyFn)
	UI.Section(page, sectionTitle)
	local container = New("Frame", {
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, page)
	New("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, container)

	local function Rebuild()
		for _, ch in ipairs(container:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
		local items = scanFn()
		if #items == 0 then
			local card = Card(container, 54)
			local lbl = Label(card, "Belum ada data. Buka toko ini sekali secara manual di game, lalu tekan Refresh.", 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 1, -16))
			lbl.TextWrapped = true
		else
			for _, item in ipairs(items) do
				BuildShopItemCard(container, item, buyFn)
			end
		end
	end

	UI.Button(page, "Refresh Daftar", "Ambil ulang daftar, harga, dan gambar terbaru dari toko.", "Refresh", function()
		Rebuild()
	end)

	Rebuild()
end

local function BuyBean(item, btn)
	btn.Text = "..."
	local ok = BuyBeanRemote(item.Id)
	btn.Text = ok and "Terbeli ✓" or "Gagal"
	task.wait(1.5)
	btn.Text = "Beli"
end

local function BuyPet(item, btn)
	if item.OwnedLabel and item.OwnedLabel.Text ~= "" then
		btn.Text = "Sudah Dimiliki"
		task.wait(1.5)
		btn.Text = "Beli"
		return
	end
	btn.Text = "..."
	local ok = BuyPetRemote(item.Id)
	btn.Text = ok and "Terbeli ✓" or "Gagal"
	task.wait(1.5)
	btn.Text = "Beli"
end

local function BuyRod(item, btn)
	if item.OwnedLabel and item.OwnedLabel.Text ~= "" then
		btn.Text = "Sudah Dimiliki"
		task.wait(1.5)
		btn.Text = "Beli"
		return
	end
	btn.Text = "..."
	local ok = BuyRodRemote(item.Id)
	btn.Text = ok and "Terbeli ✓" or "Gagal"
	task.wait(1.5)
	btn.Text = "Beli"
end

CreateShopSection(TabShop, "BEAN — PILIH & BELI", ScanBeanShop, BuyBean)
CreateShopSection(TabShop, "PET — PILIH & BELI", ScanPetShop, BuyPet)
CreateShopSection(TabShop, "ROD — PILIH & BELI", ScanRodShop, BuyRod)

-- SETTINGS TAB
UI.Section(TabSettings, "ANTI-AFK")
UI.Toggle(TabSettings, "Anti-AFK", "Mencegah akun ter-kick otomatis karena dianggap idle terlalu lama.", false, function(v)
	getgenv().AntiAFKRunning = v
end)

LocalPlayer.Idled:Connect(function()
	if getgenv().AntiAFKRunning then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0, 0))
		end)
	end
end)

UI.Section(TabSettings, "UTILITAS")
local isAntiLagActive = false
UI.Button(TabSettings, "Anti-Lag", "Matikan efek berat untuk performa.", "Aktifkan", function(btn)
	isAntiLagActive = not isAntiLagActive
	if isAntiLagActive then
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			for _, v in ipairs(Lighting:GetDescendants()) do
				if v:IsA("PostEffect") or v:IsA("Atmosphere") then
					v.Enabled = false
				end
			end
			Workspace.Terrain.WaterWaveSize = 0
			Workspace.Terrain.WaterWaveSpeed = 0
		end)
		btn.Text = "Matikan"
		btn.BackgroundColor3 = C.bad
	else
		pcall(function()
			Lighting.GlobalShadows = true
			Lighting.FogEnd = 100000
			for _, v in ipairs(Lighting:GetDescendants()) do
				if v:IsA("PostEffect") or v:IsA("Atmosphere") then
					v.Enabled = true
				end
			end
		end)
		btn.Text = "Aktifkan"
		btn.BackgroundColor3 = C.accent
	end
end)

-- CREDITS TAB
UI.Section(TabCredits, "CREDITS")
local credCard = New("Frame", {Size = UDim2.new(1, -4, 0, 84), BackgroundColor3 = C.card}, TabCredits)
Round(credCard, 10)
New("UIStroke", {Color = C.line, Thickness = 1}, credCard)
Label(credCard, "UBEY HUB", 16, C.accent, Enum.Font.GothamBold, UDim2.new(0, 0, 0, 14), UDim2.new(1, 0, 0, 22), Enum.TextXAlignment.Center)
Label(credCard, "Created by UBEY", 12, C.text, Enum.Font.Gotham, UDim2.new(0, 0, 0, 38), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Center)

UI.Button(TabCredits, "Discord Link", "Salin link discord ke clipboard.", "Salin", function(btn)
	pcall(function()
		if setclipboard then
			setclipboard("https://" .. HUB_DISCORD)
			btn.Text = "Tersalin!"
			task.wait(2)
			btn.Text = "Salin"
		end
	end)
end, Color3.fromRGB(88, 101, 242))

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
	if not SecureData.IsKeyVerified then
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

