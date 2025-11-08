//
//  WebViewContainer.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//


import SwiftUI
import WebKit
//
// MARK: - WKWebView container
//

struct WebViewContainer: NSViewRepresentable {
    let id: UUID
    let url: URL
    let onStart: () -> Void
    let onFinish: () -> Void
    let onFail: (Error) -> Void
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator     // ✅ coordinator is a real object here
        webView.load(URLRequest(url: url))
        
        // Optional timeout to clear loading overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if webView.isLoading {
                print("⚠️ Timeout – forcing onFinish()")
                onFinish()
            }
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.currentID != id {
            context.coordinator.currentID = id
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
