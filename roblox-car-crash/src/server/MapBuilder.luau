local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.VehicleCatalog)

local CarBuilder = require(script.Parent.CarBuilder)
local DamageService = require(script.Parent.DamageService)

local MapBuilder = {}

local map = Instance.new("Folder")
map.Name = "Map"

local function block(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, anchored: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.Anchored = anchored
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = map
	return part
end

-- 低い側の端が (x, 0, z) に接する坂。yaw=0 だと -Z 方向に登る
local function ramp(x: number, z: number, yaw: number, length: number, width: number, degrees: number)
	local t = 1
	local a = math.rad(degrees)
	local center = Vector3.new(0, length / 2 * math.sin(a) - t / 2 * math.cos(a), -length / 2 * math.cos(a))
	block(
		"Ramp",
		Vector3.new(width, t, length),
		CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0) * CFrame.new(center) * CFrame.Angles(a, 0, 0),
		Color3.fromRGB(120, 120, 125),
		Enum.Material.Concrete,
		true
	)
end

local function brickWall(x: number, z: number, cols: number, rows: number)
	local w, h, d = 6, 3, 3
	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			local offset = (row % 2) * w / 2
			local part = block(
				"Brick",
				Vector3.new(w - 0.1, h - 0.1, d),
				CFrame.new(x + (col - cols / 2) * w + offset, h / 2 + row * h, z),
				Color3.fromRGB(163 + math.random(-15, 15), 80, 60),
				Enum.Material.Brick,
				false
			)
			part.CustomPhysicalProperties = PhysicalProperties.new(0.8, 0.6, 0, 1, 1)
		end
	end
end

local function dummyCar(index: number, cf: CFrame, carId: string)
	local def = Catalog.ById[carId]
	local color = Color3.fromHSV(math.random(), 0.6, 0.8)
	local variant = table.clone(def)
	variant.Color = color
	local model, rig = CarBuilder.build(variant, cf, nil, nil)
	model.Name = "Dummy"
	model.Parent = map
	DamageService.attach(rig)

	-- 壊れたらしばらくして復活
	model:GetAttributeChangedSignal("Wrecked"):Once(function()
		task.delay(20, function()
			model:Destroy()
			dummyCar(index, cf, carId)
		end)
	end)
end

function MapBuilder.build()
	local old = workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end

	block("Ground", Vector3.new(1400, 4, 1400), CFrame.new(0, -2, 0), Color3.fromRGB(91, 154, 76), Enum.Material.Grass, true)
	block("Road", Vector3.new(40, 0.2, 700), CFrame.new(0, 0.1, -320), Color3.fromRGB(60, 60, 64), Enum.Material.Asphalt, true)

	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.7, 20)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(255, 200, 0)
	spawn.Parent = map

	-- ジャンプ台
	ramp(0, -40, 0, 50, 24, 18)
	ramp(-90, -60, math.rad(15), 40, 20, 25)

	-- レンガの壁・バリア
	brickWall(0, -190, 8, 6)
	for i = -2, 2 do
		local barrier = block(
			"Barrier",
			Vector3.new(10, 4, 3),
			CFrame.new(i * 11, 2, -130),
			Color3.fromRGB(190, 190, 190),
			Enum.Material.Concrete,
			false
		)
		barrier.CustomPhysicalProperties = PhysicalProperties.new(2, 0.5, 0, 1, 1)
	end

	-- 正面衝突用の巨大な壁
	block("BigWall", Vector3.new(120, 30, 6), CFrame.new(0, 15, -400), Color3.fromRGB(150, 150, 155), Enum.Material.Concrete, true)

	-- ダミー車の駐車場(体当たり用)
	local ids = { "sedan", "racer", "truck", "sedan", "racer", "truck" }
	for i, id in ids do
		local def = Catalog.ById[id]
		local pos = Vector3.new(-80 - ((i - 1) % 3) * 16, def.WheelRadius + def.Size.Y / 2 + 0.3, -120 - math.floor((i - 1) / 3) * 25)
		dummyCar(i, CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0), id)
	end

	map.Parent = workspace
end

return MapBuilder
