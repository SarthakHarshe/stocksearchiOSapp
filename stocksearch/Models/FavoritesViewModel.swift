//
//  FavoritesViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/16/24.
//

import Foundation
import Alamofire
import Combine


class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteStock] = []
    private let favoritesURL = "http://localhost:3000/watchlist"
    var timer: AnyCancellable?

    func fetchFavorites() {
        AF.request(favoritesURL, method: .get)
            .validate()
            .responseDecodable(of: [FavoriteStock].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let fetchedFavorites):
                        self.favorites = fetchedFavorites
                    case .failure(let error):
                        print("Error fetching favorites: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    func startUpdatingFavorites() {
           // Start a timer that triggers every 15 seconds
           timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
               .sink { [weak self] _ in
                   self?.fetchFavorites()
               }
       }
    
    func stopUpdatingFavorites() {
            timer?.cancel()
        }
    
    func deleteFavorite(at offsets: IndexSet) {
        offsets.forEach { index in
            let favorite = favorites[index]
            AF.request("http://localhost:3000/watchlist/\(favorite.symbol)", method: .delete)
                .validate()
                .response { response in
                    DispatchQueue.main.async {
                        if response.error == nil {
                            self.favorites.remove(at: index)
                        } else {
                            // Handle the error properly
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
