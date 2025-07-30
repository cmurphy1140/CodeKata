//
//  Challenge.swift
//  CodeKata
//
//  Created by Connor A Murphy on 7/30/25.
//

import SwiftUI
import SwiftData

@Model
class Challenge {
    @Attribute(.unique) var id: String
    var title: String
    var problemDescription: String
    var difficulty: DifficultyLevel
    var category: String
    var timeLimit: Int
    var points: Int
    var isCompleted: Bool = false
    
    init(title: String, problemDescription: String, difficulty: DifficultyLevel) {
        self.id = UUID().uuidString
        self.title = title
        self.problemDescription = problemDescription
        self.difficulty = difficulty
        self.category = "General"
        self.timeLimit = 300
        self.points = 100
    }
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case whiteBelt = "White Belt"
    case brownBelt = "Brown Belt"
    case blackBelt = "Black Belt"
    
    var emoji: String {
        switch self {
        case .whiteBelt: return "🤍"
        case .brownBelt: return "🤎"
        case .blackBelt: return "🖤"
        }
    }
}

@Model
class UserProgress {
    var totalScore: Int = 0
    var currentStreak: Int = 0
    var completedChallenges: Int = 0
    var lastActivityDate: Date = Date()
    
    init() {}
}
