//
//  PortfolioView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import SwiftUI

struct PortfolioView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    
    var body: some View {
        VStack {
            headerView
            Divider()
            stockListView
        }
        .onAppear {
            viewModel.fetchPortfolio()
            viewModel.startUpdatingPrices()
        }
        .onDisappear {
            viewModel.stopUpdatingPrices()
        }
        .onReceive(viewModel.$stocks) { _ in
            viewModel.calculateNetWorth()
        }
    }

    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Worth")
                    .font(.title2)
                Text("$\(viewModel.netWorth, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("Cash Balance")
                    .font(.title2)
                Text("$\(viewModel.cashBalance ?? 0, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }

    private var stockListView: some View {
        ForEach(viewModel.stocks) { stock in
            PortfolioStockRow(stock: stock)
        }
        .onDelete(perform: viewModel.deleteStock)
        .onMove(perform: viewModel.moveStock)
    }
}

// This is the individual stock row view
struct PortfolioStockRow: View {
    var stock: Stock

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.symbol).font(.headline)
                Text("\(stock.quantity) shares").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("$\(stock.marketValue, specifier: "%.2f")").font(.subheadline)
                priceChangeView
            }
        }
        .background(Color.white)  
    }

    private var priceChangeView: some View {
        HStack(spacing: 2) {
            Image(systemName: stock.changeFromTotalCost >= 0 ? "arrow.up.right" : "arrow.down.right")
                .foregroundColor(stock.changeFromTotalCost >= 0 ? .green : .red)
            Text("$\(stock.changeFromTotalCost, specifier: "%.2f") (\(stock.changeFromTotalCostPercentage, specifier: "%.2f")%)")
                .font(.subheadline)
                .foregroundColor(stock.changeFromTotalCost >= 0 ? .green : .red)
        }
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView(viewModel: PortfolioViewModel())
    }
}



