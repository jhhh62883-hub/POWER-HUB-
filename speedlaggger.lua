print("Exe Speed Bypass loaded")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Black / white / gray color scheme
local C_BG = Color3.fromRGB(0, 0, 0)
local C_PANEL = Color3.fromRGB(30, 30, 30)
local C_ROW = Color3.fromRGB(60, 60, 60)
local C_NEON = Color3.fromRGB(255, 255, 255)
local C_MINT = Color3.fromRGB(200, 200, 200)
local C_MID = Color3.fromRGB(120, 120, 120)
local C_DIM = Color3.fromRGB(80, 80, 80)
local C_EDGE = Color3.fromRGB(50, 50, 50)
local C_EDGE2 = Color3.fromRGB(100, 100, 100)

local GUI_NAME = "Exe Speed Bypass"
local WM_NAME = "IrishWatermark" -- unused, kept for compatibility

-- Scaling factor for a smaller UI
local S = 0.8

local function safeParent()
	local ok, hidden = pcall(function()
		return (gethui and gethui()) or (get_hidden_gui and get_hidden_gui())
	end)
	if ok and typeof(hidden) == "Instance" then return hidden end
	if pcall(function() return CoreGui.Name end) then return CoreGui end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local Parent = safeParent()

-- Clean old instances
for _, v in ipairs(Parent:GetChildren()) do
	if v.Name == GUI_NAME then pcall(function() v:Destroy() end) end
end
pcall(function()
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg and pg:FindFirstChild(WM_NAME) then pg[WM_NAME]:Destroy() end
end)

-- Remove old sound
pcall(function()
	local old = SoundService:FindFirstChild("MachoBell")
	if old then old:Destroy() end
end)

-- Bell sound (created but never played)
local Bell = Instance.new("Sound")
Bell.Name = "MachoBell"
Bell.SoundId = "rbxassetid://7149373060"
Bell.Volume = 0.55
Bell.PlaybackSpeed = 1.05
Bell.Parent = SoundService

local State = {
	Mode = "PC",
	Power = 97000,
	Active = false,
	Keybind = Enum.KeyCode.V,
	Binding = false,
	Hidden = false,
	Minimized = false,
	Locked = false,
}

local lagConn = nil
local lagAmount = 0.15

local function applyPower(val)
	State.Power = math.clamp(math.floor(val), 9000, 500000)
	local t = (State.Power - 10000) / 490000
	if t < 0 then t = 0 end
	lagAmount = t * 0.2
end
applyPower(State.Power)

local function startLag()
	if lagConn then lagConn:Disconnect() end
	lagConn = RunService.RenderStepped:Connect(function()
		if not State.Active then return end
		if lagAmount > 0 then
			local t = tick()
			while tick() - t < lagAmount do end
		end
	end)
end

local function stopLag()
	if lagConn then
		lagConn:Disconnect()
		lagConn = nil
	end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = Parent

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r * S)
	c.Parent = p
	return c
end

local function stroke(p, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = th * S
	s.Parent = p
	return s
end

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Active = true
Main.ClipsDescendants = true
Main.Position = UDim2.new(0.5, -165 * S, 0.5, -167 * S)
Main.Size = UDim2.new(0, 330 * S, 0, 334 * S)
Main.BackgroundColor3 = C_BG
Main.BackgroundTransparency = 0
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
corner(Main, 28)

local MainScale = Instance.new("UIScale")
MainScale.Scale = 1
MainScale.Parent = Main

local MainStroke = stroke(Main, C_NEON, 3.2)

local MainGrad = Instance.new("UIGradient")
MainGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(20, 20, 20)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(200, 200, 200)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(200, 200, 200)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(20, 20, 20)),
})
MainGrad.Rotation = 0
MainGrad.Parent = MainStroke

local MainImg = Instance.new("ImageLabel")
MainImg.Size = UDim2.new(1, 0, 1, 0)
MainImg.Position = UDim2.new(0, 0, 0, 0)
MainImg.BackgroundTransparency = 1
MainImg.Image = "rbxassetid://129700697019613"
MainImg.ImageTransparency = 0.22
MainImg.ScaleType = Enum.ScaleType.Crop
MainImg.ZIndex = 2
MainImg.Parent = Main
corner(MainImg, 28)

local MainTint = Instance.new("Frame")
MainTint.Size = UDim2.new(1, 0, 1, 0)
MainTint.BackgroundColor3 = C_BG
MainTint.BackgroundTransparency = 0.38
MainTint.BorderSizePixel = 0
MainTint.ZIndex = 3
MainTint.Parent = Main
corner(MainTint, 28)

local TintGrad = Instance.new("UIGradient")
TintGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, C_PANEL),
	ColorSequenceKeypoint.new(0.5, C_BG),
	ColorSequenceKeypoint.new(1.0, C_BG),
})
TintGrad.Rotation = 150
TintGrad.Parent = MainTint

-- Title
local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Text = "Exe Speed Bypass"
Title.TextSize = 19 * S
Title.TextColor3 = C_MINT
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 10
Title.Position = UDim2.new(0, 18 * S, 0, 12 * S)
Title.Size = UDim2.new(1, -105 * S, 0, 26 * S)
Title.Parent = Main

local SubTitle = Instance.new("TextLabel")
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "discord.gg/ZvERp8sHq · FREE"
SubTitle.TextSize = 10 * S
SubTitle.TextColor3 = C_DIM
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.ZIndex = 10
SubTitle.Position = UDim2.new(0, 18 * S, 0, 38 * S)
SubTitle.Size = UDim2.new(1, -105 * S, 0, 14 * S)
SubTitle.Parent = Main

-- Lock / Unlock button (next to minimize)
local LockBtn = Instance.new("TextButton")
LockBtn.Position = UDim2.new(1, -74 * S, 0, 14 * S)
LockBtn.Size = UDim2.new(0, 28 * S, 0, 28 * S)
LockBtn.BackgroundColor3 = C_ROW
LockBtn.BorderSizePixel = 0
LockBtn.Text = "🔓"
LockBtn.TextColor3 = C_MID
LockBtn.TextSize = 13 * S
LockBtn.Font = Enum.Font.GothamBlack
LockBtn.AutoButtonColor = false
LockBtn.ZIndex = 10
LockBtn.Parent = Main
corner(LockBtn, 10)
stroke(LockBtn, C_EDGE, 1.5)

local MinBtn = Instance.new("TextButton")
MinBtn.Position = UDim2.new(1, -42 * S, 0, 14 * S)
MinBtn.Size = UDim2.new(0, 28 * S, 0, 28 * S)
MinBtn.BackgroundColor3 = C_ROW
MinBtn.BorderSizePixel = 0
MinBtn.Text = "-"
MinBtn.TextColor3 = C_MID
MinBtn.TextSize = 14 * S
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.AutoButtonColor = false
MinBtn.ZIndex = 10
MinBtn.Parent = Main
corner(MinBtn, 10)
stroke(MinBtn, C_EDGE, 1.5)

local Divider = Instance.new("Frame")
Divider.Position = UDim2.new(0, 14 * S, 0, 64 * S)
Divider.Size = UDim2.new(1, -28 * S, 0, 1)
Divider.BackgroundColor3 = C_NEON
Divider.BorderSizePixel = 0
Divider.ZIndex = 10
Divider.Parent = Main

local DivGrad = Instance.new("UIGradient")
DivGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.new(0, 0, 0)),
	ColorSequenceKeypoint.new(0.35, C_NEON),
	ColorSequenceKeypoint.new(0.65, C_NEON),
	ColorSequenceKeypoint.new(1.00, Color3.new(0, 0, 0)),
})
DivGrad.Parent = Divider

local Body = Instance.new("Frame")
Body.Position = UDim2.new(0, 14 * S, 0, 76 * S)
Body.Size = UDim2.new(1, -28 * S, 0, 216 * S)
Body.BackgroundTransparency = 1
Body.ZIndex = 7
Body.Parent = Main

local function makeRow(y, height, labelText)
	local row = Instance.new("Frame")
	row.Position = UDim2.new(0, 0, 0, y * S)
	row.Size = UDim2.new(1, 0, 0, height * S)
	row.BackgroundColor3 = C_PANEL
	row.BackgroundTransparency = 0.18
	row.BorderSizePixel = 0
	row.ZIndex = 8
	row.Parent = Body
	corner(row, 14)
	stroke(row, C_EDGE, 1.2)

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C_ROW),
		ColorSequenceKeypoint.new(1, C_BG),
	})
	g.Rotation = 180
	g.Parent = row

	local tick = Instance.new("Frame")
	tick.Position = UDim2.new(0, 0, 0.5, -14 * S)
	tick.Size = UDim2.new(0, 3, 0, 28 * S)
	tick.BackgroundColor3 = C_NEON
	tick.BorderSizePixel = 0
	tick.ZIndex = 9
	tick.Parent = row
	corner(tick, 4)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextSize = 12 * S
	lbl.TextColor3 = C_MID
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 9
	lbl.Position = UDim2.new(0, 16 * S, 0, 0)
	lbl.Size = UDim2.new(0.42, 0, 1, 0)
	lbl.Parent = row

	return row
end

local ModeRow = makeRow(0, 44, "Mode")

local PCBtn = Instance.new("TextButton")
PCBtn.Position = UDim2.new(1, -186 * S, 0.5, -14 * S)
PCBtn.Size = UDim2.new(0, 84 * S, 0, 28 * S)
PCBtn.BackgroundColor3 = C_NEON
PCBtn.BorderSizePixel = 0
PCBtn.Text = "PC"
PCBtn.TextColor3 = C_BG
PCBtn.TextSize = 11 * S
PCBtn.Font = Enum.Font.GothamBold
PCBtn.AutoButtonColor = false
PCBtn.ZIndex = 9
PCBtn.Parent = ModeRow
corner(PCBtn, 10)
stroke(PCBtn, C_EDGE, 1.5)

local MobileBtn = Instance.new("TextButton")
MobileBtn.Position = UDim2.new(1, -96 * S, 0.5, -14 * S)
MobileBtn.Size = UDim2.new(0, 88 * S, 0, 28 * S)
MobileBtn.BackgroundColor3 = C_ROW
MobileBtn.BorderSizePixel = 0
MobileBtn.Text = "MOBILE"
MobileBtn.TextColor3 = C_DIM
MobileBtn.TextSize = 11 * S
MobileBtn.Font = Enum.Font.GothamBold
MobileBtn.AutoButtonColor = false
MobileBtn.ZIndex = 9
MobileBtn.Parent = ModeRow
corner(MobileBtn, 10)
stroke(MobileBtn, C_EDGE, 1.5)

local PowerRow = makeRow(54, 44, "Power")

local PowerBox = Instance.new("TextBox")
PowerBox.Position = UDim2.new(1, -112 * S, 0.5, -14 * S)
PowerBox.Size = UDim2.new(0, 104 * S, 0, 28 * S)
PowerBox.BackgroundColor3 = C_BG
PowerBox.BorderSizePixel = 0
PowerBox.Text = tostring(State.Power)
PowerBox.TextColor3 = C_MINT
PowerBox.TextSize = 12 * S
PowerBox.Font = Enum.Font.GothamBold
PowerBox.PlaceholderText = "Power"
PowerBox.PlaceholderColor3 = C_DIM
PowerBox.ClearTextOnFocus = false
PowerBox.ZIndex = 9
PowerBox.Parent = PowerRow
corner(PowerBox, 10)
stroke(PowerBox, C_EDGE2, 1.5)

local BypassRow = makeRow(108, 56, "Bypass")

local KeyBtn = Instance.new("TextButton")
KeyBtn.Position = UDim2.new(1, -182 * S, 0.5, -18 * S)
KeyBtn.Size = UDim2.new(0, 60 * S, 0, 36 * S)
KeyBtn.BackgroundColor3 = C_ROW
KeyBtn.BorderSizePixel = 0
KeyBtn.Text = State.Keybind.Name
KeyBtn.TextColor3 = C_MID
KeyBtn.TextSize = 13 * S
KeyBtn.Font = Enum.Font.GothamBold
KeyBtn.AutoButtonColor = false
KeyBtn.ZIndex = 9
KeyBtn.Parent = BypassRow
corner(KeyBtn, 12)
stroke(KeyBtn, C_EDGE, 1.8)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Position = UDim2.new(1, -116 * S, 0.5, -18 * S)
ToggleBtn.Size = UDim2.new(0, 108 * S, 0, 36 * S)
ToggleBtn.BackgroundColor3 = C_ROW
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "OFF"
ToggleBtn.TextColor3 = C_MID
ToggleBtn.TextSize = 13 * S
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = false
ToggleBtn.ZIndex = 9
ToggleBtn.Parent = BypassRow
corner(ToggleBtn, 12)
stroke(ToggleBtn, C_EDGE, 1.8)

local Footer = Instance.new("Frame")
Footer.Position = UDim2.new(0, 14 * S, 0, 300 * S)
Footer.Size = UDim2.new(1, -28 * S, 0, 22 * S)
Footer.BackgroundColor3 = C_PANEL
Footer.BackgroundTransparency = 0.28
Footer.BorderSizePixel = 0
Footer.ZIndex = 8
Footer.Parent = Main
corner(Footer, 10)
stroke(Footer, C_EDGE, 1)

local FootL = Instance.new("TextLabel")
FootL.BackgroundTransparency = 1
FootL.Text = "discord.gg/ZvERp8sHq"
FootL.TextSize = 9 * S
FootL.TextColor3 = C_DIM
FootL.Font = Enum.Font.GothamMedium
FootL.TextXAlignment = Enum.TextXAlignment.Left
FootL.ZIndex = 9
FootL.Position = UDim2.new(0, 10 * S, 0, 0)
FootL.Size = UDim2.new(0.45, 0, 1, 0)
FootL.Parent = Footer

local FootR = Instance.new("TextLabel")
FootR.BackgroundTransparency = 1
FootR.Text = "97000 pwr | LCTRL"
FootR.TextSize = 9 * S
FootR.TextColor3 = C_DIM
FootR.Font = Enum.Font.GothamMedium
FootR.TextXAlignment = Enum.TextXAlignment.Right
FootR.ZIndex = 9
FootR.Position = UDim2.new(0.45, 0, 0, 0)
FootR.Size = UDim2.new(0.55, -10 * S, 1, 0)
FootR.Parent = Footer

-- Mini
local Mini = Instance.new("Frame")
Mini.Name = "Mini"
Mini.Active = true
Mini.Visible = false
Mini.ClipsDescendants = true
Mini.Position = UDim2.new(0.5, -165 * S, 0.5, -167 * S)
Mini.Size = UDim2.new(0, 330 * S, 0, 66 * S)
Mini.BackgroundColor3 = C_BG
Mini.BorderSizePixel = 0
Mini.Parent = ScreenGui
corner(Mini, 28)

local MiniScale = Instance.new("UIScale")
MiniScale.Scale = 1
MiniScale.Parent = Mini

local MiniStroke = stroke(Mini, C_NEON, 3.2)
local MiniGrad = MainGrad:Clone()
MiniGrad.Parent = MiniStroke

local MiniImg = MainImg:Clone()
MiniImg.Parent = Mini

local MiniTint = Instance.new("Frame")
MiniTint.Size = UDim2.new(1, 0, 1, 0)
MiniTint.BackgroundColor3 = C_BG
MiniTint.BackgroundTransparency = 0.38
MiniTint.BorderSizePixel = 0
MiniTint.ZIndex = 3
MiniTint.Parent = Mini
corner(MiniTint, 28)

local MiniLbl = Instance.new("TextLabel")
MiniLbl.BackgroundTransparency = 1
MiniLbl.Text = "Exe Speed Bypass · discord.gg/ZvERp8sHq"
MiniLbl.TextSize = 13 * S
MiniLbl.TextColor3 = C_MINT
MiniLbl.Font = Enum.Font.GothamBlack
MiniLbl.TextXAlignment = Enum.TextXAlignment.Left
MiniLbl.ZIndex = 8
MiniLbl.Position = UDim2.new(0, 18 * S, 0, 0)
MiniLbl.Size = UDim2.new(1, -70 * S, 1, 0)
MiniLbl.Parent = MiniTint

local MaxBtn = Instance.new("TextButton")
MaxBtn.Position = UDim2.new(1, -42 * S, 0.5, -14 * S)
MaxBtn.Size = UDim2.new(0, 28 * S, 0, 28 * S)
MaxBtn.BackgroundColor3 = C_ROW
MaxBtn.BorderSizePixel = 0
MaxBtn.Text = "+"
MaxBtn.TextColor3 = C_MID
MaxBtn.TextSize = 16 * S
MaxBtn.Font = Enum.Font.GothamBlack
MaxBtn.AutoButtonColor = false
MaxBtn.ZIndex = 8
MaxBtn.Parent = MiniTint
corner(MaxBtn, 10)
stroke(MaxBtn, C_EDGE, 1.5)

-- WATERMARK REMOVED (no floating label above player)

local function refreshFooter()
	FootR.Text = tostring(State.Power) .. " pwr | LCTRL"
end

-- =========================================================
-- POWER LEVELS ROW  (Low / Mid / High / Ultra)
-- =========================================================
local PowerLevelRow = makeRow(172, 44, "Power Levels")

local POWER_LEVELS = {
	{Name = "Low",   Value = 100000},
	{Name = "Mid",   Value = 150000},
	{Name = "High",  Value = 230000},
	{Name = "Ultra", Value = 450000},
}

local powerLevelButtons = {}

local function syncPowerLevelHighlight()
	for _, btn in ipairs(powerLevelButtons) do
		if btn:GetAttribute("PowerValue") == State.Power then
			btn.BackgroundColor3 = C_NEON
			btn.TextColor3 = C_BG
		else
			btn.BackgroundColor3 = C_ROW
			btn.TextColor3 = C_DIM
		end
	end
end

for i, info in ipairs(POWER_LEVELS) do
	local btn = Instance.new("TextButton")
	btn.Name = info.Name .. "PowerBtn"
	btn.Position = UDim2.new(1, -(155 - (i - 1) * 39) * S, 0.5, -14 * S)
	btn.Size = UDim2.new(0, 36 * S, 0, 28 * S)
	btn.BackgroundColor3 = C_ROW
	btn.BorderSizePixel = 0
	btn.Text = info.Name
	btn.TextColor3 = C_DIM
	btn.TextSize = 9 * S
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.ZIndex = 9
	btn:SetAttribute("PowerValue", info.Value)
	btn.Parent = PowerLevelRow
	corner(btn, 9)
	stroke(btn, C_EDGE, 1.5)

	table.insert(powerLevelButtons, btn)

	btn.MouseButton1Click:Connect(function()
		applyPower(info.Value)
		PowerBox.Text = tostring(State.Power)
		refreshFooter()
		syncPowerLevelHighlight()
		if State.Active then
			stopLag()
			startLag()
		end
	end)
end
-- =========================================================

local function setActive(on)
	State.Active = on

	if on then
		ToggleBtn.Text = "ACTIVE"
		ToggleBtn.BackgroundColor3 = C_NEON
		ToggleBtn.TextColor3 = C_BG
		startLag()
	else
		ToggleBtn.Text = "OFF"
		ToggleBtn.BackgroundColor3 = C_ROW
		ToggleBtn.TextColor3 = C_MID
		stopLag()
	end

	-- No bell sound
end

local function updateBypassLayout()
	if State.Mode == "MOBILE" then
		KeyBtn.Visible = false
		ToggleBtn.Position = UDim2.new(1, -182 * S, 0.5, -18 * S)
		ToggleBtn.Size = UDim2.new(0, 174 * S, 0, 36 * S)
	else
		KeyBtn.Visible = true
		ToggleBtn.Position = UDim2.new(1, -116 * S, 0.5, -18 * S)
		ToggleBtn.Size = UDim2.new(0, 108 * S, 0, 36 * S)
	end
end

local function setMode(mode)
	State.Mode = mode
	if mode == "PC" then
		PCBtn.BackgroundColor3 = C_NEON
		PCBtn.TextColor3 = C_BG
		MobileBtn.BackgroundColor3 = C_ROW
		MobileBtn.TextColor3 = C_DIM
		applyPower(97000)
		PowerBox.Text = tostring(State.Power)
	else
		MobileBtn.BackgroundColor3 = C_NEON
		MobileBtn.TextColor3 = C_BG
		PCBtn.BackgroundColor3 = C_ROW
		PCBtn.TextColor3 = C_DIM
		applyPower(72000)
		PowerBox.Text = tostring(State.Power)
	end
	refreshFooter()
	syncPowerLevelHighlight()
	updateBypassLayout()
	if State.Active then
		stopLag()
		startLag()
	end
end

PCBtn.MouseButton1Click:Connect(function() setMode("PC") end)
MobileBtn.MouseButton1Click:Connect(function() setMode("MOBILE") end)

ToggleBtn.MouseButton1Click:Connect(function()
	setActive(not State.Active)
end)

PowerBox.FocusLost:Connect(function()
	local n = tonumber(PowerBox.Text)
	if n and n > 0 then
		applyPower(n)
	end
	PowerBox.Text = tostring(State.Power)
	refreshFooter()
	syncPowerLevelHighlight()
	if State.Active then
		stopLag()
		startLag()
	end
end)

KeyBtn.MouseButton1Click:Connect(function()
	State.Binding = true
	KeyBtn.Text = "..."
end)

local TW = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setMinimized(on)
	State.Minimized = on
	if on then
		Mini.Position = Main.Position
		local t = TweenService:Create(MainScale, TW, {Scale = 0.92})
		t:Play()
		t.Completed:Wait()
		Main.Visible = false
		MainScale.Scale = 1
		MiniScale.Scale = 0.92
		MiniTint.BackgroundTransparency = 0.35
		Mini.Visible = true
		TweenService:Create(MiniScale, TW, {Scale = 1}):Play()
	else
		Main.Position = Mini.Position
		local t = TweenService:Create(MiniScale, TW, {Scale = 0.92})
		t:Play()
		t.Completed:Wait()
		Mini.Visible = false
		MiniScale.Scale = 1
		MainScale.Scale = 0.92
		Main.Visible = true
		TweenService:Create(MainScale, TW, {Scale = 1}):Play()
	end
end

-- Lock / Unlock handling
local function setLocked(on)
	State.Locked = on
	if on then
		LockBtn.Text = "🔒"
		LockBtn.BackgroundColor3 = C_NEON
		LockBtn.TextColor3 = C_BG
		dragTarget = nil
	else
		LockBtn.Text = "🔓"
		LockBtn.BackgroundColor3 = C_ROW
		LockBtn.TextColor3 = C_MID
	end
end

LockBtn.MouseButton1Click:Connect(function()
	setLocked(not State.Locked)
end)

MinBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
MaxBtn.MouseButton1Click:Connect(function() setMinimized(false) end)

local dragTarget, dragStart, dragOrigin = nil, nil, nil

local function hookDrag(frame, moveTarget)
	frame.InputBegan:Connect(function(input)
		if State.Locked then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragTarget = moveTarget
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			dragOrigin = moveTarget.Position
		end
	end)
end

hookDrag(Main, Main)
hookDrag(MiniTint, Mini)

UserInputService.InputChanged:Connect(function(input)
	if not dragTarget then return end
	if State.Locked then
		dragTarget = nil
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement
	and input.UserInputType ~= Enum.UserInputType.Touch then return end

	local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
	dragTarget.Position = UDim2.new(
		dragOrigin.X.Scale, math.floor(dragOrigin.X.Offset + delta.X),
		dragOrigin.Y.Scale, math.floor(dragOrigin.Y.Offset + delta.Y)
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragTarget = nil
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if State.Binding then
		if input.KeyCode == Enum.KeyCode.Unknown then return end
		State.Binding = false
		if input.KeyCode ~= Enum.KeyCode.Escape then
			State.Keybind = input.KeyCode
		end
		KeyBtn.Text = State.Keybind.Name
		return
	end

	if gpe then return end

	if input.KeyCode == State.Keybind then
		setActive(not State.Active)
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		State.Hidden = not State.Hidden
		ScreenGui.Enabled = not State.Hidden
	end
end)

local hue = 0

-- Remove watermark (no floating label) — keep only gradient rotation
RunService.Heartbeat:Connect(function()
	local r = (MainGrad.Rotation + 1.8) % 360
	MainGrad.Rotation = r
	MiniGrad.Rotation = r
end)

ScreenGui.Destroying:Connect(function()
	stopLag()
	pcall(function() Bell:Destroy() end)
end)

setMode("PC")
refreshFooter()
updateBypassLayout()
syncPowerLevelHighlight()
MinBtn.Visible = true

MainScale.Scale = 0.92
TweenService:Create(
	MainScale,
	TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{Scale = 1}
):Play()

-- ===== CUSTOM FONT (LuckiestGuy) applied to our GUI =====
local function applyCustomFont(gui)
	local ok, font = pcall(Font.new, "rbxasset://fonts/families/LuckiestGuy.json")
	if not ok then return end

	for _, obj in ipairs(gui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			-- Optional: exclude specific elements by name (none excluded here)
			obj.FontFace = font
		end
	end
end

-- Apply font to our newly created GUI
applyCustomFont(ScreenGui)
