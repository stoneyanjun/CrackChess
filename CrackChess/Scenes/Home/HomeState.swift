//
//  HomeState.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

import Foundation
import ComposableArchitecture

struct HomeState: Equatable, Sendable {
    var url = URL(string: "https://www.chesskid.com/home")!
    var isLoading = true
    var loadError: String?
    var webViewID = UUID()
}
