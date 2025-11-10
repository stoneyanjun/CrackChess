//
//  WebSnapshotter.swift
//  CrackChess
//
//  Created by stone on 2025/11/9.
//

import Foundation
import WebKit
import Dependencies
import AppKit

// MARK: - Shared holder for the live WKWebView instance
enum CurrentWebViewHolder {
    static weak var webView: WKWebView?
}

// MARK: - Snapshot dependency client
struct WebSnapshotter {
    var takeSnapshot: @Sendable () async throws -> NSImage
}

// MARK: - DependencyKey conformance
extension WebSnapshotter: DependencyKey {
    static let liveValue = WebSnapshotter {
        // 🔍 1. Ensure the WebView is available
        guard let webView = CurrentWebViewHolder.webView else {
            throw NSError(
                domain: "WebSnapshotter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "WebView not available for snapshot"]
            )
        }

        // 📸 2. Perform the snapshot asynchronously
        return try await withCheckedThrowingContinuation { cont in
            let config = WKSnapshotConfiguration()
            config.afterScreenUpdates = true
            webView.takeSnapshot(with: config) { image, error in
                if let error = error {
                    print("❌ [WebSnapshotter] Snapshot failed: \(error.localizedDescription)")
                    cont.resume(throwing: error)
                } else if let image = image {
                    print("✅ [WebSnapshotter] Snapshot captured successfully (\(image.size.width)x\(image.size.height))")
                    cont.resume(returning: image)
                } else {
                    cont.resume(throwing: NSError(
                        domain: "WebSnapshotter",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown snapshot error"]
                    ))
                }
            }
        }
    }
}

// MARK: - Register dependency
extension DependencyValues {
    var webSnapshotter: WebSnapshotter {
        get { self[WebSnapshotter.self] }
        set { self[WebSnapshotter.self] = newValue }
    }
}
