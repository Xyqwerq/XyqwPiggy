print("[AF] Loading v14.1...")

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local TextService = game:GetService("TextService")
local LP = Players.LocalPlayer

-- ============================================================
-- КООРДИНАТЫ
-- ============================================================
local BOARD_1      = Vector3.new(-620.67, 125.01, -309.44)
local BOARD_2      = Vector3.new(-620.74, 127.56, -309.44)
local ENERGY_PANEL = Vector3.new(-626.17, 126.91, -309.41)
local EXIT_DOOR    = Vector3.new(-620.87, 126.83, -310.09)
local PEDESTAL     = Vector3.new(-620.87, 125.72, -239.07)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    ATTEMPT = 0,
    ON = false,
    STOP = false,
    DeletePiggy = false,
    DeletePiggyActive = false,
    NoWalk = true,
    AntiAFK = true,
    Destroyed = false,
}

local Remotes = {}
local CD_CACHE = {}
local CD_CACHE_TIME = 0
local dPConn = nil
local afkThread = nil
local AllConnections = {}

local function TrackConn(conn)
    table.insert(AllConnections, conn)
    return conn
end

-- ============================================================
-- ОШИБКИ
-- ============================================================
local function ErrorCritical(msg)
    if State.Destroyed then return end
    error("[AF CRITICAL] " .. tostring(msg), 0)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "⚠ ERROR", Text = tostring(msg), Duration = 6
        })
    end)
end

local function WarnSoft(msg)
    warn("[AF WARN] " .. tostring(msg))
end

-- ============================================================
-- NOTIFY
-- ============================================================
local function Notify(text, duration)
    if State.Destroyed then return end
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XyqwAutoFarm", Text = tostring(text), Duration = duration
        })
    end)
end

-- ============================================================
-- LOG
-- ============================================================
local LOG_LINES = {}
local LOG_MAX = 100
local LogLabelRef = nil
local LogScrollRef = nil
local LOG_FONT = Enum.Font.Code
local LOG_SIZE = 12

local function UpdateLogUI()
    if not LogLabelRef or not LogScrollRef then return end
    local text = ""
    for i = 1, #LOG_LINES do
        text = text .. LOG_LINES[i] .. "\n"
    end
    LogLabelRef.Text = text
    local width = LogScrollRef.AbsoluteSize.X - 8
    if width <= 10 then width = 200 end
    local ok, size = pcall(function()
        return TextService:GetTextSize(text, LOG_SIZE, LOG_FONT, Vector2.new(width, math.huge))
    end)
    local h = (ok and size) and (size.Y + 8) or (#LOG_LINES * 15 + 8)
    LogLabelRef.Size = UDim2.new(1, -6, 0, h)
    LogScrollRef.CanvasSize = UDim2.new(0, 0, 0, h)
    LogScrollRef.CanvasPosition = Vector2.new(0, math.max(0, h - LogScrollRef.AbsoluteSize.Y))
end

local function Log(text)
    if State.Destroyed then return end
    print("[AF] " .. text)
    table.insert(LOG_LINES, text)
    if #LOG_LINES > LOG_MAX then table.remove(LOG_LINES, 1) end
    UpdateLogUI()
end

local lastErrors = {}
local function LogError(text)
    local now = tick()
    if lastErrors[text] and (now - lastErrors[text]) < 30 then
        table.insert(LOG_LINES, "❌ " .. text .. " (dup)")
        if #LOG_LINES > LOG_MAX then table.remove(LOG_LINES, 1) end
        UpdateLogUI()
        return
    end
    lastErrors[text] = now
    Log("❌ " .. text)
    ErrorCritical(text)
end

local function LogWarn(text)
    Log("⚠ " .. text)
    WarnSoft(text)
end

-- ============================================================
-- АНИМАЦИИ
-- ============================================================
local function Tween(obj, time, props, style, dir)
    if not obj or not obj.Parent then return end
    local info = TweenInfo.new(time or 0.35, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function HoverStroke(stroke, normal, hover, normalThick, hoverThick, time)
    local parent = stroke.Parent
    if not parent then return end
    TrackConn(parent.MouseEnter:Connect(function()
        Tween(stroke, time or 0.35, { Color = hover, Thickness = hoverThick }, Enum.EasingStyle.Quart)
    end))
    TrackConn(parent.MouseLeave:Connect(function()
        Tween(stroke, time or 0.35, { Color = normal, Thickness = normalThick }, Enum.EasingStyle.Quart)
    end))
end

local function AddTextStroke(label, thickness)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 0, 0)
    s.Thickness = thickness or 2
    s.Parent = label
    return s
end

-- ============================================================
-- REMOTES / PHASE
-- ============================================================
local function GetRemote(name)
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if r then
        local obj = r:FindFirstChild(name)
        if obj then return obj end
    end
    return nil
end

local function Refresh()
    Remotes.VIPCommandEvent = GetRemote("VIPCommandEvent")
    Remotes.JoinGame = GetRemote("JoinGame")
end

local function GetPhase()
    local gf = workspace:FindFirstChild("GameFolder")
    if not gf then return nil end
    local p = gf:FindFirstChild("Phase")
    return p and p.Value or nil
end

-- ============================================================
-- БЕЗОПАСНЫЙ FIRE (проверка GameInProgress)
-- ============================================================
local function Fire(remote, a, b, c)
    if not remote or State.Destroyed then return end
    if remote.Name == "VIPCommandEvent" then
        for i = 1, 5 do
            if GetPhase() == "GameInProgress" then
                Log("BLOCKED VIP cmd '" .. tostring(a) .. "' (in game)")
                return
            end
            task.wait(0.02)
        end
    end
    -- JoinGame: НЕ отправляем если уже в игре
    if remote.Name == "JoinGame" then
        for i = 1, 5 do
            if GetPhase() == "GameInProgress" then
                Log("BLOCKED JoinGame (in game)")
                return
            end
            task.wait(0.02)
        end
    end
    pcall(function()
        if remote:IsA("RemoteEvent") then remote:FireServer(a, b, c)
        elseif remote:IsA("RemoteFunction") then remote:InvokeServer(a, b, c) end
    end)
end

local function IsVIP()
    local gf = workspace:FindFirstChild("GameFolder")
    if gf then
        local vip = gf:FindFirstChild("IsVIPServer")
        if vip and vip.Value then return true end
    end
    if game.PrivateServerId and game.PrivateServerId ~= "" then
        if game.PrivateServerOwnerId == LP.UserId or game.PrivateServerOwnerId == 0 then
            return true
        end
    end
    return false
end

-- ============================================================
-- ХЕЛПЕРЫ
-- ============================================================
local function GetHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function IsAlive()
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function IsInGame()
    return GetPhase() == "GameInProgress" and IsAlive()
end

local function HasItem(name)
    local char = LP.Character
    local bp = LP:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(name) then return true end
    if char and char:FindFirstChild(name) then return true end
    return false
end

local function GetEggInBackpack()
    local char = LP.Character
    local bp = LP:FindFirstChild("Backpack")
    for _, egg in ipairs({"RedEgg", "GreenEgg"}) do
        if bp and bp:FindFirstChild(egg) then return egg end
        if char and char:FindFirstChild(egg) then return egg end
    end
    return nil
end

local function HasAnyKey()
    local char = LP.Character
    local bp = LP:FindFirstChild("Backpack")
    for _, key in ipairs({"WhiteKey", "YellowKey", "RedKey", "BlueKey", "OrangeKey", "PurpleKey", "GreenKey"}) do
        if bp and bp:FindFirstChild(key) then return key end
        if char and char:FindFirstChild(key) then return key end
    end
    return nil
end

local function HasWrongEgg(desired)
    local bp = LP:FindFirstChild("Backpack")
    local char = LP.Character
    for _, egg in ipairs({"RedEgg", "GreenEgg"}) do
        if egg ~= desired then
            if bp and bp:FindFirstChild(egg) then return egg end
            if char and char:FindFirstChild(egg) then return egg end
        end
    end
    return nil
end

local function IsInMenu(part)
    local c, d = part, 0
    while c and d < 8 do
        if c.Name == "MenuCameras" or c.Name == "MainMenuScreen"
        or c.Name == "MainMenuForest" or c.Name == "ItemsScreen"
        or c.Name == "ItemsFocus" or c.Name == "ItemsCamera"
        or c.Name == "MenuPositions" or c.Name == "MenuStorage" then
            return true
        end
        c = c.Parent; d = d + 1
    end
    return false
end

-- ============================================================
-- DELETE PIGGY
-- ============================================================
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
    if dPConn then return end
    State.DeletePiggy = true
    if IsCutsceneOver() then
        State.DeletePiggyActive = true
        Log("Delete Piggy: ACTIVE")
    else
        State.DeletePiggyActive = false
        Notify("Piggy will be deleted after cutscene!", 5)
        Log("Delete Piggy: ARMED")
    end
    dPConn = RunService.Heartbeat:Connect(function()
        if State.Destroyed or not State.DeletePiggy then return end
        local over = IsCutsceneOver()
        if over and not State.DeletePiggyActive then
            State.DeletePiggyActive = true
            Notify("Delete Piggy: ACTIVE", 3)
            Log("Delete Piggy: ACTIVATED")
        elseif not over and State.DeletePiggyActive then
            State.DeletePiggyActive = false
            Notify("Piggy will be deleted after cutscene!", 5)
            Log("Delete Piggy: PAUSED")
        end
        if State.DeletePiggyActive then RunDeletePiggyTick() end
    end)
end

local function DisableDeletePiggy()
    State.DeletePiggy = false
    State.DeletePiggyActive = false
    if dPConn then dPConn:Disconnect(); dPConn = nil end
    Log("Delete Piggy: OFF")
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
local function EnableAntiAFK()
    if afkThread then return end
    State.AntiAFK = true
    afkThread = task.spawn(function()
        while State.AntiAFK and not State.Destroyed do
            task.wait(60)
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
    Log("Anti-AFK: ON")
end

local function DisableAntiAFK()
    State.AntiAFK = false
    if afkThread then
        pcall(function() task.cancel(afkThread) end)
        afkThread = nil
    end
    Log("Anti-AFK: OFF")
end

-- ============================================================
-- CD КЭШ
-- ============================================================
local function GetCDs(force)
    local now = tick()
    if force or (now - CD_CACHE_TIME > 2) or #CD_CACHE == 0 then
        CD_CACHE = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ClickDetector") then
                local p = obj.Parent
                if p and p:IsA("BasePart") and not IsInMenu(p) then
                    table.insert(CD_CACHE, { cd = obj, part = p, pos = p.Position })
                end
            end
        end
        CD_CACHE_TIME = now
    end
    return CD_CACHE
end

local function InvalidateCDCache()
    CD_CACHE_TIME = 0
end

-- ============================================================
-- ТЕЛЕПОРТ / КЛИК
-- ============================================================
local function Teleport(pos)
    local hrp = GetHRP()
    if not hrp then return false end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    task.wait(0.08)
    if (hrp.Position - pos).Magnitude < 8 then return true end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    task.wait(0.08)
    return (hrp.Position - pos).Magnitude < 15
end

local function ClickOneCD(cd)
    if not cd then return false end
    pcall(function() cd.MaxActivationDistance = math.huge end)
    pcall(function() if fireclickdetector then fireclickdetector(cd) end end)
    pcall(function() cd:MouseClick(LP) end)
    return true
end

local function ClickAround(pos, radius, itemCheck)
    radius = radius or 3
    local cds = GetCDs()
    local found = {}
    for _, entry in ipairs(cds) do
        local d = (entry.pos - pos).Magnitude
        if d <= radius then table.insert(found, { cd = entry.cd, dist = d }) end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    Log("ClickAround: " .. #found .. " CD")
    for i, entry in ipairs(found) do
        if State.STOP or State.Destroyed then return false end
        ClickOneCD(entry.cd)
        task.wait(0.15)
        if itemCheck and HasItem(itemCheck) then
            Log("  OK " .. itemCheck)
            InvalidateCDCache()
            return true
        end
    end
    if itemCheck then
        LogWarn(itemCheck .. " not taken")
        return false
    end
    return #found > 0
end

-- ============================================================
-- ПОИСК
-- ============================================================
local function FindMesh(meshId)
    for _, e in ipairs(GetCDs()) do
        local mesh = e.part:FindFirstChildOfClass("SpecialMesh")
        if mesh and mesh.MeshId and mesh.MeshId:find(meshId) then
            return e.part
        end
    end
    return nil
end

local function FindEgg(color)
    for _, e in ipairs(GetCDs()) do
        local mesh = e.part:FindFirstChildOfClass("SpecialMesh")
        if mesh and mesh.MeshId and mesh.MeshId:find("24829283") then
            local pe = e.part:FindFirstChildOfClass("ParticleEmitter")
            if pe then
                local c3 = nil
                pcall(function()
                    if pe.Color and pe.Color.Keypoints and #pe.Color.Keypoints > 0 then
                        c3 = pe.Color.Keypoints[1].Value
                    end
                end)
                if c3 then
                    local h = Color3.toHSV(c3) * 360
                    if color == "red" and (h < 25 or h > 335) then return e.part end
                    if color == "green" and h > 85 and h < 165 then return e.part end
                end
            end
        end
    end
    return nil
end

local function FindWhiteKey()
    for _, e in ipairs(GetCDs()) do
        local mesh = e.part:FindFirstChildOfClass("SpecialMesh")
        local pe = e.part:FindFirstChildOfClass("ParticleEmitter")
        if mesh and mesh.MeshId and mesh.MeshId:find("456878024") and pe then
            local c3 = nil
            pcall(function()
                if pe.Color and pe.Color.Keypoints and #pe.Color.Keypoints > 0 then
                    c3 = pe.Color.Keypoints[1].Value
                end
            end)
            if c3 then
                local _, s = Color3.toHSV(c3)
                if s < 0.15 then return e.part end
            end
        end
    end
    return nil
end

-- ============================================================
-- ДЕЙСТВИЯ
-- ============================================================
local function TakeItem(meshId, itemName)
    if State.Destroyed then return false end
    if GetEggInBackpack() then Log("Egg in bag, skip " .. itemName); return false end
    if HasItem(itemName) then return true end
    local target = FindMesh(meshId)
    if not target then LogWarn(itemName .. " NOT FOUND (retry)"); return false end
    Log("Take " .. itemName)
    for attempt = 1, 3 do
        if State.Destroyed then return false end
        target = FindMesh(meshId)
        if not target then break end
        Teleport(target.Position)
        task.wait(0.15)
        ClickAround(target.Position, 4, itemName)
        task.wait(0.2)
        if HasItem(itemName) then
            Log(itemName .. " OK")
            return true
        end
    end
    LogWarn(itemName .. " FAILED")
    return false
end

local function PlaceEgg(eggName)
    if not HasItem(eggName) then return true end
    Log("Place " .. eggName)
    for i = 1, 12 do
        if State.STOP or State.Destroyed or not IsInGame() then return false end
        if not HasItem(eggName) then Log(eggName .. " placed OK"); return true end
        Teleport(PEDESTAL)
        task.wait(0.2)
        ClickAround(PEDESTAL, 5)
        task.wait(0.4)
        if not HasItem(eggName) then Log(eggName .. " placed OK"); return true end
    end
    LogWarn(eggName .. " FAILED to place")
    return false
end

local function TakeEgg(color, eggName)
    if HasItem(eggName) then return true end
    local wrong = HasWrongEgg(eggName)
    if wrong then
        Log("Wrong egg: " .. wrong)
        PlaceEgg(wrong)
        task.wait(0.3)
    end
    local key = HasAnyKey()
    if key then
        Log("Drop key: " .. key)
        pcall(function()
            local bp = LP:FindFirstChild("Backpack")
            local k = bp and bp:FindFirstChild(key)
            if k then k:Destroy() end
            local ch = LP.Character
            local k2 = ch and ch:FindFirstChild(key)
            if k2 then k2:Destroy() end
        end)
        task.wait(0.2)
    end
    for i = 1, 8 do
        if State.STOP or State.Destroyed or not IsInGame() then return false end
        local target = FindEgg(color)
        if target then
            Log("Take " .. eggName .. " try " .. i)
            Teleport(target.Position)
            task.wait(0.15)
            ClickAround(target.Position, 4, eggName)
            task.wait(0.3)
            if GetEggInBackpack() == eggName then
                Log(eggName .. " OK")
                return true
            end
        end
        task.wait(0.3)
    end
    LogWarn(eggName .. " FAILED")
    return false
end

local function ClickGuiBtn(name)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, obj in ipairs(pg:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton"))
        and obj.Name == name and obj.Visible then
            pcall(function() if firesignal then firesignal(obj.MouseButton1Click) end end)
            return true
        end
    end
    return false
end

local function GetBalance()
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
    return "??????????"
end

local function WalkForward(maxSeconds)
    maxSeconds = maxSeconds or 25
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local savedSpeed = hum.WalkSpeed
    pcall(function() hum.WalkSpeed = 150 end)
    local look = hrp.CFrame.LookVector
    local dir = Vector3.new(look.X, 0, look.Z)
    if dir.Magnitude < 0.01 then dir = Vector3.new(0, 0, -1) end
    dir = dir.Unit
    local target = hrp.Position + dir * 500
    pcall(function() hum:MoveTo(target) end)
    local t0 = tick()
    local lastPos = hrp.Position
    local stuck = 0
    while tick() - t0 < maxSeconds and not State.STOP and not State.Destroyed do
        task.wait(0.1)
        ClickGuiBtn("Skip")
        if not IsAlive() then break end
        if not hrp.Parent then break end
        local pos = hrp.Position
        if (pos - lastPos).Magnitude < 1 then
            stuck = stuck + 1
            if stuck >= 15 then break end
        else
            stuck = 0
        end
        lastPos = pos
        look = hrp.CFrame.LookVector
        dir = Vector3.new(look.X, 0, look.Z)
        if dir.Magnitude > 0.01 then
            target = hrp.Position + dir.Unit * 500
        end
        pcall(function() hum:MoveTo(target) end)
    end
    pcall(function() hum.WalkSpeed = savedSpeed end)
    Log("Walk done")
end

TrackConn(RunService.RenderStepped:Connect(function()
    if State.Destroyed then return end
    if State.NoWalk then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then
                pcall(function() hum:Move(Vector3.new(0, 0, 0), false) end)
            end
        end
    end
end))

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function MainLoop()
    Log("=== LOOP START ===")
    Notify("Enabled", 3)
    Refresh()
    State.ATTEMPT = 0

    while not State.STOP and not State.Destroyed do
        State.ATTEMPT = State.ATTEMPT + 1
        Log("=== CYCLE #" .. State.ATTEMPT .. " ===")
        Notify("Farming... Attempt: " .. State.ATTEMPT, 3)

        task.wait(0.2)

        local bp = LP:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then pcall(function() t:Destroy() end) end
            end
        end
        local char = LP.Character
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") then pcall(function() t:Destroy() end) end
            end
        end
        task.wait(0.2)

        -- ========================================
        -- ЖДЁМ КОНЕЦ ТЕКУЩЕГО РАУНДА
        -- (чтобы JoinGame не выдал "host ended this round")
        -- ========================================
        Log("Wait for intermission...")
        local tW = tick()
        while tick() - tW < 40 and not State.STOP and not State.Destroyed do
            local p = GetPhase()
            if p == "Intermission" or p == nil or p == "Map Voting" then
                break
            end
            task.wait(0.3)
        end
        if State.STOP or State.Destroyed then break end
        task.wait(0.3)

        Log("Play")
        ClickGuiBtn("Play")
        task.wait(0.3)
        Fire(Remotes.JoinGame, true)
        task.wait(0.3)

        Fire(Remotes.VIPCommandEvent, "SetMap", "Gallery")
        task.wait(0.4)
        Fire(Remotes.VIPCommandEvent, "SkipTimer", true)
        task.wait(0.4)
        Fire(Remotes.VIPCommandEvent, "SetMode", "Swarm")
        task.wait(0.4)
        Fire(Remotes.VIPCommandEvent, "SkipTimer", true)
        task.wait(0.4)

        Log("Wait game...")
        local t3 = tick()
        while tick() - t3 < 60 and not State.STOP and not State.Destroyed do
            local p = GetPhase()
            if p == "GameInProgress" then break end
            if p == "Map Voting" or p == "Piggy Voting"
            or p == "Selecting Map" or p == "Selecting Piggy"
            or p == "Starting Game" or p == "Intermission" then
                Fire(Remotes.VIPCommandEvent, "SkipTimer", true)
                task.wait(1.0)
            else
                task.wait(0.2)
            end
        end
        if State.STOP or State.Destroyed then break end
        task.wait(0.2)

        Log("Skip cutscene...")
        local tCut = tick()
        while tick() - tCut < 10 and not State.STOP and not State.Destroyed do
            ClickGuiBtn("Skip")
            task.wait(0.2)
            if GetPhase() == "GameInProgress" then
                InvalidateCDCache()
                local found = false
                for _, e in ipairs(GetCDs()) do
                    if e.part.Material == Enum.Material.WoodPlanks then
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
        task.wait(0.2)

        if IsAlive() and GetPhase() == "GameInProgress" then
            InvalidateCDCache()

            -- HAMMER
            Log("--- Hammer ---")
            if not HasItem("Hammer") then TakeItem("16198309", "Hammer") end
            if not HasItem("Hammer") and IsInGame() then
                task.wait(1)
                InvalidateCDCache()
                Log("Hammer retry...")
                TakeItem("16198309", "Hammer")
            end
            if HasItem("Hammer") and IsInGame() then
                Teleport(BOARD_1); task.wait(0.15); ClickAround(BOARD_1, 3); task.wait(0.25)
                Teleport(BOARD_2); task.wait(0.15); ClickAround(BOARD_2, 3); task.wait(0.25)
                Log("Boards done")
            end

            -- WRENCH
            Log("--- Wrench ---")
            if not HasItem("Wrench") then TakeItem("16884681", "Wrench") end
            if not HasItem("Wrench") and IsInGame() then
                task.wait(1)
                InvalidateCDCache()
                Log("Wrench retry...")
                TakeItem("16884681", "Wrench")
            end
            if HasItem("Wrench") and IsInGame() then
                Teleport(ENERGY_PANEL); task.wait(0.15); ClickAround(ENERGY_PANEL, 3); task.wait(0.25)
                Log("Panel done")
            end

            -- RED EGG
            Log("--- RedEgg ---")
            if GetEggInBackpack() then PlaceEgg(GetEggInBackpack()); task.wait(0.3) end
            local w1 = HasWrongEgg("RedEgg"); if w1 and IsInGame() then PlaceEgg(w1) end
            task.wait(0.2)
            for attempt = 1, 3 do
                if not IsInGame() then break end
                if not HasItem("RedEgg") then TakeEgg("red", "RedEgg"); task.wait(0.3) end
                if HasItem("RedEgg") then
                    PlaceEgg("RedEgg"); task.wait(0.3)
                    if not HasItem("RedEgg") then Log("RedEgg OK"); break end
                end
                task.wait(0.5)
            end
            task.wait(0.5)

            -- GREEN EGG
            Log("--- GreenEgg ---")
            local w2 = HasWrongEgg("GreenEgg"); if w2 and IsInGame() then PlaceEgg(w2) end
            task.wait(1)
            for attempt = 1, 5 do
                if not IsInGame() then break end
                if not HasItem("GreenEgg") then TakeEgg("green", "GreenEgg"); task.wait(0.3) end
                if HasItem("GreenEgg") then
                    PlaceEgg("GreenEgg"); task.wait(0.3)
                    if not HasItem("GreenEgg") then Log("GreenEgg OK"); break end
                end
                task.wait(0.5)
            end
            task.wait(0.5)

            -- WHITE KEY
            Log("--- WhiteKey ---")
            if IsInGame() and not GetEggInBackpack() then
                if not HasItem("WhiteKey") then
                    local wk = FindWhiteKey()
                    if wk then
                        Teleport(wk.Position); task.wait(0.15)
                        ClickAround(wk.Position, 4, "WhiteKey"); task.wait(0.25)
                    else
                        LogWarn("WhiteKey NOT FOUND")
                    end
                end
                if HasItem("WhiteKey") then
                    Teleport(EXIT_DOOR); task.wait(0.15)
                    ClickAround(EXIT_DOOR, 3); task.wait(0.5)
                    if IsInGame() then WalkForward(25) end
                end
            end
        end

        Log("Final skip")
        local tEnd = tick()
        while tick() - tEnd < 25 and not State.STOP and not State.Destroyed do
            local p = GetPhase()
            ClickGuiBtn("Skip")
            if p == "Intermission" or p == nil then
                Fire(Remotes.VIPCommandEvent, "SkipTimer", true)
                Log("Intermission")
                break
            end
            task.wait(0.25)
        end

        task.wait(0.3)
    end

    Log("=== LOOP STOP ===")
    Notify("Disabled", 3)
    State.ON = false
end

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XyqwAF"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
local pg = LP:FindFirstChild("PlayerGui")
if pg then ScreenGui.Parent = pg end

local function DestroyAll()
    State.Destroyed = true
    State.STOP = true
    State.ON = false
    State.DeletePiggy = false
    State.DeletePiggyActive = false
    State.AntiAFK = false
    if dPConn then pcall(function() dPConn:Disconnect() end); dPConn = nil end
    if afkThread then pcall(function() task.cancel(afkThread) end); afkThread = nil end
    for _, conn in ipairs(AllConnections) do
        pcall(function() conn:Disconnect() end)
    end
    AllConnections = {}
    pcall(function() ScreenGui:Destroy() end)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "XyqwAutoFarm", Text = "Destroyed. Reload script to restore.", Duration = 4
        })
    end)
end

local function GetAdaptiveSize()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local scale = math.min(vp.X / 1920, vp.Y / 1080)
    scale = math.clamp(scale, 0.75, 1.2)
    local w = math.max(260, math.floor(320 * scale))
    local h = math.max(420, math.floor(500 * scale))
    return w, h
end

local MAIN_W, MAIN_H = GetAdaptiveSize()
local SCREEN_CENTER_POS = UDim2.new(0.5, -MAIN_W / 2, 0.5, -MAIN_H / 2)
local SCREEN_HIDDEN_POS = UDim2.new(0.5, -MAIN_W / 2, 0.5, -MAIN_H / 2 + 40)

-- DOCK
local DockBtn = Instance.new("TextButton")
DockBtn.Size = UDim2.new(0, 150, 0, 44)
DockBtn.Position = UDim2.new(0, 30, 0, 100)
DockBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DockBtn.TextColor3 = Color3.fromRGB(255, 120, 210)
DockBtn.Text = "XyqwAutoFarm"
DockBtn.TextSize = 15
DockBtn.Font = Enum.Font.GothamBold
DockBtn.BorderSizePixel = 0
DockBtn.Parent = ScreenGui
DockBtn.AutoButtonColor = false
DockBtn.ZIndex = 1000
local DockC = Instance.new("UICorner"); DockC.CornerRadius = UDim.new(0, 20); DockC.Parent = DockBtn
local DockS = Instance.new("UIStroke"); DockS.Color = Color3.fromRGB(255, 100, 200); DockS.Thickness = 2; DockS.Parent = DockBtn
local DockTS = Instance.new("UIStroke"); DockTS.Color = Color3.fromRGB(0, 0, 0); DockTS.Thickness = 2; DockTS.Parent = DockBtn
HoverStroke(DockS, Color3.fromRGB(255, 100, 200), Color3.fromRGB(255, 180, 230), 2, 3, 0.4)

-- MAIN
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, MAIN_W, 0, MAIN_H)
Main.Position = SCREEN_HIDDEN_POS
Main.BackgroundColor3 = Color3.fromRGB(10, 0, 8)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.BackgroundTransparency = 1
Main.Parent = ScreenGui
local MainC = Instance.new("UICorner"); MainC.CornerRadius = UDim.new(0, 12); MainC.Parent = Main
local MainStroke = Instance.new("UIStroke"); MainStroke.Color = Color3.fromRGB(255, 100, 200); MainStroke.Thickness = 2; MainStroke.Parent = Main

local function OpenMain()
    Main.Visible = true
    Main.BackgroundTransparency = 1
    MainStroke.Transparency = 1
    Main.Position = SCREEN_HIDDEN_POS
    Tween(Main, 0.45, { BackgroundTransparency = 0, Position = SCREEN_CENTER_POS }, Enum.EasingStyle.Quart)
    Tween(MainStroke, 0.45, { Transparency = 0 }, Enum.EasingStyle.Quart)
end

local function CloseMain()
    Tween(Main, 0.32, { BackgroundTransparency = 1, Position = SCREEN_HIDDEN_POS }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    Tween(MainStroke, 0.32, { Transparency = 1 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.35, function() Main.Visible = false end)
end

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 34)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 0, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
local TBC = Instance.new("UICorner"); TBC.CornerRadius = UDim.new(0, 12); TBC.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -46, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "XyqwAutoFarm v14.1 | Gallery"
TitleLabel.TextColor3 = Color3.fromRGB(255, 130, 215)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
TitleLabel.Parent = TitleBar
AddTextStroke(TitleLabel, 2)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 40)
CloseBtn.TextColor3 = Color3.fromRGB(255, 130, 215)
CloseBtn.Text = "X"
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
CloseBtn.AutoButtonColor = false
local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(0, 6); CC.Parent = CloseBtn
local CStroke = Instance.new("UIStroke"); CStroke.Color = Color3.fromRGB(255, 100, 200); CStroke.Thickness = 1.5; CStroke.Parent = CloseBtn
AddTextStroke(CloseBtn, 2)

TrackConn(CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, 0.35, { BackgroundColor3 = Color3.fromRGB(110, 0, 70), Rotation = 90 }, Enum.EasingStyle.Quart)
    Tween(CStroke, 0.35, { Color = Color3.fromRGB(255, 180, 230), Thickness = 2 }, Enum.EasingStyle.Quart)
end))
TrackConn(CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, 0.35, { BackgroundColor3 = Color3.fromRGB(60, 0, 40), Rotation = 0 }, Enum.EasingStyle.Quart)
    Tween(CStroke, 0.35, { Color = Color3.fromRGB(255, 100, 200), Thickness = 1.5 }, Enum.EasingStyle.Quart)
end))

local function MakeToggle(text, y, getState, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 36)
    row.Position = UDim2.new(0, 10, 0, y)
    row.BackgroundColor3 = Color3.fromRGB(30, 0, 22)
    row.BorderSizePixel = 0
    row.Parent = Main
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row
    local rStroke = Instance.new("UIStroke")
    rStroke.Color = Color3.fromRGB(255, 100, 200)
    rStroke.Thickness = 1.5
    rStroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 140, 220)
    lbl.TextSize = 15
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    AddTextStroke(lbl, 2)

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 24, 0, 24)
    box.Position = UDim2.new(1, -34, 0.5, -12)
    box.BackgroundColor3 = getState() and Color3.fromRGB(0, 220, 90) or Color3.fromRGB(220, 0, 0)
    box.Text = ""
    box.BorderSizePixel = 0
    box.Parent = row
    box.AutoButtonColor = false
    box.ZIndex = 5
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = box
    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Color3.fromRGB(255, 100, 200)
    bStroke.Thickness = 1.5
    bStroke.Parent = box

    local function U()
        local target = getState() and Color3.fromRGB(0, 220, 90) or Color3.fromRGB(220, 0, 0)
        Tween(box, 0.35, { BackgroundColor3 = target }, Enum.EasingStyle.Quart)
    end

    TrackConn(row.MouseEnter:Connect(function()
        Tween(row, 0.35, { BackgroundColor3 = Color3.fromRGB(55, 0, 40) }, Enum.EasingStyle.Quart)
        Tween(rStroke, 0.35, { Color = Color3.fromRGB(255, 180, 230), Thickness = 2 }, Enum.EasingStyle.Quart)
    end))
    TrackConn(row.MouseLeave:Connect(function()
        Tween(row, 0.35, { BackgroundColor3 = Color3.fromRGB(30, 0, 22) }, Enum.EasingStyle.Quart)
        Tween(rStroke, 0.35, { Color = Color3.fromRGB(255, 100, 200), Thickness = 1.5 }, Enum.EasingStyle.Quart)
    end))

    TrackConn(box.MouseEnter:Connect(function()
        Tween(box, 0.3, { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -36, 0.5, -14) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(bStroke, 0.3, { Color = Color3.fromRGB(255, 200, 240), Thickness = 2 }, Enum.EasingStyle.Quart)
    end))
    TrackConn(box.MouseLeave:Connect(function()
        Tween(box, 0.3, { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0.5, -12) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        Tween(bStroke, 0.3, { Color = Color3.fromRGB(255, 100, 200), Thickness = 1.5 }, Enum.EasingStyle.Quart)
    end))

    local lastClick = 0
    local function HandleClick()
        local now = tick()
        if now - lastClick < 0.15 then return end
        lastClick = now
        onToggle(); U()
        Notify(text .. ": " .. (getState() and "ON" or "OFF"), 2)
    end

    TrackConn(box.MouseButton1Click:Connect(HandleClick))
    TrackConn(row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            HandleClick()
        end
    end))
end

MakeToggle("Delete Piggy", 44, function() return State.DeletePiggy end, function()
    if State.DeletePiggy then DisableDeletePiggy() else EnableDeletePiggy() end
end)

MakeToggle("NoWalk", 86, function() return State.NoWalk end, function()
    State.NoWalk = not State.NoWalk
end)

MakeToggle("Anti-AFK", 128, function() return State.AntiAFK end, function()
    if State.AntiAFK then DisableAntiAFK() else EnableAntiAFK() end
end)

MakeToggle("AutoFarm", 170, function() return State.ON end, function()
    if State.ON then
        State.STOP = true
        State.ON = false
    else
        if not IsVIP() then Notify("Join on your private server!", 5); return end
        State.STOP = false
        State.ON = true
        task.spawn(MainLoop)
    end
end)

-- DESTROY BTN
local DestroyBtn = Instance.new("TextButton")
DestroyBtn.Size = UDim2.new(1, -20, 0, 32)
DestroyBtn.Position = UDim2.new(0, 10, 0, 214)
DestroyBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 20)
DestroyBtn.TextColor3 = Color3.fromRGB(255, 80, 100)
DestroyBtn.Text = "💥 Destroy XyqwAutoFarm"
DestroyBtn.TextSize = 13
DestroyBtn.Font = Enum.Font.GothamBold
DestroyBtn.BorderSizePixel = 0
DestroyBtn.Parent = Main
DestroyBtn.AutoButtonColor = false
local DBC = Instance.new("UICorner"); DBC.CornerRadius = UDim.new(0, 8); DBC.Parent = DestroyBtn
local DBStroke = Instance.new("UIStroke"); DBStroke.Color = Color3.fromRGB(255, 50, 80); DBStroke.Thickness = 1.5; DBStroke.Parent = DestroyBtn
AddTextStroke(DestroyBtn, 2)

TrackConn(DestroyBtn.MouseEnter:Connect(function()
    Tween(DestroyBtn, 0.3, { BackgroundColor3 = Color3.fromRGB(120, 0, 30) }, Enum.EasingStyle.Quart)
    Tween(DBStroke, 0.3, { Color = Color3.fromRGB(255, 100, 130), Thickness = 2.5 }, Enum.EasingStyle.Quart)
end))
TrackConn(DestroyBtn.MouseLeave:Connect(function()
    Tween(DestroyBtn, 0.3, { BackgroundColor3 = Color3.fromRGB(60, 0, 20) }, Enum.EasingStyle.Quart)
    Tween(DBStroke, 0.3, { Color = Color3.fromRGB(255, 50, 80), Thickness = 1.5 }, Enum.EasingStyle.Quart)
end))
TrackConn(DestroyBtn.MouseButton1Click:Connect(DestroyAll))

-- LOG
local LogFrame = Instance.new("Frame")
LogFrame.AnchorPoint = Vector2.new(0, 1)
LogFrame.Size = UDim2.new(1, -20, 0, 130)
LogFrame.Position = UDim2.new(0, 10, 1, -32)
LogFrame.BackgroundColor3 = Color3.fromRGB(18, 0, 14)
LogFrame.BorderSizePixel = 0
LogFrame.Parent = Main
local LogFrameC = Instance.new("UICorner"); LogFrameC.CornerRadius = UDim.new(0, 8); LogFrameC.Parent = LogFrame
local LStroke = Instance.new("UIStroke"); LStroke.Color = Color3.fromRGB(255, 100, 200); LStroke.Thickness = 1.5; LStroke.Parent = LogFrame

local LogTitle = Instance.new("TextLabel")
LogTitle.Size = UDim2.new(1, -10, 0, 18)
LogTitle.Position = UDim2.new(0, 6, 0, 3)
LogTitle.BackgroundTransparency = 1
LogTitle.Text = "Log (last 100):"
LogTitle.TextColor3 = Color3.fromRGB(255, 140, 220)
LogTitle.TextSize = 12
LogTitle.Font = Enum.Font.GothamBold
LogTitle.TextXAlignment = Enum.TextXAlignment.Left
LogTitle.Parent = LogFrame
AddTextStroke(LogTitle, 2)

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -10, 1, -26)
LogScroll.Position = UDim2.new(0, 5, 0, 24)
LogScroll.BackgroundTransparency = 1
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 5
LogScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 200)
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.Parent = LogFrame
LogScrollRef = LogScroll

local LogLabel = Instance.new("TextLabel")
LogLabel.Size = UDim2.new(1, -6, 0, 0)
LogLabel.Position = UDim2.new(0, 0, 0, 0)
LogLabel.BackgroundTransparency = 1
LogLabel.Text = ""
LogLabel.TextColor3 = Color3.fromRGB(240, 200, 240)
LogLabel.TextSize = LOG_SIZE
LogLabel.Font = LOG_FONT
LogLabel.TextXAlignment = Enum.TextXAlignment.Left
LogLabel.TextYAlignment = Enum.TextYAlignment.Top
LogLabel.TextWrapped = true
LogLabel.Parent = LogScroll
AddTextStroke(LogLabel, 1.5)
LogLabelRef = LogLabel

TrackConn(LogScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLogUI))

-- BALANCE
local Balance = Instance.new("TextLabel")
Balance.AnchorPoint = Vector2.new(0, 1)
Balance.Size = UDim2.new(1, -20, 0, 26)
Balance.Position = UDim2.new(0, 10, 1, -4)
Balance.BackgroundTransparency = 1
Balance.Text = "Piggy Coins: ??????????"
Balance.TextColor3 = Color3.fromRGB(255, 130, 215)
Balance.TextSize = 15
Balance.Font = Enum.Font.GothamBold
Balance.TextXAlignment = Enum.TextXAlignment.Center
Balance.Parent = Main
AddTextStroke(Balance, 2)

task.spawn(function()
    while not State.Destroyed do
        task.wait(3)
        pcall(function()
            Balance.Text = "Piggy Coins: " .. GetBalance()
        end)
    end
end)

-- DRAG MAIN
local drag = false
local dragStart = Vector2.new()
local dragStartScale = Vector2.new()
local dragStartOffset = Vector2.new()
local moved = false

TrackConn(TitleBar.InputBegan:Connect(function(input)
    if State.Destroyed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        local mp = input.Position
        local cp, cs = CloseBtn.AbsolutePosition, CloseBtn.AbsoluteSize
        if mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y then return end
        drag = true; moved = false
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        dragStartScale = Vector2.new(Main.Position.X.Scale, Main.Position.Y.Scale)
        dragStartOffset = Vector2.new(Main.Position.X.Offset, Main.Position.Y.Offset)
    end
end))

TrackConn(UserInputService.InputChanged:Connect(function(input)
    if State.Destroyed then return end
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local dx = input.Position.X - dragStart.X
        local dy = input.Position.Y - dragStart.Y
        if math.abs(dx) > 6 or math.abs(dy) > 6 then moved = true end
        if moved then
            Main.Position = UDim2.new(
                dragStartScale.X, dragStartOffset.X + dx,
                dragStartScale.Y, dragStartOffset.Y + dy
            )
        end
    end
end))

TrackConn(UserInputService.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch) and drag then
        drag = false; moved = false
    end
end))

-- DRAG DOCK
local dDrag, dStart, dStartPos, dMoved = false, nil, nil, false
TrackConn(DockBtn.InputBegan:Connect(function(input)
    if State.Destroyed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dDrag = true; dMoved = false
        dStart = input.Position
        dStartPos = DockBtn.Position
    end
end))

TrackConn(UserInputService.InputChanged:Connect(function(input)
    if dDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dStart
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then dMoved = true end
        if dMoved then
            DockBtn.Position = UDim2.new(0, dStartPos.X.Offset + d.X, 0, dStartPos.Y.Offset + d.Y)
        end
    end
end))

TrackConn(UserInputService.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch) and dDrag then
        if not dMoved then
            DockBtn.Visible = false
            OpenMain()
        end
        dDrag = false
    end
end))

TrackConn(CloseBtn.MouseButton1Click:Connect(function()
    CloseMain()
    task.delay(0.35, function()
        if State.Destroyed then return end
        DockBtn.Visible = true
        DockBtn.BackgroundTransparency = 1
        DockBtn.TextTransparency = 1
        Tween(DockBtn, 0.4, { BackgroundTransparency = 0, TextTransparency = 0 }, Enum.EasingStyle.Quart)
    end)
end))

task.spawn(function()
    task.wait(0.3)
    if State.Destroyed then return end
    DockBtn.BackgroundTransparency = 1
    DockBtn.TextTransparency = 1
    Tween(DockBtn, 0.5, { BackgroundTransparency = 0, TextTransparency = 0 }, Enum.EasingStyle.Quart)
end)

task.spawn(function()
    task.wait(1)
    if State.Destroyed then return end
    EnableAntiAFK()
    Log("Auto-enabled: Anti-AFK, NoWalk")
end)

Notify("AutoFarm v14.1 loaded!", 5)
print("[AF] Ready v14.1")
