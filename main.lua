print("[XyqwPiggy] Loading v7.5...")

local _ok, _err = pcall(function()

-- ============================================================
-- XyqwPiggy v7.5
-- Author: Xyqwerq
-- Modules: XyqwAutoFarm, XyqwSkinChanger
-- + Delete Piggy, Animations, Readable text
-- ============================================================

local VERSION = "7.5"
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer

local THEME = {
    BG     = Color3.fromRGB(0, 0, 0),
    DARK   = Color3.fromRGB(40, 0, 0),
    MAIN   = Color3.fromRGB(255, 0, 0),
    TITLE  = Color3.fromRGB(20, 0, 0),
    SUB    = Color3.fromRGB(200, 200, 200),
    ON     = Color3.fromRGB(0, 220, 90),
    OFF    = Color3.fromRGB(220, 0, 0),
    STROKE = Color3.fromRGB(120, 0, 0),
    OK     = Color3.fromRGB(0, 255, 100),
    GOLD   = Color3.fromRGB(255, 215, 0),
    YELLOW = Color3.fromRGB(255, 220, 0),
    CYAN   = Color3.fromRGB(0, 220, 255),
}

local function Notify(text, duration)
    duration = duration or 2
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XyqwPiggy", Text = tostring(text), Duration = duration
        })
    end)
end

local function Tween(obj, time, props, style, dir)
    if not obj or not obj.Parent then return end
    local info = TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function AddStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.STROKE
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function AddTextStroke(label, thickness)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 0, 0)
    s.Thickness = thickness or 1
    s.Parent = label
    return s
end

-- ============================================================
-- LOAD SCRIPT FROM URL
-- ============================================================
local function loadScriptFromURL(url, name)
    Notify("Loading " .. (name or "script") .. "...", 2)
    print("[XyqwPiggy] Loading: " .. url)

    local ok, err = pcall(function()
        if loadstring then
            local s_ok, source = pcall(function() return game:HttpGet(url) end)
            if s_ok and source and #source > 0 then
                local fn = loadstring(source)
                if fn then
                    fn()
                    Notify("OK " .. (name or "script"), 3)
                    return
                end
            end
        end
        if request then
            local r = request({Url = url, Method = "GET"})
            if r and r.Body then
                local fn = loadstring(r.Body)
                if fn then fn(); Notify("OK " .. (name or "script"), 3); return end
            end
        end
        if http_request then
            local r = http_request({Url = url, Method = "GET"})
            if r and r.Body then
                local fn = loadstring(r.Body)
                if fn then fn(); Notify("OK " .. (name or "script"), 3); return end
            end
        end
        error("All methods failed")
    end)

    if not ok then
        Notify("Failed: " .. tostring(err), 5)
        print("[XyqwPiggy] Error: " .. tostring(err))
    end
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    ESPItems = false,
    ESPMonster = false,
    ESPPlayers = false,
    AntiTrap = false,
    AutoAFK = false,
    DeletePiggy = false,        -- GUI состояние
    DeletePiggyActive = false,  -- реальное состояние (фон)
    lastScrollMisc = 0,
    miscScrolling = false,
}

local deletePiggyConn = nil

_G.__XyqwPiggyLastScroll = 0
_G.__XyqwPiggyScrolling = false

for _, obj in ipairs(CoreGui:GetChildren()) do
    if obj.Name == "XyqwPiggy" or obj.Name == "XyqwPiggyESP" then
        pcall(function() obj:Destroy() end)
    end
end
local playerGui = LP:WaitForChild("PlayerGui")
for _, obj in ipairs(playerGui:GetChildren()) do
    if obj.Name == "XyqwPiggy" or obj.Name == "XyqwPiggyESP" then
        pcall(function() obj:Destroy() end)
    end
end

local function GetPiggyCoins()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local mm = pg:FindFirstChild("MainMenu")
        if mm then
            local cs = mm:FindFirstChild("CurrencyShop")
            if cs then
                local cf = cs:FindFirstChild("CashFrame")
                if cf then
                    local cn = cf:FindFirstChild("CashNumber")
                    if cn and cn:IsA("TextLabel") then return cn.Text end
                end
            end
        end
    end
    return "?"
end

-- ============================================================
-- DELETE PIGGY LOGIC
-- ============================================================
local function GetPhase()
    local gf = workspace:FindFirstChild("GameFolder")
    if not gf then return nil end
    local p = gf:FindFirstChild("Phase")
    return p and p.Value or nil
end

local function IsCameraModel(obj)
    if obj:IsA("Camera") then return true end
    if obj:FindFirstChildOfClass("Camera") then return true end
    local n = obj.Name:lower()
    if n:find("camera") or n:find("cutscene") or n:find("intro") then return true end
    local c, d = obj.Parent, 0
    while c and d < 4 do
        local pn = c.Name:lower()
        if pn:find("camera") or pn:find("cutscene") then return true end
        c = c.Parent; d = d + 1
    end
    return false
end

local function RunDeletePiggyTick()
    if GetPhase() ~= "GameInProgress" then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            if not IsCameraModel(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local plr = Players:GetPlayerFromCharacter(obj)
                    if not plr then
                        pcall(function()
                            hum.Health = 0
                            obj.Parent = nil
                        end)
                    end
                end
            end
        end
    end
end

local function IsCutsceneOver()
    if GetPhase() ~= "GameInProgress" then return false end
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    if cam.CameraSubject ~= hum then return false end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, obj in ipairs(pg:GetChildren()) do
            local n = obj.Name:lower()
            if n:find("cutscene") or n:find("cinematic") or n:find("intro") then
                return false
            end
        end
    end
    return true
end

local function EnableDeletePiggy()
    if deletePiggyConn then return end
    State.DeletePiggy = true
    if IsCutsceneOver() then
        State.DeletePiggyActive = true
        Notify("Delete Piggy: ACTIVE", 3)
        print("[XyqwPiggy] Delete Piggy: ACTIVE")
    else
        State.DeletePiggyActive = false
        Notify("Piggy will be deleted after cutscene!", 5)
        print("[XyqwPiggy] Delete Piggy: ARMED (waiting cutscene)")
    end
    deletePiggyConn = RunService.Heartbeat:Connect(function()
        if not State.DeletePiggy then return end
        local over = IsCutsceneOver()
        if over and not State.DeletePiggyActive then
            State.DeletePiggyActive = true
            Notify("Delete Piggy: ACTIVE", 3)
            print("[XyqwPiggy] Delete Piggy: ACTIVATED")
        elseif not over and State.DeletePiggyActive then
            State.DeletePiggyActive = false
            Notify("Piggy will be deleted after cutscene!", 5)
            print("[XyqwPiggy] Delete Piggy: PAUSED")
        end
        if State.DeletePiggyActive then
            RunDeletePiggyTick()
        end
    end)
end

local function DisableDeletePiggy()
    State.DeletePiggy = false
    State.DeletePiggyActive = false
    if deletePiggyConn then
        deletePiggyConn:Disconnect()
        deletePiggyConn = nil
    end
    print("[XyqwPiggy] Delete Piggy: OFF")
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XyqwPiggy"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = playerGui end

-- DOCK (с анимацией ховера)
local DockBtn = Instance.new("TextButton")
DockBtn.Size = UDim2.new(0, 110, 0, 38)
DockBtn.Position = UDim2.new(0.03, 0, 0.15, 0)
DockBtn.BackgroundColor3 = THEME.BG
DockBtn.TextColor3 = THEME.MAIN
DockBtn.Text = "XyqwPiggy"
DockBtn.TextSize = 16
DockBtn.Font = Enum.Font.GothamBold
DockBtn.BorderSizePixel = 0
DockBtn.Parent = ScreenGui
DockBtn.AutoButtonColor = false
DockBtn.ZIndex = 1000
local DBC = Instance.new("UICorner"); DBC.CornerRadius = UDim.new(0, 12); DBC.Parent = DockBtn
local DockStroke = AddStroke(DockBtn, THEME.MAIN, 2)
AddTextStroke(DockBtn, 1.5)

DockBtn.MouseEnter:Connect(function()
    Tween(DockStroke, 0.3, { Thickness = 3, Color = Color3.fromRGB(255, 100, 100) })
end)
DockBtn.MouseLeave:Connect(function()
    Tween(DockStroke, 0.3, { Thickness = 2, Color = THEME.MAIN })
end)

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 340)
MainFrame.Position = UDim2.new(0.5, -140, 0.3, 0)
MainFrame.BackgroundColor3 = THEME.BG
MainFrame.BorderSizePixel = 3
MainFrame.BorderColor3 = THEME.MAIN
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
local MC = Instance.new("UICorner"); MC.CornerRadius = UDim.new(0, 10); MC.Parent = MainFrame

-- TITLE
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = THEME.TITLE
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local TC = Instance.new("UICorner"); TC.CornerRadius = UDim.new(0, 10); TC.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "XyqwPiggy v" .. VERSION
TitleLabel.TextColor3 = THEME.MAIN
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar
AddTextStroke(TitleLabel, 1.5)

local MiscBtn = Instance.new("TextButton")
MiscBtn.Size = UDim2.new(0, 38, 0, 22)
MiscBtn.Position = UDim2.new(1, -62, 0.5, -11)
MiscBtn.BackgroundColor3 = THEME.DARK
MiscBtn.TextColor3 = THEME.MAIN
MiscBtn.Text = "MISC"
MiscBtn.TextSize = 12
MiscBtn.Font = Enum.Font.GothamBold
MiscBtn.BorderSizePixel = 1
MiscBtn.BorderColor3 = THEME.MAIN
MiscBtn.Parent = TitleBar
MiscBtn.AutoButtonColor = false
local MBC = Instance.new("UICorner"); MBC.CornerRadius = UDim.new(0, 5); MBC.Parent = MiscBtn
AddStroke(MiscBtn); AddTextStroke(MiscBtn, 1)

MiscBtn.MouseEnter:Connect(function()
    Tween(MiscBtn, 0.25, { BackgroundColor3 = Color3.fromRGB(80, 0, 0) })
end)
MiscBtn.MouseLeave:Connect(function()
    Tween(MiscBtn, 0.25, { BackgroundColor3 = THEME.DARK })
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -24, 0.5, -11)
CloseBtn.BackgroundColor3 = THEME.DARK
CloseBtn.TextColor3 = THEME.MAIN
CloseBtn.Text = "X"
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 1
CloseBtn.BorderColor3 = THEME.MAIN
CloseBtn.Parent = TitleBar
CloseBtn.AutoButtonColor = false
local CB = Instance.new("UICorner"); CB.CornerRadius = UDim.new(0, 5); CB.Parent = CloseBtn
AddStroke(CloseBtn); AddTextStroke(CloseBtn, 1)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, 0.25, { BackgroundColor3 = Color3.fromRGB(120, 0, 0), Rotation = 90 })
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, 0.25, { BackgroundColor3 = THEME.DARK, Rotation = 0 })
end)

-- BALANCE
local BalanceFrame = Instance.new("Frame")
BalanceFrame.Size = UDim2.new(1, -16, 0, 28)
BalanceFrame.Position = UDim2.new(0, 8, 0, 34)
BalanceFrame.BackgroundColor3 = THEME.DARK
BalanceFrame.BorderSizePixel = 2
BalanceFrame.BorderColor3 = THEME.GOLD
BalanceFrame.Parent = MainFrame
local BFC = Instance.new("UICorner"); BFC.CornerRadius = UDim.new(0, 6); BFC.Parent = BalanceFrame
AddStroke(BalanceFrame, THEME.GOLD, 2)

local BalanceLabel = Instance.new("TextLabel")
BalanceLabel.Size = UDim2.new(1, -8, 1, 0)
BalanceLabel.Position = UDim2.new(0, 4, 0, 0)
BalanceLabel.BackgroundTransparency = 1
BalanceLabel.Text = "Piggy Coins: ..."
BalanceLabel.TextColor3 = THEME.GOLD
BalanceLabel.TextSize = 14
BalanceLabel.Font = Enum.Font.GothamBold
BalanceLabel.TextXAlignment = Enum.TextXAlignment.Left
BalanceLabel.Parent = BalanceFrame
AddTextStroke(BalanceLabel, 1.5)

-- SEARCH
local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(1, -16, 0, 24)
SearchBar.Position = UDim2.new(0, 8, 0, 68)
SearchBar.BackgroundColor3 = THEME.DARK
SearchBar.PlaceholderText = "Search items..."
SearchBar.PlaceholderColor3 = THEME.SUB
SearchBar.Text = ""
SearchBar.TextColor3 = THEME.MAIN
SearchBar.TextSize = 13
SearchBar.Font = Enum.Font.Gotham
SearchBar.ClearTextOnFocus = false
SearchBar.BorderSizePixel = 1
SearchBar.BorderColor3 = THEME.MAIN
SearchBar.Parent = MainFrame
local SC = Instance.new("UICorner"); SC.CornerRadius = UDim.new(0, 6); SC.Parent = SearchBar
AddStroke(SearchBar); AddTextStroke(SearchBar, 1)

-- ITEM SCROLL
local ItemScroll = Instance.new("ScrollingFrame")
ItemScroll.Size = UDim2.new(1, -16, 1, -170)
ItemScroll.Position = UDim2.new(0, 8, 0, 98)
ItemScroll.BackgroundColor3 = THEME.DARK
ItemScroll.BorderSizePixel = 1
ItemScroll.BorderColor3 = THEME.MAIN
ItemScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemScroll.ScrollBarThickness = 5
ItemScroll.ScrollBarImageColor3 = THEME.MAIN
ItemScroll.ScrollingDirection = Enum.ScrollingDirection.Y
ItemScroll.Parent = MainFrame
local ISC = Instance.new("UICorner"); ISC.CornerRadius = UDim.new(0, 6); ISC.Parent = ItemScroll
AddStroke(ItemScroll)

local ItemLayout = Instance.new("UIListLayout")
ItemLayout.Padding = UDim.new(0, 4)
ItemLayout.Parent = ItemScroll
ItemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ItemScroll.CanvasSize = UDim2.new(0, 0, 0, ItemLayout.AbsoluteContentSize.Y + 10)
end)

-- INFO
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -16, 0, 22)
InfoLabel.Position = UDim2.new(0, 8, 1, -46)
InfoLabel.BackgroundColor3 = THEME.DARK
InfoLabel.TextColor3 = THEME.MAIN
InfoLabel.Text = "0 items"
InfoLabel.TextSize = 13
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.BorderSizePixel = 1
InfoLabel.BorderColor3 = THEME.MAIN
InfoLabel.Parent = MainFrame
local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(0, 5); IC.Parent = InfoLabel
AddStroke(InfoLabel); AddTextStroke(InfoLabel, 1)

-- BOTTOM BUTTONS
local BtnFrame = Instance.new("Frame")
BtnFrame.Size = UDim2.new(1, -16, 0, 38)
BtnFrame.Position = UDim2.new(0, 8, 1, -46)
BtnFrame.BackgroundTransparency = 1
BtnFrame.Parent = MainFrame

local function MakeBtn(name, x, w)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(w, 0, 1, 0)
    btn.Position = UDim2.new(x, 0, 0, 0)
    btn.BackgroundColor3 = THEME.DARK
    btn.TextColor3 = THEME.MAIN
    btn.Text = name
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 1
    btn.BorderColor3 = THEME.MAIN
    btn.Parent = BtnFrame
    btn.AutoButtonColor = false
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
    AddStroke(btn); AddTextStroke(btn, 1)

    btn.MouseEnter:Connect(function()
        Tween(btn, 0.25, { BackgroundColor3 = Color3.fromRGB(80, 0, 0), BorderColor3 = Color3.fromRGB(255, 100, 100) })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.25, { BackgroundColor3 = THEME.DARK, BorderColor3 = THEME.MAIN })
    end)

    return btn
end

local ScanBtn = MakeBtn("Scan", 0, 0.24)
local OpenGameBtn = MakeBtn("Menu", 0.25, 0.24)
local RefreshBalBtn = MakeBtn("Balance", 0.50, 0.24)
local ResetBtn = MakeBtn("Reset", 0.75, 0.24)

-- MISC FRAME
local MiscFrame = Instance.new("Frame")
MiscFrame.Name = "MiscFrame"
MiscFrame.Size = UDim2.new(0, 230, 0, 340)
MiscFrame.Position = UDim2.new(0.5, 220, 0.5, -170)
MiscFrame.BackgroundColor3 = THEME.BG
MiscFrame.BorderSizePixel = 3
MiscFrame.BorderColor3 = THEME.MAIN
MiscFrame.Active = true
MiscFrame.Visible = false
MiscFrame.Parent = ScreenGui
MiscFrame.ZIndex = 10
local MFC = Instance.new("UICorner"); MFC.CornerRadius = UDim.new(0, 10); MFC.Parent = MiscFrame

local MiscTitleBar = Instance.new("Frame")
MiscTitleBar.Size = UDim2.new(1, 0, 0, 26)
MiscTitleBar.BackgroundColor3 = THEME.TITLE
MiscTitleBar.BorderSizePixel = 0
MiscTitleBar.Parent = MiscFrame
local MTC = Instance.new("UICorner"); MTC.CornerRadius = UDim.new(0, 10); MTC.Parent = MiscTitleBar

local MiscTitle = Instance.new("TextLabel")
MiscTitle.Size = UDim2.new(1, -30, 1, 0)
MiscTitle.Position = UDim2.new(0, 8, 0, 0)
MiscTitle.BackgroundTransparency = 1
MiscTitle.Text = "Misc"
MiscTitle.TextColor3 = THEME.MAIN
MiscTitle.TextSize = 14
MiscTitle.Font = Enum.Font.GothamBold
MiscTitle.TextXAlignment = Enum.TextXAlignment.Left
MiscTitle.Parent = MiscTitleBar
AddTextStroke(MiscTitle, 1.5)

local MiscClose = Instance.new("TextButton")
MiscClose.Size = UDim2.new(0, 20, 0, 20)
MiscClose.Position = UDim2.new(1, -24, 0.5, -10)
MiscClose.BackgroundColor3 = THEME.DARK
MiscClose.TextColor3 = THEME.MAIN
MiscClose.Text = "X"
MiscClose.TextSize = 12
MiscClose.Font = Enum.Font.GothamBold
MiscClose.BorderSizePixel = 1
MiscClose.BorderColor3 = THEME.MAIN
MiscClose.Parent = MiscTitleBar
MiscClose.AutoButtonColor = false
local MCC = Instance.new("UICorner"); MCC.CornerRadius = UDim.new(0, 5); MCC.Parent = MiscClose
AddStroke(MiscClose); AddTextStroke(MiscClose, 1)

local MiscScroll = Instance.new("ScrollingFrame")
MiscScroll.Name = "MiscScroll"
MiscScroll.Size = UDim2.new(1, -12, 1, -34)
MiscScroll.Position = UDim2.new(0, 6, 0, 30)
MiscScroll.BackgroundTransparency = 1
MiscScroll.BorderSizePixel = 0
MiscScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MiscScroll.ScrollBarThickness = 5
MiscScroll.ScrollBarImageColor3 = THEME.MAIN
MiscScroll.ScrollingDirection = Enum.ScrollingDirection.Y
MiscScroll.ScrollBarImageTransparency = 0.3
MiscScroll.ElasticBehavior = Enum.ElasticBehavior.Never
MiscScroll.Parent = MiscFrame
local MiscScrollCorner = Instance.new("UICorner"); MiscScrollCorner.CornerRadius = UDim.new(0, 6); MiscScrollCorner.Parent = MiscScroll
AddStroke(MiscScroll)

local ML = Instance.new("UIListLayout")
ML.Padding = UDim.new(0, 4)
ML.SortOrder = Enum.SortOrder.LayoutOrder
ML.Parent = MiscScroll
ML:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MiscScroll.CanvasSize = UDim2.new(0, 0, 0, ML.AbsoluteContentSize.Y + 15)
end)

MiscScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    State.lastScrollMisc = tick()
    State.miscScrolling = true
    _G.__XyqwPiggyLastScroll = State.lastScrollMisc
    _G.__XyqwPiggyScrolling = true
    task.delay(0.4, function()
        State.miscScrolling = false
        _G.__XyqwPiggyScrolling = false
    end)
end)

-- MAKE TOGGLE (с анимацией ховера)
local function MakeToggle(name, getState, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 28)
    row.BackgroundColor3 = THEME.DARK
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.MAIN
    row.Parent = MiscScroll
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
    local rowStroke = AddStroke(row)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.MAIN
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    AddTextStroke(lbl, 1)

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(1, -24, 0.5, -9)
    box.BackgroundColor3 = getState() and THEME.ON or THEME.OFF
    box.Text = ""
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.MAIN
    box.Parent = row
    box.AutoButtonColor = false
    box.ZIndex = 5
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = box
    AddStroke(box)

    -- Анимация ховера на строке
    row.MouseEnter:Connect(function()
        Tween(row, 0.3, { BackgroundColor3 = Color3.fromRGB(70, 0, 0) })
        Tween(rowStroke, 0.3, { Color = Color3.fromRGB(255, 100, 100), Thickness = 2 })
    end)
    row.MouseLeave:Connect(function()
        Tween(row, 0.3, { BackgroundColor3 = THEME.DARK })
        Tween(rowStroke, 0.3, { Color = THEME.MAIN, Thickness = 1 })
    end)

    local function U()
        local target = getState() and THEME.ON or THEME.OFF
        Tween(box, 0.3, { BackgroundColor3 = target })
    end
    local function fire()
        onToggle(); U()
        Notify(name .. ": " .. (getState() and "ON" or "OFF"), 2)
    end

    local catcher = Instance.new("TextButton")
    catcher.Size = UDim2.new(1, 0, 1, 0)
    catcher.BackgroundTransparency = 1
    catcher.Text = ""
    catcher.ZIndex = 10
    catcher.AutoButtonColor = false
    catcher.Parent = row

    local pressStart, pressPos, moved, tracking = 0, nil, false, false
    catcher.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pressStart = tick(); pressPos = input.Position; moved = false; tracking = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if tracking and pressPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if (input.Position - pressPos).Magnitude > 8 then moved = true end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if not tracking then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tracking = false
            local held = tick() - pressStart
            if not moved and held < 0.4 and (tick() - State.lastScrollMisc) > 0.4 and not State.miscScrolling then
                local mp = input.Position
                local cp, cs = catcher.AbsolutePosition, catcher.AbsoluteSize
                if mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then
                    fire()
                end
            end
            pressPos = nil
        end
    end)
end

-- MAKE MISC BTN (тонкий текст + анимация)
local function MakeMiscBtn(name, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 32)
    btn.BackgroundColor3 = THEME.DARK
    btn.TextColor3 = color
    btn.Text = name
    btn.TextSize = 13                              -- было 14
    btn.Font = Enum.Font.Gotham                    -- было GothamBold (жирный)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = color
    btn.Parent = MiscScroll
    btn.AutoButtonColor = false
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
    local btnStroke = AddStroke(btn, color, 1.5)   -- было 2
    AddTextStroke(btn, 1)                          -- было 1.5

    -- Анимация ховера
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.3, { BackgroundColor3 = Color3.fromRGB(80, 80, 20) })
        Tween(btnStroke, 0.3, { Thickness = 2.5 })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.3, { BackgroundColor3 = THEME.DARK })
        Tween(btnStroke, 0.3, { Thickness = 1.5 })
    end)

    local pressStart, pressPos, moved, tracking = 0, nil, false, false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pressStart = tick(); pressPos = input.Position; moved = false; tracking = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if tracking and pressPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if (input.Position - pressPos).Magnitude > 8 then moved = true end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if not tracking then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tracking = false
            local held = tick() - pressStart
            if not moved and held < 0.4 and (tick() - State.lastScrollMisc) > 0.4 and not State.miscScrolling then
                local mp = input.Position
                local cp, cs = btn.AbsolutePosition, btn.AbsoluteSize
                if mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then
                    onClick()
                end
            end
        end
    end)
end

-- TOGGLES
MakeToggle("Delete Piggy", function() return State.DeletePiggy end, function()
    if State.DeletePiggy then DisableDeletePiggy() else EnableDeletePiggy() end
end)
MakeToggle("ESP Items", function() return State.ESPItems end, function() State.ESPItems = not State.ESPItems end)
MakeToggle("ESP Monster", function() return State.ESPMonster end, function() State.ESPMonster = not State.ESPMonster end)
MakeToggle("ESP Players", function() return State.ESPPlayers end, function() State.ESPPlayers = not State.ESPPlayers end)
MakeToggle("Anti-Trap", function() return State.AntiTrap end, function() State.AntiTrap = not State.AntiTrap end)
MakeToggle("Auto-AFK", function() return State.AutoAFK end, function() State.AutoAFK = not State.AutoAFK end)

-- ============================================================
-- MODULE BUTTONS (читаемый текст)
-- ============================================================
local AUTOFARM_URL = "https://cdn.jsdelivr.net/gh/Xyqwerq/XyqwPiggy@main/XyqwAutoFarm.lua"
local SKINCHANGER_URL = "https://cdn.jsdelivr.net/gh/Xyqwerq/XyqwSkinChanger-Piggy@main/main.lua"

MakeMiscBtn("Load XyqwAutoFarm", THEME.YELLOW, function()
    Notify("Loading XyqwAutoFarm...", 2)
    print("[XyqwPiggy] Loading XyqwAutoFarm from: " .. AUTOFARM_URL)
    loadScriptFromURL(AUTOFARM_URL, "XyqwAutoFarm")
end)

MakeMiscBtn("Load XyqwSkinChanger", THEME.CYAN, function()
    Notify("Loading XyqwSkinChanger...", 2)
    print("[XyqwPiggy] Loading XyqwSkinChanger from: " .. SKINCHANGER_URL)
    loadScriptFromURL(SKINCHANGER_URL, "XyqwSkinChanger")
end)

-- DRAG MAIN
local mDrag, mStart, mStartPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mp = input.Position
        local function over(b)
            local p, s = b.AbsolutePosition, b.AbsoluteSize
            return mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
        end
        if over(CloseBtn) or over(MiscBtn) then return end
        mDrag = true; mStart = input.Position; mStartPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if mDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - mStart
        MainFrame.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + d.X, mStartPos.Y.Scale, mStartPos.Y.Offset + d.Y)
        if MiscFrame and MiscFrame.Visible then
            MiscFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + MainFrame.AbsoluteSize.X + 8, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
        end
    end
end)

-- DRAG MISC
local miDrag, miStart, miStartPos = false, nil, nil
MiscTitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mp = input.Position
        local p, s = MiscClose.AbsolutePosition, MiscClose.AbsoluteSize
        if mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y then return end
        miDrag = true; miStart = input.Position; miStartPos = MiscFrame.Position
    end
end)
MiscTitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if miDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - miStart
        MiscFrame.Position = UDim2.new(miStartPos.X.Scale, miStartPos.X.Offset + d.X, miStartPos.Y.Scale, miStartPos.Y.Offset + d.Y)
    end
end)

-- BUTTONS
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiscFrame.Visible = false
    DockBtn.Visible = true
end)

MiscBtn.MouseButton1Click:Connect(function()
    if MiscFrame.Visible then
        MiscFrame.Visible = false
    else
        MiscFrame.Visible = true
        MiscFrame.Position = UDim2.new(
            MainFrame.Position.X.Scale,
            MainFrame.Position.X.Offset + MainFrame.AbsoluteSize.X + 8,
            MainFrame.Position.Y.Scale,
            MainFrame.Position.Y.Offset
        )
    end
end)

MiscClose.MouseButton1Click:Connect(function()
    MiscFrame.Visible = false
end)

-- DOCK DRAG
local dockDrag, dockStart, dockStartPos, dockMoved = false, nil, nil, false
DockBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dockDrag = true; dockMoved = false
        dockStart = input.Position; dockStartPos = DockBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dockDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dockStart
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then dockMoved = true end
        if dockMoved then
            DockBtn.Position = UDim2.new(dockStartPos.X.Scale, dockStartPos.X.Offset + d.X, dockStartPos.Y.Scale, dockStartPos.Y.Offset + d.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dockDrag then
        if not dockMoved then
            MainFrame.Visible = true
            DockBtn.Visible = false
        end
        dockDrag = false
    end
end)

-- AUTO-REFRESH BALANCE
task.spawn(function()
    while true do
        task.wait(3)
        pcall(function()
            if MainFrame and MainFrame.Parent then
                BalanceLabel.Text = "Piggy Coins: " .. GetPiggyCoins()
            end
        end)
    end
end)

print("[XyqwPiggy v" .. VERSION .. "] Part 1 loaded!")

-- ESP FOLDER
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "XyqwPiggyESP"
ESPFolder.Parent = CoreGui

local ESP = { Items = {}, Monster = {}, Players = {} }

-- GET ITEM NAME
local function GetKeyNameByColor(c)
    local h, s, v = Color3.toHSV(c)
    if s < 0.15 then return "White Key" end
    local hd = h * 360
    if hd < 15 or hd >= 345 then return "Red Key" end
    if hd < 45 then return "Orange Key" end
    if hd < 70 then return "Yellow Key" end
    if hd < 160 then return "Green Key" end
    if hd < 200 then return "Cyan Key" end
    if hd < 260 then return "Blue Key" end
    if hd < 290 then return "Purple Key" end
    if hd < 345 then return "Pink Key" end
    return "Key"
end

local function GetItemName(item)
    local part = item.part
    if not part then return "Unknown" end
    local n = part.Name
    if n and n ~= "" and not n:match("^%-?%d+$") then return n end
    local mesh = part:FindFirstChildOfClass("SpecialMesh")
    local meshId = mesh and mesh.MeshId or nil
    if meshId == "rbxassetid://524706126" then return "Gear" end
    if meshId == "rbxassetid://725833400" then return "Hammer" end
    if meshId == "http://www.roblox.com/asset/?id=16198309" then return "Plank" end
    if meshId == "http://www.roblox.com/asset/?id=72012879" then return "Battery" end
    if meshId == "http://www.roblox.com/asset/?id=16884681" then return "Wrench" end
    if meshId == "rbxassetid://6714051581" then return "Note" end
    if meshId == "rbxassetid://456878024" then
        local pe = part:FindFirstChildOfClass("ParticleEmitter")
        if pe and pe.Color and pe.Color.Keypoints and #pe.Color.Keypoints > 0 then
            return GetKeyNameByColor(pe.Color.Keypoints[1].Value)
        end
        return "Key"
    end
    return "Name Encrypted"
end

-- IS DOOR / IS REAL ITEM
local MENU_NAMES = {
    MenuCameras = true, MainMenuForest = true, MainMenuScreen = true,
    ItemsScreen = true, ItemsFocus = true, ItemsCamera = true,
    MenuPositions = true, MenuStorage = true, AbilityMenuStorage = true,
}
local function IsInMenu(part)
    local c = part
    local depth = 0
    while c and depth < 8 do
        if MENU_NAMES[c.Name] then return true end
        c = c.Parent; depth = depth + 1
    end
    return false
end

local function IsDoor(part)
    for _, ch in ipairs(part:GetChildren()) do
        if ch:IsA("Script") and ch.Name:match("^%-?%d+$") then return true end
    end
    return false
end

local function IsRealItem(part)
    if IsDoor(part) then return false end
    if part:FindFirstChildOfClass("ParticleEmitter") then return true end
    for _, ch in ipairs(part:GetChildren()) do
        if ch:IsA("Script") and (ch.Name == "ItemPickupScript" or ch.Name == "NewItemPickupScript") then return true end
    end
    return false
end

local function IsAlreadyPickedUp(part)
    if part.Transparency >= 1 then return true end
    local pe = part:FindFirstChildOfClass("ParticleEmitter")
    if pe and not pe.Enabled then return true end
    local cd = part:FindFirstChildOfClass("ClickDetector")
    if cd and cd.MaxActivationDistance <= 0 then return true end
    return false
end

local function GetStableKey(part)
    local mesh = part:FindFirstChildOfClass("SpecialMesh")
    local meshId = mesh and mesh.MeshId or ""
    local p = part.Position
    local x = math.floor(p.X * 10 + 0.5) / 10
    local y = math.floor(p.Y * 10 + 0.5) / 10
    local z = math.floor(p.Z * 10 + 0.5) / 10
    return string.format("%s_%.1f_%.1f_%.1f", meshId, x, y, z)
end

local function GetListItems()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local part = obj.Parent
            if part and part:IsA("BasePart") and not IsInMenu(part) then
                if IsRealItem(part) and not IsAlreadyPickedUp(part) then
                    table.insert(items, {
                        part = part, detector = obj,
                        key = GetStableKey(part), pos = part.Position,
                    })
                end
            end
        end
    end
    table.sort(items, function(a, b)
        if math.abs(a.pos.X - b.pos.X) > 0.5 then return a.pos.X < b.pos.X end
        if math.abs(a.pos.Z - b.pos.Z) > 0.5 then return a.pos.Z < b.pos.Z end
        return a.pos.Y < b.pos.Y
    end)
    return items
end

local spinningModels = {}
local currentItems = {}
local scanInProgress = false

local function Create3DView(part, vpf)
    pcall(function()
        local world = Instance.new("WorldModel")
        world.Parent = vpf
        local model = Instance.new("Model")
        model.Parent = world
        local mp = part:Clone()
        for _, ch in ipairs(mp:GetChildren()) do
            if ch:IsA("Script") or ch:IsA("LocalScript")
            or ch:IsA("ClickDetector") or ch:IsA("ParticleEmitter")
            or ch:IsA("Weld") or ch:IsA("WeldConstraint") or ch:IsA("Attachment")
            or ch:IsA("BillboardGui") or ch:IsA("SurfaceGui") or ch:IsA("Sound")
            or ch:IsA("SelectionBox") or ch:IsA("Highlight") or ch:IsA("ForceField")
            or ch:IsA("Fire") or ch:IsA("Smoke") or ch:IsA("Sparkles")
            or ch:IsA("PointLight") or ch:IsA("SpotLight") or ch:IsA("SurfaceLight")
            or ch:IsA("RemoteEvent") or ch:IsA("RemoteFunction") then
                ch:Destroy()
            end
        end
        if mp:IsA("BasePart") then
            mp.Anchored = true
            mp.CanCollide = false
            mp.CanQuery = false
            mp.CanTouch = false
            mp.Massless = true
            mp.CFrame = CFrame.new(0, 0, 0)
        end
        mp.Parent = model
        local extents = model:GetExtentsSize()
        local maxE = math.max(extents.X, extents.Y, extents.Z)
        if maxE > 0.001 then model:ScaleTo(3) end
        if mp:IsA("BasePart") then mp.CFrame = CFrame.new(0, 0, 0) end
        local cam = Instance.new("Camera")
        cam.FieldOfView = 40
        cam.CFrame = CFrame.new(Vector3.new(4, 3, 4), Vector3.new(0, 0, 0))
        cam.Parent = vpf
        vpf.CurrentCamera = cam
        table.insert(spinningModels, mp)
    end)
end

local function TakeItem(item)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local saved = hrp.CFrame
    pcall(function() item.detector.MaxActivationDistance = math.huge end)
    hrp.CFrame = CFrame.new(item.part.Position + Vector3.new(0, 3, 0))
    task.wait(0.3)
    pcall(function() if fireclickdetector then fireclickdetector(item.detector) end end)
    task.wait(0.25)
    hrp.CFrame = saved
    Notify("Took: " .. GetItemName(item), 2)
    task.delay(0.5, function()
        if not scanInProgress and _G.__RefreshItemList then _G.__RefreshItemList() end
    end)
end

function _G.__RefreshItemList()
    if scanInProgress then return end
    scanInProgress = true
    local savedScroll = ItemScroll.CanvasPosition
    local existingRows = {}
    for _, ch in ipairs(ItemScroll:GetChildren()) do
        if ch:IsA("TextButton") and ch:GetAttribute("ItemKey") then
            existingRows[ch:GetAttribute("ItemKey")] = ch
        end
    end
    currentItems = GetListItems()
    InfoLabel.Text = "Items: " .. #currentItems
    local newKeys = {}
    for _, item in ipairs(currentItems) do newKeys[item.key] = true end

    for key, row in pairs(existingRows) do
        if not newKeys[key] then
            for i = #spinningModels, 1, -1 do
                local m = spinningModels[i]
                if not m or not m.Parent then table.remove(spinningModels, i) end
            end
            row:Destroy()
            existingRows[key] = nil
        end
    end

    for i, item in ipairs(currentItems) do
        local row = existingRows[item.key]
        if not row then
            row = Instance.new("TextButton")
            row.Size = UDim2.new(1, -5, 0, 50)
            row.BackgroundColor3 = THEME.DARK
            row.BorderSizePixel = 1
            row.BorderColor3 = THEME.STROKE
            row.Text = ""
            row.Parent = ItemScroll
            row.AutoButtonColor = false
            row.ClipsDescendants = false
            row:SetAttribute("ItemKey", item.key)
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
            local rowSt = AddStroke(row, THEME.STROKE, 1.5)

            -- Ховер на строке предмета
            row.MouseEnter:Connect(function()
                Tween(row, 0.3, { BackgroundColor3 = Color3.fromRGB(70, 0, 0) })
                Tween(rowSt, 0.3, { Color = THEME.MAIN, Thickness = 2 })
            end)
            row.MouseLeave:Connect(function()
                Tween(row, 0.3, { BackgroundColor3 = THEME.DARK })
                Tween(rowSt, 0.3, { Color = THEME.STROKE, Thickness = 1.5 })
            end)

            local vpf = Instance.new("ViewportFrame")
            vpf.Size = UDim2.new(0, 44, 0, 44)
            vpf.Position = UDim2.new(0, 3, 0.5, -22)
            vpf.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
            vpf.BorderSizePixel = 1
            vpf.BorderColor3 = THEME.MAIN
            vpf.Parent = row
            vpf.ZIndex = 2
            vpf.Ambient = Color3.fromRGB(220, 220, 220)
            vpf.LightColor = Color3.fromRGB(255, 255, 255)
            local vc = Instance.new("UICorner"); vc.CornerRadius = UDim.new(0, 5); vc.Parent = vpf
            AddStroke(vpf)
            Create3DView(item.part, vpf)
            local itemName = GetItemName(item)
            row:SetAttribute("ItemName", itemName)
            local nl = Instance.new("TextLabel")
            nl.Name = "ItemNameLabel"
            nl.Size = UDim2.new(1, -60, 1, 0)
            nl.Position = UDim2.new(0, 52, 0, 0)
            nl.BackgroundTransparency = 1
            nl.Text = itemName
            nl.TextColor3 = THEME.MAIN
            nl.TextSize = 13
            nl.Font = Enum.Font.GothamBold
            nl.TextXAlignment = Enum.TextXAlignment.Left
            nl.TextTruncate = Enum.TextTruncate.AtEnd
            nl.Parent = row
            AddTextStroke(nl, 1)
            local catcher = Instance.new("TextButton")
            catcher.Size = UDim2.new(1, 0, 1, 0)
            catcher.BackgroundTransparency = 1
            catcher.Text = ""
            catcher.ZIndex = 100
            catcher.AutoButtonColor = false
            catcher.Parent = row
            local pressStart, pressPos, moved, tracking = 0, nil, false, false
            catcher.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    pressStart = tick(); pressPos = input.Position; moved = false; tracking = true
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if tracking and pressPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    if (input.Position - pressPos).Magnitude > 6 then moved = true end
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if not tracking then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    tracking = false
                    local held = tick() - pressStart
                    if not moved and held < 0.5 then
                        local mp = input.Position
                        local cp, cs = catcher.AbsolutePosition, catcher.AbsoluteSize
                        if mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then
                            local curItem
                            for _, it in ipairs(currentItems) do
                                if it.key == row:GetAttribute("ItemKey") then curItem = it break end
                            end
                            if curItem then TakeItem(curItem) end
                        end
                    end
                    pressPos = nil
                end
            end)
        end
    end
    task.defer(function() ItemScroll.CanvasPosition = savedScroll end)
    scanInProgress = false
end

-- Вращение 3D
RunService.RenderStepped:Connect(function(dt)
    for _, model in ipairs(spinningModels) do
        if model and model.Parent then
            pcall(function()
                model.CFrame = model.CFrame * CFrame.Angles(0, math.rad(60 * dt), 0)
            end)
        end
    end
end)

-- ESP ITEMS
local function EnableItemESP()
    local current = {}
    for _, item in ipairs(GetListItems()) do
        current[item.part] = true
        if not ESP.Items[item.part] then
            local hl = Instance.new("Highlight")
            hl.FillColor = THEME.MAIN
            hl.FillTransparency = 0.7
            hl.OutlineColor = THEME.MAIN
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = item.part
            hl.Parent = ESPFolder
            ESP.Items[item.part] = hl
        end
    end
    for part, hl in pairs(ESP.Items) do
        if not current[part] then
            pcall(function() hl:Destroy() end)
            ESP.Items[part] = nil
        end
    end
end

local function DisableItemESP()
    for _, hl in pairs(ESP.Items) do pcall(function() hl:Destroy() end) end
    ESP.Items = {}
end

task.spawn(function()
    while true do
        if State.ESPItems then
            pcall(EnableItemESP)
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

-- ESP MONSTER
local function EnableMonsterESP()
    task.spawn(function()
        while State.ESPMonster do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                            local oHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                            if oHrp and (oHrp.Position - hrp.Position).Magnitude < 200 and not ESP.Monster[obj] then
                                local hl = Instance.new("Highlight")
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                                hl.FillTransparency = 0.5
                                hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee = obj
                                hl.Parent = ESPFolder
                                ESP.Monster[obj] = hl
                            end
                        end
                    end
                end
            end
            task.wait(1)
        end
        for _, hl in pairs(ESP.Monster) do pcall(function() hl:Destroy() end) end
        ESP.Monster = {}
    end)
end

local function DisableMonsterESP()
    for _, hl in pairs(ESP.Monster) do pcall(function() hl:Destroy() end) end
    ESP.Monster = {}
end

-- ESP PLAYERS
local function EnablePlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and not ESP.Players[plr] then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(0, 255, 0)
                hl.FillTransparency = 0.6
                hl.OutlineColor = Color3.fromRGB(0, 255, 0)
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = plr.Character
                hl.Parent = ESPFolder
                ESP.Players[plr] = hl
            end
        end
    end
end

local function DisablePlayerESP()
    for _, hl in pairs(ESP.Players) do pcall(function() hl:Destroy() end) end
    ESP.Players = {}
end

task.spawn(function()
    while true do
        if State.ESPPlayers then EnablePlayerESP() end
        task.wait(2)
    end
end)

-- ANTI-TRAP
task.spawn(function()
    while true do
        if State.AntiTrap then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.CanCollide then
                        local n = obj.Name:lower()
                        if n:find("trap") or n:find("lava") or n:find("spike") or n:find("kill") or n:find("damage") or n:find("bear") then
                            if (obj.Position - hrp.Position).Magnitude < 6 then
                                local ray = Ray.new(hrp.Position, Vector3.new(0, 25, 0))
                                local hit, pos = workspace:FindPartOnRay(ray, char)
                                if hit then hrp.CFrame = CFrame.new(pos - Vector3.new(0, 3, 0))
                                else hrp.CFrame = hrp.CFrame + Vector3.new(0, 15, 0) end
                                if not _G.__lastTrapNotify or tick() - _G.__lastTrapNotify > 2 then
                                    _G.__lastTrapNotify = tick()
                                    Notify("Anti-Trap!", 1)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- AUTO-AFK
task.spawn(function()
    while true do
        if State.AutoAFK then
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton1(Vector2.new(500, 500))
            end)
        end
        task.wait(60)
    end
end)

-- SEARCH
SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local q = (SearchBar.Text or ""):lower()
    for _, row in ipairs(ItemScroll:GetChildren()) do
        if row:IsA("TextButton") then
            local name = (row:GetAttribute("ItemName") or ""):lower()
            row.Visible = (q == "" or name:find(q, 1, true))
        end
    end
end)

-- BUTTON HANDLERS
ScanBtn.MouseButton1Click:Connect(function()
    Notify("Scanning...", 2)
    task.wait(0.3)
    if _G.__RefreshItemList then _G.__RefreshItemList() end
end)

OpenGameBtn.MouseButton1Click:Connect(function()
    local mainMenu = LP.PlayerGui:FindFirstChild("MainMenu")
    if mainMenu then
        local skf = mainMenu:FindFirstChild("SkinsFrame")
        if skf then skf.Visible = true; Notify("Menu opened", 2) end
    end
end)

RefreshBalBtn.MouseButton1Click:Connect(function()
    BalanceLabel.Text = "Piggy Coins: " .. GetPiggyCoins()
    Notify("Balance refreshed", 1)
end)

ResetBtn.MouseButton1Click:Connect(function()
    Notify("Reset", 2)
end)

-- Toggles handlers
task.spawn(function()
    local last1, last2 = false, false
    while true do
        task.wait(0.5)
        if State.ESPItems ~= last1 then
            last1 = State.ESPItems
            if State.ESPItems then EnableItemESP() else DisableItemESP() end
        end
        if State.ESPMonster ~= last2 then
            last2 = State.ESPMonster
            if State.ESPMonster then EnableMonsterESP() else DisableMonsterESP() end
        end
    end
end)

-- Авто-обновление списка
task.spawn(function()
    task.wait(1)
    if _G.__RefreshItemList then _G.__RefreshItemList() end
    while true do
        task.wait(3)
        if not scanInProgress and _G.__RefreshItemList then
            _G.__RefreshItemList()
        end
    end
end)

print("[XyqwPiggy v" .. VERSION .. "] Loaded!")
print("[XyqwPiggy v" .. VERSION .. "] Author: Xyqwerq")
Notify("XyqwPiggy v" .. VERSION .. " loaded!", 4)

end)

if not _ok then
    warn("[XyqwPiggy FATAL] " .. tostring(_err))
    print("[XyqwPiggy FATAL] " .. tostring(_err))
else
    print("[XyqwPiggy] Done")
end
