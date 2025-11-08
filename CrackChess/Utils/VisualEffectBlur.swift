//
//  VisualEffectBlur.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import SwiftUI

/// A reusable macOS blur background view, wrapping `NSVisualEffectView`.
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
