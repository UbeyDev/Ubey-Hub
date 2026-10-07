-- ==============================================================================
-- UBEY HUB | All-in-One Hub (Supabase Fixed & Syntax Error Cleared)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Konfigurasi Supabase (Tabel: Ubey_Project, Kolom: key_value)
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co"
local SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3d3h2ZW14ZXp0Zml5dXVyaHJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzMTAwMDIsImV4cCI6MjEwNjg4NjAwMn0.IQNQXBvOHyovn-fahzGR-yAt34-72LG6dyVtUJAa92c"

-- Fungsi Validasi Key langsung ke tabel Supabase kamu
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
    
    -- Fallback lokal untuk cadangan
    if inputKey == "ubey2026" or inputKey == "UBEY_TEST" then
        isValid = true
    end
    
    return isValid
end

-- Otomatis menyalin link Discord ke clipboard perangkat
pcall(function()
    if setclipboard then
        setclipboard("https://discord.gg/TRkVMKHwzD")
    elseif toclipboard then
        toclipboard("https://discord.gg/TRkVMKHwzD")
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
SubTitle.Text = "Masukkan key dari database Supabase"
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
-- LOAD FLUENT UI UTAMA SETELAH KEY BENAR
------------------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
if not Fluent then return end

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

pcall(function()
    Fluent:SetTheme("Darker")
end)

local Tabs = {
    Fishing = Window:AddTab({ Title = "Fishing", Icon = "fish" }),
    Summit = Window:AddTab({ Title = "Summit", Icon = "mountain" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" })
}

Fluent:Notify({
    Title = "UBEY HUB Executed",
    Content = "Verifikasi Berhasil! Semua Fitur Siap Digunakan.",
    Duration = 5
})

------------------------------------------------------------------
-- TAB 1: FISHING
------------------------------------------------------------------
Tabs.Fishing:AddParagraph({
    Title = "Auto Farm Fishing",
    Content = "Pastikan joran 'Withering Rod' sudah ada di inventory atau tangan."
})

Tabs.Fishing:AddButton({
    Title = "⚡ Bypass & Fast Rod (Set 0.05s)",
    Description = "Mengubah waktu tunggu ikan dan mematikan minigame",
    Callback = function()
        OptimizeRodSettings()
        Fluent:Notify({ Title = "Berhasil", Content = "Time_before_getfish diubah ke 0.05 & MiniGame dimatikan!", Duration = 3 })
    end,
})

Tabs.Fishing:AddToggle("AutoFishToggle", {
    Title = "Smart Auto Fishing + Fast Response",
    Default = false
}):OnChanged(function(Value)
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
end)

Tabs.Fishing:AddSlider("DelaySliderFlag", {
    Title = "Bite Delay (Kecepatan Tarik)",
    Description = "Atur jeda waktu saat ikan menggigit",
    Default = 0.5,
    Min = 0.1,
    Max = 2.0,
    Rounding = 1,
}):OnChanged(function(Value)
    getgenv().BiteDelay = Value
end)

------------------------------------------------------------------
-- TAB 2: SUMMIT
------------------------------------------------------------------
Tabs.Summit:AddParagraph({
    Title = "Auto Summit Farm",
    Content = "Fitur teleportasi otomatis untuk pendakian / summit."
})

getgenv().AutoSummitRunning = false
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
Tabs.Player:AddParagraph({
    Title = "Pengaturan Karakter",
    Content = "Atur kecepatan lari, tinggi lompatan, dan keamanan anti-AFK."
})

Tabs.Player:AddSlider("sliderws", {
    Title = "WalkSpeed Slider",
    Default = 16,
    Min = 1,
    Max = 350,
    Rounding = 1,
}):OnChanged(function(Value)
    pcall(function() 
        LocalPlayer.Character.Humanoid.WalkSpeed = Value 
    end)
end)

Tabs.Player:AddSlider("sliderjp", {
    Title = "JumpPower Slider",
    Default = 50,
    Min = 1,
    Max = 350,
    Rounding = 1,
}):OnChanged(function(Value)
    pcall(function() 
        LocalPlayer.Character.Humanoid.JumpPower = Value 
    end)
end)

Tabs.Player:AddToggle("AntiAFKToggle", {
    Title = "Anti-AFK",
    Default = false
}):OnChanged(function(Value)
    getgenv().AntiAFKRunning = Value
    if Value then
        Fluent:Notify({ Title = "Anti-AFK Aktif", Content = "Anda tidak akan terkena kick karena AFK!", Duration = 3 })
    end
end)

LocalPlayer.Idled:Connect(function()
    if getgenv().AntiAFKRunning then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

Window:SelectTab(1)

------------------------------------------------------------------
-- DRAGGABLE FLOATING LOGO BUTTON
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

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = ImageButton
UIStroke.Color = Color3.fromRGB(0, 190, 255)
UIStroke.Thickness = 2

ImageButton.MouseButton1Click:Connect(function()
    pcall(function()
        Window:Minimize()
    end)
    
    TweenService:Create(ImageButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 44, 0, 44)}):Play()
    task.wait(0.1)
    TweenService:Create(ImageButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 52, 0, 52)}):Play()
end)
