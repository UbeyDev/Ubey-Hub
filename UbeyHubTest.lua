-- ==============================================================================
-- UBEY HUB V3 | Custom GUI + All-in-One Features
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
-- GLOBAL STATE VARIABEL
------------------------------------------------------------------
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

------------------------------------------------------------------
-- GUI UTAMA & KEY SYSTEM (Desain Kamu)
------------------------------------------------------------------
pcall(function()
    PlayerGui:FindFirstChild("UbeyHub"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UbeyHub"
Gui.Parent = PlayerGui
Gui.ResetOnSpawn = false

-- BLUR / OVERLAY
local Blur = Instance.new("Frame")
Blur.Parent = Gui
Blur.Size = UDim2.new(1,0,1,0)
Blur.BackgroundColor3 = Color3.fromRGB(0,0,0)
Blur.BackgroundTransparency = 0.35

-- KEY FRAME
local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = Gui
KeyFrame.Size = UDim2.new(0,0,0,0)
KeyFrame.Position = UDim2.new(0.5,-180,0.5,-120)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,18)
Corner.Parent = KeyFrame

local Stroke = Instance.new("UIStroke")
Stroke.Parent = KeyFrame
Stroke.Color = Color3.fromRGB(0,170,255)
Stroke.Thickness = 2

TweenService:Create(
	KeyFrame,
	TweenInfo.new(0.4,Enum.EasingStyle.Back),
	{Size = UDim2.new(0,360,0,240)}
):Play()

local Logo = Instance.new("ImageLabel")
Logo.Parent = KeyFrame
Logo.BackgroundTransparency = 1
Logo.Position = UDim2.new(0.5,-35,0,10)
Logo.Size = UDim2.new(0,70,0,70)
Logo.Image = "rbxassetid://90770802417381"

local Title = Instance.new("TextLabel")
Title.Parent = KeyFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0,0,0,85)
Title.Size = UDim2.new(1,0,0,30)
Title.Text = "UBEY HUB V3"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 22

local Box = Instance.new("TextBox")
Box.Parent = KeyFrame
Box.Position = UDim2.new(0.1,0,0,130)
Box.Size = UDim2.new(0.8,0,0,40)
Box.BackgroundColor3 = Color3.fromRGB(35,35,45)
Box.PlaceholderText = "Masukkan Key..."
Box.Text = ""
Box.TextColor3 = Color3.fromRGB(255,255,255)

local BoxCorner = Instance.new("UICorner")
BoxCorner.Parent = Box

local Submit = Instance.new("TextButton")
Submit.Parent = KeyFrame
Submit.Position = UDim2.new(0.1,0,0,180)
Submit.Size = UDim2.new(0.8,0,0,35)
Submit.Text = "VERIFY KEY"
Submit.BackgroundColor3 = Color3.fromRGB(0,170,255)
Submit.TextColor3 = Color3.new(1,1,1)

local SubmitCorner = Instance.new("UICorner")
SubmitCorner.Parent = Submit

------------------------------------------------------------------
-- MAIN HUB
------------------------------------------------------------------
local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Visible = false
Main.Size = UDim2.new(0,600,0,380)
Main.Position = UDim2.new(0.5,-300,0.5,-190)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,18)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(0,170,255)

local Sidebar = Instance.new("Frame")
Sidebar.Parent = Main
Sidebar.Size = UDim2.new(0,150,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,20)

local SideCorner = Instance.new("UICorner")
SideCorner.Parent = Sidebar

local HubTitle = Instance.new("TextLabel")
HubTitle.Parent = Sidebar
HubTitle.BackgroundTransparency = 1
HubTitle.Size = UDim2.new(1,0,0,60)
HubTitle.Text = "UBEY HUB"
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextColor3 = Color3.fromRGB(0,170,255)
HubTitle.TextSize = 20

-- TOMBOL SIDEBAR TAB
local FishingBtn = Instance.new("TextButton")
FishingBtn.Parent = Sidebar
FishingBtn.Position = UDim2.new(0,10,0,70)
FishingBtn.Size = UDim2.new(1,-20,0,35)
FishingBtn.Text = "Fishing & Sell"

local GalatamaBtn = FishingBtn:Clone()
GalatamaBtn.Parent = Sidebar
GalatamaBtn.Position = UDim2.new(0,10,0,115)
GalatamaBtn.Text = "Galatama"

local SummitBtn = FishingBtn:Clone()
SummitBtn.Parent = Sidebar
SummitBtn.Position = UDim2.new(0,10,0,160)
SummitBtn.Text = "Summit"

local PlayerTabBtn = FishingBtn:Clone()
PlayerTabBtn.Parent = Sidebar
PlayerTabBtn.Position = UDim2.new(0,10,0,205)
PlayerTabBtn.Text = "Player"

local PrivacyBtn = FishingBtn:Clone()
PrivacyBtn.Parent = Sidebar
PrivacyBtn.Position = UDim2.new(0,10,0,250)
PrivacyBtn.Text = "Privacy"

local SettingsBtn = FishingBtn:Clone()
SettingsBtn.Parent = Sidebar
SettingsBtn.Position = UDim2.new(0,10,0,295)
SettingsBtn.Text = "Settings"

local CreditsBtn = FishingBtn:Clone()
CreditsBtn.Parent = Sidebar
CreditsBtn.Position = UDim2.new(0,10,0,340)
CreditsBtn.Text = "Credits"

for _,v in ipairs({FishingBtn,GalatamaBtn,SummitBtn,PlayerTabBtn,PrivacyBtn,SettingsBtn,CreditsBtn}) do
	v.BackgroundColor3 = Color3.fromRGB(35,35,45)
	v.TextColor3 = Color3.fromRGB(255,255,255)
	v.Font = Enum.Font.GothamMedium
	v.TextSize = 13
	local c = Instance.new("UICorner")
	c.Parent = v
end

-- CONTENT AREA (SCROLLING FRAME UNTUK FITUR FITUR)
local Content = Instance.new("Frame")
Content.Parent = Main
Content.Position = UDim2.new(0,160,0,10)
Content.Size = UDim2.new(1,-170,1,-20)
Content.BackgroundTransparency = 1

local function MakePage()
	local sf = Instance.new("ScrollingFrame")
	sf.Parent = Content
	sf.Size = UDim2.new(1,0,1,0)
	sf.BackgroundTransparency = 1
	sf.CanvasSize = UDim2.new(0,0,2,0)
	sf.ScrollBarThickness = 4
	sf.Visible = false
	
	local layout = Instance.new("UIListLayout")
	layout.Parent = sf
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	return sf
end

local FishingPage = MakePage()
FishingPage.Visible = true
local GalatamaPage = MakePage()
local SummitPage = MakePage()
local PlayerPage = MakePage()
local PrivacyPage = MakePage()
local SettingsPage = MakePage()
local CreditsPage = MakePage()

local function HideAll()
	FishingPage.Visible = false
	GalatamaPage.Visible = false
	SummitPage.Visible = false
	PlayerPage.Visible = false
	PrivacyPage.Visible = false
	SettingsPage.Visible = false
	CreditsPage.Visible = false
end

FishingBtn.MouseButton1Click:Connect(function() HideAll(); FishingPage.Visible = true end)
GalatamaBtn.MouseButton1Click:Connect(function() HideAll(); GalatamaPage.Visible = true end)
SummitBtn.MouseButton1Click:Connect(function() HideAll(); SummitPage.Visible = true end)
PlayerTabBtn.MouseButton1Click:Connect(function() HideAll(); PlayerPage.Visible = true end)
PrivacyBtn.MouseButton1Click:Connect(function() HideAll(); PrivacyPage.Visible = true end)
SettingsBtn.MouseButton1Click:Connect(function() HideAll(); SettingsPage.Visible = true end)
CreditsBtn.MouseButton1Click:Connect(function() HideAll(); CreditsPage.Visible = true end)

------------------------------------------------------------------
-- PEMBUATAN ELEMEN UI CUSTOM (HELPER KOMPONEN)
------------------------------------------------------------------
local function CreateLabel(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.Parent = parent
	lbl.Size = UDim2.new(1, 0, 0, 30)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local function CreateButton(parent, text, callback)
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(0,170,255)
	btn.Text = text
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	local c = Instance.new("UICorner")
	c.Parent = btn
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function CreateToggle(parent, text, default, callback)
	local f = Instance.new("TextButton")
	f.Parent = parent
	f.Size = UDim2.new(1, 0, 0, 35)
	f.BackgroundColor3 = Color3.fromRGB(30,30,40)
	f.Text = "  " .. text .. (default and " [ON]" else " [OFF]")
	f.TextColor3 = Color3.fromRGB(255,255,255)
	f.Font = Enum.Font.Gotham
	f.TextSize = 13
	f.TextXAlignment = Enum.TextXAlignment.Left
	local c = Instance.new("UICorner")
	c.Parent = f
	
	local state = default
	f.MouseButton1Click:Connect(function()
		state = not state
		f.Text = "  " .. text .. (state and " [ON]" else " [OFF]")
		f.BackgroundColor3 = state and Color3.fromRGB(0,100,180) or Color3.fromRGB(30,30,40)
		callback(state)
	end)
end

local function CreateInput(parent, placeholder, callback)
	local box = Instance.new("TextBox")
	box.Parent = parent
	box.Size = UDim2.new(1, 0, 0, 35)
	box.BackgroundColor3 = Color3.fromRGB(35,35,45)
	box.PlaceholderText = placeholder
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255,255,255)
	box.Font = Enum.Font.Gotham
	box.TextSize = 13
	local c = Instance.new("UICorner")
	c.Parent = box
	box.FocusLost:Connect(function()
		callback(box.Text)
	end)
	return box
end

------------------------------------------------------------------
-- ISI KONTEN MASING-MASING TAB (Fungsi Asli Tidak Berubah)
------------------------------------------------------------------

-- TAB 1: FISHING
CreateLabel(FishingPage, "⚡ Auto Farm Fishing & Location")
CreateButton(FishingPage, "⚡ Bypass & Fast Rod (Set 0.05s)", function()
	OptimizeRodSettings()
end)

CreateToggle(FishingPage, "Smart Auto Fishing + Teleport Spot", false, function(Value)
	getgenv().AutoFishingEventRunning = Value
	if Value then
		pcall(function()
			local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			local targetCFrame = FishingSpots[getgenv().SelectedFishingSpot]
			if hrp and targetCFrame then
				hrp.CFrame = targetCFrame
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

CreateToggle(FishingPage, "Smart Auto Fishing (Di Tempat Saja)", false, function(Value)
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

CreateLabel(FishingPage, "Bite Delay (Ketik Detik):")
CreateInput(FishingPage, "Contoh: 0.5", function(val) getgenv().BiteDelayInput = val end)

CreateLabel(FishingPage, "--- Auto Sell Timer ke NPC ---")
CreateToggle(FishingPage, "Aktifkan Auto Sell Timer", false, function(Value)
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
				end
			end
		end)
	end
end)
CreateInput(FishingPage, "Jeda Waktu Menit (Cth: 5)", function(val) getgenv().AutoSellTimerInput = val end)


-- TAB 2: GALATAMA
CreateLabel(GalatamaPage, "🏆 Auto Event Galatama")
CreateToggle(GalatamaPage, "Aktifkan Auto Join Galatama", false, function(Value)
	getgenv().AutoGalatamaRunning = Value
	if Value then
		task.spawn(function()
			while getgenv().AutoGalatamaRunning do
				pcall(function()
					local glatamaFolder = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Glatama")
					local ikutRemote = glatamaFolder and glatamaFolder:FindFirstChild("Ikut")
					if ikutRemote then
						ikutRemote:InvokeServer()
					end
				end)
				task.wait(10)
			end
		end)
	end
end)


-- TAB 3: SUMMIT
CreateLabel(SummitPage, "⛰️ Auto Summit Farm")
local summitCFrame = CFrame.new(-6766.44629, 1312.69983, -10083.8037, -0.993305981, 1.64907146e-08, 0.115513086, 1.58947078e-08, 1, -6.08075279e-09, -0.115513086, -4.20400115e-09, -0.993305981)
local bcCFrame = CFrame.new(-6834.84912, 1310.24744, -9902.42285, -1, 0, 0, 0, 1, 0, 0, 0, -1)

CreateToggle(SummitPage, "Auto Summit Loop", false, function(Value)
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


-- TAB 4: PLAYER
CreateLabel(PlayerPage, "👤 Pengaturan Karakter")
CreateLabel(PlayerPage, "Ubah WalkSpeed (Ketik Angka 1-350):")
CreateInput(PlayerPage, "WalkSpeed default 16", function(val)
	local num = tonumber(val)
	if num then
		pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = num end)
	end
end)

CreateToggle(PlayerPage, "Anti-AFK", false, function(Value)
	getgenv().AntiAFKRunning = Value
end)

LocalPlayer.Idled:Connect(function()
	if getgenv().AntiAFKRunning then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end
end)


-- TAB 5: PRIVACY
CreateLabel(PrivacyPage, "🛡️ Privacy Mode & Creator Mode")
CreateLabel(PrivacyPage, "Nama Samaran (Fake Name):")
CreateInput(PrivacyPage, "UBEY HUB", function(val)
	if val ~= "" then getgenv().FakeNameInput = val end
end)

CreateToggle(PrivacyPage, "Aktifkan Privacy Mode", false, function(Value)
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
					end
				end)
				task.wait(1)
			end
		end)
	end
end)


-- TAB 6: SETTINGS
local SettingsLabel = Instance.new("TextLabel")
SettingsLabel.Parent = SettingsPage
SettingsLabel.Size = UDim2.new(1,0,0,40)
SettingsLabel.BackgroundTransparency = 1
SettingsLabel.TextColor3 = Color3.new(1,1,1)
SettingsLabel.Font = Enum.Font.GothamBold
SettingsLabel.TextSize = 18
SettingsLabel.Text = "Halaman Settings"

CreateButton(SettingsPage, "Tutup / Hide UI", function()
	Main.Visible = false
end)


-- TAB 7: CREDITS
local CreditsLabel = Instance.new("TextLabel")
CreditsLabel.Parent = CreditsPage
CreditsLabel.Size = Instance.new("TextLabel") and UDim2.new(1,0,0,40)
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.TextColor3 = Color3.new(1,1,1)
CreditsLabel.Font = Enum.Font.GothamBold
CreditsLabel.TextSize = 18
CreditsLabel.Text = "Created By UBEY"


------------------------------------------------------------------
-- KEY VERIFY EVENT
------------------------------------------------------------------
Submit.MouseButton1Click:Connect(function()
	if validateKey(Box.Text) then
		KeyFrame.Visible = false
		Blur.Visible = false
		Main.Visible = true
	else
		Submit.Text = "KEY SALAH"
		task.wait(1)
		Submit.Text = "VERIFY KEY"
	end
end)

------------------------------------------------------------------
-- FLOATING BUTTON HP & DRAG SYSTEM
------------------------------------------------------------------
local Float = Instance.new("ImageButton")
Float.Parent = Gui
Float.Size = UDim2.new(0,65,0,65)
Float.Position = UDim2.new(0,20,0,120)
Float.Image = "rbxassetid://90770802417381"
Float.BackgroundColor3 = Color3.fromRGB(20,20,25)

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1,0)
FloatCorner.Parent = Float

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Parent = Float
FloatStroke.Color = Color3.fromRGB(0,170,255)

local Open = false
Float.MouseButton1Click:Connect(function()
	Open = not Open
	Main.Visible = Open
end)

local dragging = false
local dragStart
local startPos

Float.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Float.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		Float.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
