-- 乗り物の定義。ここにデータを足すだけで新しい車・飛行機・ヘリが増える。
--   Kind: "car" | "plane" | "heli"
--   Origin: "jp"(国産系デザイン) | "os"(海外系デザイン) | nil  ※イベントの集計用
--   RequiresEvent: 指定すると、そのイベントをクリアするまで購入できない
-- 車名は権利リスクを避けるため全て自作名。実在車のライセンスを取る場合はここを差し替える。
local Vehicles = {
	-- ===== 車 =====
	{
		Id = "sedan",
		Kind = "car",
		Origin = "jp",
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
		Kind = "car",
		Origin = "os",
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
		Kind = "car",
		Origin = "os",
		Name = "Heavy Truck",
		Price = 3500,
		RequiresEvent = "scrap_quota",
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
		Kind = "car",
		Origin = "os",
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

	-- ===== 飛行機 / ヘリ =====
	-- 操作: W/S=機首下げ/上げ(ヘリは前進/後退)、A/D=旋回、Shift/E=加速(上昇)、Ctrl/Q=減速(下降)
	{
		Id = "trainer",
		Kind = "plane",
		Style = "prop",
		Name = "Sky Trainer",
		Price = 0,
		Size = Vector3.new(3, 3, 12),
		WingSpan = 22,
		MaxSpeed = 110,
		Accel = 25,
		TakeoffSpeed = 55,
		StallSpeed = 40,
		PitchRate = 0.9,
		YawRate = 0.7,
		Health = 80,
		ImpactThreshold = 45,
		Color = Color3.fromRGB(235, 235, 240),
	},
	{
		Id = "jet",
		Kind = "plane",
		Style = "jet",
		Name = "Sky Jet",
		Price = 12000,
		RequiresEvent = "sky_rings",
		Size = Vector3.new(3.4, 3.2, 18),
		WingSpan = 16,
		MaxSpeed = 260,
		Accel = 70,
		TakeoffSpeed = 90,
		StallSpeed = 65,
		PitchRate = 1.2,
		YawRate = 0.9,
		Health = 120,
		ImpactThreshold = 60,
		Color = Color3.fromRGB(110, 118, 130),
	},
	{
		Id = "copter",
		Kind = "heli",
		Name = "Rescue Copter",
		Price = 4000,
		Size = Vector3.new(4, 3.5, 8),
		MaxSpeed = 90,
		ClimbSpeed = 35,
		YawRate = 1.4,
		Health = 100,
		ImpactThreshold = 45,
		Color = Color3.fromRGB(215, 60, 50),
	},
}

local ById = {}
for _, def in Vehicles do
	def.DamageScale = def.DamageScale or 0.6
	ById[def.Id] = def
end

return { Vehicles = Vehicles, ById = ById }
