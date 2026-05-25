--[[
    RIVALS LOADER SIMPLE — Pas de backend, pas de chiffrement
    L'utilisateur met sa clé → vérifiée contre keys.txt sur GitHub → cheat lancé
--]]

local URL_KEYS = "https://raw.githubusercontent.com/rayzersaphirz-lgtm/rivals-cdn/refs/heads/main/keys.txt"
local URL_CHEAT = "https://raw.githubusercontent.com/rayzersaphirz-lgtm/rivals-cdn/refs/heads/main/init.lua"

local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")

-- ========== GUI DE CLÉ (minimal) ==========
local bg = Drawing.new("Square")
bg.Size = Vector2.new(350, 200)
bg.Position = Vector2.new(Camera.ViewportSize.X/2 - 175, Camera.ViewportSize.Y/2 - 100)
bg.Color = Color3.fromRGB(20, 20, 20)
bg.Transparency = 0.9
bg.Visible = true

local title = Drawing.new("Text")
title.Text = "RIVALS — Clé de licence"
title.Size = 20
title.Position = bg.Position + Vector2.new(20, 15)
title.Color = Color3.fromRGB(255, 100, 100)
title.Visible = true

local status = Drawing.new("Text")
status.Text = ""
status.Size = 14
status.Position = bg.Position + Vector2.new(20, 100)
status.Color = Color3.fromRGB(255, 255, 255)
status.Visible = true

-- ========== TextBox invisible pour la saisie ==========
local sg = Instance.new("ScreenGui")
sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
sg.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 310, 0, 35)
frame.Position = UDim2.new(0, bg.Position.X + 20, 0, bg.Position.Y + 50)
frame.BackgroundTransparency = 1
frame.Parent = sg

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, 0, 1, 0)
textBox.BackgroundTransparency = 0.8
textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.PlaceholderText = "Entre ta clé..."
textBox.Font = Enum.Font.SourceSans
textBox.TextSize = 16
textBox.Text = ""
textBox.Parent = frame
textBox:CaptureFocus()

-- ========== VÉRIFICATION ==========
local function checkKey(key)
    status.Text = "Vérification..."
    status.Color = Color3.fromRGB(255, 200, 50)
    
    -- Télécharger la liste des clés
    local ok, keysFile = pcall(function()
        return game:HttpGet(URL_KEYS)
    end)
    
    if not ok then
        status.Text = "❌ Impossible de contacter le serveur"
        status.Color = Color3.fromRGB(255, 50, 50)
        return
    end
    
    -- Vérifier si la clé est dans la liste
    for line in keysFile:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$") -- trim
        if trimmed == key then
            -- ✅ VALIDE
            status.Text = "✅ Clé valide ! Chargement..."
            status.Color = Color3.fromRGB(50, 255, 50)
            
            -- Sauvegarder la clé pour les prochains lancements
            pcall(function()
                if writefile then writefile("rivals_key.txt", key) end
            end)
            
            task.wait(1)
            
            -- Cacher la GUI
            bg.Visible = false
            title.Visible = false
            status.Visible = false
            sg:Destroy()
            
            -- Télécharger et exécuter le cheat
            local cheatOk, cheatCode = pcall(function()
                return game:HttpGet(URL_CHEAT)
            end)
            
            if cheatOk then
                pcall(function() loadstring(cheatCode)() end)
            end
            return
        end
    end
    
    -- ❌ INVALIDE
    status.Text = "❌ Clé invalide. Vérifie et réessaie."
    status.Color = Color3.fromRGB(255, 50, 50)
    textBox.Text = ""
    textBox:CaptureFocus()
end

-- ========== QUAND L'UTILISATEUR APPUIE SUR ENTRÉE ==========
textBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and textBox.Text ~= "" then
        checkKey(textBox.Text)
    end
end)

-- ========== AUTO-LOGIN SI CLÉ SAUVEGARDÉE ==========
task.wait(0.5)
pcall(function()
    if readfile then
        local saved = readfile("rivals_key.txt")
        if saved and #saved > 3 then
            checkKey(saved:match("^%s*(.-)%s*$"))
        end
    end
end)
