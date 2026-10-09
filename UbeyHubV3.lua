-- ==============================================================================
-- DANZ HUB (Ubey Hub V3 Style) - Full Item Kios Taruh Edition
-- ==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- SETTING WAKTU TUNGGU & CONFIG
------------------------------------------------------------------
getgenv().ConfigWait = {
	BatuKecil = 5.8,
	BatuSedang = 11.5,
	BatuBesar = 19.5,
	PohonKecil = 5.8,
	PohonSedang = 11.5,
	PohonBesar = 19.5,
}

getgenv().SelectedTaruhSlot = "slot1"
getgenv().SelectedTaruhItem = "Bunga Melati"
getgenv().AutoTaruhEnabled = false

------------------------------------------------------------------
-- SUPABASE CONFIGURATION
------------------------------------------------------------------
local SUPABASE_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/rest/v1/Ubey_Project?key_value=eq."
local SUPABASE_ANON_KEY = "sb_publishable_8_TpNisUFO-E3rEvqonNvA_RLPy9PX5"

getgenv().KeyVerified = false
getgenv().AutoSpawnCollect = false
getgenv().AutoMineEnabled = false
getgenv().AutoWoodEnabled = false
getgenv().AutoRestockEnabled = false
getgenv().RemoveWaterEnabled = true

getgenv().SelectedMaterials = {
	["Spawn_Dupa"] = false,
	["Spawn_JamurKuburan"] = false,
	["Spawn_Kemenyan"] = false,
	["Spawn_Gagak"] = false,
	["Spawn_KepitingSungai"] = false,
	["Spawn_Melati"] = false,
}

getgenv().SelectedBatu = {
	["BatuKecil"] = false,
	["BatuSedang"] = false,
	["BatuBesar"] = false,
}

getgenv().SelectedPohon = {
	["PohonKecil"] = false,
	["PohonSedang"] = false,
	["PohonBesar"] = false,
}

local function ApplyAntiWater(state)
	pcall(function()
		if state then
			if Terrain then
				Terrain.WaterTransparency = 1
				Terrain.WaterWaveSize = 0
				Terrain.WaterWaveSpeed = 0
				Terrain.WaterColor = Color3.new(0, 0, 0)
			end
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("Part") and (v.Name:lower():find("water") or v.Name:lower():find("air") or v.Material == Enum.Material.Water) then
					v.CanCollide = false
					v.Transparency = 1
				end
			end
		end
	end)
end

local function EquipTool(toolName)
	pcall(function()
		local character = LocalPlayer.Character
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		if not character or not backpack then return end
		
		local currentTool = character:FindFirstChildOfClass("Tool")
		if currentTool and currentTool.Name == toolName then return end
		
		local tool = backpack:FindFirstChild(toolName)
		if tool then
			character.Humanoid:EquipTool(tool)
		end
	end)
end

local function StabilizeCharacter(character)
	pcall(function()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		end
	end)
end

pcall(function()
	PlayerGui:FindFirstChild("DanzHubCollect"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "DanzHubCollect"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

----------------------------------------------------
-- KEY SYSTEM UI
----------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,380,0,220)
KeyFrame.Position = UDim2.new(0.5,-190,0.5,-110)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
KeyFrame.Visible = true

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0,15)
KeyCorner.Parent = KeyFrame

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Parent = KeyFrame
KeyStroke.Color = Color3.fromRGB(0,170,255)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyFrame
KeyTitle.Size = UDim2.new(1,0,0,50)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "DANZ HUB - KEY SYSTEM"
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextColor3 = Color3.fromRGB(0,170,255)
KeyTitle.TextSize = 15

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
Instance.new("UICorner", KeyBox)

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Parent = KeyFrame
SubmitKeyBtn.Size = UDim2.new(0,165,0,35)
SubmitKeyBtn.Position = UDim2.new(0,20,0,115)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
SubmitKeyBtn.Text = "Verifikasi Key"
SubmitKeyBtn.TextColor3 = Color3.new(1,1,1)
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextSize = 13
Instance.new("UICorner", SubmitKeyBtn)

local GetKeyDiscordBtn = Instance.new("TextButton")
GetKeyDiscordBtn.Parent = KeyFrame
GetKeyDiscordBtn.Size = UDim2.new(0,165,0,35)
GetKeyDiscordBtn.Position = UDim2.new(0,195,0,115)
GetKeyDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GetKeyDiscordBtn.Text = "Get Key via Bot Discord"
GetKeyDiscordBtn.TextColor3 = Color3.new(1,1,1)
GetKeyDiscordBtn.Font = Enum.Font.GothamBold
GetKeyDiscordBtn.TextSize = 12
Instance.new("UICorner", GetKeyDiscordBtn)

local FreeKeyBackupBtn = Instance.new("TextButton")
FreeKeyBackupBtn.Parent = KeyFrame
FreeKeyBackupBtn.Size = UDim2.new(0,340,0,30)
FreeKeyBackupBtn.Position = UDim2.new(0,20,0,160)
FreeKeyBackupBtn.BackgroundColor3 = Color3.fromRGB(45,45,55)
FreeKeyBackupBtn.Text = "Gunakan Free Key (UBEY_FREE)"
FreeKeyBackupBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
FreeKeyBackupBtn.Font = Enum.Font.GothamMedium
FreeKeyBackupBtn.TextSize = 12
Instance.new("UICorner", FreeKeyBackupBtn)

local StatusKey = Instance.new("TextLabel")
StatusKey.Parent = KeyFrame
StatusKey.Size = UDim2.new(1,0,0,20)
StatusKey.Position = UDim2.new(0,0,0,195)
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

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,18)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(0,170,255)

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Parent = Main
Sidebar.Size = UDim2.new(0,140,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,20)
Sidebar.CanvasSize = UDim2.new(0,0,1.4,0)
Sidebar.ScrollBarThickness = 2

local SideCorner = Instance.new("UICorner")
SideCorner.Parent = Sidebar

local HubTitle = Instance.new("TextLabel")
HubTitle.Parent = Sidebar
HubTitle.BackgroundTransparency = 1
HubTitle.Size = UDim2.new(1,0,0,60)
HubTitle.Text = "DANZ HUB"
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextColor3 = Color3.fromRGB(0,170,255)
HubTitle.TextSize = 18

local AutoCollectMenuBtn = Instance.new("TextButton")
AutoCollectMenuBtn.Parent = Sidebar
AutoCollectMenuBtn.Position = UDim2.new(0,10,0,65)
AutoCollectMenuBtn.Size = UDim2.new(1,-20,0,32)
AutoCollectMenuBtn.Text = "Auto Collect"
AutoCollectMenuBtn.TextColor3 = Color3.new(1,1,1)
AutoCollectMenuBtn.Font = Enum.Font.GothamMedium
AutoCollectMenuBtn.TextSize = 12
AutoCollectMenuBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
Instance.new("UICorner", AutoCollectMenuBtn)

local AutoFarmMenuBtn = Instance.new("TextButton")
AutoFarmMenuBtn.Parent = Sidebar
AutoFarmMenuBtn.Position = UDim2.new(0,10,0,105)
AutoFarmMenuBtn.Size = UDim2.new(1,-20,0,32)
AutoFarmMenuBtn.Text = "Auto Mine & Wood"
AutoFarmMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
AutoFarmMenuBtn.Font = Enum.Font.GothamMedium
AutoFarmMenuBtn.TextSize = 11
AutoFarmMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
Instance.new("UICorner", AutoFarmMenuBtn)

local AutoRestockMenuBtn = Instance.new("TextButton")
AutoRestockMenuBtn.Parent = Sidebar
AutoRestockMenuBtn.Position = UDim2.new(0,10,0,145)
AutoRestockMenuBtn.Size = UDim2.new(1,-20,0,32)
AutoRestockMenuBtn.Text = "Auto Kios Taruh"
AutoRestockMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
AutoRestockMenuBtn.Font = Enum.Font.GothamMedium
AutoRestockMenuBtn.TextSize = 11
AutoRestockMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
Instance.new("UICorner", AutoRestockMenuBtn)

----------------------------------------------------
-- CONTENT & PAGES
----------------------------------------------------
local Content = Instance.new("Frame")
Content.Parent = Main
Content.Position = UDim2.new(0,150,0,30)
Content.Size = UDim2.new(1,-160,1,-40)
Content.BackgroundTransparency = 1

----------------------------------------------------
-- HALAMAN 1: AUTO COLLECT
----------------------------------------------------
local AutoCollectPage = Instance.new("ScrollingFrame")
AutoCollectPage.Parent = Content
AutoCollectPage.Size = UDim2.new(1,0,1,0)
AutoCollectPage.BackgroundTransparency = 1
AutoCollectPage.Visible = true
AutoCollectPage.CanvasSize = UDim2.new(0,0,2.6,0)
AutoCollectPage.ScrollBarThickness = 4

local pad1 = Instance.new("UIPadding")
pad1.Parent = AutoCollectPage
pad1.PaddingTop = UDim.new(0, 10)

local l1 = Instance.new("UIListLayout")
l1.Parent = AutoCollectPage
l1.SortOrder = Enum.SortOrder.LayoutOrder
l1.Padding = UDim.new(0, 8)

local TitleCol = Instance.new("TextLabel")
TitleCol.Parent = AutoCollectPage
TitleCol.Size = UDim2.new(1,0,0,25)
TitleCol.BackgroundTransparency = 1
TitleCol.Text = "📦 MENU AUTO COLLECT"
TitleCol.TextColor3 = Color3.fromRGB(0,170,255)
TitleCol.Font = Enum.Font.GothamBold
TitleCol.TextSize = 12

local function AddToggle(parent, text, defaultState, callback)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Size = UDim2.new(1,0,0,30)
	b.BackgroundColor3 = defaultState and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
	b.Text = "  " .. text .. (defaultState and " [ON]" or " [OFF]")
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", b)
	local state = defaultState
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = "  " .. text .. (state and " [ON]" or " [OFF]")
		b.BackgroundColor3 = state and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
		callback(state)
	end)
end

AddToggle(AutoCollectPage, "Master Auto Collect", false, function(v) getgenv().AutoSpawnCollect = v end)
AddToggle(AutoCollectPage, "Anti-Water (Fix Kepiting)", true, function(v) getgenv().RemoveWaterEnabled = v ApplyAntiWater(v) end)

local function AddSectionHeader(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.Parent = parent
	lbl.Size = UDim2.new(1,0,0,22)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(170,170,170)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
end

local function AddCompactButton(parent, matKey, displayName, categoryTable)
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.Size = UDim2.new(1,0,0,26)
	btn.BackgroundColor3 = Color3.fromRGB(30,30,40)
	btn.Text = "  • " .. displayName
	btn.TextColor3 = Color3.fromRGB(200,200,200)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 11
	btn.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", btn)
	
	local active = false
	btn.MouseButton1Click:Connect(function()
		active = not active
		categoryTable[matKey] = active
		if active then
			btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
			btn.TextColor3 = Color3.new(1,1,1)
		else
			btn.BackgroundColor3 = Color3.fromRGB(30,30,40)
			btn.TextColor3 = Color3.fromRGB(200,200,200)
		end
	end)
end

AddSectionHeader(AutoCollectPage, "--- PILIH BAHAN (AMBIL) ---")
AddCompactButton(AutoCollectPage, "Spawn_Dupa", "Spawn_Dupa", getgenv().SelectedMaterials)
AddCompactButton(AutoCollectPage, "Spawn_JamurKuburan", "Spawn_JamurKuburan", getgenv().SelectedMaterials)
AddCompactButton(AutoCollectPage, "Spawn_Kemenyan", "Spawn_Kemenyan", getgenv().SelectedMaterials)
AddCompactButton(AutoCollectPage, "Spawn_Gagak", "Spawn_Gagak", getgenv().SelectedMaterials)
AddCompactButton(AutoCollectPage, "Spawn_KepitingSungai", "Spawn_KepitingSungai", getgenv().SelectedMaterials)
AddCompactButton(AutoCollectPage, "Spawn_Melati", "Spawn_Melati", getgenv().SelectedMaterials)


----------------------------------------------------
-- HALAMAN 2: AUTO MINE & WOOD
----------------------------------------------------
local AutoFarmPage = Instance.new("ScrollingFrame")
AutoFarmPage.Parent = Content
AutoFarmPage.Size = UDim2.new(1,0,1,0)
AutoFarmPage.BackgroundTransparency = 1
AutoFarmPage.Visible = false
AutoFarmPage.CanvasSize = UDim2.new(0,0,3.2,0)
AutoFarmPage.ScrollBarThickness = 4

local pad2 = Instance.new("UIPadding")
pad2.Parent = AutoFarmPage
pad2.PaddingTop = UDim.new(0, 10)

local l2 = Instance.new("UIListLayout")
l2.Parent = AutoFarmPage
l2.SortOrder = Enum.SortOrder.LayoutOrder
l2.Padding = UDim.new(0, 8)

local TitleFarm = Instance.new("TextLabel")
TitleFarm.Parent = AutoFarmPage
TitleFarm.Size = UDim2.new(1,0,0,25)
TitleFarm.BackgroundTransparency = 1
TitleFarm.Text = "⛏️ MENU MINING & WOODCUTTING"
TitleFarm.TextColor3 = Color3.fromRGB(0,170,255)
TitleFarm.Font = Enum.Font.GothamBold
TitleFarm.TextSize = 12

AddToggle(AutoFarmPage, "Master Auto Mining (Beliung)", false, function(v) getgenv().AutoMineEnabled = v end)
AddToggle(AutoFarmPage, "Master Auto Wood (Kapak)", false, function(v) getgenv().AutoWoodEnabled = v end)

AddSectionHeader(AutoFarmPage, "--- PILIH BATU & POHON ---")
AddCompactButton(AutoFarmPage, "BatuKecil", "Batu Kecil", getgenv().SelectedBatu)
AddCompactButton(AutoFarmPage, "BatuSedang", "Batu Sedang", getgenv().SelectedBatu)
AddCompactButton(AutoFarmPage, "BatuBesar", "Batu Besar", getgenv().SelectedBatu)
AddCompactButton(AutoFarmPage, "PohonKecil", "Pohon Kecil", getgenv().SelectedPohon)
AddCompactButton(AutoFarmPage, "PohonSedang", "Pohon Sedang", getgenv().SelectedPohon)
AddCompactButton(AutoFarmPage, "PohonBesar", "Pohon Besar", getgenv().SelectedPohon)

local function AddSlider(parent, configKey, labelName, minVal, maxVal)
	local container = Instance.new("Frame")
	container.Parent = parent
	container.Size = UDim2.new(1,0,0,45)
	container.BackgroundTransparency = 1
	
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Parent = container
	titleLbl.Size = UDim2.new(1,-40,0,20)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "  Jeda " .. labelName .. " (Detik)"
	titleLbl.TextColor3 = Color3.fromRGB(200,200,200)
	titleLbl.Font = Enum.Font.Gotham
	titleLbl.TextSize = 11
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	
	local valLbl = Instance.new("TextLabel")
	valLbl.Parent = container
	valLbl.Size = UDim2.new(0,35,0,20)
	valLbl.Position = UDim2.new(1,-38,0,0)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = tostring(getgenv().ConfigWait[configKey])
	valLbl.TextColor3 = Color3.fromRGB(0,170,255)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 11
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	
	local sliderBg = Instance.new("Frame")
	sliderBg.Parent = container
	sliderBg.Size = UDim2.new(1,-10,0,6)
	sliderBg.Position = UDim2.new(0,5,0,28)
	sliderBg.BackgroundColor3 = Color3.fromRGB(35,35,45)
	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1,0)
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Parent = sliderBg
	sliderFill.Size = UDim2.new(math.clamp((getgenv().ConfigWait[configKey] - minVal)/(maxVal - minVal), 0, 1), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1,0)
	
	local sliderBtn = Instance.new("TextButton")
	sliderBtn.Parent = sliderBg
	sliderBtn.Size = UDim2.new(1,10,1,10)
	sliderBtn.Position = UDim2.new(0,-5,0,-5)
	sliderBtn.BackgroundTransparency = 1
	sliderBtn.Text = ""
	
	local sliding = false
	local function updateSlider(input)
		local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		local val = math.floor((minVal + (maxVal - minVal) * pos) * 10) / 10
		sliderFill.Size = UDim2.new(pos, 0, 1, 0)
		valLbl.Text = tostring(val)
		getgenv().ConfigWait[configKey] = val
	end
	
	sliderBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			updateSlider(input)
		end
	end)
	
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end)
	
	UIS.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			updateSlider(input)
		end
	end)
end

AddSectionHeader(AutoFarmPage, "--- ATUR WAKTU SLIDER (MAKS 60 DETIK) ---")
AddSlider(AutoFarmPage, "BatuKecil", "Batu Kecil", 1, 60)
AddSlider(AutoFarmPage, "BatuSedang", "Batu Sedang", 1, 60)
AddSlider(AutoFarmPage, "BatuBesar", "Batu Besar", 1, 60)
AddSlider(AutoFarmPage, "PohonKecil", "Pohon Kecil", 1, 60)
AddSlider(AutoFarmPage, "PohonSedang", "Pohon Sedang", 1, 60)
AddSlider(AutoFarmPage, "PohonBesar", "Pohon Besar", 1, 60)


----------------------------------------------------
-- HALAMAN 3: AUTO KIOS TARUH (PILIH SLOT & 12 ITEM LENGKAP)
----------------------------------------------------
local AutoRestockPage = Instance.new("ScrollingFrame")
AutoRestockPage.Parent = Content
AutoRestockPage.Size = UDim2.new(1,0,1,0)
AutoRestockPage.BackgroundTransparency = 1
AutoRestockPage.Visible = false
AutoRestockPage.CanvasSize = UDim2.new(0,0,1.8,0)
AutoRestockPage.ScrollBarThickness = 4

local pad3 = Instance.new("UIPadding")
pad3.Parent = AutoRestockPage
pad3.PaddingTop = UDim.new(0, 10)

local l3 = Instance.new("UIListLayout")
l3.Parent = AutoRestockPage
l3.SortOrder = Enum.SortOrder.LayoutOrder
l3.Padding = UDim.new(0, 8)

local TitleRestock = Instance.new("TextLabel")
TitleRestock.Parent = AutoRestockPage
TitleRestock.Size = UDim2.new(1,0,0,25)
TitleRestock.BackgroundTransparency = 1
TitleRestock.Text = "🏪 MENU AUTO KIOS (TARUH)"
TitleRestock.TextColor3 = Color3.fromRGB(0,170,255)
TitleRestock.Font = Enum.Font.GothamBold
TitleRestock.TextSize = 12

AddToggle(AutoRestockPage, "Master Auto Taruh Kios", false, function(v) getgenv().AutoTaruhEnabled = v end)

AddSectionHeader(AutoRestockPage, "--- PENGATURAN SLOT & ITEM ---")

local function AddSlotSelector(parent)
	local container = Instance.new("Frame")
	container.Parent = parent
	container.Size = UDim2.new(1,0,0,36)
	container.BackgroundTransparency = 1
	
	local lbl = Instance.new("TextLabel")
	lbl.Parent = container
	lbl.Size = UDim2.new(0.5,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "  Pilih Slot Kios"
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	
	local btn = Instance.new("TextButton")
	btn.Parent = container
	btn.Size = UDim2.new(0.45,0,0,30)
	btn.Position = UDim2.new(0.52,0,0.1,0)
	btn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	btn.Text = "slot1 ▾"
	btn.TextColor3 = Color3.fromRGB(0,170,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	Instance.new("UICorner", btn)
	
	local currentIdx = 1
	btn.MouseButton1Click:Connect(function()
		currentIdx = currentIdx + 1
		if currentIdx > 12 then currentIdx = 1 end
		local slotName = "slot" .. tostring(currentIdx)
		getgenv().SelectedTaruhSlot = slotName
		btn.Text = slotName .. " ▾"
	end)
end

local function AddItemSelector(parent)
	-- 12 Daftar item lengkap sesuai gambar game
	local items = {
		"Bunga Melati", "Dupa", "Jagung", "Jamur Rebus", "Kemenyan", "Kepiting Sungai",
		"Pisang Raja", "Sate Gagak", "Sate Kepiting", "Susu", "Telur", "Tumis Kamboja"
	}
	local container = Instance.new("Frame")
	container.Parent = parent
	container.Size = UDim2.new(1,0,0,36)
	container.BackgroundTransparency = 1
	
	local lbl = Instance.new("TextLabel")
	lbl.Parent = container
	lbl.Size = UDim2.new(0.5,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "  Pilih Item Barang"
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	
	local btn = Instance.new("TextButton")
	btn.Parent = container
	btn.Size = UDim2.new(0.45,0,0,30)
	btn.Position = UDim2.new(0.52,0,0.1,0)
	btn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	btn.Text = "Bunga Melati ▾"
	btn.TextColor3 = Color3.fromRGB(0,170,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	Instance.new("UICorner", btn)
	
	local itemIdx = 1
	btn.MouseButton1Click:Connect(function()
		itemIdx = itemIdx + 1
		if itemIdx > #items then itemIdx = 1 end
		local itemName = items[itemIdx]
		getgenv().SelectedTaruhItem = itemName
		btn.Text = itemName .. " ▾"
	end)
end

AddSlotSelector(AutoRestockPage)
AddItemSelector(AutoRestockPage)

local ExecuteTaruhBtn = Instance.new("TextButton")
ExecuteTaruhBtn.Parent = AutoRestockPage
ExecuteTaruhBtn.Size = UDim2.new(1,0,0,32)
ExecuteTaruhBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
ExecuteTaruhBtn.Text = "Taruh Barang Sekarang"
ExecuteTaruhBtn.TextColor3 = Color3.new(1,1,1)
ExecuteTaruhBtn.Font = Enum.Font.GothamBold
ExecuteTaruhBtn.TextSize = 12
Instance.new("UICorner", ExecuteTaruhBtn)

ExecuteTaruhBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local eventPath = ReplicatedStorage:FindFirstChild("rc645e8ded8e146828f98af5123faf3a8")
		if eventPath then
			local remote = eventPath:FindFirstChild("r2c39d7b63e484766b0f0da9e3961ed82")
			if remote and remote:IsA("RemoteFunction") then
				remote:InvokeServer("taruh", getgenv().SelectedTaruhSlot, getgenv().SelectedTaruhItem)
			end
		end
	end)
end)


-- Sistem Ganti Halaman (Tab Switching)
AutoCollectMenuBtn.MouseButton1Click:Connect(function()
	AutoCollectPage.Visible = true
	AutoFarmPage.Visible = false
	AutoRestockPage.Visible = false
	AutoCollectMenuBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
	AutoCollectMenuBtn.TextColor3 = Color3.new(1,1,1)
	AutoFarmMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	AutoFarmMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
	AutoRestockMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	AutoRestockMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
end)

AutoFarmMenuBtn.MouseButton1Click:Connect(function()
	AutoCollectPage.Visible = false
	AutoFarmPage.Visible = true
	AutoRestockPage.Visible = false
	AutoFarmMenuBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
	AutoFarmMenuBtn.TextColor3 = Color3.new(1,1,1)
	AutoCollectMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	AutoCollectMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
	AutoRestockMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	AutoRestockMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
end)

AutoRestockMenuBtn.MouseButton1Click:Connect(function()
	AutoCollectPage.Visible = false
	AutoFarmPage.Visible = false
	AutoRestockPage.Visible = true
	AutoRestockMenuBtn.BackgroundColor3 = Color3.fromRGB(0,100,180)
	AutoRestockMenuBtn.TextColor3 = Color3.new(1,1,1)
	AutoCollectMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	AutoCollectMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
	AutoFarmMenuBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
	AutoFarmMenuBtn.TextColor3 = Color3.fromRGB(200,200,200)
end)

----------------------------------------------------
-- SUPABASE VERIFICATION LOGIC
----------------------------------------------------
FreeKeyBackupBtn.MouseButton1Click:Connect(function()
	KeyBox.Text = "UBEY_FREE"
	pcall(function() if setclipboard then setclipboard("UBEY_FREE") end end)
	StatusKey.TextColor3 = Color3.fromRGB(0,255,100)
	StatusKey.Text = "Free Key disalin!"
end)

GetKeyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function() if setclipboard then setclipboard("https://discord.gg/YXuYeEpnXE") end end)
	StatusKey.TextColor3 = Color3.fromRGB(0,170,255)
	StatusKey.Text = "Link Discord disalin!"
end)

SubmitKeyBtn.MouseButton1Click:Connect(function()
	local enteredKey = KeyBox.Text
	if enteredKey == "" then
		StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
		StatusKey.Text = "Masukkan key terlebih dahulu!"
		return
	end
	if enteredKey == "UBEY_FREE" then
		getgenv().KeyVerified = true
		KeyFrame.Visible = false
		Main.Visible = true
		return
	end
	
	StatusKey.TextColor3 = Color3.fromRGB(255,200,0)
	StatusKey.Text = "Mengecek key..."
	
	task.spawn(function()
		local requestFunc = syn and syn.request or http and http.request or request
		local success, response = pcall(function()
			if requestFunc then
				local res = requestFunc({
					Url = SUPABASE_URL .. enteredKey,
					Method = "GET",
					Headers = { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY, ["Content-Type"] = "application/json" }
				})
				return res.Body
			else
				return HttpService:GetAsync(SUPABASE_URL .. HttpService:UrlEncode(enteredKey), false, { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY })
			end
		end)
		
		if success and response then
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
			if decodeSuccess and data and #data > 0 then
				if data[1].status == false or data[1].status == "inactive" or data[1].status == "used" then
					StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
					StatusKey.Text = "Key tidak aktif/sudah digunakan!"
					return
				end
				StatusKey.TextColor3 = Color3.fromRGB(0,255,100)
				StatusKey.Text = "Key Valid!"
				task.wait(1)
				getgenv().KeyVerified = true
				KeyFrame.Visible = false
				Main.Visible = true
			else
				StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
				StatusKey.Text = "Key Salah!"
			end
		else
			StatusKey.TextColor3 = Color3.fromRGB(255,50,50)
			StatusKey.Text = "Gagal terhubung ke server."
		end
	end)
end)

----------------------------------------------------
-- BACKGROUND WORKER (COLLECT, MINE, WOOD & TARUH KIOS)
----------------------------------------------------
task.spawn(function()
	ApplyAntiWater(true)
	while true do
		task.wait(0.4)
		
		if getgenv().RemoveWaterEnabled then
			pcall(function()
				if Terrain then Terrain.WaterTransparency = 1 Terrain.WaterWaveSize = 0 end
			end)
		end
		
		-- 1. AUTO COLLECT MATERIALS
		if getgenv().AutoSpawnCollect then
			pcall(function()
				local character = LocalPlayer.Character
				if not character or not character:FindFirstChild("HumanoidRootPart") then return end
				StabilizeCharacter(character)
				local rootPart = character.HumanoidRootPart
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local foundAny = false

				for _, obj in ipairs(Workspace:GetDescendants()) do
					if not getgenv().AutoSpawnCollect then break end
					if getgenv().SelectedMaterials[obj.Name] then
						local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
						local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
						
						if prompt and part and prompt.Enabled and prompt.ActionText == "Ambil bahan" then
							foundAny = true
							if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) end
							rootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
							task.wait(0.3)
							pcall(function() prompt:InputHoldBegin() end)
							task.wait(prompt.HoldDuration or 1.0)
							pcall(function() prompt:InputHoldEnd() end)
							pcall(function() fireproximityprompt(prompt) end)
							task.wait(0.5)
						end
					end
				end
				if not foundAny then task.wait(1) end
			end)
		end

		-- 2. AUTO MINING
		if getgenv().AutoMineEnabled then
			pcall(function()
				local character = LocalPlayer.Character
				if not character or not character:FindFirstChild("HumanoidRootPart") then return end
				StabilizeCharacter(character)
				local rootPart = character.HumanoidRootPart
				local foundAny = false

				for _, obj in ipairs(Workspace:GetDescendants()) do
					if not getgenv().AutoMineEnabled then break end
					
					local targetName = obj.Name
					local parentModel = obj.Parent
					if parentModel and getgenv().SelectedBatu[parentModel.Name] then
						targetName = parentModel.Name
					end
					
					if getgenv().SelectedBatu[targetName] then
						local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or (parentModel and parentModel:FindFirstChildWhichIsA("ProximityPrompt", true))
						local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
						
						if prompt and part and prompt.Enabled and prompt.ActionText == "Tambang" then
							foundAny = true
							EquipTool("Beliung Kayu")
							
							local sideDistance = 2.5
							if targetName == "BatuSedang" then
								sideDistance = 4.0
							elseif targetName == "BatuBesar" then
								sideDistance = 6.0
							end
							
							rootPart.CFrame = part.CFrame + (part.CFrame.RightVector * sideDistance) + Vector3.new(0, 1.5, 0)
							task.wait(0.3)
							
							pcall(function() prompt:InputHoldBegin() end)
							task.wait(prompt.HoldDuration or 1.0)
							pcall(function() prompt:InputHoldEnd() end)
							pcall(function() fireproximityprompt(prompt) end)
							
							local waitTime = getgenv().ConfigWait[targetName] or 5.8
							task.wait(waitTime)
						end
					end
				end
				if not foundAny then task.wait(1) end
			end)
		end

		-- 3. AUTO WOODCUTTING
		if getgenv().AutoWoodEnabled then
			pcall(function()
				local character = LocalPlayer.Character
				if not character or not character:FindFirstChild("HumanoidRootPart") then return end
				StabilizeCharacter(character)
				local rootPart = character.HumanoidRootPart
				local foundAny = false

				for _, obj in ipairs(Workspace:GetDescendants()) do
					if not getgenv().AutoWoodEnabled then break end
					
					local targetName = obj.Name
					local parentModel = obj.Parent
					if parentModel and getgenv().SelectedPohon[parentModel.Name] then
						targetName = parentModel.Name
					end
					
					if getgenv().SelectedPohon[targetName] then
						local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or (parentModel and parentModel:FindFirstChildWhichIsA("ProximityPrompt", true))
						local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
						
						if prompt and part and prompt.Enabled and prompt.ActionText == "Tebang" then
							foundAny = true
							EquipTool("Kapak Kayu")
							
							local sideDistance = 3.5
							if targetName == "PohonSedang" then
								sideDistance = 5.5
							elseif targetName == "PohonBesar" then
								sideDistance = 7.5
							end
							
							local targetPos = Vector3.new(part.Position.X, rootPart.Position.Y, part.Position.Z)
							rootPart.CFrame = CFrame.new(targetPos + (part.CFrame.RightVector * sideDistance), part.Position)
							
							task.wait(0.3)
							pcall(function() prompt:InputHoldBegin() end)
							task.wait(prompt.HoldDuration or 1.0)
							pcall(function() prompt:InputHoldEnd() end)
							pcall(function() fireproximityprompt(prompt) end)
							
							local waitTime = getgenv().ConfigWait[targetName] or 5.8
							task.wait(waitTime)
						end
					end
				end
				if not foundAny then task.wait(1) end
			end)
		end

		-- 4. AUTO TARUH KIOS OTOMATIS
		if getgenv().AutoTaruhEnabled then
			pcall(function()
				local eventPath = ReplicatedStorage:FindFirstChild("rc645e8ded8e146828f98af5123faf3a8")
				if eventPath then
					local remote = eventPath:FindFirstChild("r2c39d7b63e484766b0f0da9e3961ed82")
					if remote and remote:IsA("RemoteFunction") then
						remote:InvokeServer("taruh", getgenv().SelectedTaruhSlot, getgenv().SelectedTaruhItem)
					end
				end
			end)
			task.wait(3.0)
		end
	end
end)

----------------------------------------------------
-- FLOATING BUTTON HP & DRAG
----------------------------------------------------
local Float = Instance.new("ImageButton")
Float.Parent = Gui
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1,0)
FloatCorner.Parent = Float

Float.MouseButton1Click:Connect(function()
	if not getgenv().KeyVerified then
		KeyFrame.Visible = not KeyFrame.Visible
		Main.Visible = false
	else
		Main.Visible = not Main.Visible
		KeyFrame.Visible = false
	end
end)

local dragging = false
local dragStart, startPos

Float.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, Float.Position
	end
end)

UIS.TouchMoved:Connect(function(input)
	if dragging then
		local delta = input.Position - dragStart
		Float.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UIS.TouchEnded:Connect(function()
	dragging = false
end)
