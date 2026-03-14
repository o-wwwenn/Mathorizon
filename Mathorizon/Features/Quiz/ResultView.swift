import SwiftUI

struct ResultView: View {
    let deck: QuizDeck
    let mode: QuizMode
    let completedAt: Date
    let totalQuestions: Int
    let totalElapsedTime: Double
    let results: [QuestionResult]
    let persistAction: () -> Void
    let doneAction: () -> Void

    @State private var selectedResult: QuestionResult?

    private var correctCount: Int {
        results.filter(\.isCorrect).count
    }

    private var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalQuestions) * 100).rounded())
    }

    private var averageTime: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.timeSpent).reduce(0, +) / Double(results.count)
    }

    private var fastestTime: Double {
        results.map(\.timeSpent).min() ?? 0
    }

    private var slowestTime: Double {
        results.map(\.timeSpent).max() ?? 0
    }

    private var commentary: String {
        scorePercentage >= 80 ? "節奏穩定" : "再衝一輪"
    }

    var body: some View {
        ZStack {
            MathorizonBackdrop(palette: deck.palette)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(commentary)
                                .font(.title2.bold())

                            HStack(alignment: .bottom) {
                                Text("\(scorePercentage)%")
                                    .font(.system(size: 54, weight: .black, design: .rounded))
                                Spacer()
                                Text("\(correctCount) / \(totalQuestions)")
                                    .font(.title3.bold())
                                    .foregroundStyle(.secondary)
                            }

                            TimeBlockStrip(
                                progress: totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions),
                                palette: deck.palette,
                                segments: max(totalQuestions, 6)
                            )
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("回合統計")
                                .font(.headline)

                            HStack {
                                ResultMetric(title: "總時間", value: formatCompactSeconds(totalElapsedTime))
                                ResultMetric(title: "平均時間", value: formatCompactSeconds(averageTime))
                            }

                            HStack {
                                ResultMetric(title: "最快時間", value: formatCompactSeconds(fastestTime))
                                ResultMetric(title: "最慢時間", value: formatCompactSeconds(slowestTime))
                            }

                            HStack {
                                ResultMetric(title: "模式", value: mode.subtitle)
                                ResultMetric(title: "完成時間", value: completedAt.formatted(date: .omitted, time: .shortened))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("逐題回放")
                            .font(.title3.bold())

                        ForEach(Array(results.enumerated()), id: \.element.id) { offset, result in
                            Button {
                                selectedResult = result
                            } label: {
                                GlassPanel {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("第 \(offset + 1) 題")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.secondary)
                                            Text(result.prompt)
                                                .foregroundStyle(.primary)
                                                .lineLimit(2)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text(formatCompactSeconds(result.timeSpent))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(result.isCorrect ? "正確" : "錯誤")
                                                .font(.headline)
                                                .foregroundStyle(result.isCorrect ? .green : .red)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("完成") {
                        doneAction()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(deck.palette.color, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("測驗結果")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    doneAction()
                }
            }
        }
        .onAppear {
            persistAction()
        }
        .sheet(item: $selectedResult) { result in
            QuestionResultDetailView(result: result)
        }
    }
}

struct QuestionResultDetailView: View {
    let result: QuestionResult

    var body: some View {
        NavigationStack {
            List {
                Section("題目") {
                    Text(result.prompt)
                }

                Section("選項") {
                    ForEach(Array(result.choices.enumerated()), id: \.offset) { index, choice in
                        HStack {
                            Text(["A", "B", "C", "D"][index])
                            Text(choice)
                            Spacer()
                            if index == result.correctAnswerIndex {
                                Text("正解")
                                    .foregroundStyle(.green)
                            }
                            if index == result.selectedAnswerIndex {
                                Text("你的答案")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                if let explanation = result.explanation, !explanation.isEmpty {
                    Section("說明") {
                        Text(explanation)
                    }
                }

                Section("作答資訊") {
                    Text("作答時間：\(String(format: "%.2f 秒", result.timeSpent))")
                    Text("作答結果：\(result.isCorrect ? "正確" : "錯誤")")
                    Text("選擇答案：\(result.selectedAnswerText)")
                }
            }
            .navigationTitle("單題詳情")
        }
    }
}
