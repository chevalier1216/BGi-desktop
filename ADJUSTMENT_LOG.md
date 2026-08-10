# BGi Desktop 調整日誌

## 記錄規則

- 僅記錄已核准的策劃或程式變更；未核准的提案不列為完成變更。
- 每筆記錄須包含日期時間、目標、檔案相對位置、行號與摘要、驗證結果、Git commit。
- 若不適用，填寫 `不適用` 並說明原因；不得臆測 commit、行號或驗證結果。
- GitHub repository 尚未建立前，不建立 repository，亦不修改產品功能。

| 日期時間（Asia/Taipei） | 類型 | 目標 | 檔案相對位置 | 行號與摘要 | 驗證結果 | Git commit |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-08-10 14:26 | 維運 | 初始化桌面版 GitHub 儲存庫 | `.gitignore`；`.git/config`；`ADJUSTMENT_LOG.md` | `.gitignore` 1–15：排除 `.codegraph/`、Godot 產物與匯出檔；`.git/config`：僅此 repository 設定 `chev <chevalier1216@users.noreply.github.com>`；未修改產品功能。 | `git diff --cached --check` 通過；已推送 `origin/main`。 | `6129029` |
| 2026-08-10 14:22 | 維運 | 啟用持續更新的調整日誌 | `ADJUSTMENT_LOG.md` | 5–8：建立記錄規則；10–12：建立欄位與首筆紀錄；未修改產品功能。 | 已確認啟用前工作目錄未初始化為 Git repository，且僅含 `.codegraph/` 索引資料。 | 不適用：尚無 Git repository。 |

## 後續紀錄

| 日期時間（Asia/Taipei） | 類型 | 目標 | 檔案相對位置 | 行號與摘要 | 驗證結果 | Git commit |
| --- | --- | --- | --- | --- | --- | --- |
