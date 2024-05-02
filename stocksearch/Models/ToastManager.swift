//
//  ToastManager.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/27/24.
//

import SwiftUI

class GlobalToastManager: ObservableObject {
    static let shared = GlobalToastManager()

    @Published var isShowing = false
    @Published var message = ""

    func show(message: String) {
        print("Toast requested: \(message)")
        DispatchQueue.main.async {
            if self.isShowing {
                print("Attempt to show toast while another is visible: \(message)")
                return
            }
            self.message = message
            self.isShowing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isShowing = false
            }
        }
    }
}
