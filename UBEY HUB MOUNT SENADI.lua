--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.9) ~  Much Love, Ferib 

]]--

local HttpService = game:GetService("HttpService");
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local CoreGui = game:GetService("CoreGui");
local UIS = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local TeleportService = game:GetService("TeleportService");
local Stats = game:GetService("Stats");
local Lighting = game:GetService("Lighting");
local RbxAnalyticsService = game:GetService("RbxAnalyticsService");
local Workspace = game:GetService("Workspace");
local GuiService = game:GetService("GuiService");
local LocalPlayer = Players.LocalPlayer;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local HUB_TITLE = "UBEY HUB";
local HUB_SUBTITLE = "PREMIUM";
local HUB_DISCORD = "discord.gg/YXuYeEpnXE";
local LOGO_ASSET = "rbxassetid://90770802417381";
local WIN_W, WIN_H = 580, 360;
local CONFIG_FILE = "UbeyHub_Config.json";
local KEY_FILE = "UbeyHub_SavedKey.txt";
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq.";
local SUPABASE_ANON_KEY = "sb_publishable_rMWL7Qrjw9iG0c29vGZ0bw_O3swXT6n";
local SecureData = setmetatable({}, {__index=function(t, k)
	if (k == "IsKeyVerified") then
		return rawget(t, "_verified");
	end
end,__newindex=function(t, k, v)
	if (k == "IsKeyVerified") then
		rawset(t, "_verified", v);
	end
end});
SecureData.IsKeyVerified = false;
getgenv().UbeyConfig = {WaitTime=4,LoopDelay=0.1,AutoSellTimer="5"};
local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().UbeyConfig));
		end
	end);
end
local function LoadConfig()
	pcall(function()
		if (readfile and isfile and isfile(CONFIG_FILE)) then
			local FlatIdent_2953F = 0;
			local data;
			while true do
				if (FlatIdent_2953F == 0) then
					data = HttpService:JSONDecode(readfile(CONFIG_FILE));
					if (type(data) == "table") then
						for k, v in pairs(data) do
							if (getgenv().UbeyConfig[k] ~= nil) then
								getgenv().UbeyConfig[k] = v;
							end
						end
					end
					break;
				end
			end
		end
	end);
end
LoadConfig();
getgenv().AutoFishingRunning = false;
getgenv().AutoSellRunning = false;
getgenv().AutoSummitRunning = false;
getgenv().AutoDailyRunning = false;
getgenv().AutoCookPipeline = false;
getgenv().TotalFishCaught = 0;
getgenv().TotalSummitRun = 0;
getgenv().SessionStartTime = os.time();
pcall(function()
	GuiService:SetGameplayPausedNotificationEnabled(false);
end);
local function GetDeviceHWID()
	local FlatIdent_2FBEB = 0;
	local hwid;
	while true do
		if (FlatIdent_2FBEB == 1) then
			return tostring(hwid or ("UNKNOWN_DEVICE_" .. tostring(LocalPlayer.UserId)));
		end
		if (FlatIdent_2FBEB == 0) then
			hwid = nil;
			pcall(function()
				if gethwid then
					hwid = gethwid();
				elseif RbxAnalyticsService then
					hwid = RbxAnalyticsService:GetClientId();
				end
			end);
			FlatIdent_2FBEB = 1;
		end
	end
end
local CurrentHWID = GetDeviceHWID();
local function GetEquippedRodName()
	local FlatIdent_63487 = 0;
	local char;
	while true do
		if (FlatIdent_63487 == 0) then
			char = LocalPlayer.Character;
			if char then
				local tool = char:FindFirstChildOfClass("Tool");
				if tool then
					return tool.Name;
				end
			end
			FlatIdent_63487 = 1;
		end
		if (FlatIdent_63487 == 1) then
			return nil;
		end
	end
end
local function TriggerSellAll()
	pcall(function()
		local FlatIdent_8199B = 0;
		local fs;
		local sellRemote;
		while true do
			if (FlatIdent_8199B == 0) then
				fs = ReplicatedStorage:FindFirstChild("FishingSystem");
				sellRemote = fs and fs:FindFirstChild("SellFish");
				FlatIdent_8199B = 1;
			end
			if (1 == FlatIdent_8199B) then
				if sellRemote then
					sellRemote:FireServer();
				end
				break;
			end
		end
	end);
end
task.spawn(function()
	local FlatIdent_5ED46 = 0;
	local FS;
	local CastReplication;
	local CleanupCast;
	local FishGiver;
	while true do
		if (2 == FlatIdent_5ED46) then
			FishGiver = FS:WaitForChild("FishGiver");
			while true do
				if getgenv().AutoFishingRunning then
					if not SecureData.IsKeyVerified then
						getgenv().AutoFishingRunning = false;
						break;
					end
					pcall(function()
						local FlatIdent_7F35E = 0;
						local char;
						local root;
						local currentRod;
						while true do
							if (1 == FlatIdent_7F35E) then
								currentRod = GetEquippedRodName();
								if (root and currentRod) then
									local pPos = root.Position;
									local castVec = pPos + (root.CFrame.LookVector * 15);
									local hookVec = castVec - Vector3.new(0, 8, 0);
									CleanupCast:FireServer();
									task.wait(0.05);
									CastReplication:FireServer(castVec, Vector3.new(0, 5, 24), currentRod, 90);
									task.wait(tonumber(getgenv().UbeyConfig.WaitTime) or 4);
									FishGiver:FireServer({hookPosition=hookVec,powerPercent=0});
									task.wait(0.1);
									CleanupCast:FireServer();
									getgenv().TotalFishCaught = getgenv().TotalFishCaught + 1;
								end
								break;
							end
							if (FlatIdent_7F35E == 0) then
								char = LocalPlayer.Character;
								root = char and char:FindFirstChild("HumanoidRootPart");
								FlatIdent_7F35E = 1;
							end
						end
					end);
					task.wait(tonumber(getgenv().UbeyConfig.LoopDelay) or 0.1);
				else
					task.wait(0.5);
				end
			end
			break;
		end
		if (FlatIdent_5ED46 == 0) then
			FS = ReplicatedStorage:WaitForChild("FishingSystem", 10);
			if not FS then
				return;
			end
			FlatIdent_5ED46 = 1;
		end
		if (FlatIdent_5ED46 == 1) then
			CastReplication = FS:WaitForChild("CastReplication");
			CleanupCast = FS:WaitForChild("CleanupCast");
			FlatIdent_5ED46 = 2;
		end
	end
end);
task.spawn(function()
	local FlatIdent_455BF = 0;
	while true do
		if (FlatIdent_455BF == 0) then
			task.wait(5);
			while true do
				if getgenv().AutoDailyRunning then
					if not SecureData.IsKeyVerified then
						getgenv().AutoDailyRunning = false;
						break;
					end
					pcall(function()
						local DailyReward = ReplicatedStorage:FindFirstChild("DailyReward");
						if DailyReward then
							DailyReward:InvokeServer("claim");
						end
					end);
				end
				task.wait(30);
			end
			break;
		end
	end
end);
local CookData = {Menus={},Ingredients={},GrinderTime={},CookTime={}};
pcall(function()
	local FlatIdent_8F59B = 0;
	local cfg;
	while true do
		if (FlatIdent_8F59B == 1) then
			CookData.Ingredients = cfg.MenuIngredients or {};
			CookData.GrinderTime = cfg.GrinderTime or {};
			FlatIdent_8F59B = 2;
		end
		if (FlatIdent_8F59B == 0) then
			cfg = require(ReplicatedStorage.CookingSystem.FishCookingConfig);
			CookData.Menus = cfg.Menus or {};
			FlatIdent_8F59B = 1;
		end
		if (FlatIdent_8F59B == 2) then
			CookData.CookTime = cfg.CookTime or {};
			break;
		end
	end
end);
if (#CookData.Menus == 0) then
	CookData.Menus = {{Id="ikan_bakar",Rarity="Common",Name="Ikan Bakar"}};
	CookData.Ingredients = {ikan_bakar={["Bumbu Dapur"]=1}};
	CookData.GrinderTime = {Common=2};
	CookData.CookTime = {Common=2};
end
local CookCfg = {Index=1,Amount=6,BuyCap=15,GrindSlots=10,Interval=10,FirePrompt=false,GrindRarity={common=true},GrindLimit=6};
local function CookRemote(folder, name)
	local FlatIdent_7A75F = 0;
	local f;
	while true do
		if (FlatIdent_7A75F == 0) then
			f = ReplicatedStorage:FindFirstChild(folder);
			return f and f:FindFirstChild(name);
		end
	end
end
local function CurrentMenu()
	return CookData.Menus[CookCfg.Index] or CookData.Menus[1];
end
local function IngredientText(menuId)
	local parts = {};
	for name, qty in pairs(CookData.Ingredients[menuId] or {}) do
		table.insert(parts, name .. " x" .. qty);
	end
	table.sort(parts);
	return table.concat(parts, ", ");
end
local StationCache = {};
local function GetHRP()
	local FlatIdent_1B1BA = 0;
	local char;
	while true do
		if (FlatIdent_1B1BA == 0) then
			char = LocalPlayer.Character;
			return char and char:FindFirstChild("HumanoidRootPart");
		end
	end
end
local function PromptPos(p)
	local FlatIdent_380E8 = 0;
	local par;
	while true do
		if (FlatIdent_380E8 == 2) then
			if par:IsA("Model") then
				return par:GetPivot().Position;
			end
			return nil;
		end
		if (FlatIdent_380E8 == 0) then
			par = p.Parent;
			if not par then
				return nil;
			end
			FlatIdent_380E8 = 1;
		end
		if (FlatIdent_380E8 == 1) then
			if par:IsA("BasePart") then
				return par.Position;
			end
			if par:IsA("Attachment") then
				return par.WorldPosition;
			end
			FlatIdent_380E8 = 2;
		end
	end
end
local function FindStation(key)
	local cached = StationCache[key];
	if (cached and cached.Parent) then
		return cached;
	end
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local t = (d.ActionText .. " " .. d.ObjectText):lower();
			if t:find(key, 1, true) then
				StationCache[key] = d;
				return d;
			end
		end
	end
	return nil;
end
local function GoToStation(key)
	local prompt = FindStation(key);
	local hrp = GetHRP();
	if (not prompt or not hrp) then
		return false;
	end
	local pos = PromptPos(prompt);
	if not pos then
		return false;
	end
	hrp.AssemblyLinearVelocity = Vector3.zero;
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0));
	task.wait(0.6);
	if (CookCfg.FirePrompt and fireproximityprompt) then
		local FlatIdent_39764 = 0;
		while true do
			if (FlatIdent_39764 == 0) then
				pcall(function()
					fireproximityprompt(prompt);
				end);
				task.wait(0.4);
				break;
			end
		end
	end
	return true;
end
local function RunAtStations(fn)
	local FlatIdent_494DF = 0;
	local hrp;
	local home;
	local ok;
	local err;
	while true do
		if (FlatIdent_494DF == 2) then
			hrp = GetHRP();
			if (hrp and home) then
				local FlatIdent_64E40 = 0;
				while true do
					if (FlatIdent_64E40 == 0) then
						hrp.AssemblyLinearVelocity = Vector3.zero;
						hrp.CFrame = home;
						break;
					end
				end
			end
			break;
		end
		if (FlatIdent_494DF == 1) then
			ok, err = pcall(fn);
			if not ok then
				warn("[Cooking] " .. tostring(err));
			end
			FlatIdent_494DF = 2;
		end
		if (FlatIdent_494DF == 0) then
			hrp = GetHRP();
			home = hrp and hrp.CFrame;
			FlatIdent_494DF = 1;
		end
	end
end
local function GetGrindList()
	local FlatIdent_8D1A5 = 0;
	local r;
	local ok;
	local res;
	local out;
	local collect;
	while true do
		if (4 == FlatIdent_8D1A5) then
			return out;
		end
		if (1 == FlatIdent_8D1A5) then
			ok, res = pcall(function()
				return r:InvokeServer();
			end);
			if (not ok or (type(res) ~= "table")) then
				return {};
			end
			FlatIdent_8D1A5 = 2;
		end
		if (FlatIdent_8D1A5 == 3) then
			function collect(t, depth)
				local FlatIdent_5477B = 0;
				local id;
				while true do
					if (1 == FlatIdent_5477B) then
						if id then
							local FlatIdent_7F121 = 0;
							while true do
								if (FlatIdent_7F121 == 0) then
									table.insert(out, {id=id,rarity=tostring(t.rarity or ""):lower(),name=t.name,fav=(t.isFavorited == true)});
									return;
								end
							end
						end
						for _, v in pairs(t) do
							collect(v, depth + 1);
						end
						break;
					end
					if (FlatIdent_5477B == 0) then
						if ((type(t) ~= "table") or (depth > 5)) then
							return;
						end
						id = t.uniqueId or t.uniqueID or t.UniqueId;
						FlatIdent_5477B = 1;
					end
				end
			end
			collect(res, 0);
			FlatIdent_8D1A5 = 4;
		end
		if (FlatIdent_8D1A5 == 2) then
			out = {};
			collect = nil;
			FlatIdent_8D1A5 = 3;
		end
		if (0 == FlatIdent_8D1A5) then
			r = CookRemote("CookingSystem", "GrindList");
			if not r then
				return {};
			end
			FlatIdent_8D1A5 = 1;
		end
	end
end
local function DumpGrindList()
	RunAtStations(function()
		GoToStation("giling");
		local r = CookRemote("CookingSystem", "GrindList");
		if not r then
			return;
		end
		local ok, res = pcall(function()
			return r:InvokeServer();
		end);
		print("[GrindList] ok =", ok, "type =", typeof(res));
	end);
end
local RarityList = {"Common","Uncommon","Rare","Epic","Legendary","Unknown","Forgotten"};
local function MenusOfRarity(r)
	local FlatIdent_206F8 = 0;
	local out;
	while true do
		if (FlatIdent_206F8 == 1) then
			return out;
		end
		if (0 == FlatIdent_206F8) then
			out = {};
			for i, m in ipairs(CookData.Menus) do
				if (m.Rarity == r) then
					table.insert(out, i);
				end
			end
			FlatIdent_206F8 = 1;
		end
	end
end
local function GrinderTimeOf(rarityLower)
	for _, R in ipairs(RarityList) do
		if (R:lower() == rarityLower) then
			return CookData.GrinderTime[R] or 2;
		end
	end
	return 2;
end
local function GrindNow()
	local r = CookRemote("CookingSystem", "GrindRequest");
	if not r then
		return 0, {};
	end
	if not GoToStation("giling") then
		return 0, {};
	end
	local limit = math.max(1, tonumber(CookCfg.GrindLimit) or 6);
	local ids, counts = {}, {};
	for _, it in ipairs(GetGrindList()) do
		if (it.id and not it.fav and CookCfg.GrindRarity[it.rarity]) then
			table.insert(ids, it.id);
			counts[it.rarity] = (counts[it.rarity] or 0) + 1;
			if (#ids >= limit) then
				break;
			end
		end
	end
	local slots = math.max(1, tonumber(CookCfg.GrindSlots) or 10);
	for i = 1, #ids, slots do
		local FlatIdent_4D434 = 0;
		local chunk;
		while true do
			if (FlatIdent_4D434 == 0) then
				chunk = {};
				for j = i, math.min((i + slots) - 1, #ids) do
					table.insert(chunk, ids[j]);
				end
				FlatIdent_4D434 = 1;
			end
			if (FlatIdent_4D434 == 1) then
				pcall(function()
					r:FireServer(chunk);
				end);
				task.wait(1);
				break;
			end
		end
	end
	if (#ids > 0) then
		local t = 1;
		for rar, c in pairs(counts) do
			t = t + (GrinderTimeOf(rar) * c);
		end
		task.wait(t);
	end
	return #ids, counts;
end
local function BuyNow(item, total)
	local FlatIdent_61800 = 0;
	local r;
	local left;
	local cap;
	while true do
		if (FlatIdent_61800 == 2) then
			while left > 0 do
				local FlatIdent_581C8 = 0;
				local n;
				while true do
					if (FlatIdent_581C8 == 1) then
						left = left - n;
						task.wait(0.4);
						break;
					end
					if (FlatIdent_581C8 == 0) then
						n = math.min(left, cap);
						pcall(function()
							r:InvokeServer(item, n);
						end);
						FlatIdent_581C8 = 1;
					end
				end
			end
			break;
		end
		if (FlatIdent_61800 == 1) then
			left = total;
			cap = math.max(1, tonumber(CookCfg.BuyCap) or 15);
			FlatIdent_61800 = 2;
		end
		if (FlatIdent_61800 == 0) then
			r = CookRemote("TokoEvents", "TokoBuy");
			if not r then
				return;
			end
			FlatIdent_61800 = 1;
		end
	end
end
local function BuyForRecipe(amt)
	local FlatIdent_32B97 = 0;
	local menu;
	while true do
		if (FlatIdent_32B97 == 0) then
			if not GoToStation("toko bahan") then
				return;
			end
			menu = CurrentMenu();
			FlatIdent_32B97 = 1;
		end
		if (FlatIdent_32B97 == 1) then
			amt = math.max(1, tonumber(amt) or tonumber(CookCfg.Amount) or 6);
			for name, qty in pairs(CookData.Ingredients[menu.Id] or {}) do
				BuyNow(name, qty * amt);
			end
			break;
		end
	end
end
local function CookNow(amt)
	local FlatIdent_580CB = 0;
	local r;
	local menu;
	while true do
		if (FlatIdent_580CB == 3) then
			pcall(function()
				r:FireServer(menu.Id, amt);
			end);
			task.wait(((CookData.CookTime[menu.Rarity] or 2) * amt) + 2);
			break;
		end
		if (FlatIdent_580CB == 1) then
			menu = CurrentMenu();
			amt = math.max(1, tonumber(amt) or tonumber(CookCfg.Amount) or 6);
			FlatIdent_580CB = 2;
		end
		if (FlatIdent_580CB == 2) then
			BuyForRecipe(amt);
			if not GoToStation("resep") then
				return;
			end
			FlatIdent_580CB = 3;
		end
		if (FlatIdent_580CB == 0) then
			r = CookRemote("CookingSystem", "CookingCook");
			if not r then
				return;
			end
			FlatIdent_580CB = 1;
		end
	end
end
local function GrindManual()
	local FlatIdent_77172 = 0;
	local cnt;
	while true do
		if (FlatIdent_77172 == 1) then
			return cnt;
		end
		if (FlatIdent_77172 == 0) then
			cnt = 0;
			RunAtStations(function()
				cnt = GrindNow();
			end);
			FlatIdent_77172 = 1;
		end
	end
end
local function BuyManual()
	RunAtStations(function()
		BuyForRecipe();
	end);
end
local function CookManual()
	RunAtStations(function()
		CookNow();
	end);
end
task.spawn(function()
	while true do
		if getgenv().AutoCookPipeline then
			if not SecureData.IsKeyVerified then
				getgenv().AutoCookPipeline = false;
				break;
			end
			RunAtStations(function()
				local FlatIdent_634AF = 0;
				local _;
				local counts;
				local have;
				while true do
					if (0 == FlatIdent_634AF) then
						_, counts = GrindNow();
						have = counts[tostring(CurrentMenu().Rarity):lower()] or 0;
						FlatIdent_634AF = 1;
					end
					if (FlatIdent_634AF == 1) then
						if ((have > 0) and getgenv().AutoCookPipeline and SecureData.IsKeyVerified) then
							CookNow(math.min(have, tonumber(CookCfg.Amount) or 6));
						end
						break;
					end
				end
			end);
			task.wait(tonumber(CookCfg.Interval) or 10);
		else
			task.wait(0.5);
		end
	end
end);
local waypoints = {Vector3.new(-4.2, 16.3, 886.5),Vector3.new(-176.9, 79.6, 1907.9),Vector3.new(0.5, 131.2, 2793.1),Vector3.new(-1107.6, 362.1, 3266.3),Vector3.new(-1236, 504.5, 3828.8),Vector3.new(-1754.2, 730.9, 4525.4),Vector3.new(-1814.4, 746.4, 5568.2),Vector3.new(-2882.8, 740.9, 6129.6),Vector3.new(-3485.3, 740.2, 6524.1),Vector3.new(-3071.4, 794.4, 7228.8),Vector3.new(-2916.1, 835.4, 7965.9),Vector3.new(-2932, 849.1, 8838.7),Vector3.new(-3510.9, 1021.1, 9350.6),Vector3.new(-3472.3, 1021.8, 10147.4),Vector3.new(-3613.4, 1022.4, 10852.6),Vector3.new(-3849.1, 1048.2, 11692.4),Vector3.new(-4051.8, 1115.9, 12606.3),Vector3.new(-3995.3, 1197.4, 13586.2),Vector3.new(-4306.6, 1276, 14465.3),Vector3.new(-4564.7, 1295, 15327.3),Vector3.new(-4747.6, 1323.8, 16335.5),Vector3.new(-4821.9, 1366.9, 17051.8),Vector3.new(-5133.6, 1531.3, 17596.4),Vector3.new(-5339.5, 1631.6, 18276.7),Vector3.new(-5362.9, 1737.9, 19296.5),Vector3.new(-5376.3, 1761.7, 19944.1),Vector3.new(-5593.8, 1890.4, 20588.2),Vector3.new(-5700.9, 1975.2, 21045.2),Vector3.new(-6024.9, 1977.4, 21183.8),Vector3.new(-6633.9, 2048.1, 21482.6),Vector3.new(-6634.3, 2230, 22351.3)};
task.spawn(function()
	while true do
		if getgenv().AutoSummitRunning then
			if not SecureData.IsKeyVerified then
				getgenv().AutoSummitRunning = false;
				break;
			end
			pcall(function()
				local FlatIdent_6AEED = 0;
				local permisiFolder;
				local basecampFolder;
				local touchedList;
				local checkAndTouchCP;
				local tpToBasecamp;
				local safeTeleport;
				while true do
					if (FlatIdent_6AEED == 2) then
						function safeTeleport(targetPos)
							local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
							if not hrp then
								return;
							end
							pcall(function()
								LocalPlayer:RequestStreamAroundAsync(targetPos);
							end);
							hrp.CFrame = CFrame.new(targetPos);
						end
						touchedList = {};
						for _, pos in ipairs(waypoints) do
							if not getgenv().AutoSummitRunning then
								break;
							end
							safeTeleport(pos);
							local timer = 0;
							while (timer < 8) and getgenv().AutoSummitRunning do
								local FlatIdent_71EE8 = 0;
								while true do
									if (1 == FlatIdent_71EE8) then
										timer = timer + 0.5;
										break;
									end
									if (FlatIdent_71EE8 == 0) then
										checkAndTouchCP();
										task.wait(0.5);
										FlatIdent_71EE8 = 1;
									end
								end
							end
						end
						if getgenv().AutoSummitRunning then
							getgenv().TotalSummitRun = getgenv().TotalSummitRun + 1;
							task.wait(3);
							tpToBasecamp();
							task.wait(3);
						end
						break;
					end
					if (FlatIdent_6AEED == 1) then
						function checkAndTouchCP()
							if not permisiFolder then
								return;
							end
							for _, part in ipairs(permisiFolder:GetChildren()) do
								if (part:IsA("BasePart") and not touchedList[part]) then
									local FlatIdent_15A17 = 0;
									while true do
										if (FlatIdent_15A17 == 0) then
											touchedList[part] = true;
											if firetouchinterest then
												local FlatIdent_912A7 = 0;
												local hrp;
												while true do
													if (FlatIdent_912A7 == 0) then
														hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
														if hrp then
															local FlatIdent_69C4C = 0;
															while true do
																if (FlatIdent_69C4C == 0) then
																	firetouchinterest(hrp, part, 0);
																	task.wait(0.05);
																	FlatIdent_69C4C = 1;
																end
																if (1 == FlatIdent_69C4C) then
																	firetouchinterest(hrp, part, 1);
																	break;
																end
															end
														end
														break;
													end
												end
											end
											break;
										end
									end
								end
							end
						end
						tpToBasecamp = nil;
						function tpToBasecamp()
							if basecampFolder then
								local FlatIdent_8E5B4 = 0;
								local tpPart2;
								local hrp;
								while true do
									if (FlatIdent_8E5B4 == 1) then
										if (tpPart2 and hrp) then
											local FlatIdent_7063 = 0;
											while true do
												if (FlatIdent_7063 == 0) then
													hrp.CFrame = tpPart2.CFrame;
													if firetouchinterest then
														local FlatIdent_92F66 = 0;
														while true do
															if (FlatIdent_92F66 == 1) then
																firetouchinterest(hrp, tpPart2, 1);
																break;
															end
															if (FlatIdent_92F66 == 0) then
																firetouchinterest(hrp, tpPart2, 0);
																task.wait(0.1);
																FlatIdent_92F66 = 1;
															end
														end
													end
													break;
												end
											end
										end
										break;
									end
									if (FlatIdent_8E5B4 == 0) then
										tpPart2 = basecampFolder:FindFirstChild("TeleportPart2");
										hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
										FlatIdent_8E5B4 = 1;
									end
								end
							end
						end
						safeTeleport = nil;
						FlatIdent_6AEED = 2;
					end
					if (FlatIdent_6AEED == 0) then
						permisiFolder = workspace:FindFirstChild("permisi");
						basecampFolder = workspace:FindFirstChild("BASECAMP");
						touchedList = {};
						checkAndTouchCP = nil;
						FlatIdent_6AEED = 1;
					end
				end
			end);
			task.wait(1);
		else
			task.wait(0.5);
		end
	end
end);
task.spawn(function()
	pcall(function()
		CoreGui.ChildAdded:Connect(function(child)
			if ((child.Name == "ErrorPrompt") or (child.Name == "DisconnectPrompt")) then
				local FlatIdent_4E551 = 0;
				while true do
					if (FlatIdent_4E551 == 0) then
						task.wait(1);
						pcall(function()
							TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer);
						end);
						break;
					end
				end
			end
		end);
	end);
end);
pcall(function()
	local FlatIdent_10550 = 0;
	local old;
	while true do
		if (0 == FlatIdent_10550) then
			old = PlayerGui:FindFirstChild("UbeyHub");
			if old then
				old:Destroy();
			end
			break;
		end
	end
end);
local Gui = Instance.new("ScreenGui");
Gui.Name = "UbeyHub";
Gui.ResetOnSpawn = false;
Gui.DisplayOrder = 100;
Gui.Parent = PlayerGui;
local C = {bg=Color3.fromRGB(9, 12, 26),side=Color3.fromRGB(13, 17, 36),card=Color3.fromRGB(15, 21, 44),line=Color3.fromRGB(30, 42, 90),accent=Color3.fromRGB(45, 95, 255),off=Color3.fromRGB(32, 44, 105),text=Color3.fromRGB(240, 243, 255),sub=Color3.fromRGB(150, 160, 195),good=Color3.fromRGB(0, 230, 150),bad=Color3.fromRGB(255, 80, 80),warn=Color3.fromRGB(255, 200, 0)};
local function New(class, props, parent)
	local FlatIdent_6EEC8 = 0;
	local o;
	while true do
		if (0 == FlatIdent_6EEC8) then
			o = Instance.new(class);
			for k, v in pairs(props) do
				o[k] = v;
			end
			FlatIdent_6EEC8 = 1;
		end
		if (FlatIdent_6EEC8 == 1) then
			o.Parent = parent;
			return o;
		end
	end
end
local function Round(o, r)
	return New("UICorner", {CornerRadius=UDim.new(0, r or 8)}, o);
end
local function Label(parent, text, size, color, font, pos, sz, align)
	return New("TextLabel", {BackgroundTransparency=1,Text=text,TextSize=size,TextColor3=color,Font=font,Position=(pos or UDim2.new()),Size=(sz or UDim2.new(1, 0, 1, 0)),TextXAlignment=(align or Enum.TextXAlignment.Left),TextTruncate=Enum.TextTruncate.AtEnd}, parent);
end
local function MakeDraggable(obj, handle)
	local FlatIdent_2BE68 = 0;
	local dragging;
	local dragInput;
	local dragStart;
	local startPos;
	local moved;
	while true do
		if (FlatIdent_2BE68 == 2) then
			UIS.InputChanged:Connect(function(input)
				if ((input == dragInput) and dragging) then
					local d = input.Position - dragStart;
					if (d.Magnitude > 6) then
						moved = true;
					end
					obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y);
				end
			end);
			return function()
				return moved;
			end;
		end
		if (FlatIdent_2BE68 == 1) then
			handle.InputBegan:Connect(function(input)
				if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
					dragging, moved = true, false;
					dragStart, startPos = input.Position, obj.Position;
					input.Changed:Connect(function()
						if (input.UserInputState == Enum.UserInputState.End) then
							dragging = false;
						end
					end);
				end
			end);
			handle.InputChanged:Connect(function(input)
				if ((input.UserInputType == Enum.UserInputType.MouseMovement) or (input.UserInputType == Enum.UserInputType.Touch)) then
					dragInput = input;
				end
			end);
			FlatIdent_2BE68 = 2;
		end
		if (FlatIdent_2BE68 == 0) then
			handle = handle or obj;
			dragging, dragInput, dragStart, startPos, moved = nil;
			FlatIdent_2BE68 = 1;
		end
	end
end
local KeyFrame = New("Frame", {Size=UDim2.new(0, 400, 0, 240),Position=UDim2.new(0.5, -200, 0.5, -120),BackgroundColor3=C.bg,Visible=false}, Gui);
Round(KeyFrame, 14);
New("UIStroke", {Color=C.line,Thickness=1.5}, KeyFrame);
MakeDraggable(KeyFrame);
Label(KeyFrame, HUB_TITLE, 16, C.text, Enum.Font.GothamBold, UDim2.new(0, 20, 0, 12), UDim2.new(1, -40, 0, 22));
Label(KeyFrame, HUB_SUBTITLE, 10, C.warn, Enum.Font.GothamBold, UDim2.new(0, 20, 0, 32), UDim2.new(1, -40, 0, 14));
Label(KeyFrame, "Masukkan key untuk melanjutkan.", 12, C.sub, Enum.Font.Gotham, UDim2.new(0, 20, 0, 62), UDim2.new(1, -40, 0, 18));
local KeyBox = New("TextBox", {Size=UDim2.new(1, -40, 0, 40),Position=UDim2.new(0, 20, 0, 88),BackgroundColor3=C.card,PlaceholderText="Paste key di sini...",PlaceholderColor3=C.sub,Text="",TextColor3=C.text,Font=Enum.Font.Gotham,TextSize=13,ClearTextOnFocus=false}, KeyFrame);
Round(KeyBox, 10);
New("UIStroke", {Color=C.line}, KeyBox);
local SubmitKeyBtn = New("TextButton", {Size=UDim2.new(0.5, -26, 0, 38),Position=UDim2.new(0, 20, 0, 140),BackgroundColor3=C.accent,Text="Verifikasi Key",TextColor3=Color3.new(1, 1, 1),Font=Enum.Font.GothamBold,TextSize=13}, KeyFrame);
Round(SubmitKeyBtn, 10);
local GetKeyBtn = New("TextButton", {Size=UDim2.new(0.5, -26, 0, 38),Position=UDim2.new(0.5, 6, 0, 140),BackgroundColor3=Color3.fromRGB(88, 101, 242),Text="Get Key (Discord)",TextColor3=Color3.new(1, 1, 1),Font=Enum.Font.GothamBold,TextSize=13}, KeyFrame);
Round(GetKeyBtn, 10);
local StatusKey = Label(KeyFrame, "", 11, C.bad, Enum.Font.Gotham, UDim2.new(0, 20, 0, 190), UDim2.new(1, -40, 0, 22), Enum.TextXAlignment.Center);
local Main = New("Frame", {Size=UDim2.new(0, WIN_W, 0, WIN_H),Position=UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),BackgroundColor3=C.bg,Visible=false,ClipsDescendants=true}, Gui);
Round(Main, 14);
New("UIStroke", {Color=C.line,Thickness=1.5}, Main);
local Header = New("Frame", {Size=UDim2.new(1, 0, 0, 42),BackgroundTransparency=1}, Main);
MakeDraggable(Main, Header);
Label(Header, HUB_TITLE, 15, C.text, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 5), UDim2.new(0, 110, 0, 20));
Label(Header, HUB_SUBTITLE, 10, C.warn, Enum.Font.GothamBold, UDim2.new(0, 16, 0, 23), UDim2.new(0, 110, 0, 14));
local StatLabel = Label(Header, "📊 Fish: 0  |  ⛰️ Summit: 0  |  ⏱️ 00s", 11, C.accent, Enum.Font.GothamBold, UDim2.new(0, 130, 0, 0), UDim2.new(0, 260, 1, 0));
local PingLabel = Label(Header, "📡 -- ms", 11, C.good, Enum.Font.GothamBold, UDim2.new(0, 380, 0, 0), UDim2.new(1, -470, 1, 0), Enum.TextXAlignment.Right);
local MinimizeBtn = New("TextButton", {Size=UDim2.new(0, 30, 0, 30),Position=UDim2.new(1, -78, 0, 6),BackgroundTransparency=1,Text="—",TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=16}, Header);
local CloseBtn = New("TextButton", {Size=UDim2.new(0, 30, 0, 30),Position=UDim2.new(1, -42, 0, 6),BackgroundTransparency=1,Text="✕",TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=16}, Header);
local Body = New("Frame", {Size=UDim2.new(1, 0, 1, -42),Position=UDim2.new(0, 0, 0, 42),BackgroundTransparency=1}, Main);
local Sidebar = New("ScrollingFrame", {Size=UDim2.new(0, 150, 1, -10),Position=UDim2.new(0, 8, 0, 0),BackgroundTransparency=1,ScrollBarThickness=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,BorderSizePixel=0}, Body);
New("UIListLayout", {Padding=UDim.new(0, 6),SortOrder=Enum.SortOrder.LayoutOrder}, Sidebar);
New("Frame", {Size=UDim2.new(0, 2, 1, -24),Position=UDim2.new(0, 166, 0, 4),BackgroundColor3=C.accent,BorderSizePixel=0}, Body);
local Content = New("Frame", {Size=UDim2.new(1, -186, 1, 0),Position=UDim2.new(0, 178, 0, 0),BackgroundTransparency=1}, Body);
local PageTitle = Label(Content, "", 19, C.text, Enum.Font.GothamBold, UDim2.new(0, 2, 0, 0), UDim2.new(1, 0, 0, 30));
local PagesHolder = New("Frame", {Size=UDim2.new(1, 0, 1, -44),Position=UDim2.new(0, 0, 0, 38),BackgroundTransparency=1}, Content);
local isMinimized = false;
MinimizeBtn.MouseButton1Click:Connect(function()
	local FlatIdent_8BA1E = 0;
	while true do
		if (FlatIdent_8BA1E == 0) then
			isMinimized = not isMinimized;
			Body.Visible = not isMinimized;
			FlatIdent_8BA1E = 1;
		end
		if (FlatIdent_8BA1E == 1) then
			TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size=UDim2.new(0, WIN_W, 0, (isMinimized and 42) or WIN_H)}):Play();
			break;
		end
	end
end);
CloseBtn.MouseButton1Click:Connect(function()
	Main.Visible = false;
end);
task.spawn(function()
	while true do
		task.wait(2);
		if (not KeyFrame or not KeyFrame.Parent) then
			SecureData.IsKeyVerified = false;
			getgenv().AutoFishingRunning = false;
			getgenv().AutoSummitRunning = false;
			getgenv().AutoSellRunning = false;
			getgenv().AutoDailyRunning = false;
			getgenv().AutoCookPipeline = false;
			if (Main and Main.Parent) then
				Main:Destroy();
			end
			break;
		end
	end
end);
task.spawn(function()
	while true do
		local FlatIdent_B1F4 = 0;
		while true do
			if (FlatIdent_B1F4 == 0) then
				pcall(function()
					local pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue());
					PingLabel.Text = "📡 " .. pingVal .. " ms";
				end);
				task.wait(1);
				break;
			end
		end
	end
end);
task.spawn(function()
	while true do
		local FlatIdent_656E9 = 0;
		while true do
			if (FlatIdent_656E9 == 0) then
				pcall(function()
					local FlatIdent_1BA2F = 0;
					local elapsed;
					local hours;
					local mins;
					local secs;
					local timeStr;
					while true do
						if (2 == FlatIdent_1BA2F) then
							timeStr = nil;
							if (hours > 0) then
								timeStr = string.format("%02dh %02dm %02ds", hours, mins, secs);
							elseif (mins > 0) then
								timeStr = string.format("%02dm %02ds", mins, secs);
							else
								timeStr = string.format("%02ds", secs);
							end
							FlatIdent_1BA2F = 3;
						end
						if (FlatIdent_1BA2F == 3) then
							StatLabel.Text = string.format("📊 Fish: %d  |  ⛰️ Summit: %d  |  ⏱️ %s", getgenv().TotalFishCaught, getgenv().TotalSummitRun, timeStr);
							break;
						end
						if (1 == FlatIdent_1BA2F) then
							mins = math.floor((elapsed % 3600) / 60);
							secs = elapsed % 60;
							FlatIdent_1BA2F = 2;
						end
						if (FlatIdent_1BA2F == 0) then
							elapsed = os.time() - getgenv().SessionStartTime;
							hours = math.floor(elapsed / 3600);
							FlatIdent_1BA2F = 1;
						end
					end
				end);
				task.wait(1);
				break;
			end
		end
	end
end);
local function CheckUsernameInList(allowedUsersStr, currentUsername)
	local FlatIdent_90A69 = 0;
	while true do
		if (FlatIdent_90A69 == 1) then
			return false;
		end
		if (FlatIdent_90A69 == 0) then
			if (not allowedUsersStr or (allowedUsersStr == "")) then
				return false;
			end
			for name in string.gmatch(allowedUsersStr, "[^,%s]+") do
				if (string.lower(name) == string.lower(currentUsername)) then
					return true;
				end
			end
			FlatIdent_90A69 = 1;
		end
	end
end
local function ValidateKey(enteredKey, isAutoLogin)
	if (enteredKey == "") then
		if not isAutoLogin then
			local FlatIdent_92514 = 0;
			while true do
				if (FlatIdent_92514 == 0) then
					StatusKey.TextColor3 = C.bad;
					StatusKey.Text = "Masukkan Key terlebih dahulu!";
					break;
				end
			end
		end
		KeyFrame.Visible = true;
		return;
	end
	if not isAutoLogin then
		local FlatIdent_13B77 = 0;
		while true do
			if (0 == FlatIdent_13B77) then
				StatusKey.TextColor3 = C.warn;
				StatusKey.Text = "Memeriksa Validasi Akun & Key...";
				break;
			end
		end
	end
	task.spawn(function()
		local requestFunc = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request);
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({Url=(SUPABASE_URL .. HttpService:UrlEncode(enteredKey)),Method="GET",Headers={apikey=SUPABASE_ANON_KEY,Authorization=("Bearer " .. SUPABASE_ANON_KEY),["Content-Type"]="application/json"}});
				return res.Body;
			else
				return HttpService:GetAsync(SUPABASE_URL .. HttpService:UrlEncode(enteredKey), false, {apikey=SUPABASE_ANON_KEY,Authorization=("Bearer " .. SUPABASE_ANON_KEY)});
			end
		end);
		if (success and response) then
			local decodeSuccess, data = pcall(function()
				return HttpService:JSONDecode(response);
			end);
			if (decodeSuccess and data and (#data > 0)) then
				local record = data[1];
				local currentRobloxUser = LocalPlayer.Name;
				if ((record.status == false) or (record.status == "inactive") or (record.status == "used")) then
					local FlatIdent_94CF9 = 0;
					while true do
						if (FlatIdent_94CF9 == 1) then
							return;
						end
						if (FlatIdent_94CF9 == 0) then
							if not isAutoLogin then
								StatusKey.TextColor3 = C.bad;
								StatusKey.Text = "Key sudah tidak aktif / kadaluwarsa!";
							end
							KeyFrame.Visible = true;
							FlatIdent_94CF9 = 1;
						end
					end
				end
				if (record.roblox_username and (record.roblox_username ~= "")) then
					if not CheckUsernameInList(record.roblox_username, currentRobloxUser) then
						local FlatIdent_8B7B0 = 0;
						while true do
							if (FlatIdent_8B7B0 == 0) then
								if not isAutoLogin then
									local FlatIdent_14716 = 0;
									while true do
										if (0 == FlatIdent_14716) then
											StatusKey.TextColor3 = C.bad;
											StatusKey.Text = "Username (" .. currentRobloxUser .. ") tidak terdaftar!";
											break;
										end
									end
								end
								KeyFrame.Visible = true;
								FlatIdent_8B7B0 = 1;
							end
							if (FlatIdent_8B7B0 == 1) then
								return;
							end
						end
					end
				else
					pcall(function()
						if requestFunc then
							requestFunc({Url=(SUPABASE_URL .. HttpService:UrlEncode(enteredKey)),Method="PATCH",Headers={apikey=SUPABASE_ANON_KEY,Authorization=("Bearer " .. SUPABASE_ANON_KEY),["Content-Type"]="application/json"},Body=HttpService:JSONEncode({roblox_username=currentRobloxUser})});
						end
					end);
				end
				if (record.hwid_value and (record.hwid_value ~= "")) then
					if (record.hwid_value ~= CurrentHWID) then
						local FlatIdent_A446 = 0;
						while true do
							if (FlatIdent_A446 == 1) then
								return;
							end
							if (FlatIdent_A446 == 0) then
								if not isAutoLogin then
									local FlatIdent_14454 = 0;
									while true do
										if (FlatIdent_14454 == 0) then
											StatusKey.TextColor3 = C.bad;
											StatusKey.Text = "Key terikat di perangkat (HWID) lain!";
											break;
										end
									end
								end
								KeyFrame.Visible = true;
								FlatIdent_A446 = 1;
							end
						end
					end
				else
					pcall(function()
						if requestFunc then
							requestFunc({Url=(SUPABASE_URL .. HttpService:UrlEncode(enteredKey)),Method="PATCH",Headers={apikey=SUPABASE_ANON_KEY,Authorization=("Bearer " .. SUPABASE_ANON_KEY),["Content-Type"]="application/json"},Body=HttpService:JSONEncode({hwid_value=CurrentHWID})});
						end
					end);
				end
				pcall(function()
					if writefile then
						writefile(KEY_FILE, enteredKey);
					end
				end);
				SecureData.IsKeyVerified = true;
				KeyFrame.Visible = false;
				Main.Visible = true;
			else
				local FlatIdent_37555 = 0;
				while true do
					if (FlatIdent_37555 == 0) then
						if not isAutoLogin then
							local FlatIdent_11AA1 = 0;
							while true do
								if (FlatIdent_11AA1 == 0) then
									StatusKey.TextColor3 = C.bad;
									StatusKey.Text = "Key tidak ditemukan / invalid!";
									break;
								end
							end
						end
						KeyFrame.Visible = true;
						break;
					end
				end
			end
		else
			if not isAutoLogin then
				StatusKey.TextColor3 = C.bad;
				StatusKey.Text = "Gagal terhubung ke database.";
			end
			KeyFrame.Visible = true;
		end
	end);
end
SubmitKeyBtn.MouseButton1Click:Connect(function()
	ValidateKey(KeyBox.Text, false);
end);
GetKeyBtn.MouseButton1Click:Connect(function()
	local FlatIdent_84478 = 0;
	while true do
		if (FlatIdent_84478 == 0) then
			pcall(function()
				if setclipboard then
					setclipboard("https://" .. HUB_DISCORD);
				end
			end);
			StatusKey.TextColor3 = C.accent;
			FlatIdent_84478 = 1;
		end
		if (FlatIdent_84478 == 1) then
			StatusKey.Text = "Link Discord disalin!";
			break;
		end
	end
end);
local UI = {};
local Tabs = {};
UI.Tab = function(name, icon)
	local FlatIdent_15F29 = 0;
	local btn;
	local bar;
	local lbl;
	local page;
	local tab;
	while true do
		if (FlatIdent_15F29 == 1) then
			Label(btn, icon, 15, C.text, Enum.Font.Gotham, UDim2.new(0, 12, 0, 0), UDim2.new(0, 24, 1, 0), Enum.TextXAlignment.Center);
			lbl = Label(btn, name, 12, C.sub, Enum.Font.GothamMedium, UDim2.new(0, 42, 0, 0), UDim2.new(1, -46, 1, 0));
			page = New("ScrollingFrame", {Size=UDim2.new(1, 0, 1, 0),BackgroundTransparency=1,Visible=false,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y}, PagesHolder);
			New("UIListLayout", {Padding=UDim.new(0, 8),SortOrder=Enum.SortOrder.LayoutOrder}, page);
			FlatIdent_15F29 = 2;
		end
		if (FlatIdent_15F29 == 2) then
			New("UIPadding", {PaddingRight=UDim.new(0, 6),PaddingBottom=UDim.new(0, 8)}, page);
			tab = {Button=btn,Bar=bar,Label=lbl,Page=page};
			table.insert(Tabs, tab);
			btn.MouseButton1Click:Connect(function()
				local FlatIdent_61084 = 0;
				while true do
					if (FlatIdent_61084 == 0) then
						for _, t in ipairs(Tabs) do
							local on = t == tab;
							t.Page.Visible = on;
							t.Bar.Visible = on;
							t.Button.BackgroundTransparency = (on and 0) or 1;
							t.Label.TextColor3 = (on and C.text) or C.sub;
						end
						PageTitle.Text = name;
						break;
					end
				end
			end);
			FlatIdent_15F29 = 3;
		end
		if (3 == FlatIdent_15F29) then
			if (#Tabs == 1) then
				local FlatIdent_69D54 = 0;
				while true do
					if (FlatIdent_69D54 == 0) then
						page.Visible, bar.Visible = true, true;
						btn.BackgroundTransparency = 0;
						FlatIdent_69D54 = 1;
					end
					if (FlatIdent_69D54 == 1) then
						lbl.TextColor3 = C.text;
						PageTitle.Text = name;
						break;
					end
				end
			end
			return page;
		end
		if (0 == FlatIdent_15F29) then
			btn = New("TextButton", {Size=UDim2.new(1, 0, 0, 38),BackgroundColor3=C.card,BackgroundTransparency=1,AutoButtonColor=false,Text="",LayoutOrder=(#Tabs + 1)}, Sidebar);
			Round(btn, 10);
			bar = New("Frame", {Size=UDim2.new(0, 3, 0, 18),Position=UDim2.new(0, 2, 0.5, -9),BackgroundColor3=C.accent,Visible=false,BorderSizePixel=0}, btn);
			Round(bar, 2);
			FlatIdent_15F29 = 1;
		end
	end
end;
local function Card(page, h)
	local FlatIdent_523B3 = 0;
	local f;
	while true do
		if (FlatIdent_523B3 == 0) then
			f = New("Frame", {Size=UDim2.new(1, -4, 0, h or 54),BackgroundColor3=C.card}, page);
			Round(f, 10);
			FlatIdent_523B3 = 1;
		end
		if (FlatIdent_523B3 == 1) then
			New("UIStroke", {Color=C.line,Thickness=1}, f);
			return f;
		end
	end
end
local function CardText(card, title, desc, rightPad)
	Label(card, title, 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, 12, 0, 8), UDim2.new(1, -rightPad, 0, 18));
	if (desc and (desc ~= "")) then
		Label(card, desc, 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 12, 0, 27), UDim2.new(1, -rightPad, 0, 18));
	end
end
UI.Section = function(page, text, color)
	return Label(page, text, 12, color or C.accent, Enum.Font.GothamBold, nil, UDim2.new(1, -4, 0, 22));
end;
UI.Toggle = function(page, title, desc, default, cb)
	local card = Card(page);
	CardText(card, title, desc, 80);
	local sw = New("TextButton", {Text="",AutoButtonColor=false,Size=UDim2.new(0, 44, 0, 22),Position=UDim2.new(1, -56, 0.5, -11),BackgroundColor3=C.off}, card);
	Round(sw, 11);
	local knob = New("Frame", {Size=UDim2.new(0, 16, 0, 16),Position=UDim2.new(0, 3, 0.5, -8),BackgroundColor3=C.accent}, sw);
	Round(knob, 8);
	local state = (default and true) or false;
	local function render()
		local FlatIdent_9851B = 0;
		local ti;
		while true do
			if (FlatIdent_9851B == 0) then
				ti = TweenInfo.new(0.15);
				TweenService:Create(knob, ti, {Position=((state and UDim2.new(1, -19, 0.5, -8)) or UDim2.new(0, 3, 0.5, -8)),BackgroundColor3=((state and Color3.new(1, 1, 1)) or C.accent)}):Play();
				FlatIdent_9851B = 1;
			end
			if (FlatIdent_9851B == 1) then
				TweenService:Create(sw, ti, {BackgroundColor3=((state and C.accent) or C.off)}):Play();
				break;
			end
		end
	end
	render();
	sw.MouseButton1Click:Connect(function()
		local FlatIdent_559FF = 0;
		while true do
			if (FlatIdent_559FF == 0) then
				if not SecureData.IsKeyVerified then
					local FlatIdent_FBDE = 0;
					while true do
						if (FlatIdent_FBDE == 0) then
							state = false;
							render();
							FlatIdent_FBDE = 1;
						end
						if (FlatIdent_FBDE == 1) then
							return;
						end
					end
				end
				state = not state;
				FlatIdent_559FF = 1;
			end
			if (FlatIdent_559FF == 1) then
				render();
				task.spawn(cb, state);
				break;
			end
		end
	end);
	return {Set=function(v)
		state = (v and true) or false;
		render();
	end};
end;
UI.Button = function(page, title, desc, btnText, cb, color)
	local FlatIdent_4BE81 = 0;
	local card;
	local b;
	while true do
		if (FlatIdent_4BE81 == 0) then
			card = Card(page);
			CardText(card, title, desc, 130);
			FlatIdent_4BE81 = 1;
		end
		if (FlatIdent_4BE81 == 2) then
			b.MouseButton1Click:Connect(function()
				local FlatIdent_7DCBC = 0;
				while true do
					if (FlatIdent_7DCBC == 0) then
						if not SecureData.IsKeyVerified then
							return;
						end
						task.spawn(cb, b);
						break;
					end
				end
			end);
			return b, card;
		end
		if (FlatIdent_4BE81 == 1) then
			b = New("TextButton", {Size=UDim2.new(0, 104, 0, 30),Position=UDim2.new(1, -116, 0.5, -15),BackgroundColor3=(color or C.accent),Text=btnText,TextColor3=Color3.new(1, 1, 1),Font=Enum.Font.GothamBold,TextSize=12,TextTruncate=Enum.TextTruncate.AtEnd}, card);
			Round(b, 8);
			FlatIdent_4BE81 = 2;
		end
	end
end;
UI.Input = function(page, title, desc, default, placeholder, cb)
	local FlatIdent_1D5FF = 0;
	local card;
	local box;
	while true do
		if (FlatIdent_1D5FF == 2) then
			New("UIStroke", {Color=C.line}, box);
			box.FocusLost:Connect(function()
				cb(box.Text);
			end);
			FlatIdent_1D5FF = 3;
		end
		if (FlatIdent_1D5FF == 1) then
			box = New("TextBox", {Size=UDim2.new(0, 112, 0, 30),Position=UDim2.new(1, -124, 0.5, -15),BackgroundColor3=C.bg,Text=tostring(default or ""),PlaceholderText=(placeholder or ""),PlaceholderColor3=C.sub,TextColor3=C.text,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=false}, card);
			Round(box, 8);
			FlatIdent_1D5FF = 2;
		end
		if (FlatIdent_1D5FF == 0) then
			card = Card(page);
			CardText(card, title, desc, 140);
			FlatIdent_1D5FF = 1;
		end
		if (FlatIdent_1D5FF == 3) then
			return box;
		end
	end
end;
UI.Picker = function(page, title, getOptions, getSelected, onSelect, getDesc)
	local card = Card(page, 54);
	card.ClipsDescendants = true;
	Label(card, title, 13, C.text, Enum.Font.GothamMedium, UDim2.new(0, 12, 0, 8), UDim2.new(1, -160, 0, 18));
	local descLbl = Label(card, "", 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 12, 0, 27), UDim2.new(1, -160, 0, 18));
	local btn = New("TextButton", {Size=UDim2.new(0, 132, 0, 30),Position=UDim2.new(1, -144, 0, 12),BackgroundColor3=C.accent,Text="Pilih ▾",TextColor3=Color3.new(1, 1, 1),Font=Enum.Font.GothamBold,TextSize=12,TextTruncate=Enum.TextTruncate.AtEnd}, card);
	Round(btn, 8);
	local LIST_H = 124;
	local list = New("ScrollingFrame", {Size=UDim2.new(1, -24, 0, LIST_H),Position=UDim2.new(0, 12, 0, 60),BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false,ScrollBarThickness=3,ScrollBarImageColor3=C.accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y}, card);
	Round(list, 8);
	New("UIListLayout", {Padding=UDim.new(0, 4),SortOrder=Enum.SortOrder.LayoutOrder}, list);
	New("UIPadding", {PaddingTop=UDim.new(0, 4),PaddingBottom=UDim.new(0, 4),PaddingLeft=UDim.new(0, 4),PaddingRight=UDim.new(0, 8)}, list);
	local open = false;
	local self = {};
	local function setOpen(v)
		local FlatIdent_6F3E4 = 0;
		while true do
			if (FlatIdent_6F3E4 == 0) then
				open = v;
				list.Visible = v;
				FlatIdent_6F3E4 = 1;
			end
			if (FlatIdent_6F3E4 == 1) then
				card.Size = UDim2.new(1, -4, 0, (v and (60 + LIST_H + 8)) or 54);
				break;
			end
		end
	end
	self.Refresh = function()
		local FlatIdent_C342 = 0;
		local selected;
		local opts;
		local selLabel;
		while true do
			if (FlatIdent_C342 == 0) then
				selected = getSelected();
				opts = getOptions();
				FlatIdent_C342 = 1;
			end
			if (FlatIdent_C342 == 2) then
				for i, o in ipairs(opts) do
					local FlatIdent_6C51A = 0;
					local isSel;
					local row;
					while true do
						if (FlatIdent_6C51A == 0) then
							isSel = o.value == selected;
							if isSel then
								selLabel = o.label;
							end
							FlatIdent_6C51A = 1;
						end
						if (FlatIdent_6C51A == 1) then
							row = New("TextButton", {Size=UDim2.new(1, 0, 0, 28),LayoutOrder=i,AutoButtonColor=false,BackgroundColor3=((isSel and C.accent) or C.card),Text=o.label,TextColor3=C.text,Font=Enum.Font.GothamMedium,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd}, list);
							Round(row, 6);
							FlatIdent_6C51A = 2;
						end
						if (2 == FlatIdent_6C51A) then
							New("UIPadding", {PaddingLeft=UDim.new(0, 10)}, row);
							row.MouseButton1Click:Connect(function()
								local FlatIdent_2A1A = 0;
								while true do
									if (0 == FlatIdent_2A1A) then
										setOpen(false);
										onSelect(o.value);
										break;
									end
								end
							end);
							break;
						end
					end
				end
				btn.Text = selLabel .. " ▾";
				FlatIdent_C342 = 3;
			end
			if (1 == FlatIdent_C342) then
				for _, ch in ipairs(list:GetChildren()) do
					if ch:IsA("TextButton") then
						ch:Destroy();
					end
				end
				selLabel = "Pilih";
				FlatIdent_C342 = 2;
			end
			if (FlatIdent_C342 == 3) then
				descLbl.Text = (getDesc and getDesc()) or "";
				break;
			end
		end
	end;
	btn.MouseButton1Click:Connect(function()
		setOpen(not open);
	end);
	self.Refresh();
	return self;
end;
local TabFish = UI.Tab("Fishing", "🎣");
local TabSummit = UI.Tab("Summit", "⛰️");
local TabDaily = UI.Tab("Daily", "📅");
local TabCook = UI.Tab("Cooking", "🍳");
local TabSettings = UI.Tab("Settings", "⚙️");
local TabCredits = UI.Tab("Credits", "👑");
UI.Section(TabFish, "AUTO FISHING");
UI.Toggle(TabFish, "Auto Fishing", "Equip rod dulu sebelum aktifkan.", false, function(v)
	getgenv().AutoFishingRunning = v;
end);
UI.Toggle(TabFish, "Auto Sell Ikan", "Jual ikan otomatis per interval.", false, function(v)
	local FlatIdent_62CB4 = 0;
	while true do
		if (FlatIdent_62CB4 == 0) then
			getgenv().AutoSellRunning = v;
			if v then
				task.spawn(function()
					local FlatIdent_8C1D5 = 0;
					local lastSell;
					while true do
						if (FlatIdent_8C1D5 == 0) then
							lastSell = tick();
							while getgenv().AutoSellRunning do
								if not SecureData.IsKeyVerified then
									getgenv().AutoSellRunning = false;
									break;
								end
								task.wait(1);
								if (((tick() - lastSell) / 60) >= (tonumber(getgenv().UbeyConfig.AutoSellTimer) or 5)) then
									local FlatIdent_994C = 0;
									while true do
										if (FlatIdent_994C == 0) then
											TriggerSellAll();
											lastSell = tick();
											break;
										end
									end
								end
							end
							break;
						end
					end
				end);
			end
			break;
		end
	end
end);
UI.Input(TabFish, "Jeda Jual (Menit)", "Interval auto-sell dalam menit.", tostring(getgenv().UbeyConfig.AutoSellTimer), "5", function(text)
	local val = tonumber(text);
	if val then
		local FlatIdent_3C1AA = 0;
		while true do
			if (FlatIdent_3C1AA == 0) then
				getgenv().UbeyConfig.AutoSellTimer = tostring(val);
				SaveConfig();
				break;
			end
		end
	end
end);
UI.Input(TabFish, "Wait Time (detik)", "Jeda antara cast & ambil ikan.", tostring(getgenv().UbeyConfig.WaitTime), "4.0", function(text)
	local FlatIdent_3C8BC = 0;
	local val;
	while true do
		if (FlatIdent_3C8BC == 0) then
			val = tonumber(text);
			if val then
				local FlatIdent_82A94 = 0;
				while true do
					if (0 == FlatIdent_82A94) then
						getgenv().UbeyConfig.WaitTime = val;
						SaveConfig();
						break;
					end
				end
			end
			break;
		end
	end
end);
UI.Input(TabFish, "Loop Delay (detik)", "Jeda antar loop fishing.", tostring(getgenv().UbeyConfig.LoopDelay), "0.1", function(text)
	local FlatIdent_69486 = 0;
	local val;
	while true do
		if (FlatIdent_69486 == 0) then
			val = tonumber(text);
			if val then
				local FlatIdent_185A5 = 0;
				while true do
					if (0 == FlatIdent_185A5) then
						getgenv().UbeyConfig.LoopDelay = val;
						SaveConfig();
						break;
					end
				end
			end
			break;
		end
	end
end);
UI.Section(TabSummit, "AUTO SUMMIT");
UI.Toggle(TabSummit, "Auto Climb Summit", "Otomatis mendaki 31 waypoint + bypass timer.", false, function(v)
	getgenv().AutoSummitRunning = v;
end);
UI.Section(TabDaily, "AUTO DAILY LOGIN");
UI.Toggle(TabDaily, "Auto Claim Daily", "Klaim otomatis hadiah login harian.", false, function(v)
	getgenv().AutoDailyRunning = v;
end);
local function SetCard(card, title, desc)
	local FlatIdent_4CEEC = 0;
	local labels;
	while true do
		if (FlatIdent_4CEEC == 1) then
			if labels[1] then
				labels[1].Text = title;
			end
			if labels[2] then
				labels[2].Text = desc;
			else
				Label(card, desc, 11, C.sub, Enum.Font.Gotham, UDim2.new(0, 12, 0, 27), UDim2.new(1, -130, 0, 18));
			end
			break;
		end
		if (FlatIdent_4CEEC == 0) then
			labels = {};
			for _, ch in ipairs(card:GetChildren()) do
				if ch:IsA("TextLabel") then
					table.insert(labels, ch);
				end
			end
			FlatIdent_4CEEC = 1;
		end
	end
end
UI.Section(TabCook, "1. GILING: PILIH RARITY IKAN");
for _, R in ipairs(RarityList) do
	UI.Toggle(TabCook, "Giling " .. R, "Ikan " .. R .. " ikut digiling.", CookCfg.GrindRarity[R:lower()] == true, function(v)
		CookCfg.GrindRarity[R:lower()] = v or nil;
	end);
end
UI.Input(TabCook, "Maks Ikan Digiling", "Batas jumlah ikan sekali giling.", CookCfg.GrindLimit, "6", function(t)
	local v = tonumber(t);
	if (v and (v >= 1)) then
		CookCfg.GrindLimit = math.floor(v);
	end
end);
UI.Section(TabCook, "2. MASAK: PILIH RARITY & RESEP");
local RarityPicker, RecipePicker;
RarityPicker = UI.Picker(TabCook, "Rarity Masak / Daging", function()
	local FlatIdent_1F33B = 0;
	local o;
	while true do
		if (FlatIdent_1F33B == 1) then
			return o;
		end
		if (FlatIdent_1F33B == 0) then
			o = {};
			for _, R in ipairs(RarityList) do
				table.insert(o, {label=R,value=R});
			end
			FlatIdent_1F33B = 1;
		end
	end
end, function()
	return CurrentMenu().Rarity;
end, function(R)
	local FlatIdent_53252 = 0;
	local list;
	while true do
		if (FlatIdent_53252 == 0) then
			list = MenusOfRarity(R);
			if (#list > 0) then
				CookCfg.Index = list[1];
			end
			FlatIdent_53252 = 1;
		end
		if (FlatIdent_53252 == 1) then
			RarityPicker.Refresh();
			RecipePicker.Refresh();
			break;
		end
	end
end, function()
	return "Pakai Daging " .. CurrentMenu().Rarity .. " (1 daging = 1 porsi)";
end);
RecipePicker = UI.Picker(TabCook, "Resep", function()
	local FlatIdent_25061 = 0;
	local o;
	while true do
		if (FlatIdent_25061 == 0) then
			o = {};
			for _, idx in ipairs(MenusOfRarity(CurrentMenu().Rarity)) do
				local FlatIdent_1FA0 = 0;
				local m;
				while true do
					if (0 == FlatIdent_1FA0) then
						m = CookData.Menus[idx];
						table.insert(o, {label=m.Name,value=idx});
						break;
					end
				end
			end
			FlatIdent_25061 = 1;
		end
		if (FlatIdent_25061 == 1) then
			return o;
		end
	end
end, function()
	return CookCfg.Index;
end, function(idx)
	local FlatIdent_2B407 = 0;
	while true do
		if (FlatIdent_2B407 == 0) then
			CookCfg.Index = idx;
			RecipePicker.Refresh();
			break;
		end
	end
end, function()
	return "Bahan: " .. IngredientText(CurrentMenu().Id) .. " /porsi";
end);
UI.Input(TabCook, "Jumlah Porsi", "Porsi sekali masak (= jumlah daging).", CookCfg.Amount, "6", function(t)
	local FlatIdent_7EE98 = 0;
	local v;
	while true do
		if (FlatIdent_7EE98 == 0) then
			v = tonumber(t);
			if (v and (v >= 1)) then
				CookCfg.Amount = math.floor(v);
			end
			break;
		end
	end
end);
UI.Toggle(TabCook, "Trigger Prompt", "Aktifkan jika masih gagal: tekan E stasiun otomatis.", false, function(v)
	CookCfg.FirePrompt = v;
end);
UI.Section(TabCook, "AUTO");
UI.Toggle(TabCook, "Auto Giling + Masak", "Giling, beli bahan, masak, ulangi.", false, function(v)
	getgenv().AutoCookPipeline = v;
end);
UI.Input(TabCook, "Jeda Siklus (detik)", "Jeda antar siklus auto.", CookCfg.Interval, "10", function(t)
	local v = tonumber(t);
	if v then
		CookCfg.Interval = v;
	end
end);
UI.Section(TabCook, "MANUAL");
UI.Button(TabCook, "Giling Ikan", "Giling ikan sesuai rarity pilihan.", "Giling", function(btn)
	local FlatIdent_285D = 0;
	local n;
	while true do
		if (FlatIdent_285D == 0) then
			btn.Text = "...";
			n = GrindManual();
			FlatIdent_285D = 1;
		end
		if (FlatIdent_285D == 1) then
			btn.Text = n .. " ikan";
			task.wait(2);
			FlatIdent_285D = 2;
		end
		if (2 == FlatIdent_285D) then
			btn.Text = "Giling";
			break;
		end
	end
end);
UI.Button(TabCook, "Beli Bahan", "Beli bahan sesuai resep & porsi.", "Beli", function(btn)
	local FlatIdent_2E7F5 = 0;
	while true do
		if (FlatIdent_2E7F5 == 1) then
			btn.Text = "Selesai";
			task.wait(2);
			FlatIdent_2E7F5 = 2;
		end
		if (FlatIdent_2E7F5 == 0) then
			btn.Text = "...";
			BuyManual();
			FlatIdent_2E7F5 = 1;
		end
		if (FlatIdent_2E7F5 == 2) then
			btn.Text = "Beli";
			break;
		end
	end
end);
UI.Button(TabCook, "Masak Sekarang", "Beli bahan lalu masak.", "Masak", function(btn)
	btn.Text = "Memasak...";
	CookManual();
	btn.Text = "Masak";
end);
UI.Section(TabCook, "PENGATURAN & UPGRADE", C.warn);
UI.Input(TabCook, "Kapasitas Beli", "Samakan dgn upgrade toko (awal 15).", CookCfg.BuyCap, "15", function(t)
	local FlatIdent_259C6 = 0;
	local v;
	while true do
		if (FlatIdent_259C6 == 0) then
			v = tonumber(t);
			if (v and (v >= 1)) then
				CookCfg.BuyCap = math.floor(v);
			end
			break;
		end
	end
end);
UI.Input(TabCook, "Slot Giling", "Maks ikan sekali giling (awal 10).", CookCfg.GrindSlots, "10", function(t)
	local v = tonumber(t);
	if (v and (v >= 1)) then
		CookCfg.GrindSlots = math.floor(v);
	end
end);
UI.Button(TabCook, "Upgrade Kapasitas Toko", "+5 kapasitas, biaya 1.000.000 koin.", "Upgrade", function()
	local FlatIdent_3E76B = 0;
	local r;
	while true do
		if (0 == FlatIdent_3E76B) then
			r = CookRemote("TokoEvents", "TokoUpgrade");
			if r then
				local FlatIdent_7C89 = 0;
				local ok;
				local res;
				while true do
					if (FlatIdent_7C89 == 0) then
						ok, res = pcall(function()
							return r:InvokeServer();
						end);
						print("[TokoUpgrade]", ok, res);
						break;
					end
				end
			end
			break;
		end
	end
end, C.bad);
UI.Button(TabCook, "Upgrade Slot Giling", "+5 slot, biaya 25 juta (belum diuji).", "Upgrade", function()
	local r = CookRemote("CookingSystem", "GrindUpgrade");
	if r then
		local ok, res = pcall(function()
			return r:InvokeServer();
		end);
		print("[GrindUpgrade]", ok, res);
	end
end, C.bad);
UI.Button(TabCook, "Cek Struktur Giling", "Cetak isi GrindList ke console (F9).", "Cetak", function()
	DumpGrindList();
end, C.off);
UI.Section(TabSettings, "UTILITAS");
local isAntiLagActive = false;
UI.Button(TabSettings, "Anti-Lag", "Matikan efek berat untuk performa.", "Aktifkan", function(btn)
	local FlatIdent_D895 = 0;
	while true do
		if (FlatIdent_D895 == 0) then
			isAntiLagActive = not isAntiLagActive;
			if isAntiLagActive then
				local FlatIdent_60344 = 0;
				while true do
					if (FlatIdent_60344 == 0) then
						pcall(function()
							local FlatIdent_86ECC = 0;
							while true do
								if (FlatIdent_86ECC == 2) then
									Workspace.Terrain.WaterWaveSpeed = 0;
									break;
								end
								if (FlatIdent_86ECC == 0) then
									Lighting.GlobalShadows = false;
									Lighting.FogEnd = 8999999488;
									FlatIdent_86ECC = 1;
								end
								if (FlatIdent_86ECC == 1) then
									for _, v in ipairs(Lighting:GetDescendants()) do
										if (v:IsA("PostEffect") or v:IsA("Atmosphere")) then
											v.Enabled = false;
										end
									end
									Workspace.Terrain.WaterWaveSize = 0;
									FlatIdent_86ECC = 2;
								end
							end
						end);
						btn.Text = "Matikan";
						FlatIdent_60344 = 1;
					end
					if (FlatIdent_60344 == 1) then
						btn.BackgroundColor3 = C.bad;
						break;
					end
				end
			else
				local FlatIdent_734D3 = 0;
				while true do
					if (FlatIdent_734D3 == 1) then
						btn.BackgroundColor3 = C.accent;
						break;
					end
					if (FlatIdent_734D3 == 0) then
						pcall(function()
							local FlatIdent_7695C = 0;
							while true do
								if (FlatIdent_7695C == 1) then
									for _, v in ipairs(Lighting:GetDescendants()) do
										if (v:IsA("PostEffect") or v:IsA("Atmosphere")) then
											v.Enabled = true;
										end
									end
									break;
								end
								if (FlatIdent_7695C == 0) then
									Lighting.GlobalShadows = true;
									Lighting.FogEnd = 100000;
									FlatIdent_7695C = 1;
								end
							end
						end);
						btn.Text = "Aktifkan";
						FlatIdent_734D3 = 1;
					end
				end
			end
			break;
		end
	end
end);
UI.Section(TabCredits, "CREDITS");
local credCard = New("Frame", {Size=UDim2.new(1, -4, 0, 84),BackgroundColor3=C.card}, TabCredits);
Round(credCard, 10);
New("UIStroke", {Color=C.line,Thickness=1}, credCard);
Label(credCard, "UBEY HUB", 16, C.accent, Enum.Font.GothamBold, UDim2.new(0, 0, 0, 14), UDim2.new(1, 0, 0, 22), Enum.TextXAlignment.Center);
Label(credCard, "Created by UBEY", 12, C.text, Enum.Font.Gotham, UDim2.new(0, 0, 0, 38), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Center);
UI.Button(TabCredits, "Discord Link", "Salin link discord ke clipboard.", "Salin", function(btn)
	pcall(function()
		if setclipboard then
			local FlatIdent_5F7B5 = 0;
			while true do
				if (FlatIdent_5F7B5 == 1) then
					task.wait(2);
					btn.Text = "Salin";
					break;
				end
				if (0 == FlatIdent_5F7B5) then
					setclipboard("https://" .. HUB_DISCORD);
					btn.Text = "Tersalin!";
					FlatIdent_5F7B5 = 1;
				end
			end
		end
	end);
end, Color3.fromRGB(88, 101, 242));
local Float = New("ImageButton", {Size=UDim2.new(0, 60, 0, 60),Position=UDim2.new(0, 20, 0, 120),Image=LOGO_ASSET,BackgroundColor3=C.bg,AutoButtonColor=false,ZIndex=50}, Gui);
Round(Float, 30);
New("UIStroke", {Color=C.accent,Thickness=2}, Float);
local floatMoved = MakeDraggable(Float);
Float.MouseButton1Click:Connect(function()
	if floatMoved() then
		return;
	end
	if not SecureData.IsKeyVerified then
		local FlatIdent_15E91 = 0;
		while true do
			if (FlatIdent_15E91 == 0) then
				KeyFrame.Visible = not KeyFrame.Visible;
				Main.Visible = false;
				break;
			end
		end
	else
		local FlatIdent_87F0A = 0;
		while true do
			if (FlatIdent_87F0A == 0) then
				Main.Visible = not Main.Visible;
				KeyFrame.Visible = false;
				break;
			end
		end
	end
end);
task.spawn(function()
	if (readfile and isfile and isfile(KEY_FILE)) then
		local FlatIdent_1D0A6 = 0;
		local savedKey;
		while true do
			if (FlatIdent_1D0A6 == 0) then
				savedKey = readfile(KEY_FILE);
				if (savedKey and (savedKey ~= "")) then
					KeyBox.Text = savedKey;
					ValidateKey(savedKey, true);
				else
					KeyFrame.Visible = true;
				end
				break;
			end
		end
	else
		KeyFrame.Visible = true;
	end
end);
