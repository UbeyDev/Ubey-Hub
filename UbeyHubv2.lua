-- ==============================================================================
-- UBEY HUB | All-in-One Farm & Utility Hub (Custom GUI & Supabase Key System)
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Konfigurasi Supabase
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co"
local SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3d3h2ZW14ZXp0Zml5dXVyaHJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzMTAwMDIsImV4cCI6MjEwNjg4NjAwMn0.IQNQXBvOHyovn-fahzGR-yAt34-72LG6dyVtUJAa92c"

-- Fungsi Validasi Key ke Supabase
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
    
    -- Fallback lokal untuk cadangan/pengujian
    if inputKey == "UBEY_FREE" or inputKey == "" then
        isValid = true
    end
    
    return isValid
end

-- Salin Link Discord Otomatis ke Clipboard HP
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
SubTitle.Text = "Masukkan Key Di Sini"
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
-- MULAI FITUR UTAMA GAME KEBUN & FARM
------------------------------------------------------------------
-- Remote Events (Sawah)
local SeedShopRemotes = ReplicatedStorage:WaitForChild("SeedShopRemotes", 5)
local BuySeedEvent = SeedShopRemotes and SeedShopRemotes:WaitForChild("BuySeed", 5)
local PlantEvent = ReplicatedStorage:WaitForChild("PlantEvent", 5)
local PlantActionEvent = ReplicatedStorage:WaitForChild("PlantActionEvent", 5)
local SellEvent = ReplicatedStorage:WaitForChild("SellEvent", 5)

-- Remote Events (Mining System)
local MiningRemotes = ReplicatedStorage:WaitForChild("MiningSystemRemotes", 5)
local MiningStartRequest = MiningRemotes and MiningRemotes:WaitForChild("MiningStartRequest", 5)
local MiningActionEvent = MiningRemotes and MiningRemotes:WaitForChild("MiningActionEvent", 5)

-- Remote Event (Chicken Catch)
local ChickenRemotes = ReplicatedStorage:WaitForChild("ChickenCatchRemotes", 5)
local SwingNetEvent = ChickenRemotes and ChickenRemotes:WaitForChild("SwingNet", 5)

-- Remote Events & Folders (Butterfly / Kupu-Kupu)
local ButterflyRemotes = ReplicatedStorage:WaitForChild("VillageButterflies", 5)
local CatchButterflyEvent = ButterflyRemotes and ButterflyRemotes:WaitForChild("Catch", 5)

-- Remote Events (Fishing System)
local FishingRemotes = ReplicatedStorage:WaitForChild("FishingSystemRemotes", 5)
local FishingActionEvent = FishingRemotes and FishingRemotes:WaitForChild("Action", 5)
local FishingPhaseEvent = FishingRemotes and FishingRemotes:WaitForChild("Phase", 5)

-- Konfigurasi Default & Pilihan Bibit
getgenv().SelectedSeed = "Matahari"
getgenv().AutoSellInterval = 5
getgenv().AutoSellChickenInterval = 5
getgenv().AutoSellButterflyInterval = 5
local SawahModel = Workspace:WaitForChild("Sawah", 5)
local MAX_PLANTS = 30

-- Koordinat Sawah, Water, Fishing Spot & Tempat Jual Baru
local PlantPosition = Vector3.new(-15.134395599365234, 10.973939895629883, -473.38986206054688)
local WaterPosition = Vector3.new(-15.134395599365234, 13.673937797546387, -473.38986206054688)
local FishingCastTarget = Vector3.new(-92.823776245117188, 8, -305.47808837890625)
local FishingTeleportSpot = CFrame.new(-95.3258133, 12.2262278, -296.833588, 0.758470535, -7.62254473e-08, -0.651707351, -8.10995271e-09, 1, -1.26401218e-07, 0.651707351, 1.01156921e-07, 0.758470535)

local SellCFrame = CFrame.new(
    -6.58236408, 12.9271421, -407.487854, 
    0.0403795838, 3.357815e-08, 0.99918443, 
    2.3621336e-08, 1, -3.45601556e-08, 
    -0.99918443, 2.49975951e-08, 0.0403795838
)

local MiningSellCFrame = CFrame.new(-206.505844, 12.6999979, -433.204315, 0.969809055, 1.57811968e-08, 0.24386552, -2.09505693e-08, 1, 1.8603922e-08, -0.24386552, -2.31513742e-08, 0.969809055)
local ChickenSellCFrame = CFrame.new(107.542999, 12.9384336, -357.577332, -0.998321295, -1.01971223e-08, -0.0579189435, -9.84405624e-09, 1, -6.38118003e-09, 0.0579189435, -5.80031045e-09, -0.998321295)
local ButterflySellCFrame = CFrame.new(87.4784622, 12.9384327, -357.32486, -0.997522354, -7.31812833e-10, 0.0703499094, -3.4165476e-10, 1, 5.55799673e-09, -0.0703499094, 5.52019097e-09, -0.997522354)
local MilkSellCFrame = CFrame.new(82.8893051, 23.2939873, -676.127625, 0.999944627, -1.16198784e-07, 0.0105238697, 1.15764458e-07, 1, 4.18796802e-08, -0.0105238697, -4.06590708e-08, 0.999944627)

local MiningLocations = {
    ["Batu Bara 1"] = CFrame.new(-395.596588, 33.9701958, -535.331848, -0.234104395, 0.819247544, 0.523477435, 0.961516201, 0.274748325, 1.58250332e-05, -0.143811569, 0.503335714, -0.852039576),
    ["Diamond"] = CFrame.new(-378.382233, 29.6900635, -551.896606, -0.816186666, 0.518062115, 0.255834013, 0.577788353, 0.731835961, 0.361354053, -2.46763229e-05, 0.442750275, -0.89664495),
    ["Gold"] = CFrame.new(-340.845306, 34.2572861, -635.2724, 0.235785246, 0.66882515, 0.705037773, 0.23444663, 0.6649158, -0.709169805, -0.943101346, 0.332505524, -2.64644623e-05),
    ["Batubara 2"] = CFrame.new(-304.255035, 26.3019257, -662.946533, -0.821258426, -0.0497378074, 0.568384886, -0.0604742579, 0.99816978, -3.20263207e-05, -0.567342997, -0.0343989469, -0.822763205)
}

local MiningOrderList = {"Batu Bara 1", "Diamond", "Gold", "Batubara 2"}
getgenv().SelectedMiningZone = "Batu Bara 1"
getgenv().AutoLoopMining = false
getgenv().MiningTimerDuration = 3 
getgenv().AntiSitEnabled = false
getgenv().AntiAfkEnabled = false

getgenv().AutoBuyRunning = false
getgenv().AutoFarmRunning = false
getgenv().AutoSellRunning = false
getgenv().AutoSellMiningRunning = false
getgenv().AutoSellMiningInterval = 5
getgenv().AutoSellChickenRunning = false
getgenv().AutoSellButterflyRunning = false
getgenv().AutoSellMilkRunning = false

getgenv().AutoCatchChickenRunning = false
getgenv().AutoCatchButterflyRunning = false
getgenv().AutoMineRunning = false
getgenv().AutoFeedAnimalRunning = false
getgenv().AutoCollectMilkRunning = false
getgenv().AutoFishingRunning = false

local IsFarmBusy = false
local IsMiningBusy = false
local IsCatchBusy = false
getgenv().IsKandangBusy = false

local CurrentFishingSession = nil
local CurrentFishingPhase = "Idle"

local function SafeTeleport(targetCFrame)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = targetCFrame
        task.wait(0.05)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

local function TeleportToSawah()
    SafeTeleport(CFrame.new(PlantPosition + Vector3.new(0, 3, 0)))
end

local function ExecuteSell()
    if not SellEvent then return end
    pcall(function()
        SafeTeleport(SellCFrame)
        task.wait(0.3)
        SellEvent:FireServer("ALL")
        task.wait(0.2)
        SellEvent:FireServer("SellAll")
        task.wait(0.2)
        SellEvent:FireServer()
    end)
end

local function ExecuteMiningSell()
    pcall(function()
        SafeTeleport(MiningSellCFrame)
        task.wait(0.5)
        local tokoModel = Workspace:FindFirstChild("Toko Jual Hasil Tambang")
        if tokoModel then
            local prompt = tokoModel:FindFirstChild("MiningSellPrompt", true)
            if prompt and prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt)
                task.wait(0.5)
                fireproximityprompt(prompt)
            end
        else
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "MiningSellPrompt" and obj:IsA("ProximityPrompt") then
                    fireproximityprompt(obj)
                    task.wait(0.5)
                    fireproximityprompt(obj)
                    break
                end
            end
        end
    end)
end

local function ExecuteChickenSell()
    pcall(function()
        SafeTeleport(ChickenSellCFrame)
        task.wait(0.5)
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and (prompt.Name:lower():find("chicken") or prompt.Name:lower():find("ayam") or prompt.Name:lower():find("sell")) then
                local dist = (prompt.Parent:GetPivot().Position - ChickenSellCFrame.Position).Magnitude
                if dist < 15 then
                    fireproximityprompt(prompt)
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                    break
                end
            end
        end
    end)
end

local function ExecuteButterflySell()
    pcall(function()
        SafeTeleport(ButterflySellCFrame)
        task.wait(0.5)
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and (prompt.Name:lower():find("butterfly") or prompt.Name:lower():find("kupu") or prompt.Name:lower():find("sell")) then
                local dist = (prompt.Parent:GetPivot().Position - ButterflySellCFrame.Position).Magnitude
                if dist < 15 then
                    fireproximityprompt(prompt)
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                    break
                end
            end
        end
    end)
end

local function ExecuteMilkSell()
    pcall(function()
        SafeTeleport(MilkSellCFrame)
        task.wait(0.8)
        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local targetPrompt = nil
        local shortestDist = 20
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local parentPart = prompt.Parent
                if parentPart then
                    local parentPos = parentPart:IsA("BasePart") and parentPart.Position or (parentPart:IsA("Model") and parentPart:GetPivot().Position)
                    if parentPos then
                        local dist = (rootPart.Position - parentPos).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            targetPrompt = prompt
                        end
                    end
                end
            end
        end
        if targetPrompt then
            fireproximityprompt(targetPrompt)
            task.wait(0.4)
            fireproximityprompt(targetPrompt)
        end
    end)
end

local function CountSeedInInventory()
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    local function checkContainer(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local itemName = item.Name:lower()
                local selectedLower = getgenv().SelectedSeed:lower()
                if itemName:find(selectedLower) or itemName:find("bibit") then
                    local stack = item:GetAttribute("JumlahBibit") or item:GetAttribute("Amount") or item:GetAttribute("Count") or item:GetAttribute("Stok")
                    if not stack then
                        local numFromBracket = item.Name:match("%((%d+)%)")
                        if numFromBracket then stack = tonumber(numFromBracket) end
                    end
                    if not stack then
                        local numFromName = tonumber(item.Name:match("%d+"))
                        if numFromName then stack = numFromName end
                    end
                    count = count + (stack or 0)
                end
            end
        end
    end
    checkContainer(backpack)
    checkContainer(character)
    return count
end

local function CountActivePlants()
    local count = 0
    local targetReadyName = getgenv().SelectedSeed .. "_Ready"
    local targetNormalName = getgenv().SelectedSeed
    for _, Object in ipairs(Workspace:GetDescendants()) do
        if Object and Object.Parent and (Object.Name == targetReadyName or Object.Name == targetNormalName or Object.Name:match(getgenv().SelectedSeed)) then
            count = count + 1
        end
    end
    return count
end

local function CountReadyPlants()
    local count = 0
    local targetReadyName = getgenv().SelectedSeed .. "_Ready"
    for _, Object in ipairs(Workspace:GetDescendants()) do
        if Object and Object.Parent and Object.Name == targetReadyName then
            if Object:IsA("BasePart") or (Object:IsA("Model") and Object.PrimaryPart) then
                count = count + 1
            end
        end
    end
    return count
end

local function FindReadyPlant()
    local targetReadyName = getgenv().SelectedSeed .. "_Ready"
    for _, Object in ipairs(Workspace:GetDescendants()) do
        if Object and Object.Parent and Object.Name == targetReadyName then
            if Object:IsA("BasePart") or (Object:IsA("Model") and Object.PrimaryPart) then
                return Object
            end
        end
    end
    return nil
end

local function FindNearestChicken()
    local chickenFolder = Workspace:FindFirstChild("ChickenCatchSystem") and Workspace.ChickenCatchSystem:FindFirstChild("AyamBerkeliaran")
    if not chickenFolder then return nil end
    local closestChicken = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    for _, chicken in ipairs(chickenFolder:GetChildren()) do
        local targetPart = chicken:IsA("Model") and (chicken.PrimaryPart or chicken:FindFirstChildWhichIsA("BasePart"))
        if targetPart then
            local distance = (rootPart.Position - targetPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestChicken = chicken
            end
        end
    end
    return closestChicken
end

local function FindNearestButterfly()
    local visualsFolder = Workspace:FindFirstChild("ButterflyVisuals")
    if not visualsFolder then return nil end
    local closestButterfly = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    for _, bfly in ipairs(visualsFolder:GetChildren()) do
        local targetPart = bfly:IsA("Model") and (bfly.PrimaryPart or bfly:FindFirstChildWhichIsA("BasePart")) or (bfly:IsA("BasePart") and bfly)
        if targetPart then
            local distance = (rootPart.Position - targetPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestButterfly = bfly
            end
        end
    end
    return closestButterfly
end

local function FindOreNearCFrame(targetPos)
    local miningSystem = Workspace:FindFirstChild("MiningSystem")
    if not miningSystem then return nil, math.huge end
    local closestOre = nil
    local shortestDistance = math.huge
    for _, child in ipairs(miningSystem:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            for _, ore in ipairs(child:GetChildren()) do
                local targetPart = ore:IsA("Model") and (ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")) or (ore:IsA("BasePart") and ore)
                if targetPart then
                    local distance = (targetPos - targetPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestOre = ore
                    end
                end
            end
        end
    end
    return closestOre, shortestDistance
end

local function AutoEquipNet()
    pcall(function()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not char or not backpack then return end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and (currentTool.Name:match("Jaring") or currentTool.Name:match("Net")) then return end
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:match("Jaring") or item.Name:match("Net")) then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid:EquipTool(item) end
                break
            end
        end
    end)
end

local function TouchTargetWithTool(targetPart)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local currentTool = nil
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") and (child.Name:match("Jaring") or child.Name:match("Net")) then
                currentTool = child
                break
            end
        end
        local toolPart = currentTool and (currentTool:FindFirstChild("Handle") or currentTool:FindFirstChildWhichIsA("BasePart"))
        if toolPart and targetPart and targetPart:IsA("BasePart") then
            toolPart.CFrame = targetPart.CFrame
            firetouchinterest(toolPart, targetPart, 0)
            firetouchinterest(toolPart, targetPart, 1)
        end
    end)
end

local function AutoEquipPickaxe()
    pcall(function()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not char or not backpack then return end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and (currentTool.Name:lower():find("alat") or currentTool.Name:lower():find("pickaxe") or currentTool.Name:lower():find("diamond")) then return end
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local nameLower = item.Name:lower()
                if nameLower:find("alat") or nameLower:find("pickaxe") or nameLower:find("diamond") or nameLower:find("batu") then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid:EquipTool(item) end
                    return
                end
            end
        end
    end)
end

local function AutoEquipFishingRod()
    pcall(function()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not char or not backpack then return end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and (currentTool.Name:lower():find("pancing") or currentTool.Name:lower():find("rod") or currentTool.Name:lower():find("fiber") or currentTool.Name:lower():find("bambu")) then return end
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local nameLower = item.Name:lower()
                if nameLower:find("pancing") or nameLower:find("rod") or nameLower:find("fiber") or nameLower:find("bambu") or nameLower:find("carbon") then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid:EquipTool(item) end
                    return
                end
            end
        end
    end)
end

local function AutoEquipEmber()
    pcall(function()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not char or not backpack then return end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and currentTool.Name:lower():find("prem") then return end
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local nameLower = item.Name:lower()
                if nameLower:find("ember") and (nameLower:find("prem") or nameLower:find("premium")) then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid:EquipTool(item) end
                    return
                end
            end
        end
    end)
end

local function AutoRefillWater()
    pcall(function()
        local sumurModel = Workspace:FindFirstChild("SUMUR")
        if not sumurModel then return end
        local targetPrompt = sumurModel:FindFirstChildWhichIsA("ProximityPrompt", true)
        if targetPrompt and targetPrompt.Parent then
            local promptPart = targetPrompt.Parent
            local targetPos = promptPart:IsA("BasePart") and promptPart.Position or (promptPart:IsA("Model") and promptPart.PrimaryPart.Position)
            if targetPos then
                SafeTeleport(CFrame.new(targetPos + Vector3.new(2, 2, 0)))
                task.wait(0.4)
                AutoEquipEmber()
                task.wait(0.3)
                fireproximityprompt(targetPrompt)
                task.wait(0.8)
            end
        end
    end)
end

local function TriggerCowBarnPrompt(promptName)
    pcall(function()
        local cowBarns = Workspace:FindFirstChild("CowBarns")
        if not cowBarns then return end
        local myBarn = nil
        local myName = LocalPlayer.Name:lower()
        local myDisplayName = LocalPlayer.DisplayName:lower()
        for _, barn in ipairs(cowBarns:GetChildren()) do
            for _, descendant in ipairs(barn:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("StringValue") or descendant:IsA("TextButton") then
                    local textVal = tostring(descendant.Text or descendant.Value):lower()
                    if textVal:find(myName) or textVal:find(myDisplayName) then
                        myBarn = barn
                        break
                    end
                end
            end
            if myBarn then break end
        end
        if not myBarn then
            for _, barn in ipairs(cowBarns:GetChildren()) do
                for _, descendant in ipairs(barn:GetDescendants()) do
                    if descendant.Name:lower():find("sapi") or descendant.Name:lower():find("hewan") or descendant.Name:lower():find("cow") then
                        myBarn = barn
                        break
                    end
                end
                if myBarn then break end
            end
        end
        if myBarn then
            local targetPrompt = myBarn:FindFirstChild(promptName, true)
            if targetPrompt and targetPrompt:IsA("ProximityPrompt") then
                local parentPart = targetPrompt.Parent
                if parentPart then
                    local targetPos = parentPart:IsA("BasePart") and parentPart.Position or (parentPart:IsA("Model") and parentPart:GetPivot().Position)
                    if targetPos then
                        SafeTeleport(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
                        task.wait(0.4)
                        fireproximityprompt(targetPrompt)
                        task.wait(0.3)
                        fireproximityprompt(targetPrompt)
                    end
                end
            end
        end
    end)
end

if FishingPhaseEvent then
    FishingPhaseEvent.OnClientEvent:Connect(function(data)
        if typeof(data) == "table" and data.Phase then
            CurrentFishingPhase = data.Phase
            if data.SessionId then
                CurrentFishingSession = data.SessionId
            end
            if data.Phase == "Caught" or data.Phase == "Success" or data.Phase == "Failed" then
                task.delay(1.5, function()
                    if getgenv().AutoFishingRunning then
                        CurrentFishingPhase = "Idle"
                        CurrentFishingSession = nil
                    end
                end)
            end
        end
    end)
end

------------------------------------------------------------------
-- MEMUAT FLUENT UI UTAMA
------------------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
if not Fluent then return end

local Window = Fluent:CreateWindow({
    Title = "🔥 UBEY HUB | Kebun Hangout & Farm 🚀",
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
    Farm = Window:AddTab({ Title = "Farm Sawah🌾", Icon = "flower" }),
    Mining = Window:AddTab({ Title = "Auto Mining", Icon = "hammer" }),
    Fishing = Window:AddTab({ Title = "Auto Fishing", Icon = "fish" }),
    Catch = Window:AddTab({ Title = "Auto Catch", Icon = "bug" }),
    Kandang = Window:AddTab({ Title = "Peternakan", Icon = "milk" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" })
}

Fluent:Notify({ Title = "UBEY HUB Executed", Content = "Verifikasi Berhasil! Siap Digunakan.", Duration = 4 })

------------------------------------------------------------------
-- TAB 1: FARM SAWAH
------------------------------------------------------------------
Tabs.Farm:AddParagraph({
    Title = "Farming Sawah",
    Content = "Pilih jenis bibit lalu aktifkan auto buy dan auto farm."
})

Tabs.Farm:AddDropdown("SeedDropdown", {
    Title = "Pilih Jenis Bibit",
    Values = {"Matahari", "Padi", "Tomat", "Jagung", "Wortel", "Pisang"},
    Default = 1,
}):OnChanged(function(Value)
    getgenv().SelectedSeed = Value
end)

Tabs.Farm:AddToggle("AutoBuyToggle", {
    Title = "Auto Buy Seed",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoBuyRunning = Value
end)

Tabs.Farm:AddToggle("AutoFarmToggle", {
    Title = "🚀 Auto Farm",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoFarmRunning = Value
    if not Value then IsFarmBusy = false end
    if Value then TeleportToSawah() end
end)

Tabs.Farm:AddSection("Auto Sell Sawah")

Tabs.Farm:AddToggle("AutoSellToggle", {
    Title = "💰 Aktifkan Auto Sell Dengan Waktu",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoSellRunning = Value
end)

Tabs.Farm:AddInput("SellTimerInputBox", {
    Title = "⏱️ Waktu (Menit)",
    Default = "5",
    Placeholder = "Contoh: 5",
    Numeric = true,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().AutoSellInterval = tonumber(Value) or 5
end)

------------------------------------------------------------------
-- TAB 2: MINING
------------------------------------------------------------------
Tabs.Mining:AddParagraph({
    Title = "Pengaturan Lokasi Tambang",
    Content = "Pilih lokasi atau aktifkan auto pindah lokasi tambang."
})

Tabs.Mining:AddDropdown("MiningDropdown", {
    Title = "Pilih Lokasi Tambang",
    Values = {"Batu Bara 1", "Diamond", "Gold", "Batubara 2"},
    Default = 1,
}):OnChanged(function(Value)
    getgenv().SelectedMiningZone = Value
end)

Tabs.Mining:AddToggle("AutoLoopMiningToggle", {
    Title = "🔄 Auto Berpindah Lokasi",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoLoopMining = Value
end)

Tabs.Mining:AddInput("MiningTimerInputBox", {
    Title = "Durasi Waktu Per Lokasi (Detik)",
    Default = "3",
    Placeholder = "Contoh: 3",
    Numeric = true,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().MiningTimerDuration = tonumber(Value) or 3
end)

Tabs.Mining:AddButton({
    Title = "📍 Teleport Instan ke Lokasi Tambang Terpilih",
    Callback = function()
        pcall(function()
            local targetCF = MiningLocations[getgenv().SelectedMiningZone]
            if targetCF then SafeTeleport(targetCF) end
        end)
    end,
})

Tabs.Mining:AddSection("Sistem Auto Mining")

Tabs.Mining:AddToggle("AutoMineToggle", {
    Title = "Auto Mining",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoMineRunning = Value
end)

Tabs.Mining:AddSection("💎 Auto Sell Hasil Tambang")

Tabs.Mining:AddToggle("AutoSellMiningToggle", {
    Title = "💰 Auto Sell Hasil Tambang",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoSellMiningRunning = Value
end)

Tabs.Mining:AddInput("SellMiningIntervalInput", {
    Title = "Delay Auto Sell Tambang (Menit)",
    Default = "5",
    Placeholder = "Contoh: 5",
    Numeric = true,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().AutoSellMiningInterval = tonumber(Value) or 5
end)

Tabs.Mining:AddButton({
    Title = "🏪 Teleport Instan ke Penjual Tambang",
    Callback = function()
        SafeTeleport(MiningSellCFrame)
    end,
})

------------------------------------------------------------------
-- TAB 3: FISHING (DENGAN TELEPORT OTOMATIS KE SPOT BARU)
------------------------------------------------------------------
Tabs.Fishing:AddParagraph({
    Title = "Auto Mancing",
    Content = "Otomatis melempar pancing dan menarik ikan."
})

Tabs.Fishing:AddToggle("AutoFishingToggle", {
    Title = "🎣 Auto Fishing (Teleport ke Spot)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoFishingRunning = Value
    if Value then
        pcall(function()
            SafeTeleport(FishingTeleportSpot)
            Fluent:Notify({ Title = "Teleportasi", Content = "Berpindah ke Spot Mancing Utama", Duration = 3 })
        end)
    else
        CurrentFishingPhase = "Idle"
        CurrentFishingSession = nil
    end
end)

------------------------------------------------------------------
-- TAB 4: CATCHING (CHICKEN & BUTTERFLY) DENGAN INPUT TIMER
------------------------------------------------------------------
Tabs.Catch:AddParagraph({
    Title = "Chicken & Butterfly Catching",
    Content = "Tangkap ayam dan kupu-kupu secara otomatis."
})

Tabs.Catch:AddToggle("AutoCatchChickenToggle", {
    Title = "Auto Catch Chicken (Ayam)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoCatchChickenRunning = Value
end)

Tabs.Catch:AddToggle("AutoCatchButterflyToggle", {
    Title = "Auto Catch Butterfly (Kupu-Kupu)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoCatchButterflyRunning = Value
end)

Tabs.Catch:AddSection("🐔 Auto Sell Ayam & Kupu-Kupu (Dengan Timer)")

Tabs.Catch:AddToggle("AutoSellChickenToggle", {
    Title = "💰 Auto Sell Chicken (Ayam)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoSellChickenRunning = Value
end)

Tabs.Catch:AddInput("SellChickenIntervalInput", {
    Title = "⏱️ Delay Auto Sell Ayam (Menit)",
    Default = "5",
    Placeholder = "Contoh: 5",
    Numeric = true,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().AutoSellChickenInterval = tonumber(Value) or 5
end)

Tabs.Catch:AddToggle("AutoSellButterflyToggle", {
    Title = "💰 Auto Sell Kupu-Kupu",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoSellButterflyRunning = Value
end)

Tabs.Catch:AddInput("SellButterflyIntervalInput", {
    Title = "⏱️ Delay Auto Sell Kupu-Kupu (Menit)",
    Default = "5",
    Placeholder = "Contoh: 5",
    Numeric = true,
    Finished = false,
}):OnChanged(function(Value)
    getgenv().AutoSellButterflyInterval = tonumber(Value) or 5
end)

------------------------------------------------------------------
-- TAB 5: PETERNAKAN (KANDANG)
------------------------------------------------------------------
Tabs.Kandang:AddParagraph({
    Title = "Auto Farm Peternakan",
    Content = "Kasih makan hewan dan ambil susu otomatis."
})

Tabs.Kandang:AddToggle("AutoFeedAnimalToggle", {
    Title = "Auto Kasih Makan Hewan (Tiap 2 Menit)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoFeedAnimalRunning = Value
end)

Tabs.Kandang:AddToggle("AutoCollectMilkToggle", {
    Title = "Auto Ambil Susu (Tiap 2 Menit)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoCollectMilkRunning = Value
end)

Tabs.Kandang:AddSection("🥛 Auto Sell Susu")

Tabs.Kandang:AddToggle("AutoSellMilkToggle", {
    Title = "💰 Auto Sell Susu",
    Default = false
}):OnChanged(function(Value)
    getgenv().AutoSellMilkRunning = Value
end)

------------------------------------------------------------------
-- TAB 6: PLAYER
------------------------------------------------------------------
Tabs.Player:AddParagraph({
    Title = "Pengaturan Karakter & Keamanan",
    Content = "Anti sit, anti AFK, dan pengatur kecepatan lari."
})

Tabs.Player:AddToggle("AntiSitToggle", {
    Title = "🛡 Anti Sit (Cegah Karakter Duduk)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AntiSitEnabled = Value
end)

Tabs.Player:AddToggle("AntiAfkToggle", {
    Title = "⏳ Anti AFK (Cegah Kena Kick Idle)",
    Default = false
}):OnChanged(function(Value)
    getgenv().AntiAfkEnabled = Value
end)

Tabs.Player:AddSlider("WalkSpeedSlider", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 1,
    Max = 350,
    Rounding = 1,
}):OnChanged(function(Value)
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = Value end)
end)

Window:SelectTab(1)

------------------------------------------------------------------
-- BACKGROUND LOOPS (LOGIKA UTAMA FARM)
------------------------------------------------------------------
local oldIdledConnection
oldIdledConnection = LocalPlayer.Idled:Connect(function()
    if getgenv().AntiAfkEnabled then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AntiAfkEnabled then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
        task.wait(60)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AntiSitEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Sit then humanoid.Sit = false end
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if (obj:IsA("Seat") or obj:IsA("VehicleSeat")) and not obj.Disabled then
                            obj.Disabled = true
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    local lastActionTime = tick()
    while true do
        if getgenv().AutoFishingRunning and not IsFarmBusy and not IsMiningBusy and not IsCatchBusy and not getgenv().IsKandangBusy then
            pcall(function()
                AutoEquipFishingRod()
                if FishingActionEvent then
                    if CurrentFishingPhase ~= "Idle" and (tick() - lastActionTime > 8) then
                        CurrentFishingPhase = "Idle"
                        CurrentFishingSession = nil
                    end

                    if CurrentFishingPhase == "Idle" then
                        lastActionTime = tick()
                        FishingActionEvent:FireServer({
                            Action = "Cast",
                            Target = FishingCastTarget
                        })
                        CurrentFishingPhase = "Waiting"
                        task.wait(1.2)

                    elseif CurrentFishingPhase == "Bite" or CurrentFishingPhase == "Reeling" or CurrentFishingPhase == "ReelProgress" then
                        lastActionTime = tick()
                        if CurrentFishingSession then
                            for i = 1, 3 do
                                FishingActionEvent:FireServer({
                                    Action = "ReelTap",
                                    SessionId = CurrentFishingSession
                                })
                            end
                        end
                        task.wait(0.01)

                    elseif CurrentFishingPhase == "Caught" or CurrentFishingPhase == "Success" then
                        task.wait(1.0)
                        CurrentFishingPhase = "Idle"
                        CurrentFishingSession = nil
                    end
                end
            end)
        else
            task.wait(0.5)
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoBuyRunning then
            pcall(function()
                local currentSeeds = CountSeedInInventory()
                if BuySeedEvent and currentSeeds <= 20 then
                    for i = 1, 7 do
                        if not getgenv().AutoBuyRunning then break end
                        BuySeedEvent:FireServer(getgenv().SelectedSeed)
                        task.wait(0.3)
                    end
                    task.wait(5)
                end
            end)
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoFarmRunning then
            pcall(function()
                while getgenv().IsKandangBusy or getgenv().AutoMineRunning or IsMiningBusy or IsCatchBusy do task.wait(0.5) end
                TeleportToSawah()
                IsFarmBusy = true
                
                while getgenv().AutoFarmRunning and not getgenv().IsKandangBusy and not getgenv().AutoMineRunning and not IsMiningBusy and not IsCatchBusy and CountActivePlants() < MAX_PLANTS do
                    if PlantEvent then
                        PlantEvent:FireServer(PlantPosition, SawahModel, getgenv().SelectedSeed)
                        task.wait(0.25)
                    else
                        task.wait(0.5)
                    end
                end
                
                if getgenv().AutoFarmRunning and PlantActionEvent then
                    task.wait(0.3)
                    AutoRefillWater()
                    task.wait(0.5)
                    TeleportToSawah()
                    task.wait(0.3)
                    AutoEquipEmber()
                    task.wait(0.3)
                    PlantActionEvent:FireServer("WaterNearby", WaterPosition)
                    task.wait(0.5)
                end
                
                IsFarmBusy = false 
                while getgenv().AutoFarmRunning and not getgenv().IsKandangBusy and not getgenv().AutoMineRunning and not IsMiningBusy and not IsCatchBusy and CountReadyPlants() < 1 do
                    task.wait(1)
                end
                IsFarmBusy = true
                
                local emptyAttempts = 0
                while getgenv().AutoFarmRunning and not getgenv().IsKandangBusy and not getgenv().AutoMineRunning and not IsMiningBusy and not IsCatchBusy and emptyAttempts < 6 do
                    local targetInstance = FindReadyPlant()
                    if targetInstance and targetInstance.Parent and PlantActionEvent then
                        emptyAttempts = 0 
                        local targetPos = PlantPosition
                        if targetInstance:IsA("BasePart") then targetPos = targetInstance.Position end
                        SafeTeleport(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
                        PlantActionEvent:FireServer("HarvestOne", { target = targetInstance, position = targetPos })
                        task.wait(0.35)
                    else
                        emptyAttempts = emptyAttempts + 1
                        task.wait(0.5)
                    end
                end
            end)
        else
            IsFarmBusy = false
            task.wait(1)
        end
        task.wait(0.05)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoSellRunning then
            local waitTime = (getgenv().AutoSellInterval or 5) * 60
            task.wait(waitTime)
            pcall(function()
                if getgenv().AutoSellRunning then
                    IsFarmBusy = true
                    task.wait(0.5)
                    ExecuteSell()
                    task.wait(1.0)
                    if getgenv().AutoSellRunning then TeleportToSawah() end
                    IsFarmBusy = false
                end
            end)
        else
            task.wait(2)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoSellMiningRunning then
            local waitTime = (getgenv().AutoSellMiningInterval or 5) * 60
            task.wait(waitTime)
            pcall(function()
                if getgenv().AutoSellMiningRunning then
                    IsMiningBusy = true
                    task.wait(0.5)
                    ExecuteMiningSell()
                    task.wait(1.5)
                    if getgenv().AutoMineRunning then
                        local currentZone = getgenv().SelectedMiningZone or "Batu Bara 1"
                        local miningCF = MiningLocations[currentZone]
                        if miningCF then SafeTeleport(miningCF) end
                    end
                    IsMiningBusy = false
                end
            end)
        else
            task.wait(2)
        end
    end
end)

-- LOOP AUTO SELL CHICKEN (DENGAN TIMER MENIT)
task.spawn(function()
    while true do
        if getgenv().AutoSellChickenRunning then
            local waitTime = (getgenv().AutoSellChickenInterval or 5) * 60
            task.wait(waitTime)
            pcall(function()
                if getgenv().AutoSellChickenRunning then
                    IsCatchBusy = true
                    task.wait(0.5)
                    ExecuteChickenSell()
                    task.wait(1.5)
                    IsCatchBusy = false
                end
            end)
        else
            task.wait(2)
        end
    end
end)

-- LOOP AUTO SELL BUTTERFLY (DENGAN TIMER MENIT)
task.spawn(function()
    while true do
        if getgenv().AutoSellButterflyRunning then
            local waitTime = (getgenv().AutoSellButterflyInterval or 5) * 60
            task.wait(waitTime)
            pcall(function()
                if getgenv().AutoSellButterflyRunning then
                    IsCatchBusy = true
                    task.wait(0.5)
                    ExecuteButterflySell()
                    task.wait(1.5)
                    IsCatchBusy = false
                end
            end)
        else
            task.wait(2)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoSellMilkRunning then
            task.wait(300)
            pcall(function()
                if getgenv().AutoSellMilkRunning then
                    getgenv().IsKandangBusy = true
                    task.wait(0.5)
                    ExecuteMilkSell()
                    task.wait(1.5)
                    if getgenv().AutoFarmRunning then TeleportToSawah() end
                    getgenv().IsKandangBusy = false
                end
            end)
        else
            task.wait(2)
        end
    end
end)

local currentActiveSessionId = nil
pcall(function()
    if MiningActionEvent then
        MiningActionEvent.OnClientEvent:Connect(function(actionType, data)
            if actionType == "start" and data and data.sessionId then
                currentActiveSessionId = data.sessionId
            end
        end)
    end
end)

task.spawn(function()
    local currentZoneIndex = 1
    while true do
        if getgenv().AutoMineRunning and not getgenv().IsKandangBusy and not IsMiningBusy and not IsCatchBusy then
            pcall(function()
                local zoneName = getgenv().SelectedMiningZone
                if getgenv().AutoLoopMining then
                    zoneName = MiningOrderList[currentZoneIndex]
                end
                local exactCField = MiningLocations[zoneName]
                if exactCField then
                    SafeTeleport(exactCField)
                    task.wait(0.2)
                    AutoEquipPickaxe()
                    task.wait(0.15)
                    local targetOre, _ = FindOreNearCFrame(exactCField.Position)
                    if targetOre and MiningStartRequest and MiningActionEvent then
                        currentActiveSessionId = nil
                        MiningStartRequest:FireServer(targetOre)
                        task.wait(0.2)
                        local targetSessionId = currentActiveSessionId or HttpService:GenerateGUID(false)
                        local startTime = tick()
                        local zoneDuration = getgenv().AutoLoopMining and (getgenv().MiningTimerDuration or 3) or 999999
                        while getgenv().AutoMineRunning and not IsMiningBusy and (tick() - startTime < zoneDuration) do
                            MiningActionEvent:FireServer("tap", { sessionId = targetSessionId })
                            task.wait(0.05)
                            if not targetOre or not targetOre.Parent then
                                targetOre, _ = FindOreNearCFrame(exactCField.Position)
                                if targetOre then
                                    MiningStartRequest:FireServer(targetOre)
                                    task.wait(0.2)
                                end
                            end
                        end
                        currentActiveSessionId = nil
                    else
                        task.wait(0.5)
                    end
                    if getgenv().AutoLoopMining then
                        currentZoneIndex = currentZoneIndex + 1
                        if currentZoneIndex > #MiningOrderList then
                            currentZoneIndex = 1
                        end
                    end
                end
            end)
        else
            task.wait(0.5)
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoCatchChickenRunning and not IsFarmBusy and not IsMiningBusy and not IsCatchBusy and not getgenv().IsKandangBusy then
            pcall(function()
                local chicken = FindNearestChicken()
                if chicken then
                    AutoEquipNet()
                    local chickenPart = chicken:IsA("Model") and (chicken.PrimaryPart or chicken:FindFirstChildWhichIsA("BasePart"))
                    if chickenPart then
                        SafeTeleport(CFrame.new(chickenPart.Position + Vector3.new(0, 3, 0)))
                        TouchTargetWithTool(chickenPart)
                        if SwingNetEvent then SwingNetEvent:FireServer() end
                    end
                end
            end)
            task.wait(0.05)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoCatchButterflyRunning and not IsFarmBusy and not IsMiningBusy and not IsCatchBusy and not getgenv().IsKandangBusy then
            pcall(function()
                local butterfly = FindNearestButterfly()
                if butterfly then
                    AutoEquipNet()
                    local bflyPart = butterfly:IsA("Model") and (bfly.PrimaryPart or butterfly:FindFirstChildWhichIsA("BasePart")) or (bfly:IsA("BasePart") and butterfly)
                    if bflyPart then
                        SafeTeleport(bflyPart.CFrame + Vector3.new(0, 0.5, 0))
                        TouchTargetWithTool(bflyPart)
                        if SwingNetEvent then SwingNetEvent:FireServer() end
                        if CatchButterflyEvent then CatchButterflyEvent:FireServer(butterfly.Name) end
                    end
                end
            end)
            task.wait(0.01)
        else
            task.wait(0.3)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoFeedAnimalRunning or getgenv().AutoCollectMilkRunning then
            task.wait(120)
            pcall(function()
                getgenv().IsKandangBusy = true
                task.wait(0.5)
                if getgenv().AutoFeedAnimalRunning then TriggerCowBarnPrompt("FeedPrompt") task.wait(1.5) end
                if getgenv().AutoCollectMilkRunning then TriggerCowBarnPrompt("MilkPrompt") task.wait(1.5) end
                if getgenv().AutoFarmRunning then TeleportToSawah() end
                getgenv().IsKandangBusy = false
            end)
        else
            task.wait(2)
        end
    end
end)

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
