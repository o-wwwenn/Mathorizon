# Font Setup

這份文件的目的是讓設計者或開發者之後在「不破壞 Preview」的前提下，安全替換中文字體。

目前專案狀態：

- 自訂字體流程已建立
- 但 **尚未啟用**
- 所有畫面目前仍使用系統字體

這樣做的原因是：先保證 App 與 SwiftUI Preview 都能正常執行，再讓字體切換變成可控流程。

## 集中維護入口

字體切換只改這個檔案：

- `Mathorizon/Shared/AppFontRegistry.swift`

不要把 `.custom("字體名稱", size: ...)` 直接散寫在各個 View 裡。

## 啟用字體前的步驟

### 1. 確認字體檔已加入 App target

字體檔放在資料夾內不等於 App 會打包它。

請先確認字體檔：

- 已存在於專案
- 已勾選 `Mathorizon` target membership

### 2. 找出真正的 PostScript name

SwiftUI `.custom()` 要用的是字體內部名稱，不是檔名。

例如：

- 正確可能是 `GenSenRounded2TW-R`
- 錯誤不是 `GenSenRounded2-R.ttc`

專案已經幫你準備好一個安全的偵測工具：

- `Mathorizon/Shared/AppFontDebug.swift`

它**不會自動執行**，所以不會影響 Preview，也不會影響正式 App。

#### 使用方式

先在你想暫時測試的畫面加一段：

```swift
.onAppear {
    AppFontDebug.printMatchingFonts(keyword: "GenSen")
}
```

如果你想列出全部字體：

```swift
.onAppear {
    AppFontDebug.printAllFamilies()
}
```

#### 最推薦做法

你可以暫時加在：

- `ContentView.swift`

例如：

```swift
struct ContentView: View {
    var body: some View {
        HomeView()
            .onAppear {
                AppFontDebug.printMatchingFonts(keyword: "GenSen")
            }
    }
}
```

執行 App 後，到 Xcode Console 看輸出。

你會看到像這樣的結果：

```swift
Family: GenSenRounded2 TW
  Font: GenSenRounded2TW-R
```

這個 `Font:` 後面的值，才是要填進 `.custom(...)` 或 `AppFontRegistry.swift` 的名字。

#### 找到後記得移除

印完字體名稱後，把你剛剛加的 `.onAppear` 刪掉即可。

### 3. 只改 `AppFontRegistry.swift`

把這兩行：

```swift
static let chineseRegularPostScriptName = "YourChineseFont-Regular"
static let chineseBoldPostScriptName = "YourChineseFont-Bold"
```

換成真實字體名稱。

### 4. 先用小範圍畫面測試

先只讓一個畫面接 `AppFontRegistry`，確認：

- Preview 正常
- App 執行正常
- 中文有正確顯示

### 5. 最後才打開開關

把：

```swift
static let usesCustomFonts = false
```

改成：

```swift
static let usesCustomFonts = true
```

## 目前 HomeView 的接法

首頁卡片標題已經改成走集中入口：

- `AppFontRegistry.Home.compactCardTitle(size:)`
- `AppFontRegistry.Home.largeCardTitle(size:)`

所以之後若要替換首頁中文字體，只要：

1. 改 `AppFontRegistry.swift`
2. 打開 `usesCustomFonts`

不需要到 `HomeView.swift` 到處搜尋字體名稱。

## 維護原則

1. 字體名稱只存在於 `AppFontRegistry.swift`
2. 字體檔流程只記錄在這份文件
3. 真正啟用前，保持 `usesCustomFonts = false`

這是目前最容易維護，也最不容易把 Preview 弄壞的做法。
