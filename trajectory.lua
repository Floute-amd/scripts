--====================================================
-- FOOTBALL TRAJECTORY PREDICTION
-- ROUND MULTI-BEAM â€¢ ANTI LAG â€¢ NO TRACE WHEN OFF
--====================================================

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--================ CONFIG =================
local BALL_NAME = "Football"

-- Simulation
local SIM_STEP = 1/90
local MAX_STEPS = 260   -- TURUNIN (ANTI LAG)

-- Physics
local AIR_DRAG = 0.014
local FRICTION = 0.997
local BOUNCE_DAMPING = 0.78
local MAGNUS_STRENGTH = 0.065
local MIN_VELOCITY = 0.4

-- Visual
local SAMPLE_DISTANCE = 1.4   -- LEBIH JARANG (ANTI LAG)
local BEAM_WIDTH = 1.0
local BEAM_SEGMENTS = 20      -- TURUNIN
local MULTI_BEAM_OFFSET = 0.3
local MAX_SEGMENTS = 90       -- LIMIT HARD

--=========================================

local ball = Workspace:WaitForChild(BALL_NAME)
local gravity = Vector3.new(0, -Workspace.Gravity, 0)

-- Folder
local folder = Workspace:FindFirstChild("FootballPrediction")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "FootballPrediction"
folder.Parent = Workspace

-- Raycast
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances = {folder}

--================ UTILS ==================

local function hsv(h)
	return Color3.fromHSV(h % 1, 0.7, 1) -- soft color
end

local function reflect(v, n)
	return v - 2 * v:Dot(n) * n
end

local function validHit(r)
	return r and r.Instance and r.Instance.CanCollide and r.Instance.Transparency < 0.95
end

--================ CLEANER =================
local function clearTrajectory()
	for _, v in ipairs(folder:GetChildren()) do
		if v:IsA("Beam") then
			v.Enabled = false
		elseif v:IsA("Part") then
			v.Transparency = 1
		end
	end
end

--================ ATTACHMENT =================

local function makeAttachment(pos)
	local p = Instance.new("Part")
	p.Size = Vector3.one * 0.12
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Position = pos
	p.Parent = folder

	return Instance.new("Attachment", p)
end

--=========== MULTI BEAM (ROUND & SOFT) ===========

local function makeRoundBeam(a0, a1, h0, h1)
	local function spawn(curve)
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.FaceCamera = true
		b.LightEmission = 0.25
		b.Segments = BEAM_SEGMENTS

		b.Width0 = BEAM_WIDTH
		b.Width1 = BEAM_WIDTH

		b.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, hsv(h0)),
			ColorSequenceKeypoint.new(1, hsv(h1))
		}

		b.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.5, 0.22),
			NumberSequenceKeypoint.new(1, 0.4)
		}

		b.CurveSize0 = curve
		b.CurveSize1 = -curve
		b.Parent = folder
	end

	-- 3 beam cukup (ANTI LAG)
	spawn(0)
	spawn(BEAM_WIDTH * MULTI_BEAM_OFFSET)
	spawn(-BEAM_WIDTH * MULTI_BEAM_OFFSET)
end

--================ MAIN LOOP ===================

RunService.RenderStepped:Connect(function()
	if not _G.Predicting then
		clearTrajectory() -- ðŸ”¥ NO TRACE
		return
	end

	folder:ClearAllChildren()

	local pos = ball.Position
	local vel = ball.AssemblyLinearVelocity
	local spin = ball.AssemblyAngularVelocity

	local lastSample = pos
	local hue = 0

	local points = {}
	table.insert(points, {att = makeAttachment(pos), hue = hue})

	for i = 1, MAX_STEPS do
		-- physics
		vel += gravity * SIM_STEP
		vel -= vel * AIR_DRAG

		if spin.Magnitude > 0.1 and vel.Magnitude > 0.1 then
			local magnus = spin:Cross(vel)
			if magnus.Magnitude > 0 then
				vel += magnus.Unit * spin.Magnitude * MAGNUS_STRENGTH * SIM_STEP
			end
		end

		vel *= FRICTION

		local move = vel * SIM_STEP
		local ray = Workspace:Raycast(pos, move, rayParams)

		if ray and validHit(ray) then
			pos = ray.Position + ray.Normal * 0.05
			vel = reflect(vel, ray.Normal) * BOUNCE_DAMPING
		else
			pos += move
		end

		if (pos - lastSample).Magnitude >= SAMPLE_DISTANCE then
			hue += 0.02
			table.insert(points, {att = makeAttachment(pos), hue = hue})
			lastSample = pos

			if #points >= MAX_SEGMENTS then break end
		end

		if vel.Magnitude <= MIN_VELOCITY then break end
	end

	for i = 1, #points - 1 do
		makeRoundBeam(
			points[i].att,
			points[i + 1].att,
			points[i].hue,
			points[i + 1].hue
		)
	end
end)