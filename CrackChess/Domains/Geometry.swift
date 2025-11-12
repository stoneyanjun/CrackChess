import CoreGraphics

public enum Geometry {
    /// 将任意4点稳定排序为 TL, TR, BR, BL
    public static func orderQuad(_ pts: [CGPoint]) -> BoardQuad {
        precondition(pts.count == 4)
        let s = pts.sorted { a, b in a.y == b.y ? a.x < b.x : a.y < b.y }
        let upper = [s[0], s[1]].sorted { $0.x < $1.x }
        let lower = [s[2], s[3]].sorted { $0.x < $1.x }
        return BoardQuad(tl: upper[0], tr: upper[1], br: lower[1], bl: lower[0])
    }

    public static func area(_ q: BoardQuad) -> CGFloat {
        let p = q.points
        var s: CGFloat = 0
        for i in 0..<4 {
            let a = p[i], b = p[(i+1)%4]
            s += (a.x*b.y - b.x*a.y)
        }
        return abs(s) * 0.5
    }

    /// 近方形度（0~1；1越接近正方）
    public static func squareness(_ q: BoardQuad) -> Double {
        func d(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x-b.x, a.y-b.y) }
        let wTop = d(q.tl, q.tr), wBot = d(q.bl, q.br)
        let hL = d(q.tl, q.bl), hR = d(q.tr, q.br)
        let w = (wTop + wBot) * 0.5, h = (hL + hR) * 0.5
        return Double(min(w, h) / max(w, h))
    }
}
