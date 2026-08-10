# Kenney CC0 灰盒素材取得紀錄

> 日期：2026-08-10（Asia/Taipei）
> 路線：M（最低風險 MVP）
> 範圍：只取得可供 coding 進行環境灰盒與構圖驗證的官方 CC0 檔案。

## 已取得內容

來源為 Kenney 官方 [Top-down Shooter](https://kenney.nl/assets/top-down-shooter) 資產頁。該頁標示 Creative Commons CC0；內附 `License.txt` 亦明示可用於個人與商業專案。

目錄：`godot/BGiDesktop/assets/third_party/kenney_top_down_shooter/`

| 檔案 | 用途 | 尺寸／版本識別 | SHA-256 |
| --- | --- | --- | --- |
| `tilesheet_complete.png` | 環境灰盒 tile sheet | 1728×1280 | `A3075EAC400EF369686246A3CB0CC14E6356DF25E0C2C128B13EF94EC4A5BA45` |
| `spritesheet_tiles.png` | 環境灰盒圖集 | 1988×1470 | `B80AE9A10B1CABEC61FD68CCCAFAEF422B1FC5738F68C175F058F07E94B6F172` |
| `LICENSE-Kenney-Top-Down-Shooter.txt` | CC0 授權文字 | 原包 `License.txt` 複本 | `523B1CF39AD1D569CC5D6ABC9E8785668208B9C37F1E29383E2A5F8DDA8444BC` |

同目錄的 `README.md` 固定記錄來源、授權、用途邊界與完整性資料。

## 允許與禁止用途

| 狀態 | 用途 |
| --- | --- |
| 可用 | 場景灰盒、中央畫面構圖、透明桌面 UI 的遮擋／可讀性驗證。 |
| 不可用 | 「高架線與霧金天際線」最終背景、成品前景掛件、角色、武器、黑市商品、產品識別。 |
| 未取得 | 原包的角色與武器圖像；不讓其進入本案可用素材範圍。 |

這批檔案不會決定背景、掛件、動態插槽或遊戲數值。coding 只能把它當為暫時的環境 placeholder；成品美術仍等待原創或另行核准的生成／授權方案。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 目標 | 依已核准方案 M，先取得可合法使用的 CC0 環境灰盒素材供 coding 使用。 |
| 官方證據 | Kenney 資產頁標示 CC0；內附授權文字明示可商用。 |
| 產出 | 兩個環境圖集、授權文字、README 與 SHA-256 完整性記錄。 |
| 驗證 | 完成 ZIP 目錄安全檢查；環境圖集尺寸可讀；授權文字存在；研究檔與 README 完整。 |
| 邊界 | 未導入角色／武器內容；未改 Godot 程式、場景、設定或 Git；本批不能當最終美術。 |
| 下一步 | coding 可用此目錄進行灰盒場景驗證。實際遊戲內容明確後，使用者可提供素材 URL，或指定生成工具，再逐項進行商用權利與成品風格研究。 |
