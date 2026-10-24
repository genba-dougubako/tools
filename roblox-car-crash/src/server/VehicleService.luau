local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.VehicleCatalog)
local Paints = require(Shared.Paints)
local VehicleControl = require(Shared.VehicleControl)
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

	local paint = Paints[dataService.getPaint(player)]
	local model, rig = VehicleFactory.build(def, cf, player.UserId, player.Name, paint and paint.Color)
	model.Parent = carsFolder
	DamageService.attach(rig)

	-- 物理の計算は「乗っている人の端末」に任せる(操縦も同じ端末で行うのでガタつかない)。
	-- 降りたらサーバーに戻し、動力を切る。
	local function updateOwner()
		if not rig.Chassis.Parent or rig.Chassis.Anchored then
			return
		end
		local occupant = rig.Seat.Occupant
		local driver = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
		pcall(function()
			rig.Chassis:SetNetworkOwner(driver)
		end)
		if not driver then
			VehicleControl.idle(rig)
		end
	end
	rig.Seat:GetPropertyChangedSignal("Occupant"):Connect(updateOwner)
	pcall(function()
		rig.Chassis:SetNetworkOwner(player)
	end)

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

	-- 塗装: 番号を検証して保存し、今乗っている乗り物もすぐ塗り直す
	Remotes.get("SetPaint").OnServerEvent:Connect(function(player, index)
		if typeof(index) ~= "number" or index ~= math.floor(index) or index < 0 or index > #Paints then
			return
		end
		dataService.setPaint(player, index)
		local rig = cars[player]
		if rig and rig.Chassis.Parent then
			VehicleFactory.paint(rig.Chassis.Parent, index > 0 and Paints[index].Color or rig.Def.Color)
		end
	end)

	-- 簡易チート対策: 操縦は端末側なので、車種の限界を大きく超える速度が出たら物理をサーバーに戻す
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.5 then
			return
		end
		elapsed = 0
		for player, rig in cars do
			local limit = rig.Def.MaxSpeed * 1.6 + 60
			if rig.Seat.Occupant and rig.Chassis.AssemblyLinearVelocity.Magnitude > limit then
				warn(`{player.Name}: {rig.Def.Id} over speed limit, taking physics back`)
				pcall(function()
					rig.Chassis:SetNetworkOwner(nil)
				end)
				rig.Chassis.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

return VehicleService
