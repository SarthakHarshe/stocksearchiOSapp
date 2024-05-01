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
            headerView
            Divider()
            favoritesListView
        }
        .onAppear {
            viewModel.fetchFavorites()
//            viewModel.startUpdatingFavorites()
        }
        .onDisappear {
//            viewModel.stopUpdatingFavorites()
        }
    }

    private var headerView: some View {
        HStack {
            Text("Favorites").font(.title2).fontWeight(.semibold)
        }
    }

    private var favoritesListView: some View {
        ForEach(viewModel.favorites) { favorite in
            FavoriteStockRow(favorite: favorite)
        }
//        .onDelete { offsets in
//                    viewModel.deleteFavorite(at: offsets) { success, message in
//                        GlobalToastManager.shared.show(message: message)
//                    }
//                }
        .onMove(perform: viewModel.moveFavorite)
    }
}

// Inner view for displaying a single favorite stock
struct FavoriteStockRow: View {
    var favorite: FavoriteStock  // Single favorite stock object

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(favorite.symbol).font(.headline)
                Text(favorite.name).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("$\(favorite.currentPrice, specifier: "%.2f")").font(.headline)
                priceChangeView
            }
        }
        .background(Color.white) 
    }

    private var priceChangeView: some View {
        HStack(spacing: 2) {
            if favorite.change == 0 {
                Image(systemName: "minus")
                    .foregroundColor(.gray)
                Text("$\(favorite.change, specifier: "%.2f") (\(favorite.changePercentage, specifier: "%.2f")%)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: favorite.change > 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(favorite.change > 0 ? .green : .red)
                Text("$\(favorite.change, specifier: "%.2f") (\(favorite.changePercentage, specifier: "%.2f")%)")
                    .font(.subheadline)
                    .foregroundColor(favorite.change > 0 ? .green : .red)
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(viewModel: FavoritesViewModel())
    }
}

