//
//  Piece.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation

/// The color of a chess piece.
enum PieceColor: String, Codable, Equatable, Sendable {
    case white
    case black
}

/// The type of a chess piece.
enum PieceType: String, Codable, Equatable, Sendable, CaseIterable {
    case pawn
    case rook
    case knight
    case bishop
    case queen
    case king
}

/// Represents a chess piece (type + color).
struct Piece: Codable, Equatable, Sendable {
    var type: PieceType
    var color: PieceColor

    init(_ type: PieceType, _ color: PieceColor) {
        self.type = type
        self.color = color
    }

    /// A readable symbol for text-based debugging.
    var symbol: String {
        switch (color, type) {
        case (.white, .pawn):   return "♙"
        case (.white, .rook):   return "♖"
        case (.white, .knight): return "♘"
        case (.white, .bishop): return "♗"
        case (.white, .queen):  return "♕"
        case (.white, .king):   return "♔"
        case (.black, .pawn):   return "♟"
        case (.black, .rook):   return "♜"
        case (.black, .knight): return "♞"
        case (.black, .bishop): return "♝"
        case (.black, .queen):  return "♛"
        case (.black, .king):   return "♚"
        }
    }
}

// MARK: - Helpers
extension PieceColor {
    /// Toggle the color (white ↔ black).
    mutating func toggle() {
        self = (self == .white) ? .black : .white
    }

    /// Display name for UI.
    var displayName: String {
        self == .white ? "White" : "Black"
    }

    /// Non-mutating toggle version.
    var toggled: PieceColor {
        self == .white ? .black : .white
    }
}

// MARK: - Image asset name mapping
extension Piece {
    /// The asset name for this piece, matching your PNG files in Assets.xcassets.
    var assetName: String {
        switch (color, type) {
        case (.white, .pawn):   return "white_pawn"
        case (.white, .rook):   return "white_rook"
        case (.white, .knight): return "white_knight"
        case (.white, .bishop): return "white_bishop"
        case (.white, .queen):  return "white_queen"
        case (.white, .king):   return "white_king"
        case (.black, .pawn):   return "black_pawn"
        case (.black, .rook):   return "black_rook"
        case (.black, .knight): return "black_knight"
        case (.black, .bishop): return "black_bishop"
        case (.black, .queen):  return "black_queen"
        case (.black, .king):   return "black_king"
        }
    }
}
