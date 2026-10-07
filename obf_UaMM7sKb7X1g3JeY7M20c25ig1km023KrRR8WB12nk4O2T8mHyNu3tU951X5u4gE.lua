-- ==============================================================================
-- UBEY HUB | All-in-One Hub (Fishing, Summit, Player & HWID Key System)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Konfigurasi Supabase
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co"
local SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3d3h2ZW14ZXp0Zml5dXVyaHJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzMTAwMDIsImV4cCI6MjEwNjg4NjAwMn0.IQNQXBvOHyovn-fahzGR-yAt34-72LG6dyVtUJAa92c"

-- Fungsi untuk mendapatkan HWID unik executor (Delta, dll)
local function getDeviceHWID()
    local hwid = ""
    pcall(function()
        if getgenv().gethwid then
            hwid = getgenv().gethwid()
        elseif syn and syn.get_hwid then
            hwid = syn.get_hwid()
        elseif gethwid then
            hwid = gethwid()
        end
    end)
    if hwid == "" then
        hwid = "ROBLOX-FALLBACK-" .. tostring(LocalPlayer.UserId)
    end
    return hwid
end

-- Fungsi verifikasi key ke Supabase
local function verifyUserKey(inputKey)
    local url = SUPABASE_URL .. "/rest/v1/Ubey_Project?key_value=eq." .. HttpService:UrlEncode(inputKey)
    local headers = {
        ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY,
        ["Content-Type"] = "application/json"
    }

    local success, response = pcall(function()
        return syn and syn.request({
            Url = url,
            Method = "GET",
            Headers = headers
        }) or request({
            Url = url,
            Method = "GET",
            Headers = headers
        })
    end)

    if success and response and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        if data and #data > 0 then
            local row = data[1]
            local currentHWID = getDeviceHWID()
            
            if row.hwid == currentHWID then
                return true, "Key Valid & HWID Cocok!"
            else
                return false, "Key sudah terikat ke perangkat lain!"
            end
        else
            return false, "Key tidak ditemukan di database!"
        end
    else
        return false, "Gagal terhubung ke server Supabase!"
    end
end

-- Otomatis menyalin link Discord ke clipboard perangkat
pcall(function()
    if setclipboard then
        setclipboard("https://discord.gg/TRkVMKHwzD")
    elseif toclipboard then
        toclipboard("https://discord.gg/TRkVMKHwzD")
    end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

getgenv().AutoFishingEventRunning = false
getgenv().BiteDelay = 0.5
getgenv().IsInCutscene = false
getgenv().AntiAFKRunning = false

local function GetRod()
    local character = LocalPlayer.Character
    if character then
        local rodInHand = character:FindFirstChild("Withering Rod")
        if rodInHand then
            return rodInHand
        else
            local rodInBackpack = LocalPlayer.Backpack:FindFirstChild("Withering Rod")
            if rodInBackpack and character:FindFirstChildOfClass("Humanoid") then
                character.Humanoid:EquipTool(rodInBackpack)
                task.wait(0.3)
                return character:FindFirstChild("Withering Rod")
            end
        end
    end
    return nil
end

local function OptimizeRodSettings()
    pcall(function()
        local rod = GetRod()
        if rod then
            local settingsFolder = rod:FindFirstChild("Mechanics") and rod.Mechanics:FindFirstChild("Settings")
            if settingsFolder then
                local timeSetting = settingsFolder:FindFirstChild("Time_before_getfish")
                if timeSetting then
                    timeSetting.Value = 0.05
                end
                
                local enableMiniGame = settingsFolder:FindFirstChild("EnableMiniGame")
                if enableMiniGame then
                    enableMiniGame.Value = false
                end
            end
        end
    end)
end

local function DestroyGameCutscenes()
    pcall(function()
        local namesToDestroy = {
            "CutsceneForgottenKenyal",
            "CutsceneSecretKenyal",
            "CutsceneForgotten",
            "CutsceneSecret",
            "CutsceneKitsune",
            "CutsceneTangkapan",
            "KitsuneCutscene"
        }
        
        for _, name in ipairs(namesToDestroy) do
            local item = ReplicatedStorage:FindFirstChild(name, true)
            if item then
                item:Destroy()
            end
        end
        
        for _, sound in ipairs(SoundService:GetChildren()) do
            local sName = string.lower(sound.Name)
            if string.find(sName, "cutscene") or string.find(sName, "secret") or string.find(sName, "forgotten") then
                sound:Destroy()
            end
        end
    end)
end

-- Membuat Window Rayfield (UBEY HUB)
local Window = Rayfield:CreateWindow({
   Name = "🔥 UBEY HUB | All-in-One Hub 🚀",
   LoadingTitle = "🚀 UBEY HUB Loading...",
   LoadingSubtitle = "by Ubey",
   ConfigurationSaving = { Enabled = false, FolderName = nil, FileName = "UbeyHub" },
   Discord = { 
      Enabled = true, 
      Invite = "TRkVMKHwzD", 
      RememberJoins = true 
   },
   KeySystem = true,
   KeySettings = {
      Title = "Ubey Hub - Key System",
      Subtitle = "Aktivasi HWID Web Portal",
      Note = "Dapatkan key di Discord: discord.gg/TRkVMKHwzD (Link tersalin otomatis!)",
      FileName = "UbeyKeyStore",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"UBEY_GANTENG"}
   }
})

------------------------------------------------------------------
-- TAB 1: FISHING
------------------------------------------------------------------
local FishingTab = Window:CreateTab("🏠 Fishing", nil) 
local FishingSection = FishingTab:CreateSection("Auto Farm")

Rayfield:Notify({
   Title = "UBEY HUB Executed",
   Content = "Fast Notification & Stable Fishing Siap!",
   Duration = 5,
   Image = 13047715178,
})

FishingTab:CreateButton({
   Name = "⚡ Bypass & Fast Rod (Set 0.05s)",
   Callback = function()
        OptimizeRodSettings()
        Rayfield:Notify({ Title = "Berhasil", Content = "Time_before_getfish diubah ke 0.05 & MiniGame dimatikan!", Duration = 3, Image = 13047715178 })
   end,
})

FishingTab:CreateToggle({
   Name = "Smart Auto Fishing + Fast Response",
   CurrentValue = false,
   Flag = "AutoFishToggle",
   Callback = function(Value)
        getgenv().AutoFishingEventRunning = Value
        
        if Value then
            OptimizeRodSettings()
            
            local rsConnection
            rsConnection = ReplicatedStorage.ChildAdded:Connect(function(child)
                if not getgenv().AutoFishingEventRunning then return end
                local nameLower = string.lower(child.Name)
                if string.find(nameLower, "cutscene") or string.find(nameLower, "secret") or string.find(nameLower, "forgotten") then
                    pcall(function()
                        child:Destroy()
                    end)
                end
            end)
            
            task.spawn(function()
                local cutsceneEvent = ReplicatedStorage:FindFirstChild("CutsceneBroadcast")
                local cutsceneConn
                if cutsceneEvent then
                    cutsceneConn = cutsceneEvent.OnClientEvent:Connect(function(catchType, pos, player)
                        if player == LocalPlayer and (catchType == "ForgottenCatch" or catchType == "SecretCatch") then
                            getgenv().IsInCutscene = true
                            DestroyGameCutscenes()
                            
                            pcall(function()
                                local rod = GetRod()
                                if rod and rod:FindFirstChild("Mechanics") then
                                    rod.Mechanics.Remotes.MiniGame:FireServer(true)
                                end
                            end)
                            
                            task.delay(0.2, function()
                                getgenv().IsInCutscene = false
                            end)
                        end
                    end)
                end
                
                while getgenv().AutoFishingEventRunning do
                    pcall(function()
                        DestroyGameCutscenes()
                        
                        if getgenv().IsInCutscene then
                            task.wait(0.05)
                            return
                        end
                        
                        local rod = GetRod()
                        if rod and rod:FindFirstChild("Mechanics") then
                            local castEvent = rod.Mechanics.Remotes.CastEvent
                            local notifyClient = rod.Mechanics.Remotes.NotifyClient
                            local miniGameEvent = rod.Mechanics.Remotes.MiniGame
                            
                            OptimizeRodSettings()
                            
                            local character = LocalPlayer.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                local hrp = character.HumanoidRootPart
                                castEvent:FireServer(false, 100, hrp.CFrame.LookVector)
                            end
                            
                            task.wait(0.05)
                            
                            local hooked = false
                            local connection
                            
                            connection = notifyClient.OnClientEvent:Connect(function(actionType, data)
                                if actionType == "Bite" and not getgenv().IsInCutscene then
                                    hooked = true
                                    if connection then
                                        connection:Disconnect()
                                        connection = nil
                                    end
                                end
                            end)
                            
                            local startTime = tick()
                            while not hooked and getgenv().AutoFishingEventRunning and not getgenv().IsInCutscene do
                                if tick() - startTime > 12 then 
                                    break 
                                end
                                task.wait(0.05)
                            end
                            
                            if connection then 
                                connection:Disconnect() 
                                connection = nil
                            end
                            
                            if hooked and getgenv().AutoFishingEventRunning and not getgenv().IsInCutscene then
                                task.wait(getgenv().BiteDelay)
                                miniGameEvent:FireServer(true)
                                task.wait(0.3)
                            end
                        else
                            task.wait(1)
                        end
                    end)
                    task.wait(0.1)
                end
                
                if cutsceneConn then cutsceneConn:Disconnect() end
                if rsConnection then rsConnection:Disconnect() end
            end)
        end
   end,
})

FishingTab:CreateSlider({
   Name = "Bite Delay (Kecepatan Tarik)",
   Range = {0.1, 2.0},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.5,
   Flag = "DelaySliderFlag",
   Callback = function(Value) getgenv().BiteDelay = Value end,
})

------------------------------------------------------------------
-- TAB 2: SUMMIT
------------------------------------------------------------------
local SummitTab = Window:CreateTab("🏔 Summit", nil)
local SummitSection = SummitTab:CreateSection("Auto Summit Farm")

getgenv().AutoSummitRunning = false
local summitCFrame = CFrame.new(-6766.44629, 1312.69983, -10083.8037, -0.993305981, 1.64907146e-08, 0.115513086, 1.58947078e-08, 1, -6.08075279e-09, -0.115513086, -4.20400115e-09, -0.993305981)
local bcCFrame = CFrame.new(-6834.84912, 1310.24744, -9902.42285, -1, 0, 0, 0, 1, 0, 0, 0, -1)

SummitTab:CreateToggle({
   Name = "Auto Summit Loop",
   CurrentValue = false,
   Flag = "AutoSummitToggle",
   Callback = function(Value) getgenv().AutoSummitRunning = Value end,
})

task.spawn(function()
    while true do
        if getgenv().AutoSummitRunning then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
            
            if humanoidRootPart then
                local checkpointFolder = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Checkpoint")
                local tpToCheckpoint = checkpointFolder and checkpointFolder:FindFirstChild("TpToCheckpoint")
                
                for i = 1, 20 do
                    if not getgenv().AutoSummitRunning then break end
                    if tpToCheckpoint then tpToCheckpoint:FireServer(i) end
                    task.wait(0.1)
                end
                
                if getgenv().AutoSummitRunning then
                    humanoidRootPart.CFrame = summitCFrame + Vector3.new(0, 5, 0)
                    task.wait(1)
                    if getgenv().AutoSummitRunning then
                        humanoidRootPart.CFrame = summitCFrame
                        task.wait(1)
                    end
                end
                
                if getgenv().AutoSummitRunning then
                    humanoidRootPart.CFrame = bcCFrame
                    task.wait(0.5)
                end
                task.wait(0.5)
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end)

------------------------------------------------------------------
-- TAB 3: PLAYER & SETTINGS
------------------------------------------------------------------
local PlayerTab = Window:CreateTab("🏃 Player", nil)
local PlayerSection = PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
   Name = "WalkSpeed Slider",
   Range = {1, 350},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "sliderws",
   Callback = function(Value) 
        pcall(function() 
            LocalPlayer.Character.Humanoid.WalkSpeed = Value 
        end) 
   end,
})

PlayerTab:CreateSlider({
   Name = "JumpPower Slider",
   Range = {1, 350},
   Increment = 1,
   Suffix = "Power",
   CurrentValue = 50,
   Flag = "sliderjp",
   Callback = function(Value) 
        pcall(function() 
            LocalPlayer.Character.Humanoid.JumpPower = Value 
        end) 
   end,
})

local SafeSection = PlayerTab:CreateSection("Safety")

PlayerTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = false,
   Flag = "AntiAFKToggle",
   Callback = function(Value)
        getgenv().AntiAFKRunning = Value
        if Value then
            Rayfield:Notify({ Title = "Anti-AFK Aktif", Content = "Anda tidak akan terkena kick karena AFK!", Duration = 3, Image = 13047715178 })
        end
   end,
})

LocalPlayer.Idled:Connect(function()
    if getgenv().AntiAFKRunning then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)
