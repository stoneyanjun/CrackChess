import CoreGraphics

public struct BoardQuad: Sendable, Equatable {
    public let tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint
    public init(tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint) {
        self.tl = tl; self.tr = tr; self.br = br; self.bl = bl
    }
    public var points: [CGPoint] { [tl, tr, br, bl] }
}

public struct Homography: Sendable, Equatable {
    /// Row-major 3×3
    public let h: [Double]
    public init(_ h: [Double]) { precondition(h.count == 9); self.h = h }
}

public struct BoardRectifyResult: Sendable, Equatable {
    public let quad: BoardQuad
    public let homography: Homography
    public let warped: CGImage
    public let score: Double
}
