//
//  DatasetBuilder.swift
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

import Foundation
import CoreGraphics
import ImageIO
import Accelerate
import UniformTypeIdentifiers
import AppKit

public enum DatasetBuilder {

    // MARK: - Single Image (CGImage)
    public static func generateDataset(
        from warpedImage: CGImage,
        outputDir: URL,
        boardSize: Int = 1024,
        patchSize: Int = 32,
        thresholdBrightness: CGFloat = 0.15,
        thresholdEdge: CGFloat = 0.08,
        emitDebugOverlay: Bool = true
    ) throws {
        let fm = FileManager.default

        // Prepare directories
        let trainDir = outputDir.appendingPathComponent("train", isDirectory: true)
        let emptyDir = trainDir.appendingPathComponent("empty", isDirectory: true)
        let occupiedDir = trainDir.appendingPathComponent("occupied", isDirectory: true)
        try fm.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: occupiedDir, withIntermediateDirectories: true)

        // Prepare CSV metadata file
        let metaDir = outputDir.appendingPathComponent("meta", isDirectory: true)
        try fm.createDirectory(at: metaDir, withIntermediateDirectories: true)
        let csvPath = metaDir.appendingPathComponent("labels.csv")
        var csv = "filename,label,file,rank,brightness,edgeEnergy\n"

        // Cell metrics
        let cell = boardSize / 8
        var allBrightness: [CGFloat] = []
        allBrightness.reserveCapacity(64)

        // Pre-scan for global brightness mean
        for row in 0..<8 {
            for col in 0..<8 {
                let rect = CGRect(x: col * cell, y: row * cell, width: cell, height: cell)
                if let sub = croppedImage(from: warpedImage, rect: rect) {
                    let b = meanBrightness(of: sub)
                    allBrightness.append(b)
                }
            }
        }
        guard !allBrightness.isEmpty else {
            throw NSError(domain: "DatasetBuilder", code: -101, userInfo: [NSLocalizedDescriptionKey: "No cells found for brightness prescan"])
        }
        let globalMean = allBrightness.reduce(0, +) / CGFloat(allBrightness.count)

        // Second pass: classify + save
        var index = 0
        var visuals: [CellVisual] = []
        visuals.reserveCapacity(64)

        for row in 0..<8 {
            for col in 0..<8 {
                index += 1
                let rect = CGRect(x: col * cell, y: row * cell, width: cell, height: cell)
                guard let sub = croppedImage(from: warpedImage, rect: rect) else { continue }

                let b = meanBrightness(of: sub)
                let e = edgeEnergy(of: sub)

                let brightnessDiff = abs(b - globalMean) / max(globalMean, 1e-6)
                let occupied = (brightnessDiff > thresholdBrightness) || (e > thresholdEdge)

                let label = occupied ? "occupied" : "empty"
                let fileChar = Character(UnicodeScalar(97 + col)!) // 'a' + col
                let rank = 8 - row

                let filename = "\(label)_\(String(format: "%06d", index))_\(fileChar)\(rank).png"
                let saveURL = (occupied ? occupiedDir : emptyDir).appendingPathComponent(filename)

                saveImage(sub, to: saveURL, targetSize: patchSize)

                csv += "\(filename),\(occupied ? 1 : 0),\(fileChar),\(rank),\(String(format: "%.4f", b)),\(String(format: "%.4f", e))\n"

                // collect for overlay
                visuals.append(CellVisual(rect: rect, occupied: occupied, file: fileChar, rank: rank))
            }
        }

        try csv.write(to: csvPath, atomically: true, encoding: .utf8)
        print("✅ Dataset generated at: \(outputDir.path)")

        // Emit overlay image
        if emitDebugOverlay {
            let overlayURL = metaDir.appendingPathComponent("debug_overlay.png")
            saveDebugOverlay(
                warpedImage: warpedImage,
                cells: visuals,
                boardSize: boardSize,
                to: overlayURL
            )
            print("🖼️  Debug overlay saved:", overlayURL.path)
        }
    }

    // MARK: - Single Image (Path)
    public static func generateDataset(
        fromPath warpedImagePath: String,
        outputDir: URL,
        boardSize: Int = 1024,
        patchSize: Int = 32,
        thresholdBrightness: CGFloat = 0.15,
        thresholdEdge: CGFloat = 0.08,
        emitDebugOverlay: Bool = true
    ) throws {
        let url = URL(fileURLWithPath: warpedImagePath)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw NSError(domain: "DatasetBuilder", code: -100, userInfo: [NSLocalizedDescriptionKey: "Cannot load warped image at \(warpedImagePath)"])
        }
        try generateDataset(
            from: cg,
            outputDir: outputDir,
            boardSize: boardSize,
            patchSize: patchSize,
            thresholdBrightness: thresholdBrightness,
            thresholdEdge: thresholdEdge,
            emitDebugOverlay: emitDebugOverlay
        )
    }

    // MARK: - Batch Mode
    public static func batchGenerate(
        fromDir: URL,
        outputRoot: URL,
        pattern: String = "final_warped.png",
        recursive: Bool = true,
        boardSize: Int = 1024,
        patchSize: Int = 32,
        thresholdBrightness: CGFloat = 0.15,
        thresholdEdge: CGFloat = 0.08,
        emitDebugOverlay: Bool = true
    ) throws {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: fromDir, includingPropertiesForKeys: [.isDirectoryKey], options: recursive ? [] : [.skipsSubdirectoryDescendants]) else {
            throw NSError(domain: "DatasetBuilder", code: -120, userInfo: [NSLocalizedDescriptionKey: "Cannot enumerate dir: \(fromDir.path)"])
        }

        var count = 0
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent != pattern { continue }

            let parentName = fileURL.deletingLastPathComponent().lastPathComponent
            let outDir = outputRoot.appendingPathComponent(parentName, isDirectory: true)
            try fm.createDirectory(at: outDir, withIntermediateDirectories: true)

            print("▶︎ Processing: \(fileURL.path) -> \(outDir.path)")
            do {
                try generateDataset(
                    fromPath: fileURL.path,
                    outputDir: outDir,
                    boardSize: boardSize,
                    patchSize: patchSize,
                    thresholdBrightness: thresholdBrightness,
                    thresholdEdge: thresholdEdge,
                    emitDebugOverlay: emitDebugOverlay
                )
                count += 1
            } catch {
                fputs("⚠️  Skip \(fileURL.lastPathComponent): \(error)\n", stderr)
            }
        }
        print("✅ Batch done. Processed \(count) file(s).")
    }

    // MARK: - Visualization
    private struct CellVisual {
        let rect: CGRect          // grid rect in image coords (origin at top-left convention we used)
        let occupied: Bool
        let file: Character
        let rank: Int
    }

    /// Paint red (occupied) / green (empty) boxes and file/rank labels; save PNG.
    private static func saveDebugOverlay(
        warpedImage: CGImage,
        cells: [CellVisual],
        boardSize: Int,
        to url: URL
    ) {
        let width = warpedImage.width
        let height = warpedImage.height

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        // Draw base image (CG coords: origin bottom-left)
        ctx.draw(warpedImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        ctx.setLineWidth(2.0)
        ctx.setAllowsAntialiasing(true)

        // Convert our top-left style rect to CG bottom-left rect
        func convert(_ r: CGRect) -> CGRect {
            return CGRect(
                x: r.origin.x,
                y: CGFloat(height) - r.origin.y - r.size.height,
                width: r.size.width,
                height: r.size.height
            )
        }

        for c in cells {
            let r = convert(c.rect)
            if c.occupied {
                ctx.setStrokeColor(NSColor.systemRed.cgColor)
            } else {
                ctx.setStrokeColor(NSColor.systemGreen.cgColor)
            }
            ctx.stroke(r)

            // draw label (file/rank) in the corner
            let label = "\(c.file)\(c.rank)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.white,
                .backgroundColor: NSColor.black.withAlphaComponent(0.45)
            ]

            // Use NSGraphicsContext to draw AppKit text onto this CGContext
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
            // place text near top-left of the cell (in CG coords)
            let pad: CGFloat = 3
            let textRect = CGRect(x: r.minX + pad, y: r.maxY - 16 - pad, width: 40, height: 16)
            label.draw(in: textRect, withAttributes: attrs)
            NSGraphicsContext.restoreGraphicsState()
        }

        // Export PNG
        if let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil),
           let out = ctx.makeImage() {
            CGImageDestinationAddImage(dst, out, nil)
            CGImageDestinationFinalize(dst)
        }
    }

    // MARK: - Image Utilities
    /// 裁剪注意翻转 y（CGImage 原点在左下）
    private static func croppedImage(from cg: CGImage, rect: CGRect) -> CGImage? {
        let r = CGRect(
            x: rect.origin.x,
            y: CGFloat(cg.height) - rect.origin.y - rect.size.height,
            width: rect.size.width,
            height: rect.size.height
        )
        return cg.cropping(to: r)
    }

    /// 平均亮度（0..1），灰度数据基于 0..255
    private static func meanBrightness(of cg: CGImage) -> CGFloat {
        guard let data = grayscaleBuffer(of: cg) else { return 0 }
        var mean: Float = 0
        vDSP_meanv(data, 1, &mean, vDSP_Length(data.count))
        return CGFloat(mean / 255.0)
    }

    /// Sobel 边缘能量（0..1 归一）
    private static func edgeEnergy(of cg: CGImage) -> CGFloat {
        guard var srcData = grayscaleBuffer(of: cg) else { return 0 }
        let w = cg.width
        let h = cg.height

        var gx = [Float](repeating: 0, count: w * h)
        var gy = [Float](repeating: 0, count: w * h)

        let kx: [Float] = [-1, 0, 1,
                           -2, 0, 2,
                           -1, 0, 1]
        let ky: [Float] = [-1, -2, -1,
                             0,  0,  0,
                             1,  2,  1]

        srcData.withUnsafeMutableBufferPointer { srcBuf in
            gx.withUnsafeMutableBufferPointer { gxBuf in
                gy.withUnsafeMutableBufferPointer { gyBuf in
                    var srcBufImg = vImage_Buffer(
                        data: srcBuf.baseAddress,
                        height: vImagePixelCount(h),
                        width:  vImagePixelCount(w),
                        rowBytes: w * MemoryLayout<Float>.size
                    )
                    var gxBufImg = vImage_Buffer(
                        data: gxBuf.baseAddress,
                        height: vImagePixelCount(h),
                        width:  vImagePixelCount(w),
                        rowBytes: w * MemoryLayout<Float>.size
                    )
                    var gyBufImg = vImage_Buffer(
                        data: gyBuf.baseAddress,
                        height: vImagePixelCount(h),
                        width:  vImagePixelCount(w),
                        rowBytes: w * MemoryLayout<Float>.size
                    )

                    kx.withUnsafeBufferPointer { kxPtr in
                        vImageConvolve_PlanarF(
                            &srcBufImg,
                            &gxBufImg,
                            nil, 0, 0,
                            kxPtr.baseAddress!,
                            3, 3,
                            0,
                            vImage_Flags(kvImageEdgeExtend)
                        )
                    }
                    ky.withUnsafeBufferPointer { kyPtr in
                        vImageConvolve_PlanarF(
                            &srcBufImg,
                            &gyBufImg,
                            nil, 0, 0,
                            kyPtr.baseAddress!,
                            3, 3,
                            0,
                            vImage_Flags(kvImageEdgeExtend)
                        )
                    }
                }
            }
        }

        var mag = [Float](repeating: 0, count: w * h)
        vDSP.hypot(gx, gy, result: &mag)

        var mean: Float = 0
        vDSP_meanv(mag, 1, &mean, vDSP_Length(mag.count))

        let norm = max(0, min(mean / 255.0, 1.0))
        return CGFloat(norm)
    }

    /// 将 CGImage 转为灰度 Float 缓冲（0..255）
    private static func grayscaleBuffer(of cg: CGImage) -> [Float]? {
        let w = cg.width
        let h = cg.height

        if cg.colorSpace?.model == .monochrome, cg.bitsPerPixel == 8,
           let dp = cg.dataProvider?.data,
           let p = CFDataGetBytePtr(dp) {
            let count = w * h
            var out = [Float](repeating: 0, count: count)
            for i in 0..<count { out[i] = Float(p[i]) }
            return out
        }

        guard let ctx = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let rgba = ctx.data else { return nil }

        let ptr = rgba.bindMemory(to: UInt8.self, capacity: w * h * 4)
        var out = [Float](repeating: 0, count: w * h)

        let wr: Float = 0.299
        let wg: Float = 0.587
        let wb: Float = 0.114

        for i in 0..<(w*h) {
            let r = Float(ptr[i*4 + 0])
            let g = Float(ptr[i*4 + 1])
            let b = Float(ptr[i*4 + 2])
            out[i] = wr*r + wg*g + wb*b   // 0..255
        }
        return out
    }

    /// 缩放并保存 PNG（targetSize × targetSize）
    private static func saveImage(_ cg: CGImage, to url: URL, targetSize: Int) {
        guard let ctx = CGContext(
            data: nil,
            width: targetSize,
            height: targetSize,
            bitsPerComponent: 8,
            bytesPerRow: targetSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return }

        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: targetSize, height: targetSize))
        guard let scaled = ctx.makeImage() else { return }

        if let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(dst, scaled, nil)
            CGImageDestinationFinalize(dst)
        }
    }
}
