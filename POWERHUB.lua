-- ==========================================
-- POWER HUB ⚡ | Modern Secure Loader
-- ==========================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Baddal had l-link b l-API dyal l-Key System li kat-sta3ml (Mital: KeyRBLX / Lucid / Custom API)
local API_URL = "https://your-key-system-api.com/api/check?key=" 

-- UI dyal Key System
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PowerHubAuth"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "POWER HUB ⚡ | Authorization"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(0.85, 0, 0, 40)
TextBox.Position = UDim2.new(0.075, 0, 0.4, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
TextBox.BorderSizePixel = 0
TextBox.PlaceholderText = "Paste your license key here..."
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.TextSize = 12
TextBox.Font = Enum.Font.Gotham
TextBox.Parent = Frame

local BoxCorner = Instance.new("UICorner", TextBox)
BoxCorner.CornerRadius = UDim.new(0, 8)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(0.85, 0, 0, 35)
VerifyBtn.Position = UDim2.new(0.075, 0, 0.72, 0)
VerifyBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
VerifyBtn.BorderSizePixel = 0
VerifyBtn.Text = "LOGIN"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 13
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner", VerifyBtn)
VerifyBtn.Parent = Frame
BtnCorner.CornerRadius = UDim.new(0, 8)

local verified = false

-- Security check after 15 seconds
task.delay(15, function()
    if not verified then
        LocalPlayer:Kick("[POWERHUB SECURITY]: Unauthenticated access attempt.")
    end
end)

VerifyBtn.MouseButton1Click:Connect(function()
    local key = TextBox.Text
    if key == "" then return end
    
    VerifyBtn.Text = "CHECKING..."
    
    -- Request HTTP l l-API bash t-verifie l-key 
    local success, res = pcall(function()
        -- L-script kay-sifet request l l-server dyalk wla l-API dyal l-keys
        local response = game:HttpGet(API_URL .. HttpService:UrlEncode(key))
        return response
    end)
    
    if success and res then
        -- Ila l-API rj3at an l-key s-sahih (Mital: JSON response fih status = true)
        if res:find("true") or res:find("success") then
            verified = true
            ScreenGui:Destroy()
            
            -- Hna fin kay-t-loadia l-script l-asli dyal l-lagger b loadstring tani ila bghiti
            print("Key Validated Successfully!")
            -- loadstring(game:HttpGet("LINK_DYAL_SCRIPT_L_ASLI"))()
        else
            LocalPlayer:Kick("[POWERHUB SECURITY]: ❌ Invalid or Expired Key!")
        end
    else
        VerifyBtn.Text = "CONNECTION ERROR"
        task.wait(2)
        VerifyBtn.Text = "LOGIN"
    end
end)
