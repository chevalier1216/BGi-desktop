# BGi-Desktop Agent Rules

## 規範分層

- `AGENTS.md` 只放跨環境、長期有效且直接約束代理行為的規則。
- 機器路徑、目前分支清單、工具命令、測試步驟、素材決策、額度交接與其他可變執行細節，必須放入 `docs/operations/` 的獨立文件，並由本檔引用。
- 新增規則前先判斷其是否為可變細節；若是，不得直接堆入 `AGENTS.md`。

## 專案操作文件

- 專案背景與 canonical 路徑請見 `docs/operations/PROJECT_CONTEXT.md`。
- 跨裝置同步流程請見 `docs/operations/CROSS_DEVICE_DEVELOPMENT.md`。
- 手機至桌機的決策交接請使用 `docs/operations/SESSION_HANDOFF_TEMPLATE.md`。
- 可變的路徑、流程與交接細節維護於 `docs/operations/`，不寫入本檔。

## PM and branch-thread coordination

- When an existing Codex branch thread already covers a task, the PM thread must continue that existing thread through the Codex thread tools.
- Do not create or use a collaboration sub-agent from the PM thread when that branch thread exists and can receive work.
- A PM sub-agent is allowed only when no suitable existing branch thread exists, the work is clearly independent, and the user has explicitly approved that exception.
- Never describe a PM sub-agent as a replacement for an existing branch thread.

## 回覆語法

- 嚴禁濫用「不是……而是……」句式。只有在釐清必要且實質的對比或誤解時才能使用；一般說明、結論與狀態回報一律改用直接句。

## 專案根目錄與工作範圍

- 只在專案環境文件指定的 canonical project root 寫入、建置與操作 Git；備份目錄唯讀，未經使用者明確指示不得實作或提交。
- 目前工作站的實際 canonical root 與備份位置記錄於 `docs/operations/PROJECT_CONTEXT.md`。
- 回覆使用繁體中文，先給結論與可驗證根據；避免冗詞、無根據推測與非必要客套。
- 產品範圍與平台限制以已核准設計規格為準。

## 授權與檔案安全

- 可在專案根目錄內新增、修改程式、文件與測試；刪除、移動、重新命名檔案前必須取得使用者明確同意。
- Windows 系統設定、ACL、外部帳號授權與不可逆外部操作，必須先說明目標、影響與範圍並取得同意。
- 專案特定的自動產生檔與忽略檔處置，遵循 `docs/operations/PROJECT_CONTEXT.md`。
- 不得以未驗證事實宣稱測試、提交、推送或素材導入已完成。

## 分支對話與 PM 協作

- PM 必須以專案環境文件列出的既有分支對話繼續工作。
- 每項工作切成可獨立驗證的小目標；分支完成後若沒有等待使用者核准，立即派發下一個已核准範圍內的小目標。
- OPLOG_HANDOFF 必須包含日期時間、類型、目標、檔案、程式行號、摘要、驗證、未完成項目與阻塞。
- PM 收到 OPLOG_HANDOFF 後必須轉交既有 oplog 分支；不得以代理或口頭摘要取代單一日誌。

## Git、日誌與交付

- 每一項已核對變更先提交來源檔，再以獨立提交更新 `ADJUSTMENT_LOG.md`，再推送。
- 暫存時只列出明確檔案；不得使用廣泛 stage，也不得混入無關未追蹤檔或未交接內容。
- 若 Git、ACL 或測試環境阻塞，保留工作樹，記錄證據與最小處置方案；不得自行破壞性排除。

## Godot 測試與 QA

- Godot 驗證、無頭測試與 QA 必須遵循 `docs/operations/GODOT_TESTING.md`；交接時記錄驗證結果與已知非測試警告。
- 完整一輪遊玩 QA 必須待已核准的完整循環可視化操作可用後才建立；美術未完成時可用文字或色塊暫代，不得阻擋 QA。
- 未指定的經濟數值、報酬與內容一律保留 `[PLACEHOLDER]`，不得自行填入數值。

## 美術與素材

- 素材取得、授權核對、導入與資產台帳必須遵循 `docs/operations/ASSET_POLICY.md`。

## 使用額度交接

- 使用額度到達停止門檻時，必須遵循 `docs/operations/USAGE_HANDOFF.md`。
