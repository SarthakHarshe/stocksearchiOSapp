//
//  HomeScreen.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject var viewModel = HomeScreenViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // Date Section
                Section {
                    DateView(currentDate: viewModel.dateViewModel.currentDate)
                }
                
                
                // Portfolio Section
                Section(header: Text("Portfolio").font(.headline)) {
                    PortfolioView(viewModel: viewModel.portfolioViewModel)
                }
            }
            .navigationTitle("Stocks")
            .toolbar {
                EditButton()
            }
           
        }
    }
}

class HomeScreenViewModel: ObservableObject {
    @Published var dateViewModel = DateViewModel()
    @Published var portfolioViewModel = PortfolioViewModel()
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
