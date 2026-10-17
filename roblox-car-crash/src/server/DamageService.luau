local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DamageService = {}

local rewardHandler: (userId: number, amount: number, label: string) -> () = function() end

function DamageService.setRewardHandler(fn)
	rewardHandler = fn
end

local function detach(rig, index: number)
	local entry = rig.Deformables[index]
	table.remove(rig.Deformables, index)
	entry.Weld:Destroy()
	local part = entry.Part
	part.Massless = false
	part.AssemblyLinearVelocity = rig.Chassis.AssemblyLinearVelocity
		+ Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5) * 40
	Debris:AddItem(part, 20)
end

-- localDir: 車体ローカルで見た「ぶつかった方向」
local function deform(rig, localDir: Vector3, damage: number)
	local size = rig.Def.Size
	local center = Vector3.new(localDir.X * size.X / 2, size.Y / 2 + localDir.Y * size.Y, localDir.Z * size.Z / 2)
	local radius = 4 + damage * 0.3

	for i = #rig.Deformables, 1, -1 do
		local entry = rig.Deformables[i]
		local weld = entry.Weld
		local dist = (weld.C0.Position - center).Magnitude
		if dist < radius then
			local f = 1 - dist / radius
			local push = math.min(damage * 0.05 * f, 2.5)
			local function jitter()
				return (math.random() - 0.5) * f * damage * 0.02
			end
			weld.C0 = CFrame.new(-localDir * push) * weld.C0 * CFrame.Angles(jitter(), jitter(), jitter())
			entry.Part.Color = entry.Part.Color:Lerp(Color3.fromRGB(30, 30, 30), math.min(0.05 + f * damage * 0.01, 0.6))
			if damage * f > rig.Def.Health * 0.15 and math.random() < 0.5 then
				detach(rig, i)
			end
		end
	end
end

local function wreck(rig)
	local model = rig.Chassis.Parent
	model:SetAttribute("Wrecked", true)

	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(40, 40, 40)
	smoke.Opacity = 0.6
	smoke.RiseVelocity = 8
	smoke.Size = 6
	smoke.Parent = rig.Chassis

	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Parent = rig.Chassis

	local boom = Instance.new("Explosion")
	boom.Position = rig.Chassis.Position
	boom.BlastRadius = 14
	boom.BlastPressure = 300000
	boom.DestroyJointRadiusPercent = 0
	boom.ExplosionType = Enum.ExplosionType.NoCraters
	boom.Parent = workspace
end

function DamageService.attach(rig)
	local chassis: Part = rig.Chassis
	local model = chassis.Parent
	local def = rig.Def
	local ownerId: number? = model:GetAttribute("OwnerUserId")

	local health = def.Health
	model:SetAttribute("Health", health)
	model:SetAttribute("MaxHealth", health)

	-- 最後に接触した他プレイヤーの車(撃破クレジット用)
	local lastHitter, lastHitTime = nil, 0
	local function trackTouch(part: BasePart)
		part.Touched:Connect(function(other)
			local otherModel = other:FindFirstAncestorOfClass("Model")
			if otherModel and otherModel ~= model then
				local id = otherModel:GetAttribute("OwnerUserId")
				if id and id ~= ownerId then
					lastHitter, lastHitTime = id, os.clock()
				end
			end
		end)
	end
	trackTouch(chassis)
	for _, entry in rig.Deformables do
		if entry.Part.Name:find("Bumper") then
			trackTouch(entry.Part)
		end
	end

	local history = {}
	local cooldownUntil = os.clock() + Config.SpawnGrace

	local function impact(dv: Vector3)
		local damage = math.min((dv.Magnitude - Config.ImpactThreshold) * def.DamageScale, health)
		if damage <= 0 then
			return
		end
		local localDir = chassis.CFrame:VectorToObjectSpace(dv.Unit)
		deform(rig, localDir, damage)

		health -= damage
		model:SetAttribute("Health", health)

		local credited = lastHitter and os.clock() - lastHitTime <= Config.HitCredit
		if ownerId then
			rewardHandler(ownerId, damage * Config.CashPerDamage, "CRASH")
		end
		if credited then
			rewardHandler(lastHitter, damage * Config.HitCashPerDamage, "SMASH")
		end

		if health <= 0 then
			wreck(rig)
			if credited then
				rewardHandler(lastHitter, Config.WreckBonus, "WRECKED!")
			end
		end
	end

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not chassis.Parent then
			conn:Disconnect()
			return
		end
		if health <= 0 or model:GetAttribute("Crushing") then
			return
		end

		local now = os.clock()
		local v = chassis.AssemblyLinearVelocity
		table.insert(history, { now, v })
		while #history > 1 and now - history[1][1] > Config.ImpactWindow do
			table.remove(history, 1)
		end
		if now < cooldownUntil then
			return
		end

		local dv = history[1][2] - v
		if dv.Magnitude > Config.ImpactThreshold then
			impact(dv)
			table.clear(history)
			cooldownUntil = now + Config.ImpactCooldown
		end
	end)
end

return DamageService
