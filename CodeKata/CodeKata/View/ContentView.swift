//
//  ContentView.swift
//  CodeKata
//
//  Created by Connor A Murphy on 7/30/25.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var challenges: [Challenge]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack {
                // Score header
             //   ScoreHeaderView()
                
                // Challenge list
                List {
                    ForEach(challenges) { challenge in
                        NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                            ChallengeRowView(challenge: challenge)
                        }
                    }
                }
            }
            .navigationTitle("CodeKata")
            .onAppear {
            //    addSampleChallengesIfNeeded()
            }
        }
    }
    
    private func addSampleChallenges() {
        // Add sample challenges if the database is empty
        if challenges.isEmpty {
            let sampleChallenges = [
                Challenge(
                    title: "Two Sum",
                    problemDescription: "Find two numbers that add up to target",
                    difficulty: .whiteBelt
                ),
                Challenge(
                    title: "Valid Parentheses",
                    problemDescription: "Check if parentheses are properly matched",
                    difficulty: .whiteBelt
                ),
                Challenge(
                    title: "Binary Tree Traversal",
                    problemDescription: "Implement inorder tree traversal",
                    difficulty: .brownBelt
                )
            ]
            
            for challenge in sampleChallenges {
                modelContext.insert(challenge)
            }
        }
    }
}

#Preview {
    ContentView()
}

struct ChallengeRowView: View {
    let challenge: Challenge
    
    var body: some View {
        HStack {
            // Difficulty badge
            Text(challenge.difficulty.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                
                Text(challenge.problemDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if challenge.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
