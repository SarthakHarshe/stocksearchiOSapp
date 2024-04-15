//
//  HomeScreen.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject var viewModel = HomeScreenViewModel()
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            List {
                
                // Search Bar Section
                if isSearching {
                    ForEach(viewModel.searchViewModel.searchResults) { stockSymbol in
                        Button(action: {
                            // Handle the selection, potentially navigate to details view
                            // For now, we'll just print the symbol
                            print("Selected symbol: \(stockSymbol.symbol)")
                        }) {
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
                
                
                if !isSearching {
                                   Section {
                                       DateView(currentDate: viewModel.dateViewModel.currentDate)
                                   }
                                   
                                   Section(header: Text("Portfolio").font(.headline)) {
                                       PortfolioView(viewModel: viewModel.portfolioViewModel)
                                   }
                               }
            }
            .navigationTitle("Stocks")
            .searchable(text: $viewModel.searchViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always)) {
                // The empty placeholder ensures that suggestions do not pop up on the navigation bar.
            }
            .onChange(of: viewModel.searchViewModel.searchText, initial: false) { oldSearchText, newSearchText in
                isSearching = !newSearchText.isEmpty
                if !isSearching {
                                   // Collapse the search results when search text is cleared
                                   viewModel.searchViewModel.searchResults.removeAll()
                               }
            }
            .toolbar {
                EditButton()
            }
            
        }
    }
}

class HomeScreenViewModel: ObservableObject {
    @Published var dateViewModel = DateViewModel()
    @Published var portfolioViewModel = PortfolioViewModel()
    @Published var searchViewModel = SearchViewModel()
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
