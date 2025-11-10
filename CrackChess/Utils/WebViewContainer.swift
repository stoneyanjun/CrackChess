//
//  WebViewContainer.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import SwiftUI
import WebKit
import Dependencies

// MARK: - WKWebView container (macOS)
struct WebViewContainer: NSViewRepresentable {
    let id: UUID
    let url: URL
    let onStart: () -> Void
    let onFinish: () -> Void
    let onFail: (Error) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // 💾 Store reference for global snapshot access
        CurrentWebViewHolder.webView = webView

        // 🌐 Load initial page
        print("🌐 [WebViewContainer] Loading URL:", url.absoluteString)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 🌀 Reload if ID changes (triggered by .reload)
        if context.coordinator.currentID != id {
            context.coordinator.currentID = id
            print("♻️ [WebViewContainer] Reload triggered for:", url.absoluteString)
            nsView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> WebCoordinator {
        WebCoordinator(
            currentID: id,
            onStart: onStart,
            onFinish: onFinish,
            onFail: onFail
        )
    }
}
