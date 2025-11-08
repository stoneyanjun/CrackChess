//
//  WebCoordinator.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//


import SwiftUI
import WebKit

//
// MARK: - WebCoordinator (WKNavigationDelegate)
//

final class WebCoordinator: NSObject, WKNavigationDelegate {
    var currentID: UUID
    let onStart: () -> Void
    let onFinish: () -> Void
    let onFail: (Error) -> Void
    
    init(currentID: UUID,
         onStart: @escaping () -> Void,
         onFinish: @escaping () -> Void,
         onFail: @escaping (Error) -> Void) {
        self.currentID = currentID
        self.onStart = onStart
        self.onFinish = onFinish
        self.onFail = onFail
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🌐 Start loading:", webView.url?.absoluteString ?? "")
        onStart()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Only count main-frame completion
        if webView.url?.host?.contains("chesskid.com") == true {
            print("✅ Finished main frame:", webView.url?.absoluteString ?? "")
            onFinish()
        } else {
            print("ℹ️ Ignored sub-frame load:", webView.url?.absoluteString ?? "")
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Navigation failed:", error.localizedDescription)
        onFail(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("⚠️ Provisional navigation failed:", error.localizedDescription)
        onFail(error)
    }
}
