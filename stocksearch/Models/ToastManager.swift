//
//  ToastManager.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/27/24.
//

import SwiftUI

class GlobalToastManager: ObservableObject {
    static let shared = GlobalToastManager()  // Singleton instance for global access

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {  // Auto dismiss after 3 seconds (change it to lesser time check video)
                self.isShowing = false
            }
        }
    }
}
