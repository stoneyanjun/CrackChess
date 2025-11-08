//
//  HomeFeature.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import ComposableArchitecture

@Reducer
struct HomeFeature {
    
    typealias State = HomeState
    typealias Action = HomeAction
    
    func reduce(into state: inout State, action: Action) -> Effect<Action>  {
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
            state.isReadyForAnalyze = true
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

        case .readyForAnalyze:
            state.isReadyForAnalyze = true
            return .none
        }
    }
}
