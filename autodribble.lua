if not getgenv().AutoDribbleSettings then
    getgenv().AutoDribbleSettings = {
        Enabled = false,
        range = 22
    }
end

local S = getgenv().AutoDribbleSettings
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Character, HRP, Humanoid
local function LoadCharacter()
    Character = LP.Character or LP.CharacterAdded:Wait()
    HRP = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
end

LoadCharacter()
LP.CharacterAdded:Connect(function()
    task.wait(0.2)
    LoadCharacter()
end)

local DribbleRE = RS:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("BallService"):WaitForChild("RE"):WaitForChild("Dribble")

local Animations = require(
    RS:WaitForChild("Assets"):WaitForChild("Animations")
)
local AnimationCache = {} 

local function GetDribbleTrack(style)
    if not style then return nil end

    -- reuse
    if AnimationCache[style] and AnimationCache[style].Parent then
        return AnimationCache[style]
    end

    local animId = Animations.Dribbles[style]
    if not animId then return nil end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId

    local track = Humanoid:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action

    AnimationCache[style] = track
    return track
end

local function IsEnemy(player)
    return LP.Team and player.Team and LP.Team ~= player.Team
end

local function IsVulnerable(player)
    if not player.Character then return false end

    local values = player.Character:FindFirstChild("Values")
    local sliding = values and values:FindFirstChild("Sliding")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

    return (sliding and sliding.Value)
        or (humanoid and humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed == 0)
end

local function DoDribble(dist)
    if not S.Enabled then return end
    if not Character then return end

    local values = Character:FindFirstChild("Values")
    if not values or not values:FindFirstChild("HasBall") then return end
    if not values.HasBall.Value then return end

    DribbleRE:FireServer()

    local style =
        LP:FindFirstChild("PlayerStats")
        and LP.PlayerStats:FindFirstChild("Style")
        and LP.PlayerStats.Style.Value

    local track = GetDribbleTrack(style)
    if track then
        if track.IsPlaying then
            track:Stop()
        end
        track:Play()
        track:AdjustSpeed(math.clamp(1 + (10 - dist) / 10, 1, 2))
    end
    
    local ball = workspace:FindFirstChild("Football")
    if ball then
        ball.AssemblyLinearVelocity = Vector3.zero
        ball.CFrame = HRP.CFrame * CFrame.new(0, -2.5, 0)
    end
end

RunService.Heartbeat:Connect(function()
    if not S.Enabled or not HRP then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and IsEnemy(p) and IsVulnerable(p) then
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local dist = (r.Position - HRP.Position).Magnitude
                if dist <= S.range then
                    DoDribble(dist)
                    break
                end
            end
        end
    end
end)