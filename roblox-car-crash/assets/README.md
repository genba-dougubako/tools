# ゲームのアイコン・サムネイル

| ファイル | 用途 | サイズ |
| --- | --- | --- |
| `icon-512.png` | ゲームのアイコン(Roblox の「アイコン」) | 512×512 |
| `thumbnail-1920x1080.png` | ゲームページのサムネイル | 1920×1080 |

- 絵はすべて自作の図形(実在の車・ブランドは描いていない)。
- 字体: Bungee、Dela Gothic One(どちらも Google Fonts、SIL Open Font License)。

## 作り直し方
`source/` の HTML が元データ。字体の CSS(`en.css` / `jp.css`)を Google Fonts から取得して同じフォルダに置き、
Playwright で `node render.js` を実行すると PNG が出力される。文字や色は HTML を直接書き換える。

## Roblox への設定(公開前に本人が行う)
Creator Hub → 対象の体験 → 「Places / Basic Info」でアイコンとサムネイルをアップロードする。
アップロードは Roblox のモデレーション(審査)を通る。
