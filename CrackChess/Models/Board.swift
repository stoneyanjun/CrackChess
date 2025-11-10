//
//  Board.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//


import Foundation

/// Represents the 8×8 chessboard and all pieces placed on it.
struct Board: Equatable, Codable, Sendable {

    /// 8×8 grid of optional pieces, indexed as [rank][file].
    /// rank = 0 → bottom (rank 1), rank = 7 → top (rank 8)
    private(set) var grid: [[Piece?]]

    /// Initializes an empty board.
    init() {
        self.grid = Array(
            repeating: Array(repeating: nil, count: 8),
            count: 8
        )
    }

    /// Initializes the board with the standard chess setup.
    static func standardSetup() -> Board {
        var board = Board()

        // --- Black back rank (rank 7, top visually) ---
        let blackBack: [PieceType] = [.rook, .knight, .bishop, .king, .queen, .bishop, .knight, .rook]
        for file in 0..<8 {
            board.grid[7][file] = Piece(blackBack[file], .black)
        }

        // --- Black pawns (rank 6) ---
        for file in 0..<8 {
            board.grid[6][file] = Piece(.pawn, .black)
        }

        // --- White pawns (rank 1) ---
        for file in 0..<8 {
            board.grid[1][file] = Piece(.pawn, .white)
        }

        // --- White back rank (rank 0, bottom visually) ---
        let whiteBack: [PieceType] = [.rook, .knight, .bishop, .king, .queen, .bishop, .knight, .rook]
        for file in 0..<8 {
            board.grid[0][file] = Piece(whiteBack[file], .white)
        }

        return board
    }

    /// Returns the piece located at a given square.
    func piece(at square: Square) -> Piece? {
        guard (0..<8).contains(square.rank),
              (0..<8).contains(square.file)
        else { return nil }
        return grid[square.rank][square.file]
    }

    /// Sets (or removes) a piece at a specific square.
    mutating func setPiece(_ piece: Piece?, at square: Square) {
        guard (0..<8).contains(square.rank),
              (0..<8).contains(square.file)
        else { return }
        grid[square.rank][square.file] = piece
    }
}
