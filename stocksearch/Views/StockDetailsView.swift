//
//  StockDetailsView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/17/24.
//

import SwiftUI
import WebKit

struct StockDetailsView: View {
    let symbol: String
    @StateObject private var stockService: StockDetailsModel
    
    init(symbol: String) {
           self.symbol = symbol
           _stockService = StateObject(wrappedValue: StockDetailsModel(symbol: symbol))
       }
    
    var body: some View {
        ScrollView {
            VStack {
                if stockService.isLoading {
                    ProgressView("Loading...")
                } else if let stockInfo = stockService.stockInfo, let companyProfile = stockService.companyProfile {
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(companyProfile.name)
                            .font(.subheadline)
                        .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("$\(stockInfo.currentPrice, specifier: "%.2f")")
                            .font(.largeTitle)
                        
                        Image(systemName: stockInfo.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(stockInfo.change >= 0 ? .green : .red)
                        
                        Text("\(stockInfo.change >= 0 ? "+" : "")\(stockInfo.change, specifier: "%.2f")")
                            .foregroundColor(stockInfo.change >= 0 ? .green : .red)
                        
                        Text("(\(stockInfo.changePercentage, specifier: "%.2f")%)")
                            .foregroundColor(stockInfo.change >= 0 ? .green : .red)
                        
                        Spacer()
                    }
                    .padding(.top)
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Placeholder for charts
                        Text("Charts ka space imagination ke liye")
                            .padding()
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        // Add your tab view with charts here
                    }
                }
                else {
                    Text("Failed to load stock details.")
                }
            }
            .padding()
            .navigationTitle(symbol)
            .navigationBarItems(trailing: favoriteButton)
            .onAppear {
                stockService.fetchStockDetails(symbol: symbol)
            }
        }
    }
    
    private var favoriteButton: some View {
            Button(action: toggleFavorite) {
                Image(systemName: stockService.isFavorite ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
        }
    
    private func toggleFavorite() {
           if stockService.isFavorite {
               stockService.removeFromFavorites()
           } else {
               stockService.addToFavorites()
           }
       }
    
}


// Dummy data for preview
struct StockDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        StockDetailsView(symbol: "AAPL")
    }
}


