-- POWE HUB ⚡️ (White Edition)

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UserInput   = game:GetService("UserInputService")

local LP = Players.LocalPlayer
if not LP then LP = Players.PlayerAdded:Wait() end

local State = { autoBatToggled = false, hittingCooldown = false }
local Conns = { aimbot = nil }

local _aimbotTarget = nil

local function findBat()
	local char = LP.Character; if not char then return nil end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
	end
	local bp = LP:FindFirstChild("Backpack")
	if bp then
		for _, tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
		end
	end
	return nil
end

local function getClosestTarget()
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local closest, minDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum   = plr.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and hum and hum.Health > 0 then
				local dist = (tRoot.Position - root.Position).Magnitude
				if dist < minDist then minDist = dist; closest = tRoot end
			end
		end
	end
	return closest
end

local function startBatAimbot()
	if Conns.aimbot then Conns.aimbot:Disconnect() end
	local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum0 then hum0.AutoRotate = false end

	Conns.aimbot = RunService.RenderStepped:Connect(function()
		if not State.autoBatToggled then return end
		local char = LP.Character; if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
		local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

		if not char:FindFirstChildOfClass("Tool") then
			local bat = findBat()
			if bat then pcall(function() hum:EquipTool(bat) end) end
		end

		local target = getClosestTarget()
		if not target then return end
		_aimbotTarget = target

		local targetVel = target.AssemblyLinearVelocity
		local myPos     = root.Position
		local targetPos = target.Position

		local predictPos = targetPos + targetVel * 0.14
		predictPos = predictPos + target.CFrame.LookVector * 0.3

		local direction  = predictPos - myPos
		local flatDir    = Vector3.new(direction.X, 0, direction.Z).Unit
		local chaseSpeed = 58

		local desiredHeight = targetPos.Y + 3.7
		local yVel = (desiredHeight - myPos.Y) * 19.5 + targetVel.Y * 0.8
		if hum.FloorMaterial ~= Enum.Material.Air then
			yVel = math.max(yVel, 13)
		end
		yVel = math.clamp(yVel, -70, 110)

		local desiredVel = Vector3.new(flatDir.X * chaseSpeed, yVel, flatDir.Z * chaseSpeed)
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(desiredVel, 0.8)

		local speed3 = targetVel.Magnitude
		local predictTime = math.clamp(speed3 / 150, 0.05, 0.2)
		local predictedPos = targetPos + targetVel * predictTime
		local toPredict = predictedPos - myPos
		if toPredict.Magnitude > 0.1 then
			local goalCF = CFrame.lookAt(myPos, predictedPos)
			local curCF  = root.CFrame
			local diffCF = curCF:Inverse() * goalCF
			local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
			rx = math.clamp(rx, -2.5, 2.5)
			ry = math.clamp(ry, -2.5, 2.5)
			rz = math.clamp(rz, -2.5, 2.5)
			local tiltSpeed = 42
			root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(
				Vector3.new(rx * tiltSpeed, ry * tiltSpeed, rz * tiltSpeed)
			)
		end
	end)
end

local function stopBatAimbot()
	if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot = nil end
	_aimbotTarget = nil
	local c = LP.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity  = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	local hum2 = c and c:FindFirstChildOfClass("Humanoid")
	if hum2 then hum2.AutoRotate = true end
	State.hittingCooldown = false
end

-- ─── Toggle Button GUI (White Theme & POWE HUB ⚡️) ──────────────────────────
local CoreGui = game:GetService("CoreGui")
pcall(function() if CoreGui:FindFirstChild("PoweHubGui") then CoreGui.PoweHubGui:Destroy() end end)

local gui = Instance.new("ScreenGui")
gui.Name = "PoweHubGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 160, 0, 48)
btn.Position = UDim2.new(0, 20, 0.5, -24)
btn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
btn.BorderSizePixel = 0
btn.Text = "POWER HUB⚡️: OFF"
btn.TextColor3 = Color3.fromRGB(20, 20, 20)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.AutoButtonColor = false
btn.Active = true
btn.Draggable = true
btn.Parent = gui

local corner = Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", btn); stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(200, 200, 200)

local function refresh()
	if State.autoBatToggled then
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = "POWER HUB⚡️: ON"
		stroke.Color = Color3.fromRGB(0, 0, 0)
	else
		btn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
		btn.Text = "POWER HUB⚡️: OFF"
		stroke.Color = Color3.fromRGB(200, 200, 200)
	end
end

btn.MouseButton1Click:Connect(function()
	State.autoBatToggled = not State.autoBatToggled
	if State.autoBatToggled then startBatAimbot() else stopBatAimbot() end
	refresh()
end)

refresh()
