import SwiftUI
import UniformTypeIdentifiers

enum CategoryPalette: String, CaseIterable, Codable, Identifiable {
    case ocean
    case jade
    case amber
    case coral
    case indigo
    case slate

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .ocean:
            return .blue
        case .jade:
            return .green
        case .amber:
            return .orange
        case .coral:
            return .pink
        case .indigo:
            return .indigo
        case .slate:
            return .gray
        }
    }

    var tint: Color {
        color.opacity(0.16)
    }
}

enum QuizMode: Codable, Hashable {
    case limitedQuestions(count: Int)
    case limitedTime(seconds: Int)

    var title: String {
        switch self {
        case .limitedQuestions:
            return "限題模式"
        case .limitedTime:
            return "限時模式"
        }
    }

    var subtitle: String {
        switch self {
        case let .limitedQuestions(count):
            return "\(count) 題"
        case let .limitedTime(seconds):
            return Self.format(seconds: seconds)
        }
    }

    static func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    var storageValue: String {
        switch self {
        case let .limitedQuestions(count):
            return "limitedQuestions:\(count)"
        case let .limitedTime(seconds):
            return "limitedTime:\(seconds)"
        }
    }

    static func fromStorageValue(_ storageValue: String, fallbackCount: Int) -> QuizMode {
        let parts = storageValue.split(separator: ":")
        guard parts.count == 2, let value = Int(parts[1]) else {
            return .limitedQuestions(count: fallbackCount)
        }

        switch parts[0] {
        case "limitedQuestions":
            return .limitedQuestions(count: value)
        case "limitedTime":
            return .limitedTime(seconds: value)
        default:
            return .limitedQuestions(count: fallbackCount)
        }
    }
}

struct QuestionResult: Identifiable, Codable, Hashable {
    let id: UUID
    let questionID: UUID
    let prompt: String
    let choices: [String]
    let correctAnswerIndex: Int
    let selectedAnswerIndex: Int?
    let explanation: String?
    let timeSpent: Double
    let isCorrect: Bool

    init(
        id: UUID = UUID(),
        questionID: UUID,
        prompt: String,
        choices: [String],
        correctAnswerIndex: Int,
        selectedAnswerIndex: Int?,
        explanation: String?,
        timeSpent: Double,
        isCorrect: Bool
    ) {
        self.id = id
        self.questionID = questionID
        self.prompt = prompt
        self.choices = choices
        self.correctAnswerIndex = correctAnswerIndex
        self.selectedAnswerIndex = selectedAnswerIndex
        self.explanation = explanation
        self.timeSpent = timeSpent
        self.isCorrect = isCorrect
    }

    var selectedAnswerText: String {
        guard let selectedAnswerIndex, choices.indices.contains(selectedAnswerIndex) else {
            return "未作答"
        }
        return choices[selectedAnswerIndex]
    }
}

struct ImportedQuestionPayload: Codable {
    let prompt: String
    let choices: [String]
    let correctAnswerIndex: Int
    let explanation: String?
    let difficulty: Int

    var isValid: Bool {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedChoices = choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return !trimmedPrompt.isEmpty &&
            choices.count == 4 &&
            trimmedChoices.allSatisfy { !$0.isEmpty } &&
            (0..<4).contains(correctAnswerIndex) &&
            (1...5).contains(difficulty)
    }
}

struct ImportedQuestionEnvelope: Codable {
    let questions: [ImportedQuestionPayload]
}

enum QuizStage {
    case setup
    case playing
    case result
}

struct QuizDeck: Hashable {
    let title: String
    let iconName: String
    let palette: CategoryPalette
    let cardColorHex: String?
    let questions: [Question]
}

struct ReplayQuizConfiguration: Hashable {
    let mode: QuizMode
    let questions: [Question]
}

struct ExportedCategoryPayload: Codable {
    let name: String
    let iconName: String
    let palette: String
    let cardColorHex: String?
    let questions: [ImportedQuestionPayload]
}

struct LibraryExportEnvelope: Codable {
    let categories: [ExportedCategoryPayload]
}

struct LibraryJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
