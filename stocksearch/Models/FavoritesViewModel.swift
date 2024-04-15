//
//  FavoritesViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/14/24.
//

import Foundation
import Combine
import Alamofire

class FavoritesViewModel: ObservableObject {
    // Published properties that the view will listen to
    @Published var favorites: [Stock] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    
    // URLs for the backend endpoints
    private let watchlistURL = "http://localhost:3000/watchlist"
    private let stockQuoteURL = "http://localhost:3000/stock_quote"
    
    //Defining the struct for stockquote
    private struct Quote: Decodable {
        let currentPrice: Double
        let change: Double
        let percentChange: Double
        
        enum CodingKeys: String, CodingKey {
            case currentPrice = "c"
            case change = "d"
            case percentChange = "dp"
        }
    }
    
    
    // Fetches the watchlist
    func fetchFavorites() {
        isLoading = true
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .millisecondsSince1970
        AF.request(watchlistURL, method: .get)
            .validate()
            .responseDecodable(of: [Stock].self, decoder: decoder) { response in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch response.result {
                    case .success(let fetchedFavorites):
                        if let firstStock = fetchedFavorites.first {
                            self.favorites = [firstStock]
                        } else {
                            self.favorites = fetchedFavorites
                            debugPrint("Fetched favorites: \(fetchedFavorites)");
                            print("Fetched favorites: \(fetchedFavorites)");
                            debugPrint("Fetched favorites: \(self.favorites)");
                            self.fetchPriceChanges()
                            debugPrint("Fetched price changes");
                        }
                    case .failure(let error):
                        print("Failed to fetch favorites: \(error.localizedDescription)");
                        self.errorMessage = "Failed to fetch favorites: \(error.localizedDescription)"
                        let responseString = String(decoding: response.data ?? Data(), as: UTF8.self)
                        print("Raw API Response: \(responseString)");
                        self.errorMessage += "\nResponse: \(responseString)"
                    }
                }
            }
    }
    
    
    
    // Fetch price changes for each stock in the watchlist
    private func fetchPriceChanges() {
        for i in 0..<favorites.count {
            let stock = favorites[i]
            guard let url = URL(string: "\(stockQuoteURL)?symbol=\(stock.symbol)") else { continue }
            
            AF.request(url, method: .get)
                .validate()
                .responseDecodable(of: Quote.self) { [weak self] response in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch response.result {
                        case .success(let quote):
                            self.favorites[i].currentPrice = quote.currentPrice
                            self.favorites[i].priceChange = quote.change
                            self.favorites[i].priceChangePercentage = quote.percentChange
                        case .failure(let error):
                            if let data = response.data, let str = String(data: data, encoding: .utf8) {
                                self.errorMessage = "Failed to fetch price change: \(error.localizedDescription)\nRaw response: \(str)"
                            } else {
                                self.errorMessage = "Failed to fetch price change: \(error.localizedDescription)\nRaw response: Could not decode error response."
                            }
                        }
                    }
                }
        }
    }
}
