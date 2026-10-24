-- 乗り物の操縦ロジック(車・飛行機・ヘリ)。
-- 運転中は「運転している本人の端末」で毎フレーム実行する(VehicleController.client)。
-- 物理を計算している端末で直接動かすので、通信の遅れによるガタつきが出ない。
-- サーバーは乗っていない機体を止める(idle)ときだけ使う。
local Config = require(script.Parent.Config)

local VehicleControl = {}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function moveToward(value: number, target: number, step: number): number
	if value < target then
		return math.min(value + step, target)
	end
	return math.max(value - step, target)
end

local function rideHeight(def): number
	if def.Kind == "heli" then
		return def.Size.Y / 2 + 1.2
	end
	return def.Size.Y / 2 + (def.Style == "bush" and 1.85 or 1.1)
end

local function newState(chassis: BasePart)
	local _, yaw = chassis.CFrame:ToEulerAnglesYXZ()
	return { yaw = yaw, pitch = 0, roll = 0, speed = 0, throttle = 0, fwd = 0, climb = 0 }
end

-- モデルから操縦に必要な部品を集める(端末側で使う。部品は名前で探す)
function VehicleControl.fromModel(model: Model, def, ignore: { Instance })
	local chassis = model:FindFirstChild("Chassis")
	local seat = model:FindFirstChild("Seat")
	if not (def and chassis and seat) then
		return nil
	end
	local rig = {
		Kind = def.Kind,
		Def = def,
		Chassis = chassis,
		Seat = seat,
		Motors = {},
		Steers = {},
		Rotors = {},
		Align = chassis:FindFirstChild("FlightAlign"),
		Linear = chassis:FindFirstChild("FlightVelocity"),
		State = newState(chassis),
	}
	for _, d in model:GetDescendants() do
		if d.Name == "DriveMotor" then
			table.insert(rig.Motors, d)
		elseif d.Name == "SteerServo" then
			table.insert(rig.Steers, d)
		elseif d.Name == "RotorMotor" then
			table.insert(rig.Rotors, { Hinge = d, Speed = d:GetAttribute("Speed") or 40 })
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = table.clone(ignore)
	table.insert(filter, model)
	params.FilterDescendantsInstances = filter
	rig.RayParams = params
	return rig
end

-- ===== 車 =====
local function driveCar(rig, throttle: number, steer: number)
	local def = rig.Def
	local r = def.WheelRadius
	if not rig.Torque then
		rig.Torque = rig.Chassis.AssemblyMass * def.Accel * r / math.max(#rig.Motors, 1) * 1.5
	end
	local speed = rig.Chassis.AssemblyLinearVelocity.Magnitude
	for _, motor in rig.Motors do
		if throttle ~= 0 then
			motor.MotorMaxTorque = rig.Torque
			motor.AngularVelocity = Config.DriveSign * -throttle * def.MaxSpeed / r
		else
			motor.MotorMaxTorque = 0 -- 惰性走行
		end
	end
	local angle = -steer * Config.SteerSign * Config.MaxSteerAngle / (1 + speed / 50)
	for _, hinge in rig.Steers do
		hinge.TargetAngle = angle
	end
end

-- ===== 飛行機・ヘリ =====
local function isGrounded(rig): boolean
	local hit = workspace:Raycast(rig.Chassis.Position, Vector3.new(0, -(rideHeight(rig.Def) + 1.2), 0), rig.RayParams)
	return hit ~= nil
end

local function spinRotors(rig, on: boolean)
	for _, rotor in rig.Rotors or {} do
		rotor.Hinge.MotorMaxTorque = on and 1e5 or 0
		rotor.Hinge.AngularVelocity = on and rotor.Speed or 0
	end
end

local function flyPlane(rig, dt: number, input)
	local def, st = rig.Def, rig.State
	rig.Linear.Enabled = true
	rig.Align.Enabled = true
	spinRotors(rig, true)

	local pitchIn = -input.Throttle -- S / スティック下で機首上げ
	local steer = input.Steer
	local grounded = isGrounded(rig)

	st.throttle = math.clamp(st.throttle + input.Lift * dt * 0.6, 0, 1)
	st.speed = moveToward(st.speed, def.MaxSpeed * st.throttle, def.Accel * dt)

	if grounded and st.speed < def.TakeoffSpeed then
		st.pitch = lerp(st.pitch, 0, math.min(1, dt * 6)) -- 離陸速度まで機首は上がらない
	else
		st.pitch = math.clamp(st.pitch + pitchIn * def.PitchRate * dt, -1.2, 1.2)
		if pitchIn == 0 then
			st.pitch = lerp(st.pitch, 0, math.min(1, dt * 0.4))
		end
		if not grounded and st.speed < def.StallSpeed then
			st.pitch = math.max(st.pitch - dt * 0.8, -1.2) -- 失速して機首が落ちる
		end
	end

	st.yaw += -steer * def.YawRate * dt * (grounded and 0.4 or 1)
	st.roll = lerp(st.roll, -steer * 0.7, math.min(1, dt * 4))

	local heading = CFrame.Angles(0, st.yaw, 0) * CFrame.Angles(st.pitch, 0, 0)
	rig.Align.CFrame = heading * CFrame.Angles(0, 0, st.roll)

	local velocity = heading.LookVector * st.speed
	if grounded and st.pitch <= 0.01 then
		velocity = Vector3.new(velocity.X, math.min(rig.Chassis.AssemblyLinearVelocity.Y, 0), velocity.Z)
	end
	rig.Linear.VectorVelocity = velocity
end

local function flyHeli(rig, dt: number, input)
	local def, st = rig.Def, rig.State
	rig.Linear.Enabled = true
	rig.Align.Enabled = true
	spinRotors(rig, true)

	st.yaw += -input.Steer * def.YawRate * dt
	st.fwd = lerp(st.fwd, input.Throttle, math.min(1, dt * 2))
	st.climb = lerp(st.climb, input.Lift, math.min(1, dt * 3))

	local yawCF = CFrame.Angles(0, st.yaw, 0)
	rig.Align.CFrame = yawCF * CFrame.Angles(-st.fwd * 0.25, 0, -input.Steer * 0.25)
	rig.Linear.VectorVelocity = yawCF.LookVector * (st.fwd * def.MaxSpeed) + Vector3.new(0, st.climb * def.ClimbSpeed, 0)
end

-- 運転中に毎フレーム呼ぶ。input = { Throttle = -1..1, Steer = -1..1, Lift = -1..1 }
function VehicleControl.update(rig, dt: number, input)
	if rig.Chassis.Parent == nil then
		return
	end
	if rig.Chassis.Parent:GetAttribute("Wrecked") then
		VehicleControl.idle(rig)
		return
	end
	if rig.Kind == "car" then
		driveCar(rig, input.Throttle, input.Steer)
	elseif rig.Kind == "plane" then
		flyPlane(rig, dt, input)
	else
		flyHeli(rig, dt, input)
	end
end

-- 降りたとき・壊れたときに動力を切る
function VehicleControl.idle(rig)
	for _, motor in rig.Motors or {} do
		motor.MotorMaxTorque = 0
	end
	for _, hinge in rig.Steers or {} do
		hinge.TargetAngle = 0
	end
	if rig.Linear then
		rig.Linear.Enabled = false
	end
	if rig.Align then
		rig.Align.Enabled = false
	end
	spinRotors(rig, false)
	if rig.Chassis.Parent then
		rig.State = newState(rig.Chassis)
	end
end

VehicleControl.rideHeight = rideHeight

return VehicleControl
