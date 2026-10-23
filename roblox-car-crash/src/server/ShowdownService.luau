-- 国産 vs 海外 対決戦: 一定間隔でラウンドが始まり、制限時間内にプレスで潰した車の
-- デザイン(国産系/海外系)ごとに点が入る。勝った側に貢献したプレイヤーがイベントをクリアする。
-- 状態は ReplicatedStorage.Showdown の属性でクライアントに見せる。
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local EventService = require(script.Parent.EventService)

local ShowdownService = {}

local TEAM_NAME = { jp = "DOMESTIC", os = "IMPORT" }

local state = Instance.new("Folder")
state.Name = "Showdown"

local active = false
local scores = { jp = 0, os = 0 }
local contributors = { jp = {}, os = {} }

local notify = Remotes.get("Notify")

local function publish()
	state:SetAttribute("Active", active)
	state:SetAttribute("ScoreJP", scores.jp)
	state:SetAttribute("ScoreOS", scores.os)
end

local function broadcast(message: string)
	for _, player in Players:GetPlayers() do
		notify:FireClient(player, message)
	end
end

function ShowdownService.score(player: Player, origin: string?, points: number)
	if not active or not origin or not scores[origin] then
		return
	end
	scores[origin] += points
	contributors[origin][player] = true
	publish()
end

local function runRound()
	scores = { jp = 0, os = 0 }
	contributors = { jp = {}, os = {} }
	active = true
	state:SetAttribute("EndsAt", workspace:GetServerTimeNow() + Config.ShowdownDuration)
	publish()
	broadcast("SHOWDOWN START! Crush domestic or import cars in the press")

	task.wait(Config.ShowdownDuration)

	active = false
	publish()
	local winner = scores.jp > scores.os and "jp" or (scores.os > scores.jp and "os" or nil)
	if not winner then
		broadcast("SHOWDOWN: draw")
		return
	end
	broadcast(`SHOWDOWN: {TEAM_NAME[winner]} wins {scores[winner]}-{scores[winner == "jp" and "os" or "jp"]}!`)
	for player in contributors[winner] do
		if player.Parent then
			EventService.add(player, "showdown_win", 1)
		end
	end
end

function ShowdownService.init()
	state.Parent = ReplicatedStorage
	publish()
	task.spawn(function()
		local delay = Config.ShowdownFirstDelay
		while true do
			state:SetAttribute("NextAt", workspace:GetServerTimeNow() + delay)
			task.wait(delay)
			local ok, err = pcall(runRound)
			if not ok then
				active = false
				publish()
				warn(`Showdown failed: {err}`)
			end
			delay = Config.ShowdownInterval
		end
	end)
end

return ShowdownService
