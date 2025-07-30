//
//  ContentView.swift
//  CodeKata
//
//  Created by Connor A Murphy on 7/30/25.
//

import SwiftUI

struct ContentView: View {
    @State private var challenges: [Challenge] = Challenge.sampleData
    
    var body: some View {
        NavigationView {
            List(challenges) { challenge in
                NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.headline)
                        Text(challenge.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("CodeKata")
        }
    }
}

#Preview {
    ContentView()
}
