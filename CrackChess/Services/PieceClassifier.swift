//
//  PieceClassifier.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import Vision
import AppKit

final class PieceClassifier {

    static let shared = PieceClassifier()
    private var model: VNCoreMLModel?

    private init() {
        // Load custom CoreML model (e.g. ChessPieceClassifier.mlmodelc)
        if let url = Bundle.main.url(forResource: "ChessPieceClassifier", withExtension: "mlmodelc"),
           let mlModel = try? MLModel(contentsOf: url) {
            model = try? VNCoreMLModel(for: mlModel)
            print("🧠 [PieceClassifier] Loaded model successfully")
        } else {
            print("⚠️ [PieceClassifier] No model found — fallback to template logic")
        }
    }

    struct Result {
        let type: PieceType?
        let color: PieceColor?
        let confidence: Float
    }

    func classify(_ cgImage: CGImage) async throws -> Result? {
        guard let model else {
            return try await fallbackTemplateMatch(cgImage)
        }

        let request = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        guard let result = request.results?.first as? VNClassificationObservation else {
            throw BoardAnalyzerError.classificationFailed
        }

        let label = result.identifier.lowercased()
        if label == "empty" || result.confidence < 0.6 {
            return nil
        }

        let type: PieceType = PieceType.allCases.first(where: { label.contains($0.rawValue) }) ?? .pawn
        let color: PieceColor = label.contains("black") ? .black : .white

        return Result(type: type, color: color, confidence: result.confidence)
    }

    // --- Simple fallback: detect brightness/color dominance to guess color ---
    private func fallbackTemplateMatch(_ cgImage: CGImage) async throws -> Result? {
        let ci = CIImage(cgImage: cgImage)
        let avg = ci.areaAverage()
        let brightness = ((avg?.red ?? 0) + (avg?.green ?? 0) + (avg?.blue ?? 0)) / 3.0

        // ignore too-bright or too-dark cells (likely empty)
        if brightness > 0.8 || brightness < 0.2 {
            return nil
        }

        // crude heuristic: darker = black piece, lighter = white piece
        return Result(type: .pawn, color: brightness > 0.5 ? .white : .black, confidence: 0.3)
    }
}

private extension CIImage {
    func areaAverage() -> CIColor? {
        let extentVector = CIVector(x: extent.origin.x, y: extent.origin.y,
                                    z: extent.size.width, w: extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputExtentKey: extentVector,
                                                 kCIInputImageKey: self]) else { return nil }
        let outputImage = filter.outputImage!
        var bitmap = [UInt8](repeating: 0, count: 4)
        let ctx = CIContext(options: nil)
        ctx.render(outputImage,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: nil)
        return CIColor(red: CGFloat(bitmap[0]) / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2]) / 255)
    }
    var brightness: CGFloat {
        let color = areaAverage() ?? .gray
        return (color.red + color.green + color.blue) / 3
    }
}
