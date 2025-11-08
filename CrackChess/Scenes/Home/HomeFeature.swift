//
//  HomeFeature.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import ComposableArchitecture
import WebKit

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var url = URL(string: "https://www.chesskid.com/home")!
        var isLoading = true
        var loadError: String?
        var webViewID = UUID()       // used to force reload if needed
    }

    enum Action: Equatable, Sendable {
        case onAppear
        case loadStarted
        case loadFinished
        case loadFailed(String)
        case reload
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
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
            // force recreate WKWebView
            state.webViewID = UUID()
            state.isLoading = true
            state.loadError = nil
            return .none
        }
    }
}
