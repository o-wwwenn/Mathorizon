import SwiftData

enum SeedData {
    static func insertIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<QuestionCategory>()
        guard let existing = try? context.fetchCount(descriptor), existing == 0 else {
            return
        }

        for categorySeed in DefaultQuestionLibrary.categories {
            let category = QuestionCategory(
                name: categorySeed.name,
                iconName: categorySeed.iconName,
                palette: categorySeed.palette
            )

            for item in categorySeed.questions {
                let question = Question(
                    prompt: item.prompt,
                    choices: item.choices,
                    correctAnswerIndex: item.correctAnswerIndex,
                    explanation: item.explanation,
                    difficulty: item.difficulty,
                    category: category
                )
                category.questions.append(question)
                context.insert(question)
            }

            context.insert(category)
        }

        try? context.save()
    }
}
