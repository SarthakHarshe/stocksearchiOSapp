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
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    
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
                    .padding()
                    
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
                    .padding()
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Highcharts Section
                        TabView {
                            HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol, chartType: .hourly)
                                .tabItem {
                                    Image(systemName: "chart.xyaxis.line")
                                    Text("Hourly")
                                }
                            
                            HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol, chartType: .historical)
                                .tabItem {
                                    Image(systemName: "clock")
                                    Text("Historical")
                                }
                            
                        }
                        .frame(width: 400, height: 400)
                        
                        
                    }
                    VStack(alignment: .leading) {
                        if let stock = portfolioViewModel.stocks.first(where: { $0.symbol == self.symbol }) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Portfolio")
                                        .font(.headline)
                                    Spacer()
                                }
                            }
                            .padding()
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Shares Owned: \(stock.quantity)")
                                        Text("Avg. Cost / Share: $\(stock.averageCost, specifier: "%.2f")")
                                        Text("Total Cost: $\(stock.totalCost, specifier: "%.2f")")
                                        let change = (stock.currentPrice * Double(stock.quantity)) - stock.totalCost
                                        Text("Change: \(change >= 0 ? "+" : "")\(change, specifier: "%.2f")")
                                            .foregroundColor(change >= 0 ? .green : .red)
                                        Text("Market Value: $\(stock.currentPrice * Double(stock.quantity), specifier: "%.2f")")
                                    }
                                    Spacer()
                                    Button(action: {
                                        // Trade button action
                                    }) {
                                        Text("Trade")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.green)
                                            .cornerRadius(20)
                                    }
                                }
                                .padding()
                                
                            }
                            
                        }
                        else {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text("You have 0 shares of \(symbol).")
                                    Spacer()
                                    Button(action: {
                                        // Trade button action
                                    }) {
                                        Text("Trade")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.green)
                                            .cornerRadius(20)
                                    }
                                }
                                
                            }
                        }
                    }
                    
                    //Stats Section
                    VStack(alignment: .leading) {
                        VStack {
                            HStack {
                                Text("Stats")
                                    .font(.title2)
                                Spacer()
                                
                            }
                        }
                        .padding()
                        
                        VStack(alignment: .leading) {
                            HStack{
                                VStack(alignment: .leading) {
                                    Text("High Price: \(stockInfo.high, specifier: "%.2f")")
                                    Text("Low Price:  \(stockInfo.low, specifier: "%.2f")")
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Open Price: \(stockInfo.open, specifier: "%.2f")")
                                    Text("Prev. Close:  \(stockInfo.previousClose, specifier: "%.2f")")
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    
                    // About Section
                    VStack(alignment: .leading) {
                        VStack {
                            HStack {
                                Text("About")
                                    .font(.title2)
                                Spacer()
                            }
                        }
                        .padding()
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("IPO StartDate:")
                                    Text("Industry:")
                                    Text("Webpage:")
                                    Text("Company Peers:")
                                }
                                
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("\(companyProfile.ipo)")
                                    Text("\(companyProfile.industry)")
                                    Link(companyProfile.webpage, destination: URL(string: companyProfile.webpage)!)
                                        .foregroundColor(.blue)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 7) {
                                            ForEach(stockService.companyPeers.filter { !$0.contains(".") }, id: \.self) { peer in
                                                HStack(spacing: 0) {
                                                    Link(destination: URL(string: "https://www.example.com/\(peer)")!) {
                                                        Text(peer)
                                                            .foregroundColor(.blue)
                                                            .font(.system(size: 14))
                                                    }
                                                    if peer != stockService.companyPeers.filter({ !$0.contains(".") }).last {
                                                        Text(", ")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                            
                        }
                    }
                    .padding()
                    
                    //Insights Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Insights")
                            .font(.title2)
                            .frame(maxWidth: .infinity, alignment: .center)

                        if let sentimentData = stockService.insiderSentiments?.data {
                            HStack {
                                VStack(alignment: .leading, spacing: 20) {
                                    Text(stockService.companyProfile?.name ?? "Company")
                                        .fontWeight(.semibold)
                                        .overlay(VStack{Divider().offset(x: 0, y: 18)})
                                    Text("Total")
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                    Text("Positive")
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                    Text("Negative")
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                }
                                
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("MSPR")
                                        .fontWeight(.semibold)
                                        .overlay(VStack{Divider().offset(x: 0, y: 18)})
                                    Text(formatNumber(sentimentData.totalMSPR))
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                    Text(formatNumber(sentimentData.positiveMSPR))
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                    Text(formatNumber(sentimentData.negativeMSPR))
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Change")
                                        .fontWeight(.semibold)
                                        .overlay(VStack{Divider().offset(x: 0, y: 18)})
                                    Text(formatNumber(sentimentData.totalChange))
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                    Text(formatNumber(sentimentData.positiveChange))
                                        .overlay(VStack{Divider().offset(x: 0, y: 15)})
                                    Text(formatNumber(sentimentData.negativeChange)).overlay(VStack{Divider().offset(x: 0, y: 15)})
                                }
                                
                                Spacer()
                            }
                            
                            
                        } else {
                            Text("No insider sentiment data available.")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()

                    
                    
                    //Insights End here
                    
                    
                    //Recommendation Chart Section
                    VStack() {
                        HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol, chartType: .recommendationTrends)
                            .tabItem {
                                Image(systemName: "chart.xyaxis.line")
                                Text("Hourly")
                            }
                    }
                    .frame(height: 300)
                    .padding()
                    
                    
                    
                    //Recommendation Chart Section ends here
                    
                    //Historical EPS Chart
                        VStack() {
                            HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol, chartType: .historicalEPS)
                                .tabItem {
                                    Image(systemName: "clock")
                                    Text("Historical")
                                }
                        }
                        .padding()
                        .frame(height: 300)
                       
                    //Historical EPS Chart ends here
                    
                    
                    //Latest News Section
                    VStack(alignment: .leading) {
                        Text("Latest News")
                            .font(.title2)
                            .padding(.top)

                        ForEach(Array(stockService.latestNews.enumerated()), id: \.element.id) { (index, article) in
                            NewsView(article: article, isFirstArticle: index == 0)
                                .padding(.vertical)
                        }
                    }
                    .padding(.horizontal)
                    
                    //News section ends here
                    
                    
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
                stockService.fetchCompanyPeers()
                stockService.fetchInsiderSentiments()
                stockService.fetchLatestNews()
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
    
    private func formatNumber(_ number: Double) -> String {
           // Create a formatter that limits to three integer digits
           let formatter = NumberFormatter()
           formatter.maximumIntegerDigits = 3
           formatter.maximumFractionDigits = 2
           formatter.minimumFractionDigits = 2
           formatter.usesGroupingSeparator = false
           
           return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
       }
    
}


// Dummy data for preview
struct StockDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        StockDetailsView(symbol: "AAPL")
    }
}


