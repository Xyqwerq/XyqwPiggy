-- ========== XyqwPiggy v1.4 ==========
-- Piggy Script | made by Xyqwerq ♡

local VERSION = "1.4"
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

local function AddStroke(parent)
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.MAIN
    stroke.Thickness = 1
    stroke.Parent = parent
    return stroke
end

local State = {
    ESP = { Items = false, Monster = false, Players = false },
    ToolIndicator = false,
    AntiTrap = false,
    GodMode = false,
    DeletePiggy = false,
}

-- CLEANUP
for _, obj in ipairs(CoreGui:GetChildren()) do
    if obj.Name == "XyqwPiggy" or obj.Name == "XyqwPiggyESP" or obj.Name == "XyqwPiggyMisc" then
        obj:Destroy()
    end
end

-- ========== MAIN SCREEN ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XyqwPiggy"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

-- ========== MAIN GUI (280x340 как XyqwHub) ==========
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 340)
MainFrame.Position = UDim2.new(0.5, -140, 0.3, 0)
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
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = THEME.TITLE
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "XyqwPiggy | made by Xyqwerq ♡"
TitleLabel.TextColor3 = THEME.MAIN
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Кнопка Misc (квадратная, обводка)
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
local MiscBtnCorner = Instance.new("UICorner")
MiscBtnCorner.CornerRadius = UDim.new(0, 5)
MiscBtnCorner.Parent = MiscBtn
AddStroke(MiscBtn)

-- Кнопка X (обводка)
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
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn
AddStroke(CloseBtn)

-- Search Bar (обводка)
local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(1, -20, 0, 24)
SearchBar.Position = UDim2.new(0, 10, 0, 36)
SearchBar.BackgroundColor3 = THEME.DARK
SearchBar.PlaceholderText = "Search items..."
SearchBar.PlaceholderColor3 = THEME.SUBTEXT
SearchBar.Text = ""
SearchBar.TextColor3 = THEME.MAIN
SearchBar.TextSize = 12
SearchBar.Font = Enum.Font.Gotham
SearchBar.ClearTextOnFocus = false
SearchBar.BorderSizePixel = 1
SearchBar.BorderColor3 = THEME.MAIN
SearchBar.Parent = MainFrame
local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBar
AddStroke(SearchBar)

-- Content Scroll (список предметов, СКРОЛЛИТСЯ как XyqwHub)
local ItemScroll = Instance.new("ScrollingFrame")
ItemScroll.Name = "ItemScroll"
ItemScroll.Size = UDim2.new(1, -20, 1, -100)
ItemScroll.Position = UDim2.new(0, 10, 0, 66)
ItemScroll.BackgroundTransparency = 1
ItemScroll.BorderSizePixel = 0
ItemScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemScroll.ScrollBarThickness = 4
ItemScroll.ScrollBarImageColor3 = THEME.MAIN
ItemScroll.Parent = MainFrame

local ItemLayout = Instance.new("UIListLayout")
ItemLayout.Padding = UDim.new(0, 4)
ItemLayout.SortOrder = Enum.SortOrder.LayoutOrder
ItemLayout.Parent = ItemScroll

ItemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ItemScroll.CanvasSize = UDim2.new(0, 0, 0, ItemLayout.AbsoluteContentSize.Y + 70)
end)

-- Кнопка Scan (квадратная, обводка, внизу справа)
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0, 55, 0, 55)
ScanBtn.Position = UDim2.new(1, -63, 1, -63)
ScanBtn.BackgroundColor3 = THEME.MAIN
ScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ScanBtn.Text = "Scan"
ScanBtn.TextScaled = true
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.BorderSizePixel = 1
ScanBtn.BorderColor3 = THEME.MAIN
ScanBtn.Parent = MainFrame
ScanBtn.AutoButtonColor = false
ScanBtn.ZIndex = 10
AddStroke(ScanBtn)

-- ========== MISC ОКНО (200x200) ==========
local MiscFrame = Instance.new("Frame")
MiscFrame.Name = "MiscFrame"
MiscFrame.Size = UDim2.new(0, 200, 0, 200)
MiscFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 290, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
MiscFrame.BackgroundColor3 = THEME.BG
MiscFrame.BorderSizePixel = 3
MiscFrame.BorderColor3 = THEME.MAIN
MiscFrame.Active = true
MiscFrame.Visible = false
MiscFrame.Parent = ScreenGui

local MiscFrameCorner = Instance.new("UICorner")
MiscFrameCorner.CornerRadius = UDim.new(0, 10)
MiscFrameCorner.Parent = MiscFrame

-- Misc Title
local MiscTitleBar = Instance.new("Frame")
MiscTitleBar.Size = UDim2.new(1, 0, 0, 26)
MiscTitleBar.BackgroundColor3 = THEME.TITLE
MiscTitleBar.BorderSizePixel = 0
MiscTitleBar.Parent = MiscFrame

local MiscTitleCorner = Instance.new("UICorner")
MiscTitleCorner.CornerRadius = UDim.new(0, 10)
MiscTitleCorner.Parent = MiscTitleBar

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
local MiscCloseCorner = Instance.new("UICorner")
MiscCloseCorner.CornerRadius = UDim.new(0, 5)
MiscCloseCorner.Parent = MiscClose
AddStroke(MiscClose)

-- Misc Scroll
local MiscScroll = Instance.new("ScrollingFrame")
MiscScroll.Size = UDim2.new(1, -12, 1, -34)
MiscScroll.Position = UDim2.new(0, 6, 0, 30)
MiscScroll.BackgroundTransparency = 1
MiscScroll.BorderSizePixel = 0
MiscScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MiscScroll.ScrollBarThickness = 4
MiscScroll.ScrollBarImageColor3 = THEME.MAIN
MiscScroll.Parent = MiscFrame

local MiscLayout = Instance.new("UIListLayout")
MiscLayout.Padding = UDim.new(0, 4)
MiscLayout.SortOrder = Enum.SortOrder.LayoutOrder
MiscLayout.Parent = MiscScroll

MiscLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MiscScroll.CanvasSize = UDim2.new(0, 0, 0, MiscLayout.AbsoluteContentSize.Y + 10)
end)

-- ========== DOCK BUTTON ==========
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
        if MiscFrame and MiscFrame.Visible then
            MiscFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 290, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
        end
    end
end)

-- Misc drag
local miscDragging = false
local miscDragStart, miscStartPos
MiscTitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = input.Position
        local p = MiscClose.AbsolutePosition
        local s = MiscClose.AbsoluteSize
        if mousePos.X >= p.X and mousePos.X <= p.X + s.X and mousePos.Y >= p.Y and mousePos.Y <= p.Y + s.Y then return end
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

MiscBtn.MouseButton1Click:Connect(function()
    if MiscFrame.Visible then
        MiscFrame.Visible = false
    else
        MiscFrame.Visible = true
        MiscFrame.Position = UDim2.new(
            MainFrame.Position.X.Scale,
            MainFrame.Position.X.Offset + 290,
            MainFrame.Position.Y.Scale,
            MainFrame.Position.Y.Offset
        )
    end
end)

MiscClose.MouseButton1Click:Connect(function()
    MiscFrame.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiscFrame.Visible = false
    DockBtn.Visible = true
end)

print("[XyqwPiggy v" .. VERSION .. "] Part 1/3 loaded")
-- ========== ESP FOLDER ==========
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "XyqwPiggyESP"
ESPFolder.Parent = CoreGui

local ESP = { Items = {}, Monster = nil, Players = {} }

-- ESP ITEMS (обводка, не иконка)
local function EnableItemESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("item") or name:find("key") or name:find("tool")
               or name:find("gift") or name:find("egg") or name:find("coin")
               or name:find("pickup") or name:find("collect") then
                if not ESP.Items[obj] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ItemESP_" .. obj.Name
                    hl.FillColor = Color3.fromRGB(0, 255, 255)
                    hl.FillTransparency = 0.7
                    hl.OutlineColor = Color3.fromRGB(0, 255, 255)
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee = obj
                    hl.Parent = ESPFolder
                    ESP.Items[obj] = hl
                end
            end
        end
    end
end

local function DisableItemESP()
    for obj, hl in pairs(ESP.Items) do
        if hl then hl:Destroy() end
    end
    ESP.Items = {}
end

-- ESP MONSTER
local function FindMonster()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("piggy") or name:find("monster") or name:find("bot") 
               or name:find("mrp") or name:find("mrpiggy") or name:find("piggybot") then
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
                    hl.OutlineTransparency = 0
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

-- TOOL USAGE INDICATOR (подсвечиваем ProximityPrompt И ClickDetector)
local toolHighlights = {}
local function EnableToolIndicator()
    task.spawn(function()
        while State.ToolIndicator do
            local char = LP.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        local isPrompt = obj:IsA("ProximityPrompt")
                        local isClick = obj:IsA("ClickDetector")
                        if isPrompt or isClick then
                            local parent = obj.Parent
                            if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
                                if not toolHighlights[obj] then
                                    local target = parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart")
                                    if target then
                                        local hl = Instance.new("Highlight")
                                        hl.Name = "ToolUse_" .. target.Name
                                        hl.FillColor = Color3.fromRGB(255, 255, 0)
                                        hl.FillTransparency = 0.6
                                        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                                        hl.OutlineTransparency = 0
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
    godHook = nil
    kickBlockConn = nil
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = 100 hum.Health = 100 end
    end
end

-- DELETE PIGGY (Visual)
local deletePiggyConn = nil

local function EnableDeletePiggy()
    if deletePiggyConn then return end
    State.DeletePiggy = true
    deletePiggyConn = RunService.Heartbeat:Connect(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local name = obj.Name:lower()
                if name:find("piggy") or name:find("monster") or name:find("bot") 
                   or name:find("mrp") or name:find("mrpiggy") then
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
end

local function DisableDeletePiggy()
    State.DeletePiggy = false
    if deletePiggyConn then deletePiggyConn:Disconnect() deletePiggyConn = nil end
end

print("[XyqwPiggy v" .. VERSION .. "] Part 2/3 loaded")
-- ========== TOGGLE (с чекбоксом и обводкой) ==========
local function MakeToggle(name, getState, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 28)
    row.BackgroundColor3 = THEME.DARK
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.MAIN
    row.Parent = MiscScroll
    
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 6)
    rc.Parent = row
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
    
    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(1, -24, 0.5, -9)
    box.BackgroundColor3 = getState() and THEME.ON or THEME.OFF
    box.Text = ""
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.MAIN
    box.Parent = row
    box.AutoButtonColor = false
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = box
    AddStroke(box)
    
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

-- MISC ФУНКЦИИ
MakeToggle("GodMode", function() return State.GodMode end, function()
    if State.GodMode then DisableGodMode() else EnableGodMode() end
end)

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

-- ========== СПИСОК ПРЕДМЕТОВ ==========
local currentItems = {}

local function GetItemImage(item)
    local decal = item:FindFirstChildOfClass("Decal")
    if decal and decal.Texture ~= "" then return decal.Texture end
    local mesh = item:FindFirstChildOfClass("SpecialMesh")
    if mesh and mesh.TextureId and mesh.TextureId ~= "" then return mesh.TextureId end
    return "rbxassetid://6022668892"
end

-- Функция телепорта + взять + вернуться
local function TakeItem(item)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local savedCF = hrp.CFrame
    
    -- Телепорт к предмету
    hrp.CFrame = CFrame.new(item.Position + Vector3.new(0, 3, 0))
    task.wait(0.3)
    
    -- Активируем ProximityPrompt
    for _, prompt in ipairs(item:GetChildren()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(prompt) end)
        end
    end
    
    -- Активируем ClickDetector
    for _, cd in ipairs(item:GetChildren()) do
        if cd:IsA("ClickDetector") then
            pcall(function() fireclickdetector(cd) end)
        end
    end
    
    task.wait(0.2)
    
    -- Возвращаемся обратно
    hrp.CFrame = savedCF
    Notify("Collected: " .. item.Name, 2)
end

-- Обновление списка
local function RefreshItemList()
    -- Очистка
    for _, child in ipairs(ItemScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    currentItems = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("item") or name:find("key") or name:find("tool")
               or name:find("gift") or name:find("egg") or name:find("coin")
               or name:find("pickup") or name:find("collect") then
                -- Исключаем предметы в лобби (далеко от игрока)
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < 1000 then
                        table.insert(currentItems, obj)
                    end
                else
                    table.insert(currentItems, obj)
                end
            end
        end
    end
    
    if #currentItems == 0 then
        local noItems = Instance.new("TextLabel")
        noItems.Size = UDim2.new(1, -5, 0, 30)
        noItems.BackgroundTransparency = 1
        noItems.Text = "No items found"
        noItems.TextColor3 = THEME.SUBTEXT
        noItems.TextScaled = true
        noItems.Font = Enum.Font.Gotham
        noItems.Parent = ItemScroll
    end
    
    -- Создаём ряды
    for i, item in ipairs(currentItems) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, -5, 0, 44)
        row.BackgroundColor3 = THEME.DARK
        row.BorderSizePixel = 1
        row.BorderColor3 = THEME.MAIN
        row.Text = ""
        row.Parent = ItemScroll
        row.AutoButtonColor = false
        
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 6)
        rc.Parent = row
        AddStroke(row)
        
        -- Иконка предмета
        local iconFrame = Instance.new("Frame")
        iconFrame.Size = UDim2.new(0, 36, 0, 36)
        iconFrame.Position = UDim2.new(0, 5, 0.5, -18)
        iconFrame.BackgroundColor3 = THEME.BG
        iconFrame.BorderSizePixel = 1
        iconFrame.BorderColor3 = THEME.MAIN
        iconFrame.Parent = row
        
        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 5)
        ic.Parent = iconFrame
        AddStroke(iconFrame)
        
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(1, -4, 1, -4)
        icon.Position = UDim2.new(0, 2, 0, 2)
        icon.BackgroundTransparency = 1
        icon.Image = GetItemImage(item)
        icon.Parent = iconFrame
        
        -- Название
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -55, 1, 0)
        nameLbl.Position = UDim2.new(0, 46, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = item.Name
        nameLbl.TextColor3 = THEME.MAIN
        nameLbl.TextScaled = true
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row
        
        -- Клик — телепорт + взять + обратно
        row.MouseButton1Click:Connect(function()
            TakeItem(item)
        end)
    end
end

-- Scan кнопка
ScanBtn.MouseButton1Click:Connect(function()
    Notify("Scanning...", 2)
    task.wait(0.3)
    RefreshItemList()
    Notify("Scan complete (" .. #currentItems .. " items)", 2)
end)

-- Авто-сканирование при запуске
task.spawn(function()
    task.wait(1)
    RefreshItemList()
end)

-- ========== RESIZE Misc ==========
local MiscResize = Instance.new("TextButton")
MiscResize.Size = UDim2.new(0, 12, 0, 12)
MiscResize.Position = UDim2.new(1, -14, 1, -14)
MiscResize.BackgroundColor3 = THEME.MAIN
MiscResize.Text = ""
MiscResize.BorderSizePixel = 0
MiscResize.Parent = MiscFrame
MiscResize.AutoButtonColor = false
MiscResize.ZIndex = 10

local MiscResizeCorner = Instance.new("UICorner")
MiscResizeCorner.CornerRadius = UDim.new(0, 3)
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
        local newX = math.clamp(miscResizeStartSize.X.Offset + delta.X, 180, 500)
        local newY = math.clamp(miscResizeStartSize.Y.Offset + delta.Y, 180, 600)
        MiscFrame.Size = UDim2.new(0, newX, 0, newY)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miscResizing = false
    end
end)

-- ========== RESIZE Main ==========
local MainResize = Instance.new("TextButton")
MainResize.Size = UDim2.new(0, 14, 0, 14)
MainResize.Position = UDim2.new(1, -16, 1, -16)
MainResize.BackgroundColor3 = THEME.MAIN
MainResize.Text = ""
MainResize.BorderSizePixel = 0
MainResize.Parent = MainFrame
MainResize.AutoButtonColor = false
MainResize.ZIndex = 10

local MainResizeCorner = Instance.new("UICorner")
MainResizeCorner.CornerRadius = UDim.new(0, 4)
MainResizeCorner.Parent = MainResize

local mainResizing = false
local mainResizeStart, mainResizeStartSize
MainResize.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mainResizing = true
        mainResizeStart = input.Position
        mainResizeStartSize = MainFrame.Size
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if mainResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - mainResizeStart
        local newX = math.clamp(mainResizeStartSize.X.Offset + delta.X, 250, 900)
        local newY = math.clamp(mainResizeStartSize.Y.Offset + delta.Y, 300, 1000)
        MainFrame.Size = UDim2.new(0, newX, 0, newY)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mainResizing = false
    end
end)

-- ========== ФИНАЛ ==========
game:BindToClose(function()
    if godConn then godConn:Disconnect() end
    if deletePiggyConn then deletePiggyConn:Disconnect() end
    ESPFolder:Destroy()
end)

print("[XyqwPiggy v" .. VERSION .. "] Loaded!")
print("[XyqwPiggy v" .. VERSION .. "] Made by Xyqwerq ♡")
