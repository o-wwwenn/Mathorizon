import SwiftUI
import SwiftData


struct ContentView: View {
    var body: some View {
        HomeView()
    }
}



#Preview {
    ContentView()
        .modelContainer(for: [QuestionCategory.self, Question.self, TestSession.self], inMemory: true)
}

