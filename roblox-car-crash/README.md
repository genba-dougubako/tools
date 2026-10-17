# Car Crash (Roblox) — Car Crushers 2 系プロトタイプ

車を運転して、壁・ジャンプ台・ダミー車に突っ込んで壊し、その分だけお金がもらえる → 新しい車を買う、というゲームの土台です。
車は全部コード(Part + 拘束)で組み立てているので、外部アセットは不要です。

## セットアップ

1. [Rojo](https://rojo.space/) をインストール(Studio プラグイン + CLI)
2. このフォルダで `rojo serve` → Studio の Rojo プラグインから Connect
   (または `rojo build -o CarCrash.rbxl` で place ファイルを作る)
3. Studio の Game Settings → Security で **Enable Studio Access to API Services** をオンにするとセーブも試せます(オフでも動作はします)

## 遊び方

- スポーン後、画面左の **GARAGE → SPAWN** で車を出す(最初は Rusty Sedan のみ)
- `W/S` or 矢印: アクセル/ブレーキ、`A/D`: ハンドル、`R`: 車をリセット(修理)
- 壁・バリア・ダミー車・ジャンプ台で衝突 → ダメージに応じて `$` が貯まる
- 他プレイヤーやダミー車を壊すと `SMASH` ボーナス、撃破で `WRECKED!` ボーナス
- 貯めたお金で GARAGE から新しい車を購入

## プレス機(車を潰して +100 コイン)

- スポーン地点の東に大型プレス機があり、操作盤の赤ボタン(`Start Press`)で作動
- 自分の車をプレス内に停めて押す → 警告灯 → 打ち下ろし → 火花/煙/カメラ揺れ → `+100 COINS` → 車を入口の外に再出現
- 判定はすべてサーバー側(車の所有者、プレス内に収まっているか、距離、占有中か、二重報酬防止)
- 検証手順は `STUDIO_TEST_CHECKLIST.md` を参照

## 構成

| ファイル | 役割 |
| --- | --- |
| `src/shared/Config.luau` | 報酬・衝撃しきい値・操作感の調整値 |
| `src/shared/CarCatalog.luau` | 車種の定義(ここに足せば車が増える) |
| `src/server/CarBuilder.luau` | 車体・タイヤ・ステア・駆動の生成と操作 |
| `src/server/DamageService.luau` | 衝突検知、パーツの変形/脱落、体力、報酬、爆発 |
| `src/server/CarService.luau` | スポーン/購入/リセット、VehicleSeat 入力の反映 |
| `src/server/DataService.luau` | DataStore によるお金・所持車のセーブ |
| `src/server/PressService.luau` | プレス機の生成、作動の検証、潰れ演出、コイン付与、車の再出現 |
| `src/client/Effects.client.luau` | プレス時のカメラ揺れ |
| `src/server/MapBuilder.luau` | テストマップ(道路、ジャンプ台、レンガ壁、巨大壁、ダミー車) |
| `src/client/HUD.client.luau` | 所持金、速度/体力、ガレージ UI、獲得トースト |

## 衝突ダメージの仕組み

毎フレームの車体速度を `ImpactWindow` 秒ぶん記憶し、その間の速度変化が `ImpactThreshold` を超えたらクラッシュ扱い。
速度変化の向き = ぶつかった方向なので、その付近の車体パーツ(`Weld.C0`)を凹ませ、大きい衝撃ではパーツを外します。

## 調整ポイント(未テストの部分)

Studio 外で書いたため実機未検証です。最初に確認してほしい点:

- **前進/ハンドルが逆**: `Config.DriveSign` / `Config.SteerSign` を `-1` に
- **すぐ壊れる/壊れない**: `ImpactThreshold`、車ごとの `DamageScale`
- **稼ぎすぎ/少なすぎ**: `CashPerDamage`、`HitCashPerDamage`

## 次にやると良いこと

- サスペンション(SpringConstraint)と見た目のタイヤ回転
- 本格的な車モデルへの差し替え(`CarBuilder.build` の Rig 構造を保てばOK)
- 爆発/ロケット/落下エリアなどの「壊す」ギミック、ワールド拡張、ミッション、ランキング
