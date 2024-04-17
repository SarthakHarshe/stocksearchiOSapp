//
//  FavoriteStockModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/16/24.
//

struct FavoriteStock: Identifiable, Codable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let currentPrice: Double
    var change: Double
    var changePercentage: Double
}
