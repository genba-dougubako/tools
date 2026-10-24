return {
	GameTitle = "CRUSH & FLY",
	GameSubtitle = "クラッシュ＆フライ",

	StartCash = 500,
	StartCars = { "sedan", "trainer" },

	-- 衝撃判定: ImpactWindow 秒間の速度変化がこの値(studs/s)を超えたらクラッシュ
	ImpactThreshold = 30,
	ImpactWindow = 0.15,
	ImpactCooldown = 0.25,
	SpawnGrace = 1.5,

	-- 報酬
	CashPerDamage = 3, -- 自分の車が壊れた分
	HitCashPerDamage = 6, -- 自分がぶつけて壊した分(他人の車・ダミー車)
	HitCredit = 1.5, -- 最後に接触してから何秒以内なら「ぶつけた」扱いか
	WreckBonus = 150,

	-- 車の挙動(挙動が逆なら 1 <-> -1 を切り替える)
	DriveSign = 1,
	SteerSign = 1,
	MaxSteerAngle = 30,

	-- ドリフト(ボタンなし。急なハンドル操作で入る)
	DriftMinSpeed = 45, -- これ以上の速度(studs/s ≒ km/h)でないと入らない
	DriftExitSpeed = 25, -- これより遅くなると終わる
	DriftFlickChange = 1.5, -- 切り返し: 左右逆向きにこれだけ変化したら(-1→+1 なら 2)
	DriftFlickWindow = 0.25, -- …この秒数以内に
	DriftSnapChange = 0.9, -- 急ハンドル: これだけ一気に切ったら
	DriftSnapWindow = 0.08, -- …この秒数以内に
	DriftSnapSpeedRatio = 0.6, -- 急ハンドルは最高速度のこの割合以上のときだけ
	DriftRearFriction = 0.35, -- ドリフト中の後輪の摩擦(普段は 2.2)
	DriftYawRate = 2.2, -- ドリフト中に車体を回す速さ(rad/s)
	DriftYawResponse = 4,

	-- 空のリング
	RingReward = 10,
	RingComboBonus = 3, -- コンボ1段ごとの加算(最大 RingComboMax 段)
	RingComboMax = 5,
	RingComboWindow = 6, -- この秒数以内に次を通るとコンボ継続
	RingTimeout = 15, -- この秒数以内に次を通れないとコースをやり直し
	CourseBonus = 100,

	-- 国産 vs 海外 対決戦(秒)
	ShowdownFirstDelay = 60,
	ShowdownInterval = 600,
	ShowdownDuration = 180,

	-- プレス機
	PressReward = 100,

	-- 右上の地図(ワールド座標の中心と、中心から端までの距離 studs)
	MinimapCenter = Vector3.new(60, 0, -170),
	MinimapRange = 320,
	HidePlayerList = true, -- 右上の標準プレイヤー一覧を隠して地図を角に置く

	AutoSaveInterval = 60,
	DataStoreName = "CarCrashV1",
}
