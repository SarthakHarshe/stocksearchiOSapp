//
//  StockDetailsModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/17/24.
//

import Foundation
import Alamofire
import Combine

struct StockInfo: Decodable {
    let currentPrice: Double
    let change: Double
    let changePercentage: Double
    let name: String?
    
    enum CodingKeys: String, CodingKey {
            case currentPrice = "c"
            case change = "d"
            case changePercentage = "dp"
            case name
        }
}

struct CompanyProfile: Decodable {
    let name: String
    let exchange: String
    let logo: String

    
    enum CodingKeys: String, CodingKey {
            case name
            case exchange
            case logo
        }
}

struct WatchlistStock: Decodable {
    let symbol: String
    let name: String
    let exchange: String
    let logo: String
    let currentPrice: Double
    let change: Double
    let changePercentage: Double
}

struct WatchlistParameters: Encodable {
    let symbol: String
    let name: String
    let exchange: String
    let logo: String
    let currentPrice: Double
    let change: Double
    let changePercentage: Double
    let timestamp: Int64
    
    enum CodingKeys: String, CodingKey {
            case symbol
            case name
            case exchange
            case logo
            case currentPrice
            case change
            case changePercentage
            case timestamp
        }
}


class StockDetailsModel: ObservableObject {
    @Published var stockInfo: StockInfo?
    @Published var companyProfile: CompanyProfile?
    @Published var isLoading = true
    @Published var isFavorite = false
    private var symbol: String
    
    private let quoteURL = "http://localhost:3000/stock_quote"
    private let profileURL = "http://localhost:3000/company_profile"
    private let watchlistURL = "http://localhost:3000/watchlist"
    
    
    init(symbol: String) {
            self.symbol = symbol
            checkIfFavorite()
            fetchStockDetails(symbol: symbol)
        }
    
    
    func addToFavorites() {
        guard let stock = stockInfo, let profile = companyProfile else { return }

        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let params = WatchlistParameters(
            symbol: self.symbol,
            name: profile.name,
            exchange: profile.exchange,
            logo: profile.logo,
            currentPrice: stock.currentPrice,
            change: stock.change,
            changePercentage: stock.changePercentage,
            timestamp: currentTime
        )

        AF.request("\(watchlistURL)", method: .post, parameters: params, encoder: JSONParameterEncoder.default).response { response in
            switch response.result {
            case .success(_):
                print("Added to favorites successfully")
                self.isFavorite = true
            case .failure(let error):
                print("Failed to add to favorites: \(error.localizedDescription)")
            }
        }
    }


    func removeFromFavorites() {
            AF.request("\(watchlistURL)/\(symbol)", method: .delete).response { response in
                switch response.result {
                case .success(_):
                    print("Removed from favorites")
                    self.isFavorite = false
                case .failure(let error):
                    print("Failed to remove from favorites: \(error.localizedDescription)")
                }
            }
        }
    
    func checkIfFavorite() {
        AF.request(watchlistURL).responseDecodable(of: [WatchlistStock].self) { response in
            DispatchQueue.main.async {
                switch response.result {
                case .success(let favorites):
                    self.isFavorite = favorites.contains { $0.symbol == self.symbol }
                case .failure(let error):
                    print("Failed to fetch favorites: \(error.localizedDescription)")
                }
            }
        }
    }


    
    func fetchStockDetails(symbol: String) {
            isLoading = true
            let group = DispatchGroup()
            
            group.enter()
                AF.request("\(quoteURL)?symbol=\(symbol)").responseDecodable(of: StockInfo.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let stockInfo):
                        self.stockInfo = stockInfo
                    case .failure(let error):
                        print("Stock quote fetching error: \(error)")
                    }
                    group.leave()
                }
            }
            
            group.enter()
                AF.request("\(profileURL)?symbol=\(symbol)").responseDecodable(of: CompanyProfile.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let profile):
                        self.companyProfile = profile
                    case .failure(let error):
                        print("Company profile fetching error: \(error)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.isLoading = false
                self.checkIfFavorite()
            }
        }
}


