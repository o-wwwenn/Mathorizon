import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let deck: QuizDeck
    private let replayConfiguration: ReplayQuizConfiguration?

    @State private var selectedModeType = 0
    @State private var questionCount = 10
    @State private var timeLimit = 120
    @State private var autoAdvance = true
    @State private var selectedDifficulties: Set<Int> = Set(1...5)
    @State private var stage: QuizStage = .setup

    @State private var quizQuestions: [Question] = []
    @State private var currentIndex = 0
    @State private var results: [QuestionResult] = []
    @State private var selectedAnswerIndex: Int?
    @State private var hasSubmittedAnswer = false
    @State private var totalElapsedTime = 0.0
    @State private var startedAt = Date()
    @State private var questionStartedAt = Date()
    @State private var completedAt = Date()
    @State private var feedbackText = ""
    @State private var flashCorrect = false
    @State private var shakeWrong = false
    @State private var screenFlashColor = Color.clear
    @State private var quizFinished = false
    @State private var didPersistSession = false
    @State private var timer: Timer?

    private var mode: QuizMode {
        if let replayConfiguration {
            return replayConfiguration.mode
        }
        if selectedModeType == 0 {
            return .limitedQuestions(count: min(questionCount, max(availableQuestions.count, 1)))
        } else {
            return .limitedTime(seconds: timeLimit)
        }
    }

    private var availableQuestions: [Question] {
        if let replayConfiguration {
            return replayConfiguration.questions
        }
        return deck.questions.filter { selectedDifficulties.contains($0.difficulty) }
    }

    private var currentQuestion: Question? {
        guard quizQuestions.indices.contains(currentIndex) else { return nil }
        return quizQuestions[currentIndex]
    }

    private var correctCount: Int {
        results.filter(\.isCorrect).count
    }

    private var progressValue: Double {
        switch mode {
        case let .limitedQuestions(count):
            guard count > 0 else { return 0 }
            return min(Double(currentIndex) / Double(count), 1)
        case let .limitedTime(seconds):
            guard seconds > 0 else { return 0 }
            return min(totalElapsedTime / Double(seconds), 1)
        }
    }

    private var timeLabel: String {
        switch mode {
        case .limitedQuestions:
            return String(format: "經過 %.1f 秒", totalElapsedTime)
        case let .limitedTime(seconds):
            let remaining = max(Double(seconds) - totalElapsedTime, 0)
            return "剩餘 \(QuizMode.format(seconds: Int(remaining.rounded(.down))))"
        }
    }

    private var energyTitle: String {
        if flashCorrect {
            return "解題流正在上升"
        }
        if shakeWrong {
            return "錯誤衝擊發生"
        }
        return "時間模塊推進中"
    }

    private var questionCardWaterLevel: Double {
        switch mode {
        case .limitedQuestions:
            guard quizQuestions.count > 0 else { return 0 }
            return min(max(Double(correctCount) / Double(quizQuestions.count), 0), 1)
        case let .limitedTime(seconds):
            guard seconds > 0 else { return 0 }
            let remaining = max(Double(seconds) - totalElapsedTime, 0)
            return min(max(remaining / Double(seconds), 0), 1)
        }
    }

    private var waterFillColors: [Color] {
        let base = deck.cardColor
        switch mode {
        case .limitedQuestions:
            return [
                base.darkened(by: 0.08),
                base.darkened(by: 0.18)
            ]
        case .limitedTime:
            return [
                base.darkened(by: 0.06),
                base.darkened(by: 0.16)
            ]
        }
    }

    private var promptFontSize: CGFloat {
        guard let prompt = currentQuestion?.prompt else { return 28 }
        switch prompt.count {
        case 0...24:
            return 30
        case 25...42:
            return 28
        case 43...64:
            return 24
        case 65...88:
            return 21
        default:
            return 18
        }
    }

    var body: some View {
        Group {
            switch stage {
            case .setup:
                setupView
            case .playing:
                playingView
            case .result:
                ResultView(
                    deck: deck,
                    mode: mode,
                    completedAt: completedAt,
                    totalQuestions: quizQuestions.count,
                    totalElapsedTime: totalElapsedTime,
                    results: results,
                    persistAction: persistSessionIfNeeded,
                    doneAction: {
                        persistSessionIfNeeded()
                        dismiss()
                    }
                )
            }
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            timer?.invalidate()
        }
        .task {
            if replayConfiguration != nil, stage == .setup, quizQuestions.isEmpty {
                startQuiz()
            }
        }
    }

    private var setupView: some View {
        ZStack {
            MathorizonBackdrop(palette: deck.palette)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 10) {
                                    CategoryIconView(iconName: deck.iconName, size: 20)
                                    Text(deck.title)
                                        .font(.title2.bold())
                                }
                                Spacer()
                                Text("READY")
                                    .font(.caption.weight(.black))
                                    .tracking(2)
                                    .foregroundStyle(deck.cardColor)
                            }

                            Text("把這一輪切成短時間、高密度的運算節奏。")
                                .foregroundStyle(.secondary)

                            TimeBlockStrip(progress: 0.25, palette: deck.palette, segments: 10)
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("模式設定")
                                .font(.headline)

                            if replayConfiguration == nil {
                                Picker("模式", selection: $selectedModeType) {
                                    Text("限題").tag(0)
                                    Text("限時").tag(1)
                                }
                                .pickerStyle(.segmented)
                            } else {
                                Text("重做測驗會沿用原本的題目與模式。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if replayConfiguration == nil, selectedModeType == 0 {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("題數：\(min(questionCount, max(availableQuestions.count, 1)))")
                                        .font(.headline)
                                    Stepper("", value: $questionCount, in: 1...max(availableQuestions.count, 1))
                                        .labelsHidden()
                                }
                            } else if replayConfiguration == nil {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("時間：\(QuizMode.format(seconds: timeLimit))")
                                        .font(.headline)
                                    Stepper("", value: $timeLimit, in: 30...600, step: 30)
                                        .labelsHidden()
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                        ForEach([60, 120, 180, 300, 600], id: \.self) { quickTime in
                                            Button(QuizMode.format(seconds: quickTime)) {
                                                timeLimit = quickTime
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(deck.cardColor)
                                        }
                                    }
                                }
                            }

                            Toggle("答題後自動前進", isOn: $autoAdvance)
                                .tint(deck.cardColor)
                        }
                    }

                    if replayConfiguration == nil {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("難度篩選")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(availableQuestions.count) 題可用")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("可單選或複選。開始測驗時只會抽出被選到難度的題目。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 10) {
                                    ForEach(1...5, id: \.self) { level in
                                        difficultyChip(level)
                                    }
                                }
                            }
                        }
                    }

                    Button("開始測驗") {
                        startQuiz()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(deck.cardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .foregroundStyle(.white)
                    .disabled(availableQuestions.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private var playingView: some View {
        ZStack {
            MathorizonBackdrop(palette: deck.palette, intensity: 1 + progressValue)
            FullScreenWaterLevelBackground(
                level: questionCardWaterLevel,
                fillColors: waterFillColors,
                flashesCorrect: flashCorrect
            )

            VStack(spacing: 18) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(mode.title)
                                    .font(.headline)
                                Text(energyTitle)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                Text(timeLabel)
                                    .font(.headline.monospacedDigit())
                                Text("第 \(min(currentIndex + 1, quizQuestions.count)) / \(quizQuestions.count) 題")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        TimeBlockStrip(progress: max(progressValue, 0.02), palette: deck.palette, segments: 16)

                        HStack(spacing: 12) {
                            statBlock(title: "答對題數", value: "\(correctCount)", accent: .green)
                            statBlock(title: "模式", value: mode.subtitle, accent: deck.cardColor)
                        }
                    }
                }

                if let currentQuestion {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Q\(currentIndex + 1)")
                                    .font(.caption.weight(.black))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(deck.cardColor.opacity(0.16), in: Capsule())
                                Spacer()
                                Text("難度 \(currentQuestion.difficulty) / 5")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(currentQuestion.prompt)
                                .font(.system(size: promptFontSize, weight: .black, design: .rounded))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("作答會立即提交。畫面顏色與節奏會直接回應你的選擇。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(flashCorrect ? Color.green.opacity(0.55) : Color.clear, lineWidth: 2)
                    }
                    .modifier(ShakeEffect(animatableData: shakeWrong ? 1 : 0))

                    VStack(spacing: 10) {
                        ForEach(Array(currentQuestion.choices.enumerated()), id: \.offset) { index, choice in
                            Button {
                                submitAnswer(index)
                            } label: {
                                HStack(spacing: 14) {
                                    Text(optionLetter(for: index))
                                        .font(.headline)
                                        .frame(width: 36, height: 36)
                                        .background(Color.white.opacity(0.9), in: Circle())
                                        .foregroundStyle(answerForeground(for: index, question: currentQuestion))

                                    Text(choice)
                                        .font(.body.weight(.semibold))
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    if hasSubmittedAnswer && index == currentQuestion.correctAnswerIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if hasSubmittedAnswer && index == selectedAnswerIndex && index != currentQuestion.correctAnswerIndex {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                                .foregroundStyle(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(answerBackground(for: index, question: currentQuestion))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(answerStroke(for: index, question: currentQuestion), lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(hasSubmittedAnswer)
                        }
                    }

                    if hasSubmittedAnswer {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(feedbackText)
                                    .font(.headline)
                                    .foregroundStyle(selectedAnswerIndex == currentQuestion.correctAnswerIndex ? .green : .red)

                                if !currentQuestion.explanation.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("說明")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                        Text(currentQuestion.explanation)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()

                HStack {
                    Button("結束測驗") {
                        finish()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if hasSubmittedAnswer && !autoAdvance {
                        Button(currentIndex == quizQuestions.count - 1 ? "看結果" : "下一題") {
                            advanceAfterAnswer()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(deck.palette.color)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Rectangle()
                .fill(screenFlashColor)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 0.25), value: flashCorrect)
        .animation(.easeInOut(duration: 0.25), value: shakeWrong)
    }

    private func statBlock(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
    }

    private func difficultyChip(_ level: Int) -> some View {
        let isSelected = selectedDifficulties.contains(level)

        return Button {
            if isSelected, selectedDifficulties.count > 1 {
                selectedDifficulties.remove(level)
            } else {
                selectedDifficulties.insert(level)
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(level)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Text(difficultyLabel(for: level))
                    .font(.caption2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? deck.palette.color.opacity(0.9) : Color.white.opacity(0.65),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? deck.palette.color : Color.white.opacity(0.4), lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func difficultyLabel(for level: Int) -> String {
        switch level {
        case 1:
            return "低年級"
        case 2:
            return "高年級"
        case 3:
            return "國中"
        case 4:
            return "高中"
        default:
            return "成人"
        }
    }

    private func startQuiz() {
        didPersistSession = false
        quizFinished = false
        results = []
        currentIndex = 0
        totalElapsedTime = 0
        selectedAnswerIndex = nil
        hasSubmittedAnswer = false
        feedbackText = ""
        flashCorrect = false
        shakeWrong = false
        screenFlashColor = .clear
        startedAt = .now
        questionStartedAt = .now

        let shuffledQuestions = availableQuestions.shuffled()
        switch mode {
        case let .limitedQuestions(count):
            quizQuestions = Array(shuffledQuestions.prefix(min(count, shuffledQuestions.count)))
        case .limitedTime:
            quizQuestions = shuffledQuestions
        }

        stage = .playing
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            totalElapsedTime = Date().timeIntervalSince(startedAt)

            if case let .limitedTime(seconds) = mode, totalElapsedTime >= Double(seconds) {
                totalElapsedTime = Double(seconds)
                finish()
            }
        }
    }

    private func submitAnswer(_ index: Int) {
        guard let currentQuestion, !hasSubmittedAnswer else { return }

        selectedAnswerIndex = index
        hasSubmittedAnswer = true

        let timeSpent = (Date().timeIntervalSince(questionStartedAt) * 100).rounded() / 100
        let isCorrect = index == currentQuestion.correctAnswerIndex

        results.append(
            QuestionResult(
                questionID: currentQuestion.id,
                prompt: currentQuestion.prompt,
                choices: currentQuestion.choices,
                correctAnswerIndex: currentQuestion.correctAnswerIndex,
                selectedAnswerIndex: index,
                explanation: currentQuestion.explanation.isEmpty ? nil : currentQuestion.explanation,
                timeSpent: timeSpent,
                isCorrect: isCorrect
            )
        )

        if isCorrect {
            feedbackText = "答對了，節奏提升"
            flashCorrect = true
            pulseScreen(with: Color.green.opacity(0.18))
        } else {
            feedbackText = "這題答錯，系統重擊"
            shakeWrong = true
            pulseScreen(with: Color.red.opacity(0.3))
        }

        if autoAdvance {
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                await MainActor.run {
                    advanceAfterAnswer()
                }
            }
        }
    }

    private func pulseScreen(with color: Color) {
        screenFlashColor = color

        Task {
            try? await Task.sleep(for: .milliseconds(180))
            await MainActor.run {
                screenFlashColor = .clear
            }
        }
    }

    private func advanceAfterAnswer() {
        flashCorrect = false
        shakeWrong = false

        if currentIndex >= quizQuestions.count - 1 {
            finish()
            return
        }

        currentIndex += 1
        selectedAnswerIndex = nil
        hasSubmittedAnswer = false
        feedbackText = ""
        questionStartedAt = .now
    }

    private func finish() {
        guard !quizFinished else { return }
        quizFinished = true
        timer?.invalidate()
        completedAt = .now
        stage = .result
    }

    private func persistSessionIfNeeded() {
        guard !didPersistSession else { return }

        let session = TestSession(
            categoryName: deck.title,
            startedAt: startedAt,
            completedAt: completedAt,
            totalQuestions: quizQuestions.count,
            correctAnswers: correctCount,
            totalTime: totalElapsedTime,
            mode: mode,
            results: results
        )

        modelContext.insert(session)
        try? modelContext.save()
        didPersistSession = true
    }

    private func answerBackground(for index: Int, question: Question) -> Color {
        guard hasSubmittedAnswer else { return .white.opacity(0.72) }
        if index == question.correctAnswerIndex {
            return Color.green.opacity(0.24)
        }
        if index == selectedAnswerIndex {
            return Color.red.opacity(0.22)
        }
        return .white.opacity(0.55)
    }

    private func answerStroke(for index: Int, question: Question) -> Color {
        guard hasSubmittedAnswer else { return deck.cardColor.opacity(0.18) }
        if index == question.correctAnswerIndex {
            return .green.opacity(0.45)
        }
        if index == selectedAnswerIndex {
            return .red.opacity(0.45)
        }
        return .clear
    }

    private func answerForeground(for index: Int, question: Question) -> Color {
        guard hasSubmittedAnswer else { return deck.cardColor }
        if index == question.correctAnswerIndex {
            return .green
        }
        if index == selectedAnswerIndex {
            return .red
        }
        return deck.palette.color
    }

    private func optionLetter(for index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }
}

extension QuizView {
    init(deck: QuizDeck) {
        self.deck = deck
        self.replayConfiguration = nil
    }

    init(category: QuestionCategory) {
        self.deck = QuizDeck(
            title: category.name,
            iconName: category.iconName,
            palette: category.palette,
            cardColorHex: category.cardColorHex,
            questions: category.questions
        )
        self.replayConfiguration = nil
    }

    init(session: TestSession) {
        let replayQuestions = session.results.enumerated().map { offset, result in
            Question(
                id: UUID(),
                prompt: result.prompt,
                choices: result.choices,
                correctAnswerIndex: result.correctAnswerIndex,
                explanation: result.explanation ?? "",
                difficulty: 3,
                createdAt: session.startedAt.addingTimeInterval(Double(offset))
            )
        }

        self.deck = QuizDeck(
            title: "\(session.categoryName) 重做",
            iconName: "arrow.clockwise.circle.fill",
            palette: .indigo,
            cardColorHex: nil,
            questions: replayQuestions
        )
        self.replayConfiguration = ReplayQuizConfiguration(
            mode: session.mode,
            questions: replayQuestions
        )
    }
}

private struct FullScreenWaterLevelBackground: View {
    let level: Double
    let fillColors: [Color]
    let flashesCorrect: Bool

    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let clampedLevel = min(max(level, 0), 1)
            let fillHeight = proxy.size.height * clampedLevel

            ZStack(alignment: .bottom) {
                Color.clear

                ZStack(alignment: .top) {
                    LinearGradient(
                        colors: [
                            fillColors[0].opacity(flashesCorrect ? 0.28 : 0.22),
                            fillColors[1].opacity(flashesCorrect ? 0.18 : 0.13)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    WaterWaveShape(phase: phase, amplitude: 16)
                        .fill(Color.white.opacity(0.16))
                        .frame(height: 34)
                        .offset(y: -17)
                }
                .frame(height: max(fillHeight, 0))
                .animation(.easeInOut(duration: 0.5), value: level)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

private struct WaterWaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin((relativeX * .pi * 2) + phase)
            let y = rect.midY + (sine * amplitude * 0.45)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}
