//
//  StageM2Pipeline.swift
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import AppKit // ✅ For NSImage

public enum StageM2Pipeline {
    // MARK: - Run from file path
    public static func run(inputPath: String, debugOut: String?) throws {
        let url = URL(fileURLWithPath: inputPath)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw NSError(domain: "M2", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot read image"])
        }
        try runInternal(cg: cg, debugOut: debugOut)
    }

    // MARK: - ✅ Run from asset catalog
    public static func run(imageName: String, debugOut: String?) throws {
        guard let nsImage = NSImage(named: imageName),
              let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "M2", code: -11,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot load image from assets: \(imageName)"])
        }
        try runInternal(cg: cg, debugOut: debugOut)
    }

    // MARK: - Shared logic
    private static func runInternal(cg: CGImage, debugOut: String?) throws {
        let out = debugOut.map { URL(fileURLWithPath: $0, isDirectory: true) }
        let result = try BoardDetectionService.detectAndRectify(from: cg, cfg: .init(), debugOut: out)

        print("M2 OK")
        print("quad:", result.quad.points)
        print("score:", result.score)
        print("H:", result.homography.h)

        if let dir = out {
            let p = dir.appendingPathComponent("final_warped.png")
            guard let dst = CGImageDestinationCreateWithURL(
                p as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                throw NSError(domain: "M2", code: -12,
                              userInfo: [NSLocalizedDescriptionKey: "Cannot create image destination"])
            }

            CGImageDestinationAddImage(dst, result.warped, nil)
            CGImageDestinationFinalize(dst)
            print("warped saved:", p.path)
        }
    }
}
