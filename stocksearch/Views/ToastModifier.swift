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
                    .animation(.easeInOut(duration: 0.3), value: toastManager.isShowing)
            }
        }
    }

    private func toastView(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .padding(20)
                .background(Color.gray)
                .foregroundColor(.white.opacity(0.60))
                .cornerRadius(50)
                .padding(.bottom, 30)
                .font(.title2)
        }
    }
}




#Preview {
    ToastModifier() as! any View
}
