//
//  MoveRecord.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//


import Foundation

/// Represents a single chess move in algebraic (Stockfish-compatible) notation.
/// Example: "e2e4" or "b8c6"
struct MoveRecord: Codable, Equatable, Identifiable, Sendable {
    /// Unique identifier for SwiftUI List diffing.
    let id: UUID
    
    /// The move number (starting from 1 for the first white move).
    let index: Int
    
    /// The moving color.
    let color: PieceColor
    
    /// From-square in algebraic notation, e.g. "e2"
    let from: String
    
    /// To-square in algebraic notation, e.g. "e4"
    let to: String
    
    /// Algebraic string such as "e2e4" (Stockfish-compatible).
    var notation: String { "\(from)\(to)" }
    
    /// Human-readable turn text (e.g., "1. e2e4" or "1... e7e5")
    var displayText: String {
        color == .white ? "\(index). \(notation)" : "\(index)... \(notation)"
    }
    
    init(index: Int, color: PieceColor, from: Square, to: Square) {
        self.id = UUID()
        self.index = index
        self.color = color
        self.from = from.notation
        self.to = to.notation
    }
}
