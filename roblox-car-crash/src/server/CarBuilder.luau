local CollectionService = game:GetService("CollectionService")

local CarBuilder = {}

-- 比率は車体の長さ L に対する割合。CabinZ は運転席の中心位置(+ が後ろ)
local BODY_STYLES = {
	sedan = { Cabin = 0.38, CabinZ = 0.06, Hood = 0.3, Trunk = 0.22 },
	hatch = { Cabin = 0.5, CabinZ = 0.17, Hood = 0.3, Trunk = 0 },
	box = { Cabin = 0.74, CabinZ = 0.1, Hood = 0.16, Trunk = 0 },
	suv = { Cabin = 0.56, CabinZ = 0.13, Hood = 0.3, Trunk = 0 },
	pickup = { Cabin = 0.28, CabinZ = -0.12, Hood = 0.28, Trunk = 0, Bed = true },
	sports = { Cabin = 0.3, CabinZ = 0.05, Hood = 0.36, Trunk = 0.2, Spoiler = true },
}

export type Rig = {
	Def: any,
	Chassis: Part,
	Seat: VehicleSeat,
	Motors: { HingeConstraint },
	Steers: { HingeConstraint },
	Deformables: { { Part: Part, Weld: Weld } },
}

local function attachment(parent: BasePart, position: Vector3, orientation: Vector3?): Attachment
	local att = Instance.new("Attachment")
	att.Position = position
	att.Orientation = orientation or Vector3.zero
	att.Parent = parent
	return att
end

-- cf: 車体中心のワールドCFrame(前方 -Z)
function CarBuilder.build(def, cf: CFrame, ownerUserId: number?, ownerName: string?): (Model, Rig)
	local W, H, L = def.Size.X, def.Size.Y, def.Size.Z
	local model = Instance.new("Model")
	model.Name = ownerName and `{ownerName}'s {def.Name}` or def.Name
	model:SetAttribute("CarId", def.Id)
	model:SetAttribute("OwnerUserId", ownerUserId)

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = def.Size
	chassis.Color = def.Color
	chassis.Material = Enum.Material.SmoothPlastic
	chassis.CFrame = cf
	chassis.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.3, 0.1, 1, 1)
	chassis.Parent = model
	model.PrimaryPart = chassis

	local deformables = {}
	local function addBody(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?, transparency: number?)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Transparency = transparency or 0
		part.Massless = true
		part.CFrame = cf * CFrame.new(offset)
		local weld = Instance.new("Weld")
		weld.Part0 = chassis
		weld.Part1 = part
		weld.C0 = CFrame.new(offset)
		weld.Parent = part
		part.Parent = model
		table.insert(deformables, { Part = part, Weld = weld })
		return part
	end

	-- 車体の形(Body)ごとの比率: 運転席(キャビン)の長さ・位置、ボンネット、トランク
	local style = BODY_STYLES[def.Body or "sedan"] or BODY_STYLES.sedan
	local top = H / 2
	local ch = def.CabinHeight
	local cabinLen, cabinZ = L * style.Cabin, L * style.CabinZ
	local hoodLen = L * style.Hood
	addBody("Hood", Vector3.new(W, 0.6, hoodLen), Vector3.new(0, top + 0.3, -L / 2 + hoodLen / 2 + L * 0.01), def.Color)
	if style.Trunk > 0 then
		local trunkLen = L * style.Trunk
		addBody("Trunk", Vector3.new(W, 0.6, trunkLen), Vector3.new(0, top + 0.3, L / 2 - trunkLen / 2 - L * 0.01), def.Color)
	end
	addBody("Glass", Vector3.new(W * 0.9, ch, cabinLen), Vector3.new(0, top + ch / 2, cabinZ), Color3.fromRGB(120, 170, 200), Enum.Material.Glass, 0.4)
	addBody("Roof", Vector3.new(W * 0.9, 0.3, cabinLen), Vector3.new(0, top + ch + 0.15, cabinZ), def.Color)
	if style.Bed then
		local bedLen = L * 0.42
		local bedZ = L / 2 - bedLen / 2 - L * 0.02
		for _, sx in { -1, 1 } do
			addBody("BedSide", Vector3.new(0.3, 1, bedLen), Vector3.new(sx * (W / 2 - 0.15), top + 0.5, bedZ), def.Color)
		end
		addBody("Tailgate", Vector3.new(W, 1, 0.3), Vector3.new(0, top + 0.5, L / 2 - L * 0.02), def.Color)
	end
	if style.Spoiler then
		addBody("Spoiler", Vector3.new(W * 0.9, 0.2, 1), Vector3.new(0, top + 1.3, L / 2 - 0.6), Color3.fromRGB(30, 30, 30))
		for _, sx in { -1, 1 } do
			addBody("SpoilerPost", Vector3.new(0.2, 1, 0.4), Vector3.new(sx * W * 0.3, top + 0.7, L / 2 - 0.6), Color3.fromRGB(30, 30, 30))
		end
	end
	addBody("FrontBumper", Vector3.new(W + 0.4, 0.8, 0.6), Vector3.new(0, -H / 2 + 0.7, -L / 2 - 0.3), Color3.fromRGB(60, 60, 60))
	addBody("RearBumper", Vector3.new(W + 0.4, 0.8, 0.6), Vector3.new(0, -H / 2 + 0.7, L / 2 + 0.3), Color3.fromRGB(60, 60, 60))
	for _, sx in { -1, 1 } do
		addBody("Headlight", Vector3.new(1, 0.5, 0.2), Vector3.new(sx * W * 0.35, top, -L / 2 - 0.05), Color3.fromRGB(255, 244, 180), Enum.Material.Neon)
		addBody("Taillight", Vector3.new(1, 0.5, 0.2), Vector3.new(sx * W * 0.35, top, L / 2 + 0.05), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(2, 0.8, 2)
	seat.Transparency = 1
	seat.Massless = true
	seat.CFrame = cf * CFrame.new(-W * 0.2, top + 0.4, cabinZ)
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = chassis
	seatWeld.Part1 = seat
	seatWeld.Parent = seat
	seat.Parent = model

	local motors, steers = {}, {}
	local r, ww = def.WheelRadius, def.WheelWidth
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do -- sz = -1 が前輪
			local localPos = Vector3.new(sx * (W / 2 + ww / 2 + 0.1), -H / 2, sz * L * 0.32)

			local wheel = Instance.new("Part")
			wheel.Name = "Wheel"
			wheel.Shape = Enum.PartType.Cylinder -- 軸は X
			wheel.Size = Vector3.new(ww, r * 2, r * 2)
			wheel.Color = Color3.fromRGB(25, 25, 25)
			wheel.Material = Enum.Material.SmoothPlastic
			wheel.CFrame = cf * CFrame.new(localPos)
			wheel.CustomPhysicalProperties = PhysicalProperties.new(1.5, 2.2, 0, 100, 1)
			wheel.Parent = model

			local mount: BasePart = chassis
			local mountPos = localPos
			if sz == -1 then
				local carrier = Instance.new("Part")
				carrier.Name = "SteerCarrier"
				carrier.Size = Vector3.one * 0.5
				carrier.Transparency = 1
				carrier.CanCollide = false
				carrier.CanQuery = false
				carrier.CanTouch = false
				carrier.CFrame = cf * CFrame.new(localPos)
				carrier.Parent = model

				-- Orientation (0,0,90): ヒンジ軸を X -> Y(縦軸)にする
				local steer = Instance.new("HingeConstraint")
				steer.Name = "SteerServo"
				steer.Attachment0 = attachment(chassis, localPos, Vector3.new(0, 0, 90))
				steer.Attachment1 = attachment(carrier, Vector3.zero, Vector3.new(0, 0, 90))
				steer.ActuatorType = Enum.ActuatorType.Servo
				steer.ServoMaxTorque = 1e6
				steer.AngularSpeed = 6
				steer.TargetAngle = 0
				steer.Parent = chassis
				table.insert(steers, steer)

				mount = carrier
				mountPos = Vector3.zero
			end

			local motor = Instance.new("HingeConstraint")
			motor.Name = "DriveMotor"
			motor.Attachment0 = attachment(mount, mountPos)
			motor.Attachment1 = attachment(wheel, Vector3.zero)
			motor.ActuatorType = Enum.ActuatorType.Motor
			motor.MotorMaxTorque = 0
			motor.MotorMaxAcceleration = 1e6
			motor.AngularVelocity = 0
			motor.Parent = wheel
			table.insert(motors, motor)
		end
	end

	model:SetAttribute("Kind", "car")
	CollectionService:AddTag(model, "Liftable") -- Sky Crane で吊れる

	local rig: Rig = {
		Kind = "car",
		Def = def,
		Chassis = chassis,
		Seat = seat,
		Motors = motors,
		Steers = steers,
		Deformables = deformables,
	}
	return model, rig
end

function CarBuilder.rideHeight(def): number
	return def.WheelRadius + def.Size.Y / 2
end

return CarBuilder
