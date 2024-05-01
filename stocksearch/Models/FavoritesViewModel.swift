//
//  FavoritesViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/16/24.
//

import Foundation
import Alamofire
import Combine
import SwiftUI


class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteStock] = []
    private let favoritesURL = "https://assignment3-419001.wl.r.appspot.com/watchlist"
    private let quoteURL = "https://assignment3-419001.wl.r.appspot.com/stock_quote"
    var timer: AnyCancellable?
    @Published var isLoading = false
    @Published var isDataLoadedforfavorites = false
    
    
    init() {
        fetchFavorites()
        updateFavoriteStockPrices()
        self.isDataLoadedforfavorites = false
//        startUpdatingFavorites()
    }

    func fetchFavorites() {
        isLoading = true
        AF.request(favoritesURL, method: .get)
            .validate()
            .responseDecodable(of: [FavoriteStock].self) { response in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch response.result {
                    case .success(let fetchedFavorites):
                        self.favorites = fetchedFavorites
                        self.updateFavoriteStockPrices()
                        self.isDataLoadedforfavorites = true
                    case .failure(let error):
                        print("Error fetching favorites: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    func updateFavoriteStockPrices() {
        for favorite in favorites {
            AF.request("https://assignment3-419001.wl.r.appspot.com/stock_quote?symbol=\(favorite.symbol)", method: .get)
                .validate()
                .responseDecodable(of: DetailedStockQuote.self) { [weak self] response in
                    DispatchQueue.main.async {
                        switch response.result {
                        case .success(let quote):
                            if let index = self?.favorites.firstIndex(where: { $0.symbol == favorite.symbol }) {
                                self?.favorites[index].currentPrice = quote.currentPrice
                                self?.favorites[index].change = quote.change
                                self?.favorites[index].changePercentage = quote.changePercentage
                            }
                        case .failure(let error):
                            print("Error fetching stock quote for \(favorite.symbol): \(error)")
                        }
                    }
                }
        }
    }


    
//    func startUpdatingFavorites() {
//           // Start a timer that triggers every 15 seconds
//           timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
//               .sink { [weak self] _ in
//                   self?.updateFavoriteStockPrices()
//               }
//       }
//    
//    func stopUpdatingFavorites() {
//            timer?.cancel()
//        }
    
    func deleteFavorite(at offsets: IndexSet, completion: @escaping (Bool, String) -> Void) {
            for index in offsets {
                let favorite = favorites[index]
                AF.request("https://assignment3-419001.wl.r.appspot.com/watchlist/\(favorite.symbol)", method: .delete)
                    .validate()
                    .response { response in
                        DispatchQueue.main.async {
                            if response.error == nil {
                                self.favorites.remove(at: index)
                                completion(true, "\(favorite.symbol) removed from favorites")
                            } else {
                                completion(false, "Failed to remove \(favorite.symbol) from favorites")
                            }
                        }
                    }
            }
        }
    
    func moveFavorite(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
        // Update the server if necessary
    }
}

// StockQuote structure to decode the response from /stock_quote
struct DetailedStockQuote: Codable {
    let currentPrice: Double
    let change: Double
    let changePercentage: Double

    enum CodingKeys: String, CodingKey {
        case currentPrice = "c"
        case change = "d"
        case changePercentage = "dp"
    }
}

