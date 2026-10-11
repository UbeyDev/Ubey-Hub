-- UBEY HUB | AUTO FISHING (RAYFIELD UI)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

getgenv().AutoExactSeq = false
getgenv().CastDelay = 0.25   -- Delay setelah lempar kail
getgenv().MiniDelay = 0.30   -- Delay minigame
getgenv().GiveDelay = 0.20   -- Delay klaim ikan

-- LOAD RAYFIELD UI LIBRARY
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "UBEY HUB - AUTO FISHING",
   LoadingTitle = "Ubey Hub Loading...",
   LoadingSubtitle = "by UBEY",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "UbeyHubFishing",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false, -- Ubah jadi true jika ingin pakai key system
   KeySettings = {
      Title = "Key System",
      Subtitle = "Linkwarden",
      Note = "No key needed",
      FileName = "DanzKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {""}
   }
})

-- MEMBUAT TAB UTAMA
local MainTab = Window:CreateTab("Auto Farm", 4483362458)

-- DISPLAY ROD STATUS
local RodLabel = MainTab:CreateLabel("Rod: Detecting...")

-- FUNGSI UNTUK MEMBACA PANCINGAN YANG SEDANG DIPEGANG
local function GetEquippedRodName()
	local char = LocalPlayer.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			return tool.Name
		end
	end
	return "Basic Rod"
end

-- TOMBOL ON / OFF AUTO FISHING
MainTab:CreateToggle({
   Name = "Auto Fish",
   CurrentValue = false,
   Flag = "AutoFishToggle",
   Callback = function(Value)
      getgenv().AutoExactSeq = Value
   end,
})

MainTab:CreateDivider()

-- INPUT DELAY 1 (CAST)
MainTab:CreateInput({
   Name = "Cast Delay (s)",
   CurrentValue = tostring(getgenv().CastDelay),
   PlaceholderText = "0.25",
   RemoveTextAfterFocusLost = false,
   Flag = "CastDelayInput",
   Callback = function(Text)
      local val = tonumber(Text)
      if val then
         getgenv().CastDelay = val
      end
   end,
})

-- INPUT DELAY 2 (MINIGAME)
MainTab:CreateInput({
   Name = "Mini Delay (s)",
   CurrentValue = tostring(getgenv().MiniDelay),
   PlaceholderText = "0.30",
   RemoveTextAfterFocusLost = false,
   Flag = "MiniDelayInput",
   Callback = function(Text)
      local val = tonumber(Text)
      if val then
         getgenv().MiniDelay = val
      end
   end,
})

-- INPUT DELAY 3 (CLAIM)
MainTab:CreateInput({
   Name = "Claim Delay (s)",
   CurrentValue = tostring(getgenv().GiveDelay),
   PlaceholderText = "0.20",
   RemoveTextAfterFocusLost = false,
   Flag = "ClaimDelayInput",
   Callback = function(Text)
      local val = tonumber(Text)
      if val then
         getgenv().GiveDelay = val
      end
   end,
})

-- 4. LOGIKA UTAMA AUTO FISHING
task.spawn(function()
	while true do
		task.wait(0.1)
		
		-- Update tampilan label pancingan secara aman
		pcall(function()
			local currentRod = GetEquippedRodName()
			RodLabel:Set("Rod: " .. currentRod)
		end)
		
		if getgenv().AutoExactSeq then
			pcall(function()
				local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local hrp = char:WaitForChild("HumanoidRootPart", 3)
				if not hrp then return end
				
				local FS = ReplicatedStorage:WaitForChild("FishingSystem", 3)
				if not FS then return end
				
				local cast = FS:FindFirstChild("CastReplication")
				local mini = FS:FindFirstChild("MinigameStarted")
				local clean = FS:FindFirstChild("CleanupCast")
				local give = FS:FindFirstChild("FishGiver")
				local currentRod = GetEquippedRodName()
				
				local pos = hrp.Position + Vector3.new(0, 2, 0)
				local lookVec = hrp.CFrame.LookVector * 15
				local hook = pos + lookVec - Vector3.new(0, 5, 0)
				
				-- 1. Lempar Kail
				if cast then
					cast:FireServer(pos, Vector3.new(-24.72, 5, 3.71), currentRod, 100)
				end
				
				task.wait(getgenv().CastDelay)
				if not getgenv().AutoExactSeq then return end
				
				-- 2. Minigame
				if mini then
					mini:FireServer({
						hookPosition = hook,
						power = 50
					})
				end
				
				task.wait(getgenv().MiniDelay)
				if not getgenv().AutoExactSeq then return end
				
				-- 3. Cleanup Cast
				if clean then
					clean:FireServer()
				end
				
				task.wait(0.05)
				
				-- 4. Claim Ikan
				if give then
					give:FireServer({
						hookPosition = hook,
						power = 50
					})
				end
				
				task.wait(getgenv().GiveDelay)
			end)
		end
	end
end)

Rayfield:LoadConfiguration()
