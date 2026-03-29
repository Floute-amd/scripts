local player = game.Players.LocalPlayer
local ballService = game:GetService("ReplicatedStorage").Packages.Knit.Services.BallService

-- GUI aman (anti detect)
local hui = gethui and gethui() or game:GetService("CoreGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoGKGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = hui

-- Sounds
local hoverSound = Instance.new("Sound", screenGui)
hoverSound.SoundId = "rbxassetid://10066931761"
hoverSound.Volume = 1

local clickSound = Instance.new("Sound", screenGui)
clickSound.SoundId = "rbxassetid://10066968815"
clickSound.Volume = 1

local getBallSound = Instance.new("Sound")
getBallSound.SoundId = "rbxassetid://9085319375"
getBallSound.Volume = 1
getBallSound.Parent = screenGui

-- DRAG FRAME
local dragFrame = Instance.new("Frame")
dragFrame.Size = UDim2.new(0, 220, 0, 80)
dragFrame.Position = UDim2.new(0.02, 0, 0.5, 0)
dragFrame.BackgroundTransparency = 1
dragFrame.Active = true
dragFrame.Draggable = true
dragFrame.Parent = screenGui

-- Image Button
local imageBtn = Instance.new("ImageButton")
imageBtn.Size = UDim2.new(0, 200, 0, 60)
imageBtn.Position = UDim2.new(0, 10, 0, 10)
imageBtn.BackgroundTransparency = 1
imageBtn.Image = "rbxassetid://94420981449604"
imageBtn.ScaleType = Enum.ScaleType.Stretch
imageBtn.Parent = dragFrame

-- Hover & Click sound handler
imageBtn.MouseEnter:Connect(function()
	hoverSound:Play()
end)
imageBtn.MouseButton1Click:Connect(function()
	clickSound:Play()
end)

-- Label
local label = Instance.new("TextLabel", imageBtn)
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "Auto GK: ON"
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0.3
label.TextScaled = false
label.TextSize = 30 -- ubah angkanya sesuai ukuran yang kamu mau
label.ZIndex = 2

-- States
local autoGK = true
local predictionParts = {}
local predictionDuration = 1.5
local predictionStep = 0.1

-- Character references
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart, humanoid

local function setupCharacter(char)
	character = char
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
end

setupCharacter(character)
player.CharacterAdded:Connect(setupCharacter)

-- Clear prediction parts
local function clearVisuals()
	for _, part in ipairs(predictionParts) do
		if part and part.Parent then part:Destroy() end
	end
	predictionParts = {}
end

-- Create point prediction
local function createPoint(pos, color)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1.5, 1.5, 1.5)
	part.Position = pos
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.3
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Parent = workspace
	table.insert(predictionParts, part)
end

-- Predict ball
local function predict(ball)
	if not autoGK then return end
	clearVisuals()
	local pos = ball.Position
	local vel = ball.Velocity
	local gravity = Vector3.new(0, workspace.Gravity, 0)

	for t = 0, predictionDuration, predictionStep do
		local p = pos + vel * t + 0.5 * -gravity * (t ^ 2)
		if p.Y >= 1 then
			createPoint(p, Color3.fromRGB(0, 255, 255))
		end
	end
end

-- Teleport function
local function teleportTo(pos)
	if not humanoidRootPart or not humanoid then return end
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoidRootPart.CFrame = CFrame.new(pos)
	ballService.RE.Dive:FireServer()
end

-- Teleport langsung ke bola
local function teleportToBall(ball)
	if not humanoidRootPart or not humanoid then return end
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoidRootPart.CFrame = ball.CFrame
	ballService.RE.Dive:FireServer()

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://18694494525"
	humanoid:LoadAnimation(anim):Play()
end

-- Deteksi bola dikontrol
local function isBallControlled()
	local ball = workspace:FindFirstChild("Football")
	if ball and ball:FindFirstChild("Controller") then
		return ball.Controller.Value ~= nil
	end
	return false
end

-- Auto Dive
local function autoDive(ball)
	if not autoGK or not humanoidRootPart then return end

	local dist = (humanoidRootPart.Position - ball.Position).Magnitude
	if dist <= 10 then
		teleportToBall(ball)
		return
	end

	local nearest, minDist = nil, math.huge
	for _, part in pairs(predictionParts) do
		local d = (humanoidRootPart.Position - part.Position).Magnitude
		if d < minDist and d <= 30 and part.Position.Y >= 1 then
			minDist = d
			nearest = part
		end
	end

	if nearest then
		teleportTo(nearest.Position)
	end
end

-- Toggle tombol
imageBtn.MouseButton1Click:Connect(function()
	autoGK = not autoGK
	label.Text = "Auto GK: " .. (autoGK and "ON" or "OFF")
	if not autoGK then
		clearVisuals()
	end
end)

-- Deteksi HasBall karakter sendiri
local lastHasBall = false

task.spawn(function()
	while task.wait(0.1) do
		local charInWorkspace = workspace:FindFirstChild(player.Name)
		if charInWorkspace and charInWorkspace:FindFirstChild("Values") then
			local hasBall = charInWorkspace.Values:FindFirstChild("HasBall")
			if hasBall and hasBall.Value ~= lastHasBall then
				lastHasBall = hasBall.Value
				if lastHasBall == true then
					getBallSound:Play()
				end
			end
		end
	end
end)

-- Loop utama
task.spawn(function()
	while task.wait(0.1) do
		local ball = workspace:FindFirstChild("Football") and workspace.Football:FindFirstChild("Hitbox")
		if ball then
			if isBallControlled() then
				clearVisuals()
			else
				predict(ball)
				autoDive(ball)
			end
		end
	end
end)