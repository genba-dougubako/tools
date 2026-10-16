-- Size は車体(Chassis)のサイズ。前方は -Z。
local Cars = {
	{
		Id = "sedan",
		Name = "Rusty Sedan",
		Price = 0,
		Size = Vector3.new(6, 1.2, 13),
		WheelRadius = 1.3,
		WheelWidth = 0.9,
		CabinHeight = 2,
		MaxSpeed = 85,
		Accel = 45,
		Health = 100,
		Color = Color3.fromRGB(196, 40, 28),
	},
	{
		Id = "racer",
		Name = "Street Racer",
		Price = 1500,
		Size = Vector3.new(6, 1, 13.5),
		WheelRadius = 1.2,
		WheelWidth = 1,
		CabinHeight = 1.5,
		MaxSpeed = 140,
		Accel = 70,
		Health = 90,
		Color = Color3.fromRGB(13, 105, 172),
	},
	{
		Id = "truck",
		Name = "Heavy Truck",
		Price = 3500,
		Size = Vector3.new(8, 1.8, 17),
		WheelRadius = 1.8,
		WheelWidth = 1.4,
		CabinHeight = 3,
		MaxSpeed = 80,
		Accel = 35,
		Health = 260,
		DamageScale = 0.5,
		Color = Color3.fromRGB(226, 155, 64),
	},
	{
		Id = "monster",
		Name = "Monster Crusher",
		Price = 9000,
		Size = Vector3.new(9, 2, 15),
		WheelRadius = 3.2,
		WheelWidth = 2.4,
		CabinHeight = 2.2,
		MaxSpeed = 100,
		Accel = 40,
		Health = 500,
		DamageScale = 0.35,
		Color = Color3.fromRGB(75, 151, 75),
	},
}

local ById = {}
for _, def in Cars do
	def.DamageScale = def.DamageScale or 0.6
	ById[def.Id] = def
end

return { Cars = Cars, ById = ById }
