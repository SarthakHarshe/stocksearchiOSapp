//
//  HomeScreen.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject var dateViewModel = DateViewModel()
    @StateObject var portfolioViewModel = PortfolioViewModel()
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject var favoritesViewModel = FavoritesViewModel()
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            List {
                if !searchViewModel.searchText.isEmpty {
                    ForEach(searchViewModel.searchResults) { stockSymbol in
                            VStack(alignment: .leading) {
                                Text(stockSymbol.symbol)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(stockSymbol.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                    }
                } else {
                    Section {
                        DateView(currentDate: dateViewModel.currentDate)
                    }
                    
                    Section(header: Text("Portfolio")) {
                        PortfolioView(viewModel: portfolioViewModel)
                    }
                    
                    Section(header: Text("Favorites")) {
                                            FavoritesView(viewModel: favoritesViewModel)
                    }
                    
                    Section {
                                        Link("Powered by Finnhub.io", destination: URL(string: "https://www.finnhub.io")!)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                }
            }
            .navigationTitle("Stocks")
            .searchable(text: $searchViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchViewModel.searchText, initial: true) { _, newValue in
                isSearching = !newValue.isEmpty
                if newValue.isEmpty {
                    searchViewModel.searchResults.removeAll()
                }
            }
            .toolbar {
                EditButton()
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}



