--[[
    RIVALS ULTRA LOADER v3
    UI améliorée + debug intégré + correction du bug post-validation
--]]

local URL_KEYS = "https://raw.githubusercontent.com/rayzersaphirz-lgtm/rivals-cdn/refs/heads/main/keys.txt"
local URL_CHEAT = "https://raw.githubusercontent.com/rayzersaphirz-lgtm/rivals-cdn/refs/heads/main/init.lua"

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera

-- ==================== CONSOLE DE DEBUG ====================
local debugMessages = {}
local function debug(msg, color)
    color = color or Color3.fromRGB(180, 180, 180)
    table.insert(debugMessages, {
        text = "[" .. os.date("%H:%M:%S") .. "] " .. msg,
        color = color,
        time = tick()
    })
    -- Limiter à 50 messages
    if #debugMessages > 50 then
        table.remove(debugMessages, 1)
    end
    -- Aussi dans la console Roblox
    print("[RIVALS]", msg)
end

-- ==================== ÉLÉMENTS DRAWING ====================
local drawings = {}
local function newDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    table.insert(drawings, d)
    return d
end

local function removeAllDrawings()
    for _, d in ipairs(drawings) do
        pcall(function() d:Remove() end)
    end
    drawings = {}
end

-- ==================== ANIMATIONS FLUIDES ====================
local animations = {}
local function animate(property, from, to, duration, drawObj)
    animations[drawObj] = animations[drawObj] or {}
    animations[drawObj][property] = {
        from = from,
        to = to,
        start = tick(),
        duration = duration,
        obj = drawObj,
        prop = property
    }
end

RunService.RenderStepped:Connect(function()
    local now = tick()
    for obj, props in pairs(animations) do
        for prop, data in pairs(props) do
            local elapsed = now - data.start
            if elapsed >= data.duration then
                -- Animation finie
                pcall(function() obj[prop] = data.to end)
                props[prop] = nil
            else
                local t = elapsed / data.duration
                -- Ease out quad
                t = 1 - (1 - t) * (1 - t)
                local val
                if type(data.from) == "number" then
                    val = data.from + (data.to - data.from) * t
                elseif type(data.from) == "Vector2" then
                    val = Vector2.new(
                        data.from.X + (data.to.X - data.from.X) * t,
                        data.from.Y + (data.to.Y - data.from.Y) * t
                    )
                elseif type(data.from) == "Color3" then
                    val = data.from:Lerp(data.to, t)
                end
                pcall(function() obj[prop] = val end)
            end
        end
    end
end)

-- ==================== GUI PRINCIPALE ====================
local screenX = Camera.ViewportSize.X
local screenY = Camera.ViewportSize.Y
local centerX = screenX / 2
local centerY = screenY / 2

-- Dimensions
local W, H = 440, 320
local guiX, guiY = centerX - W/2, centerY - H/2

local gui = {}

-- Fond principal (ombre)
gui.shadow = newDrawing("Square", {
    Size = Vector2.new(W + 24, H + 24),
    Position = Vector2.new(guiX - 12, guiY - 12),
    Color = Color3.fromRGB(0, 0, 0),
    Transparency = 0.5,
    Visible = true,
    Filled = true,
})

-- Fond principal
gui.bg = newDrawing("Square", {
    Size = Vector2.new(W, H),
    Position = Vector2.new(guiX, guiY),
    Color = Color3.fromRGB(16, 16, 20),
    Transparency = 0.95,
    Visible = true,
    Filled = true,
})

-- Bordure dégradée simulée (haut)
gui.borderTop = newDrawing("Line", {
    From = Vector2.new(guiX, guiY),
    To = Vector2.new(guiX + W, guiY),
    Color = Color3.fromRGB(200, 60, 60),
    Thickness = 2,
    Visible = true,
})

-- Accent rouge en haut
gui.accent = newDrawing("Square", {
    Size = Vector2.new(W, 3),
    Position = Vector2.new(guiX, guiY),
    Color = Color3.fromRGB(220, 50, 50),
    Visible = true,
    Filled = true,
})

-- Logo / Titre
gui.logo = newDrawing("Text", {
    Text = "⚔ RIVALS ULTRA",
    Size = 28,
    Position = Vector2.new(guiX + 25, guiY + 20),
    Color = Color3.fromRGB(255, 255, 255),
    Font = 2,
    Visible = true,
})

-- Version
gui.version = newDrawing("Text", {
    Text = "v1.0.0",
    Size = 12,
    Position = Vector2.new(guiX + W - 60, guiY + 27),
    Color = Color3.fromRGB(120, 120, 120),
    Visible = true,
})

-- Séparateur
gui.separator = newDrawing("Line", {
    From = Vector2.new(guiX + 20, guiY + 55),
    To = Vector2.new(guiX + W - 20, guiY + 55),
    Color = Color3.fromRGB(60, 60, 60),
    Thickness = 1,
    Visible = true,
})

-- Label "Clé de licence"
gui.keyLabel = newDrawing("Text", {
    Text = "CLÉ DE LICENCE",
    Size = 11,
    Position = Vector2.new(guiX + 25, guiY + 75),
    Color = Color3.fromRGB(150, 150, 150),
    Font = 1,
    Visible = true,
})

-- Input background
gui.inputBg = newDrawing("Square", {
    Size = Vector2.new(W - 50, 45),
    Position = Vector2.new(guiX + 25, guiY + 95),
    Color = Color3.fromRGB(30, 30, 38),
    Transparency = 0.9,
    Visible = true,
    Filled = true,
})

-- Input border
gui.inputBorder = newDrawing("Square", {
    Size = Vector2.new(W - 48, 2),
    Position = Vector2.new(guiX + 26, guiY + 138),
    Color = Color3.fromRGB(200, 60, 60),
    Thickness = 1,
    Visible = true,
    Filled = true,
})

-- Input text (reflète ce que l'utilisateur tape)
gui.inputText = newDrawing("Text", {
    Text = "",
    Size = 18,
    Position = Vector2.new(guiX + 38, guiY + 104),
    Color = Color3.fromRGB(255, 255, 255),
    Visible = true,
})

-- Input placeholder
gui.inputPlaceholder = newDrawing("Text", {
    Text = "RIVALS-XXXX-XXXX-XXXX",
    Size = 16,
    Position = Vector2.new(guiX + 38, guiY + 106),
    Color = Color3.fromRGB(70, 70, 80),
    Visible = true,
})

-- Bouton Activer
gui.btnBg = newDrawing("Square", {
    Size = Vector2.new(W - 50, 48),
    Position = Vector2.new(guiX + 25, guiY + 160),
    Color = Color3.fromRGB(200, 50, 50),
    Thickness = 0,
    Visible = true,
    Filled = true,
})

gui.btnText = newDrawing("Text", {
    Text = "ACTIVER",
    Size = 18,
    Position = Vector2.new(guiX + W/2 - 45, guiY + 172),
    Color = Color3.fromRGB(255, 255, 255),
    Font = 2,
    Visible = true,
})

-- Message de statut
gui.statusText = newDrawing("Text", {
    Text = "",
    Size = 14,
    Position = Vector2.new(guiX + 25, guiY + 225),
    Color = Color3.fromRGB(255, 255, 255),
    Visible = true,
})

-- Console debug (en bas, 4 dernières lignes visibles)
gui.debugTitle = newDrawing("Text", {
    Text = "CONSOLE",
    Size = 10,
    Position = Vector2.new(guiX + 25, guiY + 255),
    Color = Color3.fromRGB(100, 100, 100),
    Font = 1,
    Visible = true,
})

local debugLines = {}
for i = 1, 4 do
    debugLines[i] = newDrawing("Text", {
        Text = "",
        Size = 10,
        Position = Vector2.new(guiX + 25, guiY + 268 + (i-1)*14),
        Color = Color3.fromRGB(130, 130, 130),
        Font = 2, -- monospace si dispo, sinon normal
        Visible = true,
    })
end

-- Icône de chargement
gui.spinnerText = "\226\128\162" -- • en UTF-8 (fallback simple)
gui.spinner = newDrawing("Text", {
    Text = "",
    Size = 20,
    Position = Vector2.new(guiX + W/2 - 10, guiY + 220),
    Color = Color3.fromRGB(200, 60, 60),
    Visible = false,
})

-- ==================== MISE À JOUR CONSOLE ====================
local function updateDebugConsole()
    local start = math.max(1, #debugMessages - 3)
    for i = 1, 4 do
        local idx = start + i - 1
        if idx <= #debugMessages then
            local msg = debugMessages[idx]
            -- Faire apparaître en fondu selon l'âge
            local age = tick() - msg.time
            local alpha = math.clamp(1 - age / 10, 0.2, 1)
            debugLines[i].Text = msg.text:sub(1, 55)
            debugLines[i].Color = msg.color
            debugLines[i].Transparency = 1 - alpha
        else
            debugLines[i].Text = ""
        end
    end
end

RunService.RenderStepped:Connect(updateDebugConsole)

-- ==================== TEXTBOX INVISIBLE POUR SAISIE ====================
local sg = Instance.new("ScreenGui")
sg.Name = "RivalsInputGUI"
sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, W - 50, 0, 45)
frame.Position = UDim2.new(0, guiX + 25, 0, guiY + 95)
frame.BackgroundTransparency = 1
frame.Parent = sg

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, 0, 1, 0)
textBox.BackgroundTransparency = 1
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.PlaceholderText = ""
textBox.Font = Enum.Font.SourceSans
textBox.TextSize = 18
textBox.Text = ""
textBox.ClearTextOnFocus = false
textBox.Parent = frame

-- Mettre à jour le texte affiché dans le Drawing
textBox.Changed:Connect(function(prop)
    if prop == "Text" then
        gui.inputText.Text = textBox.Text
        gui.inputPlaceholder.Visible = (#textBox.Text == 0)
        -- Censure partielle pour le style (affiche les 4 derniers caractères en clair)
    end
end)

-- Focus auto
task.wait(0.3)
textBox:CaptureFocus()

-- ==================== BARRE DE PROGRÈS (chargement) ====================
gui.progressBg = newDrawing("Square", {
    Size = Vector2.new(W - 50, 6),
    Position = Vector2.new(guiX + 25, guiY + 288),
    Color = Color3.fromRGB(40, 40, 50),
    Visible = false,
    Filled = true,
})

gui.progressFill = newDrawing("Square", {
    Size = Vector2.new(0, 6),
    Position = Vector2.new(guiX + 25, guiY + 288),
    Color = Color3.fromRGB(200, 60, 60),
    Visible = false,
    Filled = true,
})

local function setProgress(pct) -- 0 à 1
    gui.progressFill.Size = Vector2.new((W - 50) * pct, 6)
    gui.progressFill.Visible = true
    gui.progressBg.Visible = true
end

local function hideProgress()
    gui.progressFill.Visible = false
    gui.progressBg.Visible = false
end

-- ==================== VÉRIFICATION DE CLÉ ====================
local isVerifying = false

local function resetUI()
    gui.btnText.Text = "ACTIVER"
    gui.btnBg.Color = Color3.fromRGB(200, 50, 50)
    gui.statusText.Text = ""
    gui.inputBorder.Color = Color3.fromRGB(200, 60, 60)
    hideProgress()
    isVerifying = false
    textBox.Text = ""
    textBox:CaptureFocus()
end

local function showError(msg)
    gui.statusText.Text = "❌ " .. msg
    gui.statusText.Color = Color3.fromRGB(255, 70, 70)
    gui.btnText.Text = "RÉESSAYER"
    gui.btnBg.Color = Color3.fromRGB(180, 50, 50)
    gui.inputBorder.Color = Color3.fromRGB(255, 50, 50)
    isVerifying = false
    task.wait(0.1)
    textBox:CaptureFocus()
end

local function showSuccess(msg)
    gui.statusText.Text = "✅ " .. msg
    gui.statusText.Color = Color3.fromRGB(50, 255, 100)
    gui.btnText.Text = "✓ OK"
    gui.btnBg.Color = Color3.fromRGB(30, 140, 40)
    gui.inputBorder.Color = Color3.fromRGB(50, 220, 80)
end

local function showLoading(msg)
    gui.statusText.Text = "⏳ " .. msg
    gui.statusText.Color = Color3.fromRGB(255, 200, 50)
    gui.btnText.Text = "•••"
    gui.btnBg.Color = Color3.fromRGB(140, 100, 30)
end

-- ==================== FONCTION PRINCIPALE ====================
local function checkKey(enteredKey)
    if isVerifying then return end
    if #enteredKey < 5 then
        showError("Clé trop courte (min. 5 caractères)")
        return
    end
    
    isVerifying = true
    debug("Début vérification pour : " .. enteredKey:sub(1, 8) .. "***")
    showLoading("Téléchargement de la liste des clés...")
    setProgress(0.2)
    
    -- Télécharger keys.txt
    local ok, keysContent = pcall(function()
        return game:HttpGet(URL_KEYS)
    end)
    
    if not ok then
        debug("ERREUR: Impossible de contacter GitHub", Color3.fromRGB(255, 80, 80))
        showError("Impossible de contacter le serveur (GitHub down ?)")
        hideProgress()
        return
    end
    
    debug("Liste des clés téléchargée (" .. #keysContent .. " octets)")
    setProgress(0.5)
    showLoading("Vérification de la clé...")
    
    -- Chercher la clé ligne par ligne
    local found = false
    for line in keysContent:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed == enteredKey then
            found = true
            break
        end
    end
    
    if not found then
        debug("Clé invalide: " .. enteredKey:sub(1, 8) .. "***", Color3.fromRGB(255, 100, 100))
        showError("Clé invalide ou révoquée")
        hideProgress()
        return
    end
    
    -- ✅ CLÉ VALIDE
    debug("✅ Clé valide !", Color3.fromRGB(50, 255, 100))
    showSuccess("Clé valide !")
    setProgress(0.7)
    
    -- Sauvegarder localement
    pcall(function()
        if writefile then
            writefile("rivals_key_saved.txt", enteredKey)
            debug("Clé sauvegardée localement")
        end
    end)
    
    task.wait(0.8)
    
    -- Télécharger le cheat
    showLoading("Téléchargement du cheat...")
    setProgress(0.8)
    debug("Téléchargement de " .. URL_CHEAT)
    
    local cheatOk, cheatCode = pcall(function()
        return game:HttpGet(URL_CHEAT)
    end)
    
    if not cheatOk then
        debug("ERREUR téléchargement cheat: " .. tostring(cheatCode), Color3.fromRGB(255, 80, 80))
        showError("Impossible de télécharger le cheat")
        hideProgress()
        isVerifying = false
        return
    end
    
    debug("Cheat téléchargé : " .. #cheatCode .. " caractères", Color3.fromRGB(100, 255, 100))
    setProgress(0.9)
    showLoading("Exécution...")
    
    -- Nettoyer la GUI AVANT d'exécuter le cheat
    -- (sinon le cheat peut interférer avec nos Drawings)
    task.wait(0.3)
    debug("Nettoyage du loader...")
    removeAllDrawings()
    sg:Destroy()
    
    -- Exécuter
    debug("Exécution du cheat...", Color3.fromRGB(255, 200, 50))
    setProgress(1.0)
    
    local execOk, execErr = pcall(function()
        loadstring(cheatCode)()
    end)
    
    if not execOk then
        -- Le cheat a planté, mais on a plus de GUI pour l'afficher
        -- On crée une notification rapide
        warn("[RIVALS] ERREUR D'EXÉCUTION : " .. tostring(execErr))
        local errNotif = Drawing.new("Text")
        errNotif.Text = "❌ ERREUR CHEAT: " .. tostring(execErr):sub(1, 80)
        errNotif.Size = 14
        errNotif.Position = Vector2.new(Camera.ViewportSize.X/2 - 200, Camera.ViewportSize.Y/2 + 50)
        errNotif.Color = Color3.fromRGB(255, 60, 60)
        errNotif.Visible = true
        errNotif.Font = 2
        task.wait(8)
        pcall(function() errNotif:Remove() end)
    else
        debug("✅ Cheat exécuté avec succès !", Color3.fromRGB(50, 255, 100))
    end
end

-- ==================== ÉVÉNEMENTS ====================
textBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and textBox.Text ~= "" then
        checkKey(textBox.Text)
    end
end)

-- Clic sur le bouton Activer
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UIS:GetMouseLocation()
        local bx, by = guiX + 25, guiY + 160
        local bw, bh = W - 50, 48
        if mousePos.X >= bx and mousePos.X <= bx + bw and mousePos.Y >= by and mousePos.Y <= by + bh then
            if textBox.Text ~= "" and not isVerifying then
                checkKey(textBox.Text)
            end
        end
    end
end)

-- ==================== AUTO-LOGIN ====================
task.wait(0.8)
pcall(function()
    if readfile then
        local saved = readfile("rivals_key_saved.txt")
        if saved and #saved > 3 then
            saved = saved:match("^%s*(.-)%s*$")
            debug("Clé sauvegardée trouvée, auto-vérification...")
            gui.inputText.Text = saved
            textBox.Text = saved
            gui.inputPlaceholder.Visible = false
            task.wait(0.3)
            checkKey(saved)
        end
    end
end)

debug("Loader prêt — en attente de la clé", Color3.fromRGB(100, 200, 255))
