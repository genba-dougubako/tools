local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Course = require(Shared.RingCourse)
local Remotes = require(Shared.Remotes)

local CoinService = require(script.Parent.CoinService)
local EventService = require(script.Parent.EventService)

local RingService = {}

local SEGMENTS = 24

local notify = Remotes.get("Notify")
local rings = {} -- { CF: CFrame (ローカル -Z がリングの向き), Radius: number }
local progress = {} -- [Player] = { next, combo, lastPass, prevZ }

local function buildRing(index: number, center: Vector3, lookAt: Vector3, parent: Instance)
	local cf = CFrame.lookAt(center, lookAt)
	local radius = Course.Radius
	local model = Instance.new("Model")
	model.Name = `Ring{index}`

	for k = 0, SEGMENTS - 1 do
		local angle = k / SEGMENTS * math.pi * 2
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(80, 220, 255)
		part.Size = Vector3.new(2.6, 6.4, 2.6) -- Y が円周(接線)方向
		part.CFrame = cf * CFrame.Angles(0, 0, angle) * CFrame.new(radius, 0, 0)
		part.Parent = model
	end

	local label = Instance.new("Part")
	label.Anchored = true
	label.CanCollide = false
	label.Transparency = 1
	label.Size = Vector3.one
	label.CFrame = cf * CFrame.new(0, radius + 5, 0)
	label.Parent = model
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(80, 40)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 600
	gui.Parent = label
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.3
	text.Text = tostring(index)
	text.Parent = gui

	model.Parent = parent
	table.insert(rings, { CF = cf, Radius = radius })
end

local function reset(player: Player)
	progress[player] = { next = 1, combo = 0, lastPass = 0, prevZ = nil }
	player:SetAttribute("RingNext", 1)
end

local function onPass(player: Player, state)
	local now = os.clock()
	state.combo = (state.combo > 0 and now - state.lastPass <= Config.RingComboWindow) and state.combo + 1 or 1
	state.lastPass = now

	local reward = Config.RingReward + (math.min(state.combo, Config.RingComboMax) - 1) * Config.RingComboBonus
	CoinService.add(player, reward)
	EventService.add(player, "ring_pass", 1)

	local passed = state.next
	state.next += 1
	state.prevZ = nil

	if state.next > #rings then
		CoinService.add(player, Config.CourseBonus)
		EventService.add(player, "course_clear", 1)
		notify:FireClient(player, `COURSE CLEAR! +{Config.CourseBonus} COINS`)
		reset(player)
	else
		player:SetAttribute("RingNext", state.next)
		notify:FireClient(player, `RING {passed}/{#rings}  +{reward}  (x{state.combo})`)
	end
end

local function step(player: Player, vehicles)
	local state = progress[player]
	if not state then
		return
	end

	-- 時間切れでやり直し
	if state.next > 1 and os.clock() - state.lastPass > Config.RingTimeout then
		reset(player)
		notify:FireClient(player, "Time up - course reset")
		return
	end

	local rig = vehicles.getVehicle(player)
	if not rig or rig.Def.Kind == "car" or rig.Chassis.Parent:GetAttribute("Wrecked") then
		state.prevZ = nil
		return
	end

	local ring = rings[state.next]
	local lp = ring.CF:PointToObjectSpace(rig.Chassis.Position)
	local radial = math.sqrt(lp.X * lp.X + lp.Y * lp.Y)
	local prev = state.prevZ
	state.prevZ = lp.Z

	-- 面を前後どちらかに横切り、かつ輪の内側を通ったら通過
	if prev and (prev > 0) ~= (lp.Z > 0) and radial < ring.Radius * 0.95 then
		onPass(player, state)
	end
end

function RingService.init(vehicles)
	local folder = Instance.new("Folder")
	folder.Name = "SkyRings"
	local points = Course.Points
	for i, point in points do
		local nextPoint = points[i + 1]
		local lookAt = nextPoint or (point + (point - points[i - 1]))
		buildRing(i, point, lookAt, folder)
	end
	folder.Parent = workspace

	local function setup(player: Player)
		reset(player)
		player:SetAttribute("RingTotal", #rings)
	end
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		setup(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		progress[player] = nil
	end)

	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			step(player, vehicles)
		end
	end)
end

return RingService
