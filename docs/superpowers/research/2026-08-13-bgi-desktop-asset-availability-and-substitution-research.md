# BGi Desktop 素材可用性與替代建議盤點

> 日期：2026-08-13（Asia/Taipei）
> 範圍：唯讀盤點方案 M 下已存在的實體素材、素材研究與 `docs/assets` 規則；不下載、購買、生成、導入、移動或刪除素材。

## 1. 判讀原則

- `docs/operations/ASSET_POLICY.md` 是目前採用政策：Phosphor MIT 與 Kenney CC0 僅屬候選或灰盒來源；未經後續明確決策，不得取得或導入成品素材。
- `docs/assets/README.md` 要求來源、授權證據、用途邊界、雜湊與審核結果可追溯；候選清單不等於檔案已在專案內。
- 本報告將「能合法灰盒使用」與「能合法作成品使用」分開。後者需要台帳達到 `ready_to_import`，並具備檔案與授權證據。

## 2. 已存在實體素材

| 素材／位置 | 可追溯證據 | 目前狀態 | 可合法灰盒用途 | 不可導入成品範圍 |
| --- | --- | --- | --- | --- |
| `godot/BGiDesktop/assets/third_party/kenney_top_down_shooter/tilesheet_complete.png` | 包內 `LICENSE-Kenney-Top-Down-Shooter.txt`、`README.md`；既有 Kenney intake 研究 | `greybox_approved` | 環境灰盒、構圖、桌面比例與介面驗證 | 正式霧金天際線、前景掛件、五名小弟、武器、產品識別 |
| `godot/BGiDesktop/assets/third_party/kenney_top_down_shooter/spritesheet_tiles.png` | 同上 | `greybox_approved` | 同上 | 同上 |
| `spritesheet_characters.xml` | 同一素材包的描述檔；未見對應角色影像取得紀錄 | 不列為可用視覺素材 | 不使用 | 角色、成品與灰盒角色皆不以此檔作來源 |

## 3. 待驗證或尚未取得的來源

| 來源群組 | 已有研究／決策證據 | 狀態 | 待驗證事項 | 在驗證前的界線 |
| --- | --- | --- | --- | --- |
| Phosphor icon | `2026-08-10-bgi-desktop-asset-license-and-import-decision.md`、UI icon 候選研究 | `research_only`／候選 | 實際選用圖示、版本、檔案雜湊、notice 與用途 | 不下載、不導入；可在文件中保留語意對照 |
| Wenrexa CC0 UI 候選 | itch.io UI 候選清單 | `research_only`／候選 | 具體素材包、取得檔、包內授權、SHA-256、黑金重著色用途 | 不作成品或 Godot 資源 |
| GameArt2D Temple Run | 天際線 PRD 可行性研究 | `eligible` | 實際素材包、包內授權與中性靜態幀選擇 | 不作五名小弟的實體素材 |
| 其餘 itch.io UI／icon 候選 | itch.io UI 候選清單 | `research_only`、`prototype_only` 或依來源個別限制 | 免費檔實際範圍、商用條款、署名、收據或授權文字 | 不得視為已取得；`prototype_only` 不得進公開或發行包 |
| 使用者人工確認的 MJv6.1 羽毛、戒指、龍蛋候選 | 既有素材盤點表與先前人工確認紀錄 | 人工確認待實檔 | 原始來源、確認日期與範圍、取得檔與 SHA-256 | 不因人工確認省略台帳；未取得前不導入 |

## 4. 第一輪替代建議

### UI

| 需要 | 現在可用替代 | 待驗證後的候選方向 | 邊界 |
| --- | --- | --- | --- |
| 底部常駐列、任務／黑市／收藏／裝備窗 | Godot 既有文字、色彩 token 與 Kenney 灰盒構圖 | 24 Karat GUI 的黑金 Art Deco 語言，或 Nesía 01／Wenrexa CC0 的可切分面板 | 現階段只用文字與形狀表達狀態；不得將候選 UI 圖檔納入專案 |
| 功能 icon | 文字標籤、幾何符號、既有 UI 狀態色 | Phosphor（功能）、Wenrexa Hologram（局部 icon）、Ravenmore（資源 icon） | icon 不能單獨承擔可用、派遣中、可領取或稀有度辨識 |
| 稀有度與獎勵 | 文字名稱、色條、邊框粗細與數值標籤 | 使用者人工確認的羽毛、戒指、龍蛋 item 圖示 | 取得前不顯示圖檔；未來 item 圖示僅為獎勵／收藏，不取代文字類型 |

### 環境與角色

| 需要 | 現在可用替代 | 待驗證後的候選方向 | 邊界 |
| --- | --- | --- | --- |
| 高架線與霧金天際線 | Kenney tiles 只作構圖比例、深淺區塊與畫面留白測試 | 依原始美術交付規格製作 `BG_SKYLINE_BASE`／`BG_SKYLINE_FX` | Kenney tile 不可出現在正式背景、裝飾或品牌畫面 |
| 可拖放前景掛件 | 色塊、輪廓框、文字代號與預設錨點 | 原始掛件交付規格的 `FG_HANGER_WORLD`／`FG_HANGER_FX` | 背景替換不得改變掛件位置或效果；灰盒不等於成品掛件 |
| 五名同外觀小弟 | 五個相同抽象輪廓與狀態 ring／文字 | GameArt2D Temple Run 的中性幀，或日後明確取得的原始角色 | 不使用 Kenney 角色描述檔；派遣狀態須有色彩以外的區別 |

## 5. 取得與導入前的最小證據包

任何待驗證候選轉為可導入前，需依 `docs/assets/ASSET_LEDGER_TEMPLATE.md` 補齊：名稱、類型、來源 URL、作者／發行者、授權證據 URL、商用／修改條件、狀態、SHA-256、用途邊界、人工確認者與日期。完成後再依 `docs/assets/README.md` 的導入前檢核，確認與跨裝置副本雜湊一致。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 範圍 | 方案 M 下的唯讀素材盤點與第一輪替代建議。 |
| 可灰盒 | 僅 Kenney Top-down Shooter 的兩張 tile 圖；用途限環境構圖與介面驗證。 |
| 不可成品 | Kenney 不得進正式背景、掛件、角色、武器或產品識別；所有未取得候選也不得進成品。 |
| 待驗證 | Phosphor、Wenrexa、GameArt2D、其餘 itch.io 候選及使用者人工確認 item 候選，均仍需來源／授權／檔案台帳與 SHA-256。 |
| 產出 | 本文件；未新增或變更任何素材、Godot 或 Git。 |
| 下一步 | 取得任一素材前，先以 `docs/assets/ASSET_LEDGER_TEMPLATE.md` 建立對應台帳並完成導入前檢核。 |
