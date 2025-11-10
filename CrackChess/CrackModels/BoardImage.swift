//
//  BoardImage.swift
//  CrackChess
//
//  Created by stone on 2025/11/10.
//

import AppKit

public struct BoardImage: Equatable {
    public var nsImage: NSImage
    public var name: String?

    public init(nsImage: NSImage, name: String? = nil) {
        self.nsImage = nsImage
        self.name = name
    }

    public static func == (lhs: BoardImage, rhs: BoardImage) -> Bool {
        // NSImage doesn't conform to Equatable — compare by TIFFRepresentation length as a simple proxy
        lhs.name == rhs.name &&
        lhs.nsImage.tiffRepresentation?.count == rhs.nsImage.tiffRepresentation?.count
    }
}
