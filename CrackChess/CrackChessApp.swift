//
//  CrackChessApp.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//

/*
import SwiftUI
import ComposableArchitecture

@main
struct CrackChessApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(
                store: Store(
                    initialState: HomeFeature.State(),
                    reducer: { HomeFeature() }
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
*/
import SwiftUI
import ComposableArchitecture

@main
struct CrackChessApp: App {
    var body: some Scene {
        WindowGroup("CrackChess") {
            HomeView(
                store: Store(
                    initialState: HomeState(),
                    reducer: { HomeFeature() }
                )
            )
            .frame(minWidth: 720, minHeight: 520)
        }
        .windowStyle(.automatic)
    }
}
