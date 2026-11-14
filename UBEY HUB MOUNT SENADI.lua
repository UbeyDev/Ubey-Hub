local SCRIPT_NAME = "merged"
local KEY_FILE = "UbeyHub_SavedKey.txt"
local FUNCTION_URL = "https://vwwxvemxeztfiyuurhro.supabase.co/functions/v1/verify-key"
local ANON_KEY = "sb_publishable_rMWL7Qrjw9iG0c29vGZ0bw_O3swXT6n"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Rbx = game:GetService("RbxAnalyticsService")
local LocalPlayer = Players.LocalPlayer
local function getHwid()
	local h
	pcall(function()
		if gethwid then h = gethwid() else h = Rbx:GetClientId() end
	end)
	return tostring(h or ("UNKNOWN_" .. LocalPlayer.UserId))
end
local function httpRequest(body)
	local req = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
	if not req then return nil, "Executor tidak mendukung request HTTP." end
	local ok, res = pcall(req, {
		Url = FUNCTION_URL, Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["apikey"] = ANON_KEY,
			["Authorization"] = "Bearer " .. ANON_KEY,
		},
		Body = HttpService:JSONEncode(body),
	})
	if not ok or not res then return nil, "Gagal terhubung ke server." end
	local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body or "") end)
	if not ok2 or type(data) ~= "table" then return nil, "Respon server tidak valid." end
	return data
end
local function tryKey(key)
	key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if key == "" then return false, "Masukkan key dulu." end
	local data, err = httpRequest({
		action = "verify", key = key, hwid = getHwid(),
		username = LocalPlayer.Name, userId = LocalPlayer.UserId,
		placeId = game.PlaceId, script = SCRIPT_NAME,
	})
	if not data then return false, err end
	if not data.ok then return false, tostring(data.reason or "Key tidak valid.") end
	if type(data.script) ~= "string" or data.script == "" then
		return false, "Script belum tersedia, hubungi admin."
	end
	pcall(function() if writefile then writefile(KEY_FILE, key) end end)
	if not loadstring then return false, "Executor tidak mendukung loadstring." end
	local fn, cerr = loadstring(data.script)
	if not fn then return false, "Script rusak: " .. tostring(cerr) end
	task.spawn(fn)
	return true
end
local savedKey
pcall(function() savedKey = getgenv().script_key end)
if not savedKey or savedKey == "" then
	pcall(function()
		if readfile and isfile and isfile(KEY_FILE) then savedKey = readfile(KEY_FILE) end
	end)
end
if savedKey and savedKey ~= "" then
	local ok = tryKey(savedKey)
	if ok then return end
end
local parent
for _, f in ipairs({
	function() return gethui and gethui() end,
	function() return CoreGui end,
	function() return LocalPlayer:WaitForChild("PlayerGui") end,
}) do
	local ok, p = pcall(f)
	if ok and p then parent = p; break end
end
local gui = Instance.new("ScreenGui")
gui.Name = "UbeyLoader"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = parent
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 190)
frame.Position = UDim2.new(0.5, -170, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(9, 12, 26)
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -30, 0, 28)
title.Position = UDim2.new(0, 15, 0, 10)
title.Text = "UBEY HUB - Masukkan Key"
title.TextColor3 = Color3.fromRGB(240, 243, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -30, 0, 38)
box.Position = UDim2.new(0, 15, 0, 48)
box.BackgroundColor3 = Color3.fromRGB(15, 21, 44)
box.PlaceholderText = "Paste key di sini..."
box.PlaceholderColor3 = Color3.fromRGB(150, 160, 195)
box.Text = ""
box.TextColor3 = Color3.fromRGB(240, 243, 255)
box.Font = Enum.Font.Gotham
box.TextSize = 13
box.ClearTextOnFocus = false
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -30, 0, 38)
btn.Position = UDim2.new(0, 15, 0, 96)
btn.BackgroundColor3 = Color3.fromRGB(45, 95, 255)
btn.Text = "Verifikasi & Jalankan"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -30, 0, 36)
status.Position = UDim2.new(0, 15, 0, 142)
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 80, 80)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true
status.Parent = frame
local busy = false
btn.MouseButton1Click:Connect(function()
	if busy then return end
	busy = true
	status.TextColor3 = Color3.fromRGB(255, 200, 0)
	status.Text = "Memeriksa key..."
	local ok, msg = tryKey(box.Text)
	busy = false
	if ok then
		gui:Destroy()
	else
		status.TextColor3 = Color3.fromRGB(255, 80, 80)
		status.Text = tostring(msg)
	end
end)
