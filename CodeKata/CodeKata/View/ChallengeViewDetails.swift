//
//  ChallengeViewDetails.swift
//  CodeKata
//
//  Created by Connor A Murphy on 7/30/25.
//

import SwiftUI
import SwiftData

struct ChallengeDetailView: View {
    let challenge: Challenge
    @Environment(\.modelContext) private var modelContext
    @State private var userCode: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Challenge info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(challenge.difficulty.rawValue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("\(challenge.points) pts")
                        .font(.headline)
                }
                
                Text(challenge.title)
                    .font(.title)
                    .bold()
                
                Text(challenge.problemDescription)
                    .font(.body)
            }
            .padding()
            
            // Code editor area
            VStack(alignment: .leading) {
                Text("Your Solution:")
                    .font(.headline)
                
                TextEditor(text: $userCode)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
            
            // Submit button
            Button("Submit Solution") {
                submitSolution()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func submitSolution() {
        // Mark challenge as completed
        challenge.isCompleted = true
        
        // Save changes
        try? modelContext.save()
        
        // Show success feedback
        // TODO: Add proper validation logic
    }
}
