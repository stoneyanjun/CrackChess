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
                    // --- 1️⃣ WebView background ---
                    WebViewContainer(
                        id: viewStore.webViewID,
                        url: viewStore.url,
                        onStart: { viewStore.send(.loadStarted) },
                        onFinish: { viewStore.send(.loadFinished) },
                        onFail: { error in viewStore.send(.loadFailed(error.localizedDescription)) }
                    )
                    .ignoresSafeArea()

                    // --- 2️⃣ Left control panel ---
                    LeftPanelView(
                        width: geo.size.width / 6,
                        height: geo.size.height,
                        onCapture: { viewStore.send(.captureStarted) }
                    )

                    // --- 3️⃣ Snapshot preview overlay ---
                    if let image = viewStore.snapshotImage {
                        VStack(spacing: 6) {
                            Text("📸 Snapshot Preview")
                                .font(.headline)
                                .padding(.top, 8)

                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width / 3)
                                .cornerRadius(12)
                                .shadow(radius: 6)

                            Button("Close Preview") {
                                // remove preview only (keep ability to recapture)
                                viewStore.send(.captureCompleted(.failure("discarded")))
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom, 8)
                        }
                        .frame(width: geo.size.width / 3)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.6))
                                .blur(radius: 1)
                        )
                        .foregroundColor(.white)
                        .padding()
                        .position(x: geo.size.width - (geo.size.width / 6),
                                  y: geo.size.height / 2)
                        .animation(.easeInOut(duration: 0.25), value: viewStore.snapshotImage)
                    }

                    // --- 4️⃣ Error overlay ---
                    if let error = viewStore.loadError ?? viewStore.captureError {
                        VStack(spacing: 12) {
                            Text("⚠️ Error")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            Button("Reload") {
                                viewStore.send(.reload)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.7)))
                        .foregroundColor(.white)
                    }

                    // --- 5️⃣ Loading overlay ---
                    if viewStore.isCapturing {
                        ProgressView("Capturing...")
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
#if os(macOS)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApp.windows.first?.toggleFullScreen(nil)
                    }
#endif
                }
            }
        }
    }
}
