local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UIS = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    Stats = game:GetService("Stats"),
    NetworkClient = game:GetService("NetworkClient"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CoreGui = game:GetService("CoreGui"),
    GuiService = game:GetService("GuiService"),
}

local Players = Services.Players
local RunService = Services.RunService
local UIS = Services.UIS
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local Lighting = Services.Lighting
local Stats = Services.Stats
local NetworkClient = Services.NetworkClient
local ReplicatedStorage = Services.ReplicatedStorage
local CoreGui = Services.CoreGui
local GuiService = Services.GuiService
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")


local spoofedVelocity = Vector3.zero


SpaceHubLoadV2UI = nil
SpaceHubResetV2UI = nil
SpaceHubLoadV3UI = nil
SpaceHubResetV3UI = nil
SpaceHubLoadV4UI = nil
SpaceHubResetV4UI = nil
SpaceHubActiveCustomUI = "V1"
local CustomProgressBarVersion = "V1"
SpaceHubActiveV2Gui = nil
SpaceHubActiveV3Gui = nil
SpaceHubActiveV4Gui = nil
SpaceHubSharedPosition = nil
StealBarSize = 1.05
StealBarColor = Color3.fromRGB(245, 245, 245)

SpaceHubV2BackgroundImage = nil
SpaceHubV2TabBackgroundImage = nil
SpaceHubV3BackgroundImage = nil
SpaceHubV3HeaderBackgroundImage = nil
SpaceHubTextColor = Color3.fromRGB(255, 255, 255)


local VELOCITY_NAME = "HorizontalMoveVelocity"
local ATTACHMENT_NAME = "HorizontalMoveAttachment"
local MIN_FORCE = 1000000
local MAX_FORCE = 50000000

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

function clearHorizontalVelocity(root)
    if not root then return end
    local mover = root:FindFirstChild(VELOCITY_NAME)
    if mover and mover:IsA("LinearVelocity") then mover:Destroy() end
    local attachment = root:FindFirstChild(ATTACHMENT_NAME)
    if attachment and attachment:IsA("Attachment") then attachment:Destroy() end
end


local webhookUrl = ""

function getRequestFunction()
    if syn and syn.request then return syn.request end
    if request then return request end
    if http and http.request then return http.request end
    if http_request then return http_request end
    return nil
end

function getFullAvatarUrl(userId)
    local req = getRequestFunction()
    if not req then return nil end
    local success, result = pcall(function()
        local url = "" .. userId .. "&size=420x420&format=Png&isCircular=false"
        local response = req({Url = url, Method = "GET", Headers = {["Content-Type"] = "application/json"}})
        local body = nil
        if response then
            if response.Body then body = response.Body
            elseif response.body then body = response.body
            elseif type(response) == "string" then body = response end
        end
        if body then
            local data = HttpService:JSONDecode(body)
            if data and data.data and data.data[1] then return data.data[1].imageUrl end
        end
        return nil
    end)
    return success and result or nil
end

function sendWebhookLog(username, userId)
    if webhookUrl == "" or webhookUrl:find("TA_ID") then return end
    local req = getRequestFunction()
    if not req then return end
    local gameName = "Inconnu"
    pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
    local avatarUrl = getFullAvatarUrl(userId)
    local embed = {
        title = "**Space Hub**",
        description = string.format("Utilisateur : **`%s`**\nGame : **`%s`**\nPlace ID : **`%s`**\nUser ID : **`%s`**",
            username or "Inconnu", gameName, game.PlaceId, userId or "Inconnu"),
        color = 0x5865F2,
        footer = { text = "Space Hub • Logs" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
    }
    if avatarUrl then embed.image = { url = avatarUrl } end
    local data = { content = nil, embeds = { embed } }
    local body = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}
    pcall(function() req({Url = webhookUrl, Method = "POST", Headers = headers, Body = body}) end)
end

task.spawn(function()
    task.wait(0.5)
    sendWebhookLog(LP.DisplayName or LP.Name, LP.UserId)
end)


local OriginalLighting = {
    Technology = Lighting.Technology,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    ExposureCompensation = Lighting.ExposureCompensation,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
}

function makeDraggable(guiObject)
    local dragging, dragStartPos, startGuiPos, dragInput = false, nil, nil, nil
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            startGuiPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStartPos
            guiObject.Position = UDim2.new(
                startGuiPos.X.Scale, startGuiPos.X.Offset + delta.X,
                startGuiPos.Y.Scale, startGuiPos.Y.Offset + delta.Y
            )
        end
    end)
end


local Packages = ReplicatedStorage:WaitForChild("Packages")
local Datas = ReplicatedStorage:WaitForChild("Datas")
local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
local AnimalsData = require(Datas:WaitForChild("Animals"))


local State = {
    normalSpeed = 59, carrySpeed = 29,
    laggerModeEnabled = false, laggerNormalSpeed = 30, laggerCarrySpeed = 15,
    speedToggled = false, autoCarryEnabled = false, autoBatToggled = false,
    infJumpEnabled = false, antiRagdollEnabled = false, fpsBoostEnabled = false,
    ragdollTimerEnabled = false, ragdollTimerDuration = 3,
    antiDieEnabled = false,
    medusaCounterEnabled = false,
    batCounterEnabled = false,
    autoBatV2Enabled = false,
    tpBatEnabled = false,
    batCounterDebounce = false,
    skyMode = 0,
    stretchResEnabled = false,
    guiVisible = true, medusaLastUsed = 0, medusaDebounce = false,
    dropBrainrotActive = false, tpInProgress = false, tpUpDebounce = false,
    lastMoveDir = Vector3.new(0,0,0),
    floatingBtnsVisible = true,
    bypassGuiVisible = true,
    laggerGuiVisible = true,
    fov = 70,
    backgroundEnabled = true,
    backgroundIndex = 1,
    accentR = 255,
    accentG = 255,
    accentB = 255,
    unwalkEnabled = false,
    autoGrabEnabled = false,
    grabStealRadius = 59,
    grabStealDuration = 1.3,
    primeRange = 8.5,
    autoStealVersion = "V2",
    stealMode = "normal",
    normalStealVersion = "86",
    bodyLockEnabled = false,
    korbloxEnabled = false,
    outfit = "Off",
    animationPack = "Off",
    autoBatVersion = "V1",
}

local unwalkSavedAnimate = nil

function startUnwalk()
    local c = LP.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            pcall(function() t:Stop() end)
        end
    end
    local anim = c:FindFirstChild("Animate")
    if anim then
        unwalkSavedAnimate = anim:Clone()
        anim:Destroy()
    end
end

function stopUnwalk()
    local c = LP.Character
    if c then
        local existing = c:FindFirstChild("Animate")
        if not existing then
            local src = game:GetService("StarterPlayer"):FindFirstChildOfClass("StarterCharacterScripts")
            local starterAnim = src and src:FindFirstChild("Animate")
            if starterAnim then starterAnim:Clone().Parent = c
            elseif unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent = c end
        end
    end
    unwalkSavedAnimate = nil
end

function toggleUnwalk()
    State.unwalkEnabled = not State.unwalkEnabled
    if State.unwalkEnabled then startUnwalk() else stopUnwalk() end
    scheduleAutoSave()
end

local Keys = {
    autoBat      = Enum.KeyCode.X,
    autoBatV2    = Enum.KeyCode.R,
    tpBat        = Enum.KeyCode.Y,
    autoLeft     = Enum.KeyCode.Z,
    autoRight    = Enum.KeyCode.C,
    speed        = Enum.KeyCode.Space,
    guiHide      = Enum.KeyCode.RightControl,
    dropBrainrot = Enum.KeyCode.H,
    tpDown       = Enum.KeyCode.T,
    instaReset   = Enum.KeyCode.I,
    laggerToggle = Enum.KeyCode.K,
}

local BypassSettings = {
    keybind = "V",
    power = 97000,
    version = "V1",
    activeMode = "PC"
}

local LaggerSettings = {
    keybind = "L",
    version = "V1",
    activeMode = "PC"
}

local GuiToggleSetters = {}

local AUTO_BAT_SPEED = 58
local AUTO_BAT_VERT_SPEED = 52
local AUTO_BAT_DIST = -2.8
local AUTO_BAT_HEIGHT = 4.75
local AUTO_BAT_V_OFF = 1
local AUTO_BAT_TURN_SPEED = 285
local AUTO_BAT_MAX_TURN_RATE = 28

local AUTO_BAT_HOLD_RADIUS = 2.75
local AUTO_BAT_CORRECTION_GAIN = 14
local autoSwingEnabled = true
local autoBatEquippedThisRun = false
local _autoBatTarget = nil
local _autoBatLastScan = 0
local playerVelocityHistory = {}

local autoBatV2Connection = nil
local autoBatV2HittingCooldown = false
local autoBatV2_hrp = nil
local autoBatV2_h = nil
local autoBatV2Target = nil
local autoBatV2LastTargetPos = nil
local autoBatV2VelocityHistory = {}
local autoBatV2PredictionSphere = nil
local autoBatV2CharacterConnection = nil
local tpBatConnection = nil

local function getAutoBatManualHorizontalVelocity(humanoid, speed)
    if not humanoid then return Vector3.zero end
    local direction = humanoid.MoveDirection
    direction = Vector3.new(direction.X, 0, direction.Z)
    if direction.Magnitude > 1 then direction = direction.Unit end
    return direction * speed
end

local function blendAutoBatHorizontalVelocity(myPos, targetPos, manualVelocity, speed, holdRadius)
    local toTarget = Vector3.new(
        targetPos.X - myPos.X,
        0,
        targetPos.Z - myPos.Z
    )
    local distance = toTarget.Magnitude
    local desired = manualVelocity

    if distance > holdRadius and distance > 0.001 then
        local towardTarget = toTarget.Unit
        
        
        local movingAway = math.max(0, -desired:Dot(towardTarget))
        local correction = math.min(
            speed,
            movingAway + (distance - holdRadius) * AUTO_BAT_CORRECTION_GAIN
        )
        desired = desired + towardTarget * correction
    end

    if desired.Magnitude > speed then
        desired = desired.Unit * speed
    end
    return desired
end

local function disableNormalMovementVelocity()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local mover = root and root:FindFirstChild(VELOCITY_NAME)
    if mover and mover:IsA("LinearVelocity") then
        mover.Enabled = false
    end
end

function getBatV2()
    local char = LP.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        tool = bp:FindFirstChild("Bat")
        if tool then tool.Parent = char; return tool end
    end
    return nil
end

function tryHitBatV2()
    if autoBatV2HittingCooldown then return end
    autoBatV2HittingCooldown = true
    pcall(function()
        local bat = getBatV2()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() autoBatV2HittingCooldown = false end)
end

function getClosestPlayerV2()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, minDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (myRoot.Position - tr.Position).Magnitude
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if d < minDist and hum and hum.Health > 0 then
                    minDist = d
                    closest = p
                end
            end
        end
    end
    return closest, minDist
end

local function createAutoBatV2PredictionSphere()
    if autoBatV2PredictionSphere then autoBatV2PredictionSphere:Destroy() end
    local sphere = Instance.new("Part")
    sphere.Name = "SpaceHubAutoBatV2Prediction"
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(2, 2, 2)
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Material = Enum.Material.Neon
    sphere.Color = Color3.fromRGB(0, 150, 255)
    sphere.Transparency = 0.4
    local light = Instance.new("PointLight")
    light.Color = sphere.Color
    light.Range = 8
    light.Brightness = 2
    light.Parent = sphere
    sphere.Parent = workspace
    autoBatV2PredictionSphere = sphere
end

local function destroyAutoBatV2PredictionSphere()
    if autoBatV2PredictionSphere then
        autoBatV2PredictionSphere:Destroy()
        autoBatV2PredictionSphere = nil
    end
end

function setupCharV2(char)
    task.wait(0.1)
    autoBatV2_h = char:WaitForChild("Humanoid", 5)
    autoBatV2_hrp = char:WaitForChild("HumanoidRootPart", 5)
end


local function findBatAutoBatV2()
    local char = LP.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        local name = tool.Name:lower()
        if tool:IsA("Tool") and (name:find("bat") or name:find("slap")) then
            return tool
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            local name = tool.Name:lower()
            if tool:IsA("Tool") and (name:find("bat") or name:find("slap")) then
                return tool
            end
        end
    end
    return nil
end

local function getClosestTargetAutoBatV2()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = tRoot
                end
            end
        end
    end
    return closest
end

function startAutoBatV2()
    if autoBatV2Connection then return end
    disableNormalMovementVelocity()
    if tpBatConnection then
        State.tpBatEnabled = false
        stopTpBat()
    end
    if LP.Character then task.spawn(function() setupCharV2(LP.Character) end) end
    if not autoBatV2CharacterConnection then
        autoBatV2CharacterConnection = LP.CharacterAdded:Connect(setupCharV2)
    end
    local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum0 then hum0.AutoRotate = false end

    autoBatV2Connection = RunService.RenderStepped:Connect(function(dt)
        if not State.autoBatV2Enabled then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        if not char:FindFirstChildOfClass("Tool") then
            local bat = findBatAutoBatV2()
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end

        
        
        
        local target = autoBatV2Target
        local targetHum = target and target.Parent
            and target.Parent:FindFirstChildOfClass("Humanoid")
        if not target
            or not target.Parent
            or not target:IsDescendantOf(workspace)
            or targetHum.Health <= 0
            or (target.Position - root.Position).Magnitude > 80 then
            target = getClosestTargetAutoBatV2()
            autoBatV2Target = target
        end
        if not target then return end
        local targetVel = target.AssemblyLinearVelocity
        
        if targetVel.Magnitude > 100 then
            targetVel = Vector3.zero
        else
            targetVel = Vector3.new(
                math.clamp(targetVel.X, -75, 75),
                math.clamp(targetVel.Y, -45, 45),
                math.clamp(targetVel.Z, -75, 75)
            )
        end
        local myPos = root.Position
        local targetPos = target.Position
        local predictPos = targetPos + targetVel * 0.14
        predictPos = predictPos + target.CFrame.LookVector * 0.3
        local chaseSpeed = 58
        local manualVelocity = getAutoBatManualHorizontalVelocity(hum, chaseSpeed)
        local horizontalVelocity = blendAutoBatHorizontalVelocity(
            myPos,
            predictPos,
            manualVelocity,
            chaseSpeed,
        )
        local desiredHeight = targetPos.Y + 3.7
        local yVel = (desiredHeight - myPos.Y) * 19.5 + targetVel.Y * 0.8
        if hum.FloorMaterial ~= Enum.Material.Air then yVel = math.max(yVel, 13) end
        yVel = math.clamp(yVel, -55, 65)
        local desiredVel = Vector3.new(horizontalVelocity.X, yVel, horizontalVelocity.Z)
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(desiredVel, 0.8)

        local speed3 = targetVel.Magnitude
        local predictTime = math.clamp(speed3 / 150, 0.05, 0.2)
        local predictedPos = targetPos + targetVel * predictTime
        local toPredict = predictedPos - myPos
        if toPredict.Magnitude > 0.1 then
            local goalCF = CFrame.lookAt(myPos, predictedPos)
            local curCF = root.CFrame
            local diffCF = curCF:Inverse() * goalCF
            local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
            rx = math.clamp(rx, -2.5, 2.5)
            ry = math.clamp(ry, -2.5, 2.5)
            rz = math.clamp(rz, -2.5, 2.5)
            local tiltSpeed = 42
            local angularVelocity = root.CFrame:VectorToWorldSpace(
                Vector3.new(rx * tiltSpeed, ry * tiltSpeed, rz * tiltSpeed)
            )
            if angularVelocity.Magnitude > 24 then
                angularVelocity = angularVelocity.Unit * 24
            end
            root.AssemblyAngularVelocity = angularVelocity
        end
    end)
end

function stopAutoBatV2()
    if autoBatV2Connection then
        autoBatV2Connection:Disconnect()
        autoBatV2Connection = nil
    end
    destroyAutoBatV2PredictionSphere()
    autoBatV2Target = nil
    autoBatV2LastTargetPos = nil
    autoBatV2VelocityHistory = {}
    if autoBatV2_h then
        autoBatV2_h.AutoRotate = true
    end
    if autoBatV2_hrp then
        autoBatV2_hrp.AssemblyAngularVelocity = Vector3.zero
    end
    if autoBatV2CharacterConnection then
        autoBatV2CharacterConnection:Disconnect()
        autoBatV2CharacterConnection = nil
    end
end


function startTpBat()
    if tpBatConnection then return end
    if autoBatV2Connection then
        State.autoBatV2Enabled = false
        stopAutoBatV2()
    end
    if LP.Character then task.spawn(function() setupCharV2(LP.Character) end) end
    tpBatConnection = RunService.Heartbeat:Connect(function()
        if not State.tpBatEnabled then return end
        if not (autoBatV2_h and autoBatV2_hrp) then return end
        local target = getClosestPlayerV2()
        local tr = target and target.Character
            and target.Character:FindFirstChild("HumanoidRootPart")
        if not tr then return end
        if sethiddenproperty then
            sethiddenproperty(autoBatV2_hrp, "PhysicsRepRootPart", tr)
        end
        local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
        if (autoBatV2_hrp.Position - targetPos).Magnitude > 8 then
            autoBatV2_hrp.CFrame = CFrame.new(targetPos)
        end
        local cam = workspace.CurrentCamera
        if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position) end
        tryHitBatV2()
    end)
end

function stopTpBat()
    if tpBatConnection then
        tpBatConnection:Disconnect()
        tpBatConnection = nil
    end
end


local isStealing = false
local stealStartTime = nil
local progressConnection = nil
local StealData = {}
local autoGrabConnection = nil
local ProgressBarFill, ProgressLabel, ProgressPercentLabel, LeftToRightFill
local fpsLabel = nil
local fpsUpdateConnection = nil
local DISCORD_TEXT = "discord.gg/space-duels"

local NORMAL_STEAL_PERCENT = {
    ["75"] = 0.75,
    ["80"] = 0.80,
    ["86"] = 0.86,
    ["90"] = 0.90,
}
local normalStealProgress = 0
local normalStealPaused = false

function getDiscordProgress(percent)
    local totalChars = #DISCORD_TEXT
    local adjustedPercent = math.min(percent * 1.5, 100)
    local charsToShow = math.floor((adjustedPercent / 100) * totalChars)
    if charsToShow == 0 and percent > 0 then charsToShow = 1 end
    return string.sub(DISCORD_TEXT, 1, charsToShow)
end


function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function getPromptSpawnPosition(prompt)
    if not prompt then return nil end
    local parent = prompt.Parent
    if parent and parent.Name == "PromptAttachment" then parent = parent.Parent end
    if parent and parent.Name == "Spawn" and parent:IsA("BasePart") then
        return parent.Position
    end
    return nil
end

local function isStealTargetClose(spawnPosition)
    if not spawnPosition then return false end
    local character = LP.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local pRange = tonumber(State.primeRange) or 8.5
    return root ~= nil and (spawnPosition - root.Position).Magnitude <= pRange
end


function findNearestPrompt()
    local char = LP.Character
    local h = char and char:FindFirstChild("HumanoidRootPart")
    if not h then return nil end

    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end

    local nearestPrompt, nearestDist, nearestName = nil, math.huge, nil
    local radius = (State.stealMode == "op" and State.autoStealVersion == "V2") and math.max(State.grabStealRadius or 61, 80) or (State.grabStealRadius or 61)

    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then
        end

        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end

        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - h.Position).Magnitude
                    if dist <= radius and dist < nearestDist then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") and (ch.ActionText:find("Steal") or ch.ActionText == "" or ch.Name:lower():find("steal")) then
                                    nearestPrompt, nearestDist, nearestName = ch, dist, pod.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return nearestPrompt, nearestDist, nearestName
end


function ResetProgressBar()
    if ProgressLabel then ProgressLabel.Text = "" end
    if ProgressPercentLabel then
        ProgressPercentLabel.Text = (CustomProgressBarVersion == "V2"
            or CustomProgressBarVersion == "V3"
            or CustomProgressBarVersion == "V4") and "0%" or ""
    end
    if LeftToRightFill then LeftToRightFill.Size = UDim2.new(0, 0, 1, 0) end
    getgenv()._AS_StealProgress = 0
end


function executeStealV1(prompt, name, distance)
    if isStealing then return end

    if not StealData[prompt] then
        StealData[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            end
        end)
    end

    local data = StealData[prompt]
    if not data.ready then return end

    data.ready = false
    isStealing = true
    stealStartTime = tick()

    if ProgressLabel then ProgressLabel.Text = "" end

    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then
            progressConnection:Disconnect()
            return
        end
        local prog = math.clamp((tick() - stealStartTime) / (State.grabStealDuration or 1.3), 0, 1)
        getgenv()._AS_StealProgress = prog
        if LeftToRightFill then
            LeftToRightFill.Size = UDim2.new(prog, 0, 1, 0)
        end
        if ProgressPercentLabel then
            local percent = math.floor(prog * 100)
            ProgressPercentLabel.Text = tostring(percent) .. "%"
        end
    end)

    task.spawn(function()
        for _, f in ipairs(data.hold) do
            task.spawn(f)
        end
        task.wait(State.grabStealDuration or 1.3)
        for _, f in ipairs(data.trigger) do
            task.spawn(f)
        end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        data.ready = true
        isStealing = false
    end)
end


function executeStealV2(prompt)
    if isStealing then return end

    if not StealData[prompt] then
        StealData[prompt] = {
            hold = {},
            trigger = {},
            ready = true
        }
        if getconnections then
            for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                if c.Function then table.insert(StealData[prompt].hold, c.Function) end
            end
            for _, c in ipairs(getconnections(prompt.Triggered)) do
                if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
            end
        end
    end

    local data = StealData[prompt]
    if not data.ready then return end

    data.ready = false
    isStealing = true
    stealStartTime = tick()

    local spawnPosition = getPromptSpawnPosition(prompt)
    local isOp = State.stealMode == "op"
    local duration = isOp and 1.4 or math.max(tonumber(State.grabStealDuration) or 1.3, 0.05)
    local stopRatio = isOp and 0.92 or (NORMAL_STEAL_PERCENT[State.normalStealVersion] or NORMAL_STEAL_PERCENT["86"])
    local stopPoint = duration * stopRatio

    normalStealProgress = 0
    normalStealPaused = false

    task.spawn(function()
        for _, fn in ipairs(data.hold) do
            task.spawn(fn)
        end

        local started = tick()

        while isStealing and State.autoGrabEnabled and prompt.Parent do
            local elapsed = tick() - started
            normalStealProgress = math.clamp(elapsed / duration, 0, stopRatio)
            getgenv()._AS_StealProgress = normalStealProgress
            if LeftToRightFill then
                LeftToRightFill.Size = UDim2.new(normalStealProgress, 0, 1, 0)
            end
            if ProgressPercentLabel then
                ProgressPercentLabel.Text = tostring(math.floor(normalStealProgress * 100)) .. "%"
            end
            if elapsed >= stopPoint then break end
            task.wait()
        end

        normalStealProgress = stopRatio
        getgenv()._AS_StealProgress = stopRatio
        if LeftToRightFill then
            LeftToRightFill.Size = UDim2.new(normalStealProgress, 0, 1, 0)
        end
        if ProgressPercentLabel then
            ProgressPercentLabel.Text = tostring(math.floor(normalStealProgress * 100)) .. "%"
        end
        normalStealPaused = true

        local closeEnough = isStealTargetClose(spawnPosition)
        local waitDeadline = tick() + 2.5

        while isStealing and State.autoGrabEnabled and prompt.Parent and not closeEnough and tick() < waitDeadline do
            closeEnough = isStealTargetClose(spawnPosition)
            task.wait()
        end

        if closeEnough and isStealing and State.autoGrabEnabled and prompt.Parent then
            normalStealPaused = false
            local remaining = math.max(duration - stopPoint, 0.01)
            local finishStarted = tick()

            while isStealing and State.autoGrabEnabled and prompt.Parent do
                local finishAlpha = math.clamp((tick() - finishStarted) / remaining, 0, 1)
                normalStealProgress = stopRatio + finishAlpha * (1 - stopRatio)
                getgenv()._AS_StealProgress = normalStealProgress
                if LeftToRightFill then
                    LeftToRightFill.Size = UDim2.new(normalStealProgress, 0, 1, 0)
                end
                if ProgressPercentLabel then
                    ProgressPercentLabel.Text = tostring(math.floor(normalStealProgress * 100)) .. "%"
                end
                if finishAlpha >= 1 then break end
                task.wait()
            end

            if isStealing and State.autoGrabEnabled and prompt.Parent then
                for _, fn in ipairs(data.trigger) do
                    task.spawn(fn)
                end
                if LeftToRightFill then
                    local orig = LeftToRightFill.BackgroundColor3
                    LeftToRightFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    task.delay(0.1, function()
                        if LeftToRightFill then LeftToRightFill.BackgroundColor3 = orig end
                    end)
                end
            end
        end

        task.wait(0.06)
        data.ready = true
        isStealing = false
        stealStartTime = nil
        normalStealProgress = 0
        normalStealPaused = false
        getgenv()._AS_StealProgress = 0
        ResetProgressBar()
    end)
end

function executeSteal(prompt, name, distance)
    if State.autoStealVersion == "V2" then
        executeStealV2(prompt)
    else
        executeStealV1(prompt, name, distance)
    end
end


function startAutoGrab()
    if autoGrabConnection then return end
    autoGrabConnection = RunService.Heartbeat:Connect(function()
        if not State.autoGrabEnabled or isStealing then return end
        local prompt, distance, name = findNearestPrompt()
        if prompt then
            executeSteal(prompt, name, distance)
        end
    end)
end

function stopAutoGrab()
    if autoGrabConnection then
        autoGrabConnection:Disconnect()
        autoGrabConnection = nil
    end
    isStealing = false
    stealStartTime = nil
    normalStealProgress = 0
    normalStealPaused = false
    getgenv()._AS_StealProgress = 0
    ResetProgressBar()
end


function createCompactProgressBarV2()
    local old = CoreGui:FindFirstChild("SpaceProgressBar")
    if old then old:Destroy() end
    local sizeFactor = math.clamp(tonumber(StealBarSize) or 1.05, 0.75, 1.5)

    local gui = Instance.new("ScreenGui")
    gui.Name = "SpaceProgressBar"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local shadow = Instance.new("Frame")
    shadow.Position = UDim2.new(0.5, -151 * sizeFactor, 1, -70 * sizeFactor)
    shadow.Size = UDim2.new(0, 300, 0, 54)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.35
    shadow.BorderSizePixel = 0
    
    
    guiCorner(shadow, 11)
    local shadowScale = Instance.new("UIScale")
    shadowScale.Scale = sizeFactor
    shadowScale.Parent = shadow

    local bar = Instance.new("TextButton")
    bar.Name = "CompactProgressBarV2"
    bar.Position = UDim2.new(0.5, -154 * sizeFactor, 1, -74 * sizeFactor)
    bar.Size = UDim2.new(0, 300, 0, 54)
    bar.BackgroundColor3 = Color3.fromRGB(5, 6, 8)
    bar.BorderSizePixel = 0
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Active = true
    bar.Parent = gui
    guiCorner(bar, 12)
    guiStroke(bar, Color3.fromRGB(0, 0, 0), 1.5)
    local barScale = Instance.new("UIScale")
    barScale.Scale = sizeFactor
    barScale.Parent = bar
    makeDraggable(bar)

    local avatar = Instance.new("ImageLabel")
    avatar.Position = UDim2.new(0, 8, 0, 8)
    avatar.Size = UDim2.new(0, 36, 0, 36)
    avatar.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    avatar.BorderSizePixel = 0
    avatar.Parent = bar
    guiCorner(avatar, 10)
    guiStroke(avatar, Color3.fromRGB(70, 70, 75), 1)
    pcall(function()
        local image = Players:GetUserThumbnailAsync(
            LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48
        )
        avatar.Image = image
    end)

    ProgressPercentLabel = Instance.new("TextLabel")
    ProgressPercentLabel.Position = UDim2.new(0, 52, 0, 8)
    ProgressPercentLabel.Size = UDim2.new(0, 46, 0, 16)
    ProgressPercentLabel.BackgroundTransparency = 1
    ProgressPercentLabel.Text = "0%"
    ProgressPercentLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
    ProgressPercentLabel.TextSize = 14
    ProgressPercentLabel.Font = Enum.Font.GothamBold
    ProgressPercentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ProgressPercentLabel.ZIndex = 3
    ProgressPercentLabel.Parent = bar

    local statsLabel = Instance.new("TextLabel")
    statsLabel.Position = UDim2.new(0, 108, 0, 9)
    statsLabel.Size = UDim2.new(1, -116, 0, 13)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "FPS:
    statsLabel.TextColor3 = Color3.fromRGB(180, 182, 188)
    statsLabel.TextSize = 8
    statsLabel.Font = Enum.Font.GothamBold
    statsLabel.TextXAlignment = Enum.TextXAlignment.Right
    statsLabel.ZIndex = 3
    statsLabel.Parent = bar

    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 52, 1, -14)
    track.Size = UDim2.new(1, -60, 0, 6)
    track.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.Parent = bar
    guiCorner(track, 6)

    LeftToRightFill = Instance.new("Frame")
    LeftToRightFill.Name = "LeftToRightFill"
    LeftToRightFill.Size = UDim2.new(0, 0, 1, 0)
    LeftToRightFill.BackgroundColor3 = StealBarColor
    LeftToRightFill.BorderSizePixel = 0
    LeftToRightFill.Parent = track
    guiCorner(LeftToRightFill, 5)

    local compactFillGradient = Instance.new("UIGradient", LeftToRightFill)
    compactFillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, StealBarColor:Lerp(Color3.new(1, 1, 1), 0.18)),
        ColorSequenceKeypoint.new(1, StealBarColor),
    })

    task.spawn(function()
        local frames, last = 0, tick()
        while statsLabel.Parent do
            frames = frames + 1
            local now = tick()
            if now - last >= 1 then
                local fps = math.floor(frames / (now - last))
                local ping = "
                pcall(function()
                    ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
                end)
                statsLabel.Text = "FPS " .. fps .. "  |  PING " .. ping .. "ms  |  " ..
                    os.date("%I:%M %p")
                frames, last = 0, now
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

function createStealProgressBarV3()
    local old = CoreGui:FindFirstChild("SpaceProgressBar")
    if old then old:Destroy() end
    local sizeFactor = math.clamp(tonumber(StealBarSize) or 1.05, 0.75, 1.5)

    local gui = Instance.new("ScreenGui")
    gui.Name = "SpaceProgressBar"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local bar = Instance.new("Frame")
    bar.Name = "StealBarV3"
    bar.Active = true
    bar.ZIndex = 50
    bar.AnchorPoint = Vector2.new(0.5, 1)
    bar.Position = UDim2.new(0.5, 0, 1, -24)
    bar.Size = UDim2.new(0, 324, 0, 58)
    bar.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    bar.BorderSizePixel = 0
    bar.Parent = gui
    guiCorner(bar, 16)
    local barGradient = Instance.new("UIGradient")
    barGradient.Color = ColorSequence.new(
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(110, 110, 118)
    )
    barGradient.Rotation = 90
    barGradient.Parent = bar
    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.fromRGB(254, 254, 254)
    barStroke.Thickness = 2.4
    barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    barStroke.Transparency = 0.25
    barStroke.Parent = bar
    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 90, 90)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 90, 90)),
    })
    strokeGradient.Parent = barStroke

    local edge = Instance.new("Frame")
    edge.Name = "Edge"
    edge.ZIndex = 49
    edge.Position = UDim2.new(0, -4, 0, -4)
    edge.Size = UDim2.new(1, 8, 1, 8)
    edge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    edge.BorderSizePixel = 0
    edge.Parent = bar
    guiCorner(edge, 20)

    local barScale = Instance.new("UIScale")
    barScale.Scale = sizeFactor
    barScale.Parent = bar
    makeDraggable(bar)

    local percent = Instance.new("TextLabel")
    percent.Name = "StealPercent"
    percent.ZIndex = 54
    percent.Position = UDim2.new(0, 11, 0, 2)
    percent.Size = UDim2.new(0, 90, 0, 18)
    percent.BackgroundTransparency = 1
    percent.Text = "0%"
    percent.TextColor3 = Color3.fromRGB(255, 255, 255)
    percent.TextSize = 17
    percent.Font = Enum.Font.GothamBlack
    percent.TextXAlignment = Enum.TextXAlignment.Left
    percent.Parent = bar

    ProgressPercentLabel = percent

    local fpsLabelV3 = Instance.new("TextLabel")
    fpsLabelV3.Name = "StealFps"
    fpsLabelV3.ZIndex = 54
    fpsLabelV3.Position = UDim2.new(0, 11, 0, 21)
    fpsLabelV3.Size = UDim2.new(0, 90, 0, 13)
    fpsLabelV3.BackgroundTransparency = 1
    fpsLabelV3.Text = "FPS:
    fpsLabelV3.TextColor3 = Color3.fromRGB(190, 190, 198)
    fpsLabelV3.TextSize = 11
    fpsLabelV3.Font = Enum.Font.GothamBold
    fpsLabelV3.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabelV3.Parent = bar

    local modeInfo = Instance.new("TextLabel")
    modeInfo.Name = "StealModeInfo"
    modeInfo.ZIndex = 54
    modeInfo.Position = UDim2.new(0.5, -80, 0, 21)
    modeInfo.Size = UDim2.new(0, 160, 0, 13)
    modeInfo.BackgroundTransparency = 1
    modeInfo.Text = "NORMAL 62 RADIUS"
    modeInfo.TextColor3 = Color3.fromRGB(190, 190, 198)
    modeInfo.TextSize = 11
    modeInfo.Font = Enum.Font.GothamBold
    modeInfo.TextXAlignment = Enum.TextXAlignment.Center
    modeInfo.Parent = bar

    local pingLabelV3 = Instance.new("TextLabel")
    pingLabelV3.Name = "StealPing"
    pingLabelV3.ZIndex = 54
    pingLabelV3.Position = UDim2.new(1, -101, 0, 21)
    pingLabelV3.Size = UDim2.new(0, 90, 0, 13)
    pingLabelV3.BackgroundTransparency = 1
    pingLabelV3.Text = "PING:
    pingLabelV3.TextColor3 = Color3.fromRGB(190, 190, 198)
    pingLabelV3.TextSize = 11
    pingLabelV3.Font = Enum.Font.GothamBold
    pingLabelV3.TextXAlignment = Enum.TextXAlignment.Right
    pingLabelV3.Parent = bar

    local track = Instance.new("Frame")
    track.Name = "StealBarTrack"
    track.ZIndex = 51
    track.ClipsDescendants = true
    track.Position = UDim2.new(0, 9, 1, -22)
    track.Size = UDim2.new(1, -18, 0, 16)
    track.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    track.BorderSizePixel = 0
    track.Parent = bar
    guiCorner(track, 8)

    LeftToRightFill = Instance.new("Frame")
    LeftToRightFill.Name = "Fill"
    LeftToRightFill.ZIndex = 52
    LeftToRightFill.Size = UDim2.new(0, 0, 1, 0)
    LeftToRightFill.BackgroundColor3 = Color3.fromRGB(254, 254, 254)
    LeftToRightFill.BorderSizePixel = 0
    LeftToRightFill.Parent = track
    guiCorner(LeftToRightFill, 8)

    local fillGradient = Instance.new("UIGradient")
    fillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150)),
    })
    fillGradient.Parent = LeftToRightFill

    task.spawn(function()
        local frames, last = 0, tick()
        while bar.Parent do
            frames = frames + 1
            local now = tick()
            if now - last >= 1 then
                local fps = math.floor(frames / (now - last))
                local ping = "
                pcall(function()
                    ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
                end)
                fpsLabelV3.Text = "FPS: " .. fps
                pingLabelV3.Text = "PING: " .. ping .. "ms"
                frames, last = 0, now
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

function createProgressBar()
    if CustomProgressBarVersion == "V3" then
        createStealProgressBarV3()
        return
    elseif CustomProgressBarVersion == "V2" then
        createCompactProgressBarV2()
        return
    end
    local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
    local sizeFactor = math.clamp(tonumber(StealBarSize) or 1.05, 0.75, 1.5)
    
    
    local guiScalePB = isMobile and 0.8 or 1

    local ProgressScreenGui = Instance.new("ScreenGui")
    ProgressScreenGui.Name = "SpaceProgressBar"
    ProgressScreenGui.Parent = CoreGui
    ProgressScreenGui.ResetOnSpawn = false
    ProgressScreenGui.IgnoreGuiInset = true
    ProgressScreenGui.DisplayOrder = 999
    ProgressScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    
    local StealBarShadow = Instance.new("Frame")
    StealBarShadow.Name = "StealBarShadow"
    StealBarShadow.ZIndex = 9
    StealBarShadow.Position = UDim2.new(0.5, -177 * guiScalePB * sizeFactor, 1, -39 * guiScalePB * sizeFactor)
    StealBarShadow.Size = UDim2.new(0, 352 * guiScalePB, 0, 35 * guiScalePB)
    StealBarShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    StealBarShadow.BackgroundTransparency = 0.35
    StealBarShadow.BorderSizePixel = 0
    
    
    local shadowScale = Instance.new("UIScale")
    shadowScale.Scale = sizeFactor
    shadowScale.Parent = StealBarShadow

    local ShadowCorner = Instance.new("UICorner")
    ShadowCorner.CornerRadius = UDim.new(0, 14)
    ShadowCorner.Parent = StealBarShadow

    
    local StealBar = Instance.new("TextButton")
    StealBar.Name = "StealBar"
    StealBar.ZIndex = 10
    StealBar.ClipsDescendants = true
    StealBar.Position = UDim2.new(0.5, -180 * guiScalePB * sizeFactor, 1, -43 * guiScalePB * sizeFactor)
    StealBar.Size = UDim2.new(0, 352 * guiScalePB, 0, 35 * guiScalePB)
    StealBar.BackgroundColor3 = Color3.fromRGB(8, 8, 9)
    StealBar.BackgroundTransparency = 0
    StealBar.BorderSizePixel = 0
    StealBar.Text = ""
    StealBar.AutoButtonColor = false
    StealBar.Active = true
    StealBar.Draggable = true
    StealBar.Parent = ProgressScreenGui
    local barScale = Instance.new("UIScale")
    barScale.Scale = sizeFactor
    barScale.Parent = StealBar

    makeDraggable(StealBar)
    makeDraggable(StealBarShadow)

    
    local function updateShadowPosition()
        StealBarShadow.Position = UDim2.new(
            StealBar.Position.X.Scale,
            StealBar.Position.X.Offset - 3 * guiScalePB,
            StealBar.Position.Y.Scale,
            StealBar.Position.Y.Offset + 3 * guiScalePB
        )
    end

    StealBar:GetPropertyChangedSignal("Position"):Connect(updateShadowPosition)
    task.wait()
    updateShadowPosition()

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 19)
    BarCorner.Parent = StealBar

    local BarStroke = Instance.new("UIStroke")
    BarStroke.Color = Color3.fromRGB(0, 0, 0)
    BarStroke.Thickness = 1.5
    BarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BarStroke.Transparency = 0.1
    BarStroke.Parent = StealBar

    local BarGradient = Instance.new("UIGradient")
    BarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 3, 4))
    })
    BarGradient.Rotation = 0
    BarGradient.Parent = StealBar

    ProgressTrack = Instance.new("Frame")
    ProgressTrack.Name = "ProgressTrack"
    ProgressTrack.ZIndex = 11
    ProgressTrack.Size = UDim2.new(0, 210 * guiScalePB, 1, 0)
    ProgressTrack.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    ProgressTrack.BorderSizePixel = 0
    ProgressTrack.ClipsDescendants = true
    ProgressTrack.Parent = StealBar
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = ProgressTrack
    local TrackStroke = Instance.new("UIStroke")
    TrackStroke.Thickness = 1.5
    
    TrackStroke.Color = Color3.fromRGB(22, 22, 22)
    TrackStroke.Transparency = 1
    TrackStroke.Parent = ProgressTrack

    
    LeftToRightFill = Instance.new("Frame")
    LeftToRightFill.Name = "LeftToRightFill"
    LeftToRightFill.ZIndex = 11
    LeftToRightFill.Size = UDim2.new(0, 0, 1, 0)
    LeftToRightFill.BackgroundColor3 = StealBarColor
    LeftToRightFill.BackgroundTransparency = 0.08
    LeftToRightFill.BorderSizePixel = 0
    LeftToRightFill.Parent = ProgressTrack

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 14)
    FillCorner.Parent = LeftToRightFill

    local FillGradient = Instance.new("UIGradient")
    FillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, StealBarColor:Lerp(Color3.new(1, 1, 1), 0.18)),
        ColorSequenceKeypoint.new(0.5, StealBarColor),
        ColorSequenceKeypoint.new(1, StealBarColor:Lerp(Color3.new(0, 0, 0), 0.16))
    })
    FillGradient.Parent = LeftToRightFill

    
    local DotPoint = Instance.new("Frame")
    DotPoint.Name = "DotPoint"
    DotPoint.ZIndex = 12
    DotPoint.Position = UDim2.new(0, 12 * guiScalePB, 0.5, -4 * guiScalePB)
    DotPoint.Size = UDim2.new(0, 8 * guiScalePB, 0, 8 * guiScalePB)
    DotPoint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DotPoint.BackgroundTransparency = 0.3
    DotPoint.BorderSizePixel = 0
    local DotCorner2 = Instance.new("UICorner")
    DotCorner2.CornerRadius = UDim.new(1, 0)
    DotCorner2.Parent = DotPoint
    DotPoint.Parent = StealBar
    DotPoint.Visible = false

    
    
    ProgressPercentLabel = Instance.new("TextLabel")
    ProgressPercentLabel.Name = "Percent"
    ProgressPercentLabel.ZIndex = 12
    ProgressPercentLabel.Position = UDim2.new(0, 0, 0, 0)
    ProgressPercentLabel.Size = UDim2.new(1, -14 * guiScalePB, 1, 0)
    ProgressPercentLabel.BackgroundTransparency = 1
    ProgressPercentLabel.Text = ""
    ProgressPercentLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    ProgressPercentLabel.TextSize = 10 * guiScalePB
    ProgressPercentLabel.Font = Enum.Font.GothamBold
    ProgressPercentLabel.TextXAlignment = Enum.TextXAlignment.Right
    ProgressPercentLabel.Visible = true
    ProgressPercentLabel.Parent = StealBar

    local StealTitle = Instance.new("TextLabel")
    StealTitle.Name = "StealTitle"
    StealTitle.ZIndex = 13
    StealTitle.Position = UDim2.new(0, 15 * guiScalePB, 0, 0)
    StealTitle.Size = UDim2.new(0, 125 * guiScalePB, 1, 0)
    StealTitle.BackgroundTransparency = 1
    
    StealTitle.Text = "STEAL"
    StealTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
    StealTitle.TextSize = 12 * guiScalePB
    StealTitle.Font = Enum.Font.GothamBold
    StealTitle.TextXAlignment = Enum.TextXAlignment.Left
    StealTitle.Parent = ProgressTrack

    local StatsDivider = Instance.new("Frame")
    StatsDivider.Name = "StatsDivider"
    StatsDivider.ZIndex = 13
    StatsDivider.Position = UDim2.new(0, 212 * guiScalePB, 0, 5 * guiScalePB)
    StatsDivider.Size = UDim2.new(0, 1 * guiScalePB, 1, -10 * guiScalePB)
    StatsDivider.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
    StatsDivider.BorderSizePixel = 0
    StatsDivider.Parent = StealBar

    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Name = "Stats"
    StatsLabel.ZIndex = 13
    StatsLabel.Position = UDim2.new(0, 224 * guiScalePB, 0, 0)
    StatsLabel.Size = UDim2.new(0, 125 * guiScalePB, 1, 0)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Text = "FPS:
    StatsLabel.TextColor3 = Color3.fromRGB(235, 235, 238)
    StatsLabel.TextSize = 11 * guiScalePB
    StatsLabel.Font = Enum.Font.GothamBold
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.Parent = StealBar

    task.spawn(function()
        local frames = 0
        local lastTime = tick()
        while StatsLabel and StatsLabel.Parent do
            frames = frames + 1
            local now = tick()
            if now - lastTime >= 1 then
                local fps = math.floor(frames / (now - lastTime))
                local ping = "
                pcall(function()
                    ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
                end)
                StatsLabel.Text = "FPS:" .. tostring(fps) .. "   PING:" .. ping
                frames = 0
                lastTime = now
            end
            RunService.RenderStepped:Wait()
        end
    end)
end


local CONFIG_FILE = "SpaceConfig.json"
local autoSaveScheduled = false

function scheduleAutoSave()
    if autoSaveScheduled then return end
    autoSaveScheduled = true
    task.delay(0.3, function()
        autoSaveScheduled = false
        local cfg = {
            normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed,
            laggerNormalSpeed=State.laggerNormalSpeed, laggerCarrySpeed=State.laggerCarrySpeed,
            laggerModeEnabled=State.laggerModeEnabled,
            autoCarryEnabled=State.autoCarryEnabled,
            infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled,
            ragdollTimer=State.ragdollTimerEnabled, ragdollTimerDuration=State.ragdollTimerDuration,
            antiDie=State.antiDieEnabled,
            fpsBoost=State.fpsBoostEnabled, medusaCounter=State.medusaCounterEnabled,
            batCounter=State.batCounterEnabled, skyMode=State.skyMode,
            stretchResEnabled=State.stretchResEnabled,
            floatingBtnsVisible=State.floatingBtnsVisible,
            bypassGuiVisible=State.bypassGuiVisible, laggerGuiVisible=State.laggerGuiVisible,
            autoBatKey=Keys.autoBat.Name, autoBatV2Key=Keys.autoBatV2.Name,
            tpBatKey=Keys.tpBat.Name,
            autoLeftKey=Keys.autoLeft.Name, autoRightKey=Keys.autoRight.Name,
            autoBatToggled=State.autoBatToggled,
            tpBatEnabled=State.tpBatEnabled,
            speedKey=Keys.speed.Name, guiHideKey=Keys.guiHide.Name,
            dropBrainrotKey=Keys.dropBrainrot.Name, tpDownKey=Keys.tpDown.Name,
            instaResetKey=Keys.instaReset.Name,
            laggerToggleKey=Keys.laggerToggle.Name,
            fov=State.fov,
            backgroundEnabled=State.backgroundEnabled, backgroundIndex=State.backgroundIndex,
            accentR=State.accentR, accentG=State.accentG, accentB=State.accentB,
            autoSwingEnabled=autoSwingEnabled, unwalkEnabled=State.unwalkEnabled,
            bypassKeybind=BypassSettings.keybind, bypassPower=BypassSettings.power,
            bypassVersion=BypassSettings.version, bypassMode=BypassSettings.activeMode,
            laggerKeybind=LaggerSettings.keybind, laggerVersion=LaggerSettings.version,
            laggerMode=LaggerSettings.activeMode,
            autoGrabEnabled=State.autoGrabEnabled,
            grabStealRadius=State.grabStealRadius,
            grabStealDuration=State.grabStealDuration,
            primeRange=State.primeRange,
            autoStealVersion=State.autoStealVersion,
            stealMode=State.stealMode,
            normalStealVersion=State.normalStealVersion,
            bodyLockEnabled=State.bodyLockEnabled,
            korbloxEnabled=State.korbloxEnabled,
            outfit=State.outfit,
            animationPack=State.animationPack,
            autoBatVersion=State.autoBatVersion,
            customUI = SpaceHubActiveCustomUI,
            customProgressBar = CustomProgressBarVersion,
            stealBarSize = StealBarSize,
        }
        pcall(function() if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(cfg)) end end)
    end)
end

do
    local hasFile = false
    pcall(function() hasFile = isfile and isfile(CONFIG_FILE) end)
    if hasFile then
        local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and cfg then
            if type(cfg.normalSpeed)=="number" then State.normalSpeed=cfg.normalSpeed end
            if type(cfg.carrySpeed)=="number" then State.carrySpeed=cfg.carrySpeed end
            if type(cfg.laggerNormalSpeed)=="number" then State.laggerNormalSpeed=cfg.laggerNormalSpeed end
            if type(cfg.laggerCarrySpeed)=="number" then State.laggerCarrySpeed=cfg.laggerCarrySpeed end
            if type(cfg.laggerModeEnabled)=="boolean" then State.laggerModeEnabled=cfg.laggerModeEnabled end
            if type(cfg.autoCarryEnabled)=="boolean" then State.autoCarryEnabled=cfg.autoCarryEnabled end
            if type(cfg.infJump)=="boolean" then State.infJumpEnabled=cfg.infJump end
            if type(cfg.antiRagdoll)=="boolean" then State.antiRagdollEnabled=cfg.antiRagdoll end
            if type(cfg.ragdollTimer)=="boolean" then State.ragdollTimerEnabled=cfg.ragdollTimer end
            if type(cfg.ragdollTimerDuration)=="number" then State.ragdollTimerDuration=math.clamp(cfg.ragdollTimerDuration,1,60) end
            if type(cfg.antiDie)=="boolean" then State.antiDieEnabled=cfg.antiDie end
            if type(cfg.fpsBoost)=="boolean" then State.fpsBoostEnabled=cfg.fpsBoost end
            if type(cfg.medusaCounter)=="boolean" then State.medusaCounterEnabled=cfg.medusaCounter end
            if type(cfg.batCounter)=="boolean" then State.batCounterEnabled=cfg.batCounter end
            if type(cfg.skyMode)=="number" then State.skyMode=cfg.skyMode end
            if type(cfg.stretchResEnabled)=="boolean" then State.stretchResEnabled=cfg.stretchResEnabled end
            if type(cfg.floatingBtnsVisible)=="boolean" then State.floatingBtnsVisible=cfg.floatingBtnsVisible end
            if type(cfg.bypassGuiVisible)=="boolean" then State.bypassGuiVisible=cfg.bypassGuiVisible end
            if type(cfg.laggerGuiVisible)=="boolean" then State.laggerGuiVisible=cfg.laggerGuiVisible end
            if type(cfg.tpBatEnabled)=="boolean" then State.tpBatEnabled=cfg.tpBatEnabled end
            if type(cfg.autoBatToggled)=="boolean" then State.autoBatToggled=cfg.autoBatToggled end
            if type(cfg.autoBatKey)=="string" and Enum.KeyCode[cfg.autoBatKey] then Keys.autoBat=Enum.KeyCode[cfg.autoBatKey] end
            if type(cfg.autoBatV2Key)=="string" and Enum.KeyCode[cfg.autoBatV2Key] then
                Keys.autoBatV2=Enum.KeyCode[cfg.autoBatV2Key]
            end
            if type(cfg.tpBatKey)=="string" and Enum.KeyCode[cfg.tpBatKey] then
                Keys.tpBat=Enum.KeyCode[cfg.tpBatKey]
            end
            if type(cfg.autoLeftKey)=="string" and Enum.KeyCode[cfg.autoLeftKey] then
                Keys.autoLeft=Enum.KeyCode[cfg.autoLeftKey]
            end
            if type(cfg.autoRightKey)=="string" and Enum.KeyCode[cfg.autoRightKey] then
                Keys.autoRight=Enum.KeyCode[cfg.autoRightKey]
            end
            if type(cfg.speedKey)=="string" and Enum.KeyCode[cfg.speedKey] then Keys.speed=Enum.KeyCode[cfg.speedKey] end
            if type(cfg.guiHideKey)=="string" and Enum.KeyCode[cfg.guiHideKey] then Keys.guiHide=Enum.KeyCode[cfg.guiHideKey] end
            if type(cfg.dropBrainrotKey)=="string" and Enum.KeyCode[cfg.dropBrainrotKey] then Keys.dropBrainrot=Enum.KeyCode[cfg.dropBrainrotKey] end
            if type(cfg.tpDownKey)=="string" and Enum.KeyCode[cfg.tpDownKey] then Keys.tpDown=Enum.KeyCode[cfg.tpDownKey] end
            if type(cfg.instaResetKey)=="string" and Enum.KeyCode[cfg.instaResetKey] then Keys.instaReset=Enum.KeyCode[cfg.instaResetKey] end
            if type(cfg.laggerToggleKey)=="string" and Enum.KeyCode[cfg.laggerToggleKey] then Keys.laggerToggle=Enum.KeyCode[cfg.laggerToggleKey] end
            if type(cfg.fov)=="number" then State.fov=cfg.fov end
            if type(cfg.backgroundEnabled)=="boolean" then State.backgroundEnabled=cfg.backgroundEnabled end
            if type(cfg.backgroundIndex)=="number" then State.backgroundIndex=cfg.backgroundIndex end
            if type(cfg.accentR)=="number" then State.accentR=math.clamp(cfg.accentR,0,255) end
            if type(cfg.accentG)=="number" then State.accentG=math.clamp(cfg.accentG,0,255) end
            if type(cfg.accentB)=="number" then State.accentB=math.clamp(cfg.accentB,0,255) end
            if type(cfg.autoSwingEnabled)=="boolean" then autoSwingEnabled=cfg.autoSwingEnabled end
            if type(cfg.unwalkEnabled)=="boolean" then
                State.unwalkEnabled = cfg.unwalkEnabled
                if State.unwalkEnabled then task.delay(0.5, function() startUnwalk() end) end
            end
            if type(cfg.bypassKeybind)=="string" then BypassSettings.keybind=cfg.bypassKeybind end
            if type(cfg.bypassPower)=="number" then BypassSettings.power=math.clamp(cfg.bypassPower,10000,120000) end
            if type(cfg.bypassVersion)=="string" then BypassSettings.version=cfg.bypassVersion end
            if type(cfg.bypassMode)=="string" then BypassSettings.activeMode=cfg.bypassMode end
            if type(cfg.laggerKeybind)=="string" then LaggerSettings.keybind=cfg.laggerKeybind end
            if type(cfg.laggerVersion)=="string" then LaggerSettings.version=cfg.laggerVersion end
            if type(cfg.laggerMode)=="string" then LaggerSettings.activeMode=cfg.laggerMode end
            if type(cfg.autoGrabEnabled)=="boolean" then State.autoGrabEnabled=cfg.autoGrabEnabled end
            if type(cfg.grabStealRadius)=="number" then State.grabStealRadius=cfg.grabStealRadius end
            if type(cfg.grabStealDuration)=="number" then State.grabStealDuration=cfg.grabStealDuration end
            if type(cfg.primeRange)=="number" then State.primeRange=cfg.primeRange end
            if cfg.autoStealVersion == "V1" or cfg.autoStealVersion == "V2" then
                State.autoStealVersion=cfg.autoStealVersion
            end
            if cfg.stealMode == "normal" or cfg.stealMode == "op" then
                State.stealMode=cfg.stealMode
            end
            if cfg.normalStealVersion == "75" or cfg.normalStealVersion == "80"
                or cfg.normalStealVersion == "86" or cfg.normalStealVersion == "90" then
                State.normalStealVersion=cfg.normalStealVersion
            end
            if type(cfg.bodyLockEnabled)=="boolean" then State.bodyLockEnabled=cfg.bodyLockEnabled end
            if type(cfg.korbloxEnabled)=="boolean" then State.korbloxEnabled=cfg.korbloxEnabled end
            if cfg.outfit == "Off" or cfg.outfit == "Tenue 1"
                or cfg.outfit == "Tenue 2" or cfg.outfit == "Tenue 3"
                or cfg.outfit == "Tenue 4" or cfg.outfit == "Tenue 5" then
                State.outfit = cfg.outfit
            end
            if type(cfg.animationPack)=="string" then State.animationPack=cfg.animationPack end
            if cfg.autoBatVersion == "V1" or cfg.autoBatVersion == "V2" then
                State.autoBatVersion = cfg.autoBatVersion
            end
            if type(cfg.customUI)=="string" then SpaceHubActiveCustomUI="V1" end
            if cfg.customProgressBar == "V1" or cfg.customProgressBar == "V2" or cfg.customProgressBar == "V3" then
                CustomProgressBarVersion = cfg.customProgressBar
            end
            if type(cfg.stealBarSize) == "number" then
                StealBarSize = math.clamp(
                    math.floor(cfg.stealBarSize * 100 + 0.5) / 100,
                    0.75,
                    1.5
                )
            end
        end
    end
end


Outfit = {
    _character = nil,
    _originalDescription = nil,
}

OUTFIT_PRESETS = {
    ["Tenue 1"] = {
        colors = {
            HeadColor = Color3.fromRGB(255, 224, 189),
            LeftArmColor = Color3.fromRGB(255, 224, 189),
            RightArmColor = Color3.fromRGB(255, 224, 189),
            LeftLegColor = Color3.fromRGB(35, 35, 42),
            RightLegColor = Color3.fromRGB(35, 35, 42),
            TorsoColor = Color3.fromRGB(245, 245, 245),
        },
        scales = {HeightScale = 1, WidthScale = 1, DepthScale = 1, BodyTypeScale = 0},
    },
    ["Tenue 2"] = {
        colors = {
            HeadColor = Color3.fromRGB(255, 205, 170),
            LeftArmColor = Color3.fromRGB(255, 205, 170),
            RightArmColor = Color3.fromRGB(255, 205, 170),
            LeftLegColor = Color3.fromRGB(20, 20, 24),
            RightLegColor = Color3.fromRGB(20, 20, 24),
            TorsoColor = Color3.fromRGB(35, 35, 42),
        },
        scales = {HeightScale = 1.05, WidthScale = 0.9, DepthScale = 0.9, BodyTypeScale = 0.15},
    },
    ["Tenue 3"] = {
        colors = {
            HeadColor = Color3.fromRGB(255, 224, 189),
            LeftArmColor = Color3.fromRGB(255, 224, 189),
            RightArmColor = Color3.fromRGB(255, 224, 189),
            LeftLegColor = Color3.fromRGB(70, 90, 145),
            RightLegColor = Color3.fromRGB(70, 90, 145),
            TorsoColor = Color3.fromRGB(90, 140, 220),
        },
        scales = {HeightScale = 0.98, WidthScale = 1.04, DepthScale = 1.04, BodyTypeScale = 0.25},
    },
    ["Tenue 4"] = {
        colors = {
            HeadColor = Color3.fromRGB(190, 190, 200),
            LeftArmColor = Color3.fromRGB(190, 190, 200),
            RightArmColor = Color3.fromRGB(190, 190, 200),
            LeftLegColor = Color3.fromRGB(85, 45, 110),
            RightLegColor = Color3.fromRGB(85, 45, 110),
            TorsoColor = Color3.fromRGB(145, 70, 185),
        },
        scales = {HeightScale = 1.08, WidthScale = 0.86, DepthScale = 0.86, BodyTypeScale = 0.35},
    },
    ["Tenue 5"] = {
        colors = {
            HeadColor = Color3.fromRGB(255, 224, 189),
            LeftArmColor = Color3.fromRGB(255, 224, 189),
            RightArmColor = Color3.fromRGB(255, 224, 189),
            LeftLegColor = Color3.fromRGB(170, 35, 45),
            RightLegColor = Color3.fromRGB(170, 35, 45),
            TorsoColor = Color3.fromRGB(220, 45, 55),
        },
        scales = {HeightScale = 1.12, WidthScale = 0.94, DepthScale = 0.94, BodyTypeScale = 0.2},
    },
}

function Outfit.set(name)
    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false, "Humanoid introuvable" end

    if character ~= Outfit._character then
        Outfit._character = character
        Outfit._originalDescription = nil
    end

    if not Outfit._originalDescription then
        local ok, description = pcall(function()
            return humanoid:GetAppliedDescription()
        end)
        if not ok or not description then
            return false, "Impossible de lire la tenue actuelle"
        end
        Outfit._originalDescription = description:Clone()
    end

    local description = Outfit._originalDescription:Clone()
    if name ~= "Off" then
        local preset = OUTFIT_PRESETS[name]
        if not preset then return false, "Tenue inconnue" end
        for property, value in pairs(preset.colors) do
            pcall(function() description[property] = value end)
        end
        for property, value in pairs(preset.scales) do
            pcall(function() description[property] = value end)
        end
    end

    local ok, err = pcall(function()
        humanoid:ApplyDescription(description)
    end)
    if not ok then return false, err end
    State.outfit = name
    return true
end

Anim = {
    currentCharacter = nil,
    originalIds = {},
    Packs = {
        {"Off", nil},
        {"Default", {
            idle = {"507766666", "507766951"}, walk = "507777826",
            run = "507767714", jump = "507765000", fall = "507767968",
            climb = "507765644", swim = "507784897", swimIdle = "507785072",
        }},
        {"Ninja", {
            idle = {"656117400", "656118341"}, walk = "656121766",
            run = "656118852", jump = "656117878", fall = "656115606",
            climb = "656114359", swim = "656119721", swimIdle = "656120030",
        }},
        {"Zombie", {
            idle = {"616158929", "616160636"}, walk = "616168032",
            run = "616163682", jump = "616161997", fall = "616157476",
            climb = "616156119", swim = "616165109", swimIdle = "616166655",
        }},
        {"Toy", {
            idle = {"782841498", "782845736"}, walk = "782842708",
            run = "782842708", jump = "782847742", fall = "782846423",
            climb = "782843345", swim = "782844869", swimIdle = "782845186",
        }},
        {"Werewolf", {
            idle = {"108972460", "108973087"}, walk = "108978279",
            run = "108979811", jump = "108981979", fall = "108983357",
            climb = "108978439", swim = "108977989", swimIdle = "108977916",
        }},
    },
}

ANIM_TARGETS = {
    {"idle", "Animation1", "idle", 1}, {"idle", "Animation2", "idle", 2},
    {"walk", "WalkAnim", "walk"}, {"run", "RunAnim", "run"},
    {"jump", "JumpAnim", "jump"}, {"fall", "FallAnim", "fall"},
    {"climb", "ClimbAnim", "climb"}, {"swim", "Swim", "swim"},
    {"swimidle", "SwimIdle", "swimIdle"},
}

function animationObject(animate, folderName, objectName)
    local folder = animate and animate:FindFirstChild(folderName)
    return folder and folder:FindFirstChild(objectName)
end

function Anim.apply(pack)
    local character = LP.Character
    local animate = character and character:FindFirstChild("Animate")
    if not animate then return false, "Animate introuvable" end

    if character ~= Anim.currentCharacter then
        Anim.currentCharacter = character
        Anim.originalIds = {}
    end

    for index, target in ipairs(ANIM_TARGETS) do
        local object = animationObject(animate, target[1], target[2])
        if object and object:IsA("Animation") then
            if not Anim.originalIds[index] then
                Anim.originalIds[index] = object.AnimationId
            end
        end
    end

    local ids = pack[2]
    for index, target in ipairs(ANIM_TARGETS) do
        local object = animationObject(animate, target[1], target[2])
        if object and object:IsA("Animation") then
            local value
            if ids then
                value = ids[target[3]]
                if target[4] then value = value and value[target[4]] end
            else
                value = Anim.originalIds[index]
            end
            if value and value ~= "" then
                object.AnimationId = tostring(value):find("rbxassetid://", 1, true)
                    and tostring(value) or "rbxassetid://" .. tostring(value)
            end
        end
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop(0.05) end)
        end
    end
    return true
end

function Anim.next()
    local index = 1
    for i, pack in ipairs(Anim.Packs) do
        if pack[1] == State.animationPack then index = i; break end
    end
    local nextPack = Anim.Packs[index % #Anim.Packs + 1]
    local ok = Anim.apply(nextPack)
    if ok then State.animationPack = nextPack[1] end
    scheduleAutoSave()
    return State.animationPack
end


Outfit = {
    CurrentCharacter = nil,
    OriginalParts = {},
    OriginalShirt = nil,
    OriginalPants = nil,
    OriginalAccessories = {},
    OriginalScales = {},
    OriginalHeadLocalTransparencyModifier = 0,
    HeadGuardConnection = nil,
    Captured = false,
    Data = {
        ["Tenue 1"] = {
            shirtId = "18517930542", pantsId = "13572825731",
            accessory1 = "17163576447",
        },
        ["Tenue 2"] = {
            shirtId = "140584202280207", pantsId = "86970886981391",
            accessory1 = "15625714011", accessory2 = "15625910919",
        },
        ["Tenue 3"] = {
            shirtId = "127542925103240", pantsId = "6475285676",
            accessory1 = "110695860265349", accessory2 = "5644816041",
            accessory3 = "1", accessory4 = "1",
            scales = {
                BodyDepthScale = 0.85, BodyHeightScale = 0.90,
                BodyProportionScale = 0.50, BodyTypeScale = 0.00,
                BodyWidthScale = 0.70, HeadScale = 0.95,
            },
            bodyColor = Color3.fromRGB(90, 89, 91),
        },
        ["Tenue 4"] = {
            shirtId = "138467256717912", pantsId = "6475285676",
            accessory1 = "15625714011", accessory2 = "91864630618004",
            accessory3 = "1", accessory4 = "18473875856",
            scales = {
                BodyDepthScale = 0.85, BodyHeightScale = 0.90,
                BodyProportionScale = 0.50, BodyTypeScale = 0.00,
                BodyWidthScale = 0.70, HeadScale = 0.95,
            },
            bodyColor = Color3.fromRGB(243, 223, 208),
        },
        ["Tenue 5"] = {
            shirtId = "14138181304", pantsId = "117431351365360",
            accessory1 = "117141606635719", accessory2 = "88101962627986",
            accessory3 = "11685171991", accessory4 = "1",
            scales = {
                BodyDepthScale = 0.62, BodyHeightScale = 1.10,
                BodyProportionScale = 0.85, BodyTypeScale = 0.25,
                BodyWidthScale = 0.52, HeadScale = 0.92,
            },
            bodyColor = Color3.fromRGB(17, 17, 17),
        },
    },
}

function Outfit.stopHeadGuard()
    if Outfit.HeadGuardConnection then
        Outfit.HeadGuardConnection:Disconnect()
        Outfit.HeadGuardConnection = nil
    end
end

function Outfit.hideHead(character)
    local head = character and character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        head.Transparency = 1
        head.LocalTransparencyModifier = 1
    end
end

function Outfit.startHeadGuard(character)
    Outfit.stopHeadGuard()
    Outfit.hideHead(character)
    Outfit.HeadGuardConnection = RunService.RenderStepped:Connect(function()
        if not Outfit.Captured or Outfit.CurrentCharacter ~= character
            or State.outfit == "Off" then
            Outfit.stopHeadGuard()
            return
        end
        Outfit.hideHead(character)
    end)
end

function Outfit.capture(character)
    Outfit.CurrentCharacter = character
    Outfit.OriginalParts = {}
    local head = character:FindFirstChild("Head")
    Outfit.OriginalHeadLocalTransparencyModifier =
        head and head:IsA("BasePart") and head.LocalTransparencyModifier or 0
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            Outfit.OriginalParts[part.Name] = {
                Color = part.Color, Transparency = part.Transparency,
            }
        end
    end
    local shirt = character:FindFirstChildOfClass("Shirt")
    local pants = character:FindFirstChildOfClass("Pants")
    Outfit.OriginalShirt = shirt and shirt:Clone() or nil
    Outfit.OriginalPants = pants and pants:Clone() or nil
    Outfit.OriginalAccessories = {}
    for _, object in ipairs(character:GetChildren()) do
        if object:IsA("Accessory") then
            table.insert(Outfit.OriginalAccessories, object:Clone())
        end
    end
    Outfit.OriginalScales = {}
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, name in ipairs({
            "BodyDepthScale", "BodyHeightScale", "BodyProportionScale",
            "BodyTypeScale", "BodyWidthScale", "HeadScale",
        }) do
            local scale = humanoid:FindFirstChild(name)
            if scale and scale:IsA("NumberValue") then
                Outfit.OriginalScales[name] = scale.Value
            end
        end
    end
    Outfit.Captured = true
end

function Outfit.destroyObjects(character)
    for _, name in ipairs({
        "SpaceHubOutfitRightLeg", "SpaceHubOutfitAccessory1",
        "SpaceHubOutfitAccessory2", "SpaceHubOutfitAccessory3",
        "SpaceHubOutfitAccessory4", "SpaceHubOutfitAccessory5",
        "SpaceHubOutfitAccessory6", "SpaceHubOutfitAccessory7",
    }) do
        local object = character:FindFirstChild(name)
        if object then object:Destroy() end
    end
end

function Outfit.removeAccessories(character)
    for _, object in ipairs(character:GetChildren()) do
        if object:IsA("Accessory") then object:Destroy() end
    end
end

function Outfit.restore()
    local character = Outfit.CurrentCharacter
    if not character or not Outfit.Captured then return end
    Outfit.stopHeadGuard()
    Outfit.destroyObjects(character)
    Outfit.removeAccessories(character)
    for name, values in pairs(Outfit.OriginalParts) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            part.Color = values.Color
            part.Transparency = values.Transparency
        end
    end
    local shirt = character:FindFirstChildOfClass("Shirt")
    if shirt then shirt:Destroy() end
    if Outfit.OriginalShirt then Outfit.OriginalShirt:Clone().Parent = character end
    local pants = character:FindFirstChildOfClass("Pants")
    if pants then pants:Destroy() end
    if Outfit.OriginalPants then Outfit.OriginalPants:Clone().Parent = character end
    for _, accessory in ipairs(Outfit.OriginalAccessories) do
        accessory:Clone().Parent = character
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for name, value in pairs(Outfit.OriginalScales) do
            local scale = humanoid:FindFirstChild(name)
            if scale and scale:IsA("NumberValue") then scale.Value = value end
        end
    end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        head.LocalTransparencyModifier = Outfit.OriginalHeadLocalTransparencyModifier
    end
    Outfit.Captured = false
    Outfit.CurrentCharacter = nil
    Outfit.OriginalParts = {}
    Outfit.OriginalAccessories = {}
    Outfit.OriginalShirt = nil
    Outfit.OriginalPants = nil
    Outfit.OriginalScales = {}
end

function Outfit.addAccessory(character, assetId, name, forceManual)
    if not assetId or tostring(assetId) == "" or tostring(assetId) == "1" then
        return false
    end
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)
    if not ok or not objects or #objects == 0 then return false end
    local accessory = objects[1]
    if not accessory:IsA("Accessory") then
        local nested = accessory:FindFirstChildWhichIsA("Accessory", true)
        if nested then
            nested.Parent = nil
            accessory:Destroy()
            accessory = nested
        end
    end
    accessory.Name = name
    local handle = accessory:FindFirstChild("Handle")
        or accessory:FindFirstChildWhichIsA("BasePart", true)
    local head = character:FindFirstChild("Head")
    if not handle or not handle:IsA("BasePart") or not head then
        accessory:Destroy()
        return false
    end
    for _, object in ipairs(accessory:GetDescendants()) do
        if object:IsA("BasePart") then
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
            object.Massless = true
        end
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hasAttachment = accessory:FindFirstChildWhichIsA("Attachment", true) ~= nil
    if not forceManual and humanoid and hasAttachment and accessory:IsA("Accessory") then
        accessory.Parent = character
        local added = pcall(function() humanoid:AddAccessory(accessory) end)
        local attached = handle:FindFirstChildWhichIsA("Weld", true)
            or handle:FindFirstChildWhichIsA("WeldConstraint", true)
        if added and attached then return true end
        accessory.Parent = nil
    end
    handle.CFrame = head.CFrame * CFrame.new(
        0, 0, -(head.Size.Z * 0.5 + handle.Size.Z * 0.5)
    ) * CFrame.Angles(0, math.rad(180), 0)
    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = handle
    weld.C0 = head.CFrame:Inverse() * handle.CFrame
    weld.Parent = handle
    accessory.Parent = character
    return true
end

function Outfit.addRightLeg(character)
    local target = character:FindFirstChild("RightUpperLeg")
        or character:FindFirstChild("Right Leg")
    if not target then return false end
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://139607718")
    end)
    if not ok or not objects or #objects == 0 then return false end
    local asset = objects[1]
    asset.Name = "SpaceHubOutfitRightLeg"
    local mesh = asset:IsA("BasePart") and asset
        or asset:FindFirstChildWhichIsA("BasePart", true)
    if not mesh then asset:Destroy(); return false end
    for _, name in ipairs({"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"}) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then part.Transparency = 1 end
    end
    for _, object in ipairs(asset:GetDescendants()) do
        if object:IsA("BasePart") then
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
            object.Massless = true
        end
    end
    mesh.CFrame = target.CFrame
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target
    weld.Part1 = mesh
    weld.Parent = mesh
    asset.Parent = character
    return true
end

function Outfit.apply(name)
    local character = LP.Character
    local data = Outfit.Data[name]
    if not character or not data then return false, "Tenue inconnue" end
    if Outfit.Captured and Outfit.CurrentCharacter == character then
        Outfit.restore()
    end
    Outfit.capture(character)
    Outfit.destroyObjects(character)
    Outfit.removeAccessories(character)
    Outfit.startHeadGuard(character)
    local shirt = character:FindFirstChildOfClass("Shirt")
    if shirt then shirt:Destroy() end
    local newShirt = Instance.new("Shirt")
    newShirt.ShirtTemplate = "rbxassetid://" .. data.shirtId
    newShirt.Parent = character
    local pants = character:FindFirstChildOfClass("Pants")
    if pants then pants:Destroy() end
    local newPants = Instance.new("Pants")
    newPants.PantsTemplate = "rbxassetid://" .. data.pantsId
    newPants.Parent = character
    Outfit.addRightLeg(character)
    for index = 1, 7 do
        local id = data["accessory" .. tostring(index)]
        if id then Outfit.addAccessory(
            character, id, "SpaceHubOutfitAccessory" .. tostring(index), index == 1
        ) end
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and data.scales then
        for name, value in pairs(data.scales) do
            local scale = humanoid:FindFirstChild(name)
            if scale and scale:IsA("NumberValue") then scale.Value = value end
        end
    end
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and (
            part.Name:find("Torso") or part.Name:find("Arm")
            or part.Name:find("Leg") or part.Name:find("Foot")
            or part.Name == "Head"
        ) then
            part.Color = data.bodyColor or part.Color
        end
    end
    State.outfit = name
    return true
end

function Outfit.set(name)
    if name == "Off" then Outfit.restore(); State.outfit = "Off"; return true end
    return Outfit.apply(name)
end


Anim = {
    Packs = {
        {"Adidas Sports",18537392113,18537384940,18537380791,18537367238,18537387180,18537389531,18537363391,18537376492,18537371272},
        {"Adidas Community",122150855457006,82598234841035,75290611992385,98600215928904,109346520324160,133308483266208,88763136693023,122257458498464,102357151005774},
        {"Adidas Aura",83842218823011,118320322718866,109996626521204,95603166884636,94922130551805,134530128383903,97824616490448,110211186840347,114191137265065},
        {"Wicked Popular",92072849924640,72301599441680,104325245285198,121152442762481,113199415118199,99384245425157,131326830509784,118832222982049,76049494037641},
        {"Elder",10921111375,10921104374,10921107367,10921105765,10921110146,10921108971,10921100400,10921101664,10921102574},
        {"Zombie",10921355261,616163682,10921351278,10921350320,10921353442,10921352344,10921343576,10921344533,10921345304},
        {"Mage",10921152678,10921148209,10921149743,10921148939,10921151661,10921150788,10921143404,10921144709,10921145797},
        {"Catwalk Glam",109168724482748,81024476153754,116936326516985,92294537340807,98854111361360,134591743181628,119377220967554,133806214992291,94970088341563},
        {"Astronaut",10921046031,10921039308,10921042494,10921040576,10921045006,10921044000,10921032124,10921034824,10921036806},
        {"Wicked Dancing Through Life",73718308412641,135515454877967,78508480717326,78147885297412,129183123083281,110657013921774,129447497744818,92849173543269,132238900951109},
        {"Werewolf",10921342074,10921336997,nil,10921337907,10921341319,10921340419,10921329322,10921330408,10921333667},
        {"Superhero",10921298616,10921291831,10921294559,10921293373,10921297391,10921295495,10921286911,10921288909,10921290167},
        {"Toy",10921312010,10921306285,10921308158,10921307241,10921310341,10921309319,10921300839,10921301576,nil},
        {"No Boundaries",18747074203,18747070484,18747069148,18747062535,18747071682,18747073181,18747060903,18747067405,18747063918},
        {"NFL",110358958299415,117333533048078,119846112151352,129773241032,79090109939093,132697394189921,134630013742019,92080889861410,74451233229259},
        {"Amazon Unboxed",90478085024465,134824450619865,121454505477205,94788218468396,129126268464847,105962919001086,121145883950231,98281136301627,nil},
        {"Vampire",10921326949,10921320299,10921322186,10921321317,10921325443,10921324408,10921314188,10921315373,nil},
        {"Ninja",656121766,656118852,656117878,656115606,656121397,656119721,656114359,656117400,656118341},
        {"Robot",616095330,616091570,616090535,616087089,616094091,616092998,616086039,616088211,616089559},
        {"Levitation",616013216,616010382,616008936,616005863,616012453,616011509,616003713,616006778,616008087},
        {"Stylish",616146177,616140816,616139451,616134815,616144772,616143378,616133594,616136790,616138447},
        {"Bubbly",910034870,910025107,910016857,910001910,910030921,910028158,909997997,910004836,910009958},
        {"Cartoon",742640026,742638842,742637942,742637151,742639812,742639220,742636889,742637544,742638445},
    },
    Index = 0, Current = "Off", Enabled = false, Original = {},
}

function Anim.set(folder, name, id)
    local object = folder and folder:FindFirstChild(name)
    if object and id then object.AnimationId = "rbxassetid://" .. tostring(id) end
end

function Anim.capture()
    if next(Anim.Original) then return end
    local character = LP.Character
    local animate = character and character:FindFirstChild("Animate")
    if not animate then return end
    for _, info in ipairs({
        {"run","RunAnim"},{"walk","WalkAnim"},{"jump","JumpAnim"},
        {"fall","FallAnim"},{"swimidle","SwimIdle"},{"swim","Swim"},
        {"climb","ClimbAnim"},{"idle","Animation1"},{"idle","Animation2"},
    }) do
        local folder = animate:FindFirstChild(info[1])
        local object = folder and folder:FindFirstChild(info[2])
        if object and object:IsA("Animation") then
            Anim.Original[info[1] .. "/" .. info[2]] = object.AnimationId
        end
    end
end

function Anim.apply(pack)
    local character = LP.Character
    local animate = character and character:FindFirstChild("Animate")
    if not animate or not pack then return false end
    Anim.capture()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop(0) end)
        end
    end
    local folders = {
        {"walk","WalkAnim",pack[2]}, {"run","RunAnim",pack[3]},
        {"jump","JumpAnim",pack[4]}, {"fall","FallAnim",pack[5]},
        {"swimidle","SwimIdle",pack[6]}, {"swim","Swim",pack[7]},
        {"climb","ClimbAnim",pack[8]}, {"idle","Animation1",pack[9]},
        {"idle","Animation2",pack[10] or pack[9]},
    }
    for _, item in ipairs(folders) do
        Anim.set(animate:FindFirstChild(item[1]), item[2], item[3])
    end
    animate.Disabled = true
    task.wait(0.06)
    animate.Disabled = false
    Anim.Index = table.find(Anim.Packs, pack) or Anim.Index
    Anim.Current, Anim.Enabled = pack[1], true
    State.animationPack = pack[1]
    scheduleAutoSave()
    return true
end

function Anim.off()
    local character = LP.Character
    local animate = character and character:FindFirstChild("Animate")
    if not animate then return false end
    for key, id in pairs(Anim.Original) do
        local folderName, objectName = key:match("([^/]+)/(.+)")
        local object = animate:FindFirstChild(folderName)
            and animate[folderName]:FindFirstChild(objectName)
        if object and object:IsA("Animation") then object.AnimationId = id end
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop(0) end)
        end
    end
    animate.Disabled = true
    task.wait(0.06)
    animate.Disabled = false
    Anim.Enabled, Anim.Current = false, "Off"
    State.animationPack = "Off"
    scheduleAutoSave()
    return true
end

function Anim.next()
    if not Anim.Enabled then
        Anim.Index = 1
        Anim.apply(Anim.Packs[Anim.Index])
        return Anim.Packs[Anim.Index][1]
    end
    if Anim.Index < #Anim.Packs then
        Anim.Index = Anim.Index + 1
        Anim.apply(Anim.Packs[Anim.Index])
        return Anim.Packs[Anim.Index][1]
    end
    Anim.off()
    return "Off"
end

LP.CharacterAdded:Connect(function(character)
    Outfit.Captured, Outfit.CurrentCharacter = false, nil
    table.clear(Anim.Original)
    Anim.Enabled, Anim.Current = false, "Off"
    task.wait(0.8)
    if State.outfit and State.outfit ~= "Off" then Outfit.set(State.outfit) end
    if State.animationPack and State.animationPack ~= "Off" then
        for _, pack in ipairs(Anim.Packs) do
            if pack[1] == State.animationPack then Anim.apply(pack); break end
        end
    end
end)


function isCarryingBrainrot(char)
    if not char then return false end

    local ok, stealing = pcall(function()
        return LP:GetAttribute("Stealing")
    end)
    if ok and stealing == true then return true end

    local okChar, charStealing = pcall(function()
        return char:GetAttribute("Stealing")
    end)
    if okChar and charStealing == true then return true end

    for _, name in ipairs({"Carrying", "IsCarrying", "Grabbed", "Holding", "StealHold", "HasGrab"}) do
        local value = char:FindFirstChild(name, true)
        if value then
            if value:IsA("BoolValue") and value.Value then return true end
            if value:IsA("ObjectValue") and value.Value then return true end
            if value:IsA("StringValue") and value.Value ~= "" then return true end
        end
    end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChildWhichIsA("BasePart", true) then
            local name = child.Name:lower()
            if name:find("brainrot", 1, true) or name:find("animal", 1, true) then
                return true
            end
        elseif child:IsA("Tool") then
            local name = child.Name:lower()
            if name:find("brainrot", 1, true) or name:find("animal", 1, true) then
                return true
            end
        end
    end

    return false
end

function getCurrentSpeed()
    local isCarry = State.speedToggled
    if State.autoCarryEnabled and not isCarry then
        isCarry = isCarryingBrainrot(LP.Character)
    end

    if isCarry then
        return State.laggerModeEnabled and State.laggerCarrySpeed or State.carrySpeed
    else
        return State.laggerModeEnabled and State.laggerNormalSpeed or State.normalSpeed
    end
end


local bodyLockConnection = nil
local bodyLockRadius = 60
local prevAutoRotate = nil

function getBodyLockNearestPlayer()
    local character = LP.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest = nil
    local shortest = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (targetRoot.Position - root.Position).Magnitude
                if distance <= bodyLockRadius and distance < shortest then
                    shortest = distance
                    nearest = player
                end
            end
        end
    end

    return nearest
end

function stopBodyLock()
    State.bodyLockEnabled = false

    if bodyLockConnection then
        bodyLockConnection:Disconnect()
        bodyLockConnection = nil
    end

    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid then
        humanoid.AutoRotate = (prevAutoRotate == nil) and true or prevAutoRotate
    end
    if root then
        root.AssemblyAngularVelocity = Vector3.zero
    end

    prevAutoRotate = nil
end

function startBodyLock()
    if bodyLockConnection then return end
    State.bodyLockEnabled = true

    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and prevAutoRotate == nil then
        prevAutoRotate = humanoid.AutoRotate
    end
    if humanoid then
        humanoid.AutoRotate = false
    end

    bodyLockConnection = RunService.Heartbeat:Connect(function()
        if not State.bodyLockEnabled then return end

        local currentCharacter = LP.Character
        local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        local currentHumanoid = currentCharacter
            and currentCharacter:FindFirstChildOfClass("Humanoid")

        if not root or not currentHumanoid or currentHumanoid.Health <= 0 then
            return
        end

        local target = getBodyLockNearestPlayer()
        if target and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local targetPosition = targetRoot.Position
                local myPosition = root.Position
                local offset = Vector3.new(
                    targetPosition.X,
                    myPosition.Y,
                    targetPosition.Z
                ) - myPosition

                if offset.Magnitude > 0.1 then
                    currentHumanoid.AutoRotate = false
                    local lookDirection = offset.Unit
                    local currentDirection = root.CFrame.LookVector
                    local cross = currentDirection:Cross(lookDirection)
                    local currentVelocity = root.AssemblyAngularVelocity

                    root.AssemblyAngularVelocity = Vector3.new(
                        currentVelocity.X,
                        cross.Y * 40,
                        currentVelocity.Z
                    )
                end
            end
        else
            currentHumanoid.AutoRotate = true
        end
    end)
end

function setBodyLock(enabled)
    if enabled then
        startBodyLock()
    else
        stopBodyLock()
    end
    scheduleAutoSave()
end

LP.CharacterAdded:Connect(function()
    if State.bodyLockEnabled then
        task.wait(0.5)
        startBodyLock()
    end
end)

if State.bodyLockEnabled then
    startBodyLock()
end


local velocityConns = {}

local function setupVelocitySpoof()
    for _, connection in ipairs(velocityConns) do
        pcall(function() connection:Disconnect() end)
    end
    velocityConns = {}

    local character = LP.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not getrawmetatable or not setreadonly or not newcclosure or not checkcaller then return end

    local ok = pcall(function()
        local metatable = getrawmetatable(root)
        if not metatable then return end

        setreadonly(metatable, false)
        local oldIndex = metatable.__index
        local oldNewIndex = metatable.__newindex

        metatable.__index = newcclosure(function(self, key)
            if not checkcaller()
                and (key == "AssemblyLinearVelocity" or key == "Velocity")
                and self == root then
                return spoofedVelocity
            end
            return oldIndex(self, key)
        end)

        metatable.__newindex = newcclosure(function(self, key, value)
            if not checkcaller()
                and (key == "AssemblyLinearVelocity" or key == "Velocity")
                and self == root then
                spoofedVelocity = value
                return
            end
            return oldNewIndex(self, key, value)
        end)

        local connection = RunService.PreSimulation:Connect(function()
            if State.tpInProgress or State.autoBatToggled then return end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return end

            pcall(function()
                root:SetNetworkOwner(LP)
            end)

            local speed = math.clamp(getCurrentSpeed(), 0, 10000)
            local direction = humanoid.MoveDirection
            if direction.Magnitude > 0.05 then
                local unit = direction.Unit
                spoofedVelocity = Vector3.new(
                    unit.X * 16,
                    root.AssemblyLinearVelocity.Y,
                    unit.Z * 16
                )
                root.AssemblyLinearVelocity = Vector3.new(
                    unit.X * speed,
                    root.AssemblyLinearVelocity.Y,
                    unit.Z * speed
                )
            else
                spoofedVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end)
        table.insert(velocityConns, connection)
    end)

    if not ok then
        velocityConns = {}
    end
end

pcall(setupVelocitySpoof)
LP.CharacterAdded:Connect(function()
    task.wait()
    pcall(setupVelocitySpoof)
end)


local stretchConnection = nil
local originalCFrame = nil

function applyStretchRes()
    if stretchConnection then return end
    local Camera = workspace.CurrentCamera
    originalCFrame = Camera.CFrame
    stretchConnection = RunService.RenderStepped:Connect(function()
        if State.stretchResEnabled then
            local Camera = workspace.CurrentCamera
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.65, 0, 0, 0, 1)
        end
    end)
end

function stopStretchRes()
    if stretchConnection then stretchConnection:Disconnect(); stretchConnection = nil end
    local Camera = workspace.CurrentCamera
    if originalCFrame then Camera.CFrame = originalCFrame; originalCFrame = nil end
end

function setStretchRes(enabled)
    State.stretchResEnabled = enabled
    if enabled then applyStretchRes() else stopStretchRes() end
    scheduleAutoSave()
    if GuiToggleSetters["stretchRes"] then GuiToggleSetters["stretchRes"](enabled) end
end


local BG_IMAGES = {
    [1] = "76835310118322",
    [2] = "114138477258742",
    [3] = "128490869357075",
    [4] = "114608427279807",
    [5] = "115887697595024",
}

function syncV2Background(index)
    local imageId = BG_IMAGES[index]
    for _, image in ipairs({
        SpaceHubV2BackgroundImage,
        SpaceHubV2TabBackgroundImage,
    }) do
        if image and image.Parent then
            image.Visible = imageId ~= nil
            if imageId then
                image.Image = "rbxassetid://" .. tostring(imageId)
            end
        end
    end
    if SpaceHubV3BackgroundImage and SpaceHubV3BackgroundImage.Parent then
        SpaceHubV3BackgroundImage.Visible = imageId ~= nil
        if imageId then
            SpaceHubV3BackgroundImage.Image = "rbxassetid://" .. tostring(imageId)
        end
    end
    if SpaceHubV3HeaderBackgroundImage and SpaceHubV3HeaderBackgroundImage.Parent then
        SpaceHubV3HeaderBackgroundImage.Visible = imageId ~= nil
        if imageId then
            SpaceHubV3HeaderBackgroundImage.Image = "rbxassetid://" .. tostring(imageId)
        end
    end
end

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled


function getRealVelocity(player)
    if not player.Character then return Vector3.zero end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return Vector3.zero end
    local now = tick()
    if not playerVelocityHistory[player] then playerVelocityHistory[player] = {} end
    local history = playerVelocityHistory[player]
    table.insert(history, {pos = root.Position, time = now})
    while #history > 10 do table.remove(history, 1) end
    if #history < 3 then return root.AssemblyLinearVelocity end
    local totalVel = Vector3.zero
    local validSamples = 0
    for i = #history, 2, -1 do
        local dt = history[i].time - history[i-1].time
        if dt > 0 and dt < 0.2 then
            local vel = (history[i].pos - history[i-1].pos) / dt
            if vel.Magnitude < 250 then totalVel = totalVel + vel; validSamples = validSamples + 1 end
        end
    end
    if validSamples > 0 then return totalVel / validSamples end
    return root.AssemblyLinearVelocity
end


local autoBatEnabled = false
local autoBatTarget = nil
local autoBatLastPos = nil
local autoBatVelocity = Vector3.zero
local autoBatNextScan = 0
local autoBatNextEquip = 0
local autoBatConn = nil

function getNearest()
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (root.Position - r.Position).Magnitude
                if d < bestDist then bestDist = d; best = p end
            end
        end
    end
    return best
end

function equipBat()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bat = char:FindFirstChild("Bat")
    if bat and bat:IsA("Tool") then return bat end
    local bp = LP:FindFirstChild("Backpack")
    bat = bp and bp:FindFirstChild("Bat")
    if bat then pcall(function() hum:EquipTool(bat) end) end
end

function solveIntercept(myPos, tPos, tVel, speed)
    local off = tPos - myPos
    local a = tVel:Dot(tVel) - speed*speed
    local b = 2*tVel:Dot(off)
    local c = off:Dot(off)
    local t = 0
    if math.abs(a) < 1e-6 then
        t = math.abs(b) > 1e-6 and (-c/b) or 0
    else
        local disc = b*b - 4*a*c
        if disc < 0 then return tPos end
        local sq = math.sqrt(disc)
        local t1, t2 = (-b-sq)/(2*a), (-b+sq)/(2*a)
        if t1 > 0 and t2 > 0 then t = math.min(t1, t2) else t = math.max(t1, t2) end
    end
    return tPos + tVel * math.max(0, t)
end

function startAutoBatHook()
    if autoBatConn then return end
    disableNormalMovementVelocity()
    autoBatTarget = nil
    autoBatLastPos = nil
    autoBatVelocity = Vector3.zero

    autoBatConn = RunService.Heartbeat:Connect(function(dt)
        if not autoBatEnabled then return end

        local now = os.clock()
        if now >= autoBatNextEquip then
            autoBatNextEquip = now + 0.4
            equipBat()
        end

        local currentTargetRoot = autoBatTarget
            and autoBatTarget.Character
            and autoBatTarget.Character:FindFirstChild("HumanoidRootPart")
        local currentTargetHum = autoBatTarget
            and autoBatTarget.Character
            and autoBatTarget.Character:FindFirstChildOfClass("Humanoid")
        local targetInvalid = not currentTargetRoot
            or currentTargetHum.Health <= 0
            or (currentTargetRoot.Position - (LP.Character
                and LP.Character:FindFirstChild("HumanoidRootPart")
                and LP.Character.HumanoidRootPart.Position
                or currentTargetRoot.Position)).Magnitude > 80
        if targetInvalid or (not autoBatTarget and now >= autoBatNextScan) then
            autoBatTarget = getNearest()
            autoBatNextScan = now + 1/15
        end

        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        local tRoot = autoBatTarget and autoBatTarget.Character and autoBatTarget.Character:FindFirstChild("HumanoidRootPart")
        local tHum = autoBatTarget and autoBatTarget.Character and autoBatTarget.Character:FindFirstChildOfClass("Humanoid")

        if not tRoot or not tHum or tHum.Health <= 0 then
            hum.PlatformStand = false
            hum.AutoRotate = true
            return
        end

        local tPos = tRoot.Position + Vector3.new(0, 3, 0)
        local myPos = root.Position

        
        if autoBatLastPos and dt > 0.001 then
            local step = tPos - autoBatLastPos
            if step.Magnitude <= 80 then autoBatVelocity = step / dt end
        end
        autoBatLastPos = tPos
        if autoBatVelocity.Magnitude > 120 then autoBatVelocity = Vector3.zero end
        autoBatVelocity = autoBatVelocity:Lerp(Vector3.zero, math.clamp(dt * 3, 0, 1))

        
        local speed = 58
        local aim = tPos
        for _ = 1, 4 do aim = solveIntercept(myPos, tPos, autoBatVelocity, speed) end
        if (aim - tPos).Magnitude > 250 then aim = tPos + (aim - tPos).Unit * 250 end

        local manualVelocity = getAutoBatManualHorizontalVelocity(hum, speed)
        local horizontalVelocity = blendAutoBatHorizontalVelocity(
            myPos,
            aim,
            manualVelocity,
            speed,
        )
        local desiredHeight = tPos.Y
        local yVelocity = (desiredHeight - myPos.Y) * 14 + autoBatVelocity.Y * 0.5
        if hum.Jump then yVelocity = math.max(yVelocity, 42) end
        if hum.FloorMaterial ~= Enum.Material.Air then
            yVelocity = math.max(yVelocity, 13)
        end
        yVelocity = math.clamp(yVelocity, -55, 65)
        local move = Vector3.new(horizontalVelocity.X, yVelocity, horizontalVelocity.Z)

        
        
        
        hum.PlatformStand = false
        hum.AutoRotate = false
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(move, 0.75)

        
        local look = (tRoot.Position - myPos) * Vector3.new(1,0,1)
        if look.Magnitude > 0.1 then
            local cur = root.CFrame.LookVector * Vector3.new(1,0,1)
            if cur.Magnitude > 0.001 then
                local axis = cur.Unit:Cross(look.Unit)
                local angle = math.asin(math.clamp(axis.Magnitude, -1, 1))
                if axis.Magnitude > 0.01 then
                    root.AssemblyAngularVelocity = axis.Unit * angle * 80
                end
            end
        end

        
        if autoSwingEnabled then
            local bat = char:FindFirstChild("Bat")
            if bat and bat:IsA("Tool") then
                pcall(function() bat:Activate() end)
            end
        end
    end)
end

function stopAutoBatHook()
    if autoBatConn then autoBatConn:Disconnect(); autoBatConn = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
        end
    end
    autoBatTarget = nil
    autoBatLastPos = nil
    autoBatVelocity = Vector3.zero
end

function toggleAutoBatHook()
    autoBatEnabled = not autoBatEnabled
    if autoBatEnabled then startAutoBatHook() else stopAutoBatHook() end
    scheduleAutoSave()
    if GuiToggleSetters["autoBat"] then GuiToggleSetters["autoBat"](autoBatEnabled) end
end

function setAutoBatState(enabled)
    autoBatEnabled = enabled
    State.autoBatToggled = enabled
    if autoBatEnabled then startAutoBatHook() else stopAutoBatHook() end
    scheduleAutoSave()
    if GuiToggleSetters["autoBat"] then GuiToggleSetters["autoBat"](enabled) end
end


function setAutoBatVersion(version)
    if version ~= "V1" and version ~= "V2" then return end
    if State.autoBatVersion == version then return end

    local wasEnabled = autoBatEnabled or State.autoBatToggled or State.autoBatV2Enabled
    if wasEnabled then
        setAutoBatState(false)
    end
    if State.autoBatV2Enabled then
        State.autoBatV2Enabled = false
        stopAutoBatV2()
        if GuiToggleSetters["autoBatV2"] then GuiToggleSetters["autoBatV2"](false) end
    end

    State.autoBatVersion = version
    scheduleAutoSave()

    if wasEnabled then
        if version == "V2" then
            State.autoBatV2Enabled = true
            startAutoBatV2()
        else
            setAutoBatState(true)
        end
    end
    if GuiToggleSetters["autoBatVersion"] then
        GuiToggleSetters["autoBatVersion"](version)
    end
end

function setSelectedAutoBatState(enabled)
    State.autoBatToggled = enabled
    if State.autoBatVersion == "V2" then
        State.autoBatV2Enabled = enabled
        if enabled then startAutoBatV2() else stopAutoBatV2() end
        scheduleAutoSave()
        if GuiToggleSetters["autoBatV2"] then GuiToggleSetters["autoBatV2"](enabled) end
    else
        setAutoBatState(enabled)
    end
end


function tpDown()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local mover = root:FindFirstChild("HorizontalMoveVelocity")
    if mover and mover:IsA("LinearVelocity") then
        mover.Enabled = false
        mover:Destroy()
    end
    local attachment = root:FindFirstChild("HorizontalMoveAttachment")
    if attachment and attachment:IsA("Attachment") then
        attachment:Destroy()
    end
    
    local infMover = root:FindFirstChild("InfJumpVelocity")
    if infMover and infMover:IsA("LinearVelocity") then
        infMover.Enabled = false
        infMover:Destroy()
    end
    local infAttachment = root:FindFirstChild("InfJumpAttachment")
    if infAttachment and infAttachment:IsA("Attachment") then
        infAttachment:Destroy()
    end
    
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    
    local pos = root.Position
    root.CFrame = CFrame.new(pos.X, -6.84, pos.Z)
    
    task.wait(0.05)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    
    task.wait(0.05)
    local infMover2 = root:FindFirstChild("InfJumpVelocity")
    if infMover2 and infMover2:IsA("LinearVelocity") then
        infMover2.Enabled = false
        infMover2:Destroy()
    end
    local mover2 = root:FindFirstChild("HorizontalMoveVelocity")
    if mover2 and mover2:IsA("LinearVelocity") then
        mover2.Enabled = false
        mover2:Destroy()
    end
    
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end


function applyLavenderDreamSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name == "CustomSky" or v.Name == "CustomBloom" or v.Name == "CustomCC" or v.Name == "CustomAtmo" or v.Name == "CustomClouds" then v:Destroy() end
    end
    Lighting.Technology = Enum.Technology.Future
    Lighting.Brightness = 2.6
    Lighting.ExposureCompensation = 0.02
    Lighting.Ambient = Color3.fromRGB(180, 160, 220)
    Lighting.OutdoorAmbient = Color3.fromRGB(190, 170, 230)
    Lighting.ClockTime = 18.5
    local sky = Instance.new("Sky"); sky.Name = "CustomSky"
    sky.SkyboxBk = "rbxassetid://9994573642"; sky.SkyboxDn = "rbxassetid://9994573642"
    sky.SkyboxFt = "rbxassetid://9994573642"; sky.SkyboxLf = "rbxassetid://9994573642"
    sky.SkyboxRt = "rbxassetid://9994573642"; sky.SkyboxUp = "rbxassetid://9994573642"
    sky.StarCount = 800; sky.MoonAngularSize = 16; sky.MoonTextureId = "rbxasset://sky/moon.jpg"; sky.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "CustomBloom"
    bloom.Intensity = 0.3; bloom.Size = 35; bloom.Threshold = 0.8; bloom.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "CustomCC"
    cc.Brightness = 0.02; cc.Contrast = 0.05; cc.Saturation = 0.15; cc.TintColor = Color3.fromRGB(200, 160, 255); cc.Parent = Lighting
    local atmo = Instance.new("Atmosphere"); atmo.Name = "CustomAtmo"
    atmo.Density = 0.4; atmo.Offset = 0.08; atmo.Color = Color3.fromRGB(200, 160, 255)
    atmo.Decay = Color3.fromRGB(160, 120, 220); atmo.Glare = 1.4; atmo.Haze = 1.8; atmo.Parent = Lighting
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local clouds = Instance.new("Clouds")
        clouds.Name = "CustomClouds"
        clouds.Cover = 0.55; clouds.Density = 0.5; clouds.Color = Color3.fromRGB(220, 200, 255); clouds.Parent = terrain
    end
end


local infJumpEnabled = false
local isJumping = false
local infJumpConnection = nil
local humanoid = nil
local jumpCount = 0
local lastJumpTime = 0
local jumpCooldown = 0.05

local INF_JUMP_VEL_NAME = "InfJumpVelocity"
local INF_JUMP_ATTACH_NAME = "InfJumpAttachment"
local INF_JUMP_MIN_FORCE = 1000000
local INF_JUMP_MAX_FORCE = 50000000

function clearInfJumpVelocity(root)
    if not root then return end
    local mover = root:FindFirstChild(INF_JUMP_VEL_NAME)
    if mover and mover:IsA("LinearVelocity") then mover:Destroy() end
    local attachment = root:FindFirstChild(INF_JUMP_ATTACH_NAME)
    if attachment and attachment:IsA("Attachment") then attachment:Destroy() end
end

function startInfJumpLoop()
    if infJumpConnection then return end
    infJumpConnection = RunService.Heartbeat:Connect(function()
        if not State.infJumpEnabled then return end
        
        local char = LP.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        if hum.Jump or isJumping then
            local attachment = root:FindFirstChild(INF_JUMP_ATTACH_NAME)
            if not attachment or not attachment:IsA("Attachment") then
                if attachment then attachment:Destroy() end
                attachment = Instance.new("Attachment")
                attachment.Name = INF_JUMP_ATTACH_NAME
                attachment.Parent = root
            end

            local mover = root:FindFirstChild(INF_JUMP_VEL_NAME)
            if not mover or not mover:IsA("LinearVelocity") then
                if mover then mover:Destroy() end
                mover = Instance.new("LinearVelocity")
                mover.Name = INF_JUMP_VEL_NAME
                mover.Attachment0 = attachment
                mover.RelativeTo = Enum.ActuatorRelativeTo.World
                mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
                mover.ForceLimitsEnabled = true
                mover.ForceLimitMode = Enum.ForceLimitMode.PerAxis
                mover.Parent = root
            end

            local currentVel = root.Velocity
            local targetY = 52
            
            local mass = root.AssemblyMass or 1
            local force = math.clamp(mass * 20000, INF_JUMP_MIN_FORCE, INF_JUMP_MAX_FORCE)
            
            if currentVel.Y < targetY then
                mover.MaxAxesForce = Vector3.new(0, force, 0)
                mover.VectorVelocity = Vector3.new(0, targetY, 0)
                mover.Enabled = true
            else
                mover.Enabled = false
            end
        else
            local mover = root:FindFirstChild(INF_JUMP_VEL_NAME)
            if mover and mover:IsA("LinearVelocity") then
                mover.Enabled = false
            end
        end
    end)
end

function stopInfJumpLoop()
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            clearInfJumpVelocity(root)
        end
    end
end

function onJumpDetected()
    if State.infJumpEnabled then
        local now = tick()
        if now - lastJumpTime > jumpCooldown then
            isJumping = true
            jumpCount = jumpCount + 1
            lastJumpTime = now
            
            task.delay(2, function()
                if tick() - lastJumpTime > 1.5 then
                    jumpCount = 0
                end
            end)
            
            if jumpCount > 8 then
                task.wait(0.15)
            end
            
            task.wait(0.05)
            isJumping = false
        end
    end
end

function setupJumpDetection()
    local char = LP.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Jumping:Connect(onJumpDetected)
        humanoid = hum
    end
end

function setInfJumpInternal(on)
    State.infJumpEnabled = on
    if on then
        jumpCount = 0
        startInfJumpLoop()
        setupJumpDetection()
    else
        stopInfJumpLoop()
    end
    scheduleAutoSave()
end


LP.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Jumping:Connect(onJumpDetected)
        humanoid = hum
    end
    if State.infJumpEnabled then
        jumpCount = 0
        startInfJumpLoop()
    end
    if State.unwalkEnabled then
        task.wait(0.3)
        startUnwalk()
    end
end)

setupJumpDetection()


local MEDUSA_COOLDOWN = 25
local Conns = { antiRag = {}, anchor = {}, batCounter = {} }
local setupMedusaCounter, stopMedusaCounter
do
    local function findMedusa()
        local char = LP.Character
        if not char then return nil end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then return tool end
            end
        end
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local n = tool.Name:lower()
                    if n:find("medusa") or n:find("head") or n:find("stone") then return tool end
                end
            end
        end
        return nil
    end
    local function useMedusaCounter()
        if State.medusaDebounce then return end
        if tick() - State.medusaLastUsed < MEDUSA_COOLDOWN then return end
        local char = LP.Character
        if not char then return end
        State.medusaDebounce = true
        local med = findMedusa()
        if med then
            if med.Parent ~= char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(med) end
            end
            pcall(function() med:Activate() end)
            State.medusaLastUsed = tick()
        end
        State.medusaDebounce = false
    end
    local function onAnchorChanged(part)
        return part:GetPropertyChangedSignal("Anchored"):Connect(function()
            if part.Anchored and part.Transparency == 1 then useMedusaCounter() end
        end)
    end
    function stopMedusaCounter()
        for _, c in ipairs(Conns.anchor) do pcall(function() c:Disconnect() end) end
        Conns.anchor = {}
    end
    function setupMedusaCounter(char)
        stopMedusaCounter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
        end
        table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
        end))
    end
end


local BAT_COUNTER_SLAP_LIST = {
    "Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap",
    "Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap",
    "Galaxy Slap","Glitched Slap"
}

function findBatForCounter()
    local c = LP.Character
    if not c then return nil end
    local bp = LP:FindFirstChild("Backpack")
    for _, name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t and t:IsA("Tool") then return t end
    end
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    return nil
end

function startBatCounter()
    if Conns.batCounter then return end
    Conns.batCounter = RunService.Heartbeat:Connect(function()
        if not State.batCounterEnabled then return end
        if State.batCounterDebounce then return end
        local char = LP.Character
        if not char then return end
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        local st = hum2:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            State.batCounterDebounce = true
            task.spawn(function()
                local bat = findBatForCounter()
                if bat then
                    local hum3 = char:FindFirstChildOfClass("Humanoid")
                    if bat.Parent ~= char then
                        if hum3 then pcall(function() hum3:EquipTool(bat) end) end
                        task.wait(0.05)
                    end
                    local remote = bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
                    if remote and remote:IsA("RemoteEvent") then
                        pcall(function() remote:FireServer() end)
                        task.wait(0.15)
                        pcall(function() remote:FireServer() end)
                    else
                        pcall(function() bat:Activate() end)
                        task.wait(0.15)
                        pcall(function() bat:Activate() end)
                    end
                end
                task.wait(0.5)
                State.batCounterDebounce = false
            end)
        end
    end)
end

function stopBatCounter()
    if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter = nil end
    State.batCounterDebounce = false
end


local DROP_ASCEND_HEIGHT = 7
local DROP_ASCEND_DURATION = 0.25
local DROP_ASCEND_SPEED = 200
local DROP_VELOCITY_NAME = "DropBrainrotVelocity"
local DROP_ATTACHMENT_NAME = "DropBrainrotAttachment"
local dropBrainrotConnection = nil
local dropCollisionConnection = nil

local function disableDropPlayerCollisions()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end

local function setDropVerticalVelocity(root, velocity)
    if not root or not root.Parent then return false end

    local attachment = root:FindFirstChild(DROP_ATTACHMENT_NAME)
    if not attachment or not attachment:IsA("Attachment") then
        if attachment then attachment:Destroy() end
        attachment = Instance.new("Attachment")
        attachment.Name = DROP_ATTACHMENT_NAME
        attachment.Parent = root
    end

    local mover = root:FindFirstChild(DROP_VELOCITY_NAME)
    if not mover or not mover:IsA("LinearVelocity") then
        if mover then mover:Destroy() end
        mover = Instance.new("LinearVelocity")
        mover.Name = DROP_VELOCITY_NAME
        mover.Attachment0 = attachment
        mover.RelativeTo = Enum.ActuatorRelativeTo.World
        mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        mover.ForceLimitsEnabled = true
        mover.ForceLimitMode = Enum.ForceLimitMode.PerAxis
        mover.MaxAxesForce = Vector3.new(1000000, 1000000, 1000000)
        mover.Parent = root
    end

    mover.MaxAxesForce = Vector3.new(1000000, 1000000, 1000000)
    mover.VectorVelocity = velocity or Vector3.zero
    mover.Enabled = mover.VectorVelocity.Magnitude > 0.001
    return true
end

local function stopDropVerticalVelocity(root)
    if not root then return end
    local mover = root:FindFirstChild(DROP_VELOCITY_NAME)
    if mover and mover:IsA("LinearVelocity") then
        mover.Enabled = false
        mover.VectorVelocity = Vector3.zero
        mover:Destroy()
    end
    local attachment = root:FindFirstChild(DROP_ATTACHMENT_NAME)
    if attachment and attachment:IsA("Attachment") then
        attachment:Destroy()
    end
end

local function dropBrainrotTpDown(char, root)
    if not char or not root or not root.Parent then return end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local filter = { char }
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            table.insert(filter, player.Character)
        end
    end
    params.FilterDescendantsInstances = filter

    local from = root.Position
    local groundY = nil

    
    for _ = 1, 60 do
        local result = workspace:Raycast(from, Vector3.new(0, -2000, 0), params)
        if not result then break end

        local instance = result.Instance
        local characterModel = nil
        local ancestor = instance
        for _ = 1, 6 do
            if not ancestor or ancestor == workspace then break end
            if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
                characterModel = ancestor
                break
            end
            ancestor = ancestor.Parent
        end

        if instance.Transparency >= 0.9 or instance.CanCollide == false or characterModel then
            table.insert(filter, characterModel or instance)
            params.FilterDescendantsInstances = filter
            from = result.Position - Vector3.new(0, 0.2, 0)
        else
            groundY = result.Position.Y
            break
        end
    end

    local targetY = groundY and (groundY + 2.5) or (root.Position.Y - 175)
    local currentVelocity = root.AssemblyLinearVelocity
    root.CFrame = root.CFrame + Vector3.new(0, targetY - root.Position.Y, 0)
    root.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
    root.AssemblyAngularVelocity = Vector3.zero
end

function runDropBrainrot()
    if State.dropBrainrotActive then return end

    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if dropBrainrotConnection then
        dropBrainrotConnection:Disconnect()
        dropBrainrotConnection = nil
    end
    if dropCollisionConnection then
        dropCollisionConnection:Disconnect()
        dropCollisionConnection = nil
    end

    State.dropBrainrotActive = true
    State.tpInProgress = true

    
    disableDropPlayerCollisions()
    local collisionElapsed = 0
    dropCollisionConnection = RunService.Stepped:Connect(function(_, deltaTime)
        if not State.dropBrainrotActive then return end
        collisionElapsed = collisionElapsed + (deltaTime or 0)
        if collisionElapsed >= 0.05 then
            collisionElapsed = 0
            disableDropPlayerCollisions()
        end
    end)

    
    local horizontalMover = root:FindFirstChild(VELOCITY_NAME)
    if horizontalMover and horizontalMover:IsA("LinearVelocity") then
        horizontalMover.Enabled = false
    end

    local targetY = root.Position.Y + DROP_ASCEND_HEIGHT
    local startedAt = tick()
    dropBrainrotConnection = RunService.Heartbeat:Connect(function()
        local currentRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not currentRoot or not currentRoot.Parent then
            if dropBrainrotConnection then
                dropBrainrotConnection:Disconnect()
                dropBrainrotConnection = nil
            end
            if dropCollisionConnection then
                dropCollisionConnection:Disconnect()
                dropCollisionConnection = nil
            end
            State.dropBrainrotActive = false
            State.tpInProgress = false
            return
        end

        if tick() - startedAt >= DROP_ASCEND_DURATION then
            dropBrainrotConnection:Disconnect()
            dropBrainrotConnection = nil
            if dropCollisionConnection then
                dropCollisionConnection:Disconnect()
                dropCollisionConnection = nil
            end

            stopDropVerticalVelocity(currentRoot)
            currentRoot.AssemblyLinearVelocity = Vector3.zero
            State.dropBrainrotActive = false
            State.tpInProgress = false

            dropBrainrotTpDown(char, currentRoot)
            return
        end

        local remaining = targetY - currentRoot.Position.Y
        if remaining > 0.6 then
            setDropVerticalVelocity(currentRoot, Vector3.new(0, DROP_ASCEND_SPEED, 0))
        else
            stopDropVerticalVelocity(currentRoot)
        end
    end)
end


local AntiRagdoll = {
    Enabled = false,
    Connection = nil,
    ResetCooldown = 0,
}

function startAntiRagdoll()
    if AntiRagdoll.Connection then AntiRagdoll.Connection:Disconnect(); AntiRagdoll.Connection = nil end
    AntiRagdoll.Connection = RunService.Heartbeat:Connect(function()
        if not AntiRagdoll.Enabled then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.Health <= 0 then return end
        local state = hum:GetState()
        local now = tick()
        if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
            if now - AntiRagdoll.ResetCooldown > 0.15 then
                AntiRagdoll.ResetCooldown = now
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    root.Velocity = Vector3.zero
                    root.RotVelocity = Vector3.zero
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    for _, obj in ipairs(char:GetDescendants()) do
                        if obj:IsA("Motor6D") then obj.Enabled = true end
                    end
                    for _, obj in ipairs(char:GetDescendants()) do
                        if obj:IsA("Constraint") then obj.Enabled = true end
                    end
                    workspace.CurrentCamera.CameraSubject = hum
                    local PM = LP.PlayerScripts:FindFirstChild("PlayerModule")
                    if PM then
                        local CM = require(PM:FindFirstChild("ControlModule"))
                        if CM then CM:Enable() end
                    end
                    hum.AutoRotate = true
                    hum.PlatformStand = false
                    hum.Sit = false
                end)
            end
        end
    end)
end

function stopAntiRagdoll()
    if AntiRagdoll.Connection then AntiRagdoll.Connection:Disconnect(); AntiRagdoll.Connection = nil end
    AntiRagdoll.Enabled = false
end


do
    local AntiDie = {
        Enabled = false,
        Character = LP.Character,
        HealthConnection = nil,
        DiedConnection = nil,
    }

    local function disconnectConnections()
        if AntiDie.HealthConnection then
            AntiDie.HealthConnection:Disconnect()
            AntiDie.HealthConnection = nil
        end
        if AntiDie.DiedConnection then
            AntiDie.DiedConnection:Disconnect()
            AntiDie.DiedConnection = nil
        end
    end

    local function enableAntiDie()
        AntiDie.Enabled = true
        State.antiDieEnabled = true
        AntiDie.Character = LP.Character

        local character = AntiDie.Character
        if not character then return end

        if not character:FindFirstChild("AntiDieFF") then
            local forceField = Instance.new("ForceField")
            forceField.Name = "AntiDieFF"
            forceField.Visible = false
            forceField.Parent = character
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        disconnectConnections()

        AntiDie.HealthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if AntiDie.Enabled and humanoid.Health < 1 then
                humanoid.Health = math.max(humanoid.MaxHealth, 1)
            end
        end)

        AntiDie.DiedConnection = humanoid.Died:Connect(function()
            task.spawn(function()
                pcall(function()
                    local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
                    if currentHumanoid then
                        currentHumanoid.Health = currentHumanoid.MaxHealth
                    end
                end)
            end)
        end)
    end

    local function disableAntiDie()
        AntiDie.Enabled = false
        State.antiDieEnabled = false
        disconnectConnections()

        local character = AntiDie.Character or LP.Character
        if character then
            local forceField = character:FindFirstChild("AntiDieFF")
            if forceField then forceField:Destroy() end
        end
    end

    State.setAntiDie = function(enabled)
        if enabled then
            enableAntiDie()
        else
            disableAntiDie()
        end
        scheduleAutoSave()
    end

    LP.CharacterAdded:Connect(function(newCharacter)
        AntiDie.Character = newCharacter
        if AntiDie.Enabled then
            task.spawn(function()
                newCharacter:WaitForChild("Humanoid", 5)
                if AntiDie.Enabled then enableAntiDie() end
            end)
        end
    end)
end


do
local RagdollTimer = {
    Enabled = false,
    Connection = nil,
    CountdownId = 0,
    Active = false,
    WasRagdoll = false,
    Label = nil,
    Gui = nil,
}

function isRagdollState(humanoid)
    if not humanoid then return false end
    local state = humanoid:GetState()
    return humanoid.PlatformStand
        or state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown
end

function hideRagdollTimer()
    if RagdollTimer.Label then
        RagdollTimer.Label.Visible = false
        RagdollTimer.Label.Text = ""
    end
end

function cancelRagdollCountdown()
    RagdollTimer.CountdownId = RagdollTimer.CountdownId + 1
    RagdollTimer.Active = false
    hideRagdollTimer()
end

function startRagdollCountdown()
    if not RagdollTimer.Enabled or RagdollTimer.Active then return end

    RagdollTimer.CountdownId = RagdollTimer.CountdownId + 1
    local countdownId = RagdollTimer.CountdownId
    RagdollTimer.Active = true

    task.spawn(function()
        local label = RagdollTimer.Label
        if not label then
            RagdollTimer.Active = false
            return
        end

        label.Visible = true
        local duration = math.max(1, math.floor(State.ragdollTimerDuration or 3))
        for seconds = duration, 1, -1 do
            if countdownId ~= RagdollTimer.CountdownId or not RagdollTimer.Enabled then
                return
            end

            label.Text = tostring(seconds)
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            task.wait(1)
        end

        if countdownId ~= RagdollTimer.CountdownId or not RagdollTimer.Enabled then
            return
        end

        label.Text = "STEAL"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        task.wait(0.75)

        if countdownId ~= RagdollTimer.CountdownId then return end
        RagdollTimer.Active = false
        hideRagdollTimer()
    end)
end

function startRagdollTimer()
    if RagdollTimer.Connection then return end

    RagdollTimer.Connection = RunService.Heartbeat:Connect(function()
        if not RagdollTimer.Enabled then return end

        local char = LP.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local ragdoll = isRagdollState(humanoid)

        if ragdoll and not RagdollTimer.WasRagdoll then
            startRagdollCountdown()
        end

        RagdollTimer.WasRagdoll = ragdoll
    end)
end

function stopRagdollTimer()
    if RagdollTimer.Connection then
        RagdollTimer.Connection:Disconnect()
        RagdollTimer.Connection = nil
    end

    RagdollTimer.WasRagdoll = false
    cancelRagdollCountdown()
end

State.setRagdollTimer = function(enabled)
    State.ragdollTimerEnabled = enabled
    RagdollTimer.Enabled = enabled

    if enabled then
        startRagdollTimer()
    else
        stopRagdollTimer()
    end

    scheduleAutoSave()
end

State.buildRagdollTimerOverlay = function()
    if RagdollTimer.Gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SpaceHubRagdollTimer"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.Parent = PlayerGui
    RagdollTimer.Gui = gui

    local label = Instance.new("TextLabel")
    label.Name = "Countdown"
    label.Size = UDim2.new(0, 220, 0, 54)
    label.Position = UDim2.new(0.5, -110, 0.3, 0)
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = ""
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 34
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Visible = false
    label.Parent = gui
    RagdollTimer.Label = label
end
end


local performanceConnections = {}

function stripVisuals(obj)
    local function isPlayer(m) return Players:GetPlayerFromCharacter(m) ~= nil end
    local model = obj:FindFirstAncestorOfClass("Model")
    local isPlr = model and isPlayer(model)
    local isLocalChar = model and model == LP.Character
    if isLocalChar then
        if obj:IsA("SpecialMesh") then return end
        if obj:IsA("BasePart") then return end
    end
    if not isPlr and not isLocalChar then
        if obj:IsA("Animator") then
            pcall(function() for _, track in ipairs(obj:GetPlayingAnimationTracks()) do track:Stop(0) end end)
        end
        if obj:IsA("Animation") then pcall(function() obj:Destroy() end); return end
        if obj:IsA("AnimationController") then
            pcall(function()
                local animator = obj:FindFirstChildOfClass("Animator")
                if animator then for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end end
            end)
        end
    end
    if not isPlr then
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Highlight") then
            obj.Enabled = false
        end
        if obj:IsA("Explosion") then pcall(function() obj:Destroy() end) end
        if obj:IsA("MeshPart") then pcall(function() obj.TextureID = "" end) end
    end
    if obj:IsA("BasePart") and not isLocalChar then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
    end
    if obj:IsA("SurfaceAppearance") or obj:IsA("Texture") or obj:IsA("Decal") then
        if not isLocalChar then pcall(function() obj:Destroy() end) end
    end
end

function disableFPSBoost()
    for _, c in ipairs(performanceConnections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect()
        elseif typeof(c) == "thread" then task.cancel(c) end
    end
    table.clear(performanceConnections)
    pcall(function() setfpscap(60) end)
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
end

function applyFPSBoost()
    if not State.fpsBoostEnabled then return end
    disableFPSBoost()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1000000
    Lighting.FogStart = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") then
            pcall(function() v:Destroy() end)
        end
    end
    for _, obj in pairs(workspace:GetDescendants()) do stripVisuals(obj) end
    local conn = workspace.DescendantAdded:Connect(function(obj)
        if State.fpsBoostEnabled then stripVisuals(obj) end
    end)
    table.insert(performanceConnections, conn)
    pcall(function() setfpscap(999999999) end)
end


local skyClockTimeConnection = nil

function removeSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name == "CustomSky" or v.Name == "CustomBloom" or v.Name == "CustomCC" or v.Name == "CustomAtmo" then v:Destroy() end
    end
    if skyClockTimeConnection then skyClockTimeConnection:Disconnect(); skyClockTimeConnection = nil end
    Lighting.Technology = OriginalLighting.Technology
    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.ClockTime = OriginalLighting.ClockTime
    Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
    Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.FogStart = OriginalLighting.FogStart
    Lighting.GlobalShadows = OriginalLighting.GlobalShadows
end

function applyCyberSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name == "CustomSky" or v.Name == "CustomBloom" or v.Name == "CustomCC" or v.Name == "CustomAtmo" then v:Destroy() end
    end
    local currentTime = Lighting.ClockTime
    local isNight = currentTime < 6 or currentTime > 18
    Lighting.Technology = Enum.Technology.Future
    if isNight then
        Lighting.Brightness = 3
        Lighting.ExposureCompensation = 0.05
        Lighting.Ambient = Color3.fromRGB(0, 20, 40)
        Lighting.OutdoorAmbient = Color3.fromRGB(10, 30, 60)
    else
        Lighting.Brightness = 1.5
        Lighting.ExposureCompensation = -0.15
        Lighting.Ambient = Color3.fromRGB(30, 30, 50)
        Lighting.OutdoorAmbient = Color3.fromRGB(40, 40, 70)
    end
    local sky = Instance.new("Sky"); sky.Name = "CustomSky"
    sky.SkyboxBk = "rbxassetid://9994573642"; sky.SkyboxDn = "rbxassetid://9994573642"
    sky.SkyboxFt = "rbxassetid://9994573642"; sky.SkyboxLf = "rbxassetid://9994573642"
    sky.SkyboxRt = "rbxassetid://9994573642"; sky.SkyboxUp = "rbxassetid://9994573642"; sky.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "CustomBloom"
    bloom.Intensity = isNight and 0.35 or 0.15
    bloom.Size = isNight and 36 or 30
    bloom.Threshold = isNight and 0.8 or 0.9
    bloom.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "CustomCC"
    if isNight then
        cc.Brightness = 0.05; cc.Contrast = 0.15; cc.Saturation = 0.2; cc.TintColor = Color3.fromRGB(0, 150, 255)
    else
        cc.Brightness = -0.08; cc.Contrast = 0.05; cc.Saturation = 0.1; cc.TintColor = Color3.fromRGB(0, 100, 200)
    end
    cc.Parent = Lighting
    local atmo = Instance.new("Atmosphere"); atmo.Name = "CustomAtmo"
    if isNight then
        atmo.Density = 0.25; atmo.Offset = 0.1; atmo.Color = Color3.fromRGB(0, 100, 200)
        atmo.Decay = Color3.fromRGB(0, 40, 100); atmo.Glare = 0.3; atmo.Haze = 0.8
    else
        atmo.Density = 0.4; atmo.Offset = 0.15; atmo.Color = Color3.fromRGB(0, 80, 160)
        atmo.Decay = Color3.fromRGB(0, 30, 80); atmo.Glare = 0.1; atmo.Haze = 0.5
    end
    atmo.Parent = Lighting
end

function applySakuraSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name == "CustomSky" or v.Name == "CustomBloom" or v.Name == "CustomCC" or v.Name == "CustomAtmo" then v:Destroy() end
    end
    local currentTime = Lighting.ClockTime
    local isNight = currentTime < 6 or currentTime > 18
    Lighting.Technology = Enum.Technology.Future
    if isNight then
        Lighting.Brightness = 4; Lighting.ExposureCompensation = 0.08
        Lighting.Ambient = Color3.fromRGB(60, 40, 70); Lighting.OutdoorAmbient = Color3.fromRGB(80, 50, 100)
    else
        Lighting.Brightness = 2; Lighting.ExposureCompensation = -0.1
        Lighting.Ambient = Color3.fromRGB(80, 60, 100); Lighting.OutdoorAmbient = Color3.fromRGB(100, 70, 130)
    end
    local sky = Instance.new("Sky"); sky.Name = "CustomSky"
    sky.SkyboxBk = "rbxassetid://10174567842"; sky.SkyboxDn = "rbxassetid://10174567842"
    sky.SkyboxFt = "rbxassetid://10174567842"; sky.SkyboxLf = "rbxassetid://10174567842"
    sky.SkyboxRt = "rbxassetid://10174567842"; sky.SkyboxUp = "rbxassetid://10174567842"; sky.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "CustomBloom"
    bloom.Intensity = isNight and 0.5 or 0.25
    bloom.Size = isNight and 42 or 35
    bloom.Threshold = isNight and 0.7 or 0.85
    bloom.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "CustomCC"
    if isNight then
        cc.Brightness = 0.03; cc.Contrast = 0.1; cc.Saturation = 0.25; cc.TintColor = Color3.fromRGB(255, 150, 200)
    else
        cc.Brightness = -0.05; cc.Contrast = 0.05; cc.Saturation = 0.15; cc.TintColor = Color3.fromRGB(200, 100, 150)
    end
    cc.Parent = Lighting
    local atmo = Instance.new("Atmosphere"); atmo.Name = "CustomAtmo"
    if isNight then
        atmo.Density = 0.3; atmo.Offset = 0.08; atmo.Color = Color3.fromRGB(255, 160, 210)
        atmo.Decay = Color3.fromRGB(140, 60, 100); atmo.Glare = 0.4; atmo.Haze = 1.0
    else
        atmo.Density = 0.45; atmo.Offset = 0.12; atmo.Color = Color3.fromRGB(200, 120, 170)
        atmo.Decay = Color3.fromRGB(100, 40, 80); atmo.Glare = 0.15; atmo.Haze = 0.6
    end
    atmo.Parent = Lighting
end

function applyMoonlightSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name == "CustomSky" or v.Name == "CustomBloom" or v.Name == "CustomCC" or v.Name == "CustomAtmo" then v:Destroy() end
    end
    local currentTime = Lighting.ClockTime
    local isNight = currentTime < 6 or currentTime > 18
    Lighting.Technology = Enum.Technology.Future
    if isNight then
        Lighting.Brightness = 2.2; Lighting.ExposureCompensation = 0.05
        Lighting.Ambient = Color3.fromRGB(120, 60, 110); Lighting.OutdoorAmbient = Color3.fromRGB(140, 70, 120)
    else
        Lighting.Brightness = 2.8; Lighting.ExposureCompensation = 0.02
        Lighting.Ambient = Color3.fromRGB(180, 130, 160); Lighting.OutdoorAmbient = Color3.fromRGB(200, 150, 180)
    end
    local sky = Instance.new("Sky"); sky.Name = "CustomSky"
    sky.SkyboxBk = "rbxassetid://9994573642"; sky.SkyboxDn = "rbxassetid://9994573642"
    sky.SkyboxFt = "rbxassetid://9994573642"; sky.SkyboxLf = "rbxassetid://9994573642"
    sky.SkyboxRt = "rbxassetid://9994573642"; sky.SkyboxUp = "rbxassetid://9994573642"
    sky.StarCount = 5000; sky.MoonAngularSize = 22; sky.MoonTextureId = "rbxasset://sky/moon.jpg"; sky.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "CustomBloom"
    bloom.Intensity = isNight and 0.4 or 0.2
    bloom.Size = isNight and 38 or 32
    bloom.Threshold = isNight and 0.75 or 0.85
    bloom.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "CustomCC"
    if isNight then
        cc.Brightness = 0.02; cc.Contrast = 0.08; cc.Saturation = 0.2; cc.TintColor = Color3.fromRGB(255, 120, 200)
    else
        cc.Brightness = -0.03; cc.Contrast = 0.05; cc.Saturation = 0.15; cc.TintColor = Color3.fromRGB(200, 100, 160)
    end
    cc.Parent = Lighting
    local atmo = Instance.new("Atmosphere"); atmo.Name = "CustomAtmo"
    if isNight then
        atmo.Density = 0.5; atmo.Offset = 0.08; atmo.Color = Color3.fromRGB(255, 80, 180)
        atmo.Decay = Color3.fromRGB(140, 30, 100); atmo.Glare = 0.7; atmo.Haze = 1.4
    else
        atmo.Density = 0.45; atmo.Offset = 0.1; atmo.Color = Color3.fromRGB(220, 120, 200)
        atmo.Decay = Color3.fromRGB(160, 60, 130); atmo.Glare = 0.5; atmo.Haze = 1.0
    end
    atmo.Parent = Lighting
end

function applyHeavenSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name == "CustomSky" or v.Name == "CustomBloom" or v.Name == "CustomCC" or v.Name == "CustomAtmo" or v.Name == "CustomClouds" then v:Destroy() end
    end
    Lighting.Technology = Enum.Technology.Future
    Lighting.Brightness = 4.5; Lighting.ExposureCompensation = -0.02
    Lighting.Ambient = Color3.fromRGB(250, 245, 230); Lighting.OutdoorAmbient = Color3.fromRGB(255, 250, 240)
    Lighting.ClockTime = 12
    local sky = Instance.new("Sky"); sky.Name = "CustomSky"
    sky.SkyboxBk = "rbxassetid://9994573642"; sky.SkyboxDn = "rbxassetid://9994573642"
    sky.SkyboxFt = "rbxassetid://9994573642"; sky.SkyboxLf = "rbxassetid://9994573642"
    sky.SkyboxRt = "rbxassetid://9994573642"; sky.SkyboxUp = "rbxassetid://9994573642"
    sky.SunAngularSize = 18; sky.StarCount = 0; sky.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "CustomBloom"
    bloom.Intensity = 0.6; bloom.Size = 45; bloom.Threshold = 0.85; bloom.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "CustomCC"
    cc.Brightness = 0.02; cc.Contrast = 0.05; cc.Saturation = 0.1; cc.TintColor = Color3.fromRGB(255, 252, 235); cc.Parent = Lighting
    local atmo = Instance.new("Atmosphere"); atmo.Name = "CustomAtmo"
    atmo.Density = 0.2; atmo.Offset = 0.05; atmo.Color = Color3.fromRGB(255, 252, 235)
    atmo.Decay = Color3.fromRGB(255, 245, 215); atmo.Glare = 3.5; atmo.Haze = 1.2; atmo.Parent = Lighting
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local clouds = Instance.new("Clouds")
        clouds.Name = "CustomClouds"
        clouds.Cover = 0.9; clouds.Density = 0.4; clouds.Color = Color3.fromRGB(255, 255, 255); clouds.Parent = terrain
    end
end

function refreshSkyOnTimeChange()
    local currentSkyMode = State.skyMode
    if currentSkyMode == 1 then applyCyberSky()
    elseif currentSkyMode == 2 then applySakuraSky()
    elseif currentSkyMode == 3 then applyMoonlightSky()
    elseif currentSkyMode == 4 then applyHeavenSky()
    elseif currentSkyMode == 5 then applyLavenderDreamSky() end
end

function setSkyMode(mode)
    State.skyMode = mode
    if skyClockTimeConnection then skyClockTimeConnection:Disconnect(); skyClockTimeConnection = nil end
    if mode == 0 then removeSky()
    elseif mode == 1 then applyCyberSky(); skyClockTimeConnection = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshSkyOnTimeChange)
    elseif mode == 2 then applySakuraSky(); skyClockTimeConnection = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshSkyOnTimeChange)
    elseif mode == 3 then applyMoonlightSky(); skyClockTimeConnection = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshSkyOnTimeChange)
    elseif mode == 4 then applyHeavenSky(); skyClockTimeConnection = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshSkyOnTimeChange)
    elseif mode == 5 then applyLavenderDreamSky(); skyClockTimeConnection = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshSkyOnTimeChange) end
    scheduleAutoSave()
end

function getSkyModeText()
    if State.skyMode == 0 then return "Off"
    elseif State.skyMode == 1 then return "Cyber"
    elseif State.skyMode == 2 then return "Sakura"
    elseif State.skyMode == 3 then return "Moonlight"
    elseif State.skyMode == 4 then return "Heaven"
    elseif State.skyMode == 5 then return "Lavender Dream" end
    return "Off"
end

function nextSkyMode()
    local newMode = (State.skyMode + 1) % 6
    setSkyMode(newMode)
    return getSkyModeText()
end


LP.CharacterAdded:Connect(function(char)
    autoBatEquippedThisRun = false
    if State.autoBatToggled then task.wait(0.5) end
end)

function toggleLaggerMode()
    State.laggerModeEnabled = not State.laggerModeEnabled
    scheduleAutoSave()
    if GuiToggleSetters["laggerToggle"] then GuiToggleSetters["laggerToggle"](State.laggerModeEnabled) end
end


local CharRefs = {humanoid = nil, hrp = nil, speedLabel = nil}

function setupChar(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local head = char:WaitForChild("Head", 5)
    if not humanoid or not hrp or not head then return end
    CharRefs.humanoid = humanoid
    CharRefs.hrp = hrp
    
    clearHorizontalVelocity(hrp)
    
    local old = head:FindFirstChild("SpeedBillboard")
    if old then old:Destroy() end
    
    local bb = Instance.new("BillboardGui")
    bb.Name = "SpeedBillboard"
    bb.Size = UDim2.new(0, 240, 0, 70)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = bb
    
    local discordLabel = Instance.new("TextLabel")
    discordLabel.Name = "DiscordLabel"
    discordLabel.Size = UDim2.new(1, 0, 0.5, 0)
    discordLabel.Position = UDim2.new(0, 0, 0, 0)
    discordLabel.BackgroundTransparency = 1
    discordLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordLabel.Font = Enum.Font.GothamBold
    discordLabel.TextSize = 20
    discordLabel.TextStrokeTransparency = 0
    discordLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    discordLabel.Text = "discord.gg/spaceduels"
    discordLabel.Parent = mainFrame
    
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(0.50, 0, 0, 1.5)
    underline.Position = UDim2.new(0.25, 0, 0.48, 0)
    underline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    underline.BackgroundTransparency = 0
    underline.BorderSizePixel = 0
    underline.Parent = mainFrame
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, 0, 0.5, 0)
    speedLabel.Position = UDim2.new(0, 0, 0.5, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.TextSize = 20
    speedLabel.TextStrokeTransparency = 0
    speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    speedLabel.Text = "Speed: 0.0"
    speedLabel.Parent = mainFrame
    CharRefs.speedLabel = speedLabel
end


do
    local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}
    
    RunService.RenderStepped:Connect(function()
        local h = CharRefs.humanoid
        local hrp = CharRefs.hrp
        local lbl = CharRefs.speedLabel
        
        if not (h and hrp) then return end
        if State.tpInProgress or State.autoBatToggled then return end
        
        if lbl then
            local speed = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
            lbl.Text = "Speed: "..string.format("%.1f", speed)
        end
    end)
end


local EnemySpeedLabels = {}

function setupEnemySpeedDisplay()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local existing = head:FindFirstChild("EnemySpeedBillboard")
                    if existing then existing:Destroy() end
                    
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "EnemySpeedBillboard"
                    bb.Size = UDim2.new(0, 80, 0, 25)
                    bb.StudsOffset = Vector3.new(0, 2.5, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = head
                    
                    local mainFrame = Instance.new("Frame")
                    mainFrame.Size = UDim2.new(1, 0, 1, 0)
                    mainFrame.BackgroundTransparency = 1
                    mainFrame.Parent = bb
                    
                    local speedLabel = Instance.new("TextLabel")
                    speedLabel.Size = UDim2.new(1, 0, 1, 0)
                    speedLabel.Position = UDim2.new(0, 0, 0, 0)
                    speedLabel.BackgroundTransparency = 1
                    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    speedLabel.Font = Enum.Font.GothamBold
                    speedLabel.TextScaled = true
                    speedLabel.TextStrokeTransparency = 0
                    speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    speedLabel.Text = "0.0"
                    speedLabel.Parent = mainFrame
                    EnemySpeedLabels[player] = speedLabel
                end
            end
        end
    end
end

function updateEnemySpeedDisplay()
    for player, label in pairs(EnemySpeedLabels) do
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel = hrp.AssemblyLinearVelocity
                local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
                label.Text = string.format("%.1f", speed)
            else label.Text = "0.0" end
        else label.Text = "0.0" end
    end
end

function onPlayerAdded(player)
    if player ~= LP then
        player.CharacterAdded:Connect(function(character)
            task.wait(0.3)
            local head = character:FindFirstChild("Head")
            if head then
                local existing = head:FindFirstChild("EnemySpeedBillboard")
                if existing then existing:Destroy() end
                local bb = Instance.new("BillboardGui")
                bb.Name = "EnemySpeedBillboard"
                bb.Size = UDim2.new(0, 80, 0, 25)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = head
                local mainFrame = Instance.new("Frame")
                mainFrame.Size = UDim2.new(1, 0, 1, 0)
                mainFrame.BackgroundTransparency = 1
                mainFrame.Parent = bb
                local speedLabel = Instance.new("TextLabel")
                speedLabel.Size = UDim2.new(1, 0, 1, 0)
                speedLabel.Position = UDim2.new(0, 0, 0, 0)
                speedLabel.BackgroundTransparency = 1
                speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                speedLabel.Font = Enum.Font.GothamBold
                speedLabel.TextScaled = true
                speedLabel.TextStrokeTransparency = 0
                speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                speedLabel.Text = "0.0"
                speedLabel.Parent = mainFrame
                EnemySpeedLabels[player] = speedLabel
            end
        end)
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local existing = head:FindFirstChild("EnemySpeedBillboard")
                if existing then existing:Destroy() end
                local bb = Instance.new("BillboardGui")
                bb.Name = "EnemySpeedBillboard"
                bb.Size = UDim2.new(0, 80, 0, 25)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = head
                local mainFrame = Instance.new("Frame")
                mainFrame.Size = UDim2.new(1, 0, 1, 0)
                mainFrame.BackgroundTransparency = 1
                mainFrame.Parent = bb
                local speedLabel = Instance.new("TextLabel")
                speedLabel.Size = UDim2.new(1, 0, 1, 0)
                speedLabel.Position = UDim2.new(0, 0, 0, 0)
                speedLabel.BackgroundTransparency = 1
                speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                speedLabel.Font = Enum.Font.GothamBold
                speedLabel.TextScaled = true
                speedLabel.TextStrokeTransparency = 0
                speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                speedLabel.Text = "0.0"
                speedLabel.Parent = mainFrame
                EnemySpeedLabels[player] = speedLabel
            end
        end
    end
end

function onPlayerRemoving(player)
    EnemySpeedLabels[player] = nil
end

for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

task.spawn(function()
    while true do updateEnemySpeedDisplay(); task.wait(0.1) end
end)

if LP.Character then
    task.spawn(function()
        task.wait(0.3)
        setupChar(LP.Character)
    end)
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    setupChar(char)
end)


local C={
    bg=Color3.fromRGB(3,3,4),
    bgDark=Color3.fromRGB(5,5,7),
    row=Color3.fromRGB(10,10,13),
    input=Color3.fromRGB(15,15,18),
    white=Color3.fromRGB(255,255,255),
    whiteDim=Color3.fromRGB(180,185,195),
    whiteDark=Color3.fromRGB(35,35,40),
    text=Color3.fromRGB(242,242,245),
    textDim=Color3.fromRGB(170,175,185),
    textMuted=Color3.fromRGB(100,105,115),
    divider=Color3.fromRGB(38,38,44),
    accent=Color3.fromRGB(255,255,255),
    accentDim=Color3.fromRGB(185,185,190),
    green=Color3.fromRGB(255,255,255),
}

function guiCorner(p,r)
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,r or 10)
    c.Parent=p
    return c
end

function guiStroke(p,col,t)
    local s=Instance.new("UIStroke")
    s.Color=col or C.divider
    s.Thickness=t or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    s.Parent=p
    return s
end

function tw(obj,props,t,sty,dir)
    TweenService:Create(obj,TweenInfo.new(t or 0.18,sty or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props):Play()
end


function getResponsivePanelSize(defaultWidth, defaultHeight)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local compact = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or viewport.X <= 700
    if not compact then
        return defaultWidth, defaultHeight
    end

    local width = math.min(defaultWidth, math.max(220, viewport.X - 32))
    local height = math.min(defaultHeight, math.max(300, viewport.Y - 24))
    return width, height
end


local GuiRefs = {}
local closeBtnRef = nil
local topBarRef = nil
local BypassGuiRef = nil
local BypassBgImage = nil
local BypassBgGrad = nil
local LaggerGuiRef = nil
local LaggerBgImage = nil
local LaggerBgGrad = nil


function syncAuxBackgrounds()
    local index = State.backgroundIndex or 0
    local imageId = BG_IMAGES and BG_IMAGES[index]
    local enabled = index ~= 0 and imageId ~= nil

    for _, pair in ipairs({
        { image = BypassBgImage, gradient = BypassBgGrad },
        { image = LaggerBgImage, gradient = LaggerBgGrad },
    }) do
        if pair.image and pair.image.Parent then
            pair.image.Visible = enabled
            if enabled then
                pair.image.Image = "rbxassetid://" .. tostring(imageId)
            end
        end
        if pair.gradient and pair.gradient.Parent then
            pair.gradient.Visible = not enabled
        end
    end
end

local GUI_WIDTH, GUI_HEIGHT = getResponsivePanelSize(330, 470)
local SIDEBAR_WIDTH = 0
local CONTENT_LEFT = 10
local CONTENT_RIGHT = 10
local CATEGORY_LEFT = 0
local CATEGORY_WIDTH = 0

for _,name in pairs({
    "ADAPTHub","ApinaGUI","SKSpeedBypass","CypherHub","VoidHub",
    "SpeedBypassGUI","VoidBypassGUI","CyberHub","SpaceHub","NovaHub",
    "RaVe","SpaceHubV3","SpaceBypass","SpaceLagger","SpaceFloatingButtons",
}) do
    local old=PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local GuiHub=Instance.new("ScreenGui")
GuiHub.Name="SpaceHub"
GuiHub.ResetOnSpawn=false
GuiHub.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GuiHub.Parent=PlayerGui
GuiRefs.hub=GuiHub

local Outer=Instance.new("Frame")
Outer.Name="Outer"
Outer.Size=UDim2.new(0,GUI_WIDTH,0,GUI_HEIGHT)
Outer.Position=SpaceHubSharedPosition or UDim2.new(0,20,0,80)
Outer.BackgroundTransparency=1
Outer.BorderSizePixel=0
Outer.ClipsDescendants=false
Outer.Parent=GuiHub
GuiRefs.outer=Outer

local Inner=Instance.new("Frame")
Inner.Name="Inner"
Inner.ClipsDescendants=false
Inner.Size=UDim2.new(1,0,1,0)
Inner.BackgroundColor3=C.bg
Inner.BackgroundTransparency=0
Inner.BorderSizePixel=0
Inner.Parent=Outer
guiCorner(Inner,26)
guiStroke(Inner,Color3.fromRGB(85,85,90),1)
GuiRefs.inner = Inner

local BackgroundContainer = Instance.new("Frame")
BackgroundContainer.Name = "BackgroundContainer"
BackgroundContainer.Size = UDim2.new(1, 0, 1, 0)
BackgroundContainer.BackgroundTransparency = 1
BackgroundContainer.ZIndex = 0
BackgroundContainer.Parent = Inner

local BgGrad = Instance.new("Frame")
BgGrad.Name = "BgGrad"
BgGrad.Size = UDim2.new(1, 0, 1, 0)
BgGrad.BackgroundColor3 = C.bgDark
BgGrad.BorderSizePixel = 0
BgGrad.ZIndex = 0
BgGrad.Parent = BackgroundContainer
guiCorner(BgGrad, 26)

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28,28,34)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8,8,11)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(2,2,3))
})
grad.Rotation = 135
grad.Parent = BgGrad
GuiRefs.bgGrad = BgGrad

local BackgroundImage = Instance.new("ImageLabel")
BackgroundImage.Name = "BackgroundImage"
BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
BackgroundImage.BackgroundTransparency = 1
BackgroundImage.Image = ""
BackgroundImage.ScaleType = Enum.ScaleType.Crop
BackgroundImage.ImageTransparency = 0.02
BackgroundImage.ZIndex = 0
BackgroundImage.Visible = false
BackgroundImage.Parent = BackgroundContainer
guiCorner(BackgroundImage, 26)
GuiRefs.backgroundImage = BackgroundImage

do
    local BackgroundShade = Instance.new("Frame")
    BackgroundShade.Name = "BackgroundShade"
    BackgroundShade.Size = UDim2.new(1, 0, 1, 0)
    BackgroundShade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BackgroundShade.BackgroundTransparency = 0.78
    BackgroundShade.BorderSizePixel = 0
    BackgroundShade.ZIndex = 1
    BackgroundShade.Parent = BackgroundContainer
    guiCorner(BackgroundShade, 26)
end

closeBtnRef = Instance.new("TextButton", GuiHub)
closeBtnRef.Size = UDim2.new(0, 30, 0, 22)
closeBtnRef.Position = UDim2.new(0, GUI_WIDTH - 40, 0, 7)
closeBtnRef.BackgroundColor3 = C.accentDim
closeBtnRef.BackgroundTransparency = 0.5
closeBtnRef.BorderSizePixel = 0
closeBtnRef.Text = "-"
closeBtnRef.TextColor3 = C.white
closeBtnRef.Font = Enum.Font.GothamBold
closeBtnRef.TextSize = 17
closeBtnRef.ZIndex = 1000
Instance.new("UICorner", closeBtnRef).CornerRadius = UDim.new(0, 13)

closeBtnRef.MouseEnter:Connect(function()
    TweenService:Create(closeBtnRef, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
end)
closeBtnRef.MouseLeave:Connect(function()
   TweenService:Create(closeBtnRef, TweenInfo.new(0.12), {BackgroundColor3 = C.row}):Play()
end)

local HeaderFrame=Instance.new("Frame")
HeaderFrame.Name="Frame"
HeaderFrame.Size=UDim2.new(1,0,0,60)
HeaderFrame.BackgroundTransparency=1
HeaderFrame.BorderSizePixel=0
HeaderFrame.Parent=Inner
HeaderFrame.ZIndex=5

local SpaceWordmark=Instance.new("TextLabel")
SpaceWordmark.Name="SpaceWordmark"
SpaceWordmark.ZIndex=7
SpaceWordmark.Position=UDim2.new(0,12,0,4)
SpaceWordmark.Size=UDim2.new(1,-68,0,52)
SpaceWordmark.BackgroundTransparency=1
SpaceWordmark.BorderSizePixel=0
SpaceWordmark.Text="SPACE"
SpaceWordmark.TextColor3=C.white
SpaceWordmark.TextSize=32
SpaceWordmark.Font=Enum.Font.GothamBlack
SpaceWordmark.TextXAlignment=Enum.TextXAlignment.Left
SpaceWordmark.TextYAlignment=Enum.TextYAlignment.Center
SpaceWordmark.Parent=HeaderFrame

local HeaderMinimize=Instance.new("TextButton")
HeaderMinimize.Name="MinimizeButton"
HeaderMinimize.ZIndex=6
HeaderMinimize.Position=UDim2.new(1,-40,0,5)
HeaderMinimize.Size=UDim2.new(0,30,0,22)
HeaderMinimize.BackgroundColor3=Color3.fromRGB(20,20,20)
HeaderMinimize.BackgroundTransparency=0.5
HeaderMinimize.BorderSizePixel=0
HeaderMinimize.Text="-"
HeaderMinimize.TextColor3=Color3.fromRGB(255,255,255)
HeaderMinimize.TextSize=14
HeaderMinimize.Font=Enum.Font.GothamBold
HeaderMinimize.Parent=HeaderFrame
Instance.new("UICorner",HeaderMinimize)
HeaderMinimize.MouseButton1Click:Connect(function()
    GuiRefs.outer.Visible=false
    if closeBtnRef then closeBtnRef.Visible=false end
end)

local ContentFrame=Instance.new("ScrollingFrame")
ContentFrame.Name="ScrollingFrame"
ContentFrame.Size=UDim2.new(1,0,1,-70)
ContentFrame.Position=UDim2.new(0,0,0,60)
ContentFrame.BackgroundTransparency=1
ContentFrame.BorderSizePixel=0
ContentFrame.ScrollBarThickness=3
ContentFrame.ScrollBarImageColor3=Color3.fromRGB(254,254,254)
ContentFrame.ScrollBarImageTransparency=0.4
ContentFrame.CanvasSize=UDim2.new(0,0,0,0)
ContentFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
ContentFrame.ScrollingDirection=Enum.ScrollingDirection.Y
ContentFrame.ScrollingEnabled=true
ContentFrame.ElasticBehavior=Enum.ElasticBehavior.Never
ContentFrame.Parent=Inner
GuiRefs.contentFrame=ContentFrame

local CLayout=Instance.new("UIListLayout")
CLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
CLayout.SortOrder=Enum.SortOrder.LayoutOrder
CLayout.Parent=ContentFrame
local CPad=Instance.new("UIPadding")
CPad.PaddingTop=UDim.new(0,0)
CPad.PaddingBottom=UDim.new(0,8)
CPad.PaddingLeft=UDim.new(0,4)
CPad.PaddingRight=UDim.new(0,4)
CPad.Parent=ContentFrame


local Categories = {"Speed", "Mechanics", "Visual", "Settings"}
local CategoryRefs = {contents = {}, btnsBottom = {}, active = "Speed"}

for _, name in ipairs(Categories) do
    local page = Instance.new("Frame")
    page.Name = "FlatPage_" .. name
    page.Size = UDim2.new(1, 0, 0, 0)
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.BackgroundTransparency = 1
    page.Visible = true
    page.Parent = GuiRefs.contentFrame
    CategoryRefs.contents[name] = page

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 4)
    pagePadding.PaddingLeft = UDim.new(0, 12)
    pagePadding.PaddingRight = UDim.new(0, 12)
    pagePadding.Parent = page
end


GuiRefs.categoryBar = nil
GuiRefs.categoryRefs = CategoryRefs

function updateCloseBtnPosition()
    if not closeBtnRef or not GuiRefs.outer then return end
    local outerPos = GuiRefs.outer.Position
    closeBtnRef.Position = UDim2.new(
        outerPos.X.Scale,
        outerPos.X.Offset + GuiRefs.outer.Size.X.Offset - 40,
        outerPos.Y.Scale,
        outerPos.Y.Offset + 7
    )
end

GuiRefs.outer:GetPropertyChangedSignal("Position"):Connect(updateCloseBtnPosition)
GuiRefs.outer:GetPropertyChangedSignal("Size"):Connect(updateCloseBtnPosition)
updateCloseBtnPosition()

do
    local dragging = false
    local dragStartPos = nil
    local startGuiPos = nil
    local dragInput = nil
    
    GuiRefs.outer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            startGuiPos = GuiRefs.outer.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    GuiRefs.outer.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStartPos
            GuiRefs.outer.Position = UDim2.new(
                startGuiPos.X.Scale, startGuiPos.X.Offset + delta.X,
                startGuiPos.Y.Scale, startGuiPos.Y.Offset + delta.Y
            )
            SpaceHubSharedPosition = GuiRefs.outer.Position
            updateCloseBtnPosition()
        end
    end)
end

function closeGui()
    State.guiVisible = false
    GuiRefs.outer.Visible = false
    if closeBtnRef then closeBtnRef.Visible = false end
    if not topBarRef then
        topBarRef = Instance.new("TextButton", GuiHub)
        topBarRef.Name = "SpaceTopBar"
        topBarRef.Size = UDim2.new(0, 90, 0, 24)
        topBarRef.Position = UDim2.new(0, 6, 0, 6)
        topBarRef.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        topBarRef.BorderSizePixel = 0
        topBarRef.Text = ""
        topBarRef.ZIndex = 1000
        topBarRef.Visible = false
        topBarRef.Active = true
        Instance.new("UICorner", topBarRef).CornerRadius = UDim.new(0, 5)
        local topBarStroke = Instance.new("UIStroke", topBarRef)
        topBarStroke.Color = Color3.fromRGB(50, 50, 50)
        topBarStroke.Thickness = 1

        local topBarTxt = Instance.new("TextLabel", topBarRef)
        topBarTxt.Size = UDim2.new(1, 0, 1, 0)
        topBarTxt.Position = UDim2.new(0, 0, 0, 0)
        topBarTxt.BackgroundTransparency = 1
        topBarTxt.Text = "SPACE HUB"
        topBarTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
        topBarTxt.Font = Enum.Font.GothamBlack
        topBarTxt.TextSize = 9
        topBarTxt.TextXAlignment = Enum.TextXAlignment.Center
        topBarTxt.ZIndex = 1001

        topBarRef.MouseButton1Click:Connect(function()
            State.guiVisible = true
            GuiRefs.outer.Visible = true
            if closeBtnRef then closeBtnRef.Visible = true end
            topBarRef.Visible = false
        end)
        topBarRef.MouseEnter:Connect(function()
            TweenService:Create(topBarRef, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(30,30,30)}):Play()
        end)
        topBarRef.MouseLeave:Connect(function()
            TweenService:Create(topBarRef, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(15,15,15)}):Play()
        end)
    end
    
    if topBarRef then topBarRef.Visible = true end
end

closeBtnRef.MouseButton1Click:Connect(closeGui)

State.guiVisible = true
if GuiRefs.outer then GuiRefs.outer.Visible = true end
if closeBtnRef then closeBtnRef.Visible = true end
if topBarRef then topBarRef.Visible = false end


local KeyListen = {
    cb = nil,
    label = nil,
    active = false,
    allowModifier = false,
    previousText = nil,
}

local KEY_DISPLAY_ALIASES = {
    ButtonA="A", ButtonB="B", ButtonX="X", ButtonY="Y",
    ButtonR1="RB", ButtonR2="RT", ButtonL1="LB", ButtonL2="LT",
    DPadUp="D↑", DPadDown="D↓", DPadLeft="D←", DPadRight="D→",
    ButtonStart="▶", ButtonSelect="◀", ButtonR3="RS", ButtonL3="LS",
    Thumbstick1="L3", Thumbstick2="R3",
    CapsLock="CapsLock",
    LeftControl="Ctrl", RightControl="Ctrl",
    LeftAlt="Alt", RightAlt="Alt",
}

function prettyKeyName(keyCode)
    local raw = keyCode.Name
    return KEY_DISPLAY_ALIASES[raw] or raw
end

function cancelKeyListen()
    if KeyListen.label then
        if KeyListen.label.Parent and KeyListen.previousText then
            KeyListen.label.Text = KeyListen.previousText
        end
        KeyListen.label.BackgroundColor3 = C.accent
        KeyListen.label.BackgroundTransparency = 0.5
    end
    KeyListen.cb = nil
    KeyListen.label = nil
    KeyListen.active = false
    KeyListen.allowModifier = false
    KeyListen.previousText = nil
end

function startKeyListen(labelBtn, onKeySet)
    cancelKeyListen()
    KeyListen.cb = onKeySet
    KeyListen.label = labelBtn
    KeyListen.active = true
    KeyListen.allowModifier = true
    KeyListen.previousText = labelBtn.Text
    labelBtn.Text = "..."
    labelBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    labelBtn.BackgroundTransparency = 0.3

    local captureId = labelBtn
    task.delay(8, function()
        if KeyListen.label == captureId and KeyListen.active then
            local restoreText = KeyListen.previousText or prettyKeyName(Keys.guiHide)
            cancelKeyListen()
            if labelBtn and labelBtn.Parent then
                labelBtn.Text = restoreText
                labelBtn.BackgroundColor3 = C.accent
                labelBtn.BackgroundTransparency = 0.5
            end
        end
    end)
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not KeyListen.active then return end
    local ut = input.UserInputType
    if ut ~= Enum.UserInputType.Keyboard and ut ~= Enum.UserInputType.Gamepad1 and ut ~= Enum.UserInputType.Gamepad2 then return end
    local key = input.KeyCode
    local ignored = {
        [Enum.KeyCode.Unknown] = true,
        [Enum.KeyCode.LeftShift] = true,
        [Enum.KeyCode.RightShift] = true,
        [Enum.KeyCode.LeftMeta] = true,
        [Enum.KeyCode.RightMeta] = true,
        [Enum.KeyCode.Tab] = true,
    }
    if ignored[key] and key ~= Enum.KeyCode.CapsLock then return end
    if key == Enum.KeyCode.Escape then cancelKeyListen(); return end
    local cb = KeyListen.cb
    local lbl = KeyListen.label
    cancelKeyListen()
    if lbl and lbl.Parent then
        lbl.Text = prettyKeyName(key)
        lbl.BackgroundColor3 = C.accent
        lbl.BackgroundTransparency = 0.5
    end
    if cb then task.spawn(cb, key) end
end)


function addSectionLabel(parent,text,order)
    local f=Instance.new("Frame")
    f.Name="Frame"
    f.LayoutOrder=order or 1
    f.Size=UDim2.new(1,0,0,34)
    f.BackgroundTransparency=1
    f.BorderSizePixel=0
    f.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Name="TextLabel"
    lbl.ZIndex=4
    lbl.Position=UDim2.new(0,0,0,6)
    lbl.Size=UDim2.new(1,0,0,16)
    lbl.BackgroundTransparency=1
    lbl.Text=text
    lbl.TextColor3=Color3.fromRGB(254,254,254)
    lbl.TextSize=13
    lbl.Font=Enum.Font.GothamBlack
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextTruncate=Enum.TextTruncate.AtEnd
    lbl.Parent=f
    local sep=Instance.new("Frame")
    sep.ZIndex=3
    sep.Position=UDim2.new(0,0,0,30)
    sep.Size=UDim2.new(1,0,0,1)
    sep.BackgroundColor3=Color3.fromRGB(254,254,254)
    sep.BackgroundTransparency=0.85
    sep.BorderSizePixel=0
    sep.Parent=f
    return lbl
end

function addInputRow(parent,label,value,order,callback)
    local Row=Instance.new("Frame")
    Row.Name="Frame"
    Row.ZIndex=4
    Row.LayoutOrder=order
    Row.Size=UDim2.new(1,0,0,40)
    Row.BackgroundColor3=Color3.fromRGB(18,18,18)
    Row.BackgroundTransparency=0.5
    Row.BorderSizePixel=0
    Row.Parent=parent
    guiCorner(Row,10)
    local Lbl=Instance.new("TextLabel",Row)
    Lbl.Name="TextLabel"
    Lbl.ZIndex=5
    Lbl.Position=UDim2.new(0,12,0.5,-9)
    Lbl.Size=UDim2.new(0.5,0,0,16)
    Lbl.BackgroundTransparency=1
    Lbl.Text=label
    Lbl.TextColor3=Color3.fromRGB(255,255,255)
    Lbl.TextSize=12
    Lbl.Font=Enum.Font.GothamBold
    Lbl.TextXAlignment=Enum.TextXAlignment.Left
    Lbl.Parent=Row
    local Box=Instance.new("Frame",Row)
    Box.Name="Box"
    Box.ZIndex=6
    Box.Position=UDim2.new(1,-66,0.5,-12)
    Box.Size=UDim2.new(0,54,0,24)
    Box.BackgroundColor3=Color3.fromRGB(0,0,0)
    Box.BackgroundTransparency=0.5
    Box.BorderSizePixel=0
    guiCorner(Box,6)
    guiStroke(Box,Color3.fromRGB(254,254,254),1.4)
    local Tb=Instance.new("TextBox",Box)
    Tb.Name="TextBox"
    Tb.ZIndex=7
    Tb.Size=UDim2.new(1,0,1,0)
    Tb.BackgroundTransparency=1
    Tb.Text=tostring(value)
    Tb.TextColor3=Color3.fromRGB(255,255,255)
    Tb.TextSize=12
    Tb.Font=Enum.Font.GothamBold
    Tb.ClearTextOnFocus=false
    Tb.FocusLost:Connect(function()
        local n=tonumber(Tb.Text)
        if n then callback(n) else Tb.Text=tostring(value) end
    end)
    return Row,Tb
end

function addToggleRow(parent,label,enabled,order,keybindKey,onToggle)
    local Row=Instance.new("Frame")
    Row.Name="Frame"
    Row.ZIndex=4
    Row.LayoutOrder=order
    Row.Size=UDim2.new(1,0,0,40)
    Row.BackgroundColor3=Color3.fromRGB(18,18,18)
    Row.BackgroundTransparency=0.5
    Row.BorderSizePixel=0
    Row.Parent=parent
    guiCorner(Row,10)
    guiStroke(Row,Color3.fromRGB(28,28,34),1)
    local labelX=12
    if keybindKey then
        local key=Instance.new("TextButton",Row)
        key.Name="Keybind"
        key.ZIndex=10
        key.Position=UDim2.new(0,12,0.5,-12)
        key.Size=UDim2.new(0,40,0,24)
        key.BackgroundColor3=Color3.fromRGB(254,254,254)
        key.BackgroundTransparency=0.5
        key.BorderSizePixel=0
        key.Text=Keys[keybindKey].Name
        key.TextColor3=Color3.fromRGB(0,0,0)
        key.TextSize=10
        key.Font=Enum.Font.GothamBold
        guiCorner(key,6)
        key.MouseButton1Click:Connect(function()
            startKeyListen(key,function(newKey)
                Keys[keybindKey]=newKey
                key.Text=prettyKeyName(newKey)
                scheduleAutoSave()
            end)
        end)
        labelX=60
    end
    local Lbl=Instance.new("TextLabel",Row)
    Lbl.Name="TextLabel"
    Lbl.ZIndex=5
    Lbl.Position=UDim2.new(0,labelX,0.5,-9)
    Lbl.Size=UDim2.new(0.55,0,0,16)
    Lbl.BackgroundTransparency=1
    Lbl.Text=label
    Lbl.TextColor3=Color3.fromRGB(255,255,255)
    Lbl.TextSize=12
    Lbl.Font=Enum.Font.GothamBold
    Lbl.TextXAlignment=Enum.TextXAlignment.Left
    Lbl.Parent=Row
    local Track=Instance.new("Frame",Row)
    Track.Name="Track"
    Track.ZIndex=6
    Track.Position=UDim2.new(1,-48,0.5,-9)
    Track.Size=UDim2.new(0,36,0,18)
    Track.BackgroundColor3=Color3.fromRGB(40,40,40)
    Track.BackgroundTransparency=0.5
    Track.BorderSizePixel=0
    guiCorner(Track,18)
    guiStroke(Track,Color3.fromRGB(70,70,70),1)
    local Knob=Instance.new("Frame",Track)
    Knob.Name="Knob"
    Knob.ZIndex=7
    Knob.Size=UDim2.new(0,14,0,14)
    Knob.BackgroundColor3=Color3.fromRGB(120,120,120)
    Knob.BackgroundTransparency=0.5
    Knob.BorderSizePixel=0
    guiCorner(Knob,14)
    local state=enabled or false
    local function setV(on)
        state=on
        Track.BackgroundColor3=on and Color3.fromRGB(254,254,254) or Color3.fromRGB(40,40,40)
        Track.BackgroundTransparency=on and 0.2 or 0.5
        Knob.BackgroundColor3=on and Color3.fromRGB(20,20,20) or Color3.fromRGB(120,120,120)
        Knob.Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    end
    setV(state)
    local Btn=Instance.new("TextButton",Row)
    Btn.Name="TextButton"
    Btn.ZIndex=8
    if keybindKey then
        
        Btn.Position=UDim2.new(0,58,0,0)
        Btn.Size=UDim2.new(1,-58,1,0)
    else
        Btn.Size=UDim2.new(1,0,1,0)
    end
    Btn.BackgroundTransparency=1
    Btn.Text=""
    Btn.MouseButton1Click:Connect(function()
        setV(not state)
        if onToggle then onToggle(state) end
    end)
    if keybindKey then GuiToggleSetters[keybindKey]=setV end
    return Row,setV
end

function addSelectorRow(parent,label,value,order,options,onChanged,key)
    local Row=Instance.new("Frame")
    Row.Name="Frame"
    Row.ZIndex=4
    Row.LayoutOrder=order
    Row.Size=UDim2.new(1,0,0,40)
    Row.BackgroundColor3=Color3.fromRGB(18,18,18)
    Row.BackgroundTransparency=0.5
    Row.BorderSizePixel=0
    Row.Parent=parent
    guiCorner(Row,10)
    guiStroke(Row,Color3.fromRGB(28,28,34),1)
    local Lbl=Instance.new("TextLabel",Row)
    Lbl.ZIndex=5
    Lbl.Position=UDim2.new(0,12,0.5,-9)
    Lbl.Size=UDim2.new(1,-152,0,16)
    Lbl.BackgroundTransparency=1
    Lbl.Text=label
    Lbl.TextColor3=Color3.fromRGB(255,255,255)
    Lbl.TextSize=12
    Lbl.Font=Enum.Font.GothamBold
    Lbl.TextXAlignment=Enum.TextXAlignment.Left
    Lbl.Parent=Row
    local Btn=Instance.new("TextButton",Row)
    Btn.ZIndex=6
    Btn.Position=UDim2.new(1,-70,0.5,-12)
    Btn.Size=UDim2.new(0,58,0,24)
    Btn.BackgroundColor3=Color3.fromRGB(254,254,254)
    Btn.BackgroundTransparency=0.5
    Btn.BorderSizePixel=0
    Btn.TextColor3=Color3.fromRGB(0,0,0)
    Btn.TextSize=11
    Btn.Font=Enum.Font.GothamBold
    Btn.AutoButtonColor=false
    guiCorner(Btn,6)
    local current=value
    local function setV(newValue) current=newValue; Btn.Text=tostring(newValue) end
    setV(current)
    Btn.MouseButton1Click:Connect(function()
        local index=table.find(options,current) or 1
        local nextValue=options[index % #options + 1]
        setV(nextValue)
        if onChanged then onChanged(nextValue) end
    end)
    if key then GuiToggleSetters[key]=setV end
    return Row,setV
end

function addActionRow(parent,label,keybindKey,onAction,order)
    local Row=Instance.new("Frame")
    Row.Name="Frame"
    Row.ZIndex=4
    Row.LayoutOrder=order
    Row.Size=UDim2.new(1,0,0,40)
    Row.BackgroundColor3=Color3.fromRGB(18,18,18)
    Row.BackgroundTransparency=0.5
    Row.BorderSizePixel=0
    Row.Parent=parent
    guiCorner(Row,10)
    guiStroke(Row,Color3.fromRGB(28,28,34),1)
    local Lbl=Instance.new("TextLabel",Row)
    Lbl.ZIndex=5
    Lbl.Position=UDim2.new(0,12,0.5,-9)
    Lbl.Size=UDim2.new(0.5,0,0,16)
    Lbl.BackgroundTransparency=1
    Lbl.Text=label
    Lbl.TextColor3=Color3.fromRGB(255,255,255)
    Lbl.TextSize=12
    Lbl.Font=Enum.Font.GothamBold
    Lbl.TextXAlignment=Enum.TextXAlignment.Left
    Lbl.Parent=Row
    local Action=Instance.new("TextButton",Row)
    Action.Name="ActionButton"
    Action.ZIndex=6
    Action.Position=UDim2.new(1,-134,0.5,-12)
    Action.Size=UDim2.new(0,58,0,24)
    Action.BackgroundColor3=Color3.fromRGB(254,254,254)
    Action.BackgroundTransparency=0.5
    Action.BorderSizePixel=0
    Action.Text="RUN"
    Action.TextColor3=Color3.fromRGB(0,0,0)
    Action.TextSize=10
    Action.Font=Enum.Font.GothamBold
    Action.AutoButtonColor=false
    guiCorner(Action,6)
    Action.MouseButton1Click:Connect(onAction)
    local Key=Instance.new("TextButton",Row)
    Key.Name="Keybind"
    Key.ZIndex=6
    Key.Position=UDim2.new(1,-70,0.5,-12)
    Key.Size=UDim2.new(0,58,0,24)
    Key.BackgroundColor3=Color3.fromRGB(30,30,30)
    Key.BackgroundTransparency=0.5
    Key.BorderSizePixel=0
    Key.Text=Keys[keybindKey].Name
    Key.TextColor3=Color3.fromRGB(165,165,170)
    Key.TextSize=10
    Key.Font=Enum.Font.GothamBold
    Key.AutoButtonColor=false
    guiCorner(Key,6)
    Key.MouseButton1Click:Connect(function()
        startKeyListen(Key,function(newKey)
            Keys[keybindKey]=newKey
            Key.Text=prettyKeyName(newKey)
            scheduleAutoSave()
        end)
    end)
    return Row
end


function runInstaReset()
    local character = LP.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            10000000,
            hrp.AssemblyLinearVelocity.Z
        )
    end
end

function addCycleRow(parent,label,value,order,onCycle)
    local Row=Instance.new("Frame")
    Row.Name="Frame"
    Row.ZIndex=4
    Row.LayoutOrder=order
    Row.Size=UDim2.new(1,0,0,40)
    Row.BackgroundColor3=Color3.fromRGB(18,18,18)
    Row.BackgroundTransparency=0.5
    Row.BorderSizePixel=0
    Row.Parent=parent
    guiCorner(Row,10)
    guiStroke(Row,Color3.fromRGB(28,28,34),1)
    local Lbl=Instance.new("TextLabel",Row)
    Lbl.ZIndex=5
    Lbl.Position=UDim2.new(0,12,0.5,-9)
    Lbl.Size=UDim2.new(0.5,0,0,16)
    Lbl.BackgroundTransparency=1
    Lbl.Text=label
    Lbl.TextColor3=Color3.fromRGB(255,255,255)
    Lbl.TextSize=12
    Lbl.Font=Enum.Font.GothamBold
    Lbl.TextXAlignment=Enum.TextXAlignment.Left
    Lbl.Parent=Row
    local Btn=Instance.new("TextButton",Row)
    Btn.ZIndex=6
    Btn.Position=UDim2.new(1,-70,0.5,-12)
    Btn.Size=UDim2.new(0,58,0,24)
    Btn.BackgroundColor3=Color3.fromRGB(254,254,254)
    Btn.BackgroundTransparency=0.5
    Btn.BorderSizePixel=0
    Btn.Text=tostring(value)
    Btn.TextColor3=Color3.fromRGB(0,0,0)
    Btn.TextSize=10
    Btn.Font=Enum.Font.GothamBold
    Btn.AutoButtonColor=false
    guiCorner(Btn,6)
    Btn.MouseButton1Click:Connect(function()
        local newValue=onCycle()
        if newValue ~= nil then Btn.Text=tostring(newValue) end
    end)
    return Row,Btn
end


do
    local sp=GuiRefs.categoryRefs.contents["Speed"]
    addSectionLabel(sp,"SPEED CONFIGURATION",0)
    addInputRow(sp,"Normal Speed",State.normalSpeed,1,function(v) State.normalSpeed=v; scheduleAutoSave() end)
    addInputRow(sp,"Carry Speed",State.carrySpeed,2,function(v) State.carrySpeed=v; scheduleAutoSave() end)
    addInputRow(sp,"Lagger Normal",State.laggerNormalSpeed,3,function(v) State.laggerNormalSpeed=v; scheduleAutoSave() end)
    addInputRow(sp,"Lagger Carry",State.laggerCarrySpeed,4,function(v) State.laggerCarrySpeed=v; scheduleAutoSave() end)

    
    
    addSelectorRow(sp,"Mode",State.speedToggled and "Carry" or "Normal",5,{"Normal","Carry"},function(newMode)
        State.speedToggled = newMode == "Carry"
        scheduleAutoSave()
    end,"speedMode")
    addToggleRow(sp,"Auto Carry Mode",State.autoCarryEnabled,6,nil,function(on)
        State.autoCarryEnabled = on
        scheduleAutoSave()
    end)
    addActionRow(sp,"Speed Key","speed",function() end,7)
    addActionRow(sp,"Lagger Key","laggerToggle",function() end,8)
end

do
    local mp=GuiRefs.categoryRefs.contents["Mechanics"]
    addSectionLabel(mp,"MECHANICS",0)
    
    addCycleRow(mp,"Auto Bat version",State.autoBatVersion,1,function()
        local nextVersion = State.autoBatVersion == "V1" and "V2" or "V1"
        setAutoBatVersion(nextVersion)
        return State.autoBatVersion
    end)

    addToggleRow(mp,"Tp Bat",State.tpBatEnabled,2,"tpBat",function(on)
        State.tpBatEnabled = on
        if on then startTpBat() else stopTpBat() end
        scheduleAutoSave()
    end)

    addToggleRow(mp,"Auto Bat",State.autoBatToggled,3,"autoBat",function(on)
        setSelectedAutoBatState(on)
    end)
    
    addToggleRow(mp,"Auto Swing",autoSwingEnabled,4,nil,function(on) autoSwingEnabled=on; scheduleAutoSave() end)

    addToggleRow(mp,"Body Lock",State.bodyLockEnabled,5,nil,function(on)
        setBodyLock(on)
    end)
    
    addToggleRow(mp,"Infinite Jump",State.infJumpEnabled,6,nil,function(on) setInfJumpInternal(on) end)
    
    addToggleRow(mp,"Anti Ragdoll",State.antiRagdollEnabled,7,nil,function(on)
        State.antiRagdollEnabled = on
        AntiRagdoll.Enabled = on
        if on then startAntiRagdoll() else stopAntiRagdoll() end
        scheduleAutoSave()
    end)
    
    addToggleRow(mp,"Ragdoll Timer",State.ragdollTimerEnabled,8,nil,function(on)
        State.setRagdollTimer(on)
    end)

    addToggleRow(mp,"Anti Die",State.antiDieEnabled,9,nil,function(on)
        State.setAntiDie(on)
    end)

    addToggleRow(mp,"Medusa Counter",State.medusaCounterEnabled,10,nil,function(on)
        State.medusaCounterEnabled=on
        if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
        scheduleAutoSave()
    end)
    
    addToggleRow(mp,"Unwalk",State.unwalkEnabled or false,11,nil,function(on)
        State.unwalkEnabled = on
        if on then startUnwalk() else stopUnwalk() end
        scheduleAutoSave()
    end)
    
    addSectionLabel(mp,"AUTO GRAB",12)
    addToggleRow(mp,"Auto Grab",State.autoGrabEnabled,13,nil,function(on)
        State.autoGrabEnabled = on
        if on then
            startAutoGrab()
            createProgressBar()
        else
            stopAutoGrab()
        end
        scheduleAutoSave()
    end)
    addCycleRow(mp, "Steal Version", State.autoStealVersion, 14, function()
        State.autoStealVersion = State.autoStealVersion == "V2" and "V1" or "V2"
        scheduleAutoSave()
        return State.autoStealVersion
    end)
    addCycleRow(mp, "Steal Mode", State.stealMode:upper(), 15, function()
        State.stealMode = State.stealMode == "normal" and "op" or "normal"
        scheduleAutoSave()
        return State.stealMode:upper()
    end)
    addCycleRow(mp, "Normal Pause %", State.normalStealVersion .. "%", 16, function()
        local order = {"75", "80", "86", "90"}
        local idx = 1
        for i, v in ipairs(order) do
            if v == State.normalStealVersion then idx = i break end
        end
        local nextIdx = (idx % #order) + 1
        State.normalStealVersion = order[nextIdx]
        scheduleAutoSave()
        return State.normalStealVersion .. "%"
    end)
    addInputRow(mp,"Prime Range",State.primeRange or 8.5,17,function(v)
        State.primeRange = math.clamp(v, 3, 30)
        scheduleAutoSave()
    end)
    addInputRow(mp,"Steal Radius",State.grabStealRadius,18,function(v)
        State.grabStealRadius = math.clamp(v, 10, 120)
        scheduleAutoSave()
    end)
    addInputRow(mp,"Steal Duration",State.grabStealDuration,19,function(v)
        State.grabStealDuration = math.clamp(v, 0.5, 5)
        scheduleAutoSave()
    end)
    
    addSectionLabel(mp,"ACTIONS",19)
    addActionRow(mp, "Drop Brainrot", "dropBrainrot", function() runDropBrainrot() end, 20)
    addActionRow(mp, "TP Down", "tpDown", function() tpDown() end, 21)
    addActionRow(mp, "Insta Reset", "instaReset", function()
        runInstaReset()
    end, 22)
end

do
    local vi = GuiRefs.categoryRefs.contents["Visual"]
    addSectionLabel(vi, "BACKGROUND", 0)

    local BgRow = Instance.new("Frame")
    BgRow.Size = UDim2.new(1, 0, 0, 86)
    BgRow.BackgroundColor3 = C.row
    BgRow.BackgroundTransparency = 0.6
    BgRow.BorderSizePixel = 0
    BgRow.LayoutOrder = 1
    BgRow.ZIndex = 2
    BgRow.Parent = vi
    guiCorner(BgRow, 8)
    guiStroke(BgRow, C.divider, 0.5)

    BgLeft = Instance.new("TextButton", BgRow)
    BgLeft.Size = UDim2.new(0, 22, 0, 34)
    BgLeft.Position = UDim2.new(0, 4, 0, 6)
    BgLeft.BackgroundColor3 = C.input
    BgLeft.BackgroundTransparency = 0.25
    BgLeft.BorderSizePixel = 0
    BgLeft.Text = "<"
    BgLeft.TextColor3 = C.text
    BgLeft.TextSize = 11
    BgLeft.Font = Enum.Font.GothamBold
    BgLeft.ZIndex = 4
    guiCorner(BgLeft, 7)

    BtnNone = Instance.new("TextButton", BgRow)
    BtnNone.Size = UDim2.new(0, 36, 0, 34)
    BtnNone.Position = UDim2.new(0, 31, 0, 6)
    BtnNone.BackgroundColor3 = C.accent
    BtnNone.BackgroundTransparency = State.backgroundIndex == 0 and 0.2 or 0.6
    BtnNone.BorderSizePixel = 0
    BtnNone.Text = "None"
    BtnNone.TextColor3 = C.text
    BtnNone.TextSize = 9
    BtnNone.Font = Enum.Font.GothamBold
    BtnNone.ZIndex = 3
    guiCorner(BtnNone, 6)
    StrokeNone = guiStroke(BtnNone, State.backgroundIndex == 0 and C.accent or C.divider, 0.5)

    Preview1 = Instance.new("Frame", BgRow)
    Preview1.Size = UDim2.new(0, 36, 0, 34)
    Preview1.Position = UDim2.new(0, 70, 0, 6)
    Preview1.BackgroundColor3 = Color3.fromRGB(22,22,28)
    Preview1.BorderSizePixel = 0
    guiCorner(Preview1, 6)
    Stroke1 = guiStroke(Preview1, State.backgroundIndex == 1 and C.accent or C.divider, 0.5)

    Img1 = Instance.new("ImageLabel", Preview1)
    Img1.Size = UDim2.new(1, 0, 1, 0)
    Img1.BackgroundTransparency = 1
    Img1.Image = "rbxassetid://" .. BG_IMAGES[1]
    Img1.ScaleType = Enum.ScaleType.Crop
    guiCorner(Img1, 6)

    Btn1 = Instance.new("TextButton", Preview1)
    Btn1.Size = UDim2.new(1, 0, 1, 0)
    Btn1.BackgroundTransparency = 1
    Btn1.Text = ""

    Preview2 = Instance.new("Frame", BgRow)
    Preview2.Size = UDim2.new(0, 36, 0, 34)
    Preview2.Position = UDim2.new(0, 110, 0, 6)
    Preview2.BackgroundColor3 = Color3.fromRGB(22,22,28)
    Preview2.BorderSizePixel = 0
    guiCorner(Preview2, 6)
    Stroke2 = guiStroke(Preview2, State.backgroundIndex == 2 and C.accent or C.divider, 0.5)

    Img2 = Instance.new("ImageLabel", Preview2)
    Img2.Size = UDim2.new(1, 0, 1, 0)
    Img2.BackgroundTransparency = 1
    Img2.Image = "rbxassetid://" .. BG_IMAGES[2]
    Img2.ScaleType = Enum.ScaleType.Crop
    guiCorner(Img2, 6)

    Btn2 = Instance.new("TextButton", Preview2)
    Btn2.Size = UDim2.new(1, 0, 1, 0)
    Btn2.BackgroundTransparency = 1
    Btn2.Text = ""

    Preview3 = Instance.new("Frame", BgRow)
    Preview3.Size = UDim2.new(0, 36, 0, 34)
    Preview3.Position = UDim2.new(0, 150, 0, 6)
    Preview3.BackgroundColor3 = Color3.fromRGB(22,22,28)
    Preview3.BorderSizePixel = 0
    guiCorner(Preview3, 6)
    Stroke3 = guiStroke(Preview3, State.backgroundIndex == 3 and C.accent or C.divider, 0.5)

    
    
    Img3 = Instance.new("ImageLabel", Preview3)
    Img3.Size = UDim2.new(1, 0, 1, 0)
    Img3.BackgroundTransparency = 1
    Img3.Image = "rbxassetid://" .. BG_IMAGES[3]
    Img3.ScaleType = Enum.ScaleType.Crop
    guiCorner(Img3, 6)

    Btn3 = Instance.new("TextButton", Preview3)
    Btn3.Size = UDim2.new(1, 0, 1, 0)
    Btn3.BackgroundTransparency = 1
    Btn3.Text = ""

    Preview4 = Instance.new("Frame", BgRow)
    Preview4.Size = UDim2.new(0, 36, 0, 34)
    Preview4.Position = UDim2.new(0, 190, 0, 6)
    Preview4.BackgroundColor3 = Color3.fromRGB(22,22,28)
    Preview4.BorderSizePixel = 0
    guiCorner(Preview4, 6)
    Stroke4 = guiStroke(Preview4, State.backgroundIndex == 4 and C.accent or C.divider, 0.5)

    Img4 = Instance.new("ImageLabel", Preview4)
    Img4.Size = UDim2.new(1, 0, 1, 0)
    Img4.BackgroundTransparency = 1
    Img4.Image = "rbxassetid://" .. BG_IMAGES[4]
    Img4.ScaleType = Enum.ScaleType.Crop
    guiCorner(Img4, 6)

    Btn4 = Instance.new("TextButton", Preview4)
    Btn4.Size = UDim2.new(1, 0, 1, 0)
    Btn4.BackgroundTransparency = 1
    Btn4.Text = ""

    Preview5 = Instance.new("Frame", BgRow)
    Preview5.Size = UDim2.new(0, 36, 0, 34)
    Preview5.Position = UDim2.new(0, 230, 0, 6)
    Preview5.BackgroundColor3 = Color3.fromRGB(22,22,28)
    Preview5.BorderSizePixel = 0
    guiCorner(Preview5, 6)
    Stroke5 = guiStroke(Preview5, State.backgroundIndex == 5 and C.accent or C.divider, 0.5)

    Img5 = Instance.new("ImageLabel", Preview5)
    Img5.Size = UDim2.new(1, 0, 1, 0)
    Img5.BackgroundTransparency = 1
    Img5.Image = "rbxassetid://" .. BG_IMAGES[5]
    Img5.ScaleType = Enum.ScaleType.Crop
    guiCorner(Img5, 6)

    Btn5 = Instance.new("TextButton", Preview5)
    Btn5.Size = UDim2.new(1, 0, 1, 0)
    Btn5.BackgroundTransparency = 1
    Btn5.Text = ""

    BgRight = Instance.new("TextButton", BgRow)
    BgRight.Size = UDim2.new(0, 22, 0, 34)
    BgRight.Position = UDim2.new(1, -26, 0, 6)
    BgRight.BackgroundColor3 = C.input
    BgRight.BackgroundTransparency = 0.25
    BgRight.BorderSizePixel = 0
    BgRight.Text = ">"
    BgRight.TextColor3 = C.text
    BgRight.TextSize = 11
    BgRight.Font = Enum.Font.GothamBold
    BgRight.ZIndex = 4
    guiCorner(BgRight, 7)

    
    BgPalette = {
        Color3.fromRGB(205, 153, 255),
        Color3.fromRGB(55, 130, 240),
        Color3.fromRGB(240, 55, 75),
        Color3.fromRGB(245, 70, 170),
        Color3.fromRGB(255, 210, 20),
        Color3.fromRGB(25, 25, 28),
        Color3.fromRGB(245, 245, 245),
        Color3.fromRGB(45, 145, 95),
    }
    BgPaletteButtons = {}
    function applyAccentColor(color)
        if typeof(color) ~= "Color3" then return end
        SpaceHubTextColor = color
        State.accentR = math.floor(color.R * 255 + 0.5)
        State.accentG = math.floor(color.G * 255 + 0.5)
        State.accentB = math.floor(color.B * 255 + 0.5)
        
        
        C.text = color

        for _, root in ipairs({
            GuiRefs.hub,
            SpaceHubActiveV2Gui,
            SpaceHubActiveV3Gui,
            floatingButtonsContainer,
            BypassGuiRef,
            LaggerGuiRef,
        }) do
            if root then
                for _, object in ipairs(root:GetDescendants()) do
                    if object:IsA("TextLabel")
                        or object:IsA("TextButton")
                        or object:IsA("TextBox") then
                        object.TextColor3 = color
                    end
                end
            end
        end

    end

    
    applyAccentColor(Color3.fromRGB(State.accentR, State.accentG, State.accentB))

    function bindBgPaletteButton(button)
        button.MouseButton1Click:Connect(function()
            local selectedColor = button:GetAttribute("PaletteColor")
            applyAccentColor(selectedColor)
            scheduleAutoSave()
            for _, paletteButton in ipairs(BgPaletteButtons) do
                paletteButton.BackgroundTransparency =
                    paletteButton.BackgroundColor3 == selectedColor and 0 or 0.18
            end
        end)
    end
    BgPaletteIndex = 1
    while BgPalette[BgPaletteIndex] do
        BgPaletteColor = BgPalette[BgPaletteIndex]
        BgPaletteButton = Instance.new("TextButton", BgRow)
        BgPaletteButton.Size = UDim2.new(0, 20, 0, 10)
        BgPaletteButton.Position = UDim2.new(0, 31 + (BgPaletteIndex - 1) * 22, 0, 63)
        BgPaletteButton.BackgroundColor3 = BgPaletteColor
        BgPaletteButton.BorderSizePixel = 0
        BgPaletteButton.Text = ""
        BgPaletteButton.ZIndex = 4
        BgPaletteButton:SetAttribute("PaletteColor", BgPaletteColor)
        guiCorner(BgPaletteButton, 3)
        BgPaletteButtons[BgPaletteIndex] = BgPaletteButton
        bindBgPaletteButton(BgPaletteButton)
        BgPaletteIndex = BgPaletteIndex + 1
    end

    function updateBgButtons(index)
        tw(BtnNone, {BackgroundTransparency = index == 0 and 0.2 or 0.6})
        StrokeNone.Color = index == 0 and C.accent or C.divider
        Stroke1.Color = index == 1 and C.accent or C.divider
        Stroke2.Color = index == 2 and C.accent or C.divider
        Stroke3.Color = index == 3 and C.accent or C.divider
        Stroke4.Color = index == 4 and C.accent or C.divider
        Stroke5.Color = index == 5 and C.accent or C.divider
    end

    function selectBackgroundIndex(index)
        index = math.clamp(index, 0, 5)
        State.backgroundIndex = index
        State.backgroundEnabled = index ~= 0
        if GuiRefs.backgroundImage then
            GuiRefs.backgroundImage.Visible = index ~= 0
            if index ~= 0 then
                GuiRefs.backgroundImage.Image = "rbxassetid://" .. BG_IMAGES[index]
            end
        end
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = index == 0 end
        syncV2Background(index)
        updateBgButtons(index)
        scheduleAutoSave()
        syncAuxBackgrounds()
    end

    BgLeft.MouseButton1Click:Connect(function()
        selectBackgroundIndex((State.backgroundIndex or 0) - 1)
    end)
    BgRight.MouseButton1Click:Connect(function()
        selectBackgroundIndex((State.backgroundIndex or 0) + 1)
    end)

    BtnNone.MouseButton1Click:Connect(function()
        State.backgroundIndex = 0
        State.backgroundEnabled = false
        if GuiRefs.backgroundImage then GuiRefs.backgroundImage.Visible = false end
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = true end
        syncV2Background(0)
        updateBgButtons(0)
        scheduleAutoSave()
        syncAuxBackgrounds()
    end)
    Btn1.MouseButton1Click:Connect(function()
        State.backgroundIndex = 1
        State.backgroundEnabled = true
        if GuiRefs.backgroundImage then GuiRefs.backgroundImage.Image = "rbxassetid://" .. BG_IMAGES[1]; GuiRefs.backgroundImage.Visible = true end
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = false end
        syncV2Background(1)
        updateBgButtons(1)
        scheduleAutoSave()
        syncAuxBackgrounds()
    end)
    Btn2.MouseButton1Click:Connect(function()
        State.backgroundIndex = 2
        State.backgroundEnabled = true
        if GuiRefs.backgroundImage then GuiRefs.backgroundImage.Image = "rbxassetid://" .. BG_IMAGES[2]; GuiRefs.backgroundImage.Visible = true end
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = false end
        syncV2Background(2)
        updateBgButtons(2)
        scheduleAutoSave()
        syncAuxBackgrounds()
    end)
    Btn3.MouseButton1Click:Connect(function()
        State.backgroundIndex = 3
        State.backgroundEnabled = true
        if GuiRefs.backgroundImage then GuiRefs.backgroundImage.Image = "rbxassetid://" .. BG_IMAGES[3]; GuiRefs.backgroundImage.Visible = true end
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = false end
        syncV2Background(3)
        updateBgButtons(3)
        scheduleAutoSave()
        syncAuxBackgrounds()
    end)
    Btn4.MouseButton1Click:Connect(function()
        State.backgroundIndex = 4
        State.backgroundEnabled = true
        if GuiRefs.backgroundImage then GuiRefs.backgroundImage.Image = "rbxassetid://" .. BG_IMAGES[4]; GuiRefs.backgroundImage.Visible = true end
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = false end
        syncV2Background(4)
        updateBgButtons(4)
        scheduleAutoSave()
        syncAuxBackgrounds()
    end)
    Btn5.MouseButton1Click:Connect(function()
        State.backgroundIndex = 5
        State.backgroundEnabled = true
        if GuiRefs.backgroundImage then GuiRefs.backgroundImage.Image = "rbxassetid://" .. BG_IMAGES[5]; GuiRefs.backgroundImage.Visible = true end
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = false end
        syncV2Background(5)
        updateBgButtons(5)
        scheduleAutoSave()
        syncAuxBackgrounds()
    end)

    BgRow.MouseEnter:Connect(function() tw(BgRow, {BackgroundTransparency=0.3}) end)
    BgRow.MouseLeave:Connect(function() tw(BgRow, {BackgroundTransparency=0.6}) end)

    addSectionLabel(vi, "VISUAL", 2)

    local _, fovBox = addInputRow(vi, "FOV", State.fov, 5, function(v)
        local clamped = math.clamp(math.floor(v), 70, 120)
        State.fov = clamped
        pcall(function() workspace.CurrentCamera.FieldOfView = clamped end)
        scheduleAutoSave()
    end)

    addCycleRow(vi, "Custom Sky", getSkyModeText(), 8, function()
        nextSkyMode()
        return getSkyModeText()
    end)

    addToggleRow(vi, "Stretch Rez", State.stretchResEnabled, 6, nil, function(on)
        setStretchRes(on)
    end)
    
    addToggleRow(vi, "FPS Boost", State.fpsBoostEnabled, 7, nil, function(on)
        State.fpsBoostEnabled = on
        if on then applyFPSBoost() else disableFPSBoost() end
        scheduleAutoSave()
    end)

    addCycleRow(vi, "Tenue", State.outfit, 9, function()
        local nextOutfit = {
            Off = "Tenue 1",
            ["Tenue 1"] = "Tenue 2",
            ["Tenue 2"] = "Tenue 3",
            ["Tenue 3"] = "Tenue 4",
            ["Tenue 4"] = "Tenue 5",
            ["Tenue 5"] = "Off",
        }
        State.outfit = nextOutfit[State.outfit] or "Off"
        local ok, err = Outfit.set(State.outfit)
        if not ok then
            warn("Space Hub Outfit: " .. tostring(err))
        end
        scheduleAutoSave()
        return State.outfit
    end)

    if State.korbloxEnabled then
        task.defer(function()
            Korblox.apply()
        end)
    end

    addCycleRow(vi, "Animation Pack", State.animationPack, 10, function()
        return Anim.next()
    end)

end


local floatingButtonsContainer = nil
local floatingButtonsGui = nil
local quickBtnSetters = {}

do
    local sg = GuiRefs.categoryRefs.contents["Settings"]
    addSectionLabel(sg, "SETTINGS", 0)
    addToggleRow(sg, "Side Buttons", State.floatingBtnsVisible, 1, nil, function(on)
        State.floatingBtnsVisible = on
        if floatingButtonsContainer then floatingButtonsContainer.Visible = on end
        scheduleAutoSave()
    end)
    addToggleRow(sg, "Bypass GUI", State.bypassGuiVisible, 2, nil, function(on)
        State.bypassGuiVisible = on
        if BypassGuiRef then BypassGuiRef.Enabled = on end
        scheduleAutoSave()
    end)
    addToggleRow(sg, "Lagger GUI", State.laggerGuiVisible, 3, nil, function(on)
        State.laggerGuiVisible = on
        if LaggerGuiRef then LaggerGuiRef.Enabled = on end
        scheduleAutoSave()
    end)

    addSectionLabel(sg, "SPACE FLAT UI", 4)
    
    

    addCycleRow(sg, "Custom Progress Bar", CustomProgressBarVersion, 6, function()
        if CustomProgressBarVersion == "V1" then
            CustomProgressBarVersion = "V2"
        elseif CustomProgressBarVersion == "V2" then
            CustomProgressBarVersion = "V3"
        else
            CustomProgressBarVersion = "V1"
        end
        if State.autoGrabEnabled then
            local current = CoreGui:FindFirstChild("SpaceProgressBar")
            if current then current:Destroy() end
            createProgressBar()
        end
        scheduleAutoSave()
        return CustomProgressBarVersion
    end)

    StealSizeRow = Instance.new("Frame", sg)
    StealSizeRow.Size = UDim2.new(1, 0, 0, 44)
    StealSizeRow.BackgroundColor3 = C.row
    StealSizeRow.BackgroundTransparency = 0.6
    StealSizeRow.BorderSizePixel = 0
    StealSizeRow.LayoutOrder = 7
    guiCorner(StealSizeRow, 8)
    guiStroke(StealSizeRow, C.divider, 0.5)

    StealSizeLabel = Instance.new("TextLabel", StealSizeRow)
    StealSizeLabel.Position = UDim2.new(0, 13, 0, 0)
    StealSizeLabel.Size = UDim2.new(0.43, 0, 0, 44)
    StealSizeLabel.BackgroundTransparency = 1
    StealSizeLabel.Text = "Steal Bar Size"
    StealSizeLabel.TextColor3 = C.text
    StealSizeLabel.TextSize = 10
    StealSizeLabel.Font = Enum.Font.GothamBold
    StealSizeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local function makeStealSizeButton(text, x)
        local button = Instance.new("TextButton", StealSizeRow)
        button.Position = UDim2.new(1, x, 0, 8)
        button.Size = UDim2.new(0, 29, 0, 27)
        button.BackgroundColor3 = C.input
        button.BackgroundTransparency = 0.25
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = C.text
        button.TextSize = 13
        button.Font = Enum.Font.GothamBold
        button.AutoButtonColor = false
        guiCorner(button, 7)
        guiStroke(button, C.divider, 0.5)
        return button
    end

    StealSizeMinusButton = makeStealSizeButton("-", -174)
    StealSizeValueLabel = Instance.new("TextLabel", StealSizeRow)
    StealSizeValueLabel.Position = UDim2.new(1, -141, 0, 8)
    StealSizeValueLabel.Size = UDim2.new(0, 102, 0, 27)
    StealSizeValueLabel.BackgroundColor3 = C.input
    StealSizeValueLabel.BackgroundTransparency = 0.25
    StealSizeValueLabel.BorderSizePixel = 0
    StealSizeValueLabel.TextColor3 = C.text
    StealSizeValueLabel.TextSize = 10
    StealSizeValueLabel.Font = Enum.Font.GothamBold
    StealSizeValueLabel.TextXAlignment = Enum.TextXAlignment.Center
    StealSizeValueLabel.TextYAlignment = Enum.TextYAlignment.Center
    guiCorner(StealSizeValueLabel, 7)
    guiStroke(StealSizeValueLabel, C.divider, 0.5)

    StealSizePlusButton = makeStealSizeButton("+", -35)

    function updateStealSizeLabel()
        StealSizeValueLabel.Text = string.format("%.2fx", StealBarSize)
    end

    function setStealBarSize(delta)
        StealBarSize = math.clamp(
            math.floor((StealBarSize + delta) * 100 + 0.5) / 100,
            0.75,
            1.5
        )
        updateStealSizeLabel()
        if State.autoGrabEnabled then
            local current = CoreGui:FindFirstChild("SpaceProgressBar")
            if current then current:Destroy() end
            createProgressBar()
        end
        scheduleAutoSave()
    end

    updateStealSizeLabel()
    StealSizeMinusButton.MouseButton1Click:Connect(function()
        setStealBarSize(-0.05)
    end)
    StealSizePlusButton.MouseButton1Click:Connect(function()
        setStealBarSize(0.05)
    end)

    local guiRow = Instance.new("Frame")
    guiRow.Size = UDim2.new(1, 0, 0, 38)
    guiRow.BackgroundColor3 = C.row
    guiRow.BackgroundTransparency = 0.6
    guiRow.BorderSizePixel = 0
    guiRow.LayoutOrder = 8
    guiRow.Parent = sg
    guiCorner(guiRow, 8)
    guiStroke(guiRow, C.divider, 0.5)

    local guiRowLbl = Instance.new("TextLabel", guiRow)
    guiRowLbl.Size = UDim2.new(0.6, 0, 0, 14)
    guiRowLbl.Position = UDim2.new(0, 10, 0, 7)
    guiRowLbl.BackgroundTransparency = 1
    guiRowLbl.Text = "Hide GUI Key"
    guiRowLbl.TextColor3 = C.text
    guiRowLbl.TextSize = 10
    guiRowLbl.Font = Enum.Font.GothamBold
    guiRowLbl.TextXAlignment = Enum.TextXAlignment.Left

    local guiKBtn = Instance.new("TextButton", guiRow)
    guiKBtn.Size = UDim2.new(0, 40, 0, 20)
    guiKBtn.Position = UDim2.new(1, -48, 0.5, -10)
    guiKBtn.BackgroundColor3 = C.accent
    guiKBtn.BackgroundTransparency = 0.5
    guiKBtn.BorderSizePixel = 0
    guiKBtn.Text = prettyKeyName(Keys.guiHide)
    guiKBtn.TextColor3 = C.text
    guiKBtn.TextSize = 8
    guiKBtn.Font = Enum.Font.GothamBold
    guiCorner(guiKBtn, 4)
    
    guiKBtn.MouseButton1Click:Connect(function()
        startKeyListen(guiKBtn, function(newKey)
            Keys.guiHide = newKey
            guiKBtn.Text = prettyKeyName(newKey)
            scheduleAutoSave()
        end)
    end)

    local guiHover = Instance.new("TextButton", guiRow)
    guiHover.Size = UDim2.new(1, 0, 1, 0)
    guiHover.BackgroundTransparency = 1
    guiHover.Text = ""
    guiHover.ZIndex = 0
    guiHover.MouseEnter:Connect(function() tw(guiRow, {BackgroundTransparency=0.3}) end)
    guiHover.MouseLeave:Connect(function() tw(guiRow, {BackgroundTransparency=0.6}) end)

end


function updateScrollSize()
    task.wait(0.1)
    local cf = GuiRefs.contentFrame
    if not cf then return end
    cf.ScrollingEnabled = true
    cf.ScrollBarThickness = 3
    cf.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    cf.ScrollBarImageTransparency = 0.5
    local layout = cf:FindFirstChildWhichIsA("UIListLayout")
    if layout then
        local totalHeight = 0
        for _, child in ipairs(cf:GetChildren()) do
            if child:IsA("Frame") and child.Visible then
                totalHeight = totalHeight + child.Size.Y.Offset + 6
            end
        end
        local canvasHeight = math.max(totalHeight, layout.AbsoluteContentSize.Y) + 50
        cf.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            local newHeight = layout.AbsoluteContentSize.Y + 50
            if newHeight > cf.CanvasSize.Y.Offset then cf.CanvasSize = UDim2.new(0, 0, 0, newHeight) end
        end)
    end
end

function fixAllPages()
    if GuiRefs.categoryRefs then
        for name, page in pairs(GuiRefs.categoryRefs.contents or {}) do
            if page then
                task.spawn(function()
                    task.wait(0.1)
                    local layout = page:FindFirstChildWhichIsA("UIListLayout")
                    if layout then
                        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                            task.wait(0.05)
                            updateScrollSize()
                        end)
                    end
                end)
            end
        end
    end
end

task.spawn(function()
    task.wait(0.3)
    updateScrollSize()
    fixAllPages()
    if GuiRefs.categoryRefs and GuiRefs.categoryRefs.btnsBottom then
        for name, btn in pairs(GuiRefs.categoryRefs.btnsBottom) do
            btn.MouseButton1Click:Connect(function()
                task.wait(0.2)
                updateScrollSize()
            end)
        end
    end
    while true do task.wait(2); updateScrollSize() end
end)


function createFloatingButtons()
    local BG_OFF = Color3.fromRGB(0,0,0)
    local BG_ON  = Color3.fromRGB(38,38,38)
    local FONT_SZ = 8
    local BW, BH = 55, 55
    local GAP = 4
    local CORNER = UDim.new(0,12)

    if floatingButtonsGui then floatingButtonsGui:Destroy() end

    
    
    floatingButtonsGui = Instance.new("ScreenGui")
    floatingButtonsGui.Name = "SpaceFloatingButtons"
    floatingButtonsGui.ResetOnSpawn = false
    floatingButtonsGui.IgnoreGuiInset = true
    floatingButtonsGui.DisplayOrder = 20
    floatingButtonsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    floatingButtonsGui.Parent = PlayerGui

    floatingButtonsContainer = Instance.new("Frame", floatingButtonsGui)
    floatingButtonsContainer.Name = "FloatingButtonsContainer"
    floatingButtonsContainer.Size = UDim2.new(1,0,1,0)
    floatingButtonsContainer.BackgroundTransparency = 1
    floatingButtonsContainer.BorderSizePixel = 0
    floatingButtonsContainer.ZIndex = 499
    floatingButtonsContainer.Visible = State.floatingBtnsVisible

    local POS_FILE = "SpaceHub_btnpos.json"
    local savedPos = {}
    pcall(function()
        if readfile then
            local ok, content = pcall(readfile, POS_FILE)
            if ok and content and content ~= "" then
                local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
                if ok2 and type(data) == "table" then savedPos = data end
            end
        end
    end)
    local function saveBtnPositions()
        task.spawn(function()
            pcall(function()
                if not writefile then return end
                writefile(POS_FILE, HttpService:JSONEncode(savedPos))
            end)
        end)
    end

    local vp = workspace.CurrentCamera.ViewportSize
    local COLS = 2
    local TOTAL_ROWS = 4
    local CONTENT_W = COLS*BW + (COLS-1)*GAP
    local CONTENT_H = TOTAL_ROWS*BH + (TOTAL_ROWS-1)*GAP
    local BASE_X = vp.X - CONTENT_W - 10
    local BASE_Y = vp.Y/2 - CONTENT_H/2

    local btnDefs = {
        {label="DROP\nBR",     key="DropBR",     row=0, col=0, toggle=false,
            press=function() task.spawn(runDropBrainrot) end},
        {label="AUTO\nBAT",    key="Lock",       row=0, col=1, toggle=true,
            get=function() return State.autoBatToggled end,
            set=function(v) setSelectedAutoBatState(v) end},
        {label="TP\nDOWN",     key="TpDown",     row=1, col=0, toggle=false,
            press=function() tpDown() end},
        {label="CARRY\nSPD",   key="CarrySpeed", row=1, col=1, toggle=true,
            get=function() return State.speedToggled end,
            set=function(v) State.speedToggled = v; scheduleAutoSave() end},
        {label="LAGGER\nMODE", key="Lag",        row=2, col=0, toggle=true,
            get=function() return State.laggerModeEnabled end,
            set=function(v) State.laggerModeEnabled = v; scheduleAutoSave(); if GuiToggleSetters["laggerToggle"] then GuiToggleSetters["laggerToggle"](v) end end},
        {label="INSTA\nRESET", key="InstaReset", row=2, col=1, toggle=false,
            press=function() runInstaReset() end},
        {label="TP\nBAT",      key="BatV2",      row=3, col=0, toggle=true,
            get=function() return State.tpBatEnabled end,
            set=function(v) State.tpBatEnabled = v; if v then startTpBat() else stopTpBat() end; if GuiToggleSetters["tpBat"] then GuiToggleSetters["tpBat"](v) end; scheduleAutoSave() end},
        {label="GRAB",         key="Grab",       row=3, col=1, toggle=true,
            get=function() return State.autoGrabEnabled end,
            set=function(v)
                State.autoGrabEnabled = v
                if v then
                    startAutoGrab()
                    createProgressBar()
                else
                    stopAutoGrab()
                end
                scheduleAutoSave()
            end},
    }

    for _, def in ipairs(btnDefs) do
        local defaultX = BASE_X + def.col * (BW + GAP)
        local defaultY = BASE_Y + def.row * (BH + GAP)
        local sp = savedPos[def.key]
        local initX = sp and sp.x or defaultX
        local initY = sp and sp.y or defaultY
        local initOn = def.toggle and def.get and def.get() or false

        local btn = Instance.new("TextButton", floatingButtonsContainer)
        btn.Size = UDim2.new(0, BW, 0, BH)
        btn.Position = UDim2.new(0, initX, 0, initY)
        btn.BackgroundColor3 = initOn and BG_ON or BG_OFF
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 500
        btn.Active = true
        Instance.new("UICorner", btn).CornerRadius = CORNER
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = Color3.fromRGB(55,55,55)
        bStroke.Thickness = 0.5

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = def.label
        lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = FONT_SZ
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.TextWrapped = true
        lbl.ZIndex = 501

        local function setVis(v)
            btn.BackgroundColor3 = v and BG_ON or BG_OFF
            bStroke.Color = v and Color3.fromRGB(180,180,180) or Color3.fromRGB(55,55,55)
        end
        quickBtnSetters[def.key] = setVis

        local dragging = false
        local dragStartInput = nil
        local dragStartPos = nil
        local touchMoved = false

        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                touchMoved = false
                dragStartInput = Vector2.new(inp.Position.X, inp.Position.Y)
                dragStartPos = Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset)
            end
        end)
        btn.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStartInput
                if delta.Magnitude > 6 then touchMoved = true end
                if touchMoved then
                    local vp2 = workspace.CurrentCamera.ViewportSize
                    local newX = math.clamp(dragStartPos.X + delta.X, 0, vp2.X - BW)
                    local newY = math.clamp(dragStartPos.Y + delta.Y, 0, vp2.Y - BH)
                    btn.Position = UDim2.new(0, newX, 0, newY)
                end
            end
        end)
        btn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                savedPos[def.key] = {x = btn.Position.X.Offset, y = btn.Position.Y.Offset}
                saveBtnPositions()
                if not touchMoved then
                    if def.toggle then
                        local newVal = not (def.get and def.get() or false)
                        if def.set then def.set(newVal) end
                        setVis(newVal)
                    else
                        if def.press then def.press() end
                        TweenService:Create(btn, TweenInfo.new(0.07), {BackgroundColor3=Color3.fromRGB(40,40,40)}):Play()
                        task.delay(0.18, function()
                            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=BG_OFF}):Play()
                        end)
                    end
                end
                touchMoved = false
            end
        end)

        def._btn = btn
    end
end

createFloatingButtons()


UIS.InputBegan:Connect(function(inp, gp)
    local keyCode = inp.KeyCode
    if (gp and keyCode ~= Enum.KeyCode.Space) or KeyListen.active then return end

    if keyCode == Keys.guiHide then
        State.guiVisible = not State.guiVisible
        if SpaceHubActiveCustomUI == "V2" then
            if SpaceHubActiveV2Gui then
                SpaceHubActiveV2Gui.Enabled = State.guiVisible
            end
        elseif SpaceHubActiveCustomUI == "V3" then
            if SpaceHubActiveV3Gui then
                SpaceHubActiveV3Gui.Enabled = State.guiVisible
            end
        elseif SpaceHubActiveCustomUI == "V4" then
            if SpaceHubActiveV4Gui then
                SpaceHubActiveV4Gui.Enabled = State.guiVisible
            end
        else
            if GuiRefs.outer then GuiRefs.outer.Visible = State.guiVisible end
            if closeBtnRef then closeBtnRef.Visible = State.guiVisible end
        end
        if not State.guiVisible and topBarRef then topBarRef.Visible = true end
        if State.guiVisible and topBarRef then topBarRef.Visible = false end
    elseif keyCode == Keys.speed then
        State.speedToggled = not State.speedToggled
        scheduleAutoSave()
        if quickBtnSetters["CarrySpeed"] then quickBtnSetters["CarrySpeed"](State.speedToggled) end
        if GuiToggleSetters["speedMode"] then
            GuiToggleSetters["speedMode"](State.speedToggled and "Carry" or "Normal")
        end
    elseif keyCode == Keys.autoBat then
        setSelectedAutoBatState(not (State.autoBatVersion == "V2" and State.autoBatV2Enabled or autoBatEnabled))
    elseif keyCode == Keys.tpBat then
        State.tpBatEnabled = not State.tpBatEnabled
        if State.tpBatEnabled then startTpBat() else stopTpBat() end
        if GuiToggleSetters["tpBat"] then GuiToggleSetters["tpBat"](State.tpBatEnabled) end
        scheduleAutoSave()
    elseif keyCode == Keys.dropBrainrot then
        runDropBrainrot()
    elseif keyCode == Keys.tpDown then
        tpDown()
    elseif keyCode == Keys.instaReset then
        runInstaReset()
    elseif keyCode == Keys.laggerToggle then
        State.laggerModeEnabled = not State.laggerModeEnabled
        scheduleAutoSave()
        if quickBtnSetters["Lag"] then quickBtnSetters["Lag"](State.laggerModeEnabled) end
        if GuiToggleSetters["laggerToggle"] then GuiToggleSetters["laggerToggle"](State.laggerModeEnabled) end
    end
end)


do
    
    
    DisableCanCollideTrackedPlayers = DisableCanCollideTrackedPlayers or {}

    function DisableCanCollidePart(part)
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide=false end
    end
    function DisableCanCollideTrackCharacter(character)
        DisableCanCollideParts = character:GetChildren()
        DisableCanCollidePartIndex = 1
        while DisableCanCollideParts[DisableCanCollidePartIndex] do
            DisableCanCollidePart(DisableCanCollideParts[DisableCanCollidePartIndex])
            DisableCanCollidePartIndex = DisableCanCollidePartIndex + 1
        end
        character.ChildAdded:Connect(function(child) DisableCanCollidePart(child) end)
    end
    function DisableCanCollideTrackPlayer(player)
        if player==LP then return end
        if player.Character then DisableCanCollideTrackCharacter(player.Character) end
        player.CharacterAdded:Connect(DisableCanCollideTrackCharacter)
        DisableCanCollideTrackedPlayers[player]=true
    end
    DisableCanCollidePlayerList = Players:GetPlayers()
    DisableCanCollideIndex = 1
    while DisableCanCollidePlayerList[DisableCanCollideIndex] do
        DisableCanCollideTrackPlayer(DisableCanCollidePlayerList[DisableCanCollideIndex])
        DisableCanCollideIndex = DisableCanCollideIndex + 1
    end
    Players.PlayerAdded:Connect(DisableCanCollideTrackPlayer)
    RunService.RenderStepped:Connect(function()
        
        
        
        DisableCanCollideIterator = next(DisableCanCollideTrackedPlayers)
        while DisableCanCollideIterator do
            DisableCanCollidePlayer = DisableCanCollideIterator
            DisableCanCollideCharacter = DisableCanCollidePlayer.Character
            if DisableCanCollideCharacter then
                DisableCanCollideParts = DisableCanCollideCharacter:GetChildren()
                DisableCanCollidePartIndex = 1
                while DisableCanCollideParts[DisableCanCollidePartIndex] do
                    DisableCanCollidePart(DisableCanCollideParts[DisableCanCollidePartIndex])
                    DisableCanCollidePartIndex = DisableCanCollidePartIndex + 1
                end
            end
            DisableCanCollideIterator =
                next(DisableCanCollideTrackedPlayers, DisableCanCollideIterator)
        end
    end)
end


function createSpeedBypassGUI()
    local SBState = {
        running = false,
        bomb = nil,
        spamThread = nil,
        activeMode = BypassSettings.activeMode,
    }
    local VERSION_WAIT = {V1 = 0.1265, V2 = 0.12}
    local SBUI = {}
    
    local function buildBomb(power, depth)
        local mt = {}
        local st = {}
        table.insert(st, {})
        local z = st[1]
        for i = 1, depth do local t = {}; table.insert(z, t); z = t end
        for i = 1, math.floor(power / (depth + 2)) do table.insert(mt, st) end
        return mt
    end
    
    local function startBypass()
        if SBState.running then return end
        SBState.running = true
        NetworkClient:SetOutgoingKBPSLimit(math.huge)
        local power = SBState.activeMode == "MOBILE" and 72000 or BypassSettings.power
        SBState.bomb = buildBomb(power, 296)
        local waitTime = VERSION_WAIT[BypassSettings.version]
        SBState.spamThread = task.spawn(function()
            while SBState.running do
                pcall(function() game.RobloxReplicatedStorage.SetPlayerBlockList:FireServer(SBState.bomb) end)
                task.wait(waitTime)
            end
        end)
        if SBUI.statusText then
            SBUI.statusText.Text = "STATUS: ACTIVE"
            SBUI.statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if SBUI.pillBg and SBUI.dot then
            SBUI.pillBg.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
            SBUI.dot.Position = UDim2.new(1, -17, 0.5, -7)
            SBUI.dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    local function stopBypass()
        if not SBState.running then return end
        SBState.running = false
        if SBState.spamThread then task.cancel(SBState.spamThread) end
        SBState.bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
        if SBUI.statusText then
            SBUI.statusText.Text = "STATUS: IDLE"
            SBUI.statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if SBUI.pillBg and SBUI.dot then
            SBUI.pillBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            SBUI.dot.Position = UDim2.new(0, 3, 0.5, -7)
            SBUI.dot.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        end
    end
    
    local function toggleBypass()
        if SBState.running then stopBypass() else startBypass() end
    end
    
    local function restartBypass()
        if SBState.running then stopBypass(); task.wait(0.1); startBypass() end
    end
    
    local function updateUI()
        if SBUI.powerValue then SBUI.powerValue.Text = tostring(BypassSettings.power) end
        if SBUI.hotkeyBtn then SBUI.hotkeyBtn.Text = BypassSettings.keybind end
        if SBUI.statusText then
            SBUI.statusText.Text = SBState.running and "STATUS: ACTIVE" or "STATUS: IDLE"
            SBUI.statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if SBUI.pillBg and SBUI.dot then
            local on = SBState.running
            SBUI.pillBg.BackgroundColor3 = on and Color3.fromRGB(60, 60, 65) or Color3.fromRGB(25, 25, 30)
            SBUI.dot.Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            SBUI.dot.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(55, 55, 60)
        end
        if SBUI.optionContainer then
            SBUI.optionContainer.Visible = (SBState.activeMode == "MOBILE")
        end
    end
    
    local bg = Instance.new("ScreenGui")
    bg.Name = "SpaceBypass"
    bg.ResetOnSpawn = false
    bg.Enabled = State.bypassGuiVisible
    bg.Parent = PlayerGui
    BypassGuiRef = bg
    
    local main = Instance.new("Frame", bg)
    main.Size = UDim2.fromOffset(230, 145)
    main.Position = UDim2.new(1, -245, 0.5, -72)
    main.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    
    
    main.BackgroundTransparency = 0.32
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.ZIndex = 1
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = Color3.fromRGB(255, 255, 255)
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.3
    makeDraggable(main)

    
    local auxBg = Instance.new("ImageLabel", main)
    auxBg.Name = "SpaceBackground"
    auxBg.Size = UDim2.fromScale(1, 1)
    auxBg.BackgroundTransparency = 1
    auxBg.Image = ""
    auxBg.ScaleType = Enum.ScaleType.Crop
    auxBg.ImageTransparency = 0.08
    auxBg.ZIndex = 1
    auxBg.Visible = false
    Instance.new("UICorner", auxBg).CornerRadius = UDim.new(0, 12)
    BypassBgImage = auxBg

    local auxGrad = Instance.new("Frame", main)
    auxGrad.Name = "SpaceBackgroundGradient"
    auxGrad.Size = UDim2.fromScale(1, 1)
    auxGrad.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    auxGrad.BackgroundTransparency = 0
    auxGrad.BorderSizePixel = 0
    auxGrad.ZIndex = 0
    auxGrad.Visible = true
    Instance.new("UICorner", auxGrad).CornerRadius = UDim.new(0, 12)
    local auxGradient = Instance.new("UIGradient", auxGrad)
    auxGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 38)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(9, 9, 12)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 2, 4)),
    })
    auxGradient.Rotation = 135
    BypassBgGrad = auxGrad
    
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(0, 125, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "SPACE BYPASS"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 2
    
    local subTitle = Instance.new("TextLabel", main)
    subTitle.Size = UDim2.new(0, 120, 0, 10)
    subTitle.Position = UDim2.new(0, 10, 0, 22)
    subTitle.BackgroundTransparency = 1
    subTitle.Text = "discord.gg/spaceduels"
    subTitle.TextColor3 = Color3.fromRGB(80, 80, 85)
    subTitle.Font = Enum.Font.GothamBold
    subTitle.TextSize = 7
    subTitle.TextXAlignment = Enum.TextXAlignment.Left
    subTitle.ZIndex = 2
    
    local sep = Instance.new("Frame", main)
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Position = UDim2.new(0, 10, 0, 34)
    sep.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sep.BorderSizePixel = 0
    sep.ZIndex = 2
    
    local statusText = Instance.new("TextLabel", main)
    statusText.Size = UDim2.new(1, -20, 0, 22)
    statusText.Position = UDim2.new(0, 10, 0, 38)
    statusText.BackgroundTransparency = 1
    statusText.Text = "STATUS: IDLE"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 9
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.ZIndex = 2
    SBUI.statusText = statusText
    
    local sep2 = Instance.new("Frame", main)
    sep2.Size = UDim2.new(1, -20, 0, 1)
    sep2.Position = UDim2.new(0, 10, 0, 52)
    sep2.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sep2.BorderSizePixel = 0
    sep2.ZIndex = 2
    
    local modeContainer = Instance.new("Frame", main)
    modeContainer.Size = UDim2.new(0, 100, 0, 22)
    modeContainer.Position = UDim2.new(0, 10, 0, 58)
    modeContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    modeContainer.BorderSizePixel = 0
    modeContainer.ZIndex = 2
    Instance.new("UICorner", modeContainer).CornerRadius = UDim.new(0, 6)
    local modeStroke = Instance.new("UIStroke", modeContainer)
    modeStroke.Color = Color3.fromRGB(30, 30, 35)
    modeStroke.Thickness = 1
    
    local pcBtn = Instance.new("TextButton", modeContainer)
    pcBtn.Size = UDim2.new(0.5, 0, 1, 0)
    pcBtn.Position = UDim2.new(0, 0, 0, 0)
    pcBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    pcBtn.BackgroundTransparency = 0
    pcBtn.BorderSizePixel = 0
    pcBtn.Text = "PC"
    pcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pcBtn.Font = Enum.Font.GothamBold
    pcBtn.TextSize = 8
    pcBtn.ZIndex = 3
    Instance.new("UICorner", pcBtn).CornerRadius = UDim.new(0, 6)
    
    local mobileBtn = Instance.new("TextButton", modeContainer)
    mobileBtn.Size = UDim2.new(0.5, 0, 1, 0)
    mobileBtn.Position = UDim2.new(0.5, 0, 0, 0)
    mobileBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    mobileBtn.BackgroundTransparency = 0
    mobileBtn.BorderSizePixel = 0
    mobileBtn.Text = "MOBILE"
    mobileBtn.TextColor3 = Color3.fromRGB(80, 80, 85)
    mobileBtn.Font = Enum.Font.GothamBold
    mobileBtn.TextSize = 8
    mobileBtn.ZIndex = 3
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(0, 6)
    
    local function setMode(mode)
        SBState.activeMode = mode
        BypassSettings.activeMode = mode
        if mode == "PC" then
            pcBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            pcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            mobileBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            mobileBtn.TextColor3 = Color3.fromRGB(80, 80, 85)
            if SBUI.optionContainer then SBUI.optionContainer.Visible = false end
            if SBUI.hotkeyLabel then SBUI.hotkeyLabel.Visible = true end
            if SBUI.hotkeyBtn then SBUI.hotkeyBtn.Visible = true end
        else
            mobileBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            pcBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            pcBtn.TextColor3 = Color3.fromRGB(80, 80, 85)
            if SBUI.optionContainer then SBUI.optionContainer.Visible = true end
            if SBUI.hotkeyLabel then SBUI.hotkeyLabel.Visible = false end
            if SBUI.hotkeyBtn then SBUI.hotkeyBtn.Visible = false end
        end
        restartBypass()
        updateUI()
        scheduleAutoSave()
    end
    
    pcBtn.MouseButton1Click:Connect(function() setMode("PC") end)
    mobileBtn.MouseButton1Click:Connect(function() setMode("MOBILE") end)
    
    local powerLabel = Instance.new("TextLabel", main)
    powerLabel.Size = UDim2.new(0, 100, 0, 12)
    powerLabel.Position = UDim2.new(0, 120, 0, 58)
    powerLabel.BackgroundTransparency = 1
    powerLabel.Text = "POWER VALUE"
    powerLabel.TextColor3 = Color3.fromRGB(80, 80, 85)
    powerLabel.Font = Enum.Font.GothamBold
    powerLabel.TextSize = 9
    powerLabel.TextXAlignment = Enum.TextXAlignment.Left
    powerLabel.ZIndex = 2
    
    local powerContainer = Instance.new("Frame", main)
    powerContainer.Size = UDim2.new(0, 100, 0, 26)
    powerContainer.Position = UDim2.new(0, 120, 0, 72)
    powerContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    powerContainer.BorderSizePixel = 0
    powerContainer.ZIndex = 2
    Instance.new("UICorner", powerContainer).CornerRadius = UDim.new(0, 6)
    local powerStroke = Instance.new("UIStroke", powerContainer)
    powerStroke.Color = Color3.fromRGB(30, 30, 35)
    powerStroke.Thickness = 1
    
    local minusBtn = Instance.new("TextButton", powerContainer)
    minusBtn.Size = UDim2.new(0, 30, 1, 0)
    minusBtn.Position = UDim2.new(0, 0, 0, 0)
    minusBtn.BackgroundTransparency = 1
    minusBtn.Text = "-"
    minusBtn.TextColor3 = Color3.fromRGB(150, 150, 155)
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 18
    minusBtn.ZIndex = 3
    minusBtn.MouseButton1Click:Connect(function()
        BypassSettings.power = math.max(10000, BypassSettings.power - 2000)
        if SBUI.powerValue then SBUI.powerValue.Text = tostring(BypassSettings.power) end
        restartBypass()
        scheduleAutoSave()
    end)
    
    local powerVal = Instance.new("TextBox", powerContainer)
    powerVal.Size = UDim2.new(1, -60, 1, 0)
    powerVal.Position = UDim2.new(0, 30, 0, 0)
    powerVal.BackgroundTransparency = 1
    powerVal.Text = tostring(BypassSettings.power)
    powerVal.TextColor3 = Color3.fromRGB(255, 255, 255)
    powerVal.Font = Enum.Font.GothamBlack
    powerVal.TextSize = 12
    powerVal.TextXAlignment = Enum.TextXAlignment.Center
    powerVal.ZIndex = 3
    powerVal.ClearTextOnFocus = false
    SBUI.powerValue = powerVal

    powerVal.FocusLost:Connect(function()
        local num = tonumber(powerVal.Text)
        if num then
            num = math.clamp(math.floor(num), 10000, 120000)
            BypassSettings.power = num
            powerVal.Text = tostring(num)
            restartBypass()
            updateUI()
            scheduleAutoSave()
        else
            powerVal.Text = tostring(BypassSettings.power)
        end
    end)

    local powerClickArea = Instance.new("TextButton", powerContainer)
    powerClickArea.Size = UDim2.new(1, -60, 1, 0)
    powerClickArea.Position = UDim2.new(0, 30, 0, 0)
    powerClickArea.BackgroundTransparency = 1
    powerClickArea.Text = ""
    powerClickArea.ZIndex = 4
    powerClickArea.MouseButton1Click:Connect(function() powerVal:CaptureFocus() end)
    powerClickArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then powerVal:CaptureFocus() end
    end)
    
    local plusBtn = Instance.new("TextButton", powerContainer)
    plusBtn.Size = UDim2.new(0, 30, 1, 0)
    plusBtn.Position = UDim2.new(1, -30, 0, 0)
    plusBtn.BackgroundTransparency = 1
    plusBtn.Text = "+"
    plusBtn.TextColor3 = Color3.fromRGB(150, 150, 155)
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 18
    plusBtn.ZIndex = 3
    plusBtn.MouseButton1Click:Connect(function()
        BypassSettings.power = math.min(120000, BypassSettings.power + 2000)
        if SBUI.powerValue then SBUI.powerValue.Text = tostring(BypassSettings.power) end
        restartBypass()
        scheduleAutoSave()
    end)
    
    local optionContainer = Instance.new("Frame", main)
    optionContainer.Size = UDim2.new(1, 0, 0, 30)
    optionContainer.Position = UDim2.new(0, 0, 0, 106)
    optionContainer.BackgroundTransparency = 1
    optionContainer.BorderSizePixel = 0
    optionContainer.ZIndex = 2
    SBUI.optionContainer = optionContainer
    optionContainer.Visible = (SBState.activeMode == "MOBILE")
    
    local optionText = Instance.new("TextLabel", optionContainer)
    optionText.Size = UDim2.new(0.6, -12, 1, 0)
    optionText.Position = UDim2.new(0, 12, 0, 0)
    optionText.BackgroundTransparency = 1
    optionText.Text = "Click To Activate"
    optionText.TextColor3 = Color3.fromRGB(80, 80, 85)
    optionText.Font = Enum.Font.GothamBold
    optionText.TextSize = 10
    optionText.TextXAlignment = Enum.TextXAlignment.Left
    optionText.ZIndex = 3
    
    local pillBg = Instance.new("Frame", optionContainer)
    pillBg.Size = UDim2.new(0, 40, 0, 20)
    pillBg.Position = UDim2.new(1, -52, 0.5, -10)
    pillBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    pillBg.BorderSizePixel = 0
    pillBg.ZIndex = 7
    Instance.new("UICorner", pillBg).CornerRadius = UDim.new(0, 10)
    local pillStroke = Instance.new("UIStroke", pillBg)
    pillStroke.Color = Color3.fromRGB(35, 35, 40)
    pillStroke.Thickness = 1
    SBUI.pillBg = pillBg
    
    local dot = Instance.new("Frame", pillBg)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, 3, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    dot.BorderSizePixel = 0
    dot.ZIndex = 8
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 7)
    SBUI.dot = dot
    
    local clickArea = Instance.new("TextButton", optionContainer)
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.Position = UDim2.new(0, 0, 0, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 4
    clickArea.MouseButton1Click:Connect(function() toggleBypass() end)
    
    local hotkeyLabel = Instance.new("TextLabel", main)
    hotkeyLabel.Size = UDim2.new(0, 50, 0, 12)
    hotkeyLabel.Position = UDim2.new(0, 10, 0, 104)
    hotkeyLabel.BackgroundTransparency = 1
    hotkeyLabel.Text = "HOTKEY"
    hotkeyLabel.TextColor3 = Color3.fromRGB(80, 80, 85)
    hotkeyLabel.Font = Enum.Font.GothamBold
    hotkeyLabel.TextSize = 9
    hotkeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    hotkeyLabel.ZIndex = 2
    SBUI.hotkeyLabel = hotkeyLabel
    hotkeyLabel.Visible = (SBState.activeMode == "PC")
    
    local hotkeyBtn = Instance.new("TextButton", main)
    hotkeyBtn.Size = UDim2.new(0, 70, 0, 22)
    hotkeyBtn.Position = UDim2.new(0, 68, 0, 118)
    hotkeyBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    hotkeyBtn.BorderSizePixel = 0
    hotkeyBtn.Text = BypassSettings.keybind
    hotkeyBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
    hotkeyBtn.Font = Enum.Font.GothamBold
    hotkeyBtn.TextSize = 10
    hotkeyBtn.ZIndex = 3
    Instance.new("UICorner", hotkeyBtn).CornerRadius = UDim.new(0, 6)
    local hotkeyStroke = Instance.new("UIStroke", hotkeyBtn)
    hotkeyStroke.Color = Color3.fromRGB(30, 30, 35)
    hotkeyStroke.Thickness = 1
    SBUI.hotkeyBtn = hotkeyBtn
    hotkeyBtn.Visible = (SBState.activeMode == "PC")
    
    hotkeyBtn.MouseButton1Click:Connect(function()
        startKeyListen(hotkeyBtn, function(nk)
            BypassSettings.keybind = nk.Name
            hotkeyBtn.Text = prettyKeyName(nk)
            updateUI()
            scheduleAutoSave()
        end)
    end)
    
    SBState.running = false
    updateUI()
    
    local bypassKeyConn
    bypassKeyConn = UIS.InputBegan:Connect(function(input, gp)
        if gp or KeyListen.active then return end
        if SBState.activeMode == "PC" and input.KeyCode.Name == BypassSettings.keybind then toggleBypass() end
    end)
    
    bg.AncestryChanged:Connect(function()
        if not bg.Parent then stopBypass(); bypassKeyConn:Disconnect() end
    end)
end


function createLaggerGUI()
    local LAGGER_PRESETS = {
        V1 = {power = 400000, wait = 0.34, depth = 296},
        V2 = {power = 55000, wait = 0.17, depth = 296}
    }
    local LaggerState = {
        running = false,
        bomb = nil,
        spamThread = nil,
        activeMode = "PC",
    }
    local SBUI = {}
    
    local function buildBomb(power, depth)
        local mt = {}
        local st = {}
        table.insert(st, {})
        local z = st[1]
        for i = 1, depth do local t = {}; table.insert(z, t); z = t end
        for i = 1, math.floor(power / (depth + 2)) do table.insert(mt, st) end
        return mt
    end
    
    local function startLagger()
        if LaggerState.running then return end
        LaggerState.running = true
        NetworkClient:SetOutgoingKBPSLimit(math.huge)
        local preset = LAGGER_PRESETS[LaggerSettings.version]
        LaggerState.bomb = buildBomb(preset.power, preset.depth)
        local waitTime = preset.wait
        LaggerState.spamThread = task.spawn(function()
            while LaggerState.running do
                pcall(function() game.RobloxReplicatedStorage.SetPlayerBlockList:FireServer(LaggerState.bomb) end)
                task.wait(waitTime)
            end
        end)
        if SBUI.statusText then
            SBUI.statusText.Text = "STATUS: ACTIVE"
            SBUI.statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if SBUI.pillBg and SBUI.dot then
            SBUI.pillBg.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
            SBUI.dot.Position = UDim2.new(1, -17, 0.5, -7)
            SBUI.dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    local function stopLagger()
        if not LaggerState.running then return end
        LaggerState.running = false
        if LaggerState.spamThread then task.cancel(LaggerState.spamThread) end
        LaggerState.bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
        if SBUI.statusText then
            SBUI.statusText.Text = "STATUS: IDLE"
            SBUI.statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if SBUI.pillBg and SBUI.dot then
            SBUI.pillBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            SBUI.dot.Position = UDim2.new(0, 3, 0.5, -7)
            SBUI.dot.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        end
    end
    
    local function toggleLagger()
        if LaggerState.running then stopLagger() else startLagger() end
    end
    
    local function restartLagger()
        if LaggerState.running then stopLagger(); task.wait(0.1); startLagger() end
    end
    
    local function updateUI()
        if SBUI.hotkeyBtn then SBUI.hotkeyBtn.Text = LaggerSettings.keybind end
        if SBUI.statusText then
            SBUI.statusText.Text = LaggerState.running and "STATUS: ACTIVE" or "STATUS: IDLE"
            SBUI.statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if SBUI.pillBg and SBUI.dot then
            local on = LaggerState.running
            SBUI.pillBg.BackgroundColor3 = on and Color3.fromRGB(60, 60, 65) or Color3.fromRGB(25, 25, 30)
            SBUI.dot.Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            SBUI.dot.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(55, 55, 60)
        end
        if SBUI.v1 and SBUI.v2 then
            local isV1 = (LaggerSettings.version == "V1")
            SBUI.v1.BackgroundColor3 = isV1 and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(15, 15, 18)
            SBUI.v1.TextColor3 = isV1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 80, 85)
            SBUI.v2.BackgroundColor3 = not isV1 and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(15, 15, 18)
            SBUI.v2.TextColor3 = not isV1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 80, 85)
        end
        if SBUI.optionContainer then SBUI.optionContainer.Visible = (LaggerState.activeMode == "MOBILE") end
        if SBUI.hotkeyLabel and SBUI.hotkeyBtn then
            local isMobile = (LaggerState.activeMode == "MOBILE")
            SBUI.hotkeyLabel.Visible = not isMobile
            SBUI.hotkeyBtn.Visible = not isMobile
        end
    end
    
    local bg = Instance.new("ScreenGui")
    bg.Name = "SpaceLagger"
    bg.ResetOnSpawn = false
    bg.Enabled = State.laggerGuiVisible
    bg.Parent = PlayerGui
    bg.DisplayOrder = 6
    LaggerGuiRef = bg
    
    local main = Instance.new("Frame", bg)
    main.Size = UDim2.fromOffset(230, 145)
    main.Position = UDim2.new(1, -245, 0.5, -72)
    main.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    
    
    main.BackgroundTransparency = 0.32
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.ZIndex = 1
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = Color3.fromRGB(255, 255, 255)
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.3
    makeDraggable(main)

    
    
    local auxBg = Instance.new("ImageLabel", main)
    auxBg.Name = "SpaceBackground"
    auxBg.Size = UDim2.fromScale(1, 1)
    auxBg.BackgroundTransparency = 1
    auxBg.Image = ""
    auxBg.ScaleType = Enum.ScaleType.Crop
    auxBg.ImageTransparency = 0.08
    auxBg.ZIndex = 1
    auxBg.Visible = false
    Instance.new("UICorner", auxBg).CornerRadius = UDim.new(0, 12)
    LaggerBgImage = auxBg

    local auxGrad = Instance.new("Frame", main)
    auxGrad.Name = "SpaceBackgroundGradient"
    auxGrad.Size = UDim2.fromScale(1, 1)
    auxGrad.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    auxGrad.BackgroundTransparency = 0
    auxGrad.BorderSizePixel = 0
    auxGrad.ZIndex = 0
    auxGrad.Visible = true
    Instance.new("UICorner", auxGrad).CornerRadius = UDim.new(0, 12)
    local auxGradient = Instance.new("UIGradient", auxGrad)
    auxGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 38)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(9, 9, 12)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 2, 4)),
    })
    auxGradient.Rotation = 135
    LaggerBgGrad = auxGrad
    
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(0, 125, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "SPACE LAGGER"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 2
    
    local subTitle = Instance.new("TextLabel", main)
    subTitle.Size = UDim2.new(0, 120, 0, 10)
    subTitle.Position = UDim2.new(0, 10, 0, 22)
    subTitle.BackgroundTransparency = 1
    subTitle.Text = "discord.gg/spaceduels"
    subTitle.TextColor3 = Color3.fromRGB(80, 80, 85)
    subTitle.Font = Enum.Font.GothamBold
    subTitle.TextSize = 7
    subTitle.TextXAlignment = Enum.TextXAlignment.Left
    subTitle.ZIndex = 2
    
    local sep = Instance.new("Frame", main)
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Position = UDim2.new(0, 10, 0, 34)
    sep.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sep.BorderSizePixel = 0
    sep.ZIndex = 2
    
    local statusText = Instance.new("TextLabel", main)
    statusText.Size = UDim2.new(1, -20, 0, 22)
    statusText.Position = UDim2.new(0, 10, 0, 38)
    statusText.BackgroundTransparency = 1
    statusText.Text = "STATUS: IDLE"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 9
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.ZIndex = 2
    SBUI.statusText = statusText
    
    local sep2 = Instance.new("Frame", main)
    sep2.Size = UDim2.new(1, -20, 0, 1)
    sep2.Position = UDim2.new(0, 10, 0, 52)
    sep2.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    sep2.BorderSizePixel = 0
    sep2.ZIndex = 2
    
    local modeContainer = Instance.new("Frame", main)
    modeContainer.Size = UDim2.new(0, 100, 0, 22)
    modeContainer.Position = UDim2.new(0, 10, 0, 58)
    modeContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    modeContainer.BorderSizePixel = 0
    modeContainer.ZIndex = 2
    Instance.new("UICorner", modeContainer).CornerRadius = UDim.new(0, 6)
    local modeStroke = Instance.new("UIStroke", modeContainer)
    modeStroke.Color = Color3.fromRGB(30, 30, 35)
    modeStroke.Thickness = 1
    
    local pcBtn = Instance.new("TextButton", modeContainer)
    pcBtn.Size = UDim2.new(0.5, 0, 1, 0)
    pcBtn.Position = UDim2.new(0, 0, 0, 0)
    pcBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    pcBtn.BackgroundTransparency = 0
    pcBtn.BorderSizePixel = 0
    pcBtn.Text = "PC"
    pcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pcBtn.Font = Enum.Font.GothamBold
    pcBtn.TextSize = 8
    pcBtn.ZIndex = 3
    Instance.new("UICorner", pcBtn).CornerRadius = UDim.new(0, 6)
    
    local mobileBtn = Instance.new("TextButton", modeContainer)
    mobileBtn.Size = UDim2.new(0.5, 0, 1, 0)
    mobileBtn.Position = UDim2.new(0.5, 0, 0, 0)
    mobileBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    mobileBtn.BackgroundTransparency = 0
    mobileBtn.BorderSizePixel = 0
    mobileBtn.Text = "MOBILE"
    mobileBtn.TextColor3 = Color3.fromRGB(80, 80, 85)
    mobileBtn.Font = Enum.Font.GothamBold
    mobileBtn.TextSize = 8
    mobileBtn.ZIndex = 3
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(0, 6)
    
    local function setMode(mode)
        LaggerState.activeMode = mode
        if mode == "PC" then
            pcBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            pcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            mobileBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            mobileBtn.TextColor3 = Color3.fromRGB(80, 80, 85)
        else
            mobileBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            pcBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            pcBtn.TextColor3 = Color3.fromRGB(80, 80, 85)
        end
        updateUI()
    end
    
    pcBtn.MouseButton1Click:Connect(function() setMode("PC") end)
    mobileBtn.MouseButton1Click:Connect(function() setMode("MOBILE") end)
    
    local versionLabel = Instance.new("TextLabel", main)
    versionLabel.Size = UDim2.new(0, 100, 0, 12)
    versionLabel.Position = UDim2.new(0, 120, 0, 58)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "LAGGER VERSION"
    versionLabel.TextColor3 = Color3.fromRGB(80, 80, 85)
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.TextSize = 9
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.ZIndex = 2
    
    local versionContainer = Instance.new("Frame", main)
    versionContainer.Size = UDim2.new(0, 100, 0, 26)
    versionContainer.Position = UDim2.new(0, 120, 0, 72)
    versionContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    versionContainer.BorderSizePixel = 0
    versionContainer.ZIndex = 2
    Instance.new("UICorner", versionContainer).CornerRadius = UDim.new(0, 6)
    local versionStroke = Instance.new("UIStroke", versionContainer)
    versionStroke.Color = Color3.fromRGB(30, 30, 35)
    versionStroke.Thickness = 1
    
    local v1Btn = Instance.new("TextButton", versionContainer)
    v1Btn.Size = UDim2.new(0.5, 0, 1, 0)
    v1Btn.Position = UDim2.new(0, 0, 0, 0)
    v1Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    v1Btn.BackgroundTransparency = 0
    v1Btn.BorderSizePixel = 0
    v1Btn.Text = "V1"
    v1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    v1Btn.Font = Enum.Font.GothamBold
    v1Btn.TextSize = 10
    v1Btn.ZIndex = 3
    Instance.new("UICorner", v1Btn).CornerRadius = UDim.new(0, 6)
    SBUI.v1 = v1Btn
    
    local v2Btn = Instance.new("TextButton", versionContainer)
    v2Btn.Size = UDim2.new(0.5, 0, 1, 0)
    v2Btn.Position = UDim2.new(0.5, 0, 0, 0)
    v2Btn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    v2Btn.BackgroundTransparency = 0
    v2Btn.BorderSizePixel = 0
    v2Btn.Text = "V2"
    v2Btn.TextColor3 = Color3.fromRGB(80, 80, 85)
    v2Btn.Font = Enum.Font.GothamBold
    v2Btn.TextSize = 10
    v2Btn.ZIndex = 3
    Instance.new("UICorner", v2Btn).CornerRadius = UDim.new(0, 6)
    SBUI.v2 = v2Btn
    
    v1Btn.MouseButton1Click:Connect(function()
        LaggerSettings.version = "V1"
        restartLagger()
        updateUI()
        scheduleAutoSave()
    end)
    v2Btn.MouseButton1Click:Connect(function()
        LaggerSettings.version = "V2"
        restartLagger()
        updateUI()
        scheduleAutoSave()
    end)
    
    local optionContainer = Instance.new("Frame", main)
    optionContainer.Size = UDim2.new(1, 0, 0, 30)
    optionContainer.Position = UDim2.new(0, 0, 0, 106)
    optionContainer.BackgroundTransparency = 1
    optionContainer.BorderSizePixel = 0
    optionContainer.ZIndex = 2
    SBUI.optionContainer = optionContainer
    optionContainer.Visible = (LaggerState.activeMode == "MOBILE")
    
    local optionText = Instance.new("TextLabel", optionContainer)
    optionText.Size = UDim2.new(0.6, -12, 1, 0)
    optionText.Position = UDim2.new(0, 12, 0, 0)
    optionText.BackgroundTransparency = 1
    optionText.Text = "Click To Activate"
    optionText.TextColor3 = Color3.fromRGB(80, 80, 85)
    optionText.Font = Enum.Font.GothamBold
    optionText.TextSize = 10
    optionText.TextXAlignment = Enum.TextXAlignment.Left
    optionText.ZIndex = 3
    
    local pillBg = Instance.new("Frame", optionContainer)
    pillBg.Size = UDim2.new(0, 40, 0, 20)
    pillBg.Position = UDim2.new(1, -52, 0.5, -10)
    pillBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    pillBg.BorderSizePixel = 0
    pillBg.ZIndex = 7
    Instance.new("UICorner", pillBg).CornerRadius = UDim.new(0, 10)
    local pillStroke = Instance.new("UIStroke", pillBg)
    pillStroke.Color = Color3.fromRGB(35, 35, 40)
    pillStroke.Thickness = 1
    SBUI.pillBg = pillBg
    
    local dot = Instance.new("Frame", pillBg)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, 3, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    dot.BorderSizePixel = 0
    dot.ZIndex = 8
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 7)
    SBUI.dot = dot
    
    local clickArea = Instance.new("TextButton", optionContainer)
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.Position = UDim2.new(0, 0, 0, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 4
    clickArea.MouseButton1Click:Connect(function() toggleLagger() end)
    
    local hotkeyLabel = Instance.new("TextLabel", main)
    hotkeyLabel.Size = UDim2.new(0, 50, 0, 12)
    hotkeyLabel.Position = UDim2.new(0, 10, 0, 104)
    hotkeyLabel.BackgroundTransparency = 1
    hotkeyLabel.Text = "HOTKEY"
    hotkeyLabel.TextColor3 = Color3.fromRGB(80, 80, 85)
    hotkeyLabel.Font = Enum.Font.GothamBold
    hotkeyLabel.TextSize = 9
    hotkeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    hotkeyLabel.ZIndex = 2
    SBUI.hotkeyLabel = hotkeyLabel
    hotkeyLabel.Visible = (LaggerState.activeMode == "PC")
    
    local hotkeyBtn = Instance.new("TextButton", main)
    hotkeyBtn.Size = UDim2.new(0, 70, 0, 22)
    hotkeyBtn.Position = UDim2.new(0, 68, 0, 118)
    hotkeyBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    hotkeyBtn.BorderSizePixel = 0
    hotkeyBtn.Text = LaggerSettings.keybind
    hotkeyBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
    hotkeyBtn.Font = Enum.Font.GothamBold
    hotkeyBtn.TextSize = 10
    hotkeyBtn.ZIndex = 3
    Instance.new("UICorner", hotkeyBtn).CornerRadius = UDim.new(0, 6)
    local hotkeyStroke = Instance.new("UIStroke", hotkeyBtn)
    hotkeyStroke.Color = Color3.fromRGB(30, 30, 35)
    hotkeyStroke.Thickness = 1
    SBUI.hotkeyBtn = hotkeyBtn
    hotkeyBtn.Visible = (LaggerState.activeMode == "PC")
    
    hotkeyBtn.MouseButton1Click:Connect(function()
        startKeyListen(hotkeyBtn, function(nk)
            LaggerSettings.keybind = nk.Name
            hotkeyBtn.Text = prettyKeyName(nk)
            updateUI()
            scheduleAutoSave()
        end)
    end)
    
    LaggerState.running = false
    updateUI()
    
    local laggerKeyConn
    laggerKeyConn = UIS.InputBegan:Connect(function(input, gp)
        if gp or KeyListen.active then return end
        if LaggerState.activeMode == "PC" and input.KeyCode.Name == LaggerSettings.keybind then toggleLagger() end
    end)
    
    bg.AncestryChanged:Connect(function()
        if not bg.Parent then stopLagger(); laggerKeyConn:Disconnect() end
    end)
end


function applyFOV(v)
    pcall(function() workspace.CurrentCamera.FieldOfView = v end)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() applyFOV(State.fov) end)

task.wait(0.1)
task.wait(0.5)

if GuiRefs and GuiRefs.backgroundImage then
    if State.backgroundIndex == 0 then
        GuiRefs.backgroundImage.Visible = false
        if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = true end
    elseif BG_IMAGES[State.backgroundIndex] then
        local imgId = BG_IMAGES[State.backgroundIndex]
        if imgId then
            GuiRefs.backgroundImage.Image = "rbxassetid://" .. imgId
            GuiRefs.backgroundImage.Visible = true
            if GuiRefs.bgGrad then GuiRefs.bgGrad.Visible = false end
        end
    end
end

createSpeedBypassGUI()
createLaggerGUI()
syncAuxBackgrounds()
State.buildRagdollTimerOverlay()
applyFOV(State.fov)
setSkyMode(State.skyMode)
setStretchRes(State.stretchResEnabled)

if State.infJumpEnabled then setInfJumpInternal(true) end
if State.antiRagdollEnabled then AntiRagdoll.Enabled = true; startAntiRagdoll() end
if State.ragdollTimerEnabled then State.setRagdollTimer(true) end
if State.antiDieEnabled then State.setAntiDie(true) end
if State.fpsBoostEnabled then applyFPSBoost() end
if State.medusaCounterEnabled then setupMedusaCounter(LP.Character) end
if State.batCounterEnabled then startBatCounter() end
    if State.autoBatVersion == "V2" then
        State.autoBatV2Enabled = State.autoBatToggled
        if State.autoBatV2Enabled then
            startAutoBatV2()
        end
    else
        setAutoBatState(State.autoBatToggled)
    end
setupEnemySpeedDisplay()

if State.autoGrabEnabled then
    startAutoGrab()
    createProgressBar()
end

if State.unwalkEnabled then task.delay(0.5, function() startUnwalk() end) end

task.wait(0.2)
State.guiVisible = true
if GuiRefs.outer then GuiRefs.outer.Visible = true end
if closeBtnRef then closeBtnRef.Visible = true end
if topBarRef then topBarRef.Visible = false end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then clearHorizontalVelocity(root) end
end)

LP.CharacterRemoving:Connect(function(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then clearHorizontalVelocity(root) end
end)


do
    SpaceHubLoadV2UI = function(existing)
        if existing then
            
            
            
            
            pcall(function() existing:Destroy() end)
            existing = nil
        end
        local function v2Toggle(label, on)
            pcall(function()
                if label == "Infinite Jump" then
                    setInfJumpInternal(on)
                elseif label == "Unwalk" then
                    State.unwalkEnabled = on
                    if on then startUnwalk() else stopUnwalk() end
                    scheduleAutoSave()
                elseif label == "Stretch Res" then
                    setStretchRes(on)
                elseif label == "Auto Bat" then
                    setAutoBatState(on)
                elseif label == "Tp Bat" then
                    State.tpBatEnabled = on
                    if on then startTpBat() else stopTpBat() end
                    scheduleAutoSave()
                elseif label == "Auto Swing" then
                    autoSwingEnabled = on
                    scheduleAutoSave()
                elseif label == "Lagger Mode" then
                    State.laggerModeEnabled = on
                    scheduleAutoSave()
                elseif label == "Anti Ragdoll" then
                    State.antiRagdollEnabled = on
                    if on then startAntiRagdoll() else stopAntiRagdoll() end
                    scheduleAutoSave()
                elseif label == "Medusa Counter" then
                    State.medusaCounterEnabled = on
                    if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
                    scheduleAutoSave()
                elseif label == "Auto Grab" then
                    State.autoGrabEnabled = on
                    if on then startAutoGrab(); createProgressBar() else stopAutoGrab() end
                    scheduleAutoSave()
                elseif label == "FPS Boost" then
                    State.fpsBoostEnabled = on
                    if on then applyFPSBoost() else disableFPSBoost() end
                    scheduleAutoSave()
                end
            end)
        end


local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer


local ACCENT       = Color3.fromRGB(255,255,255)
local BG_DARK      = Color3.fromRGB(10,11,13)
local ROW_BG       = Color3.fromRGB(16,17,20)
local CARD_STROKE  = Color3.fromRGB(34,37,43)
local TEXT_WHITE    = Color3.fromRGB(255,255,255)
local TEXT_PRIMARY  = Color3.fromRGB(238,238,238)
local TEXT_DIM      = Color3.fromRGB(125,125,125)
local TEXT_SECTION  = Color3.fromRGB(200,205,215)
local BTN_BG       = Color3.fromRGB(18,18,18)
local TOGGLE_OFF   = Color3.fromRGB(40,40,40)
local TOGGLE_KNOB  = Color3.fromRGB(185,185,185)
local KNOB_ON      = Color3.fromRGB(12,12,12)
local GRAD_TOP     = Color3.fromRGB(20,21,25)
local GRAD_BOT     = Color3.fromRGB(13,14,17)

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)


local TAB_BG_IMAGES = {
    "rbxassetid://76835310118322",
    "rbxassetid://114138477258742",
    "rbxassetid://98780560101696",
}
local GENERAL_BG_IMAGES = {
    "rbxassetid://76835310118322",
    "rbxassetid://114138477258742",
    "rbxassetid://98780560101696",
}


local Toggles = {}
local UIToggleKey = Enum.KeyCode.LeftControl


function cardStyle(f)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,9); c.Parent = f
    local s = Instance.new("UIStroke"); s.Color = CARD_STROKE; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Transparency = 0.4; s.Parent = f
    local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(GRAD_TOP,GRAD_BOT); g.Rotation = 90; g.Transparency = NumberSequence.new(0.08,0.08); g.Parent = f
end

function smallBtn(p)
    local b = Instance.new("TextButton")
    b.Position = p.Pos or UDim2.new(0,0,0,0); b.Size = p.Size or UDim2.new(0,40,0,23)
    b.BackgroundColor3 = p.Bg or BTN_BG; b.BorderSizePixel = 0
    b.Text = p.Text or ""; b.TextColor3 = p.Col or TEXT_DIM; b.TextSize = p.TS or 11
    b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false; b.ZIndex = p.Z or 1; b.Parent = p.Parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,p.CR or 6); c.Parent = b
    local s = Instance.new("UIStroke"); s.Color = p.SC or CARD_STROKE; s.Thickness = p.ST or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Transparency = p.STr or 0.5; s.Parent = b
    return b
end

function accentBar(parent, on)
    local b = Instance.new("Frame")
    b.Position = UDim2.new(0,0,0.5,-11); b.Size = UDim2.new(0,3,0,22)
    b.BackgroundColor3 = on and ACCENT or TEXT_WHITE
    b.BackgroundTransparency = on and 0 or 1; b.BorderSizePixel = 0; b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,2); c.Parent = b
    return b
end

function autoCanvas(scroll)
    local lay = scroll:FindFirstChildOfClass("UIListLayout"); if not lay then return end
    local pad = scroll:FindFirstChildOfClass("UIPadding")
    local function upd()
        local h = lay.AbsoluteContentSize.Y + (pad and pad.PaddingBottom.Offset or 0)
        scroll.CanvasSize = UDim2.new(0,0,0,h)
    end
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
    task.defer(upd)
end



function sectionHeader(parent, text)
    local r = Instance.new("Frame"); r.Size = UDim2.new(1,0,0,24); r.BackgroundTransparency = 1; r.Parent = parent
    local b = Instance.new("Frame"); b.Position = UDim2.new(0,0,0.5,-6); b.Size = UDim2.new(0,3,0,13)
    b.BackgroundColor3 = ACCENT; b.BorderSizePixel = 0; b.Parent = r
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,2)
    local l = Instance.new("TextLabel"); l.Position = UDim2.new(0,12,0,0); l.Size = UDim2.new(1,-12,1,0)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = TEXT_SECTION; l.TextSize = 11
    l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = r
    return r
end

function inputRow(parent, label, def, hidden)
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,44)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0
    if hidden then r.Visible = false end; r.Parent = parent; cardStyle(r)
    local l = Instance.new("TextLabel"); l.Position = UDim2.new(0,13,0,0); l.Size = UDim2.new(1,-84,1,0)
    l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = TEXT_PRIMARY; l.TextSize = 13
    l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = r
    local bx = Instance.new("TextBox"); bx.Position = UDim2.new(1,-66,0.5,-12); bx.Size = UDim2.new(0,56,0,25)
    bx.BackgroundColor3 = BTN_BG; bx.BorderSizePixel = 0; bx.Text = def; bx.TextColor3 = ACCENT
    bx.TextSize = 13; bx.Font = Enum.Font.GothamBold; bx.Parent = r
    Instance.new("UICorner",bx).CornerRadius = UDim.new(0,6)
    local s = Instance.new("UIStroke"); s.Color = CARD_STROKE; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Transparency = 0.5; s.Parent = bx
    return r, bx
end

function v2KeybindSlot(label)
    local slots = {
        ["Carry Mode"] = "speed",
        ["Lagger Mode"] = "laggerToggle",
        ["Auto Left"] = "autoLeft",
        ["Auto Right"] = "autoRight",
        ["Auto Bat"] = "autoBat",
        ["Bat Aimbot"] = "autoBat",
        ["TP Bat"] = "tpBat",
    }
    return slots[label]
end

function actionKeybindSlot(label)
    local slots = {
        ["Drop Brainrot"] = "dropBrainrot",
        ["Drop"] = "dropBrainrot",
        ["TP Down"] = "tpDown",
        ["Insta Reset"] = "instaReset",
    }
    return slots[label]
end

function toggleRow(parent, label, keybind, on, hasExpand, onToggle)
    local keySlot = v2KeybindSlot(label)
    if keySlot and Keys[keySlot] then keybind = Keys[keySlot].Name end
    local h = keybind and 44 or 46
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,h)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0; r.Parent = parent; cardStyle(r)
    local bar = accentBar(r, on)
    local lw = keybind and UDim2.new(1,-120,1,0) or UDim2.new(1,-74,1,0)
    if hasExpand then lw = UDim2.new(1,-108,1,0) end
    local l = Instance.new("TextLabel"); l.Position = UDim2.new(0,14,0,0); l.Size = lw; l.BackgroundTransparency = 1
    l.Text = label; l.TextColor3 = TEXT_PRIMARY; l.TextSize = 14; l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = r

    local tb = Instance.new("TextButton"); tb.Position = UDim2.new(1,-54,0.5,-11); tb.Size = UDim2.new(0,44,0,22)
    tb.BackgroundColor3 = on and ACCENT or TOGGLE_OFF; tb.BorderSizePixel = 0; tb.Text = ""; tb.AutoButtonColor = false; tb.Parent = r
    Instance.new("UICorner",tb).CornerRadius = UDim.new(0,11)
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0,16,0,16); knob.BorderSizePixel = 0
    knob.Position = on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3 = on and KNOB_ON or TOGGLE_KNOB; knob.Parent = tb
    Instance.new("UICorner",knob)

    local state = on
    local function set(v)
        state = v
        TweenService:Create(tb, TWEEN_FAST, {BackgroundColor3 = v and ACCENT or TOGGLE_OFF}):Play()
        TweenService:Create(knob, TWEEN_FAST, {Position = v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8), BackgroundColor3 = v and KNOB_ON or TOGGLE_KNOB}):Play()
        TweenService:Create(bar, TWEEN_FAST, {BackgroundTransparency = v and 0 or 1}):Play()
        bar.BackgroundColor3 = ACCENT
    end
    tb.MouseButton1Click:Connect(function()
        local nextState = not state
        set(nextState)
        if onToggle then onToggle(nextState) end
    end)

    if keybind then
        
        
        local currentKey = keySlot and Keys[keySlot]
        local kb = smallBtn({
            Parent = r,
            Pos = UDim2.new(1,-104,0.5,-11),
            Size = UDim2.new(0,40,0,23),
            Text = currentKey and prettyKeyName(currentKey) or keybind,
            Z = 4,
        })
        kb.MouseButton1Click:Connect(function()
            startKeyListen(kb, function(newKey)
                if keySlot and Keys[keySlot] then
                    Keys[keySlot] = newKey
                end
                kb.Text = prettyKeyName(newKey)
                scheduleAutoSave()
            end)
        end)
        if keySlot then
            GuiToggleSetters[keySlot] = set
        end
    end

    local expandRows
    if hasExpand then
        expandRows = {}; local exp = false
        local eb = smallBtn({Parent=r, Pos=UDim2.new(1,-90,0.5,-11), Size=UDim2.new(0,26,0,22),
            Text="▲", Col=ACCENT, Bg=Color3.fromRGB(24,18,23), SC=ACCENT, ST=1.2, STr=0.15})
        eb.MouseButton1Click:Connect(function()
            exp = not exp; eb.Text = exp and "▼" or "▲"
            for _,rr in ipairs(expandRows) do rr.Visible = exp end
        end)
    end

    Toggles[label] = {get=function() return state end, set=set, subs=expandRows}
    return r, tb, expandRows
end

function actionRow(parent, label, keybind, onAction)
    local keySlot = actionKeybindSlot(label)
    if keySlot and Keys[keySlot] then keybind = Keys[keySlot].Name end
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,42)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0; r.Parent = parent; cardStyle(r)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,-56,1,0); btn.BackgroundTransparency = 1
    btn.Text = label; btn.TextColor3 = TEXT_PRIMARY; btn.TextSize = 14; btn.Font = Enum.Font.GothamBold; btn.Parent = r
    local bar = accentBar(r, false)
    btn.MouseButton1Click:Connect(function()
        bar.BackgroundColor3 = ACCENT
        TweenService:Create(bar, TWEEN_FAST, {BackgroundTransparency = 0}):Play()
        task.delay(0.3, function() TweenService:Create(bar, TWEEN_FAST, {BackgroundTransparency = 1}):Play() end)
        if onAction then onAction() end
    end)
    if keybind then
        local kb = smallBtn({Parent=r, Pos=UDim2.new(1,-50,0.5,-11), Size=UDim2.new(0,40,0,23), Text=keybind, Z=3})
        kb.MouseButton1Click:Connect(function()
            startKeyListen(kb, function(newKey)
                if keySlot and Keys[keySlot] then Keys[keySlot] = newKey end
                kb.Text = prettyKeyName(newKey)
                scheduleAutoSave()
            end)
        end)
    end
    return r, btn
end

function fullActionRow(parent, label)
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,42)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0; r.Parent = parent; cardStyle(r)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1
    btn.Text = label; btn.TextColor3 = TEXT_PRIMARY; btn.TextSize = 14; btn.Font = Enum.Font.GothamBold; btn.Parent = r
    accentBar(r, false)
    return r, btn
end

function modeSelector(parent, lt, rt)
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,36)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0; r.Parent = parent; cardStyle(r)
    local sl = Instance.new("Frame"); sl.ZIndex = 2; sl.Position = UDim2.new(0,4,0,4); sl.Size = UDim2.new(0.5,-6,1,-8)
    sl.BackgroundColor3 = Color3.fromRGB(235,45,150); sl.BorderSizePixel = 0; sl.Parent = r
    Instance.new("UICorner",sl).CornerRadius = UDim.new(0,7)
    local sg = Instance.new("UIGradient"); sg.Color = ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(205,205,205)); sg.Rotation = 90; sg.Parent = sl
    local lb = Instance.new("TextButton"); lb.ZIndex=3; lb.Size=UDim2.new(0.5,0,1,0); lb.BackgroundTransparency=1; lb.BorderSizePixel=0
    lb.Text=lt; lb.TextColor3=TEXT_WHITE; lb.TextSize=11; lb.Font=Enum.Font.GothamBold; lb.AutoButtonColor=false; lb.Parent=r
    local rb = Instance.new("TextButton"); rb.ZIndex=3; rb.Position=UDim2.new(0.5,0,0,0); rb.Size=UDim2.new(0.5,0,1,0); rb.BackgroundTransparency=1; rb.BorderSizePixel=0
    rb.Text=rt; rb.TextColor3=TEXT_DIM; rb.TextSize=11; rb.Font=Enum.Font.GothamBold; rb.AutoButtonColor=false; rb.Parent=r
    local left = true
    local function setM(l) left=l
        TweenService:Create(sl, TWEEN_FAST, {Position=l and UDim2.new(0,4,0,4) or UDim2.new(0.5,2,0,4)}):Play()
        lb.TextColor3 = l and TEXT_WHITE or TEXT_DIM; rb.TextColor3 = l and TEXT_DIM or TEXT_WHITE
    end
    lb.MouseButton1Click:Connect(function() setM(true) end); rb.MouseButton1Click:Connect(function() setM(false) end)
    return r, function() return left end
end

function arrowSelector(parent, label, options, onChange)
    if type(options)=="string" then options={options} end
    local idx = 1
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,44)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0; r.Parent = parent; cardStyle(r)
    local l = Instance.new("TextLabel"); l.Position=UDim2.new(0,13,0,0); l.Size=UDim2.new(0.43,0,0,44); l.BackgroundTransparency=1
    l.Text=label; l.TextColor3=TEXT_PRIMARY; l.TextSize=13; l.Font=Enum.Font.GothamMedium; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=r
    local la = smallBtn({Parent=r, Pos=UDim2.new(1,-174,0,8), Size=UDim2.new(0,29,0,27), Text="<", Col=TEXT_PRIMARY, TS=13, CR=7, SC=CARD_STROKE, STr=0.45})
    local vl = Instance.new("TextLabel"); vl.Position=UDim2.new(1,-141,0,8); vl.Size=UDim2.new(0,102,0,27)
    vl.BackgroundColor3=BTN_BG; vl.BorderSizePixel=0; vl.Text=options[1]; vl.TextColor3=TEXT_PRIMARY; vl.TextSize=10; vl.Font=Enum.Font.GothamBold; vl.Parent=r
    Instance.new("UICorner",vl).CornerRadius=UDim.new(0,7)
    local vs = Instance.new("UIStroke"); vs.Color=CARD_STROKE; vs.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; vs.Transparency=0.45; vs.Parent=vl
    local ra = smallBtn({Parent=r, Pos=UDim2.new(1,-35,0,8), Size=UDim2.new(0,29,0,27), Text=">", Col=TEXT_PRIMARY, TS=13, CR=7, SC=CARD_STROKE, STr=0.45})
    local function upd()
        vl.Text = options[idx]
        if onChange then onChange(idx, options[idx]) end
    end
    la.MouseButton1Click:Connect(function() idx=idx-1; if idx<1 then idx=#options end; upd() end)
    ra.MouseButton1Click:Connect(function() idx=idx+1; if idx>#options then idx=1 end; upd() end)
    return r, vl, function() return idx, options[idx] end
end

function dropdownRow(parent, label, def)
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,44)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0; r.Parent = parent; cardStyle(r)
    local l = Instance.new("TextLabel"); l.Position=UDim2.new(0,13,0,0); l.Size=UDim2.new(0.45,0,0,44); l.BackgroundTransparency=1
    l.Text=label; l.TextColor3=TEXT_PRIMARY; l.TextSize=13; l.Font=Enum.Font.GothamMedium; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=r
    local dd = smallBtn({Parent=r, Pos=UDim2.new(1,-130,0,8), Size=UDim2.new(0,120,0,27), Text=def, Col=TEXT_PRIMARY, TS=11, CR=7, SC=CARD_STROKE, STr=0.45})
    local ca = Instance.new("Frame"); ca.Position=UDim2.new(0,13,0,44); ca.Size=UDim2.new(1,-26,0,0); ca.BackgroundTransparency=1; ca.Parent=r
    local lay = Instance.new("UIListLayout"); lay.Padding=UDim.new(0,4); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Parent=ca
    local exp = false
    dd.MouseButton1Click:Connect(function()
        exp = not exp
        TweenService:Create(r, TWEEN_MED, {Size=UDim2.new(1,0,0, exp and (44+lay.AbsoluteContentSize.Y+10) or 44)}):Play()
    end)
    return r, dd, ca
end

function keybindRow(parent, label, key)
    local r = Instance.new("Frame"); r.ClipsDescendants = true; r.Size = UDim2.new(1,0,0,44)
    r.BackgroundColor3 = ROW_BG; r.BackgroundTransparency = 0.03; r.BorderSizePixel = 0; r.Parent = parent; cardStyle(r)
    local l = Instance.new("TextLabel"); l.Position=UDim2.new(0,13,0,0); l.Size=UDim2.new(0.45,0,0,44); l.BackgroundTransparency=1
    l.Text=label; l.TextColor3=TEXT_PRIMARY; l.TextSize=13; l.Font=Enum.Font.GothamMedium; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=r
    local kb = smallBtn({Parent=r, Pos=UDim2.new(1,-130,0.5,-12), Size=UDim2.new(0,120,0,25), Text=key, Col=TEXT_DIM, TS=11, CR=6})
    return r, kb
end


function makePage(parent, name, order, vis)
    local p = Instance.new("ScrollingFrame"); p.Name=name; p.Visible=vis~=false; p.LayoutOrder=order
    p.Size=UDim2.new(1,0,1,0); p.BackgroundTransparency=1; p.BorderSizePixel=0
    p.ScrollBarThickness=2; p.ScrollBarImageColor3=ACCENT; p.CanvasSize=UDim2.new(0,0,0,0); p.Parent=parent
    local l = Instance.new("UIListLayout"); l.Padding=UDim.new(0,7); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=p
    local pd = Instance.new("UIPadding"); pd.PaddingBottom=UDim.new(0,10); pd.PaddingRight=UDim.new(0,4); pd.Parent=p
    autoCanvas(p)
    return p
end

function makeTab(parent, name, text, pos, active)
    local b = Instance.new("TextButton"); b.Name=name; b.ZIndex=9
    if pos then b.Position=pos end; b.Size=UDim2.new(1,0,0,30)
    b.BackgroundColor3=Color3.fromRGB(18,19,23); b.BackgroundTransparency=active and 0 or 0.28; b.BorderSizePixel=0
    b.Text=text; b.TextColor3=active and TEXT_WHITE or TEXT_DIM; b.TextSize=9; b.Font=Enum.Font.GothamBold; b.AutoButtonColor=false; b.Parent=parent
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    local s = Instance.new("UIStroke"); s.Color=active and ACCENT or CARD_STROKE; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Transparency=0.25; s.Parent=b
    return b
end


local RaVe = Instance.new("ScreenGui"); RaVe.Name="RaVe"; RaVe.ResetOnSpawn=false
RaVe.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; RaVe.Parent=LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame"); Frame.Name="Frame"; Frame.ClipsDescendants=true
local panelWidth, panelHeight = getResponsivePanelSize(420, 528)
Frame.Position=SpaceHubSharedPosition or UDim2.new(0,22,0.5,-math.floor(panelHeight / 2)); Frame.Size=UDim2.fromOffset(panelWidth, panelHeight)
Frame.BackgroundColor3=BG_DARK; Frame.BorderSizePixel=0; Frame.Parent=RaVe

Instance.new("UICorner",Frame).CornerRadius=UDim.new(0,16)
do
    local g = Instance.new("UIGradient"); g.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(16,19,26)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(9,10,13)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(11,14,20))
    }); g.Rotation=90; g.Parent=Frame
    local st = Instance.new("UIStroke"); st.Color=ACCENT; st.Thickness=1.5; st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; st.Transparency=1; st.Parent=Frame
    local sg = Instance.new("UIGradient"); sg.Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(205,205,205)); sg.Rotation=256.4; sg.Parent=st
end


for _,d in ipairs({
    {P=UDim2.new(0,-18,0,30), S=UDim2.new(0,360,0,360), C=ACCENT, T=0.922},
    {P=UDim2.new(0,-4,0,44),  S=UDim2.new(0,330,0,330), T=0.852},
    {P=UDim2.new(1,-2,1,-30), S=UDim2.new(0,360,0,360), C=ACCENT, T=0.922, A=Vector2.new(1,1), R=180},
    {P=UDim2.new(1,-2,1,-44), S=UDim2.new(0,330,0,330), T=0.852, A=Vector2.new(1,1), R=180},
}) do
    local i = Instance.new("ImageLabel"); i.Visible=false; i.ZIndex=0; i.Position=d.P; i.Size=d.S
    i.BackgroundTransparency=1; i.Image="rbxassetid://108037416708175"
    if d.C then i.ImageColor3=d.C end; i.ImageTransparency=d.T; i.ScaleType=Enum.ScaleType.Fit
    if d.A then i.AnchorPoint=d.A end; if d.R then i.Rotation=d.R end; i.Parent=Frame
end


local Header = Instance.new("Frame"); Header.Size=UDim2.new(1,0,0,68); Header.BackgroundTransparency=1; Header.Parent=Frame
do
    local t = Instance.new("TextLabel"); t.ZIndex=3; t.Position=UDim2.new(0,18,0,13); t.Size=UDim2.new(0,320,0,34)
    t.BackgroundTransparency=1; t.Text='Space Hub'; t.TextColor3=TEXT_WHITE
    t.TextSize=26; t.Font=Enum.Font.GothamBlack; t.TextXAlignment=Enum.TextXAlignment.Left; t.RichText=true; t.Parent=Header
    local tg = Instance.new("UIGradient"); tg.Offset=Vector2.new(-0.92,0); tg.Parent=t
    local s = Instance.new("TextLabel"); s.ZIndex=3; s.Position=UDim2.new(0,20,0,45); s.Size=UDim2.new(0,240,0,13)
    s.BackgroundTransparency=1; s.Text="discord.gg/space-hub"; s.TextColor3=TEXT_DIM
    s.TextSize=11; s.Font=Enum.Font.GothamMedium; s.TextXAlignment=Enum.TextXAlignment.Left; s.Parent=Header
end

local MinBtn = Instance.new("TextButton"); MinBtn.ZIndex=3; MinBtn.Position=UDim2.new(1,-42,0,13); MinBtn.Size=UDim2.new(0,30,0,30)
MinBtn.BackgroundColor3=BTN_BG; MinBtn.BorderSizePixel=0; MinBtn.Text="-"; MinBtn.TextColor3=TEXT_PRIMARY
MinBtn.TextSize=13; MinBtn.Font=Enum.Font.GothamBold; MinBtn.AutoButtonColor=false; MinBtn.Parent=Header
Instance.new("UICorner",MinBtn); do local s=Instance.new("UIStroke"); s.Color=CARD_STROKE; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Transparency=0.4; s.Parent=MinBtn end


local Div = Instance.new("Frame"); Div.Position=UDim2.new(0,16,0,64); Div.Size=UDim2.new(1,-32,0,1)
Div.BackgroundColor3=TEXT_WHITE; Div.BorderSizePixel=0; Div.Parent=Frame
do local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(ACCENT,ACCENT); g.Transparency=NumberSequence.new(0.2,0.85); g.Parent=Div end


local MainScroll = Instance.new("ScrollingFrame"); MainScroll.Name="MainScroll"; MainScroll.Visible=false
MainScroll.Position=UDim2.new(0,13,0,72); MainScroll.Size=UDim2.new(1,-26,1,-86)
MainScroll.BackgroundTransparency=1; MainScroll.BorderSizePixel=0; MainScroll.ScrollBarThickness=2
MainScroll.ScrollBarImageColor3=Color3.fromRGB(112,115,123); MainScroll.CanvasSize=UDim2.new(0,0,0,0); MainScroll.Parent=Frame
do
    local l=Instance.new("UIListLayout"); l.Padding=UDim.new(0,7); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=MainScroll
    local p=Instance.new("UIPadding"); p.PaddingBottom=UDim.new(0,12); p.PaddingRight=UDim.new(0,4); p.Parent=MainScroll
end


local PagedContent = Instance.new("Frame"); PagedContent.Name="PagedContent"
PagedContent.Position=UDim2.new(0,13,0,72); PagedContent.Size=UDim2.new(1,-128,1,-86)
PagedContent.BackgroundTransparency=1; PagedContent.ZIndex=2; PagedContent.Parent=Frame


local PM = makePage(PagedContent, "KuRuPage_MOVEMENT", 1, true)

sectionHeader(PM, "SPEED CONFIGURATION")
inputRow(PM, "Normal Speed", "59.5")
inputRow(PM, "Carry Speed", "28.8")
toggleRow(PM, "Carry Mode", "Q", false)
toggleRow(PM, "Auto Carry Mode", nil, State.autoCarryEnabled, false, function(on)
    State.autoCarryEnabled = on
    scheduleAutoSave()
end)

sectionHeader(PM, "LAGGER CONFIGURATION")
inputRow(PM, "Lagger Normal Speed", "15")
inputRow(PM, "Lagger Carry Speed", "24.5")
toggleRow(PM, "Lagger Mode", "R", false)
modeSelector(PM, "LAGGER NORMAL", "LAGGER CARRY")

sectionHeader(PM, "QUICK ACTIONS")
sectionHeader(PM, "DROP BRAINROT")
actionRow(PM, "Drop", "X")

sectionHeader(PM, "TP DOWN")
actionRow(PM, "TP Down", "F")
toggleRow(PM, "Auto TP Down", nil, false)
inputRow(PM, "Auto TP Height", "20")

sectionHeader(PM, "JUMP")
toggleRow(PM, "Infinite Jump", nil, false)
toggleRow(PM, "Anti Ragdoll", nil, false)
toggleRow(PM, "Unwalk", nil, false)
toggleRow(PM, "Try Hard Animation", nil, false)
dropdownRow(PM, "Animation Pack", "Off  v")
arrowSelector(PM, "Sky", {"Off","Stars","Sunset","Night","Galaxy"})

sectionHeader(PM, "AUTO PATH")
toggleRow(PM, "Auto Left", "Z", false)
toggleRow(PM, "Auto Right", "C", false)


local PS = makePage(PagedContent, "KuRuPage_STEAL", 2, false)

sectionHeader(PS, "STEAL CONFIGURATION")
local _, _, stealSubs = toggleRow(PS, "Auto Steal", nil, true, true)
modeSelector(PS, "NORMAL", "SEMI")
local sr1 = inputRow(PS, "SEMI Range", "10", true)
local sr2 = inputRow(PS, "SEMI Prime", "80", true)
if stealSubs then table.insert(stealSubs, sr1); table.insert(stealSubs, sr2) end
inputRow(PS, "Radius", "62")
inputRow(PS, "Duration", "1.3")
sectionHeader(PS, "ACTIONS")
actionRow(PS, "Insta Reset", "I", function()
    runInstaReset()
end)


local PC = makePage(PagedContent, "KuRuPage_COMBAT", 3, false)

sectionHeader(PC, "BAT AIMBOT")
    toggleRow(PC, "Auto Bat", Keys.autoBat.Name, State.autoBatToggled, true, function(on)
        setSelectedAutoBatState(on)
    end)
modeSelector(PC, "DEFAULT", "BYPASS")
inputRow(PC, "Auto Bat Speed", "48")
toggleRow(PC, "Auto Swing", nil, false)
toggleRow(PC, "Mirror TP", nil, false)
    toggleRow(PC, "TP Bat", Keys.tpBat.Name, State.tpBatEnabled, true, function(on)
        State.tpBatEnabled = on
        if on then startTpBat() else stopTpBat() end
        scheduleAutoSave()
    end)
modeSelector(PC, "SURE HIT", "HIGH PING")

sectionHeader(PC, "PROTECTION")
toggleRow(PC, "Safe Mode", nil, false)

sectionHeader(PC, "COUNTERS")
toggleRow(PC, "Bat Counter", nil, false)
toggleRow(PC, "Medusa Counter", nil, false)
toggleRow(PC, "Auto Counter", nil, false)

sectionHeader(PC, "BODY LOCK")
toggleRow(PC, "Body Lock", nil, false)
inputRow(PC, "Lock Radius", "20")


local PMisc = makePage(PagedContent, "KuRuPage_MISC", 4, false)

sectionHeader(PMisc, "RESET")
actionRow(PMisc, "Insta Reset", "I", function()
    runInstaReset()
end)
toggleRow(PMisc, "Medusa Auto Reset", nil, false)
toggleRow(PMisc, "Auto Reset On Respawn", nil, false)

sectionHeader(PMisc, "APPEARANCE")
arrowSelector(PMisc, "Side Profile", {"PLAYER","OUTLINE","SILHOUETTE"})
toggleRow(PMisc, "Headless", nil, false)
toggleRow(PMisc, "Anti-Lag", nil, false)
toggleRow(PMisc, "Potato Graphics", nil, false)
toggleRow(PMisc, "FOV Change", nil, false)
inputRow(PMisc, "FOV Value", "120")
toggleRow(PMisc, "Stretch Res", nil, false)
toggleRow(PMisc, "ESP", nil, true)
toggleRow(PMisc, "Show Tracer", nil, true)


local PSett = makePage(PagedContent, "KuRuPage_SETTINGS", 5, false)

local GeneralBG


GeneralBG = Instance.new("ImageLabel"); GeneralBG.Name="GeneralBackground"; GeneralBG.ZIndex=1
GeneralBG.Position=UDim2.new(0,13,0,72); GeneralBG.Size=UDim2.new(1,-128,1,-86)
GeneralBG.BackgroundColor3=Color3.fromRGB(5,5,7); GeneralBG.BackgroundTransparency=0.12; GeneralBG.BorderSizePixel=0
GeneralBG.Image=GENERAL_BG_IMAGES[1]; GeneralBG.ImageTransparency=0.2; GeneralBG.ScaleType=Enum.ScaleType.Crop; GeneralBG.Parent=Frame
Instance.new("UICorner",GeneralBG).CornerRadius=UDim.new(0,10)
SpaceHubV2BackgroundImage = GeneralBG


local LayoutTabs = Instance.new("Frame"); LayoutTabs.Name="LayoutTabs"; LayoutTabs.ZIndex=8
LayoutTabs.Position=UDim2.new(1,-100,0,72); LayoutTabs.Size=UDim2.new(0,88,1,-86)
LayoutTabs.BackgroundTransparency=1; LayoutTabs.Parent=Frame

local SideTabBG = Instance.new("ImageLabel"); SideTabBG.Name="SideTabBackground"; SideTabBG.ZIndex=5
SideTabBG.Size=UDim2.new(1,0,1,0); SideTabBG.BackgroundColor3=Color3.fromRGB(5,5,7)
SideTabBG.BackgroundTransparency=0.15; SideTabBG.BorderSizePixel=0
SideTabBG.Image=TAB_BG_IMAGES[1]; SideTabBG.ImageTransparency=0.18
SideTabBG.ScaleType=Enum.ScaleType.Crop; SideTabBG.Parent=LayoutTabs
Instance.new("UICorner",SideTabBG).CornerRadius=UDim.new(0,10)
SpaceHubV2TabBackgroundImage = SideTabBG
syncV2Background(State.backgroundIndex)

local TabHL = Instance.new("Frame"); TabHL.ZIndex=8; TabHL.Size=UDim2.new(0.999991,0,0,30)
TabHL.BackgroundColor3=ACCENT; TabHL.BackgroundTransparency=0.82; TabHL.BorderSizePixel=0; TabHL.Parent=LayoutTabs
Instance.new("UICorner",TabHL).CornerRadius=UDim.new(0,7)
do local s=Instance.new("UIStroke"); s.Color=ACCENT; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=TabHL end


local SideId = Instance.new("Frame"); SideId.Name="SideIdentity"; SideId.ZIndex=10
SideId.Position=UDim2.new(0,0,0,150); SideId.Size=UDim2.new(1,0,0,132)
SideId.BackgroundTransparency=1; SideId.BorderSizePixel=0; SideId.Parent=LayoutTabs
do
    local av = Instance.new("ImageLabel"); av.ZIndex=11; av.AnchorPoint=Vector2.new(0.5,0)
    av.Position=UDim2.new(0.5,0,0,0); av.Size=UDim2.new(0,72,0,72)
    av.BackgroundColor3=Color3.fromRGB(8,9,11); av.BorderSizePixel=0
    av.Image="rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=150&h=150"
    av.ScaleType=Enum.ScaleType.Crop; av.Parent=SideId
    Instance.new("UICorner",av).CornerRadius=UDim.new(0,33)
    local as2=Instance.new("UIStroke"); as2.Color=ACCENT; as2.Thickness=2; as2.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; as2.Parent=av

    local b1=Instance.new("TextLabel"); b1.ZIndex=11; b1.Position=UDim2.new(0,0,0,80); b1.Size=UDim2.new(1,0,0,15)
    b1.BackgroundTransparency=1; b1.Text="buyer of,"; b1.TextColor3=TEXT_DIM; b1.TextSize=10; b1.Font=Enum.Font.GothamMedium; b1.Parent=SideId
    local n1=Instance.new("TextLabel"); n1.ZIndex=11; n1.Position=UDim2.new(0,0,0,98); n1.Size=UDim2.new(1,0,0,18)
    n1.BackgroundTransparency=1; n1.Text=LocalPlayer.DisplayName; n1.TextColor3=TEXT_PRIMARY; n1.TextSize=12
    n1.Font=Enum.Font.GothamBold; n1.TextTruncate=Enum.TextTruncate.AtEnd; n1.Parent=SideId
    local s1=Instance.new("TextLabel"); s1.ZIndex=11; s1.Position=UDim2.new(0,0,0,116); s1.Size=UDim2.new(1,0,0,11)
    s1.BackgroundTransparency=1; s1.Text="CORES LOADED"; s1.TextColor3=ACCENT; s1.Font=Enum.Font.GothamBold; s1.Parent=SideId
end


local TM = makeTab(LayoutTabs,"Tab_MOVEMENT","Main",nil,true)
local TS = makeTab(LayoutTabs,"Tab_STEAL","Other",UDim2.new(0,0,0,40),false)
local TMi= makeTab(LayoutTabs,"Tab_MISC","Customization",UDim2.new(0,0,1,-38),false)
local TSe= makeTab(LayoutTabs,"Tab_SETTINGS","Config",UDim2.new(0,0,1,-78),false)


local NotifFrame = Instance.new("Frame"); NotifFrame.Position=UDim2.new(1,-262,1,-396)
NotifFrame.Size=UDim2.new(0,250,0,380); NotifFrame.BackgroundTransparency=1; NotifFrame.Parent=RaVe
do local l=Instance.new("UIListLayout"); l.Padding=UDim.new(0,8); l.VerticalAlignment=Enum.VerticalAlignment.Bottom; l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=NotifFrame end


local MinPill = Instance.new("Frame"); MinPill.Visible=false; MinPill.Active=true; MinPill.ZIndex=40
MinPill.Position=UDim2.new(0,24,0.35,0); MinPill.Size=UDim2.new(0,140,0,40)
MinPill.BackgroundColor3=Color3.fromRGB(5,5,7); MinPill.BackgroundTransparency=0.02; MinPill.BorderSizePixel=0; MinPill.Parent=RaVe
Instance.new("UICorner",MinPill).CornerRadius=UDim.new(0,12)
do
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(55,57,63); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Transparency=0.55; s.Parent=MinPill
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text="Space Hub"; l.TextColor3=ACCENT; l.TextSize=14; l.Font=Enum.Font.GothamBlack; l.Parent=MinPill
    local b=Instance.new("TextButton"); b.ZIndex=41; b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.AutoButtonColor=false; b.Parent=MinPill
    b.MouseButton1Click:Connect(function() MinPill.Visible=false; Frame.Visible=true end)
end


function notify(text, dur)
    dur = dur or 3
    local n = Instance.new("Frame"); n.Size=UDim2.new(1,0,0,36); n.BackgroundColor3=Color3.fromRGB(5,5,7); n.BackgroundTransparency=0.05; n.BorderSizePixel=0; n.Parent=NotifFrame
    Instance.new("UICorner",n).CornerRadius=UDim.new(0,10)
    local ns=Instance.new("UIStroke"); ns.Color=ACCENT; ns.Transparency=0.5; ns.Parent=n
    local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,-16,1,0); nl.Position=UDim2.new(0,8,0,0)
    nl.BackgroundTransparency=1; nl.Text=text; nl.TextColor3=TEXT_PRIMARY; nl.TextSize=11; nl.Font=Enum.Font.GothamBold
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=n
    task.delay(dur, function()
        TweenService:Create(n,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        TweenService:Create(nl,TweenInfo.new(0.4),{TextTransparency=1}):Play()
        TweenService:Create(ns,TweenInfo.new(0.4),{Transparency=1}):Play()
        task.delay(0.45,function() n:Destroy() end)
    end)
end


local Pages = {Main=PM, Other=PS, Customization=PMisc, Config=PSett}
local Tabs  = {Main=TM, Other=TS, Customization=TMi, Config=TSe}
local curTab = "Main"

function switchTab(name)
    if curTab == name then return end; curTab = name
    local reverse = {Main="Speed", Other="Mechanics", Customization="Visual", Config="Settings"}
    if GuiRefs.categoryRefs and reverse[name] then
        GuiRefs.categoryRefs.active = reverse[name]
    end
    for k,p in pairs(Pages) do p.Visible = (k==name) end
    for k,b in pairs(Tabs) do
        local act = (k==name)
        b.TextColor3 = act and TEXT_WHITE or TEXT_DIM
        b.BackgroundTransparency = act and 0 or 0.28
        local st = b:FindFirstChildOfClass("UIStroke")
        if st then st.Color = act and ACCENT or CARD_STROKE end
    end
    local ab = Tabs[name]
    if ab then TweenService:Create(TabHL, TWEEN_MED, {Position=UDim2.new(ab.Position.X.Scale,ab.Position.X.Offset,ab.Position.Y.Scale,ab.Position.Y.Offset)}):Play() end
end

TM.MouseButton1Click:Connect(function() switchTab("Main") end)
TS.MouseButton1Click:Connect(function() switchTab("Other") end)
TMi.MouseButton1Click:Connect(function() switchTab("Customization") end)
TSe.MouseButton1Click:Connect(function() switchTab("Config") end)


function minimize() Frame.Visible=false; MinPill.Visible=true end
MinBtn.MouseButton1Click:Connect(minimize)


do
    local function makeDrag(obj, target)
        local drag,dInp,dStart,sPos
        obj.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                drag=true; dStart=i.Position; sPos=target.Position
                i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
            end
        end)
        obj.InputChanged:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dInp=i end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if i==dInp and drag then
                local d=i.Position-dStart
                target.Position=UDim2.new(sPos.X.Scale,sPos.X.Offset+d.X,sPos.Y.Scale,sPos.Y.Offset+d.Y)
                SpaceHubSharedPosition = target.Position
            end
        end)
    end
    makeDrag(Header, Frame)
    makeDrag(MinPill, MinPill)
end


UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode==UIToggleKey then
        if Frame.Visible then minimize() else MinPill.Visible=false; Frame.Visible=true end
    end
end)


do
    Frame.BackgroundTransparency=1; Frame.Size=UDim2.new(0,panelWidth,0,0)
    task.defer(function()
        TweenService:Create(Frame, TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
            Size=UDim2.fromOffset(panelWidth,panelHeight), BackgroundTransparency=0
        }):Play()
        task.delay(0.3, function() notify("Space Hub loaded!", 4) end)
    end)
end

    
    
    local function mountV1Page(sourceName, destination, keepV2Content)
        local source = GuiRefs.categoryRefs and GuiRefs.categoryRefs.contents
            and GuiRefs.categoryRefs.contents[sourceName]
        if not source or not destination then return end
        if not keepV2Content then
            for _, child in ipairs(destination:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end
        end
        source.Parent = destination
        source.Visible = true
        source.Size = UDim2.new(1, 0, 0, 0)
        source.AutomaticSize = Enum.AutomaticSize.Y
    end

    mountV1Page("Speed", PM)
    mountV1Page("Mechanics", PS)
    mountV1Page("Visual", PMisc)
    
    
    
    mountV1Page("Settings", PSett, true)
    PC.Visible = false

    local savedCategory = GuiRefs.categoryRefs and GuiRefs.categoryRefs.active
    local initialTab = ({Speed="Main", Mechanics="Other", Visual="Customization", Settings="Config"})[savedCategory] or "Main"
    switchTab(initialTab)

    return RaVe
    end

    SpaceHubResetV2UI = function()
        local v2 = PlayerGui:FindFirstChild("RaVe")
        if v2 then v2.Enabled = false end
    local pages = GuiRefs.categoryRefs and GuiRefs.categoryRefs.contents
    if pages and GuiRefs.contentFrame then
            for _, page in pairs(pages) do
                page.Parent = GuiRefs.contentFrame
                page.Visible = true
            end
        end
        if GuiRefs.hub then GuiRefs.hub.Enabled = true end
    end
end


do
    SpaceHubLoadV3UI = function(existing)
        if existing then pcall(function() existing:Destroy() end) end

        local gui = Instance.new("ScreenGui")
        gui.Name = "SpaceHubV3"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = PlayerGui

        local panelWidth, panelHeight = getResponsivePanelSize(300, 480)
        local main = Instance.new("Frame")
        main.Name = "Main"
        main.Size = UDim2.fromOffset(panelWidth, panelHeight)
        main.Position = SpaceHubSharedPosition or UDim2.new(0.5, -150, 0.5, -240)
        main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        main.BorderSizePixel = 0
        main.Active = true
        main.Parent = gui
        guiCorner(main, 16)
        guiStroke(main, Color3.fromRGB(110, 110, 120), 1.5)

        local art = Instance.new("ImageLabel")
        art.Size = UDim2.fromScale(1, 1)
        art.BackgroundTransparency = 1
        art.Image = "rbxassetid://138886580032113"
        art.ImageTransparency = 0.38
        art.ScaleType = Enum.ScaleType.Crop
        art.ZIndex = 1
        art.Parent = main
        guiCorner(art, 16)
        SpaceHubV3BackgroundImage = art
        syncV2Background(State.backgroundIndex)

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 88)
        header.BackgroundTransparency = 1
        header.Active = true
        header.ZIndex = 2
        header.Parent = main

        local headerArt = Instance.new("ImageLabel")
        headerArt.Size = UDim2.new(1, 0, 0, 145)
        headerArt.BackgroundTransparency = 1
        headerArt.Image = "rbxassetid://138886580032113"
        headerArt.ImageTransparency = 0.2
        headerArt.ScaleType = Enum.ScaleType.Crop
        headerArt.ZIndex = 2
        headerArt.Parent = header
        guiCorner(headerArt, 16)
        SpaceHubV3HeaderBackgroundImage = headerArt
        syncV2Background(State.backgroundIndex)
        local hg = Instance.new("UIGradient")
        hg.Rotation = 90
        hg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.6, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        hg.Parent = headerArt

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 66)
        title.Position = UDim2.new(0, 0, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = "Space"
        title.TextXAlignment = Enum.TextXAlignment.Center
        title.TextColor3 = Color3.fromRGB(240, 240, 240)
        title.TextSize = 54
        title.Font = Enum.Font.LuckiestGuy
        title.ZIndex = 3
        title.Parent = header
        local titleStroke = Instance.new("UIStroke")
        titleStroke.Color = Color3.fromRGB(0, 0, 0)
        titleStroke.Thickness = 3
        titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        titleStroke.Parent = title

        local min = Instance.new("TextButton")
        min.Size = UDim2.fromOffset(26, 26)
        min.Position = UDim2.new(1, -36, 0, 10)
        min.Text = "-"
        min.TextSize = 18
        min.TextColor3 = Color3.fromRGB(240, 240, 240)
        min.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        min.BorderSizePixel = 0
        min.ZIndex = 4
        min.Parent = header
        guiCorner(min, 8)

        local content = Instance.new("Frame")
        content.Position = UDim2.new(0, 12, 0, 88)
        content.Size = UDim2.new(1, -24, 1, -144)
        content.BackgroundTransparency = 1
        content.ClipsDescendants = true
        content.ZIndex = 2
        content.Parent = main

        local pages = {}
        local pageNames = {"Main", "Other", "Customization", "Config"}
        for _, name in ipairs(pageNames) do
            local page = Instance.new("ScrollingFrame")
            page.Name = "V3Page_" .. name
            page.Size = UDim2.fromScale(1, 1)
            page.BackgroundTransparency = 1
            page.BorderSizePixel = 0
            page.ScrollBarThickness = 3
            page.ScrollBarImageColor3 = Color3.fromRGB(110, 110, 118)
            page.Visible = name == "Main"
            page.ZIndex = 3
            page.Parent = content
            pages[name] = page
        end

        local sourcePages = GuiRefs.categoryRefs and GuiRefs.categoryRefs.contents
        local mounts = {Main="Speed", Other="Mechanics", Customization="Visual", Config="Settings"}
        for name, sourceName in pairs(mounts) do
            local source = sourcePages and sourcePages[sourceName]
            if source then
                source.Parent = pages[name]
                source.Visible = true
                source.Size = UDim2.new(1, 0, 0, 0)
                source.AutomaticSize = Enum.AutomaticSize.Y
                local targetPage = pages[name]
                local sourceLayout = source:FindFirstChildOfClass("UIListLayout")
                local function updatePageCanvas()
                    local height = sourceLayout
                        and sourceLayout.AbsoluteContentSize.Y
                        or source.AbsoluteSize.Y
                    targetPage.CanvasSize = UDim2.new(0, 0, 0, height + 18)
                end
                if sourceLayout then
                    sourceLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvas)
                end
                source:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePageCanvas)
                task.defer(updatePageCanvas)
            end
        end

        local tabs = Instance.new("Frame")
        tabs.Size = UDim2.new(1, -16, 0, 36)
        tabs.Position = UDim2.new(0, 8, 1, -44)
        tabs.BackgroundTransparency = 1
        tabs.ZIndex = 5
        tabs.Parent = main
        local buttons = {}
        local function selectTab(name)
            for tabName, button in pairs(buttons) do
                button.TextColor3 = tabName == name
                    and Color3.fromRGB(240, 240, 240)
                    or Color3.fromRGB(190, 190, 195)
            end
            for tabName, page in pairs(pages) do page.Visible = tabName == name end
        end
        local labels = {Main="MAIN", Other="OTHER", Customization="CUSTOM", Config="CONFIG"}
        for i, name in ipairs(pageNames) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0.25, -2, 0, 30)
            button.Position = UDim2.new((i - 1) / 4, 1, 0.5, -15)
            button.BackgroundTransparency = 1
            button.BorderSizePixel = 0
            button.Text = labels[name]
            button.TextSize = 10
            button.Font = Enum.Font.GothamBold
            button.TextColor3 = Color3.fromRGB(190, 190, 195)
            button.ZIndex = 6
            button.Parent = tabs
            guiCorner(button, 8)
            buttons[name] = button
            button.MouseButton1Click:Connect(function()
                selectTab(name)
                local reverse = {Main="Speed", Other="Mechanics", Customization="Visual", Config="Settings"}
                if GuiRefs.categoryRefs and reverse[name] then
                    GuiRefs.categoryRefs.active = reverse[name]
                end
            end)
        end
        local savedCategory = GuiRefs.categoryRefs and GuiRefs.categoryRefs.active
        local initialTab = ({Speed="Main", Mechanics="Other", Visual="Customization", Settings="Config"})[savedCategory] or "Main"
        selectTab(initialTab)

        local minimized = false
        min.MouseButton1Click:Connect(function()
            minimized = not minimized
            min.Text = minimized and "+" or "-"
            content.Visible = not minimized
            tabs.Visible = not minimized
            main.Size = minimized and UDim2.fromOffset(math.min(panelWidth, 300), 94)
                or UDim2.fromOffset(panelWidth, panelHeight)
        end)
        
        do
            local dragging, dragStart, startPos = false, nil, nil
            local function clampPosition(raw)
                local camera = workspace.CurrentCamera
                local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
                local size = main.AbsoluteSize
                local inset = GuiService:GetGuiInset()
                local x = math.clamp(raw.X.Offset, 0, math.max(0, viewport.X - size.X))
                local y = math.clamp(raw.Y.Offset, 0, math.max(0, viewport.Y - inset.Y - size.Y))
                return UDim2.fromOffset(x, y)
            end
            main.Position = clampPosition(main.Position)
            SpaceHubSharedPosition = main.Position
            header.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = main.Position
                end
            end)
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UIS.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - dragStart
                    main.Position = clampPosition(UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    ))
                    SpaceHubSharedPosition = main.Position
                end
            end)
        end
        applyAccentColor(Color3.fromRGB(State.accentR, State.accentG, State.accentB))
        return gui
    end

    SpaceHubResetV3UI = function()
        if SpaceHubActiveV3Gui then
            SpaceHubActiveV3Gui.Enabled = false
        end
        local pages = GuiRefs.categoryRefs and GuiRefs.categoryRefs.contents
        if pages and GuiRefs.contentFrame then
            for _, page in pairs(pages) do
                page.Parent = GuiRefs.contentFrame
                page.Visible = true
            end
        end
        if GuiRefs and GuiRefs.hub then GuiRefs.hub.Enabled = true end
    end
end


do
    SpaceHubLoadV4UI = function(existing)
        if existing then pcall(function() existing:Destroy() end) end

        local gui = Instance.new("ScreenGui")
        gui.Name = "SpaceHubV4"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = PlayerGui

        local main = Instance.new("Frame")
        main.Name = "CleanHubV4"
        
        
        local panelWidth, panelHeight = getResponsivePanelSize(340, 495)
        main.Size = UDim2.fromOffset(panelWidth, panelHeight)
        main.Position = SpaceHubSharedPosition or UDim2.new(0, 20, 0, 110)
        main.BackgroundColor3 = Color3.fromRGB(9, 9, 12)
        main.BackgroundTransparency = 0.08
        main.BorderSizePixel = 0
        main.Active = true
        main.Parent = gui
        guiCorner(main, 18)
        guiStroke(main, Color3.fromRGB(120, 120, 130), 1.3)

        local bg = Instance.new("ImageLabel")
        bg.Name = "CleanHubBackground"
        bg.Size = UDim2.fromScale(1, 1)
        bg.BackgroundTransparency = 1
        bg.ImageTransparency = 0.12
        bg.ScaleType = Enum.ScaleType.Crop
        bg.ZIndex = 1
        bg.Parent = main
        guiCorner(bg, 18)
        SpaceHubV3BackgroundImage = bg
        syncV2Background(State.backgroundIndex)

        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 0.52
        overlay.BorderSizePixel = 0
        overlay.ZIndex = 2
        overlay.Parent = main
        guiCorner(overlay, 18)

        local rail = Instance.new("Frame")
        rail.Name = "Categories"
        rail.Position = UDim2.new(1, -85, 0, 0)
        rail.Size = UDim2.new(0, 85, 1, 0)
        rail.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        rail.BackgroundTransparency = 1
        rail.BorderSizePixel = 0
        rail.ZIndex = 3
        rail.Parent = main
        guiCorner(rail, 18)

        local brand = Instance.new("TextLabel")
        brand.Size = UDim2.fromOffset(210, 30)
        brand.Position = UDim2.fromOffset(74, 11)
        brand.BackgroundTransparency = 1
        brand.Text = "Space Hub"
        brand.TextColor3 = Color3.fromRGB(245, 245, 248)
        brand.TextSize = 20
        brand.Font = Enum.Font.GothamBlack
        brand.TextXAlignment = Enum.TextXAlignment.Left
        brand.ZIndex = 4
        brand.Parent = main
        local brandGradient = Instance.new("UIGradient")
        brandGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(238, 220, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(156, 101, 220)),
        })
        brandGradient.Rotation = 12
        brandGradient.Parent = brand

        local version = Instance.new("TextLabel")
        version.Size = UDim2.fromOffset(170, 16)
        version.Position = UDim2.fromOffset(76, 38)
        version.BackgroundTransparency = 1
        version.Text = "discord.gg/space-hub"
        version.TextColor3 = Color3.fromRGB(255, 255, 255)
        version.TextSize = 9
        version.Font = Enum.Font.GothamMedium
        version.TextXAlignment = Enum.TextXAlignment.Left
        version.ZIndex = 4
        version.Parent = main

        local avatar = Instance.new("ImageLabel")
        avatar.Name = "Avatar"
        avatar.Size = UDim2.fromOffset(46, 46)
        avatar.Position = UDim2.fromOffset(20, 8)
        avatar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150"
        avatar.ScaleType = Enum.ScaleType.Crop
        avatar.ZIndex = 5
        avatar.Parent = main
        guiCorner(avatar, 31)
        guiStroke(avatar, Color3.fromRGB(255, 255, 255), 2)

        local body = Instance.new("Frame")
        body.Position = UDim2.fromOffset(0, 0)
        body.Size = UDim2.new(1, -85, 1, 0)
        body.BackgroundTransparency = 1
        body.ZIndex = 3
        body.Parent = main

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, -30, 0, 92)
        header.Position = UDim2.fromOffset(18, 8)
        header.BackgroundTransparency = 1
        header.Active = true
        header.ZIndex = 4
        header.Parent = body

        local heading = Instance.new("TextLabel")
        heading.Size = UDim2.new(1, -50, 1, 0)
        heading.BackgroundTransparency = 1
        heading.Text = "Clean Hub"
        heading.Visible = false
        heading.TextColor3 = Color3.fromRGB(238, 238, 242)
        heading.TextSize = 25
        heading.Font = Enum.Font.GothamBold
        heading.TextXAlignment = Enum.TextXAlignment.Left
        heading.ZIndex = 5
        heading.Parent = header

        local min = Instance.new("TextButton")
        min.Size = UDim2.fromOffset(30, 30)
        min.Position = UDim2.new(1, -30, 0, 12)
        min.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        min.Text = "−"
        min.TextColor3 = Color3.fromRGB(235, 235, 240)
        min.TextSize = 18
        min.Font = Enum.Font.GothamBold
        min.AutoButtonColor = false
        min.ZIndex = 5
        min.Parent = header
        guiCorner(min, 9)

        local content = Instance.new("Frame")
        content.Position = UDim2.fromOffset(10, 76)
        content.Size = UDim2.new(1, -18, 1, -88)
        content.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
        content.BackgroundTransparency = 0.24
        content.BorderSizePixel = 0
        content.ClipsDescendants = true
        content.ZIndex = 4
        content.Parent = body
        guiCorner(content, 13)

        local pages, buttons = {}, {}
        local pageNames = {"Main", "Other", "Customization", "Config"}
        
        
        local labels = {Main="MOMENT", Other="COMBAT", Customization="MAIN", Config="KEYBINDS"}
        local mounts = {Main="Speed", Other="Mechanics", Customization="Visual", Config="Settings"}
        local sourcePages = GuiRefs.categoryRefs and GuiRefs.categoryRefs.contents
        for _, name in ipairs(pageNames) do
            local page = Instance.new("ScrollingFrame")
            page.Name = "V4Page_" .. name
            page.Size = UDim2.fromScale(1, 1)
            page.BackgroundTransparency = 1
            page.BorderSizePixel = 0
            page.ScrollBarThickness = 3
            page.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 158)
            page.Visible = false
            page.ZIndex = 5
            page.Parent = content
            pages[name] = page
            local source = sourcePages and sourcePages[mounts[name]]
            if source then
                source.Parent = page
                source.Visible = true
                source.Size = UDim2.new(1, -8, 0, 0)
                source.AutomaticSize = Enum.AutomaticSize.Y
                local layout = source:FindFirstChildOfClass("UIListLayout")
                local function resize()
                    page.CanvasSize = UDim2.fromOffset(0, (layout and layout.AbsoluteContentSize.Y or source.AbsoluteSize.Y) + 18)
                end
                if layout then layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize) end
                task.defer(resize)
            end
        end


        local nav = Instance.new("Frame")
        nav.Size = UDim2.new(1, -10, 0, 150)
        nav.Position = UDim2.fromOffset(5, 104)
        nav.BackgroundTransparency = 1
        nav.ZIndex = 4
        nav.Parent = rail
        local navLayout = Instance.new("UIListLayout")
        navLayout.Padding = UDim.new(0, 7)
        navLayout.SortOrder = Enum.SortOrder.LayoutOrder
        navLayout.Parent = nav

        local function selectTab(name)
            for n, p in pairs(pages) do p.Visible = n == name end
            for n, b in pairs(buttons) do
                b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                b.BackgroundTransparency = n == name and 0.18 or 1
                b.TextColor3 = n == name and Color3.fromRGB(12, 12, 16) or Color3.fromRGB(255, 255, 255)
            end
            heading.Text = labels[name]
            local reverse = {Main="Speed", Other="Mechanics", Customization="Visual", Config="Settings"}
            if GuiRefs.categoryRefs and reverse[name] then GuiRefs.categoryRefs.active = reverse[name] end
        end
        for i, name in ipairs(pageNames) do
            local b = Instance.new("TextButton")
            b.LayoutOrder = i
            b.Size = UDim2.new(1, 0, 0, 34)
            b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            b.BackgroundTransparency = 1
            b.BorderSizePixel = 0
            b.Text = "  " .. labels[name]
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.TextSize = 10
            b.Font = Enum.Font.GothamBold
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.AutoButtonColor = false
            b.ZIndex = 5
            b.Parent = nav
            guiCorner(b, 8)
            buttons[name] = b
            b.MouseButton1Click:Connect(function() selectTab(name) end)
        end
        local saved = GuiRefs.categoryRefs and GuiRefs.categoryRefs.active
        selectTab(({Speed="Main", Mechanics="Other", Visual="Customization", Settings="Config"})[saved] or "Main")

        local minimized = false
        min.MouseButton1Click:Connect(function()
            minimized = not minimized
            content.Visible = not minimized
            rail.Visible = not minimized
            main.Size = minimized and UDim2.fromOffset(math.min(panelWidth, 220), 62)
                or UDim2.fromOffset(panelWidth, panelHeight)
            min.Text = minimized and "+" or "−"
        end)
        do
            local dragging, start, origin
            
            
            
            local function clampPosition(position)
                local camera = workspace.CurrentCamera
                local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
                local size = main.AbsoluteSize
                local x = position.X.Scale * viewport.X + position.X.Offset
                local y = position.Y.Scale * viewport.Y + position.Y.Offset
                x = math.clamp(x, 0, math.max(0, viewport.X - size.X))
                y = math.clamp(y, 0, math.max(0, viewport.Y - size.Y))
                return UDim2.fromOffset(x, y)
            end

            main.Position = clampPosition(main.Position)
            SpaceHubSharedPosition = main.Position

            header.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging, start, origin = true, i.Position, main.Position
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = i.Position - start
                    main.Position = clampPosition(UDim2.fromOffset(
                        origin.X.Offset + d.X,
                        origin.Y.Offset + d.Y
                    ))
                    SpaceHubSharedPosition = main.Position
                end
            end)
        end
        return gui
    end
    SpaceHubResetV4UI = function()
        if SpaceHubActiveV4Gui then SpaceHubActiveV4Gui.Enabled = false end
        local pages = GuiRefs.categoryRefs and GuiRefs.categoryRefs.contents
        if pages and GuiRefs.contentFrame then
            for _, page in pairs(pages) do page.Parent = GuiRefs.contentFrame; page.Visible = true end
        end
        if GuiRefs and GuiRefs.hub then GuiRefs.hub.Enabled = true end
    end
end


task.spawn(function()
    task.wait(0.5)
    
    if SpaceHubActiveCustomUI == "V2" then
        if SpaceHubLoadV2UI then
            
            if GuiRefs and GuiRefs.hub then
                GuiRefs.hub.Enabled = false
            end
            
            SpaceHubActiveV2Gui = SpaceHubLoadV2UI(SpaceHubActiveV2Gui)
        end
    elseif SpaceHubActiveCustomUI == "V3" then
        if GuiRefs and GuiRefs.hub then GuiRefs.hub.Enabled = false end
        if SpaceHubLoadV3UI then
            SpaceHubActiveV3Gui = SpaceHubLoadV3UI(SpaceHubActiveV3Gui)
        end
    elseif SpaceHubActiveCustomUI == "V4" then
        if GuiRefs and GuiRefs.hub then GuiRefs.hub.Enabled = false end
        if SpaceHubLoadV4UI then
            SpaceHubActiveV4Gui = SpaceHubLoadV4UI(SpaceHubActiveV4Gui)
        end
    else
        
        if SpaceHubActiveV2Gui then
            SpaceHubActiveV2Gui.Enabled = false
        end
        if SpaceHubActiveV4Gui then
            SpaceHubActiveV4Gui.Enabled = false
        end
        if SpaceHubResetV2UI then
            SpaceHubResetV2UI()
        end
        if GuiRefs and GuiRefs.hub then
            GuiRefs.hub.Enabled = true
        end
    end

    applyAccentColor(Color3.fromRGB(State.accentR, State.accentG, State.accentB))
end)

task.defer(function()
    if State.outfit and State.outfit ~= "Off" then
        Outfit.set(State.outfit)
    end
    if State.animationPack and State.animationPack ~= "Off" then
        for _, pack in ipairs(Anim.Packs) do
            if pack[1] == State.animationPack then
                Anim.apply(pack)
                break
            end
        end
    end
end)
