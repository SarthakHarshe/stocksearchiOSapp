//
//  FavoritesView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/14/24.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: FavoritesViewModel

    var body: some View {
        VStack {
                List(viewModel.favorites) { stock in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(stock.symbol)
                                .font(.headline)
                            Text(stock.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("$\(stock.currentPrice, specifier: "%.2f")")
                                .font(.subheadline)
                            HStack(spacing: 2) {
                                Image(systemName: (stock.priceChange ?? 0) >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundColor((stock.priceChange ?? 0) >= 0 ? .green : .red)
                                Text("\((stock.priceChange ?? 0), specifier: "%.2f") (\((stock.priceChangePercentage ?? 0), specifier: "%.2f")%)")
                                    .font(.subheadline)
                                    .foregroundColor((stock.priceChange ?? 0) >= 0 ? .green : .red)
                            }
                        }
                    }
                }
            

            if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                        }
        }
        .onAppear {
            viewModel.fetchFavorites()
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FavoritesViewModel()
        FavoritesView(viewModel: viewModel)
    }
}

