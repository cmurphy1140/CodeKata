//
//  ChallengeViewDetails.swift
//  CodeKata
//
//  Created by Connor A Murphy on 7/30/25.
//

import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    @State private var userCode = ""
    @State private var showingAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Challenge info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Difficulty: \(challenge.difficulty)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text(challenge.description)
                        .font(.body)
                }
                
                // Code input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Solution:")
                        .font(.headline)
                    
                    TextEditor(text: $userCode)
                        .font(.system(.body, design: .monospaced))
                        .border(Color.gray.opacity(0.3))
                        .frame(minHeight: 200)
                }
                
                // Submit button
                Button("Submit Solution") {
                    showingAlert = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle(challenge.title)
        .navigationBarTitleDisplayMode(.large)
        .alert("Solution Submitted!", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text("Great job! Your solution has been submitted.")
        }
    }
}

#Preview {
    NavigationView {
        ChallengeDetailView(challenge: Challenge.sampleData[0])
    }
}
