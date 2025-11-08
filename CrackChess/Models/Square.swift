//
//  Square.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//


import Foundation

/// A coordinate on the chessboard, file [a–h] and rank [1–8].
struct Square: Codable, Hashable, Equatable, Sendable {
    let file: Int   // 0 = a, 7 = h
    let rank: Int   // 0 = 1, 7 = 8

    // Existing initializer
    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    // ✅ New convenience initializer from algebraic notation ("e2")
    init?(notation: String) {
        guard notation.count == 2 else { return nil }

        let chars = Array(notation.lowercased())
        guard let fileChar = chars.first,
              let rankChar = chars.last,
              fileChar >= "a", fileChar <= "h",
              rankChar >= "1", rankChar <= "8"
        else { return nil }

        // Convert 'a'→0, 'b'→1, … 'h'→7
        let fileIndex = Int(fileChar.asciiValue! - Character("a").asciiValue!)
        // Convert '1'→0, '2'→1, … '8'→7
        let rankIndex = Int(rankChar.asciiValue! - Character("1").asciiValue!)

        self.file = fileIndex
        self.rank = rankIndex
    }

    // (Optional) Utility to convert back to "e2"
    var notation: String {
        let fileChar = Character(UnicodeScalar(file + 97)!) // 97 = 'a'
        let rankChar = Character(UnicodeScalar(rank + 49)!) // 49 = '1'
        return "\(fileChar)\(rankChar)"
    }
    
    /// Returns whether the square should be dark or light,
    /// according to chess convention (a1 = dark).
    var isDark: Bool {
        (file + rank).isMultiple(of: 2) == false
    }
}
