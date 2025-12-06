--========================================
-- Rayfield UI 読み込み
--========================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "AIMBOT",
    LoadingTitle = "tp hub+",
    LoadingSubtitle = "Made by @tp",
    ConfigurationSaving = { Enabled = false }
})

-- タブ作成
local AIMTab = Window:CreateTab("AIMBOT")
local ESPTab = Window:CreateTab("ESP")
local TPTab = Window:CreateTab("テレポート")
local GunTab = Window:CreateTab("武器強化")
local InfJumpTab = Window:CreateTab("無限ジャンプ") -- 新規タブ

--========================================
-- 変数
--========================================
local player = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local mouse = player:GetMouse()
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

local AimbotEnabled = false
local WallCheck = false
local FOV = 100
local FOVFixed = false
local AimPart = "Head"
local Smoothness = 0.3

local ESPEnabled = false
local ESP3DEnabled = false

local infJumpEnabled = false

local ESPLabels = {}
local Lines = {}

--========================================
-- レインボーカラー
--========================================
local function rainbowColor()
    return Color3.fromHSV((tick() % 5) / 5, 1, 1)
end

--========================================
-- FOV円
--========================================
local Circle = Drawing.new("Circle")
Circle.Thickness = 2
Circle.NumSides = 100
Circle.Visible = false
Circle.Filled = false
Circle.Radius = FOV

--========================================
-- AIMBOT GUI
--========================================
AIMTab:CreateToggle({Name = "AIMBOT", CurrentValue = false, Callback = function(v) AimbotEnabled = v; Circle.Visible = v end})
AIMTab:CreateToggle({Name = "壁越しエイムしない（WallCheck）", CurrentValue = false, Callback = function(v) WallCheck = v end})
AIMTab:CreateSlider({Name = "FOVサイズ", Range = {50, 500}, Increment = 5, CurrentValue = 100, Callback = function(v) FOV = v; Circle.Radius = v end})
AIMTab:CreateToggle({Name = "FOV固定", CurrentValue = false, Callback = function(v) FOVFixed = v end})
AIMTab:CreateSlider({Name = "エイムスムーズ", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.3, Callback = function(v) Smoothness = v end})

--========================================
-- ESP GUI
--========================================
ESPTab:CreateToggle({Name = "ESP (警察のみ / 青ハイライト + 名前)", CurrentValue = false, Callback = function(v) ESPEnabled = v end})
ESPTab:CreateToggle({Name = "3D ESP (警察 / 虹色アウトライン)", CurrentValue = false, Callback = function(v) ESP3DEnabled = v end})

--========================================
-- テレポート GUI
--========================================
local function TPButton(name, pos)
    TPTab:CreateButton({
        Name = name,
        Callback = function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z) end
        end
    })
end

TPButton("AK47 にテレポート", Vector3.new(-936.25, 97, 2034.75))
TPButton("警察の事務所にテレポート", Vector3.new(813.64, 99.98, 2222.8))
TPButton("犯罪者のところにテレポート", Vector3.new(-974.03, 108.32, 2059.43))
TPButton("なんかの塔にテレポート", Vector3.new(821.95, 125.84, 2586.53))

--========================================
-- 壁越しチェック
--========================================
local function canSee(targetPart)
    if not WallCheck then return true end
    local origin = cam.CFrame.Position
    local direction = (targetPart.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, rayParams)
    if result then
        return (result.Instance:IsDescendantOf(targetPart.Parent))
    end
    return false
end

--========================================
-- 3D ESP
--========================================
local function createHighlight(char)
    if not char:FindFirstChild("Highlight") then
        local h = Instance.new("Highlight")
        h.Name = "Highlight"
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.Parent = char
    end
end

local function removeHighlight(char)
    if char:FindFirstChild("Highlight") then
        char.Highlight:Destroy()
    end
end

--========================================
-- 2D ESPラベル作成
--========================================
local function getESPLabel(plr)
    if not ESPLabels[plr] then
        local label = Drawing.new("Text")
        label.Size = 16
        label.Color = Color3.fromRGB(0, 170, 255)
        label.Outline = true
        label.OutlineColor = Color3.fromRGB(0,0,0)
        label.Visible = true
        ESPLabels[plr] = label
    end
    return ESPLabels[plr]
end

--========================================
-- 🔫 AK-47 無限弾 + リロード無効
--========================================
local function MakeAKInfinite(tool)
    if not tool then return end
    local ammoObj = tool:FindFirstChild("Ammo") 
                    or (tool:FindFirstChild("Configuration") and tool.Configuration:FindFirstChild("Ammo"))
                    or (tool:FindFirstChild("GunSettings") and tool.GunSettings:FindFirstChild("Ammo"))
    if not ammoObj then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("IntValue") and v.Name:lower():find("ammo") then
                ammoObj = v
                break
            end
        end
    end
    if ammoObj then
        task.spawn(function()
            while tool.Parent == player.Backpack or tool.Parent == player.Character do
                ammoObj.Value = 999999
                if tool:FindFirstChild("Reloading") then
                    tool.Reloading.Value = false
                end
                task.wait(0.1)
            end
        end)
    end
end

local function CheckAK()
    local bp = player:WaitForChild("Backpack")
    local char = player.Character or player.CharacterAdded:Wait()
    local function check(tool)
        if tool.Name == "AK-47" then
            MakeAKInfinite(tool)
        end
    end
    bp.ChildAdded:Connect(check)
    char.ChildAdded:Connect(check)
    for _, t in ipairs(bp:GetChildren()) do check(t) end
    for _, t in ipairs(char:GetChildren()) do check(t) end
end

CheckAK()

GunTab:CreateButton({
    Name = "AK-47 無限弾 + リロード無効",
    Callback = function()
        CheckAK()
        Rayfield:Notify({
            Title = "武器強化",
            Content = "AK-47 が無限弾 & リロード無効になりました！",
            Duration = 3
        })
    end
})

--========================================
-- 無限ジャンプタブ
--========================================
InfJumpTab:CreateToggle({
    Name = "無限ジャンプ GUI表示",
    CurrentValue = false,
    Callback = function(v)
        if v then
            -- GUI作成
            if not player.PlayerGui:FindFirstChild("InfJumpGUI") then
                local screenGui = Instance.new("ScreenGui")
                screenGui.Name = "InfJumpGUI"
                screenGui.ResetOnSpawn = false
                screenGui.Parent = player:WaitForChild("PlayerGui")

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 280, 0, 120)
                frame.Position = UDim2.new(0.5, -140, 0, 30)
                frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                frame.BackgroundTransparency = 0.1
                frame.BorderSizePixel = 0
                frame.Active = true
                frame.Draggable = true
                frame.Parent = screenGui

                local frameCorner = Instance.new("UICorner")
                frameCorner.CornerRadius = UDim.new(0, 15)
                frameCorner.Parent = frame

                local border = Instance.new("UIStroke")
                border.Parent = frame
                border.Thickness = 4
                border.LineJoinMode = Enum.LineJoinMode.Round
                border.Color = Color3.fromHSV(0,1,1)

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 35)
                title.BackgroundTransparency = 1
                title.Text = "🚀 無限ジャンプ"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.Font = Enum.Font.GothamBold
                title.TextSize = 18
                title.Parent = frame

                local infJumpBtn = Instance.new("TextButton")
                infJumpBtn.Size = UDim2.new(0.9, 0, 0, 50)
                infJumpBtn.Position = UDim2.new(0.05, 0, 0, 50)
                infJumpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                infJumpBtn.Text = "無限ジャンプ: オフ"
                infJumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                infJumpBtn.Font = Enum.Font.GothamBold
                infJumpBtn.TextSize = 16
                infJumpBtn.Parent = frame

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 12)
                btnCorner.Parent = infJumpBtn

                -- ボタン押したらオンオフ切替
                infJumpBtn.MouseButton1Click:Connect(function()
                    infJumpEnabled = not infJumpEnabled
                    if infJumpEnabled then
                        infJumpBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 100)
                        infJumpBtn.Text = "無限ジャンプ: オン ✓"
                    else
                        infJumpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        infJumpBtn.Text = "無限ジャンプ: オフ"
                    end
                end)

                -- レインボーアニメーション
                local RunService = game:GetService("RunService")
                local hue = 0
                RunService.Heartbeat:Connect(function(deltaTime)
                    hue = (hue + deltaTime * 0.2) % 1
                    border.Color = Color3.fromHSV(hue, 1, 1)
                end)
            end
        else
            local gui = player.PlayerGui:FindFirstChild("InfJumpGUI")
            if gui then gui:Destroy() end
            infJumpEnabled = false
        end
    end
})

--========================================
-- メインループ
--========================================
game:GetService("RunService").RenderStepped:Connect(function()
    -- FOV虹色
    if AimbotEnabled then
        Circle.Color = rainbowColor()
        Circle.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 3D ESP
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Team and plr.Team.Name == "Guards" then
            if ESP3DEnabled then
                if plr.Character then
                    createHighlight(plr.Character)
                    plr.Character.Highlight.OutlineColor = rainbowColor()
                end
            else
                if plr.Character then removeHighlight(plr.Character) end
            end
        end
    end

    -- 2D ESP + ライン
    if ESPEnabled then
        local screenBottomCenter = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y - 10)
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or plr.Team.Name ~= "Guards" then
                if ESPLabels[plr] then ESPLabels[plr]:Remove(); ESPLabels[plr]=nil end
                if Lines[plr] then Lines[plr]:Remove(); Lines[plr]=nil end
                continue
            end
            local humanoid = plr.Character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                if ESPLabels[plr] then ESPLabels[plr].Visible = false end
                if Lines[plr] then Lines[plr].Visible = false end
                continue
            end
            local part = plr.Character.HumanoidRootPart
            if not canSee(part) then
                if ESPLabels[plr] then ESPLabels[plr].Visible = false end
                if Lines[plr] then Lines[plr].Visible = false end
                continue
            end
            local pos, visible = cam:WorldToViewportPoint(part.Position)
            local label = getESPLabel(plr)
            if visible then
                label.Position = Vector2.new(pos.X, pos.Y)
                label.Text = plr.Name
                label.Visible = true
            else
                label.Visible = false
            end
            if not Lines[plr] then
                Lines[plr] = Drawing.new("Line")
                Lines[plr].Thickness = 2
                Lines[plr].Visible = true
            end
            local line = Lines[plr]
            line.From = screenBottomCenter
            line.To = Vector2.new(pos.X, pos.Y)
            line.Color = rainbowColor()
            line.Visible = visible
        end
    end

    -- AIMBOT
    if AimbotEnabled then
        local nearest, shortest = nil, FOV
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr ~= player and plr.Team and plr.Team.Name == "Guards" then
                if plr.Character and plr.Character:FindFirstChild(AimPart) then
                    local humanoid = plr.Character:FindFirstChild("Humanoid")
                    if not humanoid or humanoid.Health <= 0 then continue end
                    local part = plr.Character[AimPart]
                    if not canSee(part) then continue end
                    local pos, visible = cam:WorldToViewportPoint(part.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                        if dist < shortest then
                            nearest = part
                            shortest = dist
                        end
                    end
                end
            end
        end
        if nearest then
            local dir = (nearest.Position - cam.CFrame.Position).Unit
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, cam.CFrame.Position + dir), Smoothness)
        end
    end
end)

--========================================
-- 無限ジャンプ処理
--========================================
game:GetService("UserInputService").JumpRequest:Connect(function()
    if infJumpEnabled and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- キャラクターリスポーン時
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    humanoid = char:WaitForChild("Humanoid")
end)
