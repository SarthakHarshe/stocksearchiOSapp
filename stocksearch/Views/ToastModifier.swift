//
//  ToastModifier.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/27/24.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @ObservedObject private var toastManager = GlobalToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content
            if toastManager.isShowing {
                toastView(toastManager.message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: toastManager.isShowing)
            }
        }
    }

    private func toastView(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .padding()
                .background(Color.black.opacity(0.75))
                .foregroundColor(Color.white)
                .cornerRadius(8)
                .padding(.bottom, 50)
        }
    }
}




#Preview {
    ToastModifier() as! any View
}
