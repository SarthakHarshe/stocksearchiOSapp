//
//  SearchViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/15/24.
//

import SwiftUI
import Combine

struct StockSymbol: Identifiable, Decodable {
    let description: String
    let displaySymbol: String
    let symbol: String
    let type: String

    // Conform to Identifiable by providing a unique ID
    var id: String { symbol }
}


class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [StockSymbol] = []
    private var cancellables = Set<AnyCancellable>()
    private let debouncePeriod: TimeInterval = 0.2

    init() {
        $searchText
            .removeDuplicates()
            .debounce(for: .seconds(debouncePeriod), scheduler: RunLoop.main)
            .map { $0.uppercased() }
            .sink { [weak self] in self?.fetchSuggestions(query: $0) }
            .store(in: &cancellables)
    }

    func fetchSuggestions(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        let urlString = "http://localhost:3000/autocomplete?q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [StockSymbol].self, decoder: JSONDecoder())
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$searchResults)
    }
}
