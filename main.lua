-- ✅ Kavo UI for Wave - Final Script (Part 1)

-- Load Kavo UI with Midnight Theme
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("IshkebHub", "Midnight")

-- Tabs
local Combat = Window:NewTab("Combat")
local Movement = Window:NewTab("Movement")

-- Sections
local CombatSec = Combat:NewSection("Aimbot + ESP")
local MoveSec = Movement:NewSection("Movement")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Variables
local aimbotEnabled = false
local aimSmoothness = 0.25
local fovRadius = 150
local lockedTarget = nil
local espEnabled = false
local visuals = {}
local showCrosshair = true

-- Drawing
local Drawing = Drawing or getgenv().Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Visible = true

local crossLineH = Drawing.new("Line")
local crossLineV = Drawing.new("Line")
for _, l in ipairs({crossLineH, crossLineV}) do
    l.Thickness = 1
    l.Transparency = 1
    l.Color = Color3.fromRGB(255, 0, 0)
end

-- Combat UI Controls
CombatSec:NewToggle("Crosshair", "Show center cross", function(v)
    showCrosshair = v
end)

CombatSec:NewToggle("Aimbot (Hold M2)", "Locks to closest player", function(v)
    aimbotEnabled = v
end)

CombatSec:NewSlider("Smoothness", "How fast to aim", 100, 5, function(v)
    aimSmoothness = v / 100
end)

CombatSec:NewSlider("FOV Radius", "Lock-on range", 500, 50, function(v)
    fovRadius = v
end)

CombatSec:NewToggle("ESP + Tracers", "Shows boxes, health, tracers", function(v)
    espEnabled = v
    if not v then
        for _, s in pairs(visuals) do
            s.box.Visible = false
            s.health.Visible = false
            s.tracer.Visible = false
        end
    end
end)

-- ESP Setup
local function setupVisuals(plr)
    if visuals[plr] then return end
    visuals[plr] = {
        box = Drawing.new("Square"),
        health = Drawing.new("Line"),
        tracer = Drawing.new("Line")
    }
    visuals[plr].box.Thickness = 2
    visuals[plr].box.Color = Color3.fromRGB(255, 0, 0)
    visuals[plr].box.Transparency = 1
    visuals[plr].box.Filled = false

    visuals[plr].health.Color = Color3.fromRGB(0, 255, 0)
    visuals[plr].health.Thickness = 3
    visuals[plr].health.Transparency = 1

    visuals[plr].tracer.Color = Color3.fromRGB(255, 255, 255)
    visuals[plr].tracer.Thickness = 1
    visuals[plr].tracer.Transparency = 1
end

local function removeVisuals(plr)
    if visuals[plr] then
        for _, v in pairs(visuals[plr]) do v:Remove() end
        visuals[plr] = nil
    end
end
Players.PlayerRemoving:Connect(removeVisuals)

-- Flight/Noclip Setup
local flying = false
local flySpeed = 50
local flyVelocity, flyGyro
local moveKeys = {W=false, A=false, S=false, D=false, Space=false, LeftShift=false}

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if moveKeys[i.KeyCode.Name] ~= nil then moveKeys[i.KeyCode.Name] = true end
end)

UserInputService.InputEnded:Connect(function(i)
    if moveKeys[i.KeyCode.Name] ~= nil then moveKeys[i.KeyCode.Name] = false end
end)

MoveSec:NewToggle("Flight (WASD)", "Fly freely", function(state)
    flying = state
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and state then
        flyVelocity = Instance.new("BodyVelocity", hrp)
        flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyVelocity.Velocity = Vector3.zero

        flyGyro = Instance.new("BodyGyro", hrp)
        flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyGyro.P = 9e4
        flyGyro.CFrame = hrp.CFrame
    else
        if flyVelocity then flyVelocity:Destroy() end
        if flyGyro then flyGyro:Destroy() end
    end
end)

MoveSec:NewSlider("Flight Speed", "Adjust movement speed", 200, 10, function(val)
    flySpeed = val
end)

local noclip = false
MoveSec:NewToggle("Noclip", "Walk through walls", function(state)
    noclip = state
end)
-- Final Render Loop
RunService.RenderStepped:Connect(function()
    local mouse = UserInputService:GetMouseLocation()

    -- Update Crosshair
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    crossLineH.From = center - Vector2.new(5, 0)
    crossLineH.To = center + Vector2.new(5, 0)
    crossLineV.From = center - Vector2.new(0, 5)
    crossLineV.To = center + Vector2.new(0, 5)
    crossLineH.Visible = showCrosshair
    crossLineV.Visible = showCrosshair

    -- Update FOV Circle
    fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
    fovCircle.Radius = fovRadius
    fovCircle.Visible = aimbotEnabled

    -- Apply Flight
    if flying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = Camera.CFrame
        local dir = Vector3.zero
        if moveKeys.W then dir += cam.LookVector end
        if moveKeys.S then dir -= cam.LookVector end
        if moveKeys.A then dir -= cam.RightVector end
        if moveKeys.D then dir += cam.RightVector end
        if moveKeys.Space then dir += Vector3.new(0, 1, 0) end
        if moveKeys.LeftShift then dir -= Vector3.new(0, 1, 0) end
        flyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        flyGyro.CFrame = cam
    end

    -- Apply Noclip
    if noclip and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end

    -- ESP
    if espEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("HumanoidRootPart") then
                setupVisuals(plr)
                local head = plr.Character.Head
                local root = plr.Character.HumanoidRootPart
                local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                local top, onTop = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.3, 0))
                local bottom, onBottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
                local center = Camera:WorldToViewportPoint(root.Position)

                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2
                local v = visuals[plr]

                if onTop and onBottom then
                    v.box.Size = Vector2.new(width, height)
                    v.box.Position = Vector2.new(top.X - width / 2, top.Y)
                    v.box.Visible = true

                    if humanoid and humanoid.Health > 0 then
                        local healthRatio = humanoid.Health / humanoid.MaxHealth
                        local barHeight = height * healthRatio
                        v.health.From = Vector2.new(top.X - width / 2 - 5, top.Y + height)
                        v.health.To = Vector2.new(top.X - width / 2 - 5, top.Y + height - barHeight)
                        v.health.Visible = true
                    else
                        v.health.Visible = false
                    end

                    v.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    v.tracer.To = Vector2.new(center.X, center.Y)
                    v.tracer.Visible = true
                else
                    v.box.Visible = false
                    v.health.Visible = false
                    v.tracer.Visible = false
                end
            elseif visuals[plr] then
                visuals[plr].box.Visible = false
                visuals[plr].health.Visible = false
                visuals[plr].tracer.Visible = false
            end
        end
    end

    -- Aimbot
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not lockedTarget or not lockedTarget.Character or not lockedTarget.Character:FindFirstChild("Head") then
            local closest, dist = nil, fovRadius
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                    local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if vis and d < dist then
                        closest = p
                        dist = d
                    end
                end
            end
            lockedTarget = closest
        end
        if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, lockedTarget.Character.Head.Position),
                aimSmoothness
            )
        end
    else
        lockedTarget = nil
    end
end)
