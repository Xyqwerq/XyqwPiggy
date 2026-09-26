-- ========== XyqwPiggy v1.1 ==========
-- Piggy Script by Xyqwerq
-- Standalone (not part of XyqwHub)

local VERSION = "1.1"
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

-- THEME
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

-- NOTIFY
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

-- STATE
local State = {
    ESP = { Items = false, Monster = false, Players = false },
    ToolIndicator = false,
    AntiTrap = false,
    GodMode = false,
    AutoCollect = false,
}

-- CLEANUP
for _, obj in ipairs(CoreGui:GetChildren()) do
    if obj.Name == "XyqwPiggy" or obj.Name == "XyqwPiggyESP" then
        obj:Destroy()
    end
end

-- ========== GUI ==========
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
MainFrame.Size = UDim2.new(0, 340, 0, 420)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -210)
MainFrame.BackgroundColor3 = THEME.BG
MainFrame.BorderSizePixel = 3
MainFrame.BorderColor3 = THEME.MAIN
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = THEME.TITLE
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 150, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "XyqwPiggy v" .. VERSION
TitleLabel.TextColor3 = THEME.MAIN
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0, 3)
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
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Search Bar
local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(1, -20, 0, 26)
SearchBar.Position = UDim2.new(0, 10, 0, 38)
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
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBar

-- Tab Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 26)
TabBar.Position = UDim2.new(0, 10, 0, 70)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TABS = {"Misc", "ESP", "Collect"}
local tabButtons = {}
local currentTab = "Misc"

local function SwitchTab(name)
    currentTab = name
    for n, btn in pairs(tabButtons) do
        if n == name then
            btn.BackgroundColor3 = THEME.MAIN
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            btn.BackgroundColor3 = THEME.DARK
            btn.TextColor3 = THEME.MAIN
        end
    end
    if RefreshContent then RefreshContent() end
end

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = TabBar

for _, name in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.33, -3, 1, 0)
    btn.BackgroundColor3 = THEME.DARK
    btn.TextColor3 = THEME.MAIN
    btn.Text = name
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 1
    btn.BorderColor3 = THEME.MAIN
    btn.Parent = TabBar
    btn.AutoButtonColor = false
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    tabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end

-- Content Scroll
local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -20, 1, -135)
ContentScroll.Position = UDim2.new(0, 10, 0, 102)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.ScrollBarThickness = 4
ContentScroll.ScrollBarImageColor3 = THEME.MAIN
ContentScroll.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroll

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
DockBtn.ZIndex = 999

local DockCorner = Instance.new("UICorner")
DockCorner.CornerRadius = UDim.new(0, 10)
DockCorner.Parent = DockBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    DockBtn.Visible = true
end)

DockBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    DockBtn.Visible = false
end)

-- ========== TOGGLE (с чекбоксом) ==========
local function MakeToggle(name, getState, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 34)
    row.BackgroundColor3 = THEME.DARK
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.MAIN
    row.Parent = ContentScroll
    
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
    
    -- Чекбокс (квадратик)
    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 22, 0, 22)
    box.Position = UDim2.new(1, -30, 0.5, -11)
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
    
    -- Клик по всему ряду тоже срабатывает
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = input.Position
            local bp = box.AbsolutePosition
            local bs = box.AbsoluteSize
            if mousePos.X >= bp.X and mousePos.X <= bp.X + bs.X and mousePos.Y >= bp.Y and mousePos.Y <= bp.Y + bs.Y then
                return
            end
            onToggle()
            UpdateCheck()
            Notify(name .. ": " .. (getState() and "ON" or "OFF"), 2)
        end
    end)
    
    return row, box
end

print("[XyqwPiggy v" .. VERSION .. "] Part 1/3 loaded")
-- ========== ESP FOLDER ==========
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "XyqwPiggyESP"
ESPFolder.Parent = CoreGui

local ESP = {
    Items = {},
    Monster = nil,
    Players = {},
}

-- ========== ESP ITEMS (с картинками) ==========
local function GetItemImage(item)
    -- Пытаемся найти картинку предмета
    local decal = item:FindFirstChildOfClass("Decal")
    if decal and decal.Texture ~= "" then
        return decal.Texture
    end
    
    local mesh = item:FindFirstChildOfClass("SpecialMesh")
    if mesh and mesh.TextureId and mesh.TextureId ~= "" then
        return mesh.TextureId
    end
    
    -- Стандартная иконка
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
                    bb.Size = UDim2.new(0, 60, 0, 60)
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

-- ========== ESP MONSTER ==========
local function FindMonster()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("piggy") or obj.Name:lower():find("monster") or obj.Name:lower():find("bot") or obj.Name:lower():find("mrboss")) then
            return obj
        end
    end
    return nil
end

local function EnableMonsterESP()
    task.spawn(function()
        while State.ESP.Monster do
            local monster = FindMonster()
            if monster then
                local hum = monster:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
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
                    if ESP.Monster then
                        ESP.Monster:Destroy()
                        ESP.Monster = nil
                    end
                end
            else
                if ESP.Monster then
                    ESP.Monster:Destroy()
                    ESP.Monster = nil
                end
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

-- ========== ESP PLAYERS ==========
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

-- Авто-обновление
task.spawn(function()
    while true do
        if State.ESP.Players then
            EnablePlayerESP()
        end
        task.wait(2)
    end
end)

-- ========== TOOL USAGE INDICATOR ==========
local toolHighlights = {}

local function EnableToolIndicator()
    task.spawn(function()
        while State.ToolIndicator do
            local char = LP.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    -- Подсвечиваем все ProximityPrompt
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
                    -- Убираем если tool нет
                    for prompt, hl in pairs(toolHighlights) do
                        if hl then hl:Destroy() end
                    end
                    toolHighlights = {}
                end
            end
            task.wait(1)
        end
        -- Очистка при выключении
        for prompt, hl in pairs(toolHighlights) do
            if hl then hl:Destroy() end
        end
        toolHighlights = {}
    end)
end

-- ========== ANTI-TRAP ==========
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
                                local dist = (obj.Position - hrp.Position).Magnitude
                                if dist < 6 then
                                    dangerous = true
                                    break
                                end
                            end
                        end
                    end
                    if dangerous then
                        -- Телепорт вверх
                        hrp.CFrame = hrp.CFrame + Vector3.new(0, 20, 0)
                        Notify("Anti-Trap: Detected!", 1)
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

-- ========== GODMODE (через hookmetamethod) ==========
local godHook = nil
local godConn = nil

local function EnableGodMode()
    if godHook or godConn then return end
    State.GodMode = true
    
    -- Метод 1: hookmetamethod на __index для Health
    pcall(function()
        if hookmetamethod and getnamecallmethod then
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", function(self, key)
                if State.GodMode and typeof(self) == "Instance" and key == "Health" then
                    local ok, isHumanoid = pcall(function() return self:IsA("Humanoid") end)
                    if ok and isHumanoid then
                        local maxHealth = self.MaxHealth
                        return maxHealth
                    end
                end
                return oldIndex(self, key)
            end)
            godHook = oldIndex
        end
    end)
    
    -- Метод 2: постоянное восстановление HP (fallback)
    godConn = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.MaxHealth < 1000000 then
                    hum.MaxHealth = 1000000
                end
                if hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end
        end
    end)
end

local function DisableGodMode()
    State.GodMode = false
    if godConn then godConn:Disconnect() godConn = nil end
    godHook = nil
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end

-- ========== REFRESH CONTENT ==========
function RefreshContent()
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    if currentTab == "Misc" then
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
        
        MakeToggle("Auto-Collect", function() return State.AutoCollect end, function()
            State.AutoCollect = not State.AutoCollect
            if State.AutoCollect then EnableAutoCollect() else DisableAutoCollect() end
        end)
        
    elseif currentTab == "ESP" then
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
        
    elseif currentTab == "Collect" then
        RefreshItemList()
    end
    
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
end

print("[XyqwPiggy v" .. VERSION .. "] Part 2/3 loaded")
-- ========== AUTO-COLLECT (через Tween) ==========
local collectConn = nil
local savedPos = nil

local function TeleportTo(targetCF, duration)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local tween = TweenService:Create(hrp, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad), {CFrame = targetCF})
    tween:Play()
    tween.Completed:Wait()
end

function EnableAutoCollect()
    if collectConn then return end
    savedPos = nil
    collectConn = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        
        if not savedPos then savedPos = hrp.CFrame end
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("item") or name:find("key") or name:find("tool") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < 500 and dist > 5 then
                        local currentPos = hrp.CFrame
                        TeleportTo(CFrame.new(obj.Position + Vector3.new(0, 2, 0)), 0.3)
                        task.wait(0.2)
                        
                        for _, prompt in ipairs(obj:GetChildren()) do
                            if prompt:IsA("ProximityPrompt") then
                                pcall(function() fireproximityprompt(prompt) end)
                            end
                        end
                        
                        task.wait(0.1)
                        TeleportTo(currentPos, 0.3)
                        savedPos = currentPos
                        break
                    end
                end
            end
        end
        task.wait(0.5)
    end)
end

function DisableAutoCollect()
    if collectConn then collectConn:Disconnect() collectConn = nil end
    savedPos = nil
end

-- ========== СПИСОК ПРЕДМЕТОВ ==========
local function RefreshItemList()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("item") or name:find("key") or name:find("tool") 
               or name:find("gift") or name:find("egg") or name:find("coin")
               or name:find("pickup") or name:find("collect") then
                table.insert(items, obj)
            end
        end
    end
    
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 0, 300)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = ContentScroll
    
    local itemScroll = Instance.new("ScrollingFrame")
    itemScroll.Size = UDim2.new(1, 0, 1, 0)
    itemScroll.BackgroundTransparency = 1
    itemScroll.BorderSizePixel = 0
    itemScroll.CanvasSize = UDim2.new(0, 0, 0, #items * 53 + 10)
    itemScroll.ScrollBarThickness = 4
    itemScroll.ScrollBarImageColor3 = THEME.MAIN
    itemScroll.Parent = listFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = itemScroll
    
    if #items == 0 then
        local noItems = Instance.new("TextLabel")
        noItems.Size = UDim2.new(1, 0, 0, 30)
        noItems.BackgroundTransparency = 1
        noItems.Text = "No items found"
        noItems.TextColor3 = THEME.SUBTEXT
        noItems.TextScaled = true
        noItems.Font = Enum.Font.Gotham
        noItems.Parent = itemScroll
    end
    
    for i, item in ipairs(items) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 48)
        row.BackgroundColor3 = THEME.DARK
        row.BorderSizePixel = 1
        row.BorderColor3 = THEME.MAIN
        row.Parent = itemScroll
        
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 8)
        rc.Parent = row
        
        -- Иконка (крутящийся предмет)
        local iconFrame = Instance.new("Frame")
        iconFrame.Size = UDim2.new(0, 40, 0, 40)
        iconFrame.Position = UDim2.new(0, 5, 0.5, -20)
        iconFrame.BackgroundColor3 = THEME.DARK
        iconFrame.BorderSizePixel = 1
        iconFrame.BorderColor3 = THEME.MAIN
        iconFrame.Parent = row
        
        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 6)
        ic.Parent = iconFrame
        
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(1, -4, 1, -4)
        icon.Position = UDim2.new(0, 2, 0, 2)
        icon.BackgroundTransparency = 1
        icon.Image = GetItemImage(item)
        icon.Parent = iconFrame
        
        -- Имя предмета
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -65, 1, 0)
        nameLbl.Position = UDim2.new(0, 50, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = item.Name
        nameLbl.TextColor3 = THEME.MAIN
        nameLbl.TextScaled = true
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = row
        
        -- Клик — телепорт к предмету
        row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local char = LP.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local currentPos = hrp.CFrame
                        TeleportTo(CFrame.new(item.Position + Vector3.new(0, 2, 0)), 0.3)
                        task.wait(0.2)
                        for _, prompt in ipairs(item:GetChildren()) do
                            if prompt:IsA("ProximityPrompt") then
                                pcall(function() fireproximityprompt(prompt) end)
                            end
                        end
                        task.wait(0.1)
                        TeleportTo(currentPos, 0.3)
                        Notify("Collected: " .. item.Name, 2)
                    end
                end
            end
        end)
    end
    
    -- Кнопка Scan (квадратная)
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0, 80, 0, 80)
    scanBtn.Position = UDim2.new(1, -95, 1, -95)
    scanBtn.BackgroundColor3 = THEME.MAIN
    scanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    scanBtn.Text = "SCAN"
    scanBtn.TextScaled = true
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.BorderSizePixel = 0
    scanBtn.Parent = MainFrame
    scanBtn.AutoButtonColor = false
    scanBtn.ZIndex = 10
    scanBtn.Name = "ScanBtn"
    
    scanBtn.MouseButton1Click:Connect(function()
        Notify("Scanning...", 2)
        RefreshContent()
        Notify("Scan complete", 2)
    end)
end

-- Удаляем старую Scan кнопку при переключении вкладки
local function RemoveScanBtn()
    local old = MainFrame:FindFirstChild("ScanBtn")
    if old then old:Destroy() end
end

-- Переопределяем RefreshContent чтобы удалять Scan
local oldRefreshContent = RefreshContent
RefreshContent = function()
    RemoveScanBtn()
    oldRefreshContent()
end

-- ========== RESIZE ==========
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
ResizeHandle.Position = UDim2.new(1, -18, 1, -18)
ResizeHandle.BackgroundColor3 = THEME.MAIN
ResizeHandle.Text = ""
ResizeHandle.BorderSizePixel = 0
ResizeHandle.Parent = MainFrame
ResizeHandle.AutoButtonColor = false
ResizeHandle.ZIndex = 10

local ResizeCorner = Instance.new("UICorner")
ResizeCorner.CornerRadius = UDim.new(0, 4)
ResizeCorner.Parent = ResizeHandle

local resizing = false
local resizeStart, resizeStartSize
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        resizeStartSize = MainFrame.Size
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        local newX = math.clamp(resizeStartSize.X.Offset + delta.X, 260, 900)
        local newY = math.clamp(resizeStartSize.Y.Offset + delta.Y, 320, 1000)
        MainFrame.Size = UDim2.new(0, newX, 0, newY)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- ========== DRAG ==========
local dragging = false
local dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = input.Position
        local p = CloseBtn.AbsolutePosition
        local s = CloseBtn.AbsoluteSize
        if mousePos.X >= p.X and mousePos.X <= p.X + s.X and mousePos.Y >= p.Y and mousePos.Y <= p.Y + s.Y then
            return
        end
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ========== ИНИЦИАЛИЗАЦИЯ ==========
SwitchTab("Misc")

game:BindToClose(function()
    if collectConn then collectConn:Disconnect() end
    if godConn then godConn:Disconnect() end
    ESPFolder:Destroy()
end)

print("[XyqwPiggy v" .. VERSION .. "] Loaded!")
print("[XyqwPiggy v" .. VERSION .. "] Made by Xyqwerq!")
