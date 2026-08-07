-- ─── Bat Aimbot ───────────────────────────────────────────────────────────
local AIMBOT_SPEED   = 60
local MELEE_OFFSET   = 3
local lockedTarget   = nil

local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local ff  = targetChar:FindFirstChildOfClass("ForceField")
    return hum and hrp and hum.Health > 0 and not ff
end

local function getBestTarget(myHRP)
    if lockedTarget and isTargetValid(lockedTarget) then
        return lockedTarget:FindFirstChild("HumanoidRootPart"), lockedTarget
    end
    local shortestDist = math.huge
    local newTargetChar, newTargetHRP = nil, nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and isTargetValid(p.Character) then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            local d = (tHRP.Position - myHRP.Position).Magnitude
            if d < shortestDist then
                shortestDist = d
                newTargetHRP  = tHRP
                newTargetChar = p.Character
            end
        end
    end
    lockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end

local function startBatAimbot()
    if Connections.batAimbot then return end
    if AutoLeftEnabled      then stopAutoLeft()      end
    if AutoRightEnabled     then stopAutoRight()     end
    if AutoLeftPlayEnabled  then stopAutoLeftPlay()  end
    if AutoRightPlayEnabled then stopAutoRightPlay() end

    local r   = getHRP()
    local hum = getHum()
    if not r or not hum then return end

    hum.AutoRotate = false

    local att = r:FindFirstChild("AimbotAttachment") or Instance.new("Attachment", r)
    att.Name = "AimbotAttachment"

    local align = r:FindFirstChild("AimbotAlign") or Instance.new("AlignOrientation", r)
    align.Name         = "AimbotAlign"
    align.Mode         = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0  = att
    align.MaxTorque    = math.huge
    align.Responsiveness = 200

    Connections.batAimbot = RunService.Heartbeat:Connect(function()
        if not Enabled.BatAimbot then return end
        local currentHRP = getHRP()
        local currentHum = getHum()
        if not currentHRP or not currentHum then return end

        local targetHRP, targetChar = getBestTarget(currentHRP)

        if targetHRP and targetChar then
            local targetVel      = targetHRP.AssemblyLinearVelocity
            local speed          = targetVel.Magnitude
            local predictTime    = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos   = targetHRP.Position + (targetVel * predictTime)
            local dirToTarget    = predictedPos - currentHRP.Position
            local dist3D         = dirToTarget.Magnitude
            local targetStandPos = dist3D > 0 and (predictedPos - dirToTarget.Unit * MELEE_OFFSET) or predictedPos

            align.CFrame = CFrame.lookAt(currentHRP.Position, predictedPos)

            local moveDir     = targetStandPos - currentHRP.Position
            local distToStand = moveDir.Magnitude
            if distToStand > 1 then
                currentHRP.AssemblyLinearVelocity = moveDir.Unit * AIMBOT_SPEED
            else
                currentHRP.AssemblyLinearVelocity = targetVel
            end
        else
            lockedTarget = nil
            currentHRP.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function stopBatAimbot()
    if Connections.batAimbot then Connections.batAimbot:Disconnect(); Connections.batAimbot=nil end
    local r   = getHRP()
    local hum = getHum()
    if r then
        local att   = r:FindFirstChild("AimbotAttachment")
        local align = r:FindFirstChild("AimbotAlign")
        if att   then att:Destroy()   end
        if align then align:Destroy() end
        r.AssemblyLinearVelocity = Vector3.zero
    end
    if hum then hum.AutoRotate = true end
    lockedTarget = nil
end
