//
//  MathorizonApp.swift
//  Mathorizon
//
//  Created by 楊哲鈞Owen on 2026/3/13.
//

import SwiftUI
import SwiftData

@main
struct MathorizonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [QuestionCategory.self, Question.self, TestSession.self])
    }
}
