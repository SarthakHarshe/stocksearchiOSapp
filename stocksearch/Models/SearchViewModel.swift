//
//  SearchViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/15/24.
//

import SwiftUI
import Combine
import Alamofire

struct StockSymbol: Identifiable, Decodable {
    let description: String
    let displaySymbol: String
    let symbol: String
    let type: String
    var id: String { symbol }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [StockSymbol] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.processSearchText(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .store(in: &cancellables)
    }

    private func processSearchText(_ searchText: String) {
        guard !searchText.isEmpty else {
            self.searchResults = []
            return
        }

        fetchSuggestions(query: searchText)
    }

    func fetchSuggestions(query: String) {
        let urlString = "https://assignment3-419001.wl.r.appspot.com/autocomplete?q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: urlString) else {
            self.searchResults = []
            return
        }

        AF.request(url, method: .get).validate().responseDecodable(of: [StockSymbol].self) { response in
            switch response.result {
            case .success(let results):
                self.searchResults = results
                print("Received results: \(results.count)")
            case .failure(let error):
                print("Error fetching data: \(error.localizedDescription)")
                self.searchResults = []
            }
        }
    }
}









