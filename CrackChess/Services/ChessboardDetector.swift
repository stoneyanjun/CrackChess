//
//  ChessboardDetector.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import Vision
import CoreImage

enum ChessboardDetector {

    static func detectBoard(in cgImage: CGImage) async throws -> CGRect {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumAspectRatio = 0.9
        request.maximumAspectRatio = 1.1
        request.minimumSize = 0.2
        request.minimumConfidence = 0.5

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let obs = request.results?.first else {
            throw BoardAnalyzerError.boardNotFound
        }
        return VNImageRectForNormalizedRect(obs.boundingBox,
                                            cgImage.width,
                                            cgImage.height)
    }

    static func cropAndWarp(image: CGImage, rect: CGRect) throws -> CGImage {
        let ci = CIImage(cgImage: image).cropped(to: rect)
        let ctx = CIContext()
        guard let out = ctx.createCGImage(ci, from: ci.extent) else {
            throw BoardAnalyzerError.boardNotFound
        }
        return out
    }
}
