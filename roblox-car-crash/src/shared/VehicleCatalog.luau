-- 乗り物の定義。ここにデータを足すだけで新しい車・飛行機・ヘリが増える。
--   Kind: "car" | "plane" | "heli"
--   Origin: "jp"(国産系デザイン) | "os"(海外系デザイン)  ※イベントの集計用
--   RequiresEvent: そのイベントをクリアするまで購入できない
--   Inspiration: モデルにした実在車(社内メモ。ゲーム内には表示しない)
-- ゲーム内の名前は権利リスクを避けるため全て自作名。ライセンスを取ったら Name を差し替える。

-- 車の体格クラスごとの標準値(個別の項目で上書きできる)
local CLASSES = {
	kei = { Body = "box", Size = Vector3.new(5, 1.2, 10), WheelRadius = 1.1, WheelWidth = 0.8, CabinHeight = 2.6, MaxSpeed = 70, Accel = 40, Health = 80 },
	mini = { Body = "hatch", Size = Vector3.new(5, 1.1, 10), WheelRadius = 1.1, WheelWidth = 0.8, CabinHeight = 1.8, MaxSpeed = 85, Accel = 50, Health = 80 },
	hatch = { Body = "hatch", Size = Vector3.new(5.6, 1.1, 11.5), WheelRadius = 1.2, WheelWidth = 0.9, CabinHeight = 1.9, MaxSpeed = 85, Accel = 48, Health = 90 },
	sedan = { Body = "sedan", Size = Vector3.new(6, 1.2, 13), WheelRadius = 1.3, WheelWidth = 0.9, CabinHeight = 2, MaxSpeed = 90, Accel = 48, Health = 100 },
	mpv = { Body = "box", Size = Vector3.new(6, 1.3, 14), WheelRadius = 1.3, WheelWidth = 0.9, CabinHeight = 2.8, MaxSpeed = 80, Accel = 40, Health = 120 },
	bigvan = { Body = "box", Size = Vector3.new(6.6, 1.5, 16), WheelRadius = 1.4, WheelWidth = 1, CabinHeight = 3.2, MaxSpeed = 80, Accel = 38, Health = 150 },
	suv = { Body = "suv", Size = Vector3.new(6.6, 1.6, 14), WheelRadius = 1.6, WheelWidth = 1.1, CabinHeight = 2.4, MaxSpeed = 90, Accel = 45, Health = 160 },
	offroad = { Body = "suv", Size = Vector3.new(5.4, 1.6, 10.5), WheelRadius = 1.6, WheelWidth = 1.1, CabinHeight = 2.4, MaxSpeed = 75, Accel = 42, Health = 150 },
	pickup = { Body = "pickup", Size = Vector3.new(7, 1.6, 17), WheelRadius = 1.7, WheelWidth = 1.2, CabinHeight = 2.4, MaxSpeed = 90, Accel = 45, Health = 200 },
	sports = { Body = "sports", Size = Vector3.new(6, 0.9, 13), WheelRadius = 1.2, WheelWidth = 1, CabinHeight = 1.4, MaxSpeed = 150, Accel = 75, Health = 90 },
	super = { Body = "sports", Size = Vector3.new(6.6, 0.8, 13.5), WheelRadius = 1.25, WheelWidth = 1.1, CabinHeight = 1.2, MaxSpeed = 190, Accel = 95, Health = 90 },
}

local function car(id: string, origin: string, class: string, name: string, price: number, inspiration: string, overrides)
	local def = { Id = id, Kind = "car", Origin = origin, Name = name, Price = price, Inspiration = inspiration }
	for k, v in CLASSES[class] do
		def[k] = v
	end
	for k, v in overrides or {} do
		def[k] = v
	end
	return def
end

local rgb = Color3.fromRGB

local Vehicles = {
	-- ===== 初期からの車 =====
	car("sedan", "jp", "sedan", "Rusty Sedan", 0, "-", { MaxSpeed = 85, Accel = 45, Color = rgb(196, 40, 28) }),
	car("racer", "os", "sports", "Street Racer", 1500, "-", { Size = Vector3.new(6, 1, 13.5), CabinHeight = 1.5, MaxSpeed = 140, Accel = 70, Color = rgb(13, 105, 172) }),
	car("truck", "os", "pickup", "Heavy Truck", 3500, "-", {
		Body = "sedan",
		Size = Vector3.new(8, 1.8, 17),
		WheelRadius = 1.8,
		WheelWidth = 1.4,
		CabinHeight = 3,
		MaxSpeed = 80,
		Accel = 35,
		Health = 260,
		DamageScale = 0.5,
		RequiresEvent = "scrap_quota",
		Color = rgb(226, 155, 64),
	}),
	car("monster", "os", "offroad", "Monster Crusher", 9000, "-", {
		Size = Vector3.new(9, 2, 15),
		WheelRadius = 3.2,
		WheelWidth = 2.4,
		CabinHeight = 2.2,
		MaxSpeed = 100,
		Accel = 40,
		Health = 500,
		DamageScale = 0.35,
		Color = rgb(75, 151, 75),
	}),

	-- ===== 国産系 20 =====
	car("pocket_hatch", "jp", "hatch", "Pocket Hatch", 800, "Toyota Yaris", { Color = rgb(230, 230, 235) }),
	car("commuter", "jp", "sedan", "Commuter Sedan", 1200, "Toyota Corolla", { Color = rgb(150, 155, 165) }),
	car("family_mover", "jp", "mpv", "Family Mover", 1400, "Toyota Sienta", { Color = rgb(120, 180, 160) }),
	car("kei_tower", "jp", "kei", "Kei Tower", 600, "Honda N-BOX", { Color = rgb(245, 240, 225) }),
	car("kei_slider", "jp", "kei", "Kei Slider", 600, "Suzuki Spacia", { Color = rgb(255, 200, 120) }),
	car("tall_cube", "jp", "kei", "Tall Cube", 900, "Toyota Roomy", { Size = Vector3.new(5.4, 1.2, 11), Color = rgb(90, 90, 100) }),
	car("compact_mover", "jp", "mpv", "Compact Mover", 1300, "Honda Freed", { Size = Vector3.new(5.8, 1.3, 13), Color = rgb(180, 200, 220) }),
	car("mini_crawler", "jp", "offroad", "Mini Crawler", 1600, "Suzuki Jimny", { Size = Vector3.new(4.8, 1.5, 9), MaxSpeed = 65, Color = rgb(160, 170, 90) }),
	car("work_van", "jp", "bigvan", "Work Van", 1800, "Toyota HiAce", { Color = rgb(250, 250, 250) }),
	car("grand_lounge", "jp", "bigvan", "Grand Lounge", 4500, "Toyota Alphard", { Size = Vector3.new(6.6, 1.5, 15.5), MaxSpeed = 90, Color = rgb(20, 20, 25) }),
	car("desert_chief", "jp", "suv", "Desert Chief", 5500, "Toyota Land Cruiser", { Health = 220, Color = rgb(200, 190, 165) }),
	car("eco_wedge", "jp", "hatch", "Eco Wedge", 1500, "Toyota Prius", { Size = Vector3.new(6, 1.1, 13), Accel = 55, Color = rgb(200, 210, 220) }),
	car("thunder_gt", "jp", "super", "Thunder GT", 22000, "Nissan GT-R", { Body = "sports", Size = Vector3.new(6.6, 1, 14), CabinHeight = 1.5, Health = 130, Color = rgb(70, 75, 85) }),
	car("sunrise_coupe", "jp", "sports", "Sunrise Coupe", 12000, "Toyota Supra", { MaxSpeed = 165, Color = rgb(230, 90, 30) }),
	car("drift_coupe", "jp", "sports", "Drift Coupe", 7000, "Toyota GR86", { MaxSpeed = 140, Color = rgb(240, 240, 245) }),
	car("redline_hatch", "jp", "hatch", "Redline Hatch", 9000, "Honda Civic Type R", { MaxSpeed = 150, Accel = 80, Color = rgb(235, 235, 235) }),
	car("breeze_roadster", "jp", "sports", "Breeze Roadster", 6000, "Mazda Roadster", { Size = Vector3.new(5.6, 0.9, 11.5), CabinHeight = 1, MaxSpeed = 130, Color = rgb(170, 20, 30) }),
	car("rotor_coupe", "jp", "sports", "Rotor Coupe", 11000, "Mazda RX-7", { MaxSpeed = 160, Color = rgb(250, 210, 30) }),
	car("rally_x", "jp", "sedan", "Rally Sedan X", 10000, "Mitsubishi Lancer Evolution", { MaxSpeed = 150, Accel = 85, Color = rgb(30, 80, 170) }),
	car("midship_blade", "jp", "super", "Midship Blade", 30000, "Honda NSX", { RequiresEvent = "jp_vs_os", Color = rgb(200, 30, 30) }),

	-- ===== 海外系 20 =====
	car("volt_crossover", "os", "suv", "Volt Crossover", 6000, "Tesla Model Y", { Accel = 85, MaxSpeed = 120, Color = rgb(240, 240, 245) }),
	car("volt_sedan", "os", "sedan", "Volt Sedan", 5500, "Tesla Model 3", { Accel = 90, MaxSpeed = 130, Color = rgb(30, 30, 35) }),
	car("ranch_pickup", "os", "pickup", "Ranch Pickup", 4000, "Ford F-Series", { Color = rgb(40, 60, 120) }),
	car("prairie_pickup", "os", "pickup", "Prairie Pickup", 4000, "Chevrolet Silverado", { Color = rgb(150, 20, 20) }),
	car("euro_crossover", "os", "suv", "Euro Crossover", 3800, "Volkswagen Tiguan", { Color = rgb(130, 140, 150) }),
	car("jade_sedan", "os", "sedan", "Jade Sedan", 3000, "BYD King", { Accel = 60, Color = rgb(40, 110, 90) }),
	car("sparrow_ev", "os", "mini", "Sparrow City EV", 1500, "BYD Seagull", { Accel = 60, Color = rgb(200, 230, 240) }),
	car("stallion_gt", "os", "sports", "Stallion GT", 9000, "Ford Mustang", { MaxSpeed = 155, Color = rgb(30, 90, 200) }),
	car("arrow_v8", "os", "sports", "Arrow V8", 16000, "Chevrolet Corvette", { MaxSpeed = 175, Color = rgb(250, 200, 0) }),
	car("muscle_coupe", "os", "sports", "Muscle Coupe", 8500, "Chevrolet Camaro", { Size = Vector3.new(6.4, 1, 13.5), Color = rgb(230, 120, 20) }),
	car("brute_coupe", "os", "sports", "Brute Coupe", 9500, "Dodge Challenger", { Size = Vector3.new(6.6, 1.1, 14.5), Health = 120, Color = rgb(90, 30, 120) }),
	car("rock_climber", "os", "offroad", "Rock Climber 4x4", 4500, "Jeep Wrangler", { Size = Vector3.new(6, 1.6, 11.5), Color = rgb(60, 100, 50) }),
	car("euro_hatch", "os", "hatch", "Euro Hatch", 2500, "Volkswagen Golf", { Color = rgb(60, 70, 160) }),
	car("autobahn_sport", "os", "sedan", "Autobahn Sport", 14000, "BMW M3", { MaxSpeed = 170, Accel = 85, Color = rgb(20, 120, 160) }),
	car("box_commander", "os", "offroad", "Box Commander", 20000, "Mercedes-Benz G-Class", { Size = Vector3.new(6.4, 1.8, 13), CabinHeight = 2.8, Health = 260, MaxSpeed = 95, Color = rgb(25, 25, 25) }),
	car("ring_supercar", "os", "super", "Ring Supercar", 28000, "Audi R8", { Color = rgb(220, 220, 225) }),
	car("classic_rear", "os", "sports", "Classic Rear-Engine", 18000, "Porsche 911", { Size = Vector3.new(6, 1, 13), MaxSpeed = 175, Color = rgb(190, 190, 195) }),
	car("wedge_supercar", "os", "super", "Wedge Supercar", 35000, "Lamborghini Huracan", { MaxSpeed = 205, RequiresEvent = "jp_vs_os", Color = rgb(120, 200, 40) }),
	car("scarlet_v8", "os", "super", "Scarlet V8", 35000, "Ferrari 488", { MaxSpeed = 205, RequiresEvent = "jp_vs_os", Color = rgb(200, 0, 0) }),
	car("city_mini", "os", "mini", "City Mini", 2000, "MINI Cooper", { Color = rgb(20, 70, 50) }),

	-- ===== 飛行機 10 / ヘリ =====
	-- 操作: W/S=機首下げ/上げ(ヘリは前進/後退)、A/D=旋回、Shift/E=加速(上昇)、Ctrl/Q=減速(下降)、F=ウインチ(Sky Crane)
	{
		Id = "trainer", Kind = "plane", Style = "prop", Name = "Sky Trainer", Price = 0, Inspiration = "Cessna 172",
		Size = Vector3.new(3, 3, 12), WingSpan = 22, MaxSpeed = 110, Accel = 25, TakeoffSpeed = 55, StallSpeed = 40,
		PitchRate = 0.9, YawRate = 0.7, Health = 80, ImpactThreshold = 45, Color = rgb(235, 235, 240),
	},
	{
		Id = "aero_stunt", Kind = "plane", Style = "stunt", Name = "Aero Stunt", Price = 3000, Inspiration = "Extra 330 / biplanes",
		Size = Vector3.new(2.6, 2.6, 10), WingSpan = 16, MaxSpeed = 140, Accel = 40, TakeoffSpeed = 50, StallSpeed = 35,
		PitchRate = 1.6, YawRate = 1.2, Health = 70, ImpactThreshold = 45, Color = rgb(230, 40, 40),
	},
	{
		Id = "bush_hopper", Kind = "plane", Style = "bush", Name = "Bush Hopper", Price = 2500, Inspiration = "DHC-2 Beaver (floatplane)",
		Size = Vector3.new(3.4, 3.4, 13), WingSpan = 24, MaxSpeed = 90, Accel = 22, TakeoffSpeed = 40, StallSpeed = 30,
		PitchRate = 0.8, YawRate = 0.6, Health = 110, ImpactThreshold = 45, Color = rgb(250, 200, 40),
	},
	{
		Id = "jet", Kind = "plane", Style = "jet", Name = "Sky Jet", Price = 12000, RequiresEvent = "sky_rings", Inspiration = "business jet",
		Size = Vector3.new(3.4, 3.2, 18), WingSpan = 16, MaxSpeed = 260, Accel = 70, TakeoffSpeed = 90, StallSpeed = 65,
		PitchRate = 1.2, YawRate = 0.9, Health = 120, ImpactThreshold = 60, Color = rgb(110, 118, 130),
	},
	{
		Id = "air_liner", Kind = "plane", Style = "liner", Name = "Air Liner", Price = 20000, Inspiration = "Boeing 737",
		Size = Vector3.new(6, 6, 40), WingSpan = 50, MaxSpeed = 200, Accel = 30, TakeoffSpeed = 80, StallSpeed = 60,
		PitchRate = 0.5, YawRate = 0.35, Health = 300, ImpactThreshold = 60, Color = rgb(245, 245, 250),
	},
	{
		Id = "strike_fighter", Kind = "plane", Style = "fighter", Name = "Strike Fighter", Price = 40000, RequiresEvent = "jp_vs_os", Inspiration = "F-16 / F-22",
		Size = Vector3.new(3.4, 3, 20), WingSpan = 14, MaxSpeed = 330, Accel = 110, TakeoffSpeed = 95, StallSpeed = 70,
		PitchRate = 1.6, YawRate = 1.1, Health = 140, ImpactThreshold = 70, Color = rgb(95, 105, 115),
	},
	{
		Id = "copter", Kind = "heli", Style = "light", Name = "Rescue Copter", Price = 4000, Inspiration = "Robinson R44 / EMS heli",
		Size = Vector3.new(4, 3.5, 8), MaxSpeed = 90, ClimbSpeed = 35, YawRate = 1.4, Health = 100, ImpactThreshold = 45, Color = rgb(215, 60, 50),
	},
	{
		Id = "sky_crane", Kind = "heli", Style = "crane", Name = "Sky Crane", Price = 8000, RequiresEvent = "scrap_quota", CanLift = true, Inspiration = "CH-47 Chinook",
		Size = Vector3.new(6, 5, 18), MaxSpeed = 70, ClimbSpeed = 25, YawRate = 0.9, Health = 250, ImpactThreshold = 50, Color = rgb(85, 100, 70),
	},
	{
		Id = "gunship", Kind = "heli", Style = "gunship", Name = "Gunship", Price = 18000, RequiresEvent = "heavy_lift", Inspiration = "AH-64 Apache",
		Size = Vector3.new(3, 3.5, 10), MaxSpeed = 130, ClimbSpeed = 40, YawRate = 1.8, Health = 160, ImpactThreshold = 50, Color = rgb(60, 70, 55),
	},
	{
		Id = "tilt_rotor", Kind = "heli", Style = "tiltrotor", Name = "Tilt Rotor", Price = 25000, RequiresEvent = "heavy_lift", Inspiration = "V-22 Osprey",
		Size = Vector3.new(4, 4, 16), WingSpan = 22, MaxSpeed = 170, ClimbSpeed = 35, YawRate = 1, Health = 180, ImpactThreshold = 55, Color = rgb(120, 125, 120),
	},
}

local ById = {}
for _, def in Vehicles do
	def.DamageScale = def.DamageScale or 0.6
	def.Color = def.Color or rgb(160, 160, 160)
	assert(not ById[def.Id], `duplicate vehicle id {def.Id}`)
	ById[def.Id] = def
end

return { Vehicles = Vehicles, ById = ById }
