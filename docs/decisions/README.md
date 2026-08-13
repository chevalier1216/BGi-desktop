# 決策紀錄（ADR）

本目錄保存可被 Git 追蹤、需要長期引用的架構、產品與流程決策。ChatGPT Project 中形成且已核准的決策，必須回寫為此處的 ADR；聊天紀錄只保存討論脈絡與連結。

每份 ADR 使用獨立 Markdown 檔案，建議命名為 `YYYY-MM-DD-<decision-topic>.md`。

## ADR 模板

```md
# [決策標題]

> 狀態：proposed | accepted | superseded | deprecated
> 日期：YYYY-MM-DD

## 背景

此決策要解決的問題、約束與已知事實。

## 決策

已選擇的方案，以及適用範圍與不適用範圍。

## 替代方案

- 方案 A：取捨與未採用原因。
- 方案 B：取捨與未採用原因。

## 影響

對產品、規格、程式、測試、操作或後續決策的影響。

## Git commit／文件連結

- Git commit：`[PLACEHOLDER]`
- 相關文件：`[PLACEHOLDER]`
```

ADR 的狀態、關聯規格與 Git commit 必須可追溯；新決策若取代既有 ADR，應在兩份文件互相連結，不移動或刪除原紀錄。
