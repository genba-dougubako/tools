local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local axisRemote = Remotes.get("FlightAxis")

-- W/S/A/D は VehicleSeat が拾う。ここでは上下(加速/上昇)の入力だけを送る。
-- Space はシートから降りてしまうので使わない。
local lastAxis = 0
local lastSent = 0

RunService.Heartbeat:Connect(function()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat:IsA("VehicleSeat") and seat.Parent
	local kind = model and model:GetAttribute("Kind")

	local axis = 0
	if kind == "plane" or kind == "heli" then
		local up = UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		local down = UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
		axis = (up and 1 or 0) - (down and 1 or 0)
	end

	local now = os.clock()
	if axis ~= lastAxis or (axis ~= 0 and now - lastSent > 0.25) then
		lastAxis = axis
		lastSent = now
		axisRemote:FireServer(axis)
	end
end)
