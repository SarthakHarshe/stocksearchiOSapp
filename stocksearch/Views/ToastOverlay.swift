//
//  ToastOverlay.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/28/24.
//

import SwiftUI

struct ToastOverlay: View {
    @ObservedObject private var toastManager = GlobalToastManager.shared

    var body: some View {
        VStack {
            Spacer()
            if toastManager.isShowing {
                Text(toastManager.message)
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: toastManager.isShowing)
                    .onAppear {
                        print("ToastOverlay showing: \(toastManager.message)")
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .edgesIgnoringSafeArea(.all)
    }
}



#Preview {
    ToastOverlay()
}
