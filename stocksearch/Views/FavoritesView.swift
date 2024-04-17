//
//  FavoritesView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/16/24.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: FavoritesViewModel

    var body: some View {
        VStack {
                ForEach(viewModel.favorites) { stock in
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
                                Image(systemName: stock.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundColor(stock.change >= 0 ? .green : .red)
                                Text("$\(stock.change, specifier: "%.2f") (\(stock.changePercentage, specifier: "%.2f")%)")
                                    .font(.subheadline)
                                    .foregroundColor(stock.change >= 0 ? .green : .red)
                            }
                        }
                    }
                    .background(Color.white)
                }
                .onDelete(perform: viewModel.deleteFavorite)
                .onMove(perform: viewModel.moveFavorite)
        }
        .onAppear {
            viewModel.fetchFavorites()
            viewModel.startUpdatingFavorites()
        }
        .onDisappear {
                    viewModel.stopUpdatingFavorites()
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(viewModel: FavoritesViewModel())
    }
}
