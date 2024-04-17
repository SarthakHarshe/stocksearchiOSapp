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
        VStack() {
            // Top section for Net Worth and Cash Balance
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.title2)
                    Text("$\(viewModel.netWorth, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cash Balance")
                        .font(.title2)
                    Text("$\(viewModel.cashBalance ?? 0, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            Divider()
            
            // List of Stocks
                ForEach(viewModel.stocks) { stock in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(stock.symbol)
                                .font(.headline)
                            Text("\(stock.quantity) shares")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("$\(stock.currentPrice, specifier: "%.2f")")
                                .font(.subheadline)
                            HStack(spacing: 2) {
                                Image(systemName: stock.changeFromTotalCost >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundColor(stock.changeFromTotalCost >= 0 ? .green : .red)
                                Text("$\(stock.changeFromTotalCost, specifier: "%.2f") (\(stock.changeFromTotalCostPercentage, specifier: "%.2f")%)")
                                    .font(.subheadline)
                                    .foregroundColor(stock.changeFromTotalCost >= 0 ? .green : .red)
                            }
                        }
                    }
                    .background(Color.white)
                }
                .onDelete(perform: viewModel.deleteStock)
                .onMove(perform: viewModel.moveStock)
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
   
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PortfolioViewModel()
        PortfolioView(viewModel: viewModel)
    }
}

