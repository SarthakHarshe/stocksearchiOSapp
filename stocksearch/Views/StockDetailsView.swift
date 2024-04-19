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
                        
                        // Highcharts Section
                        TabView {
                            HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol)
                                .tabItem {
                                    Image(systemName: "chart.xyaxis.line")
                                    Text("Hourly")
                                }
                            
                            HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol)
                                .tabItem {
                                    Image(systemName: "clock")
                                    Text("Historical")
                                }
                        }
                        .frame(height: 300)
                        
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
                Image(systemName: stockService.isFavorite ? "plus.circle.fill" : "plus.circle")
                    .foregroundColor(.black)
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


