--====================================================
-- Prison Life TP HUB+  (Rayfield 完全統合版)
--====================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
Name = "Prison Life TP HUB+",
LoadingTitle = "Prison Life TP HUB+",
LoadingSubtitle = "Made by @tp",
ConfigurationSaving = { Enabled = false }
})

--====================================================
-- タブ作成
--====================================================

local AIMTab = Window:CreateTab("AIMBOT")
local ESPTab = Window:CreateTab("ESP")
local TPTab = Window:CreateTab("テレポート")
local GunTab = Window:CreateTab("武器強化")
local JumpTab = Window:CreateTab("無限ジャンプ")
local TaserTab = Window:CreateTab("テーザー耐性")

--====================================================
-- 基本変数
--====================================================

local player = game.Players.LocalPlayer
local cam = workspace.CurrentCamera

local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

local AimbotEnabled = false
local ESPEnabled = false
local ESP3DEnabled = false
local infJumpEnabled = false
local AntiTaserEnabled = false

local AimPart = "Head"
local FOV = 120
local Smoothness = 0.25
local WallCheck = true

local targetTeamName = "Guards" -- Prison Life の警察チーム名

--====================================================
-- レインボー関数
--====================================================

local function rainbow()
return Color3.fromHSV((tick() % 5) / 5, 1, 1)
end

--====================================================
-- FOV円
--====================================================

local Circle = Drawing.new("Circle")
Circle.Thickness = 2
Circle.NumSides = 100
Circle.Visible = false
Circle.Radius = FOV * (300/200) -- 修正：以前の比率に合わせる
Circle.Filled = false

--====================================================
-- AIMBOT GUI
--====================================================

AIMTab:CreateToggle({
Name = "AIMBOT",
CurrentValue = false,
Callback = function(v)
AimbotEnabled = v
Circle.Visible = v
end
})

AIMTab:CreateToggle({
Name = "壁越しエイムなし（WallCheck）",
CurrentValue = true,
Callback = function(v)
WallCheck = v
end
})

AIMTab:CreateSlider({
Name = "FOVサイズ",
Range = {50, 300},
Increment = 5,
CurrentValue = 120,
Callback = function(v)
FOV = v
Circle.Radius = v * (300/200) -- 修正
end
})

AIMTab:CreateSlider({
Name = "エイムスムーズ",
Range = {0.05, 1},
Increment = 0.05,
CurrentValue = 0.25,
Callback = function(v)
Smoothness = v
end
})

--====================================================
-- ESP GUI
--====================================================

ESPTab:CreateToggle({
Name = "ESP（警察だけ）",
CurrentValue = false,
Callback = function(v)
ESPEnabled = v
end
})

ESPTab:CreateToggle({
Name = "3D ESP（虹色アウトライン）",
CurrentValue = false,
Callback = function(v)
ESP3DEnabled = v
end
})

--====================================================
-- テレポート GUI
--====================================================

local function addTP(name, pos)
TPTab:CreateButton({
Name = name,
Callback = function()
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if hrp then
hrp.CFrame = CFrame.new(pos)
end
end
})
end

addTP("AK-47", Vector3.new(-936.25, 97, 2034.75))
addTP("警察の事務所", Vector3.new(813.64, 99.98, 2222.8))
addTP("犯罪者の場所", Vector3.new(-974.03, 108.32, 2059.43))
addTP("塔", Vector3.new(821.95, 125.84, 2586.53))

--====================================================
-- 無限ジャンプ
--====================================================

JumpTab:CreateToggle({
Name = "無限ジャンプ",
CurrentValue = false,
Callback = function(v)
infJumpEnabled = v
end
})

--====================================================
-- テーザー耐性
--====================================================

TaserTab:CreateToggle({
Name = "テーザー耐性（撃たれても転ばない）",
CurrentValue = false,
Callback = function(v)
AntiTaserEnabled = v
Rayfield:Notify({Title="テーザー耐性", Content=(v and "有効" or "無効"), Duration=2})
end
})

--====================================================
-- AK-47 無限弾
--====================================================

GunTab:CreateButton({
Name = "AK-47 無限弾",
Callback = function()
local function monitor(tool)
if tool.Name == "AK-47" then
task.spawn(function()
while tool.Parent == player.Backpack or tool.Parent == player.Character do
local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("GunSettings") and tool.GunSettings:FindFirstChild("Ammo")
if ammo then ammo.Value = 999999 end
task.wait(0.1)
end
end)
end
end

player.Backpack.ChildAdded:Connect(monitor)  
    if player.Character then  
        player.Character.ChildAdded:Connect(monitor)  
    end  

    Rayfield:Notify({Title="武器強化", Content="AK-47 無限弾が有効化", Duration=3})  
end

})

--====================================================
-- 判定系
--====================================================

local function canSee(part)
if not WallCheck then return true end
local origin = cam.CFrame.Position
local direction = (part.Position - origin)
local params = RaycastParams.new()
params.FilterDescendantsInstances = {player.Character}
params.FilterType = Enum.RaycastFilterType.Blacklist
local result = workspace:Raycast(origin, direction, params)
return not result or result.Instance:IsDescendantOf(part.Parent)
end

--====================================================
-- ESP 設定
--====================================================

local labels = {}

local function getLabel(plr)
if not labels[plr] then
local txt = Drawing.new("Text")
txt.Size = 16
txt.Outline = true
txt.Visible = false
txt.Color = Color3.fromRGB(0, 255, 255)
labels[plr] = txt
end
return labels[plr]
end

--====================================================
-- メインループ（AIMBOT / ESP / テーザー耐性）
--====================================================

game:GetService("RunService").RenderStepped:Connect(function()

--===== テーザー耐性（PlatformStand解除） =====--  
if AntiTaserEnabled then  
    humanoid.PlatformStand = false  
    humanoid.Sit = false  
end  

--===== FOV円 =====--  
if AimbotEnabled then  
    Circle.Color = rainbow()  
    Circle.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)  
    Circle.Radius = FOV * (300/200) -- 描画比率  
end  

--===== AIMBOT =====--  
if AimbotEnabled then  
    local nearest = nil  
    local shortest = FOV  

    for _, plr in ipairs(game.Players:GetPlayers()) do  
        if plr ~= player and plr.Team and plr.Team.Name == targetTeamName then  
            local c = plr.Character  
            if c and c:FindFirstChild(AimPart) and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then  
                local pos, visible = cam:WorldToViewportPoint(c[AimPart].Position)  
                if visible then  
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude  
                    if dist < shortest and canSee(c[AimPart]) then  
                        shortest = dist  
                        nearest = c[AimPart]  
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

--===== ESP =====--  
for _, plr in ipairs(game.Players:GetPlayers()) do  
    if plr.Team and plr.Team.Name == targetTeamName and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then  
        local hrp = plr.Character.HumanoidRootPart  
        local headPos, visible = cam:WorldToViewportPoint(hrp.Position)  

        local label = getLabel(plr)  

        if ESPEnabled then  
            if visible then  
                label.Visible = true  
                label.Position = Vector2.new(headPos.X, headPos.Y)  
                label.Text = plr.Name  
                label.Color = Color3.fromRGB(0, 200, 255)  
            else  
                label.Visible = false  
            end  
        else  
            label.Visible = false  
        end  

        -- 3D ESP ハイライト  
        if ESP3DEnabled then  
            if not plr.Character:FindFirstChild("Highlight") then  
                local h = Instance.new("Highlight", plr.Character)  
                h.FillTransparency = 1  
                h.OutlineTransparency = 0  
            end  
            plr.Character.Highlight.OutlineColor = rainbow()  
        else  
            if plr.Character:FindFirstChild("Highlight") then  
                plr.Character.Highlight:Destroy()  
            end  
        end  
    end  
end

end)

--====================================================
-- 無限ジャンプ
--====================================================

game:GetService("UserInputService").JumpRequest:Connect(function()
if infJumpEnabled then
humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end
end)

--====================================================
-- リスポーン対応
--====================================================

player.CharacterAdded:Connect(function(new)
char = new
humanoid = new:WaitForChild("Humanoid")
end)
