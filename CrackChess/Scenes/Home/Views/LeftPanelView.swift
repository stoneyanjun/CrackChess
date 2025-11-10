//
//  LeftPanelView.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import SwiftUI
struct LeftPanelView: View {
    let width: CGFloat
    let height: CGFloat
    let onCapture: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // --- Capture button ---
            Button(action: onCapture) {
                Label("Capture Board", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
            .padding(.horizontal, 12)
            
            Divider().padding(.horizontal, 8)

            VStack(spacing: 10) {
                Text("Panel ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Use buttons to capture and analyze board.")
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
