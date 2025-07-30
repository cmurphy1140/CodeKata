//
//  Challenge.swift
//  CodeKata
//
//  Created by Connor A Murphy on 7/30/25.
//

import Foundation

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let difficulty: String
    
    static let sampleData = [
        Challenge(
            title: "Two Sum",
            description: "Find two numbers that add up to target",
            difficulty: "Easy"
        ),
        Challenge(
            title: "Reverse String",
            description: "Reverse a string in-place",
            difficulty: "Easy"
        ),
        Challenge(
            title: "Binary Tree Traversal",
            description: "Traverse a binary tree in order",
            difficulty: "Medium"
        ),
        Challenge(
            title: "Dynamic Programming",
            description: "Solve using dynamic programming",
            difficulty: "Hard"
        )
    ]
}
