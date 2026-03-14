# Mathorizon

Mathorizon 是一個用 `SwiftUI + SwiftData` 製作的數學練習遊戲 App。  
核心目標是讓使用者可以快速選單元、開始短回合測驗、查看結果、保存歷史紀錄，並且自行維護題庫。

目前專案已具備：

- 首頁單元選擇
- 限題 / 限時兩種測驗模式
- 難度篩選
- 即時作答回饋
- 結果頁與歷史紀錄
- 重做歷史測驗
- 題庫管理
- 題目 JSON 匯入
- 單元 JSON 匯出 / 分享 / 檔案匯入
- 自訂單元卡片顏色與圖示（SF Symbol / Emoji）

## 開發環境

- Xcode
- SwiftUI
- SwiftData
- iOS App 專案

## 專案結構

### App 入口

- [Mathorizon/MathorizonApp.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/MathorizonApp.swift)
  App 進入點，建立 `SwiftData` 的 `modelContainer`

- [Mathorizon/ContentView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/ContentView.swift)
  畫面入口，直接進到 `HomeView`

### Data

- [Mathorizon/Data/DefaultQuestionLibrary.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Data/DefaultQuestionLibrary.swift)
  預設題庫資料。第一次啟動時，這裡的內容會被寫進資料庫。

- [Mathorizon/Data/SeedData.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Data/SeedData.swift)
  負責首次啟動時插入預設資料，避免重複插入。

### Models

- [Mathorizon/Models/PersistenceModels.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Models/PersistenceModels.swift)
  SwiftData 持久化模型：
  - `QuestionCategory`
  - `Question`
  - `TestSession`

- [Mathorizon/Models/QuizTypes.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Models/QuizTypes.swift)
  非持久型別與匯入匯出型別：
  - `CategoryPalette`
  - `QuizMode`
  - `QuestionResult`
  - `ImportedQuestionPayload`
  - `ExportedCategoryPayload`
  - `LibraryExportEnvelope`
  - `QuizDeck`
  - `ReplayQuizConfiguration`

### Features

- [Mathorizon/Features/Home/HomeView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Home/HomeView.swift)
  首頁。負責：
  - 顯示主品牌
  - 題庫 / 歷史入口
  - 內建主單元卡片
  - 動態生成新增單元的卡片

- [Mathorizon/Features/Quiz/QuizView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Quiz/QuizView.swift)
  測驗設定與作答流程。負責：
  - 限題 / 限時模式
  - 難度篩選
  - 計時
  - 作答即時回饋
  - 全頁水位背景效果

- [Mathorizon/Features/Quiz/ResultView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Quiz/ResultView.swift)
  測驗結果頁與單題詳情。

- [Mathorizon/Features/History/ScoreHistoryView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/History/ScoreHistoryView.swift)
  歷史紀錄列表與詳情，支援重做歷史測驗。

- [Mathorizon/Features/Admin/AdminView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Admin/AdminView.swift)
  題庫管理中心。負責：
  - 新增 / 編輯 / 刪除單元
  - 新增 / 編輯 / 刪除題目
  - 題目 JSON 匯入
  - 單元 JSON 匯出與分享
  - 題庫 JSON 檔案匯入

### Shared

- [Mathorizon/Shared/ViewHelpers.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/ViewHelpers.swift)
  共用 UI 元件與 helper：
  - 背景
  - 卡片樣式
  - icon 顯示
  - color / hex 轉換

- [Mathorizon/Shared/AppFontRegistry.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/AppFontRegistry.swift)
  字體設定入口。首頁字體樣式集中管理在這裡。

- [Mathorizon/Shared/AppFontDebug.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/AppFontDebug.swift)
  用來列出 App 裡可用字體名稱，協助找 PostScript name。

### Fonts / Docs

- [Mathorizon/Resourses/Fonts/FONT_SETUP.md](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Resourses/Fonts/FONT_SETUP.md)
  字體導入與維護說明。

## 資料模型

### QuestionCategory

單元模型。

重要欄位：

- `name`
- `iconName`
- `paletteRawValue`
- `cardColorHex`
- `questions`

說明：

- `iconName` 可用 `SF Symbol` 或 `Emoji`
- `cardColorHex` 會影響首頁卡片與測驗頁主題色

### Question

題目模型。

重要欄位：

- `prompt`
- `choices`
- `correctAnswerIndex`
- `explanation`
- `difficulty`

說明：

- `explanation` 目前語意更接近「說明」，可留空
- `difficulty` 範圍為 `1...5`

### TestSession

歷史紀錄模型。

重要欄位：

- `categoryName`
- `modeData`
- `resultsData`
- `totalQuestions`
- `correctAnswers`
- `totalTime`

## 功能資料流

### 首次啟動

1. App 進入 [MathorizonApp.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/MathorizonApp.swift)
2. 首頁載入 [SeedData.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Data/SeedData.swift)
3. 若資料庫沒有單元，就把 [DefaultQuestionLibrary.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Data/DefaultQuestionLibrary.swift) 寫入

### 開始測驗

1. 首頁點選某個單元卡片
2. 進入 [QuizView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Quiz/QuizView.swift)
3. 使用者設定模式、難度篩選、自動前進
4. 系統依條件產生題目清單
5. 答題完成後進入 [ResultView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Quiz/ResultView.swift)
6. 測驗結果寫入 `TestSession`

### 重做歷史測驗

1. 在 [ScoreHistoryView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/History/ScoreHistoryView.swift) 點進歷史詳情
2. 選擇「重做這組題目」
3. 系統用當次保存的 `QuestionResult` 重建 `QuizDeck`

## 維護指南

### 1. 修改預設題庫

主要修改：

- [Mathorizon/Data/DefaultQuestionLibrary.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Data/DefaultQuestionLibrary.swift)

你可以：

- 新增預設單元
- 修改預設單元名稱 / 圖示 / 色盤
- 修改每一題的內容

注意：

- 這只影響「第一次啟動還沒資料時」的種子資料
- 已存在使用者資料庫裡的內容，不會自動被覆蓋

### 2. 修改首頁卡片

主要修改：

- [Mathorizon/Features/Home/HomeView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Home/HomeView.swift)

首頁分成兩種卡片來源：

- 固定卡片：題庫、歷史紀錄、四則運算、代數、比例、混合
- 動態卡片：使用者新增的額外單元

若要調整首頁視覺：

- `HomeBrandBanner`
- `SmallHomeCard`
- `LargeHomeCard`
- `HomeBackgroundGlow`

若要調整新增單元卡片如何出現：

- `extraCategories`

### 3. 修改測驗規則

主要修改：

- [Mathorizon/Features/Quiz/QuizView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Quiz/QuizView.swift)

常見修改入口：

- `mode`
  控制限題 / 限時

- `availableQuestions`
  控制難度篩選後可用題目

- `startQuiz()`
  控制開始時如何抽題

- `submitAnswer(_:)`
  控制作答紀錄與即時回饋

- `waterFillColors`
  控制背景水位顏色

### 4. 修改題庫管理

主要修改：

- [Mathorizon/Features/Admin/AdminView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Admin/AdminView.swift)

目前這個檔案已經是題庫管理核心，包含：

- 單元管理
- 題目管理
- JSON 題庫匯入匯出
- 分享
- AI Prompt

如果之後想再拆分維護，優先建議拆成：

- `CategoryManagementView`
- `QuestionManagementView`
- `LibraryTransferView`

### 5. 修改匯入 / 匯出格式

主要修改：

- [Mathorizon/Models/QuizTypes.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Models/QuizTypes.swift)
- [Mathorizon/Features/Admin/AdminView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Admin/AdminView.swift)

目前題庫 JSON 結構核心是：

- `ExportedCategoryPayload`
- `LibraryExportEnvelope`

若要擴充欄位，建議同步更新：

- 匯出資料生成 `exportData(for:)`
- 匯入解析 `decodedLibraryPayloads(from:)`
- 寫入資料 `importLibrary(from:)`

### 6. 修改圖示與顏色策略

主要修改：

- [Mathorizon/Shared/ViewHelpers.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/ViewHelpers.swift)

關鍵 helper：

- `CategoryIconView`
  統一處理 `SF Symbol / Emoji`

- `QuestionCategory.homeCardColor`
  單元卡片顏色

- `QuizDeck.cardColor`
  測驗頁主題色 / 水位色

### 7. 修改字體

請先讀：

- [Mathorizon/Resourses/Fonts/FONT_SETUP.md](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Resourses/Fonts/FONT_SETUP.md)

再改：

- [Mathorizon/Shared/AppFontRegistry.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/AppFontRegistry.swift)

如果要查字體 PostScript name：

- [Mathorizon/Shared/AppFontDebug.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/AppFontDebug.swift)

注意：

- `Resourses` 資料夾名稱目前拼法就是 `Resourses`
- 專案已依這個路徑工作，若要改名要一併整理專案引用

## JSON 格式

### 匯入單題 / 多題

目前題目匯入可接受：

- 單題物件
- 題目陣列
- `{"questions": [...]}`

每題至少需要：

- `prompt`
- `choices`
- `correctAnswerIndex`
- `difficulty`

可選：

- `explanation`

### 匯出單元題庫

目前單元匯出格式：

```json
{
  "categories": [
    {
      "name": "四則運算",
      "iconName": "plus.forwardslash.minus",
      "palette": "coral",
      "cardColorHex": "#C5483D",
      "questions": [
        {
          "prompt": "7 + 8 = ?",
          "choices": ["13", "14", "15", "16"],
          "correctAnswerIndex": 2,
          "difficulty": 1,
          "explanation": "7 + 8 = 15"
        }
      ]
    }
  ]
}
```

## 目前已知維護建議

### 建議 1

`AdminView.swift` 已經很大。  
若之後再擴充功能，優先把它拆成多個檔案，不然維護成本會持續上升。

### 建議 2

如果之後題庫真的變大，匯入可以改成分批寫入。  
目前一般幾十到幾百題都可接受。

### 建議 3

如果要讓歷史重做 100% 還原原始回合，之後可以把完整題目清單也一併存進 `TestSession`。  
現在重做主要是依靠保存下來的 `results` 重建。

## 建議維護順序

平常修改時，建議這樣找檔案：

1. 改資料內容：先看 [DefaultQuestionLibrary.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Data/DefaultQuestionLibrary.swift)
2. 改畫面入口：看 [HomeView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Home/HomeView.swift)
3. 改測驗流程：看 [QuizView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Quiz/QuizView.swift)
4. 改結果與歷史：看 [ResultView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Quiz/ResultView.swift) / [ScoreHistoryView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/History/ScoreHistoryView.swift)
5. 改題庫管理：看 [AdminView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Admin/AdminView.swift)
6. 改共用 UI / 色彩 / icon：看 [ViewHelpers.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/ViewHelpers.swift)
7. 改字體：看 [AppFontRegistry.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Shared/AppFontRegistry.swift) 與 [FONT_SETUP.md](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Resourses/Fonts/FONT_SETUP.md)

## 建議後續拆分

如果要繼續提升可維護性，下一步最值得做的是：

- 把 [AdminView.swift](/Users/owenyang/Desktop/Mathorizon/Mathorizon/Features/Admin/AdminView.swift) 拆檔
- 把匯入 / 匯出 / 分享獨立成 service
- 補測試，至少覆蓋：
  - 題目匯入
  - 題庫匯入匯出
  - 難度篩選
  - 重做測驗

