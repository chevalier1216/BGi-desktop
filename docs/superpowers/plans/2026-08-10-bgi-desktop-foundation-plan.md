# BGi Desktop Godot 基礎框架實作計畫

## 目標

建立 Windows 優先、可由 Godot 4.7.1 開啟的桌面 UI 基礎專案；視窗無標題列與外框，依 Windows 可用工作區定位於工作列上方，預設非置頂，並提供置頂切換。

## 已確認邊界

- 不實作 GPS、真實地圖、行動端功能或 Android widget。
- 不實作未定案的任務數值、經濟、付費或 Steam Cloud 整合。
- UI 僅提供地盤、布置與任務區的結構與互動入口，不宣稱完成可玩循環。

## 小目標

1. 在 `G:\\Projects\\Godot\\BGiDesktop` 建立 Godot 專案與 Windows 視窗控制層。
2. 建立底部桌面 UI 場景：左側地盤／布置、中央地盤狀態、右側任務面板與設定按鈕。
3. 將視窗定位到 `DisplayServer.screen_get_usable_rect()` 底端，使其不覆蓋 Windows 工作列；預設不置頂，並持久化使用者的置頂偏好。
4. 在 Godot 無介面模式載入專案，檢查場景與 GDScript 可解析；再進行 Windows 執行檔啟動檢查。

## 已知限制

Godot 的一般 Windows 視窗無法單靠內建 API 保證附著於 Windows 桌面圖示層（WorkerW）。本基礎版採「無框、透明、位於可用工作區底部、預設不置頂」模式，符合不遮擋工作列與一般工作視窗的要求；若日後要求固定嵌入桌面圖示層，需另行核准 Windows 原生 Shell 整合。

