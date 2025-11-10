//
//  HomeAction.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import SwiftUI
import ComposableArchitecture

enum CaptureResult: Equatable, Sendable {
    case success(NSImage)
    case failure(String)
}
enum ClassificationResult: Equatable, Sendable {
    case success(GameStatus)
    case failure(String)
}

enum HomeAction: Equatable, Sendable {
    case onAppear
    case loadStarted
    case loadFinished
    case loadFailed(String)
    case reload
    
    case captureStarted
    case captureCompleted(CaptureResult)
    
    case classifyStarted
    case classifyCompleted(ClassificationResult)
}
