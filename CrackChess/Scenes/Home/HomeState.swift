//
//  HomeState.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import ComposableArchitecture
import SwiftUI

struct HomeState: Equatable, Sendable {
    var url = URL(string: "https://www.chesskid.com/home")!
    var isLoading = true
    var loadError: String?
    var webViewID = UUID()
    
    var isCapturing = false
    var captureError: String?
    var snapshotImage: NSImage?
    
    var isClassifying = false
    var classifiedStatus: GameStatus?
    var classifyError: String?
}
