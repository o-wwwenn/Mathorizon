import SwiftUI
import SwiftData

struct ScoreHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TestSession.completedAt, order: .reverse) private var sessions: [TestSession]

    var body: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(session.categoryName)
                                .font(.headline)
                            Spacer()
                            Text("\(session.scorePercentage)%")
                                .foregroundStyle(scoreColor(for: session.scorePercentage))
                        }
                        Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(session.correctAnswers)/\(session.totalQuestions) 題，總時間 \(String(format: "%.2f 秒", session.totalTime))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteSessions)
        }
        .navigationTitle("歷史紀錄")
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
    }
}

struct SessionDetailView: View {
    let session: TestSession

    @State private var selectedResult: QuestionResult?

    var body: some View {
        List {
            Section("摘要") {
                LabeledContent("單元", value: session.categoryName)
                LabeledContent("模式", value: session.mode.title + " \(session.mode.subtitle)")
                LabeledContent("得分", value: "\(session.scorePercentage)%")
                LabeledContent("平均時間", value: String(format: "%.2f 秒", session.averageTime))
                LabeledContent("最快 / 最慢", value: String(format: "%.2f / %.2f 秒", session.fastestTime, session.slowestTime))
            }

            Section {
                NavigationLink {
                    QuizView(session: session)
                } label: {
                    Label("重做這組題目", systemImage: "arrow.clockwise.circle.fill")
                }
            }

            Section("題目") {
                ForEach(Array(session.results.enumerated()), id: \.element.id) { offset, result in
                    Button {
                        selectedResult = result
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("第 \(offset + 1) 題")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(result.prompt)
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Text(result.isCorrect ? "正確" : "錯誤")
                                .foregroundStyle(result.isCorrect ? .green : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle("紀錄詳情")
        .sheet(item: $selectedResult) { result in
            QuestionResultDetailView(result: result)
        }
    }
}
