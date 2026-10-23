local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.VehicleCatalog)
local EventCatalog = require(Shared.EventCatalog)
local Remotes = require(Shared.Remotes)

local DamageService = require(script.Parent.DamageService)
local EventService = require(script.Parent.EventService)
local VehicleFactory = require(script.Parent.VehicleFactory)

local VehicleService = {}

local cars = {} -- [Player] = Rig
local lastCarId = {} -- [Player] = string
local lastSpawn = {} -- [Player] = os.clock()

local dataService

local carsFolder = Instance.new("Folder")
carsFolder.Name = "Cars"
carsFolder.Parent = workspace

local function removeCar(player: Player)
	local rig = cars[player]
	if rig then
		cars[player] = nil
		rig.Chassis.Parent:Destroy()
	end
end

-- at: 指定すると、その位置・向きに車を出してキャラクターもそこへ移動する(プレス後の再出現用)
local function spawnCar(player: Player, carId: string, at: CFrame?)
	local def = Catalog.ById[carId]
	if not def or not dataService.owns(player, carId) then
		return
	end
	local now = os.clock()
	if not at and lastSpawn[player] and now - lastSpawn[player] < 1 then
		return
	end
	lastSpawn[player] = now

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and humanoid.Health > 0) then
		return
	end

	removeCar(player)

	if at then
		character:PivotTo(at + Vector3.new(0, 5, 0))
		root = character:FindFirstChild("HumanoidRootPart") or root
	end

	-- 足元の地面に合わせて置く(落下ダメージを避ける)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character, carsFolder }
	local hit = workspace:Raycast(root.Position + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), params)
	local groundY = hit and hit.Position.Y or root.Position.Y - 3
	local _, yaw = (at or root.CFrame):ToEulerAnglesYXZ()
	local height = groundY + VehicleFactory.rideHeight(def) + 0.5
	local cf = CFrame.new(root.Position.X, height, root.Position.Z) * CFrame.Angles(0, yaw, 0)

	local model, rig = VehicleFactory.build(def, cf, player.UserId, player.Name)
	model.Parent = carsFolder
	pcall(function()
		rig.Chassis:SetNetworkOwner(player)
	end)
	DamageService.attach(rig)

	cars[player] = rig
	lastCarId[player] = carId
	rig.Seat:Sit(humanoid)
end

function VehicleService.getVehicle(player: Player)
	return cars[player]
end

-- 管理対象から外す(車自体は壊さない)。プレス中の車を他の処理から切り離すのに使う
function VehicleService.forget(player: Player)
	cars[player] = nil
end

function VehicleService.respawn(player: Player, at: CFrame)
	spawnCar(player, lastCarId[player] or "sedan", at)
end

function VehicleService.init(service)
	dataService = service
	local spawnRemote = Remotes.get("SpawnCar")
	local buyRemote = Remotes.get("BuyCar")
	local resetRemote = Remotes.get("ResetCar")
	local notifyRemote = Remotes.get("Notify")

	spawnRemote.OnServerEvent:Connect(function(player, carId)
		if typeof(carId) == "string" then
			spawnCar(player, carId)
		end
	end)

	resetRemote.OnServerEvent:Connect(function(player)
		spawnCar(player, lastCarId[player] or "sedan")
	end)

	buyRemote.OnServerEvent:Connect(function(player, carId)
		local def = typeof(carId) == "string" and Catalog.ById[carId]
		if not def or dataService.owns(player, carId) then
			return
		end
		if def.RequiresEvent and not EventService.isDone(player, def.RequiresEvent) then
			local event = EventCatalog.ById[def.RequiresEvent]
			notifyRemote:FireClient(player, `Locked: clear "{event and event.Name or def.RequiresEvent}" first`)
			return
		end
		if dataService.spend(player, def.Price) then
			dataService.grant(player, carId)
			notifyRemote:FireClient(player, `Bought {def.Name}!`)
			spawnCar(player, carId)
		else
			notifyRemote:FireClient(player, "Not enough cash")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		removeCar(player)
		lastCarId[player] = nil
		lastSpawn[player] = nil
	end)

	-- 飛行機・ヘリの上下入力(クライアントから)。範囲を丸めて保存するだけ
	Remotes.get("FlightAxis").OnServerEvent:Connect(function(player, axis)
		local rig = cars[player]
		if rig and typeof(axis) == "number" and axis == axis then
			rig.Lift = math.clamp(axis, -1, 1)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		for _, rig in cars do
			if rig.Seat.Occupant then
				rig.Active = true
				rig.Update(rig, dt)
			elseif rig.Active then
				rig.Active = false
				rig.Idle(rig)
			end
		end
	end)
end

return VehicleService
