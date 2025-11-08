//
//  Coordinator.swift
//  CrackChess
//
//  Created by stone on 2025/11/8.
//
import Foundation
import WebKit

class Coordinator: NSObject, WKNavigationDelegate {
    var currentID: UUID
    let onStart: () -> Void
    let onFinish: () -> Void
    let onFail: (Error) -> Void

    init(currentID: UUID,
         onStart: @escaping () -> Void,
         onFinish: @escaping () -> Void,
         onFail: @escaping (Error) -> Void) {
        self.currentID = currentID
        self.onStart = onStart
        self.onFinish = onFinish
        self.onFail = onFail
    }
}
