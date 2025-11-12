//
//  BoardDetectionService.swift
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

import CoreGraphics
import UniformTypeIdentifiers
import ImageIO

public struct BoardDetectionConfig: Sendable {
    public var minBoardAreaFraction: Double = 0.22
    public var vision = VisionClientConfig()
    public var cannyLow: Int = 80
    public var cannyHigh: Int = 160
    public var morphKernel: Int = 3
    public var outSize: Int = 1024
    public init() {}
}

public enum BoardDetectionService {

    public static func detectAndRectify(from cgImage: CGImage,
                                        cfg: BoardDetectionConfig = .init(),
                                        debugOut: URL? = nil
    ) throws -> BoardRectifyResult {

        // 1) Vision 主通道
        if let (quad, conf) = try VisionClient.detectBoardQuad(from: cgImage, config: cfg.vision) {
            let (warped, H) = try RectifyService.warp(cgImage: cgImage, quad: quad, config: .init(outSize: cfg.outSize))
            if let d = debugOut { try dump(warped, name: "vision_warped.png", to: d) }
            return .init(quad: quad, homography: H, warped: warped, score: conf)
        }

        // 2) OpenCV 兜底
        if let dict = OpenCVClient.detectBoardQuad(from: cgImage, cannyLow: Int32(cfg.cannyLow), cannyHigh: Int32(cfg.cannyHigh), morphKernel3: Int32(cfg.morphKernel), minAreaFraction: cfg.minBoardAreaFraction) as? [String: Any],
           let pts = dict["quad"] as? [NSValue],
           let score = dict["score"] as? NSNumber {

            let quad = Geometry.orderQuad(pts.map { CGPoint(x: $0.pointValue.x, y: $0.pointValue.y) })
            let (warped, H) = try RectifyService.warp(cgImage: cgImage, quad: quad, config: .init(outSize: cfg.outSize))
            if let d = debugOut { try dump(warped, name: "opencv_warped.png", to: d) }
            return .init(quad: quad, homography: H, warped: warped, score: score.doubleValue)
        }

        throw NSError(domain: "BoardDetection", code: -2, userInfo: [NSLocalizedDescriptionKey:"No board detected"])
    }

    private static func dump(_ img: CGImage, name: String, to dir: URL) throws {
        let url = dir.appendingPathComponent(name)
        let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dst, img, nil)
        CGImageDestinationFinalize(dst)
    }
}
