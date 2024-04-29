//
//  stocksearchApp.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI

@main
struct stocksearchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GlobalToastManager.shared)
                
        }
    }
}
