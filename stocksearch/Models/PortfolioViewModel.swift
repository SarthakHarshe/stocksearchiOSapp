//
//  PortfolioViewModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/13/24.
//

import Foundation
import Alamofire
import Combine

class PortfolioViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var cashBalance: Double?
    @Published var netWorth: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    var timer: AnyCancellable?
    @Published var isDataLoadedforportfolio = false

    
    

    // URLs for the backend endpoints
    private let portfolioURL = "http://localhost:3000/portfolio"
    private let quoteURL = "http://localhost:3000/stock_quote"
    private let userDataURL = "http://localhost:3000/userdata"

    // Initialize to fetch data
    init() {
        fetchUserData()
        fetchPortfolio()
        self.isDataLoadedforportfolio = false
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
                    switch response.result {
                    case .success(let stocks):
                        self.stocks = stocks
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
                        self.isDataLoadedforportfolio = true
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
    
    func startUpdatingPrices() {
        // Start a timer that triggers every 15 seconds
        timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.updateStockPrices()
                self?.calculateNetWorth()
                // Optionally update other values like Net Worth if they depend on other data
            }
    }
    
    // Call this function to stop the timer if needed
        func stopUpdatingPrices() {
            timer?.cancel()
        }
    
    func updateData() {
            fetchUserData()
            fetchPortfolio()
        }
    
    func buyStock(symbol: String, quantity: Int, price: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let buyURL = "http://localhost:3000/portfolio/buy"
        let request = BuyStockRequest(symbol: symbol, quantity: quantity, price: price)

        AF.request(buyURL, method: .post, parameters: request, encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: BuySellResponse.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(_):
                        completion(.success("Bought \(quantity) shares of \(symbol)."))
                        self.updateData()
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
    }
    
    func sellStock(symbol: String, quantity: Int, price: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let sellURL = "http://localhost:3000/portfolio/sell"
        let request = SellStockRequest(symbol: symbol, quantity: quantity, price: price)

        AF.request(sellURL, method: .post, parameters: request, encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: BuySellResponse.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(_):
                        completion(.success("Sold \(quantity) shares of \(symbol)."))
                        self.updateData()
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
    }

    
    func updateWalletBalance(newBalance: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let updateWalletURL = "http://localhost:3000/userdata/update-wallet"
        let request = UpdateWalletRequest(newBalance: newBalance)

        AF.request(updateWalletURL, method: .post, parameters: request, encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: WalletUpdateResponse.self) { response in
                switch response.result {
                case .success(let walletResponse):
                    self.cashBalance = newBalance
                    completion(.success(walletResponse.message))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func deleteStock(at offsets: IndexSet) {
        offsets.forEach { index in
            let stock = stocks[index]
            AF.request("http://localhost:3000/portfolio/\(stock.symbol)", method: .delete)
                .validate()
                .response { response in
                    DispatchQueue.main.async {
                        if response.error == nil {
                            self.stocks.remove(at: index)
                            self.calculateNetWorth()
                        } else {
                            // Handle the error properly later
                        }
                    }
                }
        }
    }
    
    func moveStock(from source: IndexSet, to destination: Int) {
        stocks.move(fromOffsets: source, toOffset: destination)
    }


}

// Data structures for decoding JSON from the backend
struct StockQuote: Codable {
    var currentPrice: Double
    enum CodingKeys: String, CodingKey {
        case currentPrice = "c"  // Key in JSON that holds the current price
    }
}

struct BuySellResponse: Codable {
    let message: String
    let walletBalance: Double?
}

struct WalletUpdateResponse: Codable {
    let message: String
}

struct BuyStockRequest: Encodable {
    let symbol: String
    let quantity: Int
    let price: Double
}

struct SellStockRequest: Encodable {
    let symbol: String
    let quantity: Int
    let price: Double
}

struct UpdateWalletRequest: Encodable {
    let newBalance: Double
}

