-- 飛行機(plane)とヘリ(heli)の組み立て。物理は「アーケード式」で、操縦の計算は
-- Shared/VehicleControl が運転者の端末で行い、AlignOrientation / LinearVelocity で機体を追従させる。

local VehicleControl = require(game:GetService("ReplicatedStorage").Shared.VehicleControl)

local AircraftBuilder = {}

local function newAttachment(parent: BasePart, position: Vector3, orientation: Vector3?): Attachment
	local att = Instance.new("Attachment")
	att.Position = position
	att.Orientation = orientation or Vector3.zero
	att.Parent = parent
	return att
end

function AircraftBuilder.rideHeight(def): number
	return VehicleControl.rideHeight(def)
end

function AircraftBuilder.build(def, cf: CFrame, ownerUserId: number?, ownerName: string?)
	local W, H, L = def.Size.X, def.Size.Y, def.Size.Z
	local model = Instance.new("Model")
	model.Name = ownerName and `{ownerName}'s {def.Name}` or def.Name
	model:SetAttribute("CarId", def.Id)
	model:SetAttribute("OwnerUserId", ownerUserId)
	model:SetAttribute("Kind", def.Kind)

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = def.Size
	chassis.Color = def.Color
	chassis.Material = Enum.Material.SmoothPlastic
	chassis.CFrame = cf
	chassis.CustomPhysicalProperties = PhysicalProperties.new(2, 0.05, 0.1, 1, 1)
	chassis.Parent = model
	model.PrimaryPart = chassis

	local function addPart(name: string, size: Vector3, localCF: CFrame, color: Color3, opts)
		opts = opts or {}
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = opts.Material or Enum.Material.SmoothPlastic
		part.Transparency = opts.Transparency or 0
		part.Shape = opts.Shape or Enum.PartType.Block
		part.CanCollide = opts.CanCollide ~= false
		part.Massless = true
		part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.05, 0, 1, 1)
		part.CFrame = cf * localCF
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = chassis
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
		return part
	end

	local accent = Color3.fromRGB(40, 60, 90)
	local glass = Color3.fromRGB(120, 170, 200)
	local dark = Color3.fromRGB(30, 30, 30)
	local style = def.Style
	local seatOffset
	local rotors = {}

	-- ヒンジで回る羽根(プロペラ/ローター)。axis = "Y"(ヘリ) か "Z"(プロペラ)
	local function spinner(name: string, size: Vector3, localPos: Vector3, axis: string, speed: number)
		local blade = addPart(name, size, CFrame.new(localPos), dark, { CanCollide = false })
		blade:FindFirstChildOfClass("WeldConstraint"):Destroy()
		blade.Massless = false
		if axis == "Y" then
			local cross = Instance.new("Part")
			cross.Name = name .. "Cross"
			cross.Size = Vector3.new(size.Z, size.Y, size.X)
			cross.Color = dark
			cross.CanCollide = false
			cross.Massless = true
			cross.CFrame = blade.CFrame
			local crossWeld = Instance.new("WeldConstraint")
			crossWeld.Part0 = blade
			crossWeld.Part1 = cross
			crossWeld.Parent = cross
			cross.Parent = model
		end
		-- Orientation で X 軸(ヒンジ軸)を回す: (0,0,90) で Y、(0,90,0) で Z
		local orientation = axis == "Y" and Vector3.new(0, 0, 90) or Vector3.new(0, 90, 0)
		local hinge = Instance.new("HingeConstraint")
		hinge.Name = "RotorMotor"
		hinge:SetAttribute("Speed", speed)
		hinge.Attachment0 = newAttachment(chassis, localPos, orientation)
		hinge.Attachment1 = newAttachment(blade, Vector3.zero, orientation)
		hinge.ActuatorType = Enum.ActuatorType.Motor
		hinge.MotorMaxTorque = 0
		hinge.MotorMaxAcceleration = 1e5
		hinge.AngularVelocity = 0
		hinge.Parent = blade
		table.insert(rotors, { Hinge = hinge, Speed = speed })
	end

	if def.Kind == "plane" then
		local jetLike = style == "jet" or style == "fighter" or style == "liner"
		local big = style == "liner"
		local wingY = style == "bush" and H / 2 + 0.3 or (big and -H * 0.2 or 0.2)
		local chord = big and 8 or (jetLike and 5 or 3.4)

		addPart("Nose", Vector3.new(W, H, W), CFrame.new(0, 0, -L / 2), def.Color, { Shape = Enum.PartType.Ball })
		addPart("Wing", Vector3.new(def.WingSpan, big and 0.8 or 0.4, chord), CFrame.new(0, wingY, big and L * 0.05 or 0.5), accent)
		if style == "stunt" then
			addPart("UpperWing", Vector3.new(def.WingSpan, 0.4, chord), CFrame.new(0, H / 2 + 1.4, 0), accent)
			for _, sx in { -1, 1 } do
				addPart("WingStrut", Vector3.new(0.3, 1.8, 0.3), CFrame.new(sx * def.WingSpan * 0.35, H / 2 + 0.4, 0), dark)
			end
		end

		local tailScale = big and 2.5 or 1
		addPart("Tailplane", Vector3.new(W * 2.4 * (big and 1.6 or 1), 0.3 * tailScale, 2.6 * tailScale), CFrame.new(0, 0.4, L / 2 - 1 * tailScale), accent)
		if style == "fighter" then
			for _, sx in { -1, 1 } do
				addPart("Fin", Vector3.new(0.4, 3, 2.8), CFrame.new(sx * 1.2, H / 2 + 1.2, L / 2 - 1.6) * CFrame.Angles(0, 0, sx * math.rad(-15)), accent)
			end
		else
			addPart("Fin", Vector3.new(0.4 * tailScale, 3.4 * tailScale, 2.8 * tailScale), CFrame.new(0, H / 2 + 1.4 * tailScale, L / 2 - 1.2 * tailScale), accent)
		end

		local cockpitZ = big and -L / 2 + 4 or -L * 0.15
		if big then
			addPart("Windows", Vector3.new(W + 0.05, 0.6, L * 0.75), CFrame.new(0, H * 0.15, 0), Color3.fromRGB(30, 50, 70), { CanCollide = false })
		end
		addPart("Canopy", Vector3.new(W * 0.8, 1.6, big and 2.5 or 3.6), CFrame.new(0, H / 2 + (big and -0.4 or 0.5), cockpitZ), glass, {
			Material = Enum.Material.Glass,
			Transparency = 0.4,
		})

		if style == "bush" then
			-- フロート(水上機)
			for _, sx in { -1, 1 } do
				addPart("Float", Vector3.new(1, 1, L * 0.9), CFrame.new(sx * W * 0.8, -H / 2 - 1.35, 0), Color3.fromRGB(220, 220, 220))
				for _, sz in { -L * 0.2, L * 0.2 } do
					addPart("FloatStrut", Vector3.new(0.3, 1.2, 0.3), CFrame.new(sx * W * 0.6, -H / 2 - 0.4, sz), dark)
				end
			end
		else
			for _, sx in { -1, 1 } do
				addPart("Gear", Vector3.new(1.6, 1.6, 1.6), CFrame.new(sx * (big and 4 or 1.6), -H / 2 - 0.3, big and 2 or -2), dark, { Shape = Enum.PartType.Ball })
			end
			addPart("NoseGear", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, -H / 2 - 0.3, jetLike and -L / 2 + 3 or L / 2 - 2), dark, { Shape = Enum.PartType.Ball })
		end

		if style == "liner" then
			for _, sx in { -1, 1 } do
				addPart("Engine", Vector3.new(4, 3, 3), CFrame.new(sx * def.WingSpan * 0.25, wingY - 2, L * 0.02) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(180, 180, 185), {
					Shape = Enum.PartType.Cylinder,
				})
			end
		elseif style == "fighter" then
			addPart("Afterburner", Vector3.new(0.4, 2, 2), CFrame.new(0, 0, L / 2 + 0.2) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 140, 40), {
				Shape = Enum.PartType.Cylinder,
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
		elseif style == "jet" then
			for _, sx in { -1, 1 } do
				addPart("Engine", Vector3.new(3, 1.8, 1.8), CFrame.new(sx * (W / 2 + 0.6), -0.4, L / 2 - 3) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(70, 70, 75), {
					Shape = Enum.PartType.Cylinder,
				})
				addPart("Afterburner", Vector3.new(0.4, 1.4, 1.4), CFrame.new(sx * (W / 2 + 0.6), -0.4, L / 2 - 1.4) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 140, 40), {
					Shape = Enum.PartType.Cylinder,
					Material = Enum.Material.Neon,
					CanCollide = false,
				})
			end
		else
			spinner("Propeller", Vector3.new(0.4, W * 1.8, 0.5), Vector3.new(0, 0, -L / 2 - W * 0.55), "Z", 60)
		end
		seatOffset = Vector3.new(0, H / 2 + (big and -1 or 0.2), cockpitZ)
	else
		-- ヘリ共通: 風防とスキッド
		addPart("Cockpit", Vector3.new(W * 0.9, 2, 2.8), CFrame.new(0, 0.2, -L / 2 + 1), glass, {
			Material = Enum.Material.Glass,
			Transparency = 0.4,
		})
		for _, sx in { -1, 1 } do
			addPart("Skid", Vector3.new(0.4, 0.4, L * 0.9), CFrame.new(sx * (W / 2), -H / 2 - 1, 0), accent)
			for _, sz in { -L * 0.25, L * 0.25 } do
				addPart("Strut", Vector3.new(0.3, 1.2, 0.3), CFrame.new(sx * (W / 2), -H / 2 - 0.4, sz), accent)
			end
		end

		if style == "crane" then
			-- 前後2つのローター(タンデム)
			for _, sz in { -L * 0.36, L * 0.36 } do
				addPart("Mast", Vector3.new(1, 1.6, 1), CFrame.new(0, H / 2 + 0.8, sz), accent)
				spinner("Rotor", Vector3.new(16, 0.2, 1), Vector3.new(0, H / 2 + 1.7, sz), "Y", 30)
			end
			addPart("Winch", Vector3.new(1.4, 0.6, 1.4), CFrame.new(0, -H / 2 - 0.3, 0), Color3.fromRGB(250, 200, 30))
		elseif style == "tiltrotor" then
			addPart("Wing", Vector3.new(def.WingSpan, 0.5, 3), CFrame.new(0, H / 2, -1), accent)
			addPart("Fin", Vector3.new(0.4, 3, 2.4), CFrame.new(0, H / 2 + 1.2, L / 2 - 1.2), accent)
			addPart("Tailplane", Vector3.new(7, 0.3, 2), CFrame.new(0, H / 2 + 0.2, L / 2 - 1), accent)
			for _, sx in { -1, 1 } do
				addPart("Nacelle", Vector3.new(1.6, 3, 1.6), CFrame.new(sx * def.WingSpan / 2, H / 2 + 1, -1), Color3.fromRGB(90, 95, 90))
				spinner("Rotor", Vector3.new(10, 0.2, 0.8), Vector3.new(sx * def.WingSpan / 2, H / 2 + 2.7, -1), "Y", 35)
			end
		else
			addPart("TailBoom", Vector3.new(1, 1, 9), CFrame.new(0, 0.8, L / 2 + 4), def.Color)
			addPart("TailFin", Vector3.new(0.4, 2.6, 1.6), CFrame.new(0, 2, L / 2 + 8), def.Color)
			addPart("Mast", Vector3.new(0.7, 1.2, 0.7), CFrame.new(0, H / 2 + 0.6, 0), accent)
			if style == "gunship" then
				addPart("StubWing", Vector3.new(W + 6, 0.3, 1.6), CFrame.new(0, 0, 0.5), accent)
				for _, sx in { -1, 1 } do
					addPart("Pod", Vector3.new(2.4, 1, 1), CFrame.new(sx * (W / 2 + 2.6), -0.6, 0.5) * CFrame.Angles(0, math.rad(90), 0), dark, {
						Shape = Enum.PartType.Cylinder,
					})
				end
			end
			spinner("Rotor", Vector3.new(style == "gunship" and 15 or 18, 0.2, 1), Vector3.new(0, H / 2 + 1.3, 0), "Y", 40)
		end
		seatOffset = Vector3.new(-W * 0.22, 0.2, -L / 2 + 1.5)
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(2, 0.8, 2)
	seat.Transparency = 1
	seat.Massless = true
	seat.CFrame = cf * CFrame.new(seatOffset)
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = chassis
	seatWeld.Part1 = seat
	seatWeld.Parent = seat
	seat.Parent = model

	-- 姿勢・速度の目標を与える拘束(運転手がいる間だけ有効)
	local att = newAttachment(chassis, Vector3.zero)
	local align = Instance.new("AlignOrientation")
	align.Name = "FlightAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.RigidityEnabled = false
	align.Responsiveness = 25
	align.MaxTorque = 1e9
	align.MaxAngularVelocity = math.huge
	align.CFrame = cf.Rotation
	align.Enabled = false
	align.Parent = chassis

	local linear = Instance.new("LinearVelocity")
	linear.Name = "FlightVelocity"
	linear.Attachment0 = att
	linear.RelativeTo = Enum.ActuatorRelativeTo.World
	linear.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linear.MaxForce = 1e9
	linear.VectorVelocity = Vector3.zero
	linear.Enabled = false
	linear.Parent = chassis

	local rig = {
		Kind = def.Kind,
		Def = def,
		Chassis = chassis,
		Seat = seat,
		Deformables = {}, -- 変形なし(DamageService との互換用)
		Align = align,
		Linear = linear,
		Rotors = rotors,
		CanLift = def.CanLift == true,
	}
	model:SetAttribute("CanLift", def.CanLift == true)
	return model, rig
end

return AircraftBuilder
