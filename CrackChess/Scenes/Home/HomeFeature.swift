//
//  HomeFeature.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import ComposableArchitecture
import AppKit

@Reducer
struct HomeFeature {

    // MARK: - Types
    typealias State = HomeState
    typealias Action = HomeAction

    // MARK: - Dependencies
    @Dependency(\.webSnapshotter) var webSnapshotter

    // MARK: - Reducer
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {

        // --- 1️⃣ Page loading lifecycle ---
        case .onAppear:
            state.isLoading = true
            state.loadError = nil
            return .none

        case .loadStarted:
            state.isLoading = true
            state.loadError = nil
            return .none

        case .loadFinished:
            state.isLoading = false
            return .none

        case let .loadFailed(message):
            state.isLoading = false
            state.loadError = message
            return .none

        case .reload:
            state.webViewID = UUID()
            state.isLoading = true
            state.loadError = nil
            return .none

        // --- 2️⃣ Snapshot capture start ---
        case .captureStarted:
            state.isCapturing = true
            state.captureError = nil
            state.snapshotImage = nil
            print("📸 [HomeFeature] Starting WKWebView snapshot...")

            // Asynchronously request a snapshot from the dependency
            return .run { send in
                do {
                    let image = try await webSnapshotter.takeSnapshot()
                    await send(.captureCompleted(.success(image)))
                } catch {
                    await send(.captureCompleted(.failure(error.localizedDescription)))
                }
            }

        // --- 3️⃣ Snapshot capture result ---
        case let .captureCompleted(result):
            state.isCapturing = false
            switch result {
            case let .success(image):
                state.snapshotImage = image
                print("✅ [HomeFeature] Snapshot stored in state (\(image.size.width)x\(image.size.height))")
                return .send(.classifyStarted)
            case let .failure(message):
                state.captureError = message
                print("❌ [HomeFeature] Snapshot failed: \(message)")
            }
            return .none
            
        case .classifyStarted:
            state.isClassifying = true
            state.classifyError = nil
            print("🔎 [HomeFeature] Starting board classification...")
            return .run { [image = state.snapshotImage] send in
                do {
                    let status = try await BoardAnalyzer.analyze(snapshot: image)
                    await send(.classifyCompleted(.success(status)))
                } catch {
                    await send(.classifyCompleted(.failure(error.localizedDescription)))
                }
            }

        case let .classifyCompleted(result):
            state.isClassifying = false
            switch result {
            case let .success(status):
                state.classifiedStatus = status
                print("✅ [HomeFeature] Classification complete. Pieces:")
            case let .failure(message):
                state.classifyError = message
                print("❌ [HomeFeature] Classification failed:", message)
            }
            return .none
        }
    }
}
