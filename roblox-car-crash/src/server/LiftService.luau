-- Sky Crane のウインチ: F キーで真下の車を吊る/離す
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Remotes = require(Shared.Remotes)

local EventService = require(script.Parent.EventService)

local LiftService = {}

local REACH = 30 -- ヘリの真下から吊れる距離(studs)

local notify = Remotes.get("Notify")

local function release(rig)
	if rig.Carry then
		rig.Carry.Rope:Destroy()
		rig.Carry.Att0:Destroy()
		rig.Carry.Att1:Destroy()
		rig.Carry = nil
	end
end

local function findTarget(rig): Model?
	local origin = rig.Chassis.Position
	local best, bestDist = nil, REACH
	for _, model in CollectionService:GetTagged("Liftable") do
		local chassis = model.PrimaryPart
		local seat = model:FindFirstChild("Seat")
		if chassis and chassis.Parent and not chassis.Anchored and not model:GetAttribute("Crushing") and not (seat and seat.Occupant) then
			local offset = chassis.Position - origin
			local dist = offset.Magnitude
			if offset.Y < -2 and dist < bestDist then
				best, bestDist = model, dist
			end
		end
	end
	return best
end

local function toggle(player: Player, vehicles)
	local rig = vehicles.getVehicle(player)
	if not rig or not rig.CanLift or not rig.Seat.Occupant then
		return
	end
	if rig.Chassis.Parent:GetAttribute("Wrecked") then
		release(rig)
		return
	end
	if rig.Carry then
		release(rig)
		notify:FireClient(player, "Released")
		return
	end

	local target = findTarget(rig)
	if not target then
		notify:FireClient(player, "No car below (fly lower)")
		return
	end

	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.new(0, -rig.Def.Size.Y / 2, 0)
	att0.Parent = rig.Chassis
	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, target.PrimaryPart.Size.Y / 2, 0)
	att1.Parent = target.PrimaryPart
	local rope = Instance.new("RopeConstraint")
	rope.Attachment0 = att0
	rope.Attachment1 = att1
	rope.Length = math.clamp((att0.WorldPosition - att1.WorldPosition).Magnitude, 8, 25)
	rope.Visible = true
	rope.Thickness = 0.3
	rope.Color = BrickColor.new("Bright yellow")
	rope.Parent = rig.Chassis
	pcall(function()
		target.PrimaryPart:SetNetworkOwner(player)
	end)

	rig.Carry = { Rope = rope, Att0 = att0, Att1 = att1 }
	EventService.add(player, "cars_lifted", 1)
	notify:FireClient(player, "Hooked! Press F to release")
end

function LiftService.init(vehicles)
	Remotes.get("Winch").OnServerEvent:Connect(function(player)
		toggle(player, vehicles)
	end)
end

return LiftService
