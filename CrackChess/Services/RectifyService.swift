//
//  RectifyService.swift
//  CrackChess
//
//  Created by stone on 2025/11/11.
//
import CoreGraphics

public struct RectifyConfig: Sendable {
    public var outSize: Int
    public init(outSize: Int = 1024) {
        self.outSize = outSize
    }
}

public enum RectifyService {
    public static func warp(
        cgImage: CGImage,
        quad: BoardQuad,
        config: RectifyConfig = .init()
    ) throws -> (CGImage, Homography) {
        // ✅ 这里直接生成 [NSValue]
        let pts: [NSValue] = [quad.tl, quad.tr, quad.br, quad.bl]
            .map { NSValue(point: NSPoint(x: $0.x, y: $0.y)) }
        
        // ✅ 直接传入 [NSValue]
        guard let dict = OpenCVClient.warpBoard(
                cgImage,
                quad: pts,
                outWidth: Int32(config.outSize),
                outHeight: Int32(config.outSize)
            ) as? [String: Any]
        else {
            throw NSError(domain: "RectifyService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "warp failed (no dict)"])
        }

        // ✅ CF 类型用 as! 消除恒真警告（且安全）
        let outImg = dict["image"] as! CGImage
        guard let hArr = dict["H"] as? [NSNumber] else {
            throw NSError(domain: "RectifyService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "warp failed (no H)"])
        }

        return (outImg, Homography(hArr.map { $0.doubleValue }))
    }
}

