-- rename by prince

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

do
    if not _G._UT6AntiDropInstalled then
        local gameMetatable = getrawmetatable(game)
        local originalIndex, originalNewIndex
        local spoofedVelocity = Vector3.zero
        local isAntiDropActive = false

        local function initializeAntiDrop()
            if isAntiDropActive or not gameMetatable then return end
            originalIndex = gameMetatable.__index
            originalNewIndex = gameMetatable.__newindex
            setreadonly(gameMetatable, false)

            gameMetatable.__index = newcclosure(function(self, key)
                if not checkcaller() and (key == "AssemblyLinearVelocity" or key == "Velocity")
                    and typeof(self) == "Instance" and self:IsA("BasePart")
                    and self.Name == "HumanoidRootPart" and localPlayer.Character
                    and self:IsDescendantOf(localPlayer.Character) then
                    return spoofedVelocity
                end
                return originalIndex(self, key)
            end)

            gameMetatable.__newindex = newcclosure(function(self, key, value)
                if not checkcaller() and (key == "AssemblyLinearVelocity" or key == "Velocity")
                    and typeof(self) == "Instance" and self:IsA("BasePart")
                    and self.Name == "HumanoidRootPart" and localPlayer.Character
                    and self:IsDescendantOf(localPlayer.Character) then
                    spoofedVelocity = value
                    return
                end
                return originalNewIndex(self, key, value)
            end)

            setreadonly(gameMetatable, true)
            isAntiDropActive = true
        end

        initializeAntiDrop()

        localPlayer.CharacterAdded:Connect(function()
            task.wait(0.1)
            if not isAntiDropActive then initializeAntiDrop() end
        end)

        _G._UT6AntiDropInstalled = true
    end
end

do
    local antiBatConnection = nil
    local currentSpeed = 10000
    local currentAngle = 0
    local direction = 1

    local function stopAntiBat()
        if antiBatConnection then
            pcall(function() antiBatConnection:Disconnect() end)
            antiBatConnection = nil
        end
        currentSpeed = 10000
        currentAngle = 0
        direction = 1
        _G._UT6DuelsAntiBatDesiredXZ = nil
        _G._UT6DuelsAntiBatSpiking = false
    end

    local function startAntiBat()
        stopAntiBat()
        antiBatConnection = RunService.Heartbeat:Connect(function()
            if not _G.UT6DuelsAntiBatEnabled then return end
            local character = localPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart or not rootPart.Parent then return end

            local originalVelocityXZ = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)

            currentSpeed = currentSpeed + (50 * direction)
            if currentSpeed >= 20000 then
                currentSpeed = 20000
                direction = -1
            elseif currentSpeed <= 10000 then
                currentSpeed = 10000
                direction = 1
            end

            currentAngle = currentAngle + (math.random() * 0.5)
            local radius = currentSpeed + math.random(-5000, 5000)
            local newX = math.cos(currentAngle) * radius
            local newZ = math.sin(currentAngle) * radius

            _G._UT6DuelsAntiBatSpiking = true
            rootPart.Velocity = Vector3.new(newX, rootPart.Velocity.Y, newZ)

            RunService.RenderStepped:Wait()

            if rootPart.Parent then
                local targetVelocity = _G._UT6DuelsAntiBatDesiredXZ
                if targetVelocity then
                    rootPart.Velocity = Vector3.new(targetVelocity.X, rootPart.Velocity.Y, targetVelocity.Z)
                else
                    rootPart.Velocity = Vector3.new(originalVelocityXZ.X, rootPart.Velocity.Y, originalVelocityXZ.Z)
                end
            end
            _G._UT6DuelsAntiBatSpiking = false
        end)
    end

    _G.UT6DuelsAntiBatEnabled = _G.UT6DuelsAntiBatEnabled == true

    local function runSafe(callback)
        pcall(callback)
    end

    _G.UT6DuelsAntiBat = {
        setEnabled = function(isEnabled)
            local enabled = isEnabled and true or false
            _G.UT6DuelsAntiBatEnabled = enabled
            if enabled then
                runSafe(startAntiBat)
            else
                runSafe(stopAntiBat)
            end
        end,
        isEnabled = function()
            return _G.UT6DuelsAntiBatEnabled == true
        end,
    }

    task.spawn(function()
        while true do
            task.wait(0.5)
            if _G.UT6DuelsAntiBatEnabled then
                if not antiBatConnection then
                    runSafe(startAntiBat)
                end
            elseif antiBatConnection then
                runSafe(stopAntiBat)
            end
        end
    end)

    localPlayer.CharacterAdded:Connect(function(character)
        if _G._UT6DuelsWaitCharReady then
            _G._UT6DuelsWaitCharReady(character, 10)
        end
        if _G.UT6DuelsAntiBatEnabled then
            startAntiBat()
        else
            stopAntiBat()
        end
    end)
end

local existingGui = playerGui:FindFirstChild("UT6AntiBat")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UT6AntiBat"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = 0.82
uiScale.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(310, 215)
mainFrame.Position = UDim2.new(0.5, -155, 0.5, -108)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 18)
frameCorner.Parent = mainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(120, 70, 255)
frameStroke.Thickness = 2
frameStroke.Transparency = 0.15
frameStroke.Parent = mainFrame

local background = Instance.new("ImageLabel")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundTransparency = 1
background.Image = "rbxassetid://126793180958099"
background.ImageTransparency = 0.55
background.ScaleType = Enum.ScaleType.Crop
background.ZIndex = 0
background.Parent = mainFrame
local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 18)
bgCorner.Parent = background

local shadeFrame = Instance.new("Frame")
shadeFrame.Size = UDim2.fromScale(1, 1)
shadeFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 9)
shadeFrame.BackgroundTransparency = 0.38
shadeFrame.BorderSizePixel = 0
shadeFrame.ZIndex = 1
shadeFrame.Parent = mainFrame
local shadeCorner = Instance.new("UICorner")
shadeCorner.CornerRadius = UDim.new(0, 18)
shadeCorner.Parent = shadeFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 0, 42)
titleLabel.Position = UDim2.fromOffset(22, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "UT6 ANTI BAT"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 25
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 2
titleLabel.Parent = mainFrame

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -100, 0, 18)
subtitleLabel.Position = UDim2.fromOffset(23, 44)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "ANTI BAT CONTROL"
subtitleLabel.TextColor3 = Color3.fromRGB(190, 175, 255)
subtitleLabel.TextSize = 10
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.ZIndex = 2
subtitleLabel.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(34, 30)
closeButton.Position = UDim2.new(1, -46, 0, 13)
closeButton.BackgroundColor3 = Color3.fromRGB(30, 25, 42)
closeButton.Text = "--"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 17
closeButton.Font = Enum.Font.GothamBlack
closeButton.AutoButtonColor = false
closeButton.ZIndex = 3
closeButton.Parent = mainFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.fromOffset(100, 22)
statusLabel.Position = UDim2.fromOffset(23, 82)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "STATUS  🟥"
statusLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 2
statusLabel.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.fromOffset(255, 47)
toggleButton.Position = UDim2.fromOffset(27, 108)
toggleButton.BackgroundColor3 = Color3.fromRGB(27, 25, 37)
toggleButton.Text = "ANTI BAT                         OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 15
toggleButton.Font = Enum.Font.GothamBlack
toggleButton.AutoButtonColor = false
toggleButton.ZIndex = 2
toggleButton.Parent = mainFrame
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 14)
toggleCorner.Parent = toggleButton
local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(95, 80, 125)
toggleStroke.Thickness = 1.4
toggleStroke.Parent = toggleButton

local sizeMenuLabel = Instance.new("TextLabel")
sizeMenuLabel.Size = UDim2.fromOffset(80, 20)
sizeMenuLabel.Position = UDim2.fromOffset(25, 171)
sizeMenuLabel.BackgroundTransparency = 1
sizeMenuLabel.Text = "MENU SIZE"
sizeMenuLabel.TextColor3 = Color3.fromRGB(210, 205, 225)
sizeMenuLabel.TextSize = 10
sizeMenuLabel.Font = Enum.Font.GothamBold
sizeMenuLabel.ZIndex = 2
sizeMenuLabel.Parent = mainFrame

local sizeBar = Instance.new("Frame")
sizeBar.Size = UDim2.fromOffset(180, 5)
sizeBar.Position = UDim2.fromOffset(105, 179)
sizeBar.BackgroundColor3 = Color3.fromRGB(65, 55, 85)
sizeBar.BorderSizePixel = 0
sizeBar.ZIndex = 2
sizeBar.Parent = mainFrame
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = sizeBar

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.fromOffset(18, 18)
sliderKnob.Position = UDim2.new(0.5, -9, 0.5, -9)
sliderKnob.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
sliderKnob.Text = ""
sliderKnob.AutoButtonColor = false
sliderKnob.ZIndex = 3
sliderKnob.Parent = sizeBar
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = sliderKnob

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -30, 0, 16)
hintLabel.Position = UDim2.fromOffset(15, 195)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "PC: H  •  Drag to move"
hintLabel.TextColor3 = Color3.fromRGB(160, 155, 180)
hintLabel.TextSize = 9
hintLabel.Font = Enum.Font.GothamMedium
hintLabel.ZIndex = 2
hintLabel.Parent = mainFrame

local function setAntiBatUI(isEnabled)
    _G.UT6DuelsAntiBatEnabled = isEnabled
    if _G.UT6DuelsAntiBat and _G.UT6DuelsAntiBat.setEnabled then
        _G.UT6DuelsAntiBat.setEnabled(isEnabled)
    end
    toggleButton.Text = isEnabled and "ANTI BAT                         ON" or "ANTI BAT                         OFF"
    statusLabel.Text = isEnabled and "STATUS  🟢" or "STATUS  🟥"
    toggleButton.BackgroundColor3 = isEnabled and Color3.fromRGB(35, 60, 42) or Color3.fromRGB(27, 25, 37)
    toggleStroke.Color = isEnabled and Color3.fromRGB(80, 220, 125) or Color3.fromRGB(95, 80, 125)
end

toggleButton.MouseButton1Click:Connect(function()
    setAntiBatUI(not _G.UT6DuelsAntiBatEnabled)
end)

local isDragging = false
local dragStartPoint, dragStartPosition

local function processDrag(input)
    local delta = input.Position - dragStartPoint
    mainFrame.Position = UDim2.new(
        dragStartPosition.X.Scale, dragStartPosition.X.Offset + delta.X,
        dragStartPosition.Y.Scale, dragStartPosition.Y.Offset + delta.Y
    )
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y - mainFrame.AbsolutePosition.Y < 65 then
            isDragging = true
            dragStartPoint = input.Position
            dragStartPosition = mainFrame.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        processDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.fromOffset(115, 42)
openButton.Position = UDim2.new(0, 18, 0.5, -21)
openButton.BackgroundColor3 = Color3.fromRGB(20, 17, 29)
openButton.Text = "UT6  •  OPEN"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 13
openButton.Font = Enum.Font.GothamBlack
openButton.AutoButtonColor = false
openButton.Visible = false
openButton.ZIndex = 10
openButton.Parent = screenGui
local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 14)
openCorner.Parent = openButton
local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(130, 90, 255)
openStroke.Thickness = 2
openStroke.Parent = openButton

local function closeMenu()
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0)
    })
    tween:Play()
    tween.Completed:Wait()
    mainFrame.Visible = false
    openButton.Visible = true
end

local function openMenu()
    openButton.Visible = false
    mainFrame.Visible = true
    mainFrame.Size = UDim2.fromOffset(0, 0)
    TweenService:Create(mainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(310, 215)
    }):Play()
end

closeButton.MouseButton1Click:Connect(closeMenu)
openButton.MouseButton1Click:Connect(openMenu)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then
        if mainFrame.Visible then closeMenu() else openMenu() end
    end
end)

local isResizing = false

local function updateMenuSize(x)
    local leftBound = sizeBar.AbsolutePosition.X
    local barWidth = sizeBar.AbsoluteSize.X
    local alpha = math.clamp((x - leftBound) / barWidth, 0, 1)

    sliderKnob.Position = UDim2.new(alpha, -9, 0.5, -9)
    uiScale.Scale = 0.65 + (alpha * 0.45)
end

local function startResizing(input)
    isResizing = true
    updateMenuSize(input.Position.X)
end

sizeBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        startResizing(input)
    end
end)

sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        startResizing(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            updateMenuSize(input.Position.X)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end)

setAntiBatUI(_G.UT6DuelsAntiBatEnabled == true)
