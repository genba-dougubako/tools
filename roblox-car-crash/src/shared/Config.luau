return {
	StartCash = 500,
	StartCars = { "sedan" },

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

	AutoSaveInterval = 60,
	DataStoreName = "CarCrashV1",
}
