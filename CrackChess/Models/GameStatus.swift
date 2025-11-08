//
//  GameStatus.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//


import Foundation

/// Represents the overall state of a chess match.
/// Stage Two: adds move support (basic piece relocation).
struct GameStatus: Equatable, Codable, Sendable {

    /// The complete chessboard, including all pieces.
    var board: Board

    /// Whose turn it is to move (for domain reference only).
    /// The authoritative turn is stored in GameState.currentTurn.
    var turn: PieceColor

    /// The current phase of the game.
    var phase: Phase

    // MARK: - Initialization
    init() {
        self.board = Board.standardSetup()
        self.turn = .white
        self.phase = .playing
    }

    // MARK: - Game logic

    /// Moves a piece from one square to another, updating the board.
    /// Assumes the move has already been validated by the reducer.
    mutating func move(from: Square, to: Square) {
        guard let piece = board.piece(at: from) else { return }

        // Remove the piece from its original square
        board.setPiece(nil, at: from)

        // If destination has a piece (capture), it's automatically replaced
        board.setPiece(piece, at: to)
    }

    /// Represents the current game phase or result.
    enum Phase: String, Codable, Equatable, Sendable {
        case playing      // Normal play
        case check        // King under check
        case checkmate    // Game over - checkmate
        case stalemate    // Game over - draw by stalemate
        case draw         // Game over - draw by other reasons
    }
}
