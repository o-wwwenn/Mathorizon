import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct AdminView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: \QuestionCategory.createdAt) private var categories: [QuestionCategory]

    @State private var selectedCategoryID: UUID?
    @State private var showAddCategory = false
    @State private var showAddQuestion = false
    @State private var editingCategory: QuestionCategory?
    @State private var editingQuestion: Question?
    @State private var selectedQuestionIDs = Set<UUID>()
    @State private var showLibraryImporter = false
    @State private var exportDocument: LibraryJSONDocument?
    @State private var showLibraryExporter = false
    @State private var shareFile: ShareFile?
    @State private var libraryStatusMessage = ""
    @State private var libraryStatusColor: Color = .secondary
    @State private var pendingDeleteCategory: QuestionCategory?

    private var selectedCategory: QuestionCategory? {
        categories.first(where: { $0.id == selectedCategoryID }) ?? categories.first
    }

    var body: some View {
        List(selection: $selectedQuestionIDs) {
            Section("單元") {
                Picker("單元", selection: Binding(
                    get: { selectedCategoryID ?? categories.first?.id ?? UUID() },
                    set: { selectedCategoryID = $0 }
                )) {
                    ForEach(categories) { category in
                        Text(category.name).tag(category.id)
                    }
                }

                Button("新增單元") {
                    showAddCategory = true
                }

                Button("匯入題庫 JSON") {
                    showLibraryImporter = true
                }

                if let selectedCategory {
                    Button("編輯目前單元") {
                        editingCategory = selectedCategory
                    }

                    Button(role: .destructive) {
                        pendingDeleteCategory = selectedCategory
                    } label: {
                        Text("刪除目前單元")
                    }

                    Button("匯出目前單元 JSON") {
                        prepareCategoryExport(for: selectedCategory)
                    }

                    Button("分享目前單元") {
                        prepareCategoryShare(for: selectedCategory)
                    }
                }

                if !libraryStatusMessage.isEmpty {
                    Text(libraryStatusMessage)
                        .foregroundStyle(libraryStatusColor)
                        .font(.caption)
                }
            }

            if let selectedCategory {
                Section("\(selectedCategory.name) 題目") {
                    Button("新增題目") {
                        showAddQuestion = true
                    }

                    ForEach(selectedCategory.questions.sorted(by: { $0.createdAt < $1.createdAt })) { question in
                        Group {
                            if editMode?.wrappedValue == .active {
                                questionRow(for: question)
                            } else {
                                Button {
                                    editingQuestion = question
                                } label: {
                                    questionRow(for: question)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .tag(question.id)
                    }
                    .onDelete { offsets in
                        let questions = selectedCategory.questions.sorted(by: { $0.createdAt < $1.createdAt })
                        for index in offsets {
                            modelContext.delete(questions[index])
                        }
                        try? modelContext.save()
                    }
                }
            }
        }
        .navigationTitle("題庫管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .bottomBar) {
                if !selectedQuestionIDs.isEmpty {
                    Button(role: .destructive) {
                        deleteSelectedQuestions()
                    } label: {
                        Text("刪除已選 \(selectedQuestionIDs.count) 題")
                    }
                }
            }
        }
        .onAppear {
            selectedCategoryID = selectedCategoryID ?? categories.first?.id
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView()
        }
        .sheet(isPresented: $showAddQuestion) {
            if let selectedCategory {
                AddQuestionView(category: selectedCategory)
            }
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category)
        }
        .sheet(item: $editingQuestion) { question in
            EditQuestionView(question: question)
        }
        .fileImporter(
            isPresented: $showLibraryImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleLibraryImport(result: result)
        }
        .fileExporter(
            isPresented: $showLibraryExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFileName
        ) { result in
            switch result {
            case .success:
                libraryStatusMessage = "題庫 JSON 已匯出。"
                libraryStatusColor = .green
            case let .failure(error):
                libraryStatusMessage = "匯出失敗：\(error.localizedDescription)"
                libraryStatusColor = .red
            }
        }
        .sheet(item: $shareFile) { file in
            ShareSheet(activityItems: [file.url])
        }
        .alert("刪除單元", isPresented: Binding(
            get: { pendingDeleteCategory != nil },
            set: { if !$0 { pendingDeleteCategory = nil } }
        ), presenting: pendingDeleteCategory) { category in
            Button("刪除", role: .destructive) {
                deleteCategory(category)
                pendingDeleteCategory = nil
            }
            Button("取消", role: .cancel) {
                pendingDeleteCategory = nil
            }
        } message: { category in
            Text("刪除「\(category.name)」會連同底下所有題目一起移除，且無法復原。")
        }
    }

    @ViewBuilder
    private func questionRow(for question: Question) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question.prompt)
                .multilineTextAlignment(.leading)
            Text("難度 \(question.difficulty)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func deleteSelectedQuestions() {
        guard let selectedCategory else { return }
        let targets = selectedCategory.questions.filter { selectedQuestionIDs.contains($0.id) }
        for question in targets {
            modelContext.delete(question)
        }
        selectedQuestionIDs.removeAll()
        editMode?.wrappedValue = .inactive
        try? modelContext.save()
    }

    private func deleteCategory(_ category: QuestionCategory) {
        let remaining = categories.filter { $0.id != category.id }
        modelContext.delete(category)
        selectedQuestionIDs.removeAll()
        selectedCategoryID = remaining.first?.id
        try? modelContext.save()
    }

    private var exportFileName: String {
        let name = selectedCategory?.name ?? "Mathorizon-Library"
        return name.replacingOccurrences(of: " ", with: "-")
    }

    private func prepareCategoryExport(for category: QuestionCategory) {
        guard let data = exportData(for: [category]) else {
            libraryStatusMessage = "目前單元無法匯出。"
            libraryStatusColor = .red
            return
        }
        exportDocument = LibraryJSONDocument(data: data)
        showLibraryExporter = true
    }

    private func prepareCategoryShare(for category: QuestionCategory) {
        guard let data = exportData(for: [category]) else {
            libraryStatusMessage = "目前單元無法分享。"
            libraryStatusColor = .red
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(category.name)-Mathorizon.json")

        do {
            try data.write(to: url, options: .atomic)
            shareFile = ShareFile(url: url)
        } catch {
            libraryStatusMessage = "建立分享檔案失敗：\(error.localizedDescription)"
            libraryStatusColor = .red
        }
    }

    private func exportData(for categories: [QuestionCategory]) -> Data? {
        let payload = LibraryExportEnvelope(
            categories: categories.map { category in
                ExportedCategoryPayload(
                    name: category.name,
                    iconName: category.iconName,
                    palette: category.palette.rawValue,
                    cardColorHex: category.cardColorHex,
                    questions: category.questions.sorted(by: { $0.createdAt < $1.createdAt }).map { question in
                        ImportedQuestionPayload(
                            prompt: question.prompt,
                            choices: question.choices,
                            correctAnswerIndex: question.correctAnswerIndex,
                            explanation: question.explanation.isEmpty ? nil : question.explanation,
                            difficulty: question.difficulty
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try? encoder.encode(payload)
    }

    private func handleLibraryImport(result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            do {
                let accessGranted = url.startAccessingSecurityScopedResource()
                defer {
                    if accessGranted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                try importLibrary(from: data)
            } catch {
                libraryStatusMessage = "匯入失敗：\(error.localizedDescription)"
                libraryStatusColor = .red
            }
        case let .failure(error):
            libraryStatusMessage = "選取檔案失敗：\(error.localizedDescription)"
            libraryStatusColor = .red
        }
    }

    private func importLibrary(from data: Data) throws {
        let payloads = try decodedLibraryPayloads(from: data)
        guard !payloads.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var importedQuestionCount = 0

        for payload in payloads {
            let palette = CategoryPalette(rawValue: payload.palette) ?? .ocean
            let category = QuestionCategory(
                name: payload.name,
                iconName: payload.iconName,
                palette: palette,
                cardColorHex: payload.cardColorHex
            )
            modelContext.insert(category)

            for questionPayload in payload.questions where questionPayload.isValid {
                let question = Question(
                    prompt: questionPayload.prompt.trimmingCharacters(in: .whitespacesAndNewlines),
                    choices: questionPayload.choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
                    correctAnswerIndex: questionPayload.correctAnswerIndex,
                    explanation: questionPayload.explanation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    difficulty: questionPayload.difficulty,
                    category: category
                )
                category.questions.append(question)
                modelContext.insert(question)
                importedQuestionCount += 1
            }
        }

        try modelContext.save()
        libraryStatusMessage = "成功匯入 \(payloads.count) 個單元，共 \(importedQuestionCount) 題。"
        libraryStatusColor = .green
    }

    private func decodedLibraryPayloads(from data: Data) throws -> [ExportedCategoryPayload] {
        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(LibraryExportEnvelope.self, from: data) {
            return envelope.categories
        }

        if let array = try? decoder.decode([ExportedCategoryPayload].self, from: data) {
            return array
        }

        if let single = try? decoder.decode(ExportedCategoryPayload.self, from: data) {
            return [single]
        }

        throw CocoaError(.fileReadCorruptFile)
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var iconName = "function"
    @State private var palette: CategoryPalette = .coral
    @State private var cardColor: Color = CategoryPalette.coral.color

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資料") {
                    TextField("單元名稱", text: $name)
                    TextField("圖示（可填 SF Symbol 或 Emoji）", text: $iconName)
                }

                Section("圖示預覽") {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(cardColor.opacity(0.22))
                            .frame(width: 52, height: 52)
                            .overlay {
                                CategoryIconView(iconName: iconName, size: 24)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "新單元" : name)
                                .font(.headline)
                            Text("可使用 SF Symbol，例如 function；也可直接填 emoji，例如 🧠、📐。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("視覺設定") {
                    Picker("色盤", selection: $palette) {
                        ForEach(CategoryPalette.allCases) { palette in
                            Text(palette.rawValue).tag(palette)
                        }
                    }

                    ColorPicker("主頁卡片顏色", selection: $cardColor, supportsOpacity: false)
                }
            }
            .navigationTitle("新增單元")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        let category = QuestionCategory(
                            name: name,
                            iconName: iconName,
                            palette: palette,
                            cardColorHex: cardColor.hexString()
                        )
                        modelContext.insert(category)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: palette) { _, newValue in
                cardColor = newValue.color
            }
        }
    }
}

struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let category: QuestionCategory

    @State private var name: String
    @State private var iconName: String
    @State private var palette: CategoryPalette
    @State private var cardColor: Color

    init(category: QuestionCategory) {
        self.category = category
        _name = State(initialValue: category.name)
        _iconName = State(initialValue: category.iconName)
        _palette = State(initialValue: category.palette)
        _cardColor = State(initialValue: category.homeCardColor)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資料") {
                    TextField("單元名稱", text: $name)
                    TextField("圖示（可填 SF Symbol 或 Emoji）", text: $iconName)
                }

                Section("圖示預覽") {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(cardColor.opacity(0.22))
                            .frame(width: 52, height: 52)
                            .overlay {
                                CategoryIconView(iconName: iconName, size: 24)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "單元名稱" : name)
                                .font(.headline)
                            Text("可使用 SF Symbol，例如 x.squareroot；也可直接填 emoji，例如 🧮。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("視覺設定") {
                    Picker("色盤", selection: $palette) {
                        ForEach(CategoryPalette.allCases) { palette in
                            Text(palette.rawValue).tag(palette)
                        }
                    }

                    ColorPicker("主頁卡片顏色", selection: $cardColor, supportsOpacity: false)
                }
            }
            .navigationTitle("編輯單元")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        category.iconName = iconName.trimmingCharacters(in: .whitespacesAndNewlines)
                        category.palette = palette
                        category.cardColorHex = cardColor.hexString()
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: palette) { _, newValue in
                cardColor = newValue.color
            }
        }
    }
}

struct AddQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let category: QuestionCategory

    @State private var entryMode = 0
    @State private var prompt = ""
    @State private var choiceA = ""
    @State private var choiceB = ""
    @State private var choiceC = ""
    @State private var choiceD = ""
    @State private var correctIndex = 0
    @State private var explanation = ""
    @State private var difficulty = 1
    @State private var importJSON = ""
    @State private var importStatusMessage = ""
    @State private var importStatusColor: Color = .secondary
    @State private var aiDifficulty = 3
    @State private var aiQuestionCount = 5
    @State private var aiTopicHint = ""

    private let difficultyDescriptions: [Int: String] = [
        1: "國小低年級：20 內加減、最基礎整數與圖像化情境。",
        2: "國小高年級：整數四則、分數小數基礎、簡單比例與文字題。",
        3: "國中：比例、方程式、分數運算、基礎代數與應用題。",
        4: "高中：多步驟代數、函數概念、較複雜比例與推理。",
        5: "大學 / 成人：抽象化更高、步驟更長、需較成熟的數量推理。"
    ]

    private var canSave: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceB.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceC.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceD.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var aiPrompt: String {
        """
        為「\(category.name)」產生 \(aiQuestionCount) 題數學單選題，難度固定 \(aiDifficulty)（1 到 5，5 最難）。\(aiTopicHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : " 主題聚焦：\(aiTopicHint)。")

        難度定義：
        1. 國小低年級：20 內加減、直接計算、一步驟理解。
        2. 國小高年級：四則運算、分數 / 小數初階、簡單文字題。
        3. 國中：比例、一次方程式、分數運算、基礎代數。
        4. 高中：多步驟代數、函數概念、較長推理鏈。
        5. 大學 / 成人：抽象程度更高、步驟更長、需要成熟的數量推理。

        規則：
        1. 每題都要有 prompt、choices、correctAnswerIndex、difficulty。
        2. choices 必須剛好 4 個選項。
        3. correctAnswerIndex 必須是 0 到 3 的整數。
        4. 每一題都要不同，不要改寫同一題。
        5. 錯誤選項要具有迷惑性，但不能與正解重複。
        6. 禁止使用 LaTeX、\\frac、\\times、\\div、^、_{ }、$...$、\\( \\)、\\[ \\] 或任何數學排版語法。
        7. 題目、選項、解析只能用一般文字與常見符號，例如 +、-、×、÷、=、%、:、/、²、³。
        8. difficulty 全部固定填 \(aiDifficulty)。
        9. 請一次產生完整 \(aiQuestionCount) 題，不要只產生 1 到 2 題。
        10. 只輸出 JSON，不要加任何 Markdown、說明文字、前言、結語、標題或程式碼區塊。
        11. 盡量少用中文句子，能用算式就用算式。

        錯誤示範：
        - "$4x \\times 0.8 = 3.2x$"
        - "\\frac{32}{30}"
        - "x^2"

        正確示範：
        - "4x × 0.8 = 3.2x"
        - "32/30"
        - "x²"

        JSON 格式如下：
        {
          "questions": [
            {
              "prompt": "題目文字",
              "choices": ["選項A", "選項B", "選項C", "選項D"],
              "correctAnswerIndex": 0,
              "difficulty": \(aiDifficulty)
            }
          ]
        }
        """
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("新增方式") {
                    Picker("方式", selection: $entryMode) {
                        Text("手動").tag(0)
                        Text("JSON").tag(1)
                        Text("AI Prompt").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                if entryMode == 0 {
                    Section("題目") {
                        TextField("題目內容", text: $prompt, axis: .vertical)
                        Stepper("難度 \(difficulty)", value: $difficulty, in: 1...5)
                    }

                    Section("選項") {
                        TextField("選項 A", text: $choiceA)
                        TextField("選項 B", text: $choiceB)
                        TextField("選項 C", text: $choiceC)
                        TextField("選項 D", text: $choiceD)
                        Picker("正確答案", selection: $correctIndex) {
                            Text("A").tag(0)
                            Text("B").tag(1)
                            Text("C").tag(2)
                            Text("D").tag(3)
                        }
                    }

                    Section("說明（選填）") {
                        TextField("題目說明", text: $explanation, axis: .vertical)
                    }
                } else if entryMode == 1 {
                    Section("JSON 匯入格式") {
                        Text("可貼上單一陣列，或 {\"questions\": [...]} 物件。每題都必須有 4 個選項、正確答案索引與難度。說明可省略。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $importJSON)
                            .frame(minHeight: 220)
                            .font(.system(.footnote, design: .monospaced))
                    }

                    Section("範例") {
                        Text("""
                        {
                          "questions": [
                            {
                              "prompt": "7 + 8 = ?",
                              "choices": ["13", "14", "15", "16"],
                              "correctAnswerIndex": 2,
                              "difficulty": 1
                            }
                          ]
                        }
                        """)
                        .font(.system(.caption, design: .monospaced))
                    }

                    Section {
                        Button("匯入題目") {
                            importQuestionsFromJSON()
                        }
                        .disabled(importJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if !importStatusMessage.isEmpty {
                            Text(importStatusMessage)
                                .foregroundStyle(importStatusColor)
                        }
                    }
                } else {
                    Section("AI 題目設定") {
                        Stepper("題目數量 \(aiQuestionCount)", value: $aiQuestionCount, in: 1...20)
                        Stepper("目標難度 \(aiDifficulty)", value: $aiDifficulty, in: 1...5)
                        Text(difficultyDescriptions[aiDifficulty] ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("知識點或主題（選填）", text: $aiTopicHint)
                    }

                    Section("給 AI 的 Prompt") {
                        Text(aiPrompt)
                            .textSelection(.enabled)
                            .font(.system(.footnote, design: .monospaced))

                        Button("複製 Prompt") {
                            copyToPasteboard(aiPrompt)
                            importStatusMessage = "AI Prompt 已複製，可貼到聊天工具產生 JSON。"
                            importStatusColor = .green
                        }
                    }
                }
            }
            .navigationTitle("新增題目")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        saveManualQuestion()
                    }
                    .disabled(entryMode != 0 || !canSave)
                }
            }
        }
    }

    private func saveManualQuestion() {
        let question = Question(
            prompt: prompt,
            choices: [choiceA, choiceB, choiceC, choiceD],
            correctAnswerIndex: correctIndex,
            explanation: explanation,
            difficulty: difficulty,
            category: category
        )
        category.questions.append(question)
        modelContext.insert(question)
        try? modelContext.save()
        dismiss()
    }

    private func importQuestionsFromJSON() {
        let trimmed = sanitizedMathText(in: normalizedJSONString(from: importJSON))
        guard let data = trimmed.data(using: .utf8) else {
            importStatusMessage = "JSON 內容無法讀取。"
            importStatusColor = .red
            return
        }

        let payloads = decodedPayloads(from: data)

        guard let payloads else {
            importStatusMessage = "JSON 格式不符合要求。可貼陣列、{\"questions\": [...]}，或單題物件。"
            importStatusColor = .red
            return
        }

        let validPayloads = payloads.filter(\.isValid)
        guard !validPayloads.isEmpty else {
            importStatusMessage = "沒有可匯入的有效題目。請確認題目、四個選項與難度皆完整。"
            importStatusColor = .red
            return
        }

        for payload in validPayloads {
            let question = Question(
                prompt: payload.prompt.trimmingCharacters(in: .whitespacesAndNewlines),
                choices: payload.choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
                correctAnswerIndex: payload.correctAnswerIndex,
                explanation: payload.explanation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                difficulty: payload.difficulty,
                category: category
            )
            category.questions.append(question)
            modelContext.insert(question)
        }

        try? modelContext.save()

        let skippedCount = payloads.count - validPayloads.count
        if skippedCount == 0 {
            importStatusMessage = "成功匯入 \(validPayloads.count) 題。"
            importStatusColor = .green
        } else {
            importStatusMessage = "成功匯入 \(validPayloads.count) 題，略過 \(skippedCount) 題無效資料。"
            importStatusColor = .orange
        }

        importJSON = ""
    }

    private func decodedPayloads(from data: Data) -> [ImportedQuestionPayload]? {
        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(ImportedQuestionEnvelope.self, from: data) {
            return envelope.questions
        }

        if let array = try? decoder.decode([ImportedQuestionPayload].self, from: data) {
            return array
        }

        if let single = try? decoder.decode(ImportedQuestionPayload.self, from: data) {
            return [single]
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
            let dictionaries = extractedQuestionDictionaries(from: jsonObject)
            let payloads: [ImportedQuestionPayload] = dictionaries.compactMap { dictionary in
                guard JSONSerialization.isValidJSONObject(dictionary),
                      let itemData = try? JSONSerialization.data(withJSONObject: dictionary)
                else {
                    return nil
                }
                return try? decoder.decode(ImportedQuestionPayload.self, from: itemData)
            }
            if !payloads.isEmpty {
                return payloads
            }
        }

        return nil
    }

    private func extractedQuestionDictionaries(from jsonObject: Any) -> [[String: Any]] {
        let requiredKeys = ["prompt", "choices", "correctAnswerIndex", "difficulty"]

        if let dictionaries = jsonObject as? [[String: Any]] {
            return dictionaries.flatMap { dictionary in
                if requiredKeys.allSatisfy({ dictionary[$0] != nil }) {
                    return [dictionary]
                }
                return dictionary.values.flatMap { value in
                    extractedQuestionDictionaries(from: value)
                }
            }
        }

        if let dictionary = jsonObject as? [String: Any] {
            if requiredKeys.allSatisfy({ dictionary[$0] != nil }) {
                return [dictionary]
            }

            return dictionary.values.flatMap { value in
                extractedQuestionDictionaries(from: value)
            }
        }

        if let array = jsonObject as? [Any] {
            return array.flatMap { value in
                extractedQuestionDictionaries(from: value)
            }
        }

        return []
    }

    private func normalizedJSONString(from source: String) -> String {
        var normalized = source.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.hasPrefix("```") {
            normalized = normalized
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let start = normalized.firstIndex(where: { $0 == "{" || $0 == "[" }),
           let end = normalized.lastIndex(where: { $0 == "}" || $0 == "]" }),
           start <= end {
            normalized = String(normalized[start...end])
        }

        return normalized
    }

    private func sanitizedMathText(in source: String) -> String {
        var text = source

        let replacements: [(String, String)] = [
            ("\\times", "×"),
            ("\\div", "÷"),
            ("\\cdot", "·"),
            ("\\%", "%"),
            ("\\(", ""),
            ("\\)", ""),
            ("\\[", ""),
            ("\\]", ""),
            ("$", "")
        ]

        for (target, replacement) in replacements {
            text = text.replacingOccurrences(of: target, with: replacement)
        }

        let superscripts: [(String, String)] = [
            ("^2", "²"),
            ("^3", "³")
        ]

        for (target, replacement) in superscripts {
            text = text.replacingOccurrences(of: target, with: replacement)
        }

        text = replaceSimpleFractions(in: text)

        return text
    }

    private func replaceSimpleFractions(in source: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\\frac\{([^{}]+)\}\{([^{}]+)\}"#) else {
            return source
        }

        var result = source
        let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))

        for match in matches.reversed() {
            guard match.numberOfRanges == 3,
                  let fullRange = Range(match.range(at: 0), in: result),
                  let numeratorRange = Range(match.range(at: 1), in: source),
                  let denominatorRange = Range(match.range(at: 2), in: source)
            else {
                continue
            }

            let numerator = source[numeratorRange]
            let denominator = source[denominatorRange]
            result.replaceSubrange(fullRange, with: "\(numerator)/\(denominator)")
        }

        return result
    }

    private func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}
struct EditQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let question: Question

    @State private var prompt: String
    @State private var choiceA: String
    @State private var choiceB: String
    @State private var choiceC: String
    @State private var choiceD: String
    @State private var correctIndex: Int
    @State private var explanation: String
    @State private var difficulty: Int

    init(question: Question) {
        self.question = question
        let choices = question.choices + Array(repeating: "", count: max(0, 4 - question.choices.count))
        _prompt = State(initialValue: question.prompt)
        _choiceA = State(initialValue: choices[0])
        _choiceB = State(initialValue: choices[1])
        _choiceC = State(initialValue: choices[2])
        _choiceD = State(initialValue: choices[3])
        _correctIndex = State(initialValue: question.correctAnswerIndex)
        _explanation = State(initialValue: question.explanation)
        _difficulty = State(initialValue: question.difficulty)
    }

    private var canSave: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceB.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceC.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !choiceD.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("題目") {
                    TextField("題目內容", text: $prompt, axis: .vertical)
                    Stepper("難度 \(difficulty)", value: $difficulty, in: 1...5)
                }

                Section("選項") {
                    TextField("選項 A", text: $choiceA)
                    TextField("選項 B", text: $choiceB)
                    TextField("選項 C", text: $choiceC)
                    TextField("選項 D", text: $choiceD)
                    Picker("正確答案", selection: $correctIndex) {
                        Text("A").tag(0)
                        Text("B").tag(1)
                        Text("C").tag(2)
                        Text("D").tag(3)
                    }
                }

                Section("說明（選填）") {
                    TextField("題目說明", text: $explanation, axis: .vertical)
                }
            }
            .navigationTitle("編輯題目")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveChanges() {
        question.prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        question.choices = [
            choiceA.trimmingCharacters(in: .whitespacesAndNewlines),
            choiceB.trimmingCharacters(in: .whitespacesAndNewlines),
            choiceC.trimmingCharacters(in: .whitespacesAndNewlines),
            choiceD.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        question.correctAnswerIndex = correctIndex
        question.explanation = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        question.difficulty = difficulty
        try? modelContext.save()
        dismiss()
    }
}

#if canImport(UIKit)
private struct ShareFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
