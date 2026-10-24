-- 運転中の乗り物を「この端末で」操縦する。
-- 物理を計算している端末で直接動かすので、携帯でもガタつかない。
-- W/S/A/D(携帯はスティック)は VehicleSeat から読む。上下は E/Shift・Q/Ctrl か画面ボタン。
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("VehicleCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local VehicleControl = require(Shared:WaitForChild("VehicleControl"))

local player = Players.LocalPlayer
local winchRemote = Remotes.get("Winch")

local rig = nil -- 今操縦している乗り物
local touchUp, touchDown = false, false

-- ===== 携帯用ボタン(飛行機・ヘリに乗っているときだけ表示) =====
local gui = Instance.new("ScreenGui")
gui.Name = "FlightControls"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function touchButton(label: string, position: UDim2, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 1)
	b.Position = position
	b.Size = UDim2.fromOffset(84, 64)
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.25
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = label
	b.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = b
	b.Parent = gui
	return b
end

-- 右下のジャンプボタンと重ならないよう、その上に並べる
local upButton = touchButton("▲", UDim2.new(1, -110, 1, -250), Color3.fromRGB(40, 140, 220))
local downButton = touchButton("▼", UDim2.new(1, -110, 1, -175), Color3.fromRGB(60, 60, 70))
local winchButton = touchButton("吊る", UDim2.new(1, -205, 1, -175), Color3.fromRGB(220, 170, 30))

local function hold(button: TextButton, set: (boolean) -> ())
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			set(true)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			set(false)
		end
	end)
end
hold(upButton, function(on)
	touchUp = on
end)
hold(downButton, function(on)
	touchDown = on
end)
winchButton.Activated:Connect(function()
	winchRemote:FireServer()
end)

-- ドリフト表示
local driftLabel = Instance.new("TextLabel")
driftLabel.AnchorPoint = Vector2.new(0.5, 1)
driftLabel.Position = UDim2.new(0.5, 0, 1, -90)
driftLabel.Size = UDim2.fromOffset(260, 40)
driftLabel.BackgroundTransparency = 1
driftLabel.Font = Enum.Font.GothamBlack
driftLabel.TextScaled = true
driftLabel.TextColor3 = Color3.fromRGB(255, 120, 200)
driftLabel.TextStrokeTransparency = 0.3
driftLabel.Visible = false
local driftGui = Instance.new("ScreenGui")
driftGui.Name = "DriftHUD"
driftGui.ResetOnSpawn = false
driftGui.Parent = player:WaitForChild("PlayerGui")
driftLabel.Parent = driftGui

-- ===== 乗っている乗り物を探す =====
local function currentVehicle(): Model?
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") and seat.Name == "Seat" then
		return seat.Parent
	end
	return nil
end

local function liftInput(): number
	local up = touchUp or UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local down = touchDown or UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
	return (up and 1 or 0) - (down and 1 or 0)
end

RunService.Heartbeat:Connect(function(dt)
	local model = currentVehicle()

	-- 降りた/乗り換えた: 前の乗り物の動力を切る
	if rig and (not model or rig.Chassis.Parent ~= model) then
		VehicleControl.idle(rig)
		rig = nil
		touchUp, touchDown = false, false
	end

	if model and not rig then
		local def = Catalog.ById[model:GetAttribute("CarId")]
		rig = VehicleControl.fromModel(model, def, { player.Character })
		if rig then
			local air = rig.Kind ~= "car"
			gui.Enabled = air and UserInputService.TouchEnabled
			upButton.Text = rig.Kind == "plane" and "加速" or "上昇"
			downButton.Text = rig.Kind == "plane" and "減速" or "下降"
			winchButton.Visible = model:GetAttribute("CanLift") == true
		end
	end
	if not rig then
		gui.Enabled = false
		driftLabel.Visible = false
		return
	end
	if model:GetAttribute("Crushing") or rig.Chassis.Anchored then
		return
	end

	VehicleControl.update(rig, dt, {
		Throttle = rig.Seat.ThrottleFloat,
		Steer = rig.Seat.SteerFloat,
		Lift = liftInput(),
	})

	local drift = VehicleControl.driftTime(rig)
	driftLabel.Visible = drift ~= nil
	if drift then
		driftLabel.Text = string.format("DRIFT %.1fs", drift)
	end
end)

-- F: ウインチ(吊れる機体かどうかはサーバーが判定)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F and rig and rig.Kind == "heli" then
		winchRemote:FireServer()
	end
end)
