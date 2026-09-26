-- ========== XyqwPiggy v1.3 ==========
-- Piggy Script | made by Xyqwerq ♡

local VERSION = "1.3"
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local THEME = {
    BG = Color3.fromRGB(0, 0, 0),
    DARK = Color3.fromRGB(40, 0, 0),
    MAIN = Color3.fromRGB(255, 0, 0),
    TITLE = Color3.fromRGB(20, 0, 0),
    TEXT = Color3.fromRGB(255, 255, 255),
    SUBTEXT = Color3.fromRGB(180, 180, 180),
    ON = Color3.fromRGB(0, 220, 90),
    OFF = Color3.fromRGB(220, 0, 0),
}

local function Notify(text, duration)
    duration = duration or 2
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XyqwPiggy",
            Text = text,
            Duration = duration
        })
    end)
end

local State = {
    ESP = { Items = false, Monster = false, Players = false },
    ToolIndicator = false,
    AntiTrap = false,
    GodMode = false,
}

-- CLEANUP
for _, obj in ipairs(CoreGui:GetChildren()) do
    if obj.Name == "XyqwPiggy" or obj.Name == "XyqwPiggyESP" or obj.Name == "XyqwPiggyMisc" then
        obj:Destroy()
    end
end

-- ========== MAIN GUI (только Title Bar, 280x32) ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XyqwPiggy"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 32)
MainFrame.Position = UDim2.new(0.5, -140, 0.1, 0)
MainFrame.BackgroundColor3 = THEME.BG
MainFrame.BorderSizePixel = 3
MainFrame.BorderColor3 = THEME.MAIN
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 1, 0)
TitleBar.BackgroundColor3 = THEME.TITLE
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "XyqwPiggy | made by Xyqwerq ♡"
TitleLabel.TextColor3 = THEME.MAIN
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Кнопка Misc (квадратная, слева от X)
local MiscBtn = Instance.new("TextButton")
MiscBtn.Name = "MiscBtn"
MiscBtn.Size = UDim2.new(0, 22, 0, 22)
MiscBtn.Position = UDim2.new(1, -54, 0.5, -11)
MiscBtn.BackgroundColor3 = THEME.DARK
MiscBtn.TextColor3 = THEME.MAIN
MiscBtn.Text = "M"
MiscBtn.TextScaled = true
MiscBtn.Font = Enum.Font.GothamBold
MiscBtn.BorderSizePixel = 1
MiscBtn.BorderColor3 = THEME.MAIN
MiscBtn.Parent = TitleBar
MiscBtn.AutoButtonColor = false

local MiscCorner = Instance.new("UICorner")
MiscCorner.CornerRadius = UDim.new(0, 5)
MiscCorner.Parent = MiscBtn

-- Кнопка X
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
CloseBtn.BackgroundColor3 = THEME.DARK
CloseBtn.TextColor3 = THEME.MAIN
CloseBtn.Text = "X"
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 1
CloseBtn.BorderColor3 = THEME.MAIN
CloseBtn.Parent = TitleBar
CloseBtn.AutoButtonColor = false

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn

-- ========== DOCK BUTTON (передвигается) ==========
local DockBtn = Instance.new("TextButton")
DockBtn.Name = "DockBtn"
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
DockBtn.Active = true
DockBtn.ZIndex = 999

local DockCorner = Instance.new("UICorner")
DockCorner.CornerRadius = UDim.new(0, 10)
DockCorner.Parent = DockBtn

-- Dock drag
local dockDragging = false
local dockDragStart, dockStartPos
local dockMoved = false

DockBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dockDragging = true
        dockMoved = false
        dockDragStart = input.Position
        dockStartPos = DockBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dockDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dockDragStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then dockMoved = true end
        if dockMoved then
            DockBtn.Position = UDim2.new(
                dockStartPos.X.Scale, dockStartPos.X.Offset + delta.X,
                dockStartPos.Y.Scale, dockStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dockDragging and not dockMoved then
            MainFrame.Visible = true
            DockBtn.Visible = false
        end
        dockDragging = false
    end
end)

-- Main drag
local mainDragging = false
local mainDragStart, mainStartPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = input.Position
        local function IsOver(btn)
            if not btn then return false end
            local p = btn.AbsolutePosition
            local s = btn.AbsoluteSize
            return mousePos.X >= p.X and mousePos.X <= p.X + s.X and mousePos.Y >= p.Y and mousePos.Y <= p.Y + s.Y
        end
        if IsOver(CloseBtn) or IsOver(MiscBtn) then return end
        mainDragging = true
        mainDragStart = input.Position
        mainStartPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mainDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if mainDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - mainDragStart
        MainFrame.Position = UDim2.new(mainStartPos.X.Scale, mainStartPos.X.Offset + delta.X, mainStartPos.Y.Scale, mainStartPos.Y.Offset + delta.Y)
        -- Двигаем Misc окно вместе с Main
        if MiscFrame and MiscFrame.Visible then
            MiscFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 290, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
        end
    end
end)

-- Close Main
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    if MiscFrame then MiscFrame.Visible = false end
    DockBtn.Visible = true
end)

print("[XyqwPiggy v" .. VERSION .. "] Part 1/3 loaded")
-- ========== MISC ОКНО (справа от Main, сверху) ==========
local MiscFrame = Instance.new("Frame")
MiscFrame.Name = "MiscFrame"
MiscFrame.Size = UDim2.new(0, 260, 0, 340)
MiscFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 290, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
MiscFrame.BackgroundColor3 = THEME.BG
MiscFrame.BorderSizePixel = 3
MiscFrame.BorderColor3 = THEME.MAIN
MiscFrame.Active = true
MiscFrame.Visible = false
MiscFrame.Parent = ScreenGui

local MiscFrameCorner = Instance.new("UICorner")
MiscFrameCorner.CornerRadius = UDim.new(0, 12)
MiscFrameCorner.Parent = MiscFrame

-- Misc Title
local MiscTitleBar = Instance.new("Frame")
MiscTitleBar.Size = UDim2.new(1, 0, 0, 30)
MiscTitleBar.BackgroundColor3 = THEME.TITLE
MiscTitleBar.BorderSizePixel = 0
MiscTitleBar.Parent = MiscFrame

local MiscTitleCorner = Instance.new("UICorner")
MiscTitleCorner.CornerRadius = UDim.new(0, 12)
MiscTitleCorner.Parent = MiscTitleBar

local MiscTitle = Instance.new("TextLabel")
MiscTitle.Size = UDim2.new(1, -40, 1, 0)
MiscTitle.Position = UDim2.new(0, 10, 0, 0)
MiscTitle.BackgroundTransparency = 1
MiscTitle.Text = "Misc"
MiscTitle.TextColor3 = THEME.MAIN
MiscTitle.TextScaled = true
MiscTitle.Font = Enum.Font.GothamBold
MiscTitle.TextXAlignment = Enum.TextXAlignment.Left
MiscTitle.Parent = MiscTitleBar

local MiscClose = Instance.new("TextButton")
MiscClose.Size = UDim2.new(0, 22, 0, 22)
MiscClose.Position = UDim2.new(1, -28, 0.5, -11)
MiscClose.BackgroundColor3 = THEME.DARK
MiscClose.TextColor3 = THEME.MAIN
MiscClose.Text = "X"
MiscClose.TextScaled = true
MiscClose.Font = Enum.Font.GothamBold
MiscClose.BorderSizePixel = 1
MiscClose.BorderColor3 = THEME.MAIN
MiscClose.Parent = MiscTitleBar
MiscClose.AutoButtonColor = false

local MiscCloseCorner = Instance.new("UICorner")
MiscCloseCorner.CornerRadius = UDim.new(0, 5)
MiscCloseCorner.Parent = MiscClose

-- Search
local MiscSearch = Instance.new("TextBox")
MiscSearch.Size = UDim2.new(1, -20, 0, 24)
MiscSearch.Position = UDim2.new(0, 10, 0, 35)
MiscSearch.BackgroundColor3 = THEME.DARK
MiscSearch.PlaceholderText = "Search..."
MiscSearch.PlaceholderColor3 = THEME.SUBTEXT
MiscSearch.Text = ""
MiscSearch.TextColor3 = THEME.MAIN
MiscSearch.TextSize = 12
MiscSearch.Font = Enum.Font.Gotham
MiscSearch.ClearTextOnFocus = false
MiscSearch.BorderSizePixel = 1
MiscSearch.BorderColor3 = THEME.MAIN
MiscSearch.Parent = MiscFrame

local MiscSearchCorner = Instance.new("UICorner")
MiscSearchCorner.CornerRadius = UDim.new(0, 8)
MiscSearchCorner.Parent = MiscSearch

-- Content
local MiscScroll = Instance.new("ScrollingFrame")
MiscScroll.Size = UDim2.new(1, -20, 1, -110)
MiscScroll.Position = UDim2.new(0, 10, 0, 65)
MiscScroll.BackgroundTransparency = 1
MiscScroll.BorderSizePixel = 0
MiscScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MiscScroll.ScrollBarThickness = 4
MiscScroll.ScrollBarImageColor3 = THEME.MAIN
MiscScroll.Parent = MiscFrame

local MiscLayout = Instance.new("UIListLayout")
MiscLayout.Padding = UDim.new(0, 5)
MiscLayout.SortOrder = Enum.SortOrder.LayoutOrder
MiscLayout.Parent = MiscScroll

-- SCAN кнопка (квадратная, внизу справа Misc)
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0, 55, 0, 55)
ScanBtn.Position = UDim2.new(1, -63, 1, -63)
ScanBtn.BackgroundColor3 = THEME.MAIN
ScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ScanBtn.Text = "SCAN"
ScanBtn.TextScaled = true
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.BorderSizePixel = 0
ScanBtn.Parent = MiscFrame
ScanBtn.AutoButtonColor = false
ScanBtn.ZIndex = 10

-- Misc drag
local miscDragging = false
local miscDragStart, miscStartPos
MiscTitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = input.Position
        local p = MiscClose.AbsolutePosition
        local s = MiscClose.AbsoluteSize
        if mousePos.X >= p.X and mousePos.X <= p.X + s.X and mousePos.Y >= p.Y and mousePos.Y <= p.Y + s.Y then
            return
        end
        miscDragging = true
        miscDragStart = input.Position
        miscStartPos = MiscFrame.Position
    end
end)
MiscTitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miscDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if miscDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miscDragStart
        MiscFrame.Position = UDim2.new(miscStartPos.X.Scale, miscStartPos.X.Offset + delta.X, miscStartPos.Y.Scale, miscStartPos.Y.Offset + delta.Y)
    end
end)

MiscClose.MouseButton1Click:Connect(function()
    MiscFrame.Visible = false
end)

MiscBtn.MouseButton1Click:Connect(function()
    if MiscFrame.Visible then
        MiscFrame.Visible = false
    else
        MiscFrame.Visible = true
        -- Позиционируем справа от Main, сверху
        MiscFrame.Position = UDim2.new(
            MainFrame.Position.X.Scale,
            MainFrame.Position.X.Offset + 290,
            MainFrame.Position.Y.Scale,
            MainFrame.Position.Y.Offset
        )
    end
end)

-- ========== ESP FOLDER ==========
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "XyqwPiggyESP"
ESPFolder.Parent = CoreGui

local ESP = { Items = {}, Monster = nil, Players = {} }

-- ESP ITEMS
local function GetItemImage(item)
    local decal = item:FindFirstChildOfClass("Decal")
    if decal and decal.Texture ~= "" then return decal.Texture end
    local mesh = item:FindFirstChildOfClass("SpecialMesh")
    if mesh and mesh.TextureId and mesh.TextureId ~= "" then return mesh.TextureId end
    return "rbxassetid://6022668892"
end

local function EnableItemESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("item") or name:find("key") or name:find("tool")
               or name:find("gift") or name:find("egg") or name:find("coin")
               or name:find("pickup") or name:find("collect") then
                if not ESP.Items[obj] then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ItemESP_" .. obj.Name
                    bb.Size = UDim2.new(0, 50, 0, 50)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = obj
                    bb.Parent = ESPFolder
                    local img = Instance.new("ImageLabel")
                    img.Size = UDim2.new(1, 0, 1, 0)
                    img.BackgroundTransparency = 1
                    img.Image = GetItemImage(obj)
                    img.Parent = bb
                    ESP.Items[obj] = bb
                end
            end
        end
    end
end

local function DisableItemESP()
    for obj, bb in pairs(ESP.Items) do
        if bb then bb:Destroy() end
    end
    ESP.Items = {}
end

-- ESP MONSTER
local function FindMonster()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("piggy") or name:find("monster") or name:find("bot") or name:find("mrp") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then return obj end
            end
        end
    end
    return nil
end

local function EnableMonsterESP()
    task.spawn(function()
        while State.ESP.Monster do
            local monster = FindMonster()
            if monster then
                if not ESP.Monster then
                    local hl = Instance.new("Highlight")
                    hl.Name = "MonsterESP"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee = monster
                    hl.Parent = ESPFolder
                    ESP.Monster = hl
                elseif ESP.Monster.Adornee ~= monster then
                    ESP.Monster.Adornee = monster
                end
            else
                if ESP.Monster then ESP.Monster:Destroy() ESP.Monster = nil end
            end
            task.wait(0.5)
        end
        if ESP.Monster then ESP.Monster:Destroy() ESP.Monster = nil end
    end)
end

local function DisableMonsterESP()
    State.ESP.Monster = false
    if ESP.Monster then ESP.Monster:Destroy() ESP.Monster = nil end
end

-- ESP PLAYERS
local function EnablePlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if not ESP.Players[plr] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "PlayerESP_" .. plr.Name
                    hl.FillColor = Color3.fromRGB(0, 255, 0)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee = plr.Character
                    hl.Parent = ESPFolder
                    ESP.Players[plr] = hl
                end
            end
        end
    end
end

local function DisablePlayerESP()
    for plr, hl in pairs(ESP.Players) do
        if hl then hl:Destroy() end
    end
    ESP.Players = {}
end

task.spawn(function()
    while true do
        if State.ESP.Players then EnablePlayerESP() end
        task.wait(2)
    end
end)

-- TOOL USAGE INDICATOR
local toolHighlights = {}
local function EnableToolIndicator()
    task.spawn(function()
        while State.ToolIndicator do
            local char = LP.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            local parent = obj.Parent
                            if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
                                if not toolHighlights[obj] then
                                    local target = parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart")
                                    if target then
                                        local hl = Instance.new("Highlight")
                                        hl.Name = "ToolUse_" .. target.Name
                                        hl.FillColor = Color3.fromRGB(255, 255, 0)
                                        hl.FillTransparency = 0.5
                                        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                        hl.Adornee = target
                                        hl.Parent = ESPFolder
                                        toolHighlights[obj] = hl
                                    end
                                end
                            end
                        end
                    end
                else
                    for prompt, hl in pairs(toolHighlights) do if hl then hl:Destroy() end end
                    toolHighlights = {}
                end
            end
            task.wait(1)
        end
        for prompt, hl in pairs(toolHighlights) do if hl then hl:Destroy() end end
        toolHighlights = {}
    end)
end

-- ANTI-TRAP
local function EnableAntiTrap()
    task.spawn(function()
        while State.AntiTrap do
            local char = LP.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dangerous = false
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and obj.CanCollide then
                            local name = obj.Name:lower()
                            if name:find("trap") or name:find("lava") or name:find("spike")
                               or name:find("kill") or name:find("damage") or name:find("hurt") then
                                if (obj.Position - hrp.Position).Magnitude < 6 then
                                    dangerous = true
                                    break
                                end
                            end
                        end
                    end
                    if dangerous then
                        hrp.CFrame = hrp.CFrame + Vector3.new(0, 20, 0)
                        Notify("Anti-Trap: Detected!", 1)
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

-- GODMODE
local godHook = nil
local godConn = nil
local monsterKillerConn = nil
local kickBlockConn = nil

local function EnableGodMode()
    if godConn then return end
    State.GodMode = true

    pcall(function()
        if hookmetamethod and getnamecallmethod then
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", function(self, key)
                if State.GodMode and typeof(self) == "Instance" then
                    local ok, isHum = pcall(function() return self:IsA("Humanoid") end)
                    if ok and isHum and key == "Health" then
                        return self.MaxHealth
                    end
                end
                return oldIndex(self, key)
            end)
            godHook = oldIndex
        end
    end)

    pcall(function()
        if hookmetamethod and getnamecallmethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if State.GodMode and method == "Kick" and self == LP then
                    return nil
                end
                return oldNamecall(self, ...)
            end)
            kickBlockConn = oldNamecall
        end
    end)

    monsterKillerConn = RunService.Heartbeat:Connect(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local name = obj.Name:lower()
                if name:find("piggy") or name:find("monster") or name:find("bot") then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        pcall(function()
                            hum.Health = 0
                            obj.Parent = nil
                        end)
                    end
                end
            end
        end
    end)

    godConn = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)
end

local function DisableGodMode()
    State.GodMode = false
    if godConn then godConn:Disconnect() godConn = nil end
    if monsterKillerConn then monsterKillerConn:Disconnect() monsterKillerConn = nil end
    godHook = nil
    kickBlockConn = nil
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = 100 hum.Health = 100 end
    end
end

print("[XyqwPiggy v" .. VERSION .. "] Part 2/3 loaded")
-- ========== TOGGLE ==========
local function MakeToggle(name, getState, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 32)
    row.BackgroundColor3 = THEME.DARK
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.MAIN
    row.Parent = MiscScroll

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.MAIN
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 20, 0, 20)
    box.Position = UDim2.new(1, -28, 0.5, -10)
    box.BackgroundColor3 = getState() and THEME.ON or THEME.OFF
    box.Text = ""
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.MAIN
    box.Parent = row
    box.AutoButtonColor = false

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = box

    local function UpdateCheck()
        box.BackgroundColor3 = getState() and THEME.ON or THEME.OFF
    end

    box.MouseButton1Click:Connect(function()
        onToggle()
        UpdateCheck()
        Notify(name .. ": " .. (getState() and "ON" or "OFF"), 2)
    end)

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = input.Position
            local bp = box.AbsolutePosition
            local bs = box.AbsoluteSize
            if mousePos.X >= bp.X and mousePos.X <= bp.X + bs.X and mousePos.Y >= bp.Y and mousePos.Y <= bp.Y + bs.Y then return end
            onToggle()
            UpdateCheck()
            Notify(name .. ": " .. (getState() and "ON" or "OFF"), 2)
        end
    end)

    return row
end

-- МЕНЮ ФУНКЦИЙ
MakeToggle("GodMode", function() return State.GodMode end, function()
    if State.GodMode then DisableGodMode() else EnableGodMode() end
end)

MakeToggle("Tool Usage Indicator", function() return State.ToolIndicator end, function()
    State.ToolIndicator = not State.ToolIndicator
    if State.ToolIndicator then EnableToolIndicator() end
end)

MakeToggle("Anti-Trap", function() return State.AntiTrap end, function()
    State.AntiTrap = not State.AntiTrap
    if State.AntiTrap then EnableAntiTrap() end
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

MiscScroll.CanvasSize = UDim2.new(0, 0, 0, MiscLayout.AbsoluteContentSize.Y + 70)
MiscLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MiscScroll.CanvasSize = UDim2.new(0, 0, 0, MiscLayout.AbsoluteContentSize.Y + 70)
end)

-- SCAN
ScanBtn.MouseButton1Click:Connect(function()
    Notify("Scanning...", 2)
    task.wait(0.5)
    if State.ESP.Items then
        DisableItemESP()
        EnableItemESP()
    end
    Notify("Scan complete", 2)
end)

-- ========== RESIZE Misc ==========
local MiscResize = Instance.new("TextButton")
MiscResize.Size = UDim2.new(0, 14, 0, 14)
MiscResize.Position = UDim2.new(1, -16, 1, -16)
MiscResize.BackgroundColor3 = THEME.MAIN
MiscResize.Text = ""
MiscResize.BorderSizePixel = 0
MiscResize.Parent = MiscFrame
MiscResize.AutoButtonColor = false
MiscResize.ZIndex = 10

local MiscResizeCorner = Instance.new("UICorner")
MiscResizeCorner.CornerRadius = UDim.new(0, 4)
MiscResizeCorner.Parent = MiscResize

local miscResizing = false
local miscResizeStart, miscResizeStartSize
MiscResize.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miscResizing = true
        miscResizeStart = input.Position
        miscResizeStartSize = MiscFrame.Size
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if miscResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miscResizeStart
        local newX = math.clamp(miscResizeStartSize.X.Offset + delta.X, 220, 900)
        local newY = math.clamp(miscResizeStartSize.Y.Offset + delta.Y, 260, 1000)
        MiscFrame.Size = UDim2.new(0, newX, 0, newY)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miscResizing = false
    end
end)

-- ========== ФИНАЛ ==========
game:BindToClose(function()
    if godConn then godConn:Disconnect() end
    if monsterKillerConn then monsterKillerConn:Disconnect() end
    ESPFolder:Destroy()
end)

print("[XyqwPiggy v" .. VERSION .. "] Loaded!")
print("[XyqwPiggy v" .. VERSION .. "] Made by Xyqwerq ♡")
