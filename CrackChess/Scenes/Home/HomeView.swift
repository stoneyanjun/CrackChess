//
//  HomeView.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import SwiftUI
import WebKit
import ComposableArchitecture

struct HomeView: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                // WebView Container
                WebViewContainer(
                    id: viewStore.webViewID,
                    url: viewStore.url,
                    onStart: { viewStore.send(.loadStarted) },
                    onFinish: { viewStore.send(.loadFinished) },
                    onFail: { error in viewStore.send(.loadFailed(error.localizedDescription)) }
                )

                // Optional loading overlay
                if viewStore.isLoading {
                    ProgressView("Loading…")
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.6))
                        )
                        .foregroundColor(.white)
                }

                // Optional error display
                if let error = viewStore.loadError {
                    VStack(spacing: 12) {
                        Text("⚠️ Failed to load page")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("Reload") {
                            viewStore.send(.reload)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
                }
            }
            .onAppear { viewStore.send(.onAppear) }
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// A SwiftUI wrapper for WKWebView with navigation delegate callbacks.
private struct WebViewContainer: NSViewRepresentable {
    let id: UUID
    let url: URL
    let onStart: () -> Void
    let onFinish: () -> Void
    let onFail: (Error) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Reload only when ID changes (e.g. after .reload action)
        if context.coordinator.currentID != id {
            context.coordinator.currentID = id
            nsView.load(URLRequest(url: url))
        }
    }
    
    // Inside HomeView.swift
    func makeCoordinator() -> Coordinator {
        Coordinator(
            currentID: id,
            onStart: onStart,
            onFinish: onFinish,
            onFail: onFail
        )
    }
}
