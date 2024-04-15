//
//  SearchView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/15/24.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.searchResults) { stockSymbol in
                    NavigationLink(destination: StockDetailView(symbol: stockSymbol.symbol)) {
                        VStack(alignment: .leading) {
                            Text(stockSymbol.symbol)
                                .fontWeight(.bold)
                            Text(stockSymbol.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.searchText, prompt: "Search for a stock")
            .disableAutocorrection(true)
            .onSubmit(of: .search) {
                // Do nothing to prevent navigation when pressing Enter.
            }
        }
    }
}

// Dummy stock detail view
struct StockDetailView: View {
    let symbol: String
    
    var body: some View {
        Text("Details for \(symbol)")
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
