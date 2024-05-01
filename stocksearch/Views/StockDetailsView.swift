//
//  StockDetailsView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/17/24.
//

import SwiftUI
import WebKit
import Kingfisher

struct StockDetailsView: View {
    let symbol: String
    @ObservedObject var stockService: StockDetailsModel
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    
    // State for managing sheet presentation
    @State private var showingTradeSheet = false
    @State private var tradeType: TradeType = .buy
    @State private var toastMessage: String?
    @State private var showToast = false
    
    var body: some View {
        ScrollView {
            VStack {
                if stockService.isDataLoaded == false {
                    Spacer()
                    ProgressView("Fetching Data...").padding(.top, 300)
                } else if let stockInfo = stockService.stockInfo, let companyProfile = stockService.companyProfile, stockService.isDataLoaded {
                    stockDetailsContent(stockInfo: stockInfo, companyProfile: companyProfile)
                } else {
                    Text("Failed to load stock details.").padding(.top, 300)
                }
            }
            .padding()
            .navigationBarTitle(stockService.isDataLoaded ? symbol : "", displayMode: .inline)
            .navigationBarItems(trailing: stockService.isDataLoaded ? favoriteButton : nil)
            .onAppear {
                stockService.fetchDataIfNeeded()
            }
            .sheet(isPresented: $showingTradeSheet) {
                TradeSheetView(isPresented: self.$showingTradeSheet, symbol: symbol, tradeType: self.tradeType, stockDetailsModel: stockService)
                    .environmentObject(portfolioViewModel)
            }
        }
        .overlay(
            toastOverlay
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .edgesIgnoringSafeArea(.all),
            alignment: .top
        )
    }
    
    private func stockDetailsContent(stockInfo: StockInfo, companyProfile: CompanyProfile) -> some View {
        VStack(alignment: .leading) {
            companyHeader(companyProfile: companyProfile)
            stockInformation(stockInfo: stockInfo)
            financialChartsSection()
            portfolioSection()
            statsSection(stockInfo: stockInfo)
            aboutSection(companyProfile: companyProfile)
            insightsSection()
            chartSections()
            latestNewsSection()
        }
    }
    
    private func companyHeader(companyProfile: CompanyProfile) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(companyProfile.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let imageUrl = URL(string: companyProfile.logo), !companyProfile.logo.isEmpty {
                    KFImage(imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func stockInformation(stockInfo: StockInfo) -> some View {
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
        .padding(.horizontal)
    }
    
    private func financialChartsSection() -> some View {
        TabView {
            HighchartsView(stockService: stockService, htmlName: "ChartViewa", symbol: symbol, chartType: .hourly)
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
    
    private func portfolioSection() -> some View {
        VStack(alignment: .leading) {
            if let stock = portfolioViewModel.stocks.first(where: { $0.symbol == self.symbol }) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Portfolio")
                            .font(.system(size: 24))
                        Spacer()
                    }
                }
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Shares Owned: \(stock.quantity)").fontWeight(.bold).font(.system(size: 15))
                            Text("Avg. Cost / Share: $\(stock.averageCost, specifier: "%.2f")").fontWeight(.bold).font(.system(size: 15))
                            Text("Total Cost: $\(stock.totalCost, specifier: "%.2f")").fontWeight(.bold).font(.system(size: 15))
                            let change = (stock.currentPrice * Double(stock.quantity)) - stock.totalCost
                            HStack(spacing: 2) {
                                Text("Change:").fontWeight(.bold).font(.system(size: 15))
                                Text("$\(change > 0 ? "+" : "")\(change, specifier: "%.2f")").font(.system(size: 15))
                                    .foregroundColor(change > 0 ? .green : (change < 0 ? .red : .black))
                            }
                            HStack(spacing: 2) {
                                Text("Market Value:").fontWeight(.bold).font(.system(size: 15))
                                Text("$\(stock.currentPrice * Double(stock.quantity), specifier: "%.2f")").font(.system(size: 15))
                                .foregroundColor(change > 0 ? .green : (change < 0 ? .red : .black))                            }
                        }
                        Spacer()
                        Button(action: {
                            self.showingTradeSheet = true
                        }) {
                            Text("Trade")
                                .foregroundColor(.white)
                                .padding()
                                .padding(.horizontal, 35)
                                .background(Color.green)
                                .cornerRadius(30)
                        }
                    }
                    .padding(.horizontal)
                    
                }
                
            }
            else {
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Portfolio")
                                .font(.title2)
                            Spacer()
                        }
                    }
                    .padding()
                    HStack {
                        VStack(alignment: .leading) {
                            Text("You have 0 shares of \(symbol).")
                            Text("Start Trading!")
                        }
                        Spacer()
                        Button(action: {
                            self.showingTradeSheet = true
                        }) {
                            Text("Trade")
                                .foregroundColor(.white)
                                .padding()
                                .padding(.horizontal, 30)
                                .background(Color.green)
                                .cornerRadius(30)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func statsSection(stockInfo: StockInfo) -> some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text("Stats")
                        .font(.system(size: 24))
                    Spacer()
                    
                }
            }
            
            VStack(alignment: .leading) {
                HStack{
                    VStack(alignment: .leading) {
                        Text("High Price: \(stockInfo.high, specifier: "%.2f")").font(.system(size: 15))
                            .padding(.vertical)
                        Text("Low Price:  \(stockInfo.low, specifier: "%.2f")").font(.system(size: 15))
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Open Price: \(stockInfo.open, specifier: "%.2f")").font(.system(size: 15))
                            .padding(.vertical)
                        Text("Prev. Close:  \(stockInfo.previousClose, specifier: "%.2f")").font(.system(size: 15))
                    }
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    private func aboutSection(companyProfile: CompanyProfile) -> some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text("About")
                        .font(.system(size: 24))
                    Spacer()
                    
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    Text("IPO StartDate:").font(.system(size: 15)).fontWeight(.bold)
                    Text("Industry:").font(.system(size: 15)).fontWeight(.bold)
                    Text("Webpage:").font(.system(size: 15)).fontWeight(.bold)
                    Text("Company Peers:").font(.system(size: 15)).fontWeight(.bold)
                }
                
                Spacer(minLength: 50)  // Ensures some spacing even when links are present
                
                VStack(alignment: .leading) {
                    Text("\(companyProfile.ipo)").font(.system(size: 15))
                    Text("\(companyProfile.industry)").font(.system(size: 15))
                    Link(companyProfile.webpage, destination: URL(string: companyProfile.webpage)!).font(.system(size: 15))
                        .foregroundColor(.blue)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(stockService.companyPeers.filter { !$0.contains(".") }, id: \.self) { peer in
                                NavigationLink(destination: StockDetailsView(symbol: peer, stockService: StockDetailsModel(symbol: peer))) {
                                    Text(peer)
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
    }
    
    private func insightsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack {
                HStack {
                    Text("Insights")
                        .font(.system(size: 24))
                    Spacer()
                }
            }
            VStack {
                Text("Insider Sentiments")
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            if let sentimentData = stockService.insiderSentiments?.data {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(stockService.companyProfile?.name ?? "Company")
                            .fontWeight(.bold)
                        Divider().padding(.trailing)
                        Text("Total").fontWeight(.bold)
                        Divider().padding(.trailing)
                        Text("Positive").fontWeight(.bold)
                        Divider().padding(.trailing)
                        Text("Negative").fontWeight(.bold)
                        Divider().padding(.trailing)
                    }
                    
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("MSPR")
                            .fontWeight(.bold)
                        Divider().padding(.trailing)
                        Text(formatNumber(sentimentData.totalMSPR))
                        Divider().padding(.trailing)
                        Text(formatNumber(sentimentData.positiveMSPR))
                        Divider().padding(.trailing)
                        Text(formatNumber(sentimentData.negativeMSPR))
                        Divider().padding(.trailing)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Change")
                            .fontWeight(.bold)
                        Divider()
                        Text(formatNumber(sentimentData.totalChange))
                        Divider()
                        Text(formatNumber(sentimentData.positiveChange))
                        Divider()
                        Text(formatNumber(sentimentData.negativeChange))
                        Divider()
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
    }
    
    private func chartSections() -> some View {
        VStack {
            HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol, chartType: .recommendationTrends)
                .frame(height: 400)
                .padding(.horizontal)
            
            HighchartsView(stockService: stockService, htmlName: "ChartView", symbol: symbol, chartType: .historicalEPS)
                .frame(height: 400)
                .padding(.horizontal)
        }
    }
    
    private func latestNewsSection() -> some View {
        VStack(alignment: .leading) {
            Text("News")
                .font(.title2)
                .padding(.top)
            
            ForEach(Array(stockService.latestNews.enumerated()), id: \.element.id) { (index, article) in
                NewsView(article: article, isFirstArticle: index == 0)
                    .padding(.vertical)
            }
        }
        .padding(.horizontal)
    }
    
    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Image(systemName: stockService.isFavorite ? "plus.circle.fill" : "plus.circle")
                .foregroundColor(.blue)
        }
    }
    
    private func toggleFavorite() {
        if stockService.isFavorite {
            stockService.removeFromFavorites { success, message in
                if success {
                    GlobalToastManager.shared.show(message: message)
                } else {
                    GlobalToastManager.shared.show(message: message)
                }
            }
        } else {
            stockService.addToFavorites { success, message in
                if success {
                    GlobalToastManager.shared.show(message: message)
                } else {
                    GlobalToastManager.shared.show(message: message)
                }
            }
        }
    }
    
    private func handleToast(success: Bool, message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showToast = false
        }
    }
    
    private var toastOverlay: some View {
        Group {
            if showToast {
                VStack {
                    Text(toastMessage ?? "")
                        .padding()
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 100)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showToast)
                }
            }
        }
    }
    
    private func formatNumber(_ number: Double) -> String {
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
        StockDetailsView(symbol: "AAPL", stockService: StockDetailsModel(symbol: "AAPL"))
    }
}



