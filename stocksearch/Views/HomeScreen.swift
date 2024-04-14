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
                //list content
                DateView(currentDate: viewModel.dateViewModel.currentDate)
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
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
