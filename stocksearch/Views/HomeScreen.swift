//
//  HomeScreen.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI
import LazyViewSwiftUI

struct HomeScreen: View {
    @StateObject var dateViewModel = DateViewModel()
    @StateObject var portfolioViewModel = PortfolioViewModel()
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject var favoritesViewModel = FavoritesViewModel()
    @State private var isSearching = false
    
    var body: some View {
        if !portfolioViewModel.isDataLoadedforportfolio || !favoritesViewModel.isDataLoadedforfavorites {
            ProgressView("Fetching Data...")
                .navigationTitle("Stocks")
                .navigationBarHidden(true)
        } else {
            NavigationView {
                List {
                    if !searchViewModel.searchText.isEmpty {
                        ForEach(searchViewModel.searchResults) { stockSymbol in
                            NavigationLink(destination: LazyView(StockDetailsView(symbol: stockSymbol.symbol, stockService: StockDetailsModel(symbol: stockSymbol.symbol)))) {
                                VStack(alignment: .leading) {
                                    Text(stockSymbol.symbol)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text(stockSymbol.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        Section {
                            DateView(currentDate: dateViewModel.currentDate)
                        }
                        
                        Section(header: Text("Portfolio")) {
                            PortfolioView(viewModel: portfolioViewModel).headerView
                            ForEach(portfolioViewModel.stocks) { stock in
                                NavigationLink(destination: LazyView(StockDetailsView(symbol: stock.symbol, stockService: StockDetailsModel(symbol: stock.symbol)))) {
                                    PortfolioStockRow(stock: stock) // Using the row view here
                                }
                            }
                            .onMove(perform: portfolioViewModel.moveStock)
                            .onAppear {
                                portfolioViewModel.fetchPortfolio()
                                portfolioViewModel.fetchUserData()
                            }
                        }
                        
                        Section(header: Text("Favorites")) {
                            ForEach(favoritesViewModel.favorites) { favorite in
                                NavigationLink(destination: LazyView(StockDetailsView(symbol: favorite.symbol, stockService: StockDetailsModel(symbol: favorite.symbol)))) {
                                    FavoriteStockRow(favorite: favorite)
                                }
                            }
                            .onDelete { offsets in
                                favoritesViewModel.deleteFavorite(at: offsets) { success, message in
                                }
                            }
                            .onMove(perform: favoritesViewModel.moveFavorite)
                        }
                        .onAppear {
                            favoritesViewModel.fetchFavorites()
                        }
                        
                        Section {
                            poweredByLink()
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
                .onAppear {
                    portfolioViewModel.fetchPortfolio()
                }
                .toolbar {
                    EditButton()
                }
            }
        }
    }
    
    private func poweredByLink() -> some View {
        Link("Powered by Finnhub.io", destination: URL(string: "https://www.finnhub.io")!)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}





