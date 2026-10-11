-- DANZ HUB | AUTO FISHING (AUTO ROD DETECT + GUI)
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 1. PEMBERSIHAN GUI LAMA (Jika Re-execute)
if CoreGui:FindFirstChild("DanzHubFishingUI") then
	CoreGui.DanzHubFishingUI:Destroy()
end

getgenv().AutoExactSeq = false

-- 2. VARIABEL DELAY DEFAULT
getgenv().CastDelay = 0.25   -- Delay setelah lempar kail
getgenv().MiniDelay = 0.30   -- Delay minigame
getgenv().GiveDelay = 0.20   -- Delay klaim ikan

-- 3. MEMBUAT TAMPILAN GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DanzHubFishingUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 230, 0, 260)
MainFrame.Position = UDim2.new(0.5, -115, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "DANZ HUB - AUTO FISHING"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- DISPLAY ROD STATUS
local RodLabel = Instance.new("TextLabel")
RodLabel.Size = UDim2.new(0.85, 0, 0, 20)
RodLabel.Position = UDim2.new(0.075, 0, 0.16, 0)
RodLabel.Text = "Rod: Detecting..."
RodLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
RodLabel.BackgroundTransparency = 1
RodLabel.Font = Enum.Font.SourceSansItalic
RodLabel.TextSize = 13
RodLabel.Parent = MainFrame

-- TOMBOL ON / OFF
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.85, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.075, 0, 0.26, 0)
ToggleBtn.Text = "AUTO FISH: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 15
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

-- INPUT DELAY 1 (CAST)
local CastLabel = Instance.new("TextLabel")
CastLabel.Size = UDim2.new(0.5, 0, 0, 25)
CastLabel.Position = UDim2.new(0.075, 0, 0.45, 0)
CastLabel.Text = "Cast Delay (s):"
CastLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CastLabel.TextXAlignment = Enum.TextXAlignment.Left
CastLabel.BackgroundTransparency = 1
CastLabel.Font = Enum.Font.SourceSans
CastLabel.TextSize = 13
CastLabel.Parent = MainFrame

local CastBox = Instance.new("TextBox")
CastBox.Size = UDim2.new(0.35, 0, 0, 25)
CastBox.Position = UDim2.new(0.575, 0, 0.45, 0)
CastBox.Text = tostring(getgenv().CastDelay)
CastBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CastBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
CastBox.Font = Enum.Font.SourceSansBold
CastBox.TextSize = 13
CastBox.Parent = MainFrame

-- INPUT DELAY 2 (MINIGAME)
local MiniLabel = Instance.new("TextLabel")
MiniLabel.Size = UDim2.new(0.5, 0, 0, 25)
MiniLabel.Position = UDim2.new(0.075, 0, 0.58, 0)
MiniLabel.Text = "Mini Delay (s):"
MiniLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
MiniLabel.TextXAlignment = Enum.TextXAlignment.Left
MiniLabel.BackgroundTransparency = 1
MiniLabel.Font = Enum.Font.SourceSans
MiniLabel.TextSize = 13
MiniLabel.Parent = MainFrame

local MiniBox = Instance.new("TextBox")
MiniBox.Size = UDim2.new(0.35, 0, 0, 25)
MiniBox.Position = UDim2.new(0.575, 0, 0.58, 0)
MiniBox.Text = tostring(getgenv().MiniDelay)
MiniBox.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MiniBox.Font = Enum.Font.SourceSansBold
MiniBox.TextSize = 13
MiniBox.Parent = MainFrame

-- INPUT DELAY 3 (GIVE)
local GiveLabel = Instance.new("TextLabel")
GiveLabel.Size = UDim2.new(0.5, 0, 0, 25)
GiveLabel.Position = UDim2.new(0.075, 0, 0.71, 0)
GiveLabel.Text = "Claim Delay (s):"
GiveLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
GiveLabel.TextXAlignment = Enum.TextXAlignment.Left
GiveLabel.BackgroundTransparency = 1
GiveLabel.Font = Enum.Font.SourceSans
GiveLabel.TextSize = 13
GiveLabel.Parent = MainFrame

local GiveBox = Instance.new("TextBox")
GiveBox.Size = UDim2.new(0.35, 0, 0, 25)
GiveBox.Position = UDim2.new(0.575, 0, 0.71, 0)
GiveBox.Text = tostring(getgenv().GiveDelay)
GiveBox.TextColor3 = Color3.fromRGB(255, 255, 255)
GiveBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
GiveBox.Font = Enum.Font.SourceSansBold
GiveBox.TextSize = 13
GiveBox.Parent = MainFrame

-- LOGIKA TAMPILAN DAN EVENT
ToggleBtn.MouseButton1Click:Connect(function()
	getgenv().AutoExactSeq = not getgenv().AutoExactSeq
	if getgenv().AutoExactSeq then
		ToggleBtn.Text = "AUTO FISH: ON"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	else
		ToggleBtn.Text = "AUTO FISH: OFF"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end
end)

CastBox.FocusLost:Connect(function()
	local val = tonumber(CastBox.Text)
	if val then getgenv().CastDelay = val else CastBox.Text = tostring(getgenv().CastDelay) end
end)

MiniBox.FocusLost:Connect(function()
	local val = tonumber(MiniBox.Text)
	if val then getgenv().MiniDelay = val else MiniBox.Text = tostring(getgenv().MiniDelay) end
end)

GiveBox.FocusLost:Connect(function()
	local val = tonumber(GiveBox.Text)
	if val then getgenv().GiveDelay = val else GiveBox.Text = tostring(getgenv().GiveDelay) end
end)

-- FUNGSI UNTUK MEMBACA PANCINGAN YANG SEDANG DIPEGANG
local function GetEquippedRodName()
	local char = LocalPlayer.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			return tool.Name
		end
	end
	return "Basic Rod" -- Fallback jika tidak terdeteksi
end

-- 4. LOGIKA UTAMA AUTO FISHING
task.spawn(function()
	while true do
		task.wait(0.1)
		
		-- Update tampilan label pancingan
		local currentRod = GetEquippedRodName()
		RodLabel.Text = "Rod: " .. currentRod
		
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
				
				local pos = hrp.Position + Vector3.new(0, 2, 0)
				local lookVec = hrp.CFrame.LookVector * 15
				local hook = pos + lookVec - Vector3.new(0, 5, 0)
				
				-- 1. Lempar Kail dengan Rod yang sedang dipegang
				if cast then
					cast:FireServer(pos, Vector3.new(-24.72, 5, 3.71), currentRod, 100)
				end
				
				task.wait(getgenv().CastDelay)
				if not getgenv().AutoExactSeq then return end
				
				-- 2. Memulai Minigame
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
				
				-- 4. Mengambil Ikan (FishGiver)
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
