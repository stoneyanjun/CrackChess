import Vision
import CoreGraphics

public struct VisionClientConfig: Sendable {
    public var minAspect: Float = 0.8
    public var maxAspect: Float = 1.25
    public var minConfidence: Float = 0.6
    public var maxObservations: Int = 6
    public init() {}
}

public enum VisionClient {
    public static func detectBoardQuad(from cgImage: CGImage,
                                       config: VisionClientConfig = .init()
    ) throws -> (quad: BoardQuad, confidence: Double)? {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let req = VNDetectRectanglesRequest()
        req.minimumAspectRatio = config.minAspect
        req.maximumAspectRatio = config.maxAspect
        req.minimumConfidence  = config.minConfidence
        req.maximumObservations = config.maxObservations

        try handler.perform([req])

        guard let obs = req.results as? [VNRectangleObservation], !obs.isEmpty else {
            return nil
        }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        func scale(_ n: CGPoint) -> CGPoint { CGPoint(x: n.x*size.width, y: (1-n.y)*size.height) }

        var best: (BoardQuad, Double)? = nil
        for o in obs {
            let quad = Geometry.orderQuad([o.topLeft, o.topRight, o.bottomRight, o.bottomLeft].map(scale))
            let sq = Geometry.squareness(quad)
            let area = Geometry.area(quad)
            let areaFrac = Double(area / (size.width * size.height))
            let score = Double(o.confidence) * sq * min(1.0, max(0.0, areaFrac / 0.22))
            if best == nil || score > best!.1 { best = (quad, score) }
        }
        return best.map { ($0.0, $0.1) }
    }
}
