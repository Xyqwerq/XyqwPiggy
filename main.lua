-- ========== XyqwPiggy v1.9 ==========
-- Made by Xyqwerq (Mister_Radmirka, ID: 8527910367)
-- Game: Piggy (PlaceId: 4623386862)
-- Fixes 1.9: 3D models WITHOUT WorldModel, ParticleEmitter filter,
--            scroll protection, Roblox notifications only,
--            Tool Usage = doors + items only.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")

local HUB_NAME  = "XyqwPiggy"
local VERSION   = "1.9"
local PIGGY_ID  = 4623386862

if game.PlaceId ~= PIGGY_ID then
    StarterGui:SetCore("SendNotification", {
        Title = HUB_NAME,
        Text = "This script is for Piggy only!",
        Duration = 5
    })
    return
end

if getgenv().XyqwPiggyRunning then
    StarterGui:SetCore("SendNotification", {
        Title = HUB_NAME, Text = "Already running!", Duration = 3
    })
    return
end
getgenv().XyqwPiggyRunning = true

-- ========== MESH ID → NAME ==========
local MESH_NAMES = {
    [456878024]  = "Key",
    [725833400]  = "Hammer",
    [524706126]  = "Item",
    [6714051581] = "Item",
    [16884681]   = "Item",
    [16198309]   = "Plank",
    [72012879]   = "Battery",
    [60791940]   = "Item",
}

-- ========== THEME ==========
local THEME = {
    MAIN   = Color3.fromRGB(255, 0, 0),
    DARK   = Color3.fromRGB(40, 0, 0),
    BG     = Color3.fromRGB(0, 0, 0),
    TITLE  = Color3.fromRGB(20, 0, 0),
    STROKE = Color3.fromRGB(120, 0, 0),
}

-- ========== HELPERS ==========
local function Notify(text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = HUB_NAME, Text = tostring(text), Duration = duration
        })
    end)
end

local function GetItemName(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("SpecialMesh") or d:IsA("MeshPart") then
            local mid = d.MeshId or ""
            local id = tonumber(mid:match("(%d+)"))
            if id and MESH_NAMES[id] then return MESH_NAMES[id] end
        end
    end
    return model.Name
end

-- Real item = has ParticleEmitter somewhere (17 items on map per spec)
local function IsRealItem(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local hasParticle = false
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ParticleEmitter") then hasParticle = true break end
    end
    if not hasParticle then return false end
    -- must have ClickDetector (no ProximityPrompt in Piggy)
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ClickDetector") then return true end
    end
    return false
end

-- Door = ClickDetector + NO ParticleEmitter
local function IsDoor(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local hasClick, hasParticle = false, false
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ClickDetector") then hasClick = true end
        if d:IsA("ParticleEmitter") then hasParticle = true end
    end
    return hasClick and not hasParticle
end

-- ========== SCAN ==========
local cachedItems, cachedDoors = {}, {}

local function GetMapRoot()
    return workspace:FindFirstChild("Map") or workspace
end

local function ScanMap()
    cachedItems, cachedDoors = {}, {}
    local root = GetMapRoot()
    for _, obj in ipairs(root:GetDescendants()) do
        if IsRealItem(obj) then
            table.insert(cachedItems, obj)
        elseif IsDoor(obj) then
            table.insert(cachedDoors, obj)
        end
    end
    return #cachedItems, #cachedDoors
end

-- ========== ESP ==========
local activeHighlights = {}
local espEnabled = {Items = false, Monster = false, Players = false}

local function ClearESP()
    for _, hl in pairs(activeHighlights) do
        pcall(function() hl:Destroy() end)
    end
    activeHighlights = {}
end

local function ApplyHighlight(obj, color)
    if not obj then return end
    local target = obj:IsA("Model") and obj or obj
    if activeHighlights[target] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = target
    activeHighlights[target] = hl
end

local function UpdateESP()
    ClearESP()
    if espEnabled.Items then
        for _, item in ipairs(cachedItems) do
            ApplyHighlight(item, Color3.fromRGB(0, 255, 100))
        end
    end
    if espEnabled.Monster then
        local lp = Players.LocalPlayer
        local myChar = lp and lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                -- Piggy bot = no Humanoid OR name contains "Piggy"/"Bot"
                local isBot = not hum or plr.Name:lower():find("piggy") or plr.Name:lower():find("bot")
                if isBot then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot and root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist < 100 then
                            ApplyHighlight(plr.Character, Color3.fromRGB(255, 0, 0))
                        end
                    else
                        ApplyHighlight(plr.Character, Color3.fromRGB(255, 0, 0))
                    end
                end
            end
        end
    end
    if espEnabled.Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer and plr.Character then
                ApplyHighlight(plr.Character, Color3.fromRGB(0, 150, 255))
            end
        end
    end
end

-- ========== 3D VIEWPORT MODELS (БЕЗ WorldModel) ==========
-- WorldModel ломал отображение. Используем чистый Model + Camera внутри ViewportFrame.
local function Create3DPreview(obj, size)
    size = size or UDim2.new(0, 64, 0, 64)

    local vp = Instance.new("ViewportFrame")
    vp.Size = size
    vp.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
    vp.BorderSizePixel = 1
    vp.BorderColor3 = THEME.MAIN
    vp.Ambient = Color3.fromRGB(180, 180, 180)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(-1, -1, -1)

    -- Clone and sanitize
    local clone = obj:Clone()
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript")
           or d:IsA("ParticleEmitter") or d:IsA("ClickDetector")
           or d:IsA("BillboardGui") or d:IsA("SurfaceGui")
           or d:IsA("Sound") or d:IsA("PointLight") or d:IsA("SpotLight") then
            d:Destroy()
        end
    end
    -- Unanchor everything, kill physics
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanTouch = false
            d.CanQuery = false
            d.Transparency = math.max(d.Transparency, 0)
        end
    end

    -- IMPORTANT: ставим модель НАПРЯМУЮ в ViewportFrame, без WorldModel.
    clone.Parent = vp

    -- Bounding box из модели
    local cf, sz
    if clone:IsA("Model") then
        local ok, mcf, msz = pcall(function() return clone:GetBoundingBox() end)
        if ok then cf, sz = mcf, msz else
            cf = CFrame.new(); sz = Vector3.new(2, 2, 2)
        end
    elseif clone:IsA("BasePart") then
        cf = clone.CFrame; sz = clone.Size
    else
        cf = CFrame.new(); sz = Vector3.new(2, 2, 2)
    end

    -- Move clone so its center is at origin for stable camera math
    local centerOffset = cf.Position
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CFrame = d.CFrame - centerOffset
        end
    end

    local radius = math.max(sz.X, sz.Y, sz.Z) * 0.5
    if radius <= 0 then radius = 1 end

    local cam = Instance.new("Camera")
    cam.FieldOfView = 40
    cam.Parent = vp
    cam.CFrame = CFrame.new(Vector3.new(radius * 2.4, radius * 1.4, radius * 2.4), Vector3.new(0, 0, 0))
    vp.CurrentCamera = cam

    return vp
end

-- ========== SCROLL PROTECTION ==========
-- Флаг: если пользователь скроллит — клики по кнопкам блокируются на 0.3 сек.
local scrollBlockedUntil = 0
local function BlockClicksFor(t)
    scrollBlockedUntil = math.max(scrollBlockedUntil, tick() + (t or 0.3))
end

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XyqwPiggyGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end)
if not screenGui.Parent then screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

-- ========== MAIN FRAME ==========
local main = Instance.new("Frame")
main.Name = "XyqwPiggyMain"
main.Size = UDim2.new(0, 280, 0, 340)
main.Position = UDim2.new(0.5, -140, 0.5, -170)
main.BackgroundColor3 = THEME.BG
main.BorderSizePixel = 2
main.BorderColor3 = THEME.MAIN
main.Active = true
main.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = THEME.TITLE
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = HUB_NAME .. " v" .. VERSION .. " | by Xyqwerq ♡"
titleLabel.TextColor3 = THEME.MAIN
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 1, 0)
closeBtn.Position = UDim2.new(1, -26, 0, 0)
closeBtn.BackgroundColor3 = THEME.DARK
closeBtn.TextColor3 = THEME.MAIN
closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 1
closeBtn.BorderColor3 = THEME.MAIN
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar

-- drag main
local dragStart, startPos, dragging = nil, nil, false
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

-- ========== SCROLL ==========
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -38)
scroll.Position = UDim2.new(0, 5, 0, 33)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = THEME.MAIN
scroll.Parent = main

scroll.Changed:Connect(function(prop)
    if prop == "CanvasPosition" or prop == "AbsoluteCanvasPosition" then
        BlockClicksFor(0.3)
    end
end)
-- We'll listen to UserInputService wheel too
UserInputService.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseWheel then
        if scroll.AbsolutePosition and i.Position.X >= scroll.AbsolutePosition.X
           and i.Position.X <= scroll.AbsolutePosition.X + scroll.AbsoluteSize.X
           and i.Position.Y >= scroll.AbsolutePosition.Y
           and i.Position.Y <= scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y then
            BlockClicksFor(0.3)
        end
    end
end)

-- ========== TOGGLE ROW ==========
local rowHeight = 40
local rows = {}
local function AddToggleRow(text, initialState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, rowHeight - 4)
    row.BackgroundColor3 = THEME.BG
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.STROKE
    row.Parent = scroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.AutoButtonColor = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.MAIN
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local state = initialState and true or false
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 22, 0, 22)
    box.Position = UDim2.new(1, -32, 0.5, -11)
    box.BackgroundColor3 = state and Color3.fromRGB(0, 220, 90) or Color3.fromRGB(220, 30, 30)
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.MAIN
    box.Parent = row
    box.ZIndex = 5

    btn.MouseButton1Click:Connect(function()
        if tick() < scrollBlockedUntil then return end
        state = not state
        box.BackgroundColor3 = state and Color3.fromRGB(0, 220, 90) or Color3.fromRGB(220, 30, 30)
        Notify(text .. ": " .. (state and "ON" or "OFF"), 2)
        if callback then pcall(callback, state) end
    end)

    table.insert(rows, row)
    return row
end

-- ========== ACTION ROW ==========
local function AddActionRow(text, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, rowHeight - 4)
    row.BackgroundColor3 = THEME.DARK
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.MAIN
    row.Parent = scroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = THEME.MAIN
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = row
    btn.AutoButtonColor = false

    btn.MouseButton1Click:Connect(function()
        if tick() < scrollBlockedUntil then return end
        if callback then pcall(callback) end
    end)
    table.insert(rows, row)
    return row
end

-- ========== FUNCTIONS ==========
-- ESP Items
AddToggleRow("ESP Items", false, function(v)
    espEnabled.Items = v
    if v then ScanMap() end
    UpdateESP()
end)

-- ESP Monster
AddToggleRow("ESP Monster (<100 studs)", false, function(v)
    espEnabled.Monster = v
    UpdateESP()
end)

-- ESP Players
AddToggleRow("ESP Players", false, function(v)
    espEnabled.Players = v
    UpdateESP()
end)

-- Anti-Trap
local antiTrapActive = false
AddToggleRow("Anti-Trap", false, function(v)
    antiTrapActive = v
    if v then
        task.spawn(function()
            while antiTrapActive and screenGui.Parent do
                local lp = Players.LocalPlayer
                local char = lp and lp.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("BasePart") and obj.Name:lower():find("trap")
                               and (obj.Position - hrp.Position).Magnitude < 15 then
                                obj.CanTouch = false
                                obj.CanCollide = false
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end)

-- Delete Piggy (Visual)
AddToggleRow("Delete Piggy (Visual)", false, function(v)
    if v then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local isBot = not hum or plr.Name:lower():find("piggy") or plr.Name:lower():find("bot")
                if isBot then
                    for _, d in ipairs(plr.Character:GetDescendants()) do
                        if d:IsA("BasePart") then
                            d.Transparency = 1
                            d.CanCollide = false
                            count = count + 1
                        end
                    end
                end
            end
        end
        Notify("Deleted Piggy visually (" .. count .. " parts)", 3)
    else
        -- can't restore, need character reload
        Notify("Visual delete can't be undone without respawn", 3)
    end
end)

-- Scan
AddActionRow("Scan Map", function()
    local items, doors = ScanMap()
    Notify("Items: " .. items .. " | Doors: " .. doors, 4)
    if espEnabled.Items or espEnabled.Monster or espEnabled.Players then
        UpdateESP()
    end
end)

-- Tool Usage (doors + items only)
AddActionRow("Tool Usage (Doors + Items)", function()
    local lp = Players.LocalPlayer
    local char = lp.Character
    if not char then Notify("No character", 3) return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then Notify("No HRP", 3) return end

    ScanMap()
    local original = hrp.CFrame
    local used = 0

    local function UseTarget(target)
        if not target then return end
        local cd
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("ClickDetector") then cd = d break end
        end
        if not cd then return end
        local part
        if target:IsA("Model") then
            part = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
        else
            part = target
        end
        if not part then return end
        pcall(function()
            hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.15)
            fireclickdetector(cd)
            task.wait(0.1)
            used = used + 1
        end)
        hrp.CFrame = original
        task.wait(0.1)
    end

    task.spawn(function()
        for _, door in ipairs(cachedDoors) do
            if not screenGui.Parent then break end
            UseTarget(door)
        end
        for _, item in ipairs(cachedItems) do
            if not screenGui.Parent then break end
            UseTarget(item)
        end
        hrp.CFrame = original
        Notify("Tool Usage used on " .. used .. " objects", 3)
    end)
end)

-- Item 3D previews window
AddActionRow("Item Previews (3D)", function()
    ScanMap()
    if #cachedItems == 0 then Notify("No items found — scan first", 3) return end

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 320, 0, 400)
    win.Position = UDim2.new(0.5, -160, 0.5, -200)
    win.BackgroundColor3 = THEME.BG
    win.BorderSizePixel = 2
    win.BorderColor3 = THEME.MAIN
    win.Active = true
    win.Parent = screenGui

    local wTitle = Instance.new("TextLabel")
    wTitle.Size = UDim2.new(1, -30, 0, 24)
    wTitle.Position = UDim2.new(0, 5, 0, 5)
    wTitle.BackgroundTransparency = 1
    wTitle.TextColor3 = THEME.MAIN
    wTitle.Text = "Items (" .. #cachedItems .. ") — click to TP+grab"
    wTitle.TextScaled = true
    wTitle.Font = Enum.Font.GothamBold
    wTitle.Parent = win

    local wClose = Instance.new("TextButton")
    wClose.Size = UDim2.new(0, 22, 0, 22)
    wClose.Position = UDim2.new(1, -26, 0, 6)
    wClose.BackgroundColor3 = THEME.DARK
    wClose.TextColor3 = THEME.MAIN
    wClose.Text = "X"
    wClose.TextScaled = true
    wClose.Font = Enum.Font.GothamBold
    wClose.BorderSizePixel = 1
    wClose.BorderColor3 = THEME.MAIN
    wClose.Parent = win
    wClose.MouseButton1Click:Connect(function() win:Destroy() end)

    -- drag
    local dS, sP, dg = nil, nil, false
    wTitle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dg = true; dS = i.Position; sP = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dS
            win.Position = UDim2.new(sP.X.Scale, sP.X.Offset + d.X, sP.Y.Scale, sP.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dg = false
        end
    end)

    local wScroll = Instance.new("ScrollingFrame")
    wScroll.Size = UDim2.new(1, -10, 1, -38)
    wScroll.Position = UDim2.new(0, 5, 0, 33)
    wScroll.BackgroundTransparency = 1
    wScroll.BorderSizePixel = 0
    wScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#cachedItems / 3) * 120)
    wScroll.ScrollBarThickness = 4
    wScroll.ScrollBarImageColor3 = THEME.MAIN
    wScroll.Parent = win

    local localBlockUntil = 0
    wScroll.Changed:Connect(function(p)
        if p == "CanvasPosition" then localBlockUntil = tick() + 0.3 end
    end)

    for idx, item in ipairs(cachedItems) do
        local col = (idx - 1) % 3
        local row = math.floor((idx - 1) / 3)
        local cell = Instance.new("Frame")
        cell.Size = UDim2.new(0, 100, 0, 116)
        cell.Position = UDim2.new(0, col * 103, 0, row * 120)
        cell.BackgroundColor3 = THEME.DARK
        cell.BorderSizePixel = 1
        cell.BorderColor3 = THEME.MAIN
        cell.Parent = wScroll

        local prev = Create3DPreview(item, UDim2.new(0, 96, 0, 70))
        prev.Position = UDim2.new(0, 2, 0, 2)
        prev.Parent = cell

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -4, 0, 18)
        nameLbl.Position = UDim2.new(0, 2, 0, 74)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextColor3 = THEME.MAIN
        nameLbl.Text = GetItemName(item)
        nameLbl.TextScaled = true
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.Parent = cell

        local grabBtn = Instance.new("TextButton")
        grabBtn.Size = UDim2.new(1, -4, 0, 18)
        grabBtn.Position = UDim2.new(0, 2, 0, 94)
        grabBtn.BackgroundColor3 = THEME.MAIN
        grabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        grabBtn.Text = "Grab"
        grabBtn.TextScaled = true
        grabBtn.Font = Enum.Font.GothamBold
        grabBtn.BorderSizePixel = 0
        grabBtn.Parent = cell
        grabBtn.AutoButtonColor = false

        grabBtn.MouseButton1Click:Connect(function()
            if tick() < localBlockUntil then return end
            local lp = Players.LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local cd
            for _, d in ipairs(item:GetDescendants()) do
                if d:IsA("ClickDetector") then cd = d break end
            end
            if not cd then Notify("No ClickDetector", 2) return end
            local part = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
            if not part then return end
            local orig = hrp.CFrame
            pcall(function()
                hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.15)
                fireclickdetector(cd)
                task.wait(0.1)
                hrp.CFrame = orig
            end)
            Notify("Grabbed: " .. GetItemName(item), 2)
        end)
    end
end)

-- Anti-Trap already added above; Layout rows
task.spawn(function()
    local y = 5
    for _, row in ipairs(rows) do
        row.Position = UDim2.new(0, 5, 0, y)
        y = y + rowHeight
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end)

-- Auto-rescan every 10s if any ESP is on
task.spawn(function()
    while screenGui.Parent do
        task.wait(10)
        if espEnabled.Items or espEnabled.Monster or espEnabled.Players then
            ScanMap()
            UpdateESP()
        end
    end
end)

-- Initial scan
task.spawn(function()
    task.wait(2)
    local items, doors = ScanMap()
    Notify("Ready. Items: " .. items .. ", Doors: " .. doors, 4)
end)

-- Cleanup
game:BindToClose(function()
    getgenv().XyqwPiggyRunning = nil
end)
