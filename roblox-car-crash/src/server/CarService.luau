local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.CarCatalog)
local Remotes = require(Shared.Remotes)

local CarBuilder = require(script.Parent.CarBuilder)
local DamageService = require(script.Parent.DamageService)

local CarService = {}

local cars = {} -- [Player] = Rig
local lastCarId = {} -- [Player] = string
local lastSpawn = {} -- [Player] = os.clock()

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

local function spawnCar(player: Player, carId: string, dataService)
	local def = Catalog.ById[carId]
	if not def or not dataService.owns(player, carId) then
		return
	end
	local now = os.clock()
	if lastSpawn[player] and now - lastSpawn[player] < 1 then
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

	-- 足元の地面に合わせて置く(落下ダメージを避ける)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character, carsFolder }
	local hit = workspace:Raycast(root.Position + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), params)
	local groundY = hit and hit.Position.Y or root.Position.Y - 3
	local _, yaw = root.CFrame:ToEulerAnglesYXZ()
	local height = groundY + def.WheelRadius + def.Size.Y / 2 + 0.5
	local cf = CFrame.new(root.Position.X, height, root.Position.Z) * CFrame.Angles(0, yaw, 0)

	local model, rig = CarBuilder.build(def, cf, player.UserId, player.Name)
	model.Parent = carsFolder
	pcall(function()
		rig.Chassis:SetNetworkOwner(player)
	end)
	DamageService.attach(rig)

	cars[player] = rig
	lastCarId[player] = carId
	rig.Seat:Sit(humanoid)
end

function CarService.init(dataService)
	local spawnRemote = Remotes.get("SpawnCar")
	local buyRemote = Remotes.get("BuyCar")
	local resetRemote = Remotes.get("ResetCar")
	local notifyRemote = Remotes.get("Notify")

	spawnRemote.OnServerEvent:Connect(function(player, carId)
		if typeof(carId) == "string" then
			spawnCar(player, carId, dataService)
		end
	end)

	resetRemote.OnServerEvent:Connect(function(player)
		spawnCar(player, lastCarId[player] or "sedan", dataService)
	end)

	buyRemote.OnServerEvent:Connect(function(player, carId)
		local def = typeof(carId) == "string" and Catalog.ById[carId]
		if not def or dataService.owns(player, carId) then
			return
		end
		if dataService.spend(player, def.Price) then
			dataService.grant(player, carId)
			notifyRemote:FireClient(player, `Bought {def.Name}!`)
			spawnCar(player, carId, dataService)
		else
			notifyRemote:FireClient(player, "Not enough cash")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		removeCar(player)
		lastCarId[player] = nil
		lastSpawn[player] = nil
	end)

	RunService.Heartbeat:Connect(function()
		for _, rig in cars do
			local seat = rig.Seat
			if seat.Occupant then
				local wrecked = rig.Chassis.Parent:GetAttribute("Wrecked")
				CarBuilder.drive(rig, wrecked and 0 or seat.ThrottleFloat, wrecked and 0 or seat.SteerFloat)
			elseif rig.Driven then
				CarBuilder.coast(rig)
			end
		end
	end)
end

return CarService
