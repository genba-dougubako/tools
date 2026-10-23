local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("VehicleCatalog"))
local EventCatalog = require(Shared:WaitForChild("EventCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local spawnRemote = Remotes.get("SpawnCar")
local buyRemote = Remotes.get("BuyCar")
local resetRemote = Remotes.get("ResetCar")
local notifyRemote = Remotes.get("Notify")

local KIND_LABEL = { car = "CAR", plane = "PLANE", heli = "HELI" }

local function new(class: string, props: { [string]: any }, parent: Instance?)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local gui = new("ScreenGui", { Name = "CarCrashHUD", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

local function text(props: { [string]: any }, parent: Instance)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextStrokeTransparency = 0.5,
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base, parent)
end

local function button(props: { [string]: any }, parent: Instance)
	local base = {
		BackgroundColor3 = Color3.fromRGB(40, 40, 48),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		AutoButtonColor = true,
	}
	for k, v in props do
		base[k] = v
	end
	local b = new("TextButton", base, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	return b
end

local function panelFrame(position: UDim2)
	local panel = new("ScrollingFrame", {
		Position = position,
		Size = UDim2.fromOffset(340, 320),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, panel)
	return panel
end

local function clearRows(panel: ScrollingFrame)
	for _, child in panel:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function row(panel: ScrollingFrame, order: number, height: number)
	local frame = new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Color3.fromRGB(40, 40, 48),
	}, panel)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
	return frame
end

-- 上部: 現金 / コイン / リング進行
local cashLabel = text({
	Position = UDim2.new(0.5, -110, 0, 10),
	Size = UDim2.fromOffset(220, 36),
	TextColor3 = Color3.fromRGB(120, 255, 120),
}, gui)
local coinsLabel = text({
	Position = UDim2.new(0.5, -110, 0, 48),
	Size = UDim2.fromOffset(220, 30),
	TextColor3 = Color3.fromRGB(255, 220, 60),
}, gui)
local ringLabel = text({
	Position = UDim2.new(0.5, -110, 0, 80),
	Size = UDim2.fromOffset(220, 26),
	TextColor3 = Color3.fromRGB(120, 220, 255),
	Visible = false,
}, gui)

-- 下部: 速度 / 高度 / 体力
local stats = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(300, 64),
	BackgroundColor3 = Color3.fromRGB(20, 20, 24),
	BackgroundTransparency = 0.3,
	Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, stats)
local speedLabel = text({ Size = UDim2.new(1, 0, 0, 34) }, stats)
local healthBack = new("Frame", {
	Position = UDim2.new(0, 10, 1, -20),
	Size = UDim2.new(1, -20, 0, 12),
	BackgroundColor3 = Color3.fromRGB(60, 0, 0),
	BorderSizePixel = 0,
}, stats)
local healthFill = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(80, 220, 80),
	BorderSizePixel = 0,
}, healthBack)

-- 左: メニュー
local garageButton = button({
	Position = UDim2.new(0, 10, 0.5, -80),
	Size = UDim2.fromOffset(130, 40),
	Text = "GARAGE",
}, gui)
local eventsButton = button({
	Position = UDim2.new(0, 10, 0.5, -34),
	Size = UDim2.fromOffset(130, 40),
	Text = "EVENTS",
}, gui)
local resetButton = button({
	Position = UDim2.new(0, 10, 0.5, 12),
	Size = UDim2.fromOffset(130, 40),
	Text = "RESET (R)",
}, gui)

local garagePanel = panelFrame(UDim2.new(0, 150, 0.5, -80))
local eventsPanel = panelFrame(UDim2.new(0, 150, 0.5, -80))

local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")

local function ownedSet()
	local owned = {}
	for id in string.gmatch(player:GetAttribute("Owned") or "", "[^,]+") do
		owned[id] = true
	end
	return owned
end

local function refreshGarage()
	clearRows(garagePanel)
	local owned = ownedSet()

	for i, def in Catalog.Vehicles do
		local frame = row(garagePanel, i, 56)
		text({
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.new(0.58, 0, 0, 24),
			Text = def.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, frame)

		local event = def.RequiresEvent and EventCatalog.ById[def.RequiresEvent]
		local unlocked = not def.RequiresEvent or player:GetAttribute(`Done_{def.RequiresEvent}`) == true
		local sub = KIND_LABEL[def.Kind] or ""
		if not owned[def.Id] and not unlocked and event then
			sub ..= `  |  Clear: {event.Name}`
		end
		text({
			Position = UDim2.fromOffset(8, 30),
			Size = UDim2.new(0.58, 0, 0, 18),
			Text = sub,
			TextColor3 = Color3.fromRGB(170, 170, 180),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, frame)

		local isOwned = owned[def.Id]
		local label, color
		if isOwned then
			label, color = "SPAWN", Color3.fromRGB(40, 120, 200)
		elseif not unlocked then
			label, color = "LOCKED", Color3.fromRGB(90, 90, 95)
		elseif cash.Value >= def.Price then
			label, color = `BUY ${def.Price}`, Color3.fromRGB(40, 160, 70)
		else
			label, color = `BUY ${def.Price}`, Color3.fromRGB(110, 50, 50)
		end
		local action = button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.new(0.36, 0, 0, 36),
			Text = label,
			BackgroundColor3 = color,
		}, frame)
		action.Activated:Connect(function()
			if isOwned then
				spawnRemote:FireServer(def.Id)
			else
				buyRemote:FireServer(def.Id) -- 未解放などの判定はサーバー側
			end
		end)
	end
end

local function refreshEvents()
	clearRows(eventsPanel)
	for i, event in EventCatalog.Events do
		local lines = #event.Requirements + 2
		local frame = row(eventsPanel, i, 22 * lines + 8)
		local done = player:GetAttribute(`Done_{event.Id}`) == true

		local title = event.Name
		if event.Status == "planned" then
			title ..= "  (COMING SOON)"
		elseif done then
			title ..= "  - CLEARED"
		end
		text({
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.new(1, -16, 0, 20),
			Text = title,
			TextColor3 = done and Color3.fromRGB(120, 255, 120) or Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, frame)
		text({
			Position = UDim2.fromOffset(8, 26),
			Size = UDim2.new(1, -16, 0, 18),
			Text = event.Description,
			TextColor3 = Color3.fromRGB(170, 170, 180),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, frame)
		for j, req in event.Requirements do
			local value = math.min(player:GetAttribute(`Stat_{req.Stat}`) or 0, req.Target)
			text({
				Position = UDim2.fromOffset(16, 26 + 22 * j),
				Size = UDim2.new(1, -24, 0, 18),
				Text = `{req.Label or req.Stat}: {value}/{req.Target}`,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, frame)
		end
	end
end

local function showPanel(which: ScrollingFrame)
	local show = not which.Visible
	garagePanel.Visible = false
	eventsPanel.Visible = false
	which.Visible = show
end

garageButton.Activated:Connect(function()
	showPanel(garagePanel)
end)
eventsButton.Activated:Connect(function()
	showPanel(eventsPanel)
end)
resetButton.Activated:Connect(function()
	resetRemote:FireServer()
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.R then
		resetRemote:FireServer()
	end
end)

-- 属性(所持車/統計/クリア状況/リング進行)が変わったら再描画
local function refreshAll()
	cashLabel.Text = `$ {cash.Value}`
	refreshGarage()
	refreshEvents()
	local total = player:GetAttribute("RingTotal")
	local nextRing = player:GetAttribute("RingNext")
	if total and nextRing and nextRing > 1 then
		ringLabel.Text = `RINGS {nextRing - 1}/{total}`
		ringLabel.Visible = true
	else
		ringLabel.Visible = false
	end
end
player.AttributeChanged:Connect(refreshAll)
cash.Changed:Connect(refreshAll)
refreshAll()

-- 通知
notifyRemote.OnClientEvent:Connect(function(message: string)
	local toast = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, math.random(-60, 60), 0.3, 0),
		Size = UDim2.fromOffset(340, 40),
		Text = message,
		TextColor3 = Color3.fromRGB(255, 230, 80),
	}, gui)
	local tween = TweenService:Create(toast, TweenInfo.new(1.4), {
		Position = toast.Position - UDim2.fromOffset(0, 60),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	Debris:AddItem(toast, 1.5)
end)

-- 速度 / 高度 / 体力
RunService.RenderStepped:Connect(function()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local car = seat and seat:IsA("VehicleSeat") and seat.Parent
	local chassis = car and car:FindFirstChild("Chassis")
	stats.Visible = chassis ~= nil
	if not chassis then
		return
	end

	-- 1 stud ~ 0.28 m
	local kmh = math.floor(chassis.AssemblyLinearVelocity.Magnitude * 0.28 * 3.6)
	local kind = car:GetAttribute("Kind")
	if kind == "plane" or kind == "heli" then
		speedLabel.Text = `{kmh} km/h   ALT {math.floor(chassis.Position.Y * 0.28)} m`
	else
		speedLabel.Text = `{kmh} km/h`
	end
	local ratio = math.clamp((car:GetAttribute("Health") or 0) / (car:GetAttribute("MaxHealth") or 1), 0, 1)
	healthFill.Size = UDim2.fromScale(ratio, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(220 * (1 - ratio) + 40, 220 * ratio + 20, 40)
end)

-- Coins
local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local function updateCoins()
	coinsLabel.Text = `COINS {coins.Value}`
end
coins.Changed:Connect(updateCoins)
updateCoins()
