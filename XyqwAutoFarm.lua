-- ============================================================
-- XyqwAutoFarm v1.0
-- Loaded by XyqwPiggy main.lua
-- Author: Xyqwerq
-- ============================================================

print("[XyqwAutoFarm] Loading...")

local _ok, _err = pcall(function()

local Players           = game:GetService("Players")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local LP                = Players.LocalPlayer

-- ============================================================
-- CHECK: не запущен ли уже
-- ============================================================
if _G.__XyqwAutoFarmRunning then
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XyqwAutoFarm",
            Text = "AutoFarm already running!",
            Duration = 3
        })
    end)
    return
end

local function Notify(text, duration)
    duration = duration or 2
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XyqwAutoFarm", Text = tostring(text), Duration = duration
        })
    end)
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    Running = false,
    NeedStop = false,
    CurrentCycle = 0,
    ItemsCollected = 0,
    Config = {
        MAP = "Gallery",
        MODE = "Swarm",
        SKIP_TIMER = true,
        COLLECT_DELAY = 0.05,
        RESCAN_DELAY = 0.3,
        MAX_GAME_TIME = 180,
        AUTO_LOOP = true,
        AUTO_PLAY = true,
        AUTO_SKIP = true,
        AUTO_COLLECT = true,
    },
}

_G.__XyqwAutoFarmRunning = true
_G.__XyqwAutoFarmStop = function()
    State.NeedStop = true
    State.Running = false
end

-- ============================================================
-- REMOTES
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
    print("[XyqwAutoFarm] JoinGame:", FarmRemotes.JoinGame)
    print("[XyqwAutoFarm] VIPCommandEvent:", FarmRemotes.VIPCommandEvent)
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

local function FindButtonRecursive(parent, name)
    if not parent then return nil end
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("TextButton") then
            if obj.Name:lower() == name:lower() and obj.Visible then return obj end
        end
    end
    return nil
end

local function SafeClickBtn(btn)
    if not btn then return false end
    if firesignal then
        return pcall(function() firesignal(btn.MouseButton1Click) end)
    end
    return false
end

-- ============================================================
-- PRIVATE SERVER CHECK
-- ============================================================
local function IsPrivateServer()
    local gf = workspace:FindFirstChild("GameFolder")
    if gf then
        local v = gf:FindFirstChild("IsVIPServer")
        if v and v:IsA("BoolValue") then return v.Value end
    end
    return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

-- ============================================================
-- FARM LOGIC
-- ============================================================
local function GetListItems()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local isMenu = false
                local c = part
                local depth = 0
                while c and depth < 8 do
                    if c.Name == "MenuCameras" or c.Name == "GameFolder" or c.Name == "MainMenuForest" then
                        isMenu = true; break
                    end
                    c = c.Parent; depth = depth + 1
                end
                if not isMenu then
                    local hasPE = part:FindFirstChildOfClass("ParticleEmitter") ~= nil
                    local hasPickup = false
                    for _, ch in ipairs(part:GetChildren()) do
                        if ch:IsA("Script") and (ch.Name == "ItemPickupScript" or ch.Name == "NewItemPickupScript") then
                            hasPickup = true; break
                        end
                    end
                    if hasPE or hasPickup then
                        table.insert(items, { part = part, detector = obj })
                    end
                end
            end
        end
    end
    return items
end

local function FarmPressPlay()
    if FarmRemotes.JoinGame and SafeFireRemote(FarmRemotes.JoinGame, true) then
        task.wait(0.4); return true
    end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, name in ipairs({"Play", "play", "PlayButton"}) do
            local b = FindButtonRecursive(pg, name)
            if b then SafeClickBtn(b); return true end
        end
    end
    return false
end

local function FarmPressSkip()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    local b = FindButtonRecursive(pg, "Skip")
    if b then SafeClickBtn(b); Notify("Skip pressed", 1); return true end
    if FarmRemotes.VIPCommandEvent then
        SafeFireRemote(FarmRemotes.VIPCommandEvent, "SkipTimer", true)
        return true
    end
    return false
end

local function FarmSetupGallery()
    if not FarmRemotes.VIPCommandEvent then RefreshFarmRemotes() end
    if not FarmRemotes.VIPCommandEvent then
        print("[XyqwAutoFarm] VIPCommandEvent not found")
        return false
    end
    SafeFireRemote(FarmRemotes.VIPCommandEvent, "SetMap", State.Config.MAP)
    task.wait(0.3)
    SafeFireRemote(FarmRemotes.VIPCommandEvent, "SetMode", State.Config.MODE)
    task.wait(0.3)
    SafeFireRemote(FarmRemotes.VIPCommandEvent, "SkipTimer", true)
    return true
end

local function FarmCollectOnce()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local items = GetListItems()
    print("[XyqwAutoFarm] Found items:", #items)
    local collected = 0
    for _, item in ipairs(items) do
        if State.NeedStop then break end
        local saved = hrp.CFrame
        pcall(function() item.detector.MaxActivationDistance = math.huge end)
        pcall(function() hrp.CFrame = CFrame.new(item.part.Position + Vector3.new(0, 3, 0)) end)
        task.wait(State.Config.COLLECT_DELAY)
        pcall(function() if fireclickdetector then fireclickdetector(item.detector) end end)
        task.wait(State.Config.COLLECT_DELAY)
        pcall(function() hrp.CFrame = saved end)
        collected = collected + 1
        State.ItemsCollected = State.ItemsCollected + 1
    end
    return collected
end

local function FarmMainLoop()
    State.Running = true
    Notify("Started!", 3)
    print("[XyqwAutoFarm] Loop started")
    RefreshFarmRemotes()

    while State.Config.AUTO_LOOP and not State.NeedStop do
        State.CurrentCycle = State.CurrentCycle + 1
        State.ItemsCollected = 0
        Notify("Cycle #" .. State.CurrentCycle, 2)

        local phase = GetGamePhase()
        if not phase or phase == "GameInProgress" then
            local t = tick()
            while tick() - t < 200 do
                if State.NeedStop then break end
                if GetGamePhase() == "Intermission" then break end
                task.wait(0.5)
            end
        end

        if State.NeedStop then break end

        if State.Config.AUTO_PLAY then
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
            if State.NeedStop then break end
            if GetGamePhase() == "GameInProgress" then break end
            task.wait(0.5)
        end

        if State.NeedStop then break end

        if GetGamePhase() == "GameInProgress" then
            task.wait(2)
            FarmCollectOnce()
            Notify("Collected: " .. State.ItemsCollected, 3)
            print("[XyqwAutoFarm] Cycle collected:", State.ItemsCollected)
            if State.Config.AUTO_SKIP then
                task.wait(2)
                FarmPressSkip()
                task.wait(3)
                FarmPressSkip()
            end
        end

        task.wait(3)
    end

    State.Running = false
    _G.__XyqwAutoFarmRunning = false
    Notify("Stopped", 3)
    print("[XyqwAutoFarm] Loop stopped")
    -- Обновляем тоггл если он есть
    if _G.__XyqwAutoFarmUpdateToggle then
        _G.__XyqwAutoFarmUpdateToggle(false)
    end
end

_G.__XyqwAutoFarmStart = FarmMainLoop

-- ============================================================
-- ПОИСК MiscScroll в главном GUI XyqwPiggy
-- ============================================================
local function FindMiscScroll()
    -- Ищем в CoreGui
    local cg = CoreGui:FindFirstChild("XyqwPiggy")
    if cg then
        local misc = cg:FindFirstChild("MiscFrame", true)
        if misc then
            local scroll = misc:FindFirstChild("MiscScroll", true)
            if scroll then return scroll end
        end
    end
    -- Ищем в PlayerGui
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local xp = pg:FindFirstChild("XyqwPiggy")
        if xp then
            local misc = xp:FindFirstChild("MiscFrame", true)
            if misc then
                local scroll = misc:FindFirstChild("MiscScroll", true)
                if scroll then return scroll end
            end
        end
    end
    return nil
end

-- ============================================================
-- СОЗДАНИЕ ТОГГЛА в стиле XyqwPiggy MakeToggle
-- ============================================================
local function CreateAutoFarmToggle(miscScroll)
    if not miscScroll then
        Notify("MiscScroll not found!", 3)
        return nil
    end

    -- Ищем уже существующий чтобы не дублировать
    local existing = miscScroll:FindFirstChild("XyqwAutoFarmToggle")
    if existing then return existing end

    local THEME = {
        DARK   = Color3.fromRGB(40, 0, 0),
        MAIN   = Color3.fromRGB(255, 0, 0),
        STROKE = Color3.fromRGB(120, 0, 0),
        ON     = Color3.fromRGB(0, 220, 90),
        OFF    = Color3.fromRGB(220, 0, 0),
    }

    local row = Instance.new("Frame")
    row.Name = "XyqwAutoFarmToggle"
    row.Size = UDim2.new(1, -4, 0, 28)
    row.BackgroundColor3 = THEME.DARK
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.MAIN
    row.Parent = miscScroll
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row

    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.STROKE
    stroke.Thickness = 1
    stroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "XyqwAutoFarm"
    lbl.TextColor3 = THEME.MAIN
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local ls = Instance.new("UIStroke")
    ls.Color = Color3.fromRGB(0, 0, 0)
    ls.Thickness = 1.5
    ls.Parent = lbl

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(1, -24, 0.5, -9)
    box.BackgroundColor3 = THEME.OFF
    box.Text = ""
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.MAIN
    box.Parent = row
    box.AutoButtonColor = false
    box.ZIndex = 5
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = box

    local bs = Instance.new("UIStroke")
    bs.Color = THEME.STROKE
    bs.Thickness = 1
    bs.Parent = box

    local catcher = Instance.new("TextButton")
    catcher.Size = UDim2.new(1, 0, 1, 0)
    catcher.BackgroundTransparency = 1
    catcher.Text = ""
    catcher.ZIndex = 10
    catcher.AutoButtonColor = false
    catcher.Parent = row

    local isOn = false

    local function UpdateBox()
        box.BackgroundColor3 = isOn and THEME.ON or THEME.OFF
    end

    _G.__XyqwAutoFarmUpdateToggle = function(state)
        isOn = state
        UpdateBox()
    end

    local function fire()
        isOn = not isOn
        UpdateBox()
        if isOn then
            Notify("ON - loading...", 2)
            -- проверка сервера
            if not IsPrivateServer() then
                Notify("[!] PUBLIC server, may not work!", 3)
            else
                Notify("[OK] PRIVATE server", 2)
            end
            State.NeedStop = false
            State.CurrentCycle = 0
            State.ItemsCollected = 0
            _G.__XyqwAutoFarmRunning = true
            task.spawn(FarmMainLoop)
        else
            Notify("OFF - stopping...", 2)
            State.NeedStop = true
            State.Running = false
            _G.__XyqwAutoFarmRunning = false
        end
    end

    -- Защита от скролла (как в MakeToggle)
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
            local lastScroll = _G.__XyqwPiggyLastScroll or 0
            local scrolling = _G.__XyqwPiggyScrolling or false
            if not moved and held < 0.4 and (tick() - lastScroll) > 0.4 and not scrolling then
                local mp = input.Position
                local cp, cs = catcher.AbsolutePosition, catcher.AbsoluteSize
                if mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then
                    fire()
                end
            end
            pressPos = nil
        end
    end)

    UpdateBox()
    print("[XyqwAutoFarm] Toggle created in MiscScroll")
    return row
end

-- ============================================================
-- СОЗДАНИЕ ТОГГЛА
-- ============================================================
task.spawn(function()
    -- ждём загрузки GUI XyqwPiggy
    local tries = 0
    while tries < 20 do
        local scroll = FindMiscScroll()
        if scroll then
            CreateAutoFarmToggle(scroll)
            Notify("Toggle added to Misc", 3)
            return
        end
        task.wait(0.5)
        tries = tries + 1
    end
    Notify("MiscScroll not found - check XyqwPiggy loaded", 5)
    warn("[XyqwAutoFarm] MiscScroll not found after 10 seconds")
end)

print("[XyqwAutoFarm] Ready")

end)

if not _ok then
    warn("[XyqwAutoFarm FATAL] " .. tostring(_err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "XyqwAutoFarm",
            Text = "Error: " .. tostring(_err),
            Duration = 5
        })
    end)
else
    print("[XyqwAutoFarm] Loaded successfully")
end
