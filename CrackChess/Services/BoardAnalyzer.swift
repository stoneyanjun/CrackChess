//
//  BoardAnalyzer.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import Vision
import CoreImage
import AppKit

enum BoardAnalyzerError: Error {
    case imageUnavailable
    case boardNotFound
    case classificationFailed
}

@MainActor
final class BoardAnalyzer {

    static func analyze(snapshot image: NSImage?) async throws -> GameStatus {
        guard let image, let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw BoardAnalyzerError.imageUnavailable
        }

        print("🔍 [BoardAnalyzer] Starting analysis on snapshot \(cgImage.width)x\(cgImage.height)")

        // --- 1️⃣ Detect board rectangle ---
        let rect = try await ChessboardDetector.detectBoard(in: cgImage)
        print("✅ [BoardAnalyzer] Board rect found:", rect)

        // --- 2️⃣ Warp to square ---
        let warped = try ChessboardDetector.cropAndWarp(image: cgImage, rect: rect)

        // --- 3️⃣ Split into 8×8 cells ---
        let cells = splitIntoCells(warped)
        print("🧩 [BoardAnalyzer] Extracted \(cells.count) cells")

        // --- 4️⃣ Classify each cell ---
        let classifier = PieceClassifier.shared
        var pieces: [DetectedPiece] = []

        for (index, cell) in cells.enumerated() {
            let rank = 8 - (index / 8)
            let file = index % 8
            if let result = try await classifier.classify(cell.image) {
                pieces.append(
                    DetectedPiece(position: Square(file: file, rank: rank),
                                  type: result.type,
                                  color: result.color,
                                  confidence: result.confidence)
                )
            }
        }

        print("♟ [BoardAnalyzer] Classified \(pieces.count) occupied squares")

        // --- 5️⃣ Build GameStatus ---
        var board = Board()
        for p in pieces where p.type != nil {
            let piece = Piece(p.type!, p.color!)
            board.setPiece(piece, at: p.position)
        }

        return GameStatus(board: board, turn: .white, phase: .playing)
    }

    // Helper to divide the square board into 8×8
    private static func splitIntoCells(_ cgImage: CGImage) -> [(rect: CGRect, image: CGImage)] {
        let width = cgImage.width
        let height = cgImage.height
        let cellW = width / 8
        let cellH = height / 8
        var result: [(CGRect, CGImage)] = []
        for row in 0..<8 {
            for col in 0..<8 {
                let rect = CGRect(x: col * cellW, y: row * cellH, width: cellW, height: cellH)
                if let sub = cgImage.cropping(to: rect) {
                    result.append((rect, sub))
                }
            }
        }
        return result
    }
}

struct DetectedPiece {
    let position: Square
    let type: PieceType?
    let color: PieceColor?
    let confidence: Float
}
