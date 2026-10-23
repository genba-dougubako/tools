-- 乗り物の種類ごとのビルダーへの窓口。新しい種類(船など)を足すときはここに登録する。
local AircraftBuilder = require(script.Parent.AircraftBuilder)
local CarBuilder = require(script.Parent.CarBuilder)

local builders = {
	car = CarBuilder,
	plane = AircraftBuilder,
	heli = AircraftBuilder,
}

local VehicleFactory = {}

-- 戻り値の rig は共通インターフェース: Kind, Def, Chassis, Seat, Deformables, Update(rig, dt), Idle(rig)
function VehicleFactory.build(def, cf: CFrame, ownerUserId: number?, ownerName: string?)
	return builders[def.Kind].build(def, cf, ownerUserId, ownerName)
end

function VehicleFactory.rideHeight(def): number
	return builders[def.Kind].rideHeight(def)
end

return VehicleFactory
