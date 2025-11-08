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
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // --- Background WebView ---
                    WebViewContainer(
                        id: viewStore.webViewID,
                        url: viewStore.url,
                        onStart: { viewStore.send(.loadStarted) },
                        onFinish: { viewStore.send(.loadFinished) },
                        onFail: { error in viewStore.send(.loadFailed(error.localizedDescription)) }
                    )
                    .ignoresSafeArea()
                    .frame(width: geo.size.width, height: geo.size.height)
                    
                    // --- Left Panel overlay ---
                    LeftPanelView(
                        width: geo.size.width / 6,
                        height: geo.size.height,
                        onReady: { viewStore.send(.readyForAnalyze) }
                    )
                    .frame(
                        width: geo.size.width / 5,
                        height: geo.size.height
                    )
                    .alignmentGuide(.leading) { _ in 0 } // align flush left
                    .alignmentGuide(.top) { _ in 0 }     // align flush top
                    .ignoresSafeArea(edges: [.top, .bottom])
                    
                    // --- Error overlay ---
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
                .onAppear {
                    viewStore.send(.onAppear)
#if os(macOS)
                    // Auto full-screen on macOS
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApp.windows.first?.toggleFullScreen(nil)
                    }
#endif
                }
            }
        }
    }
}
