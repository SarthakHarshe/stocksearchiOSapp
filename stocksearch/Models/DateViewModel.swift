//
//  DateViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import Foundation

class DateViewModel: ObservableObject {
    @Published var currentDate: String = ""
    
    init() {
        updateDate()
    }
    
    func updateDate() {
        let date = Date()
        let format = DateFormatter()
        format.dateStyle = .medium
        format.timeStyle = .none
        format.locale = Locale(identifier: "en_US")
        currentDate = format.string(from: date)
    }
}
