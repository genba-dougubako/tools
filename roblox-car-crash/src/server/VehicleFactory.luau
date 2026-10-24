-- 乗り物の種類ごとのビルダーへの窓口。新しい種類(船など)を足すときはここに登録する。
local AircraftBuilder = require(script.Parent.AircraftBuilder)
local CarBuilder = require(script.Parent.CarBuilder)

local builders = {
	car = CarBuilder,
	plane = AircraftBuilder,
	heli = AircraftBuilder,
}

local VehicleFactory = {}

-- 標準色で塗られた部品に印を付けておき、塗装のときはそれだけ塗り替える
function VehicleFactory.paint(model: Model, color: Color3)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Paintable") then
			part.Color = color
		end
	end
end

-- 戻り値の rig は共通インターフェース: Kind, Def, Chassis, Seat, Deformables(操縦は Shared/VehicleControl)
function VehicleFactory.build(def, cf: CFrame, ownerUserId: number?, ownerName: string?, paint: Color3?)
	local model, rig = builders[def.Kind].build(def, cf, ownerUserId, ownerName)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Color == def.Color then
			part:SetAttribute("Paintable", true)
		end
	end
	if paint then
		VehicleFactory.paint(model, paint)
	end
	return model, rig
end

function VehicleFactory.rideHeight(def): number
	return builders[def.Kind].rideHeight(def)
end

return VehicleFactory
