//
//  LeftPanelView.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import SwiftUI

/// A side control panel that overlays on top of the WebView.
/// Future expansion: more actions like "Extract Board", "Analyze", "Save Snapshot".
struct LeftPanelView: View {
    let width: CGFloat
    let height: CGFloat
    let onReady: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // --- Ready button ---
            Button(action: onReady) {
                Text("Ready")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
            .padding(.horizontal, 12)

            Divider().padding(.horizontal, 8)

            // --- Placeholder for future controls ---
            VStack(spacing: 10) {
                Text("Panel ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Add analysis tools here…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(width: width, height: height)
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow)
                .opacity(0.9)
        )
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1),
            alignment: .trailing
        )
        .ignoresSafeArea()
    }
}
