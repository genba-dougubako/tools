local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local PressService = {}

-- ローカル座標: -Z が奥(車の進行方向)、+Z が入口、Y が上。
-- ワールドでは入口がスポーン側(-X)を向く。
local ORIGIN = CFrame.new(70, 0, 20) * CFrame.Angles(0, -math.pi / 2, 0)
local BAY = Vector3.new(22, 14, 26) -- 内寸(幅, 有効高さ, 奥行き)
local FLOOR_Y = 0.4
local PLATE_THICK = 3
local REST_BOTTOM = 13 -- 待機時のプレス板の下面の高さ
local PRESS_BOTTOM = 1.4 -- 最下点でのプレス板の下面の高さ
local BEAM_BOTTOM = 20
local PANEL_POS = Vector3.new(-16, 0, 9)
local PANEL_REACH = 20 -- ボタンから操作者までの最大距離(studs)

local WARN_TIME = 1.5
local SLAM_TIME = 1.1
local HOLD_TIME = 1.2
local RAISE_TIME = 1.5

local notify = Remotes.get("Notify")
local fxRemote = Remotes.get("PressFx")

local folder = Instance.new("Folder")
folder.Name = "CarPress"

local function part(name: string, size: Vector3, localCF: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = ORIGIN * localCF
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local concrete = Color3.fromRGB(125, 125, 130)
local steel = Color3.fromRGB(70, 72, 78)

-- 構造物
part("Floor", Vector3.new(BAY.X + 4, FLOOR_Y, BAY.Z + 2), CFrame.new(0, FLOOR_Y / 2, 0), Color3.fromRGB(85, 85, 90), Enum.Material.Concrete)
part("BackWall", Vector3.new(BAY.X + 4, BEAM_BOTTOM, 2), CFrame.new(0, BEAM_BOTTOM / 2, -BAY.Z / 2 - 1), concrete, Enum.Material.Concrete)
for _, sx in { -1, 1 } do
	part("SideWall", Vector3.new(2, BEAM_BOTTOM, BAY.Z + 2), CFrame.new(sx * (BAY.X / 2 + 1), BEAM_BOTTOM / 2, 0), concrete, Enum.Material.Concrete)
end
local roof = part("Roof", Vector3.new(BAY.X + 4, 2, BAY.Z + 2), CFrame.new(0, BEAM_BOTTOM + 1, 0), steel, Enum.Material.Metal)
roof.Transparency = 0.6

-- 可動部
local plate = part("PressPlate", Vector3.new(BAY.X - 1, PLATE_THICK, BAY.Z - 2), CFrame.new(), Color3.fromRGB(230, 150, 20), Enum.Material.DiamondPlate)
local rods = {}
for _, sx in { -1, 1 } do
	for _, sz in { -1, 1 } do
		local rod = part("PistonRod", Vector3.one, CFrame.new(), Color3.fromRGB(170, 170, 175), Enum.Material.Metal)
		table.insert(rods, { Part = rod, X = sx * 8, Z = sz * 9 })
	end
end

local function plateBottom(t: number): number
	return REST_BOTTOM + (PRESS_BOTTOM - REST_BOTTOM) * t
end

-- t = 0 で待機位置、1 で最下点
local function setPress(t: number)
	local bottom = plateBottom(t)
	plate.CFrame = ORIGIN * CFrame.new(0, bottom + PLATE_THICK / 2, 0)
	local top = bottom + PLATE_THICK
	local len = BEAM_BOTTOM - top
	for _, rod in rods do
		rod.Part.Size = Vector3.new(1.6, len, 1.6)
		rod.Part.CFrame = ORIGIN * CFrame.new(rod.X, top + len / 2, rod.Z)
	end
end
setPress(0)

-- 警告灯
local beacon = part("Beacon", Vector3.new(2, 2, 2), CFrame.new(0, BEAM_BOTTOM + 3, 0), Color3.fromRGB(60, 0, 0), Enum.Material.SmoothPlastic)
local beaconLight = Instance.new("PointLight")
beaconLight.Color = Color3.fromRGB(255, 40, 40)
beaconLight.Range = 30
beaconLight.Enabled = false
beaconLight.Parent = beacon

local function setBeacon(on: boolean)
	beacon.Color = on and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(60, 0, 0)
	beacon.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	beaconLight.Enabled = on
end

-- 看板
local signPart = part("Sign", Vector3.one, CFrame.new(0, BEAM_BOTTOM + 8, BAY.Z / 2), Color3.new(), Enum.Material.SmoothPlastic)
signPart.Transparency = 1
signPart.CanCollide = false
local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.fromOffset(360, 90)
billboard.MaxDistance = 300
billboard.Parent = signPart
local signText = Instance.new("TextLabel")
signText.Size = UDim2.fromScale(1, 1)
signText.BackgroundTransparency = 1
signText.Font = Enum.Font.GothamBlack
signText.TextScaled = true
signText.TextColor3 = Color3.fromRGB(255, 220, 60)
signText.TextStrokeTransparency = 0.3
signText.Text = `CAR PRESS\nCrush your car: +{Config.PressReward} COINS`
signText.Parent = billboard

-- 操作盤
part("PanelPedestal", Vector3.new(2, 4, 2), CFrame.new(PANEL_POS + Vector3.new(0, 2, 0)), steel, Enum.Material.Metal)
local button = part("PanelButton", Vector3.new(1.2, 0.6, 1.2), CFrame.new(PANEL_POS + Vector3.new(0, 4.3, 0)), Color3.fromRGB(220, 30, 30), Enum.Material.Neon)
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Start Press"
prompt.ObjectText = "Car Press"
prompt.HoldDuration = 0.4
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Parent = button

-- 操作者を退避させる場所(操作盤の手前)
local standCF = ORIGIN * CFrame.new(PANEL_POS.X, 3, PANEL_POS.Z + 4)
-- プレス後に車を出す場所(入口の外、奥向き)
local respawnCF = ORIGIN * CFrame.new(0, 0, BAY.Z / 2 + 14)

local busy = false

local function insideBay(position: Vector3): boolean
	local lp = ORIGIN:PointToObjectSpace(position)
	return math.abs(lp.X) < BAY.X / 2 + 2 and math.abs(lp.Z) < BAY.Z / 2 + 2 and lp.Y < BEAM_BOTTOM
end

-- 車体(Chassis)の8隅がすべて内寸の中にあり、ほぼ水平であること
local function carInBay(chassis: BasePart): boolean
	if chassis.CFrame.UpVector.Y < 0.7 then
		return false
	end
	local half = chassis.Size / 2
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local lp = ORIGIN:PointToObjectSpace(chassis.CFrame * Vector3.new(sx * half.X, sy * half.Y, sz * half.Z))
				if math.abs(lp.X) > BAY.X / 2 - 1 or math.abs(lp.Z) > BAY.Z / 2 - 1 or lp.Y < 0 or lp.Y > BAY.Y then
					return false
				end
			end
		end
	end
	return true
end

-- 車を固定し、関節を外して、パーツ単位で潰せる状態にする
local function lockCar(player: Player, model: Model, rig)
	rig.Seat.Disabled = true
	local seatWeld = rig.Seat:FindFirstChild("SeatWeld")
	if seatWeld then
		seatWeld:Destroy() -- 先に外さないと PivotTo で車ごと動く
	end
	if player.Character then
		player.Character:PivotTo(standCF)
	end

	pcall(function()
		rig.Chassis:SetNetworkOwner(nil)
	end)
	local squash = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.AssemblyLinearVelocity = Vector3.zero
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(squash, { Part = d, CF = d.CFrame, Size = d.Size })
		end
	end
	local bbCF, bbSize = model:GetBoundingBox()
	return squash, bbCF.Position.Y + bbSize.Y / 2
end

local function squashCar(squash, carTop: number, t: number)
	local k = math.clamp((plateBottom(t) - FLOOR_Y) / (carTop - FLOOR_Y), 0.05, 1)
	for _, e in squash do
		if e.Part.Parent then
			local pos = e.CF.Position
			local newY = FLOOR_Y + (pos.Y - FLOOR_Y) * k
			e.Part.Size = Vector3.new(e.Size.X, e.Size.Y * k, e.Size.Z)
			e.Part.CFrame = CFrame.new(pos.X, newY, pos.Z) * e.CF.Rotation
		end
	end
end

local function crushFx()
	local origin = ORIGIN * CFrame.new(0, FLOOR_Y + 1, 0)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = origin
	anchor.Parent = workspace

	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate = 0
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Speed = NumberRange.new(30, 60)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, -60, 0)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(1.2, 0)
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 210, 90))
	sparks.Parent = anchor
	sparks:Emit(90)

	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(70, 70, 70)
	smoke.Opacity = 0.5
	smoke.RiseVelocity = 6
	smoke.Size = 8
	smoke.Parent = anchor

	local flash = Instance.new("PointLight")
	flash.Color = Color3.fromRGB(255, 190, 80)
	flash.Brightness = 8
	flash.Range = 40
	flash.Parent = anchor

	local boom = Instance.new("Explosion") -- 見た目のみ(押し出し・関節破壊なし)
	boom.Position = origin.Position
	boom.BlastRadius = 12
	boom.BlastPressure = 0
	boom.DestroyJointRadiusPercent = 0
	boom.ExplosionType = Enum.ExplosionType.NoCraters
	boom.Parent = workspace

	task.delay(0.4, function()
		flash:Destroy()
	end)
	task.delay(2, function()
		smoke.Enabled = false
	end)
	Debris:AddItem(anchor, 6)

	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - origin.Position).Magnitude < 150 then
			fxRemote:FireClient(p, origin.Position)
		end
	end
end

local function tweenValue(value: NumberValue, target: number, seconds: number, style: Enum.EasingStyle, direction: Enum.EasingDirection)
	local tween = TweenService:Create(value, TweenInfo.new(seconds, style, direction), { Value = target })
	tween:Play()
	tween.Completed:Wait()
end

local function addCoins(player: Player, amount: number)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		coins.Value += amount
	end
end

local function runPress(carService, player: Player, model: Model, rig)
	local squash, carTop = lockCar(player, model, rig)

	local progress = Instance.new("NumberValue")
	local deepest = 0 -- 板が上がっても潰れた車は元に戻さない
	local conn = progress.Changed:Connect(function(t)
		setPress(t)
		deepest = math.max(deepest, t)
		squashCar(squash, carTop, deepest)
	end)

	-- 警告
	notify:FireClient(player, "Press starting...")
	for _ = 1, 3 do
		setBeacon(true)
		task.wait(WARN_TIME / 6)
		setBeacon(false)
		task.wait(WARN_TIME / 6)
	end
	setBeacon(true)

	-- 打ち下ろし
	tweenValue(progress, 1, SLAM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	crushFx()

	-- 成功判定: 最後まで潰れた状態で車が残っていて、プレイヤーも在席
	if model.Parent and player.Parent then
		addCoins(player, Config.PressReward)
		notify:FireClient(player, `CRUSHED! +{Config.PressReward} COINS`)
	end

	task.wait(HOLD_TIME)
	tweenValue(progress, 0, RAISE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	conn:Disconnect()
	progress:Destroy()
	setBeacon(false)
	model:Destroy()

	if player.Parent then
		carService.respawn(player, respawnCF)
	end
end

local function onTriggered(carService, player: Player)
	if busy then
		notify:FireClient(player, "Press is busy")
		return
	end

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and humanoid.Health > 0) then
		return
	end
	if (root.Position - button.Position).Magnitude > PANEL_REACH then
		return
	end

	local rig = carService.getCar(player)
	local model = rig and rig.Chassis.Parent
	if not model or model:GetAttribute("Crushing") then
		notify:FireClient(player, "Spawn a car first")
		return
	end
	if not carInBay(rig.Chassis) then
		notify:FireClient(player, "Park your car inside the press")
		return
	end

	for _, other in Players:GetPlayers() do
		local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if other ~= player and otherRoot and insideBay(otherRoot.Position) then
			notify:FireClient(player, "Clear the press area")
			return
		end
	end

	-- ここから先は yield するので、先に占有してから処理する
	busy = true
	model:SetAttribute("Crushing", true)
	carService.forget(player)
	prompt.Enabled = false

	local ok, err = pcall(runPress, carService, player, model, rig)
	if not ok then
		warn(`Press failed: {err}`)
		setPress(0)
		setBeacon(false)
		if model.Parent then
			model:Destroy()
		end
	end
	prompt.Enabled = true
	busy = false
end

local function setupCoins(player: Player)
	local stats = player:WaitForChild("leaderstats", 30)
	if stats and not stats:FindFirstChild("Coins") then
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = stats
	end
end

function PressService.init(carService)
	folder.Parent = workspace

	Players.PlayerAdded:Connect(function(player)
		task.spawn(setupCoins, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(setupCoins, player)
	end

	prompt.Triggered:Connect(function(player)
		onTriggered(carService, player)
	end)
end

return PressService
