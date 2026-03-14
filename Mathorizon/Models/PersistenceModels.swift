import Foundation
import SwiftData

@Model
final class QuestionCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var paletteRawValue: String
    var cardColorHex: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Question.category)
    var questions: [Question]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        palette: CategoryPalette,
        cardColorHex: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.paletteRawValue = palette.rawValue
        self.cardColorHex = cardColorHex
        self.createdAt = createdAt
        self.questions = []
    }

    var palette: CategoryPalette {
        get { CategoryPalette(rawValue: paletteRawValue) ?? .ocean }
        set { paletteRawValue = newValue.rawValue }
    }
}

@Model
final class Question {
    @Attribute(.unique) var id: UUID
    var prompt: String
    var choicesData: Data
    var correctAnswerIndex: Int
    var explanation: String
    var difficulty: Int
    var createdAt: Date

    var category: QuestionCategory?

    init(
        id: UUID = UUID(),
        prompt: String,
        choices: [String],
        correctAnswerIndex: Int,
        explanation: String,
        difficulty: Int,
        createdAt: Date = .now,
        category: QuestionCategory? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.choicesData = (try? JSONEncoder().encode(choices)) ?? Data()
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.category = category
    }

    var choices: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: choicesData)) ?? []
        }
        set {
            choicesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}

@Model
final class TestSession {
    @Attribute(.unique) var id: UUID
    var categoryName: String
    var startedAt: Date
    var completedAt: Date
    var totalQuestions: Int
    var correctAnswers: Int
    var totalTime: Double
    var modeData: String
    var resultsData: Data

    init(
        id: UUID = UUID(),
        categoryName: String,
        startedAt: Date,
        completedAt: Date,
        totalQuestions: Int,
        correctAnswers: Int,
        totalTime: Double,
        mode: QuizMode,
        results: [QuestionResult]
    ) {
        self.id = id
        self.categoryName = categoryName
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.totalTime = totalTime
        self.modeData = mode.storageValue
        self.resultsData = (try? JSONEncoder().encode(results)) ?? Data()
    }

    var mode: QuizMode {
        QuizMode.fromStorageValue(modeData, fallbackCount: totalQuestions)
    }

    var results: [QuestionResult] {
        (try? JSONDecoder().decode([QuestionResult].self, from: resultsData)) ?? []
    }

    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions) * 100).rounded())
    }

    var averageTime: Double {
        guard totalQuestions > 0 else { return 0 }
        return totalTime / Double(totalQuestions)
    }

    var fastestTime: Double {
        results.map(\.timeSpent).min() ?? 0
    }

    var slowestTime: Double {
        results.map(\.timeSpent).max() ?? 0
    }
}
