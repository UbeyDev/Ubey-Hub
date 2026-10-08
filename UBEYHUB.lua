-- ==============================================================================
-- UBEY HUB | All-in-One Hub (Fishing, Location, Auto Sell Timer & NPC, Summit, dll)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- AUTO RECONNECT SYSTEM (Anti Disconnect / Sinyal Hilang)
------------------------------------------------------------------
local function SetupAutoReconnect()
    pcall(function()
        CoreGui.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" or child.Name == "DisconnectPrompt" then
                task.wait(1)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end)
            end
        end)
    end)
end
task.spawn(SetupAutoReconnect)

-- Konfigurasi Supabase
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co"
local SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3d3h2ZW14ZXp0Zml5dXVyaHJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzMTAwMDIsImV4cCI6MjEwNjg4NjAwMn0.IQNQXBvOHyovn-fahzGR-yAt34-72LG6dyVtUJAa92c"

local function validateKey(inputKey)
    local isValid = false
    pcall(function()
        local url = SUPABASE_URL .. "/rest/v1/Ubey_Project?key_value=eq." .. HttpService:UrlEncode(inputKey)
        local request = (syn and syn.request) or (http and http.request) or http_request or request
        if request then
            local res = request({
                Url = url,
                Method = "GET",
                Headers = {
                    ["apikey"] = SUPABASE_KEY,
                    ["Authorization"] = "Bearer " .. SUPABASE_KEY
                }
            })
            if res and res.StatusCode == 200 then
                local data = HttpService:JSONDecode(res.Body)
                if data and #data > 0 then
                    isValid = true
                end
            end
        end
    end)
    
    -- Menggunakan UBEY_FREE sebagai key utama/fallback
    if inputKey == "UBEY_FREE" then
        isValid = true
    end
    
    return isValid
end

-- Salin Link Discord Otomatis ke HP
pcall(function()
    if setclipboard then
        setclipboard("https://discord.gg/aCbAWe9PYB")
    elseif toclipboard then
        toclipboard("https://discord.gg/aCbAWe9PYB")
    end
end)

------------------------------------------------------------------
-- MANUAL KEY SYSTEM GUI
------------------------------------------------------------------
pcall(function()
    if CoreGui:FindFirstChild("UbeyHubKeyScreen") then
        CoreGui.UbeyHubKeyScreen:Destroy()
    end
end)

local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "UbeyHubKeyScreen"
KeyGui.Parent = CoreGui
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "KeyMain"
MainFrame.Parent = KeyGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
MainFrame.Size = UDim2.new(0, 320, 0, 220)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 0, 0, 15)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🔑 UBEY HUB | Key System"
TitleLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
TitleLabel.TextSize = 18

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = MainFrame
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, 0, 0, 45)
SubTitle.Size = UDim2.new(1, 0, 0, 25)
SubTitle.Font = Enum.Font.Gotham
SubTitle.Text = "Masukkan key di sini"
SubTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
SubTitle.TextSize = 12

local TextBox = Instance.new("TextBox")
TextBox.Parent = MainFrame
TextBox.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
TextBox.BorderSizePixel = 0
TextBox.Position = UDim2.new(0.1, 0, 0, 85)
TextBox.Size = UDim2.new(0.8, 0, 0, 40)
TextBox.Font = Enum.Font.Gotham
TextBox.PlaceholderText = "Ketik key kamu di sini..."
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
TextBox.TextSize = 14

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 8)
BoxCorner.Parent = TextBox

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Parent = MainFrame
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Position = UDim2.new(0.1, 0, 0, 140)
SubmitBtn.Size = UDim2.new(0.8, 0, 0, 40)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "SUBMIT KEY"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.TextSize = 14

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = SubmitBtn

local keyVerified = false

SubmitBtn.MouseButton1Click:Connect(function()
    local enteredKey = TextBox.Text
    SubmitBtn.Text = "MEMERIKSA..."
    if validateKey(enteredKey) then
        keyVerified = true
        KeyGui:Destroy()
    else
        SubmitBtn.Text = "SALAH / KEY TIDAK VALID!"
        SubmitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1.5)
        SubmitBtn.Text = "SUBMIT KEY"
        SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    end
end)

repeat task.wait(0.2) until keyVerified

------------------------------------------------------------------
-- LOAD FLUENT UI UTAMA
------------------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
if not Fluent then return end

-- Global State Variabel
getgenv().AutoFishingEventRunning = false
getgenv().BiteDelayInput = "0.5"
getgenv().SelectedFishingSpot = "Spot Mancing Jembatan"
getgenv().AutoSellRunning = false
getgenv().AutoSellTimerInput = "5"
getgenv().AutoGalatamaRunning = false
getgenv().AutoSummitRunning = false
getgenv().AntiAFKRunning = false
getgenv().HideNameRunning = false
getgenv().FakeNameInput = "UBEY HUB"

-- Data Koordinat Spot Mancing & NPC Penjual
local FishingSpots = {
    ["Spot Mancing Jembatan"] = CFrame.new(-6783.74756, 1322.81006, -9757.34473, 0.0899723172, -9.34088291e-08, 0.995944262, 1.76120434e-08, 1, 9.21981638e-08, -0.995944262, 9.24533072e-09, 0.0899723172),
    ["Spot Mancing Core"] = CFrame.new(-9069.33887, 1250.32092, -6510.3374, 0.99812746, -7.96398965e-08, -0.0611686334, 8.05492206e-08, 1, 1.24000188e-08, 0.0611686334, -1.73038845e-08, 0.99812746),
    ["Spot Mancing Ikan Anomali"] = CFrame.new(-8199.52832, 1238.83752, -6278.13135, -0.999144316, 1.1644854e-08, -0.0413601957, 1.63464247e-08, 1, -1.13335595e-07, 0.0413601957, -1.13914709e-07, -0.999144316)
}

local NpcSellCFrame = CFrame.new(-6668.01416, 1312.69983, -9965.2998, 0.999977231, 1.08366018e-08, -0.00675115408, -1.09201403e-08, 1, -1.2337189e-08, 0.00675115408, 1.24106316e-08, 0.999977231)

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
                if timeSetting then timeSetting.Value = 0.05 end
                local enableMiniGame = settingsFolder:FindFirstChild("EnableMiniGame")
                if enableMiniGame then enableMiniGame.Value = false end
            end
        end
    end)
end

local function TriggerSellToNpc()
    pcall(function()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local currentSpotCFrame = hrp.CFrame
        hrp.CFrame = NpcSellCFrame
        task.wait(0.8)
        
        local mancing = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Mancing")
        local jualSemua = mancing and mancing:FindFirstChild("JualSemua")
        if jualSemua then
            jualSemua:InvokeServer()
        end
        task.wait(0.8)
        
        if getgenv().AutoFishingEventRunning then
            hrp.CFrame = currentSpotCFrame
        end
    end)
end

local Window = Fluent:CreateWindow({
    Title = "🔥 UBEY HUB | All-in-One Hub 🚀",
    SubTitle = "by Ubey",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl,
    Logo = "rbxassetid://90770802417381"
})

pcall(function() Fluent:SetTheme("Darker") end)

local Tabs = {
    Fishing = Window:AddTab({ Title = "Fishing & Sell", Icon = "fish" }),
    Galatama = Window:AddTab({ Title = "Galatama", Icon = "trophy" }),
    Summit = Window:AddTab({ Title = "Summit", Icon = "mountain" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Privacy = Window:AddTab({ Title = "Privacy", Icon = "shield" })
}

Fluent:Notify({ Title = "UBEY HUB Executed", Content = "Verifikasi Berhasil! Siap Digunakan.", Duration = 4 })

------------------------------------------------------------------
-- TAB 1: FISHING
------------------------------------------------------------------
Tabs.Fishing:AddParagraph({
    Title = "Auto Farm Fishing & Location",
    Content = "Pilih lokasi lalu gunakan tombol teleport atau mancing biasa di tempat."
})

Tabs.Fishing:AddDropdown("FishingSpotDropdown", {
    Title = "Pilih Lokasi Mancing",
    Values = {"Spot Mancing Jembatan", "Spot Mancing Core", "Spot Mancing Ikan Anomali"},
    Default = 1,
}):OnChanged(function(Value)
    getgenv().SelectedFishingSpot = Value
end)

Tabs.Fishing:AddButton({
    Title = "⚡ Bypass & Fast Rod (Set 0.05s)",
    Description = "Mengubah waktu tunggu ikan dan mematikan minigame",
    Callback = function()
        OptimizeRodSettings()
        Fluent:Notify({ Title = "Berhasil", Content = "Pengaturan joran dioptimalkan!", Duration = 3 })
    end,
})

Tabs.Fishing:AddToggle("AutoFishTeleportToggle", {
    Title = "Smart Auto Fishing + Teleport Spot",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoFishingEventRunning = Value
    if Value then
        pcall(function()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            local targetCFrame = FishingSpots[getgenv().SelectedFishingSpot]
            if hrp and targetCFrame then
                hrp.CFrame = targetCFrame
                Fluent:Notify({ Title = "Teleportasi", Content = "Berpindah ke " .. getgenv().SelectedFishingSpot, Duration = 3 })
            end
        end)
        
        OptimizeRodSettings()
        task.spawn(function()
            while getgenv().AutoFishingEventRunning do
                pcall(function()
                    local rod = GetRod()
                    if rod and rod:FindFirstChild("Mechanics") then
                        local castEvent = rod.Mechanics.Remotes.CastEvent
                        local notifyClient = rod.Mechanics.Remotes.NotifyClient
                        local miniGameEvent = rod.Mechanics.Remotes.MiniGame
                        
                        OptimizeRodSettings()
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        castEvent:FireServer(false, 100, hrp.CFrame.LookVector)
                        
                        task.wait(0.05)
                        local hooked = false
                        local conn
                        conn = notifyClient.OnClientEvent:Connect(function(actionType)
                            if actionType == "Bite" then
                                hooked = true
                                if conn then conn:Disconnect() end
                            end
                        end)
                        
                        local start = tick()
                        while not hooked and getgenv().AutoFishingEventRunning do
                            if tick() - start > 10 then break end
                            task.wait(0.05)
                        end
                        if conn then conn:Disconnect() end
                        
                        if hooked and getgenv().AutoFishingEventRunning then
                            local currentDelay = tonumber(getgenv().BiteDelayInput) or 0.5
                            task.wait(currentDelay)
                            miniGameEvent:FireServer(true)
                            task.wait(0.3)
                        end
                    else
                        task.wait(1)
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

Tabs.Fishing:AddToggle("AutoFishNormalToggle", {
    Title = "Smart Auto Fishing (Di Tempat Saja)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoFishingEventRunning = Value
    if Value then
        OptimizeRodSettings()
        task.spawn(function()
            while getgenv().AutoFishingEventRunning do
                pcall(function()
                    local rod = GetRod()
                    if rod and rod:FindFirstChild("Mechanics") then
                        local castEvent = rod.Mechanics.Remotes.CastEvent
                        local notifyClient = rod.Mechanics.Remotes.NotifyClient
                        local miniGameEvent = rod.Mechanics.Remotes.MiniGame
                        
                        OptimizeRodSettings()
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        castEvent:FireServer(false, 100, hrp.CFrame.LookVector)
                        
                        task.wait(0.05)
                        local hooked = false
                        local conn
                        conn = notifyClient.OnClientEvent:Connect(function(actionType)
                            if actionType == "Bite" then
                                hooked = true
                                if conn then conn:Disconnect() end
                            end
                        end)
                        
                        local start = tick()
                        while not hooked and getgenv().AutoFishingEventRunning do
                            if tick() - start > 10 then break end
                            task.wait(0.05)
                        end
                        if conn then conn:Disconnect() end
                        
                        if hooked and getgenv().AutoFishingEventRunning then
                            local currentDelay = tonumber(getgenv().BiteDelayInput) or 0.5
                            task.wait(currentDelay)
                            miniGameEvent:FireServer(true)
                            task.wait(0.3)
                        end
                    else
                        task.wait(1)
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

Tabs.Fishing:AddInput("BiteDelayInputBox", {
    Title = "Bite Delay (Ketik Angka Detik)",
    Default = "0.5",
    Placeholder = "Contoh: 0.5 atau 0.2",
    Numeric = true,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().BiteDelayInput = Value
end)

Tabs.Fishing:AddSection("Pengaturan Auto Sell (Timer ke NPC)")

Tabs.Fishing:AddToggle("AutoSellToggle", {
    Title = "Aktifkan Auto Sell Timer ke NPC",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoSellRunning = Value
    if Value then
        task.spawn(function()
            local lastSellTime = tick()
            while getgenv().AutoSellRunning do
                task.wait(1)
                local elapsedMinutes = (tick() - lastSellTime) / 60
                local targetMinutes = tonumber(getgenv().AutoSellTimerInput) or 5
                
                if elapsedMinutes >= targetMinutes then
                    TriggerSellToNpc()
                    lastSellTime = tick()
                    Fluent:Notify({ Title = "Auto Sell (Timer)", Content = "Menjual ikan berkala ke NPC (" .. tostring(targetMinutes) .. " menit)!", Duration = 4 })
                end
            end
        end)
    end
end)

Tabs.Fishing:AddInput("SellTimerInputBox", {
    Title = "Jeda Waktu Timer (Ketik Menit)",
    Default = "5",
    Placeholder = "Contoh: 5 atau 10",
    Numeric = true,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().AutoSellTimerInput = Value
end)

------------------------------------------------------------------
-- TAB 2: GALATAMA
------------------------------------------------------------------
Tabs.Galatama:AddParagraph({
    Title = "Auto Event Galatama",
    Content = "Otomatis ikut serta / klik gabung saat event perlombaan ikan Galatama dimulai."
})

Tabs.Galatama:AddToggle("AutoGalatamaToggle", {
    Title = "Aktifkan Auto Join Galatama",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoGalatamaRunning = Value
    if Value then
        task.spawn(function()
            while getgenv().AutoGalatamaRunning do
                pcall(function()
                    local glatamaFolder = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Glatama")
                    local ikutRemote = glatamaFolder and glatamaFolder:FindFirstChild("Ikut")
                    
                    if ikutRemote then
                        local success, res1, res2 = pcall(function()
                            return ikutRemote:InvokeServer()
                        end)
                        
                        if success and res1 == true then
                            Fluent:Notify({
                                Title = "Galatama Berhasil!",
                                Content = "Berhasil bergabung ke event Galatama (" .. tostring(res2) .. ")!",
                                Duration = 4
                            })
                        end
                    end
                end)
                task.wait(10)
            end
        end)
    end
end)

------------------------------------------------------------------
-- TAB 3: SUMMIT
------------------------------------------------------------------
Tabs.Summit:AddParagraph({
    Title = "Auto Summit Farm",
    Content = "Fitur teleportasi otomatis untuk pendakian / summit."
})

local summitCFrame = CFrame.new(-6766.44629, 1312.69983, -10083.8037, -0.993305981, 1.64907146e-08, 0.115513086, 1.58947078e-08, 1, -6.08075279e-09, -0.115513086, -4.20400115e-09, -0.993305981)
local bcCFrame = CFrame.new(-6834.84912, 1310.24744, -9902.42285, -1, 0, 0, 0, 1, 0, 0, 0, -1)

Tabs.Summit:AddToggle("AutoSummitToggle", {
    Title = "Auto Summit Loop",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoSummitRunning = Value
end)

task.spawn(function()
    while true do
        if getgenv().AutoSummitRunning then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                local cpFolder = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Checkpoint")
                local tpCP = cpFolder and cpFolder:FindFirstChild("TpToCheckpoint")
                for i = 1, 20 do
                    if not getgenv().AutoSummitRunning then break end
                    if tpCP then tpCP:FireServer(i) end
                    task.wait(0.1)
                end
                if getgenv().AutoSummitRunning then
                    hrp.CFrame = summitCFrame
                    task.wait(1)
                end
                if getgenv().AutoSummitRunning then
                    hrp.CFrame = bcCFrame
                    task.wait(0.5)
                end
            end
            task.wait(0.5)
        else
            task.wait(0.5)
        end
    end
end)

------------------------------------------------------------------
-- TAB 4: PLAYER
------------------------------------------------------------------
Tabs.Player:AddParagraph({
    Title = "Pengaturan Karakter",
    Content = "Atur kecepatan lari dan anti-AFK."
})

Tabs.Player:AddSlider("sliderws", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 1,
    Max = 350,
    Rounding = 1,
}):OnChanged(function(Value)
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = Value end)
end)

Tabs.Player:AddToggle("AntiAFKToggle", {
    Title = "Anti-AFK",
    Default = false
}):OnChanged(function(Value)
    getgenv().AntiAFKRunning = Value
end)

LocalPlayer.Idled:Connect(function()
    if getgenv().AntiAFKRunning then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

------------------------------------------------------------------
-- TAB 5: PRIVACY
------------------------------------------------------------------
Tabs.Privacy:AddParagraph({
    Title = "Privacy & Content Creator Mode",
    Content = "Samarkan namamu dan sembunyikan label total summit di atas kepala saat merekam video."
})

Tabs.Privacy:AddInput("FakeNameInputBox", {
    Title = "Nama Samaran (Fake Name)",
    Default = "UBEY HUB",
    Placeholder = "Ketik nama samaran...",
    Numeric = false,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().FakeNameInput = Value
end)

Tabs.Privacy:AddToggle("HideNameToggle", {
    Title = "Aktifkan Privacy Mode (Hide Name & Summit)",
    Default = false
}):OnChanged(function(Value)
    getgenv().HideNameRunning = Value
    if Value then
        task.spawn(function()
            while getgenv().HideNameRunning do
                pcall(function()
                    local fakeName = getgenv().FakeNameInput or "UBEY HUB"
                    local character = LocalPlayer.Character
                    if character then
                        local head = character:FindFirstChild("Head")
                        if head then
                            for _, child in ipairs(head:GetDescendants()) do
                                if child:IsA("TextLabel") or child:IsA("TextMesh") then
                                    local txt = child.Text
                                    if string.find(txt, LocalPlayer.Name) or string.find(txt, LocalPlayer.DisplayName) then
                                        child.Text = fakeName
                                    elseif string.find(string.lower(txt), "summit") or (tonumber(txt) ~= nil and tonumber(txt) > 0) then
                                        child.Text = ""
                                    end
                                end
                            end
                        end
                        
                        for _, descendant in ipairs(character:GetDescendants()) do
                            if descendant:IsA("BillboardGui") then
                                for _, lbl in ipairs(descendant:GetDescendants()) do
                                    if lbl:IsA("TextLabel") then
                                        local txt = lbl.Text
                                        if string.find(txt, LocalPlayer.Name) or string.find(txt, LocalPlayer.DisplayName) then
                                            lbl.Text = fakeName
                                        elseif string.find(string.lower(txt), "summit") or (tonumber(txt) and tonumber(txt) > 5) then
                                            lbl.Text = ""
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if PlayerGui then
                        for _, gui in ipairs(PlayerGui:GetDescendants()) do
                            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                                local txt = gui.Text
                                if string.find(txt, LocalPlayer.Name) or string.find(txt, LocalPlayer.DisplayName) then
                                    gui.Text = string.gsub(gui.Text, LocalPlayer.DisplayName, fakeName)
                                    gui.Text = string.gsub(gui.Text, LocalPlayer.Name, fakeName)
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

Window:SelectTab(1)

------------------------------------------------------------------
-- FLOATING LOGO BUTTON
------------------------------------------------------------------
pcall(function()
    if CoreGui:FindFirstChild("UbeyHubFloatingLogo") then
        CoreGui.UbeyHubFloatingLogo:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UbeyHubFloatingLogo"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ImageButton = Instance.new("ImageButton")
ImageButton.Name = "LogoButton"
ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
ImageButton.BorderColor3 = Color3.fromRGB(0, 170, 255)
ImageButton.BorderSizePixel = 3
ImageButton.Position = UDim2.new(0.05, 0, 0.15, 0)
ImageButton.Size = UDim2.new(0, 52, 0, 52)
ImageButton.Image = "rbxassetid://90770802417381"
ImageButton.Active = true
ImageButton.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.5, 0)
UICorner.Parent = ImageButton

ImageButton.MouseButton1Click:Connect(function()
    pcall(function() Window:Minimize() end)
end)
