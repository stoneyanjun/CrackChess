//
//  HomeAction.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import ComposableArchitecture

enum HomeAction: Equatable, Sendable {
    case onAppear
    case loadStarted
    case loadFinished
    case loadFailed(String)
    case reload
    case readyForAnalyze
}
