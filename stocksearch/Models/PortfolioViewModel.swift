//
//  PortfolioViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import Foundation
import Alamofire

class PortfolioViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var cashBalance: Double?  // Now optional to reflect uninitialized state
    @Published var netWorth: Double = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // URLs for the backend endpoints
    private let portfolioURL = "http://localhost:3000/portfolio"
    private let quoteURL = "http://localhost:3000/stock_quote"
    private let userDataURL = "http://localhost:3000/userdata"

    // Initialize to fetch data
    init() {
        fetchUserData()
        fetchPortfolio()
    }

    // Fetch user data to get the wallet balance
    func fetchUserData() {
        AF.request(userDataURL, method: .get)
            .validate()
            .responseDecodable(of: UserData.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let userData):
                        self.cashBalance = userData.walletBalance
                        self.calculateNetWorth()
                    case .failure(let error):
                        self.errorMessage = "Failed to load user data: \(error.localizedDescription)"
                    }
                }
            }
    }

    // Fetch the portfolio data
    func fetchPortfolio() {
        isLoading = true
        AF.request(portfolioURL, method: .get)
            .validate()
            .responseDecodable(of: [Stock].self) { response in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch response.result {
                    case .success(let stocks):
                        debugPrint([Stock].self)
                        self.stocks = stocks
                        debugPrint(stocks)
                        self.updateStockPrices()
                    case .failure(let error):
                        self.errorMessage = "Failed to load portfolio: \(error.localizedDescription)"
                    }
                }
            }
    }

    // Update stock prices using the stock_quote endpoint
    func updateStockPrices() {
        for stock in stocks {
            fetchLatestPrice(for: stock)
        }
    }

    // Fetch the latest price for a given stock
    func fetchLatestPrice(for stock: Stock) {
        AF.request("\(quoteURL)?symbol=\(stock.symbol)", method: .get)
            .validate()
            .responseDecodable(of: StockQuote.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let quote):
                        stock.currentPrice = quote.currentPrice
                        self.calculateNetWorth()
                    case .failure(let error):
                        print("Error fetching price for \(stock.symbol): \(error)")
                    }
                }
            }
    }

    // Calculate the net worth as the sum of the market values of all stocks plus the cash balance
    func calculateNetWorth() {
        if let cash = cashBalance {
            netWorth = stocks.reduce(cash) { (result, stock) -> Double in
                result + stock.marketValue
            }
        }
    }
}

// Data structures for decoding JSON from the backend
struct StockQuote: Codable {
    var currentPrice: Double
    enum CodingKeys: String, CodingKey {
        case currentPrice = "c"  // Key in JSON that holds the current price
    }
}

