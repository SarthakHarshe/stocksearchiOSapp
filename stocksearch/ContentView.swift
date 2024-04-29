//
//  ContentView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeScreen()
            .modifier(ToastModifier())
    }
}

#Preview {
    ContentView()
}
