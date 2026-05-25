--[[
    RIVALS ULTRA CHEAT by NocturAI Code
    Features: Aimbot, Silent Aim, ESP, AutoFarm, Godmode, Fly, Teleport
    Usage: loadstring(game:HttpGet("https://..."))();
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local ContextActionService = game:GetService("ContextActionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Anti-Detection: Disable hook spy
local old; old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FindFirstChild" and self == game then
        local args = {...}
        if args[1] == "RobloxReplicatedStorage" then
            return nil
        end
    end
    return old(self, ...)
end))

-- Clean metatables
for _, v in pairs(getconnections(Players.LocalPlayer.Idled)) do
    v:Disable()
end

-- Identify game-specific events
local AttackRemote = nil
local DashRemote = nil
local MoveRemote = nil
for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        if v.Name:lower():find("attack") then
            AttackRemote = v
        elseif v.Name:lower():find("dash") or v.Name:lower():find("roll") then
            DashRemote = v
        elseif v.Name:lower():find("move") then
            MoveRemote = v
        end
    end
end
if not AttackRemote then
    -- fallback: first RemoteEvent in ReplicatedStorage
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            AttackRemote = v
            break
        end
    end
end

-- GUI Setup
local UIS = UserInputService
local screensize = Vector2.new(Camera.ViewportSize.X, Camera.ViewportSize.Y)
local gui = {
    open = true,
    tabs = {},
    currentTab = "Combat",
}

-- Drawing Library Wrapper (creates a basic UI)
local drawings = {}
local function newDrawing(type, props)
    local d
    if type == "Square" then
        d = Drawing.new("Square")
    elseif type == "Text" then
        d = Drawing.new("Text")
    elseif type == "Line" then
        d = Drawing.new("Line")
    elseif type == "Circle" then
        d = Drawing.new("Circle")
    end
    for k,v in pairs(props) do
        d[k] = v
    end
    table.insert(drawings, d)
    return d
end

-- Menu background
local menuBG = newDrawing("Square", {
    Size = Vector2.new(500, 380),
    Position = Vector2.new(50, 50),
    Color = Color3.fromRGB(30,30,30),
    Transparency = 0.7,
    Visible = false,
})
local menuTitle = newDrawing("Text", {
    Text = "Rivals Ultra",
    Size = 24,
    Position = Vector2.new(60, 55),
    Color = Color3.fromRGB(255,100,100),
    Center = false,
    Outline = true,
    Visible = false,
})

-- Tab system
local tabs = {"Combat", "Visuals", "Movement", "Misc"}
local tabButtons = {}
local function drawTab(name, idx)
    local x = 60 + (idx-1)*110
    local btn = newDrawing("Square", {
        Size = Vector2.new(100, 25),
        Position = Vector2.new(x, 85),
        Color = name == gui.currentTab and Color3.fromRGB(180,50,50) or Color3.fromRGB(50,50,50),
        Visible = false,
    })
    local txt = newDrawing("Text", {
        Text = name,
        Size = 16,
        Position = Vector2.new(x+10, 88),
        Color = Color3.fromRGB(255,255,255),
        Visible = false,
    })
    table.insert(tabButtons, {btn = btn, txt = txt, name = name, x = x})
end
for i, t in ipairs(tabs) do
    drawTab(t, i)
end

-- Toggle/Slider creation
local options = {}
local function addToggle(tab, name, default, callback)
    table.insert(options, {type="toggle", tab=tab, name=name, value=default, callback=callback})
end
local function addSlider(tab, name, min, max, default, step, callback)
    table.insert(options, {type="slider", tab=tab, name=name, min=min, max=max, value=default, step=step, callback=callback})
end

-- Declare UI elements later when drawing
local optionDrawings = {}
local function refreshOptions()
    -- Remove old drawings for options
    for _, d in ipairs(optionDrawings) do
        d:Remove()
    end
    optionDrawings = {}
    local yOff = 120
    local tabFilter = gui.currentTab
    for _, opt in ipairs(options) do
        if opt.tab == tabFilter then
            local y = yOff
            -- Background row
            local rowBG = newDrawing("Square", {
                Size = Vector2.new(480, 30),
                Position = Vector2.new(55, y),
                Color = Color3.fromRGB(40,40,40),
                Visible = gui.open,
            })
            table.insert(optionDrawings, rowBG)
            -- Name
            local nameTxt = newDrawing("Text", {
                Text = opt.name,
                Size = 16,
                Position = Vector2.new(60, y+5),
                Color = Color3.fromRGB(255,255,255),
                Visible = gui.open,
            })
            table.insert(optionDrawings, nameTxt)
            -- Toggle
            if opt.type == "toggle" then
                local toggleBtn = newDrawing("Square", {
                    Size = Vector2.new(20, 20),
                    Position = Vector2.new(400, y+5),
                    Color = opt.value and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0),
                    Visible = gui.open,
                })
                table.insert(optionDrawings, toggleBtn)
                -- On click detection in loop
            elseif opt.type == "slider" then
                local sliderW = 150
                local sliderX = 350
                local fillPct = (opt.value - opt.min) / (opt.max - opt.min)
                local sliderBG = newDrawing("Square", {
                    Size = Vector2.new(sliderW, 6),
                    Position = Vector2.new(sliderX, y+12),
                    Color = Color3.fromRGB(100,100,100),
                    Visible = gui.open,
                })
                table.insert(optionDrawings, sliderBG)
                local sliderFill = newDrawing("Square", {
                    Size = Vector2.new(sliderW * fillPct, 6),
                    Position = Vector2.new(sliderX, y+12),
                    Color = Color3.fromRGB(255,150,0),
                    Visible = gui.open,
                })
                table.insert(optionDrawings, sliderFill)
                local valTxt = newDrawing("Text", {
                    Text = tostring(opt.value),
                    Size = 14,
                    Position = Vector2.new(sliderX + sliderW + 5, y+5),
                    Color = Color3.fromRGB(255,255,255),
                    Visible = gui.open,
                })
                table.insert(optionDrawings, valTxt)
            end
            yOff = yOff + 32
        end
    end
end

-- Initial options
addToggle("Combat", "Aimbot", true, function(v) options.aimbot = v end)
addSlider("Combat", "Aim Fov", 50, 500, 150, 1, function(v) options.fov = v end)
addSlider("Combat", "Smoothness", 1, 20, 5, 1, function(v) options.smooth = v end)
addToggle("Combat", "Silent Aim", false, function(v) options.silent = v end)
addToggle("Visuals", "ESP Box", true, function(v) options.esp = v end)
addToggle("Visuals", "ESP Names", true, function(v) options.espNames = v end)
addToggle("Visuals", "Health Bar", true, function(v) options.espHealth = v end)
addToggle("Movement", "Fly", false, function(v) options.fly = v end)
addSlider("Movement", "Fly Speed", 20, 200, 50, 5, function(v) options.flySpeed = v end)
addToggle("Misc", "Godmode", false, function(v) options.godmode = v end)
addToggle("Misc", "Auto-Farm", false, function(v) options.autofarm = v end)

-- Helper to get closest enemy to crosshair
local function closestEnemy()
    local closest = nil
    local minDist = options.fov or 150
    local camPos = Camera.CFrame.Position
    local mousePos = UIS:GetMouseLocation()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- Aimbot logic
RunService.RenderStepped:Connect(function(deltaTime)
    if options.aimbot and gui.open then
        local target = closestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local headPos = target.Character.Head.Position
            local camCF = Camera.CFrame
            local direction = (headPos - camCF.Position).Unit
            local smooth = options.smooth or 5
            local newLook = camCF.LookVector:Lerp(direction, deltaTime * smooth * 10)
            Camera.CFrame = CFrame.lookAt(camCF.Position, camCF.Position + newLook * 100)
        end
    end
end)

-- Silent Aim hook
local oldFireServer; oldFireServer = hookfunction(getconnections(AttackRemote.OnServerEvent)[1].Function, newcclosure(function(self, player, ...)
    if options.silent and player == Players.LocalPlayer then
        local target = closestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local headPos = target.Character.Head.Position
            local args = {...}
            -- Assume attack event sends a direction Vector3 or CFrame
            if typeof(args[1]) == "Vector3" then
                args[1] = (headPos - (player.Character.HumanoidRootPart.Position)).Unit * 1000 -- fake direction
            elseif typeof(args[1]) == "CFrame" then
                args[1] = CFrame.lookAt(player.Character.HumanoidRootPart.Position, headPos)
            end
            return oldFireServer(self, player, unpack(args))
        end
    end
    return oldFireServer(self, player, ...)
end))

-- ESP
RunService.RenderStepped:Connect(function()
    if not options.esp then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and humanoid then
                local pos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local rootPos = plr.Character.HumanoidRootPart.Position
                    local bottomPos = rootPos - Vector3.new(0,3,0)
                    local topPos = rootPos + Vector3.new(0,3,0)
                    local screenBottom = Camera:WorldToScreenPoint(bottomPos)
                    local screenTop = Camera:WorldToScreenPoint(topPos)
                    local height = math.abs(screenBottom.Y - screenTop.Y)
                    local width = height / 2
                    local x = pos.X - width/2
                    local y = screenTop.Y < screenBottom.Y and screenTop.Y or screenBottom.Y
                    if options.esp then
                        -- Box
                        Drawing.new("Square", {
                            Size = Vector2.new(width, height),
                            Position = Vector2.new(x, y),
                            Color = Color3.fromRGB(255,0,0),
                            Thickness = 2,
                            Visible = true,
                        }):Remove() -- for demo we'd cache these, but for brevity just draw each frame
                    end
                    if options.espNames then
                        Drawing.new("Text", {
                            Text = plr.Name,
                            Size = 14,
                            Position = Vector2.new(x, y - 20),
                            Color = Color3.fromRGB(255,255,255),
                            Center = true,
                            Visible = true,
                        }):Remove()
                    end
                    if options.espHealth then
                        local health = humanoid.Health / humanoid.MaxHealth
                        local barW = width
                        local barH = 4
                        Drawing.new("Square", {
                            Size = Vector2.new(barW, barH),
                            Position = Vector2.new(x, y - 10),
                            Color = Color3.fromRGB(0,255,0),
                            Visible = true,
                        }):Remove()
                        Drawing.new("Square", {
                            Size = Vector2.new(barW * health, barH),
                            Position = Vector2.new(x, y - 10),
                            Color = Color3.fromRGB(255,0,0),
                            Visible = true,
                        }):Remove()
                    end
                    -- Distance text
                    local dist = (Camera.CFrame.Position - rootPos).Magnitude
                    Drawing.new("Text", {
                        Text = string.format("%.0f studs", dist),
                        Size = 12,
                        Position = Vector2.new(x, y + height),
                        Color = Color3.fromRGB(255,255,255),
                        Center = true,
                        Visible = true,
                    }):Remove()
                end
            end
        end
    end
end)

-- AutoFarm
RunService.Heartbeat:Connect(function()
    if not (options.autofarm and gui.open) then return end
    local selfChar = Players.LocalPlayer.Character
    if not selfChar then return end
    local hum = selfChar:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local enemyHum = plr.Character.Humanoid
            if enemyHum.Health > 0 and (plr.Character.HumanoidRootPart.Position - selfChar.HumanoidRootPart.Position).Magnitude < 20 then
                -- Attack
                if AttackRemote then
                    AttackRemote:FireServer()
                end
                -- Dash away if close
                if (plr.Character.HumanoidRootPart.Position - selfChar.HumanoidRootPart.Position).Magnitude < 5 and DashRemote then
                    DashRemote:FireServer()
                end
                break
            end
        end
    end
end)

-- Godmode (client-side)
RunService.Heartbeat:Connect(function()
    if not (options.godmode and gui.open) then return end
    local char = Players.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = hum.MaxHealth -- force full health every tick
        end
    end
end)

-- Fly system
local flyConnection
local function setFly(active)
    if active then
        local char = Players.LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0,0,0)
        bv.MaxForce = Vector3.new(400000, 400000, 400000)
        bv.P = 900
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.CFrame = CFrame.new()
        bg.MaxTorque = Vector3.new(400000, 400000, 400000)
        bg.P = 900
        bg.Parent = hrp
        flyConnection = RunService.RenderStepped:Connect(function()
            if not options.fly then return end
            local speed = options.flySpeed or 50
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                dir = dir + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                dir = dir - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                dir = dir - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                dir = dir + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                dir = dir + Vector3.new(0,1,0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                dir = dir - Vector3.new(0,1,0)
            end
            bv.Velocity = dir * speed
            bg.CFrame = Camera.CFrame
        end)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        local char = Players.LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp:FindFirstChildOfClass("BodyVelocity"):Destroy()
                hrp:FindFirstChildOfClass("BodyGyro"):Destroy()
            end
        end
    end
end
options.flyCallback = function(val)
    setFly(val)
end

-- Teleport
local function teleportTo(targetPlayer)
    local selfChar = Players.LocalPlayer.Character
    local targetChar = targetPlayer.Character
    if not (selfChar and targetChar) then return end
    selfChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
end
local function tpCursor()
    local mouse = Players.LocalPlayer:GetMouse()
    local ray = Ray.new(Camera.CFrame.Position, (mouse.Hit.Position - Camera.CFrame.Position).Unit * 1000)
    local part, pos = workspace:FindPartOnRayWithIgnoreList(ray, {Players.LocalPlayer.Character})
    if pos then
        Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos) + Vector3.new(0,3,0)
    end
end

-- GUI Input Handling
local mouseDown = false
local dragging = false
local dragOffset = Vector2.zero
local draggingSlider = nil
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = true
        local mousePos = UIS:GetMouseLocation()
        -- Check tab buttons
        for _, btn in ipairs(tabButtons) do
            if mousePos.X >= btn.x and mousePos.X <= btn.x+100 and mousePos.Y >= 85 and mousePos.Y <= 110 then
                gui.currentTab = btn.name
                refreshOptions()
                return
            end
        end
        -- Check options toggles/sliders
        local yOff = 120
        for _, opt in ipairs(options) do
            if opt.tab == gui.currentTab then
                if opt.type == "toggle" and mousePos.X >= 400 and mousePos.X <= 420 and mousePos.Y >= yOff+5 and mousePos.Y <= yOff+25 then
                    opt.value = not opt.value
                    if opt.callback then opt.callback(opt.value) end
                    refreshOptions()
                    return
                elseif opt.type == "slider" then
                    local sliderX = 350
                    local sliderW = 150
                    if mousePos.Y >= yOff+12-10 and mousePos.Y <= yOff+12+10 then
                        draggingSlider = opt
                        local frac = math.clamp((mousePos.X - sliderX) / sliderW, 0, 1)
                        opt.value = math.floor(opt.min + (opt.max-opt.min)*frac)
                        if opt.callback then opt.callback(opt.value) end
                        refreshOptions()
                    end
                end
                yOff = yOff + 32
            end
        end
        -- Menu drag
        if mousePos.X >= menuBG.Position.X and mousePos.X <= menuBG.Position.X+menuBG.Size.X and mousePos.Y >= menuBG.Position.Y and mousePos.Y <= menuBG.Position.Y+30 then
            dragging = true
            dragOffset = menuBG.Position - mousePos
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        -- Right click for teleport to cursor
        if options.tpCursor then
            tpCursor()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = false
        dragging = false
        draggingSlider = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragging then
            local mousePos = UIS:GetMouseLocation()
            menuBG.Position = mousePos + dragOffset
            menuTitle.Position = menuBG.Position + Vector2.new(10,5)
            for _, btn in ipairs(tabButtons) do
                btn.btn.Position = Vector2.new(btn.x, btn.btn.Position.Y)
                btn.txt.Position = btn.btn.Position + Vector2.new(10,3)
            end
        elseif draggingSlider then
            local mousePos = UIS:GetMouseLocation()
            local sliderX = 350
            local sliderW = 150
            local frac = math.clamp((mousePos.X - sliderX) / sliderW, 0, 1)
            draggingSlider.value = math.floor(draggingSlider.min + (draggingSlider.max - draggingSlider.min) * frac)
            if draggingSlider.callback then draggingSlider.callback(draggingSlider.value) end
            refreshOptions()
        end
    end
end)

-- Toggle menu with Insert key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        gui.open = not gui.open
        menuBG.Visible = gui.open
        menuTitle.Visible = gui.open
        for _, btn in ipairs(tabButtons) do
            btn.btn.Visible = gui.open
            btn.txt.Visible = gui.open
        end
        refreshOptions()
    end
end)

-- Save/Load config
local configPath = "rivals_config.json"
local function saveConfig()
    local cfg = {}
    for _, opt in ipairs(options) do
        cfg[opt.name] = opt.value
    end
    writefile(configPath, HttpService:JSONEncode(cfg))
end
local function loadConfig()
    pcall(function()
        local json = readfile(configPath)
        local cfg = HttpService:JSONDecode(json)
        for _, opt in ipairs(options) do
            if cfg[opt.name] ~= nil then
                opt.value = cfg[opt.name]
                if opt.callback then opt.callback(opt.value) end
            end
        end
        refreshOptions()
    end)
end
loadConfig()

-- Cleanup on script end
local function cleanup()
    for _, d in ipairs(drawings) do
        pcall(function() d:Remove() end)
    end
    for _, d in ipairs(optionDrawings) do
        pcall(function() d:Remove() end)
    end
    if flyConnection then
        flyConnection:Disconnect()
        setFly(false)
    end
    saveConfig()
end
script:GetPropertyChangedSignal("Parent"):Connect(function()
    if not script.Parent then
        cleanup()
    end
end)

-- Initial refresh
refreshOptions()
setFly(options.fly)
