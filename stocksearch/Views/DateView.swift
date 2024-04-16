//
//  DateView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI

struct DateView: View {
    var currentDate: String
    
    var body: some View {
        HStack {
            Text(currentDate)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.gray)
            Spacer()
        }
        .padding(3)
    }
}

#Preview {
    DateView(currentDate: "April 13, 2024")
}
