-- ==========================================
-- POWER HUB ⚡ | Official Loader with API Key System
-- ==========================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- 1. UI dyal Key System (Bhal li f s-sowra dyalk)
local ScreenGuiKey = Instance.new("ScreenGui")
ScreenGuiKey.Name = "PowerHubKeySystem"
ScreenGuiKey.Parent = game.CoreGui

local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(0, 260, 0, 130)
KeyFrame.Position = UDim2.new(0.5, -130, 0.5, -65)
KeyFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true
KeyFrame.Parent = ScreenGuiKey

local UICorner = Instance.new("UICorner", KeyFrame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "POWER HUB ⚡ | Key System"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.Code
Title.Parent = KeyFrame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(0.85, 0, 0, 35)
TextBox.Position = UDim2.new(0.075, 0, 0.35, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TextBox.BorderSizePixel = 0
TextBox.PlaceholderText = "Enter Key Here..."
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.TextSize = 12
TextBox.Font = Enum.Font.Code
TextBox.Parent = KeyFrame

local BoxCorner = Instance.new("UICorner", TextBox)
BoxCorner.CornerRadius = UDim.new(0, 6)

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0.85, 0, 0, 30)
SubmitBtn.Position = UDim2.new(0.075, 0, 0.7, 0)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Text = "VERIFY KEY"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.TextSize = 12
SubmitBtn.Font = Enum.Font.Code
SubmitBtn.Parent = KeyFrame

local BtnCorner = Instance.new("UICorner", SubmitBtn)
BtnCorner.CornerRadius = UDim.new(0, 6)

local keyVerified = false

-- Timer dyal Kick ila ma dakhlch l-key
task.delay(20, function()
    if not keyVerified then
        LocalPlayer:Kick("[POWERHUB SECURITY]\n❌ Invalid Key or Expired! Get a valid key from our shop.")
    end
end)

SubmitBtn.MouseButton1Click:Connect(function()
    local userKey = TextBox.Text
    
    if userKey == "" then return end
    
    SubmitBtn.Text = "CHECKING..."
    
    -- 2. Hna kat-dir l-API link dyal l-keys li kat-generer (Mital: KeyRBLX wla database dyalk)
    -- L-API kat-verifie wach l-key kain w active wla la
    local success, response = pcall(function()
        -- Baddal had l-link b l-API dyal l-Key System li kat-sta3ml
        -- return game:HttpGet("https://your-key-system-api.com/verify?key=" .. userKey)
        
        -- Ila knti baghi t-jrb ghir b mital lokal 3adi:
        if userKey == "POWER-VIP-2026" then return "true" else return "false" end
    end)
    
    if success and response == "true" then
        keyVerified = true
        ScreenGuiKey:Destroy()
        
        -- ==========================================
        -- 3. HNA K-T-HOTT SCRIPT DYALK L-ASLI (L-Lagger w UI)
        -- ==========================================
        print("Access Granted! Loading Power Hub...")
        
    else
        LocalPlayer:Kick("[POWERHUB SECURITY]\n❌ Invalid Key or Expired! Get a valid key from our shop.")
    end
end)
