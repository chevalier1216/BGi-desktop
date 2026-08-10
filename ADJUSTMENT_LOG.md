# BGi Desktop 調整日誌

## 記錄規則

- 僅記錄已核准的策劃或程式變更；未核准的提案不列為完成變更。
- 每筆記錄須包含日期時間、目標、檔案相對位置、行號與摘要、驗證結果、Git commit。
- 若不適用，填寫 `不適用` 並說明原因；不得臆測 commit、行號或驗證結果。
- GitHub repository 尚未建立前，不建立 repository，亦不修改產品功能。
- `G:\Projects\BGi-Desktop` 為唯一 canonical repository；`C:\Users\phil\Documents\ChatGPT\BGi-Desktop_codex` 僅保留副本，禁止寫入、清理或刪除。

| 日期時間（Asia/Taipei） | 類型 | 目標 | 檔案相對位置 | 行號與摘要 | 驗證結果 | Git commit |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-08-10 15:28 | 程式 | 建立純 GDScript 派遣規則模型與拒絕案例測試 | `godot/BGiDesktop/scripts/dispatch_rules.gd`；`godot/BGiDesktop/tests/dispatch_rules_test.gd` | `dispatch_rules.gd` 4–32：驗證隊伍人數 1–5、重複派遣、不存在小弟與非可用小弟；僅回傳驗證結果，不寫回狀態。`dispatch_rules_test.gd` 7–28：正常派遣、少於 1 人、超過 5 人、不存在小弟、非可用小弟與重複指派測試。 | Godot 4.7.1 以 `--headless --path G:\\Projects\\BGi-Desktop\\godot\\BGiDesktop --script res://tests/dispatch_rules_test.gd` 執行，結束碼 0；兩個新增檔案均通過 Git whitespace 檢查。 | `ba86c48` |
| 2026-08-10 15:24 | 程式 | 建立固定 23 項新手任務目錄與可讀任務清單骨架 | `godot/BGiDesktop/project.godot`；`godot/BGiDesktop/scripts/starter_mission_catalog.gd`；`godot/BGiDesktop/scripts/desktop_shell.gd`；`godot/BGiDesktop/scenes/desktop_shell.tscn`；`docs/superpowers/plans/2026-08-10-bgi-desktop-foundation-plan.md` | `project.godot` 10–13：註冊 `StarterMissionCatalog` 自動載入；`starter_mission_catalog.gd` 3–22：固定 23 項時長與預期分布，26–39：識別碼、未接受狀態與不替換刷新，41–53：完整性驗證；`desktop_shell.gd` 20–25、41–54：載入並格式化顯示任務資料；場景 115–126：23 項清單入口與唯讀捲動區；計畫 15–20：小目標。 | Godot 4.7.1 以 `--headless --path G:\\Projects\\BGi-Desktop\\godot\\BGiDesktop --editor --quit` 與 `--quit-after 5` 均結束碼 0，未輸出解析或執行期錯誤，固定目錄 assert 未觸發；指定來源的 Git whitespace 檢查通過。 | `c4948b8` |
| 2026-08-10 15:27 | 研究 | 完成「黑金桌上地盤模型」視覺資產盤點與提案 | `docs/superpowers/research/2026-08-10-bgi-desktop-visual-asset-inventory-and-proposal.md` | 1–5：研究與提案、未核准且不授權素材／Godot 變更；7–24：黑金桌上地盤模型與視覺 token；64–73：Phosphor Icons（MIT）為首選、Kenney CC0 僅場景原型；77–84：成品插圖待原創權利方案另核且核准前不下載、不導入；90–96：交接結論與限制。 | `a3b8d46` 僅新增研究 Markdown，未含素材檔或 Godot 變更；`ea7a5a4` 僅移除第 3、4 行 Markdown 尾端空白與原第 97 行檔尾空白行。清理後 `git diff --check -- <研究文件>` 與暫存區檢查均通過。 | `a3b8d46`；`ea7a5a4` |
| 2026-08-10 15:20 | 程式 | 建立 5 名初始小弟狀態模型與非文字狀態指示 | `godot/BGiDesktop/project.godot`；`godot/BGiDesktop/scripts/game_state.gd`；`godot/BGiDesktop/scripts/desktop_shell.gd`；`godot/BGiDesktop/scenes/desktop_shell.tscn`；`docs/superpowers/plans/2026-08-10-bgi-desktop-foundation-plan.md` | `project.godot` 10–12：註冊 `GameState` 自動載入；`game_state.gd` 3–21：三種狀態、固定 5 名初始小弟與唯讀複本介面；`desktop_shell.gd` 3–37：顏色圓點與提示渲染；場景 80–90：初始狀態與圓點容器；計畫 15–19：Git 專案位置與初始狀態小目標。 | Godot 4.7.1 以 `--headless --path G:\\Projects\\BGi-Desktop\\godot\\BGiDesktop --quit-after 5` 啟動主場景，結束碼 0、未輸出解析或執行期錯誤；指定已追蹤來源通過 `git diff --check`，未追蹤的 `game_state.gd` 以空基準 `git diff --no-index --check` 檢查通過。 | `c4948b8` |
| 2026-08-10 15:19 | 維運 | 確立 canonical repository 路徑政策 | `ADJUSTMENT_LOG.md` | 9：指定 `G:\\Projects\\BGi-Desktop` 為所有日誌、Git 與程式操作的唯一 canonical repository；C 槽副本僅保留且不得寫入、清理或刪除。 | 交接內容載明此路徑政策；本輪操作均在 `G:\\Projects\\BGi-Desktop` 執行。 | `7afa4b1` |
| 2026-08-10 15:19 | 維運 | 遷移 repository 至 `G:\\Projects\\BGi-Desktop` 並併入 Godot 原始碼 | `docs/superpowers/plans/2026-08-10-bgi-desktop-foundation-plan.md`；`godot/BGiDesktop/` | 計畫 5–22：定義 Windows 優先、工作列上方視窗與 Godot 載入驗證範圍；Godot 專案現存於 `godot/BGiDesktop/`，未納入其 `.godot/` 產物。 | `git rev-parse --show-toplevel` 回傳 `G:/Projects/BGi-Desktop`；`git check-ignore -v godot/BGiDesktop/.godot/editor/project_metadata.cfg` 命中 `.gitignore` 第 5 行。 | `c04b009` |
| 2026-08-10 15:19 | 程式 | 納入 Godot 桌面 UI 基礎框架 | `godot/BGiDesktop/project.godot`；`scenes/desktop_shell.tscn`；`scripts/desktop_shell.gd`；`scripts/desktop_window_controller.gd` | `project.godot` 5–29：主場景、Autoload、無框透明不可縮放視窗；`desktop_shell.tscn` 17–118：地盤、場景、任務 UI 結構；`desktop_shell.gd` 1–10：控制項繫結；`desktop_window_controller.gd` 3–46：工作列上方定位、置頂偏好與緊湊配置。 | 使用 Godot 4.7.1 以 `--headless --path G:\\Projects\\BGi-Desktop\\godot\\BGiDesktop --editor --quit` 載入，結束碼 0。提交前 `git diff --cached --check` 指出計畫、`project.godot`、場景與 `desktop_shell.gd` 各有 1 個檔尾空白行；未宣稱 whitespace 檢查通過。 | `c04b009` |
| 2026-08-10 15:03 | 策劃 | 核准目前設計規格為製作基準 | `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md` | 3–5：標示規格已核准、數值 placeholder 與非 Godot 實作範圍；192–203：納入驗收準則；205–211：版本紀錄。 | 交接內容載明使用者明確確認；本次設計規格暫存區 `git diff --cached --check` 通過；提交僅包含 1 個 Markdown 規格檔，未含 Godot 程式。 | `24c5eb1` |
| 2026-08-10 15:01 | 策劃 | 新手與第一地盤任務節奏 | `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md` | 77–95：固定 23 個新手任務、未接受任務不受手動刷新替換、常規任務為 15 分鐘 N／1 小時 X／2 小時 Y，第一地盤上限 2 小時；173–174：調校假設。 | 交接內容載明使用者明確指定；規格表格數量加總為 23，指定時長與第一地盤上限均已核對。 | `24c5eb1` |
| 2026-08-10 14:52 | 策劃 | 桌面常駐型 UI 與 Steam Cloud 邊界 | `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md` | 150–158：無一般視窗裝飾、錨定工作列上方、透明區不攔截桌面；162–163：首版本機存檔與 Steam 正式發行前 Steam Cloud；201–202：驗收準則。 | 交接內容載明使用者依參考圖與明確要求核准；相關 UI、本機存檔與 Steam Cloud 條文已核對。 | `24c5eb1` |
| 2026-08-10 14:52 | 策劃 | 多人派遣與團隊報酬倍率 | `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md` | 55–61：每人單一任務、任務最低／最多人數與明示團隊倍率；107–116：任務卡顯示與報酬結算；194：驗收準則。 | 交接內容載明使用者明確要求；`min_assignees`、`max_assignees`、`crew_reward_multiplier` 及單人不可並行條文均已核對。 | `24c5eb1` |
| 2026-08-10 14:29 | 策劃 | 地盤觸及解鎖新人物 | `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md` | 43–51：5 名同外觀初始小弟；49–50：首次觸及新地盤解鎖 1 名人物，屬本機進度而非付費內容；126–130、200：地盤狀態與驗收準則。 | 交接內容載明使用者明確指定；初始人數、解鎖時機與非付費邊界已核對。 | `24c5eb1` |
| 2026-08-10 14:29 | 策劃 | 地盤＋探索混合核心循環 | `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md` | 9–13：產品定位與非付費／本機邊界；35–37：長期循環；97–103：任務產出；120–140：地盤、影響力、分級貨幣標籤與收藏。 | 交接內容載明使用者選擇 C；核心循環、範圍與 `[PLACEHOLDER]` 標示均已核對。 | `24c5eb1` |
| 2026-08-10 14:26 | 維運 | 初始化桌面版 GitHub 儲存庫 | `.gitignore`；`.git/config`；`ADJUSTMENT_LOG.md` | `.gitignore` 1–15：排除 `.codegraph/`、Godot 產物與匯出檔；`.git/config`：僅此 repository 設定 `chev <chevalier1216@users.noreply.github.com>`；未修改產品功能。 | `git diff --cached --check` 通過；已推送 `origin/main`。 | `6129029` |
| 2026-08-10 14:22 | 維運 | 啟用持續更新的調整日誌 | `ADJUSTMENT_LOG.md` | 5–8：建立記錄規則；10–12：建立欄位與首筆紀錄；未修改產品功能。 | 已確認啟用前工作目錄未初始化為 Git repository，且僅含 `.codegraph/` 索引資料。 | 不適用：尚無 Git repository。 |

## 後續紀錄

| 日期時間（Asia/Taipei） | 類型 | 目標 | 檔案相對位置 | 行號與摘要 | 驗證結果 | Git commit |
| --- | --- | --- | --- | --- | --- | --- |
