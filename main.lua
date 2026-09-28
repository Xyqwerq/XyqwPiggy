-- ============================================================
-- ========== XyqwPiggy v7.1 UNIVERSAL ==========
-- ============================================================
-- Автор: Xyqwerq
-- ✅ SkinChanger через addButton (loadScriptFromURL)
-- ✅ AutoFarm Gallery
-- ✅ Book 1 + Book 2 предметы
-- ✅ Исправлен скролл Misc
-- ============================================================

local VERSION = "7.1"
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP                = Players.LocalPlayer

-- CONFIG
local GAME_CONFIGS = {
    [4623386862] = { name = "Piggy Book 1" },
    [5661005779] = { name = "Piggy Book 2" },
}
local CURRENT_GAME = GAME_CONFIGS[game.PlaceId] or { name = "Unknown" }

-- THEME
local THEME = {
    BG     = Color3.fromRGB(0, 0, 0),
    DARK   = Color3.fromRGB(40, 0, 0),
    MAIN   = Color3.fromRGB(255, 0, 0),
    TITLE  = Color3.fromRGB(20, 0, 0),
    SUB    = Color3.fromRGB(200, 200, 200),
    ON     = Color3.fromRGB(0, 220, 90),
    OFF    = Color3.fromRGB(220, 0, 0),
    STROKE = Color3.fromRGB(120, 0, 0),
    WARN   = Color3.fromRGB(255, 200, 0),
    OK     = Color3.fromRGB(0, 255, 100),
    GOLD   = Color3.fromRGB(255, 215, 0),
}

local function Notify(text, duration)
    duration = duration or 2
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XyqwPiggy", Text = tostring(text), Duration = duration
        })
    end)
end

local function AddStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.STROKE
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function AddTextStroke(label)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 0, 0)
    s.Thickness = 1.5
    s.Parent = label
end

-- ============================================================
-- ⭐ ADD BUTTON (как в XyqwHub) — загрузка скриптов по URL
-- ============================================================
local function loadScriptFromURL(url, name)
    Notify("Loading " .. (name or "script") .. "...", 2)
    print("[XyqwPiggy] Loading: " .. url)
    
    local ok, err = pcall(function()
        -- Способ 1: loadstring + HttpGet
        if loadstring and game.HttpGet then
            local source = game.HttpGet(url)
            if source and #source > 0 then
                local fn = loadstring(source)
                if fn then
                    fn()
                    Notify("✓ " .. (name or "script") .. " loaded!", 2)
                    return
                end
            end
        end
        
        -- Способ 2: request
        if request then
            local r = request({Url = url, Method = "GET"})
            if r and r.Body then
                local fn = loadstring(r.Body)
                if fn then
                    fn()
                    Notify("✓ " .. (name or "script") .. " loaded!", 2)
                    return
                end
            end
        end
        
        -- Способ 3: http_request
        if http_request then
            local r = http_request({Url = url, Method = "GET"})
            if r and r.Body then
                local fn = loadstring(r.Body)
                if fn then
                    fn()
                    Notify("✓ " .. (name or "script") .. " loaded!", 2)
                    return
                end
            end
        end
        
        error("All methods failed")
    end)
    
    if not ok then
        Notify("Failed: " .. tostring(err), 4)
        print("[XyqwPiggy] Error: " .. tostring(err))
    end
end

local function addButton(name, url, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 32)
    btn.BackgroundColor3 = THEME.DARK
    btn.TextColor3 = THEME.MAIN
    btn.Text = name
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 2
    btn.BorderColor3 = THEME.MAIN
    btn.Parent = parent
    btn.AutoButtonColor = false
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
    AddStroke(btn, THEME.MAIN, 2); AddTextStroke(btn)
    
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
            if not moved and held < 0.4 then
                local mp = input.Position
                local cp, cs = btn.AbsolutePosition, btn.AbsoluteSize
                if mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then
                    loadScriptFromURL(url, name)
                end
            end
        end
    end)
    
    return btn
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    ScannedItems = {},
    SpinningModels = {},
    CurrentEquipped = nil,
    ESPItems = false,
    ESPMonster = false,
    ESPPlayers = false,
    AntiTrap = false,
    AutoAFK = false,
    lastScrollMisc = 0,
    miscScrolling = false,
}

-- CLEANUP
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

-- BALANCE
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
                    if cn and cn:IsA("TextLabel") then
                        return cn.Text
                    end
                end
            end
        end
    end
    return "?"
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

-- DOCK "XyqwPiggy" (закруглённая, красная обводка)
local DockBtn = Instance.new("TextButton")
DockBtn.Size = UDim2.new(0, 110, 0, 38)
DockBtn.Position = UDim2.new(0.03, 0, 0.15, 0)
DockBtn.BackgroundColor3 = THEME.BG
DockBtn.TextColor3 = THEME.MAIN
DockBtn.Text = "XyqwPiggy"
DockBtn.TextScaled = true
DockBtn.Font = Enum.Font.GothamBold
DockBtn.BorderSizePixel = 0
DockBtn.Parent = ScreenGui
DockBtn.AutoButtonColor = false
DockBtn.ZIndex = 1000
local DBC = Instance.new("UICorner"); DBC.CornerRadius = UDim.new(0, 12); DBC.Parent = DockBtn
AddStroke(DockBtn, THEME.MAIN, 2); AddTextStroke(DockBtn)

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.92, 0, 0.9, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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
TitleLabel.Size = UDim2.new(1, -160, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "XyqwPiggy v" .. VERSION
TitleLabel.TextColor3 = THEME.MAIN
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar
AddTextStroke(TitleLabel)

-- SkinChanger кнопка
local SkinBtn = Instance.new("TextButton")
SkinBtn.Size = UDim2.new(0, 80, 0, 22)
SkinBtn.Position = UDim2.new(1, -146, 0.5, -11)
SkinBtn.BackgroundColor3 = THEME.DARK
SkinBtn.TextColor3 = THEME.MAIN
SkinBtn.Text = "SkinChanger"
SkinBtn.TextScaled = true
SkinBtn.Font = Enum.Font.GothamBold
SkinBtn.BorderSizePixel = 1
SkinBtn.BorderColor3 = THEME.MAIN
SkinBtn.Parent = TitleBar
SkinBtn.AutoButtonColor = false
local SKB = Instance.new("UICorner"); SKB.CornerRadius = UDim.new(0, 5); SKB.Parent = SkinBtn
AddStroke(SkinBtn); AddTextStroke(SkinBtn)

-- Misc кнопка
local MiscBtn = Instance.new("TextButton")
MiscBtn.Size = UDim2.new(0, 38, 0, 22)
MiscBtn.Position = UDim2.new(1, -62, 0.5, -11)
MiscBtn.BackgroundColor3 = THEME.DARK
MiscBtn.TextColor3 = THEME.MAIN
MiscBtn.Text = "MISC"
MiscBtn.TextScaled = true
MiscBtn.Font = Enum.Font.GothamBold
MiscBtn.BorderSizePixel = 1
MiscBtn.BorderColor3 = THEME.MAIN
MiscBtn.Parent = TitleBar
MiscBtn.AutoButtonColor = false
local MBC = Instance.new("UICorner"); MBC.CornerRadius = UDim.new(0, 5); MBC.Parent = MiscBtn
AddStroke(MiscBtn); AddTextStroke(MiscBtn)

-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -24, 0.5, -11)
CloseBtn.BackgroundColor3 = THEME.DARK
CloseBtn.TextColor3 = THEME.MAIN
CloseBtn.Text = "X"
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 1
CloseBtn.BorderColor3 = THEME.MAIN
CloseBtn.Parent = TitleBar
CloseBtn.AutoButtonColor = false
local CB = Instance.new("UICorner"); CB.CornerRadius = UDim.new(0, 5); CB.Parent = CloseBtn
AddStroke(CloseBtn); AddTextStroke(CloseBtn)

-- BALANCE
local BalanceFrame = Instance.new("Frame")
BalanceFrame.Size = UDim2.new(1, -16, 0, 28)
BalanceFrame.Position = UDim2.new(0, 8, 0, 32)
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
BalanceLabel.TextScaled = true
BalanceLabel.Font = Enum.Font.GothamBold
BalanceLabel.TextXAlignment = Enum.TextXAlignment.Left
BalanceLabel.Parent = BalanceFrame
AddTextStroke(BalanceLabel)

-- SEARCH
local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(1, -16, 0, 24)
SearchBar.Position = UDim2.new(0, 8, 0, 66)
SearchBar.BackgroundColor3 = THEME.DARK
SearchBar.PlaceholderText = "Search items..."
SearchBar.PlaceholderColor3 = THEME.SUB
SearchBar.Text = ""
SearchBar.TextColor3 = THEME.MAIN
SearchBar.TextScaled = true
SearchBar.Font = Enum.Font.Gotham
SearchBar.ClearTextOnFocus = false
SearchBar.BorderSizePixel = 1
SearchBar.BorderColor3 = THEME.MAIN
SearchBar.Parent = MainFrame
local SC = Instance.new("UICorner"); SC.CornerRadius = UDim.new(0, 6); SC.Parent = SearchBar
AddStroke(SearchBar); AddTextStroke(SearchBar)

-- ITEM SCROLL
local ItemScroll = Instance.new("ScrollingFrame")
ItemScroll.Size = UDim2.new(1, -16, 1, -180)
ItemScroll.Position = UDim2.new(0, 8, 0, 96)
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
InfoLabel.TextScaled = true
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.BorderSizePixel = 1
InfoLabel.BorderColor3 = THEME.MAIN
InfoLabel.Parent = MainFrame
local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(0, 5); IC.Parent = InfoLabel
AddStroke(InfoLabel); AddTextStroke(InfoLabel)

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
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 1
    btn.BorderColor3 = THEME.MAIN
    btn.Parent = BtnFrame
    btn.AutoButtonColor = false
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
    AddStroke(btn); AddTextStroke(btn)
    return btn
end

local ScanBtn = MakeBtn("Scan", 0, 0.24)
local OpenGameBtn = MakeBtn("Menu", 0.25, 0.24)
local RefreshBalBtn = MakeBtn("Balance", 0.50, 0.24)
local ResetBtn = MakeBtn("Reset", 0.75, 0.24)

-- ============================================================
-- MISC FRAME
-- ============================================================
local MiscFrame = Instance.new("Frame")
MiscFrame.Size = UDim2.new(0, 230, 0, 320)
MiscFrame.Position = UDim2.new(0.5, 220, 0.5, -160)
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
MiscTitle.TextScaled = true
MiscTitle.Font = Enum.Font.GothamBold
MiscTitle.TextXAlignment = Enum.TextXAlignment.Left
MiscTitle.Parent = MiscTitleBar
AddTextStroke(MiscTitle)

local MiscClose = Instance.new("TextButton")
MiscClose.Size = UDim2.new(0, 20, 0, 20)
MiscClose.Position = UDim2.new(1, -24, 0.5, -10)
MiscClose.BackgroundColor3 = THEME.DARK
MiscClose.TextColor3 = THEME.MAIN
MiscClose.Text = "X"
MiscClose.TextScaled = true
MiscClose.Font = Enum.Font.GothamBold
MiscClose.BorderSizePixel = 1
MiscClose.BorderColor3 = THEME.MAIN
MiscClose.Parent = MiscTitleBar
MiscClose.AutoButtonColor = false
local MCC = Instance.new("UICorner"); MCC.CornerRadius = UDim.new(0, 5); MCC.Parent = MiscClose
AddStroke(MiscClose); AddTextStroke(MiscClose)

local MiscScroll = Instance.new("ScrollingFrame")
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

-- ФИКС СКРОЛЛА MISC
MiscScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    State.lastScrollMisc = tick()
    State.miscScrolling = true
    task.delay(0.4, function()
        State.miscScrolling = false
    end)
end)

-- ============================================================
-- TOGGLE BUILDER
-- ============================================================
local function MakeToggle(name, getState, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 28)
    row.BackgroundColor3 = THEME.DARK
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.MAIN
    row.Parent = MiscScroll
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
    AddStroke(row)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.MAIN
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    AddTextStroke(lbl)

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

    local function U() box.BackgroundColor3 = getState() and THEME.ON or THEME.OFF end
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

MakeToggle("ESP Items", function() return State.ESPItems end, function() State.ESPItems = not State.ESPItems end)
MakeToggle("ESP Monster", function() return State.ESPMonster end, function() State.ESPMonster = not State.ESPMonster end)
MakeToggle("ESP Players", function() return State.ESPPlayers end, function() State.ESPPlayers = not State.ESPPlayers end)
MakeToggle("Anti-Trap", function() return State.AntiTrap end, function() State.AntiTrap = not State.AntiTrap end)
MakeToggle("Auto-AFK", function() return State.AutoAFK end, function() State.AutoAFK = not State.AutoAFK end)
-- ============================================================
-- ESP FOLDER
-- ============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "XyqwPiggyESP"
ESPFolder.Parent = CoreGui

local ESP = { Items = {}, Monster = {}, Players = {}, Tools = {} }

-- ============================================================
-- GET ITEM NAME
-- ============================================================
local MESH_NAMES = {
    ["rbxassetid://725833400"]                    = "Hammer",
    ["rbxassetid://456878024"]                    = "Key",
    ["rbxassetid://524706126"]                    = "Gear",
    ["http://www.roblox.com/asset/?id=16884681"]  = "Tool",
    ["http://www.roblox.com/asset/?id=16198309"]  = "Plank",
    ["http://www.roblox.com/asset/?id=72012879"]  = "Battery",
    ["rbxassetid://6714051581"]                   = "Note",
    ["http://www.roblox.com/asset/?id=60791940"]  = "Gear",
}

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
    if n and n ~= "" and not n:match("^%-?%d+$") then
        return n
    end
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

-- ============================================================
-- IS DOOR / IS REAL ITEM
-- ============================================================
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
        c = c.Parent
        depth = depth + 1
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
        if ch:IsA("Script") and (ch.Name == "ItemPickupScript" or ch.Name == "NewItemPickupScript") then
            return true
        end
    end
    for _, ch in ipairs(part:GetChildren()) do
        if ch:IsA("RemoteEvent") and ch.Name == "ClickEvent" then return true end
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

-- ============================================================
-- 3D VIEW
-- ============================================================
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
        if maxE > 0.001 then
            model:ScaleTo(3)
        end
        if mp:IsA("BasePart") then
            mp.CFrame = CFrame.new(0, 0, 0)
        end
        local cam = Instance.new("Camera")
        cam.FieldOfView = 40
        cam.CFrame = CFrame.new(Vector3.new(4, 3, 4), Vector3.new(0, 0, 0))
        cam.Parent = vpf
        vpf.CurrentCamera = cam
        table.insert(spinningModels, mp)
    end)
end

-- ============================================================
-- TAKE ITEM
-- ============================================================
local function TakeItem(item)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local saved = hrp.CFrame
    pcall(function() item.detector.MaxActivationDistance = math.huge end)
    hrp.CFrame = CFrame.new(item.part.Position + Vector3.new(0, 3, 0))
    task.wait(0.3)
    pcall(function()
        if fireclickdetector then fireclickdetector(item.detector) end
    end)
    task.wait(0.25)
    hrp.CFrame = saved
    Notify("Took: " .. GetItemName(item), 2)
    task.delay(0.5, function()
        if not scanInProgress then
            _G.__RefreshItemList and _G.__RefreshItemList()
        end
    end)
end

-- ============================================================
-- REFRESH LIST
-- ============================================================
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
            AddStroke(row, THEME.STROKE, 1.5)
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
            nl.TextScaled = true
            nl.Font = Enum.Font.GothamBold
            nl.TextXAlignment = Enum.TextXAlignment.Left
            nl.TextTruncate = Enum.TextTruncate.AtEnd
            nl.Parent = row
            AddTextStroke(nl)
            local catcher = Instance.new("TextButton")
            catcher.Size = UDim2.new(1, 0, 1, 0)
            catcher.BackgroundTransparency = 1
            catcher.Text = ""
            catcher.ZIndex = 100
            catcher.AutoButtonColor = false
            catcher.Parent = row
            local pressStart, pressPos, moved, tracking = 0, nil, false, false
            catcher.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    pressStart = tick(); pressPos = input.Position; moved = false; tracking = true
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if tracking and pressPos and
                (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    if (input.Position - pressPos).Magnitude > 6 then moved = true end
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if not tracking then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    tracking = false
                    local held = tick() - pressStart
                    if not moved and held < 0.5 then
                        local mp = input.Position
                        local cp, cs = catcher.AbsolutePosition, catcher.AbsoluteSize
                        if mp.X >= cp.X and mp.X <= cp.X + cs.X
                        and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then
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

-- ============================================================
-- ESP ITEMS
-- ============================================================
local function EnableItemESP()
    for _, item in ipairs(GetListItems()) do
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
end

local function DisableItemESP()
    for _, hl in pairs(ESP.Items) do pcall(function() hl:Destroy() end) end
    ESP.Items = {}
end

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
                            if oHrp then
                                local dist = (oHrp.Position - hrp.Position).Magnitude
                                if dist < 200 then
                                    if not ESP.Monster[obj] then
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
                                else
                                    if ESP.Monster[obj] then
                                        pcall(function() ESP.Monster[obj]:Destroy() end)
                                        ESP.Monster[obj] = nil
                                    end
                                end
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
        if plr ~= LP and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not ESP.Players[plr] then
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
                        if n:find("trap") or n:find("lava") or n:find("spike")
                        or n:find("kill") or n:find("damage") or n:find("bear") then
                            if (obj.Position - hrp.Position).Magnitude < 6 then
                                hrp.CFrame = hrp.CFrame + Vector3.new(0, 25, 0)
                                Notify("Anti-Trap!", 1)
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
                if VirtualUser and VirtualUser.Button1Down then
                    VirtualUser:Button1Down(Vector2.new(0, 0))
                elseif VirtualUser and VirtualUser.ClickButton1 then
                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                end
            end)
        end
        task.wait(60)
    end)
end)

-- ============================================================
-- SEARCH
-- ============================================================
SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local q = (SearchBar.Text or ""):lower()
    for _, row in ipairs(ItemScroll:GetChildren()) do
        if row:IsA("TextButton") then
            local name = (row:GetAttribute("ItemName") or ""):lower()
            if q == "" or name:find(q, 1, true) then
                row.Visible = true
            else
                row.Visible = false
            end
        end
    end
end)

-- ============================================================
-- BUTTON HANDLERS
-- ============================================================
ScanBtn.MouseButton1Click:Connect(function()
    Notify("Scanning...", 2)
    task.wait(0.3)
    _G.__RefreshItemList()
end)

OpenGameBtn.MouseButton1Click:Connect(function()
    local mainMenu = LP.PlayerGui:FindFirstChild("MainMenu")
    if mainMenu then
        local skf = mainMenu:FindFirstChild("SkinsFrame")
        if skf then skf.Visible = true Notify("Menu opened", 2) end
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
    local lastESPItems = false
    local lastESPMonster = false
    while true do
        task.wait(0.5)
        if State.ESPItems ~= lastESPItems then
            lastESPItems = State.ESPItems
            if State.ESPItems then EnableItemESP() else DisableItemESP() end
        end
        if State.ESPMonster ~= lastESPMonster then
            lastESPMonster = State.ESPMonster
            if State.ESPMonster then EnableMonsterESP() else DisableMonsterESP() end
        end
    end
end)

-- Авто-обновление списка
task.spawn(function()
    task.wait(1)
    _G.__RefreshItemList()
    while true do
        task.wait(1)
        if not scanInProgress then
            _G.__RefreshItemList()
        end
    end
end)

print("[XyqwPiggy v" .. VERSION .. "] Part 2 loaded!")
-- ============================================================
-- AUTOFARM: REMOTES
-- ============================================================
local FarmRemotes = { JoinGame = nil, VIPCommandEvent = nil }

local function GetFarmRemote(name)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local r = remotes:FindFirstChild(name)
        if r then return r end
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == name and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            return obj
        end
    end
    return nil
end

local function RefreshFarmRemotes()
    FarmRemotes.JoinGame = GetFarmRemote("JoinGame")
    FarmRemotes.VIPCommandEvent = GetFarmRemote("VIPCommandEvent")
end

local function GetGamePhase()
    local gf = workspace:FindFirstChild("GameFolder")
    if not gf then return nil end
    local phase = gf:FindFirstChild("Phase")
    return phase and phase.Value or nil
end

local function SafeFireRemote(obj, ...)
    if not obj then return false end
    return pcall(function()
        if obj:IsA("RemoteEvent") then obj:FireServer(...)
        elseif obj:IsA("RemoteFunction") then obj:InvokeServer(...) end
    end)
end

local function SafeClickBtn(btn)
    if not btn then return false end
    if firesignal then
        local ok = pcall(function() firesignal(btn.MouseButton1Click) end)
        if ok then return true end
    end
    return pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                pcall(function() conn:Fire() end)
            end
        end
    end)
end

local function FarmPressPlay()
    if FarmRemotes.JoinGame then
        if SafeFireRemote(FarmRemotes.JoinGame, true) then
            task.wait(0.4)
            return true
        end
    end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local mm = pg:FindFirstChild("MainMenu")
        if mm then
            local ms = mm:FindFirstChild("MainScreen")
            if ms then
                local cf = ms:FindFirstChild("CenterFrame")
                if cf then
                    local cb = cf:FindFirstChild("CenterButtons")
                    if cb then
                        local playBtn = cb:FindFirstChild("Play")
                        if playBtn then
                            SafeClickBtn(playBtn)
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function FarmPressSkip()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    local mm = pg:FindFirstChild("MainMenu")
    if not mm then return false end
    local skipBtn = mm:FindFirstChild("Skip")
    if skipBtn then
        SafeClickBtn(skipBtn)
        return true
    end
    return false
end

local function FarmSetupGallery()
    if not FarmRemotes.VIPCommandEvent then RefreshFarmRemotes() end
    if not FarmRemotes.VIPCommandEvent then return false end
    SafeFireRemote(FarmRemotes.VIPCommandEvent, "SetMap", State.FarmConfig.MAP)
    task.wait(0.3)
    SafeFireRemote(FarmRemotes.VIPCommandEvent, "SetMode", State.FarmConfig.MODE)
    task.wait(0.3)
    if State.FarmConfig.SKIP_TIMER then
        SafeFireRemote(FarmRemotes.VIPCommandEvent, "SkipTimer", true)
        task.wait(0.2)
        SafeFireRemote(FarmRemotes.VIPCommandEvent, "SkipTimer", true)
    end
    return true
end

local function FarmCollectOnce()
    local collected = 0
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local itemFolder = workspace:FindFirstChild("ItemFolder")
    if not itemFolder then return 0 end
    for _, item in ipairs(itemFolder:GetChildren()) do
        if State.FarmNeedStop then break end
        if item:IsA("BasePart") then
            local cd = item:FindFirstChildOfClass("ClickDetector")
            if cd then
                pcall(function() hrp.CFrame = CFrame.new(item.Position + Vector3.new(0, 2, 0)) end)
                task.wait(State.FarmConfig.COLLECT_DELAY)
                pcall(function()
                    if fireclickdetector then fireclickdetector(cd) end
                end)
                collected = collected + 1
                State.FarmItemsCollected = State.FarmItemsCollected + 1
                State.FarmLastActivity = tick()
            end
        end
    end
    return collected
end

local function FarmCollectLoop()
    local startTime = tick()
    while not State.FarmNeedStop do
        local phase = GetGamePhase()
        if phase ~= "GameInProgress" then break end
        if tick() - startTime > State.FarmConfig.MAX_GAME_TIME then break end
        FarmCollectOnce()
        task.wait(State.FarmConfig.RESCAN_DELAY)
    end
end

local function FarmMainLoop()
    State.FarmRunning = true
    Notify("AutoFarm started!", 3)
    RefreshFarmRemotes()

    while State.FarmConfig.AUTO_LOOP and not State.FarmNeedStop do
        State.FarmCurrentCycle = State.FarmCurrentCycle + 1
        State.FarmItemsCollected = 0
        State.FarmLastActivity = tick()

        local phase = GetGamePhase()
        if not phase or phase == "GameInProgress" then
            local t = tick()
            while tick() - t < 200 do
                if State.FarmNeedStop then break end
                if GetGamePhase() == "Intermission" then break end
                task.wait(0.5)
            end
        end

        if State.FarmNeedStop then break end

        if State.FarmConfig.AUTO_PLAY then
            local p = GetGamePhase()
            if p == nil or p == "Intermission" then
                FarmPressPlay()
                task.wait(1)
            end
        end

        FarmSetupGallery()
        task.wait(1)

        local t2 = tick()
        while tick() - t2 < 90 do
            if State.FarmNeedStop then break end
            local p = GetGamePhase()
            if p == "GameInProgress" then break end
            if p == "Map Voting" or p == "Piggy Voting" then
                if not _G.__lastSkipVote or tick() - _G.__lastSkipVote > 5 then
                    _G.__lastSkipVote = tick()
                    SafeFireRemote(FarmRemotes.VIPCommandEvent, "SkipTimer", true)
                end
            end
            task.wait(0.5)
        end

        if State.FarmNeedStop then break end

        if GetGamePhase() == "GameInProgress" then
            task.wait(2)
            if State.FarmConfig.AUTO_COLLECT then
                FarmCollectLoop()
            end
            if State.FarmConfig.AUTO_SKIP and not State.FarmNeedStop then
                task.wait(2)
                FarmPressSkip()
                task.wait(3)
                FarmPressSkip()
            end
        end

        task.wait(3)
    end

    State.FarmRunning = false
    Notify("AutoFarm stopped", 3)
end

_G.__FarmMainLoop = FarmMainLoop

-- ============================================================
-- AUTO FARM CONFIRM WINDOW
-- ============================================================
local function IsPrivateServer()
    local gf = workspace:FindFirstChild("GameFolder")
    if gf then
        local vipsv = gf:FindFirstChild("IsVIPServer")
        if vipsv and vipsv:IsA("BoolValue") then
            return vipsv.Value
        end
    end
    return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

local function ShowAutoFarmConfirm()
    for _, obj in ipairs(ScreenGui:GetChildren()) do
        if obj.Name == "AutoFarmConfirm" then obj:Destroy() end
    end

    local isPrivate = IsPrivateServer()

    local confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "AutoFarmConfirm"
    confirmFrame.Size = UDim2.new(0, 360, 0, 300)
    confirmFrame.Position = UDim2.new(0.5, -180, 0.5, -150)
    confirmFrame.BackgroundColor3 = THEME.BG
    confirmFrame.BorderSizePixel = 3
    confirmFrame.BorderColor3 = THEME.MAIN
    confirmFrame.Active = true
    confirmFrame.ZIndex = 100
    confirmFrame.Parent = ScreenGui
    local cfc = Instance.new("UICorner"); cfc.CornerRadius = UDim.new(0, 10); cfc.Parent = confirmFrame

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = THEME.TITLE
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 101
    titleBar.Parent = confirmFrame
    local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 10); tbc.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "XyqwPiggy | READ THIS!!"
    title.TextColor3 = THEME.MAIN
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 102
    title.Parent = titleBar
    AddTextStroke(title)

    local warnText = Instance.new("TextLabel")
    warnText.Size = UDim2.new(1, -20, 0, 60)
    warnText.Position = UDim2.new(0, 10, 0, 42)
    warnText.BackgroundTransparency = 1
    warnText.Text = "AutoFarm works only on PRIVATE servers and on the Gallery map (AutoFarm selects it automatically)"
    warnText.TextColor3 = Color3.fromRGB(255, 255, 255)
    warnText.TextScaled = true
    warnText.Font = Enum.Font.GothamBold
    warnText.TextWrapped = true
    warnText.TextXAlignment = Enum.TextXAlignment.Center
    warnText.ZIndex = 102
    warnText.Parent = confirmFrame
    AddTextStroke(warnText)

    local serverStatus = Instance.new("TextLabel")
    serverStatus.Size = UDim2.new(1, -20, 0, 50)
    serverStatus.Position = UDim2.new(0, 10, 0, 110)
    serverStatus.BackgroundTransparency = 1
    if isPrivate then
        serverStatus.Text = "You are currently on a PRIVATE server."
        serverStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        serverStatus.Text = "You are currently on a PUBLIC server, AutoFarm may not work!"
        serverStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
    serverStatus.TextScaled = true
    serverStatus.Font = Enum.Font.GothamBold
    serverStatus.TextWrapped = true
    serverStatus.TextXAlignment = Enum.TextXAlignment.Center
    serverStatus.ZIndex = 102
    serverStatus.Parent = confirmFrame
    AddTextStroke(serverStatus)

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0.45, -10, 0, 48)
    cancelBtn.Position = UDim2.new(0, 10, 1, -58)
    cancelBtn.BackgroundColor3 = THEME.DARK
    cancelBtn.TextColor3 = THEME.MAIN
    cancelBtn.Text = "Cancel"
    cancelBtn.TextScaled = true
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.BorderSizePixel = 2
    cancelBtn.BorderColor3 = THEME.MAIN
    cancelBtn.ZIndex = 102
    cancelBtn.Parent = confirmFrame
    cancelBtn.AutoButtonColor = false
    local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 6); cbc.Parent = cancelBtn
    AddStroke(cancelBtn, THEME.MAIN, 2); AddTextStroke(cancelBtn)

    local runBtn = Instance.new("TextButton")
    runBtn.Size = UDim2.new(0.45, -10, 0, 48)
    runBtn.Position = UDim2.new(0.5, 0, 1, -58)
    runBtn.BackgroundColor3 = THEME.DARK
    runBtn.TextColor3 = THEME.SUB
    runBtn.Text = "Run AutoFarm (5)"
    runBtn.TextScaled = true
    runBtn.Font = Enum.Font.GothamBold
    runBtn.BorderSizePixel = 2
    runBtn.BorderColor3 = THEME.SUB
    runBtn.ZIndex = 102
    runBtn.Parent = confirmFrame
    runBtn.AutoButtonColor = false
    local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(0, 6); rbc.Parent = runBtn
    AddStroke(runBtn, THEME.SUB, 2); AddTextStroke(runBtn)

    local canRun = false

    task.spawn(function()
        for i = 5, 1, -1 do
            runBtn.Text = "Run AutoFarm (" .. i .. ")"
            task.wait(1)
            if not confirmFrame.Parent then return end
        end
        canRun = true
        runBtn.Text = "Run AutoFarm"
        runBtn.TextColor3 = THEME.OK
        runBtn.BorderColor3 = THEME.OK
        AddStroke(runBtn, THEME.OK, 2)
    end)

    cancelBtn.MouseButton1Click:Connect(function()
        confirmFrame:Destroy()
        Notify("AutoFarm cancelled", 2)
    end)

    runBtn.MouseButton1Click:Connect(function()
        if not canRun then
            Notify("Please wait!", 2)
            return
        end
        confirmFrame:Destroy()
        State.FarmNeedStop = false
        State.FarmCurrentCycle = 0
        State.FarmItemsCollected = 0
        task.spawn(FarmMainLoop)
    end)
end

-- ============================================================
-- MISC BUTTONS: AutoFarm + SkinChanger
-- ============================================================
local function MakeMiscBtn(name, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 34)
    btn.BackgroundColor3 = THEME.DARK
    btn.TextColor3 = color
    btn.Text = name
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 2
    btn.BorderColor3 = color
    btn.Parent = MiscScroll
    btn.AutoButtonColor = false
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
    AddStroke(btn, color, 2); AddTextStroke(btn)

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

MakeMiscBtn("🤖 Run AutoFarm", Color3.fromRGB(0, 200, 255), function()
    ShowAutoFarmConfirm()
end)

MakeMiscBtn("⏹ Stop AutoFarm", Color3.fromRGB(255, 0, 0), function()
    State.FarmNeedStop = true
    State.FarmRunning = false
    Notify("AutoFarm stopped", 2)
end)

-- ============================================================
-- ⭐ SKINCHANGER через addButton (как в XyqwHub)
-- ============================================================
local SKINCHANGER_URL = "https://raw.githubusercontent.com/Xyqwerq/XyqwSkinChanger-Piggy/main/main.lua"

SkinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiscFrame.Visible = false
    DockBtn.Visible = true
    
    loadScriptFromURL(SKINCHANGER_URL, "SkinChanger")
end)

-- ============================================================
-- DRAG MAIN
-- ============================================================
local mDrag, mStart, mStartPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mp = input.Position
        local function over(b)
            local p, s = b.AbsolutePosition, b.AbsoluteSize
            return mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
        end
        if over(CloseBtn) or over(MiscBtn) or over(SkinBtn) then return end
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
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiscFrame.Visible = false
    DockBtn.Visible = true
end)

MiscBtn.MouseButton1Click:Connect(function()
    MiscFrame.Visible = not MiscFrame.Visible
end)
MiscClose.MouseButton1Click:Connect(function()
    MiscFrame.Visible = false
end)

-- DOCK drag
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
        if MainFrame.Parent then
            BalanceLabel.Text = "Piggy Coins: " .. GetPiggyCoins()
        end
    end
end)

-- ============================================================
-- LOAD
-- ============================================================
print("[XyqwPiggy v" .. VERSION .. "] Loaded!")
print("[XyqwPiggy v" .. VERSION .. "] Game: " .. CURRENT_GAME.name)
print("[XyqwPiggy v" .. VERSION .. "] SkinChanger через addButton (loadScriptFromURL)")
print("[XyqwPiggy v" .. VERSION .. "] AutoFarm в Misc")
print("[XyqwPiggy v" .. VERSION .. "] By Xyqwerq")

Notify("XyqwPiggy v" .. VERSION .. " loaded!", 4)
