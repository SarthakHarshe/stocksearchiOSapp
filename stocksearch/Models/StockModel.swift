//
//  StockModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import Foundation
import Combine

class Stock: Identifiable, Codable, ObservableObject {
    var id: String
    var symbol: String
    var name: String
    var currentPrice: Double
    var quantity: Int
    var averageCost: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case symbol
        case name
        case currentPrice
        case quantity
        case averageCost
    }

    var totalCost: Double { Double(quantity) * averageCost }
    var marketValue: Double { Double(quantity) * currentPrice }
    var changeFromTotalCost: Double { (currentPrice - averageCost) * Double(quantity) }
    var changeFromTotalCostPercentage: Double {
        if totalCost == 0 { return 0 }
        return (changeFromTotalCost / totalCost) * 100
    }

    init(id: String, symbol: String, name: String, currentPrice: Double, quantity: Int, averageCost: Double) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.quantity = quantity
        self.averageCost = averageCost
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        quantity = try container.decode(Int.self, forKey: .quantity)
        averageCost = try container.decode(Double.self, forKey: .averageCost)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(currentPrice, forKey: .currentPrice)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(averageCost, forKey: .averageCost)
    }
}
