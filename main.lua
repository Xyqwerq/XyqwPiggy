-- ========== XyqwPiggy v2.3 ==========
-- Piggy Script | made by Xyqwerq
-- Только ITEMS. Двери убраны. Подобранные скрыты.

local VERSION = "2.3"
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")
local LP                = Players.LocalPlayer

local THEME = {
    BG     = Color3.fromRGB(0, 0, 0),
    DARK   = Color3.fromRGB(40, 0, 0),
    MAIN   = Color3.fromRGB(255, 0, 0),
    TITLE  = Color3.fromRGB(20, 0, 0),
    SUB    = Color3.fromRGB(180, 180, 180),
    ON     = Color3.fromRGB(0, 220, 90),
    OFF    = Color3.fromRGB(220, 0, 0),
    STROKE = Color3.fromRGB(120, 0, 0),
    ITEM   = Color3.fromRGB(0, 255, 255),
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
    s.Thickness = thickness or 1.5
    s.Parent = parent
    return s
end

local function AddTextStroke(label)
    local s = Instance.new("UIStroke")
    s.Color = THEME.STROKE
    s.Thickness = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    s.Parent = label
end

-- ============================================================
-- MESH → NAME
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

-- ============================================================
-- GET ITEM NAME (расширенный, безопасный)
-- ============================================================
local function GetItemName(item)
    local part = item.part
    if not part then return "Unknown" end

    -- 1) ParticleEmitter цвет → ключи (безопасно через Keypoints)
    local pe = part:FindFirstChildOfClass("ParticleEmitter")
    if pe and pe.Color and pe.Color.Keypoints and #pe.Color.Keypoints > 0 then
        local c = pe.Color.Keypoints[1].Value
        if c.R > 0.9 and c.G < 0.3 and c.B < 0.3 then return "Red Key" end
        if c.B > 0.9 and c.R < 0.3 and c.G < 0.3 then return "Blue Key" end
        if c.G > 0.9 and c.R < 0.3 and c.B < 0.3 then return "Green Key" end
        if c.B > 0.9 and c.G > 0.9 and c.R < 0.3 then return "Cyan Key" end
        if c.R > 0.9 and c.G > 0.9 and c.B < 0.3 then return "Yellow Key" end
        if c.R > 0.9 and c.G > 0.3 and c.B < 0.1 then return "Orange Key" end
        if c.R > 0.5 and c.G < 0.4 and c.B > 0.9 then return "Purple Key" end
        if c.R > 0.9 and c.G > 0.5 and c.B > 0.9 then return "Pink Key" end
        if c.R > 0.9 and c.G > 0.9 and c.B > 0.9 then return "White Key" end
    end

    -- 2) MeshId
    local mesh = part:FindFirstChildOfClass("SpecialMesh")
    if mesh and mesh.MeshId and MESH_NAMES[mesh.MeshId] then
        return MESH_NAMES[mesh.MeshId]
    end

    -- 3) Имя части (если осмысленное)
    local n = part.Name
    if n and n ~= "" and not n:match("^%-?%d+$") then
        return n
    end

    return "Item"
end

-- ============================================================
-- MENU FILTER
-- ============================================================
local MENU_NAMES = {
    MenuCameras = true, MainMenuForest = true, MainMenuScreen = true,
    ItemsScreen = true, ItemsFocus = true, ItemsCamera = true,
    MenuPositions = true,
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

-- ============================================================
-- IS REAL ITEM (только реальные подбираемые предметы)
-- ============================================================
local KNOWN_ITEM_MESHES = {
    ["rbxassetid://725833400"] = true,                     -- Hammer
    ["rbxassetid://456878024"] = true,                     -- Key
    ["rbxassetid://524706126"] = true,                     -- Gear
    ["http://www.roblox.com/asset/?id=16884681"] = true,   -- Tool
    ["http://www.roblox.com/asset/?id=16198309"] = true,   -- Plank
    ["http://www.roblox.com/asset/?id=72012879"] = true,   -- Battery
    ["rbxassetid://6714051581"] = true,                    -- Note
    ["http://www.roblox.com/asset/?id=60791940"] = true,   -- Gear
}

-- Является ли часть настоящим ПОДБИРАЕМЫМ предметом
local function IsRealItem(part)
    -- 1) ParticleEmitter ВКЛЮЧЁН → точно предмет в игре
    local pe = part:FindFirstChildOfClass("ParticleEmitter")
    if pe and pe.Enabled then return true end
    -- 2) ItemPickupScript
    for _, ch in ipairs(part:GetChildren()) do
        if ch:IsA("Script") and ch.Name == "ItemPickupScript" then return true end
    end
    return false
end

-- Уже подобран / невидим / нельзя взять
local function IsAlreadyPickedUp(part)
    -- Невидимый
    if part.Transparency >= 1 then return true end
    -- ParticleEmitter выключен (значит подобрали)
    local pe = part:FindFirstChildOfClass("ParticleEmitter")
    if pe and not pe.Enabled then return true end
    -- MaxActivationDistance = 0 (нельзя кликнуть)
    local cd = part:FindFirstChildOfClass("ClickDetector")
    if cd and cd.MaxActivationDistance <= 0 then return true end
    return false
end

-- ============================================================
-- GET LIST ITEMS (ТОЛЬКО реальные подбираемые предметы)
-- ============================================================
local function GetListItems()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local part = obj.Parent
            if part and part:IsA("BasePart") and not IsInMenu(part) then
                if IsRealItem(part) and not IsAlreadyPickedUp(part) then
                    table.insert(items, {
                        part = part,
                        detector = obj,
                        type = "Item",
                    })
                end
            end
        end
    end
    return items
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    ESP = { Items = false, Monster = false, Players = false },
    ToolIndicator = false,
    AntiTrap = false,
    DeletePiggy = false,
}

-- ============================================================
-- CLEANUP
-- ============================================================
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

-- ============================================================
-- MAIN FRAME
-- ============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
MainFrame.BackgroundColor3 = THEME.BG
MainFrame.BorderSizePixel = 3
MainFrame.BorderColor3 = THEME.MAIN
MainFrame.Active = true
MainFrame.Parent = ScreenGui
local MC = Instance.new("UICorner"); MC.CornerRadius = UDim.new(0, 10); MC.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = THEME.TITLE
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local TC = Instance.new("UICorner"); TC.CornerRadius = UDim.new(0, 10); TC.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "XyqwPiggy v" .. VERSION .. " | made by Xyqwerq"
TitleLabel.TextColor3 = THEME.MAIN
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar
AddTextStroke(TitleLabel)

local MiscBtn = Instance.new("TextButton")
MiscBtn.Size = UDim2.new(0, 22, 0, 22)
MiscBtn.Position = UDim2.new(1, -52, 0.5, -11)
MiscBtn.BackgroundColor3 = THEME.DARK
MiscBtn.TextColor3 = THEME.MAIN
MiscBtn.Text = "M"
MiscBtn.TextScaled = true
MiscBtn.Font = Enum.Font.GothamBold
MiscBtn.BorderSizePixel = 1
MiscBtn.BorderColor3 = THEME.MAIN
MiscBtn.Parent = TitleBar
MiscBtn.AutoButtonColor = false
local MB = Instance.new("UICorner"); MB.CornerRadius = UDim.new(0, 5); MB.Parent = MiscBtn
AddStroke(MiscBtn); AddTextStroke(MiscBtn)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
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

local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(1, -20, 0, 24)
SearchBar.Position = UDim2.new(0, 10, 0, 36)
SearchBar.BackgroundColor3 = THEME.DARK
SearchBar.PlaceholderText = "Search items..."
SearchBar.PlaceholderColor3 = THEME.SUB
SearchBar.Text = ""
SearchBar.TextColor3 = THEME.MAIN
SearchBar.TextSize = 12
SearchBar.Font = Enum.Font.Gotham
SearchBar.ClearTextOnFocus = false
SearchBar.BorderSizePixel = 1
SearchBar.BorderColor3 = THEME.MAIN
SearchBar.Parent = MainFrame
local SC = Instance.new("UICorner"); SC.CornerRadius = UDim.new(0, 6); SC.Parent = SearchBar
AddStroke(SearchBar); AddTextStroke(SearchBar)

local ItemScroll = Instance.new("ScrollingFrame")
ItemScroll.Size = UDim2.new(1, -20, 1, -140)
ItemScroll.Position = UDim2.new(0, 10, 0, 66)
ItemScroll.BackgroundTransparency = 1
ItemScroll.BorderSizePixel = 0
ItemScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemScroll.ScrollBarThickness = 4
ItemScroll.ScrollBarImageColor3 = THEME.MAIN
ItemScroll.ScrollingDirection = Enum.ScrollingDirection.Y
ItemScroll.Parent = MainFrame

local ItemLayout = Instance.new("UIListLayout")
ItemLayout.Padding = UDim.new(0, 4)
ItemLayout.Parent = ItemScroll
ItemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ItemScroll.CanvasSize = UDim2.new(0, 0, 0, ItemLayout.AbsoluteContentSize.Y + 10)
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 16)
StatusLabel.Position = UDim2.new(0, 10, 1, -68)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Items: 0"
StatusLabel.TextColor3 = THEME.SUB
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0, 140, 0, 32)
ScanBtn.Position = UDim2.new(0.5, -70, 1, -42)
ScanBtn.BackgroundColor3 = THEME.BG
ScanBtn.TextColor3 = THEME.MAIN
ScanBtn.Text = "Scan"
ScanBtn.TextScaled = true
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.BorderSizePixel = 1
ScanBtn.BorderColor3 = THEME.MAIN
ScanBtn.Parent = MainFrame
ScanBtn.AutoButtonColor = false
ScanBtn.ZIndex = 10
AddStroke(ScanBtn, THEME.MAIN, 2); AddTextStroke(ScanBtn)

-- ============================================================
-- MISC FRAME
-- ============================================================
local MiscFrame = Instance.new("Frame")
MiscFrame.Size = UDim2.new(0, 220, 0, 250)
MiscFrame.Position = UDim2.new(0.5, 180, 0.3, 0)
MiscFrame.BackgroundColor3 = THEME.BG
MiscFrame.BorderSizePixel = 3
MiscFrame.BorderColor3 = THEME.MAIN
MiscFrame.Active = true
MiscFrame.Visible = false
MiscFrame.Parent = ScreenGui
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
MiscScroll.ScrollBarThickness = 4
MiscScroll.ScrollBarImageColor3 = THEME.MAIN
MiscScroll.Parent = MiscFrame

local ML = Instance.new("UIListLayout")
ML.Padding = UDim.new(0, 4)
ML.Parent = MiscScroll
ML:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MiscScroll.CanvasSize = UDim2.new(0, 0, 0, ML.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- SCROLL GUARDS
-- ============================================================
local lastScrollItem, lastScrollMisc = 0, 0
ItemScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    lastScrollItem = tick()
end)
MiscScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    lastScrollMisc = tick()
end)

-- ============================================================
-- DOCK BUTTON
-- ============================================================
local DockBtn = Instance.new("TextButton")
DockBtn.Size = UDim2.new(0, 110, 0, 32)
DockBtn.Position = UDim2.new(0.5, -55, 0.05, 42)
DockBtn.BackgroundColor3 = THEME.BG
DockBtn.TextColor3 = THEME.MAIN
DockBtn.Text = "XyqwPiggy"
DockBtn.TextScaled = true
DockBtn.Font = Enum.Font.GothamBold
DockBtn.BorderSizePixel = 3
DockBtn.BorderColor3 = THEME.MAIN
DockBtn.Parent = ScreenGui
DockBtn.Visible = false
DockBtn.AutoButtonColor = false
DockBtn.ZIndex = 999
local DC = Instance.new("UICorner"); DC.CornerRadius = UDim.new(0, 10); DC.Parent = DockBtn
AddTextStroke(DockBtn)

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
        if not dockMoved then MainFrame.Visible = true; DockBtn.Visible = false end
        dockDrag = false
    end
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
    end
end)

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

MiscBtn.MouseButton1Click:Connect(function()
    MiscFrame.Visible = not MiscFrame.Visible
end)
MiscClose.MouseButton1Click:Connect(function() MiscFrame.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false; MiscFrame.Visible = false; DockBtn.Visible = true
end)

-- ============================================================
-- ESP FOLDER
-- ============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "XyqwPiggyESP"
ESPFolder.Parent = CoreGui

local ESP = { Items = {}, Monster = {}, Players = {}, Tools = {} }

local function EnableItemESP()
    for _, item in ipairs(GetListItems()) do
        if not ESP.Items[item.part] then
            local hl = Instance.new("Highlight")
            hl.FillColor = THEME.ITEM
            hl.FillTransparency = 0.7
            hl.OutlineColor = THEME.ITEM
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

local function EnableMonsterESP()
    task.spawn(function()
        while State.ESP.Monster do
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
    State.ESP.Monster = false
    for _, hl in pairs(ESP.Monster) do pcall(function() hl:Destroy() end) end
    ESP.Monster = {}
end

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
        if State.ESP.Players then EnablePlayerESP() end
        task.wait(2)
    end
end)

local function EnableToolIndicator()
    task.spawn(function()
        while State.ToolIndicator do
            local char = LP.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                for _, item in ipairs(GetListItems()) do
                    if not ESP.Tools[item.part] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = THEME.ITEM
                        hl.FillTransparency = 0.6
                        hl.OutlineColor = THEME.ITEM
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Adornee = item.part
                        hl.Parent = ESPFolder
                        ESP.Tools[item.part] = hl
                    end
                end
            else
                for _, hl in pairs(ESP.Tools) do pcall(function() hl:Destroy() end) end
                ESP.Tools = {}
            end
            task.wait(1)
        end
        for _, hl in pairs(ESP.Tools) do pcall(function() hl:Destroy() end) end
        ESP.Tools = {}
    end)
end

local function EnableAntiTrap()
    task.spawn(function()
        while State.AntiTrap do
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
                                Notify("Anti-Trap: Detected!", 1)
                                break
                            end
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

local dPConn = nil
local function EnableDeletePiggy()
    if dPConn then return end
    State.DeletePiggy = true
    dPConn = RunService.Heartbeat:Connect(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                    pcall(function() hum.Health = 0 end)
                    pcall(function() obj.Parent = nil end)
                end
            end
        end
    end)
end

local function DisableDeletePiggy()
    State.DeletePiggy = false
    if dPConn then dPConn:Disconnect(); dPConn = nil end
end

-- ============================================================
-- TOGGLE (input-based)
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
    catcher.Position = UDim2.new(0, 0, 0, 0)
    catcher.BackgroundTransparency = 1
    catcher.Text = ""
    catcher.ZIndex = 10
    catcher.AutoButtonColor = false
    catcher.Parent = row

    local pressStart, pressPos, moved, tracking = 0, nil, false, false

    catcher.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            pressStart = tick()
            pressPos = input.Position
            moved = false
            tracking = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if tracking and pressPos and
        (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = (input.Position - pressPos).Magnitude
            if d > 6 then moved = true end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not tracking then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            tracking = false
            local held = tick() - pressStart
            if not moved and held < 0.5 and (tick() - lastScrollMisc) > 0.3 then
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

MakeToggle("Delete Piggy (Visual)", function() return State.DeletePiggy end, function()
    if State.DeletePiggy then DisableDeletePiggy() else EnableDeletePiggy() end
end)
MakeToggle("ESP Items", function() return State.ESP.Items end, function()
    State.ESP.Items = not State.ESP.Items
    if State.ESP.Items then EnableItemESP() else DisableItemESP() end
end)
MakeToggle("ESP Monster", function() return State.ESP.Monster end, function()
    State.ESP.Monster = not State.ESP.Monster
    if State.ESP.Monster then EnableMonsterESP() else DisableMonsterESP() end
end)
MakeToggle("ESP Players", function() return State.ESP.Players end, function()
    State.ESP.Players = not State.ESP.Players
    if State.ESP.Players then EnablePlayerESP() else DisablePlayerESP() end
end)
MakeToggle("Tool Usage", function() return State.ToolIndicator end, function()
    State.ToolIndicator = not State.ToolIndicator
    if State.ToolIndicator then EnableToolIndicator() end
end)
MakeToggle("Anti-Trap", function() return State.AntiTrap end, function()
    State.AntiTrap = not State.AntiTrap
    if State.AntiTrap then EnableAntiTrap() end
end)

-- ============================================================
-- 3D VIEW (WorldModel + ScaleTo)
-- ============================================================
local currentItems = {}
local spinningModels = {}
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
            or ch:IsA("Decal") or ch:IsA("Texture") then
                if not ch:IsA("Decal") and not ch:IsA("Texture") then
                    ch:Destroy()
                end
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
        else
            local mesh = mp:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                local sz = mp.Size
                local effX = math.abs(sz.X * mesh.Scale.X)
                local effY = math.abs(sz.Y * mesh.Scale.Y)
                local effZ = math.abs(sz.Z * mesh.Scale.Z)
                local mE = math.max(effX, effY, effZ)
                if mE > 0.001 then
                    local k = 3.0 / mE
                    mesh.Scale = Vector3.new(mesh.Scale.X * k, mesh.Scale.Y * k, mesh.Scale.Z * k)
                end
            end
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
    if not char then Notify("No character!", 2) return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then Notify("No HRP!", 2) return end

    local saved = hrp.CFrame
    pcall(function() item.detector.MaxActivationDistance = math.huge end)
    hrp.CFrame = CFrame.new(item.part.Position + Vector3.new(0, 3, 0))
    task.wait(0.3)

    local fired = false
    pcall(function()
        if fireclickdetector then
            fireclickdetector(item.detector)
            fired = true
        end
    end)

    task.wait(0.25)
    hrp.CFrame = saved

    if fired then
        Notify("Took: " .. GetItemName(item), 2)
    else
        Notify("Cannot take: " .. GetItemName(item), 2)
    end

    -- Автообновление списка через 0.5 сек
    task.delay(0.5, function()
        if not scanInProgress then
            RefreshItemList()
        end
    end)
end

-- ============================================================
-- REFRESH LIST
-- ============================================================
function RefreshItemList()
    if scanInProgress then return end
    scanInProgress = true

    for _, ch in ipairs(ItemScroll:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    spinningModels = {}

    currentItems = GetListItems()
    StatusLabel.Text = "Items: " .. #currentItems

    if #currentItems == 0 then
        Notify("No items found. Wait for game.", 3)
    else
        Notify("Found: " .. #currentItems .. " items", 2)
    end

    for i, item in ipairs(currentItems) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, -5, 0, 50)
        row.BackgroundColor3 = THEME.DARK
        row.BorderSizePixel = 1
        row.BorderColor3 = THEME.MAIN
        row.Text = ""
        row.Parent = ItemScroll
        row.AutoButtonColor = false
        row.ClipsDescendants = false
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
        AddStroke(row, THEME.ITEM, 1.5)

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
        nl.Size = UDim2.new(1, -60, 1, 0)
        nl.Position = UDim2.new(0, 52, 0, 0)
        nl.BackgroundTransparency = 1
        nl.Text = itemName
        nl.TextColor3 = THEME.ITEM
        nl.TextScaled = true
        nl.Font = Enum.Font.GothamBold
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.TextTruncate = Enum.TextTruncate.AtEnd
        nl.Parent = row
        AddTextStroke(nl)

        -- Click-catcher
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
                pressStart = tick()
                pressPos = input.Position
                moved = false
                tracking = true
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if tracking and pressPos and
            (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local d = (input.Position - pressPos).Magnitude
                if d > 6 then moved = true end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if not tracking then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                tracking = false
                local held = tick() - pressStart
                if not moved and held < 0.5 and (tick() - lastScrollItem) > 0.3 then
                    local mp = input.Position
                    local cp, cs = catcher.AbsolutePosition, catcher.AbsoluteSize
                    if mp.X >= cp.X and mp.X <= cp.X + cs.X
                    and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then
                        TakeItem(item)
                    end
                end
                pressPos = nil
            end
        end)
    end

    scanInProgress = false
end

-- Spin 3D
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
-- SCAN
-- ============================================================
ScanBtn.MouseButton1Click:Connect(function()
    Notify("Scanning...", 2)
    task.wait(0.3)
    RefreshItemList()
end)

-- Авто-обновление каждые 5 сек
task.spawn(function()
    task.wait(1)
    RefreshItemList()

    while true do
        task.wait(5)
        if not scanInProgress then
            RefreshItemList()
        end
    end
end)

-- ============================================================
-- RESIZE
-- ============================================================
local RS = Instance.new("TextButton")
RS.Size = UDim2.new(0, 14, 0, 14)
RS.Position = UDim2.new(1, -16, 1, -16)
RS.BackgroundColor3 = THEME.MAIN
RS.Text = ""
RS.BorderSizePixel = 0
RS.Parent = MainFrame
RS.AutoButtonColor = false
RS.ZIndex = 10
local RSC = Instance.new("UICorner"); RSC.CornerRadius = UDim.new(0, 4); RSC.Parent = RS

local rsz, rStart, rStartSize = false, nil, nil
RS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        rsz = true; rStart = input.Position; rStartSize = MainFrame.Size
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if rsz and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - rStart
        local nx = math.clamp(rStartSize.X.Offset + d.X, 250, 900)
        local ny = math.clamp(rStartSize.Y.Offset + d.Y, 300, 1000)
        MainFrame.Size = UDim2.new(0, nx, 0, ny)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        rsz = false
    end
end)

-- ============================================================
-- CLEANUP
-- ============================================================
game:BindToClose(function()
    if dPConn then dPConn:Disconnect() end
    pcall(function() ESPFolder:Destroy() end)
end)

print("[XyqwPiggy v" .. VERSION .. "] Loaded!")
print("[XyqwPiggy v" .. VERSION .. "] Made by Xyqwerq")
