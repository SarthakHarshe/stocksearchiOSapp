//
//  CustomToast.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/28/24.
//

import SwiftUI

struct CustomToast: View {
    var message: String

       var body: some View {
           Text(message)
               .padding()
               .background(Color.black.opacity(0.75))
               .foregroundColor(.white)
               .cornerRadius(10)
               .transition(.opacity)
               .animation(.easeInOut, value: message)
       }
}

#Preview {
    CustomToast(message: "Hello, World!")
}
