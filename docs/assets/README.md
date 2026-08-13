# 素材文件規則

本目錄只管理素材的可追溯資訊與跨裝置決策，不存放二進位素材，也不取代 `docs/operations/ASSET_POLICY.md` 的取得政策、`docs/README.md` 的文件導覽或 `CROSS_DEVICE_DEVELOPMENT.md` 的協作流程。

## 1. 目前已存在的分類

| 分類 | 位置 | 現況與用途 |
| --- | --- | --- |
| 第三方實體素材 | `godot/BGiDesktop/assets/third_party/kenney_top_down_shooter/` | Kenney Top-down Shooter；僅灰盒環境、構圖與介面驗證。不得作為正式天際線、掛件、角色、武器或產品識別。 |
| 採用與來源研究 | `docs/superpowers/research/2026-08-10-bgi-desktop-asset-*.md` | 候選、授權、採用關卡與台帳欄位。 |
| 美術交付與分層研究 | `docs/superpowers/research/2026-08-10-bgi-desktop-{original-art-delivery-spec,skyline-*.md}` | 背景、掛件、動態插槽與靜態備援的交付規格。 |
| UI 候選研究 | `docs/superpowers/research/2026-08-10-bgi-desktop-{ui-*,itchio-ui-candidate-shortlist}.md` | icon 語意、狀態色、UI 候選與限制。 |

## 2. 素材來源台帳

每個已取得、準備導入或由手機討論確認的素材包，必須在對應研究文件或本目錄後續的台帳文件保留一筆紀錄。最低欄位如下：

| 欄位 | 要求 |
| --- | --- |
| `asset_id`、`parent_asset_id`、`asset_type` | 使用穩定 ASCII 識別碼，並標示所屬素材包與類型。 |
| `candidate_status` | 僅用 `research_only`、`eligible`、`acquired_pending_review`、`greybox_approved`、`ready_to_import`、`blocked`；原型專用另加 `prototype_only`。 |
| `author`、`source_url` | 作者／供應者與可回查的原始來源頁。 |
| `license_name`、`license_url`、`license_snapshot_date` | 授權名稱、原文網址與檢查日期。若為使用者人工確認，須明記確認者、日期與確認範圍，不能誤寫成公開授權。 |
| `commercial_allowed`、`modification_allowed`、`notice_requirement` | 分別記錄商用、修改與署名／notice 義務；未知即填未知。 |
| `cost_amount`、`cost_currency`、`receipt_reference` | 付款或贊助素材必填；免費素材填 `0`、`N/A`、`N/A`。 |
| `intended_use`、`prohibited_use` | 對應具體畫面或用途，並寫明不得使用的範圍。 |
| `file_name`、`file_hash_sha256`、`file_size_bytes` | 實際取得後必填，用以辨識跨裝置的同一檔案。 |
| `canvas_size`、`layer_id` | 視覺素材填尺寸及 `BG_*`、`FG_*`、`UI_*` 分層識別。 |
| `review_owner`、`reviewed_at`、`review_result` | 記錄最終審核責任、時間與結果。 |

## 3. 授權證據與檔案標記

1. 取得前：保存來源頁、授權頁或使用者人工確認的文字證據與日期；缺少可驗證權利時，狀態維持 `research_only` 或 `blocked`。
2. 取得後：保存素材包內 `LICENSE`／`README`、SHA-256、檔案大小及取得日期；頁面證據與包內條款衝突時，以較嚴格者處理並退回 `acquired_pending_review`。
3. `greybox_approved`：只能用於灰盒、構圖或驗證，不得流入產品識別或正式成品畫面。
4. `prototype_only`：可在內部原型使用；不得進入公開宣傳、商店截圖、可發行匯出或最終授權清單。上架前必須替換或補足商用權利。
5. `ready_to_import`：必須已有來源、授權、用途、禁用範圍、檔案雜湊與必要 notice；缺少任一項不得標記為此狀態。

## 4. 手機討論的回寫規則

手機上的素材選擇、授權人工確認或用途限制，不能只留在聊天紀錄。同步到 Git 文件時：

1. 僅回寫可執行的結論：素材包 ID、來源 URL、確認日期、使用範圍、授權／署名結論、狀態與上架前動作。
2. 選擇既有的素材研究／台帳文件更新；若沒有對應主題，才在本目錄新增素材台帳文件。不得重述聊天逐字稿。
3. 人工確認授權須使用「使用者人工確認」標示，保留原始頁面未提供或未驗證的條款欄位，避免將人工判斷轉寫成 CC0、MIT 或其他未證實授權。
4. 變更用途、授權狀態或採用決定時，依專案既有規則同步 `ADJUSTMENT_LOG.md`；僅新增候選或研究結論時不自行宣告為正式採用。
5. 文件更新完成後，回報 OPLOG_HANDOFF：更新檔案、結論、證據位置、未變更的素材、阻塞與下一步。

## 5. 導入前檢核

在任何素材檔放入 `godot/BGiDesktop/assets/` 前，確認：

- 台帳狀態不是 `research_only`、`blocked` 或未處理的 `prototype_only`。
- 授權證據、包內條款、用途與檔案雜湊已記錄。
- 使用範圍符合灰盒／正式成品的指定邊界。
- 必要署名或 notice 已指定輸出位置。
- 跨裝置取得的是同一 SHA-256 檔案；不相同時重新審核。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 範圍 | 新增跨裝置素材文件規則；未下載、導入、移動或刪除素材。 |
| 現況 | 實體素材僅確認到 Kenney Top-down Shooter，定位為灰盒；其餘素材狀態由既有研究文件管理。 |
| 產出 | `docs/assets/README.md`，定義台帳、授權證據、灰盒／原型／成品邊界與手機決策回寫規則。 |
| 未覆寫 | 不重複資產取得政策、文件導覽或全域跨裝置協作文件。 |
| 下一步 | 後續素材取得或手機確認時，依第 2–5 節更新既有台帳並執行導入前檢核。 |
