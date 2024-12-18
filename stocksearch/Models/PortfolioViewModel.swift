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

    
    


    private let portfolioURL = "https://assignment3-419001.wl.r.appspot.com/portfolio"
    private let quoteURL = "https://assignmenst3-419001.wl.r.appspot.com/stock_quote"
    private let userDataURL = "https://assignment3-419001.wl.r.appspot.com/userdata"

    init() {
        fetchUserData()
        fetchPortfolio()
        self.isDataLoadedforportfolio = false
    }


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
                        self.isDataLoadedforportfolio = true
                    case .failure(let error):
                        self.errorMessage = "Failed to load portfolio: \(error.localizedDescription)"
                    }
                }
            }
    }

   
    func updateStockPrices() {
        for stock in stocks {
            fetchLatestPrice(for: stock)
        }
    }


    func fetchLatestPrice(for stock: Stock) {
        AF.request("https://assignment3-419001.wl.r.appspot.com/stock_quote?symbol=\(stock.symbol)", method: .get)
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
                
            }
    }
    
   
        func stopUpdatingPrices() {
            timer?.cancel()
        }
    
    func updateData() {
            fetchUserData()
            fetchPortfolio()
        }
    
    func buyStock(symbol: String, quantity: Int, price: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let buyURL = "https://assignment3-419001.wl.r.appspot.com/portfolio/buy"
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
        let sellURL = "https://assignment3-419001.wl.r.appspot.com/portfolio/sell"
        let request = SellStockRequest(symbol: symbol, quantity: quantity, price: price)
        print("Sending request to sell stock: \(request)")

        AF.request(sellURL, method: .post, parameters: request, encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: BuySellResponse.self) { response in
                print("Response from selling stock: \(response)")
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(_):
                        completion(.success("Sold \(quantity) shares of \(symbol)."))
                        self.updateData()
                    case .failure(let error):
                        print("Error selling stock: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
    }

    
    func updateWalletBalance(newBalance: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let updateWalletURL = "https://assignment3-419001.wl.r.appspot.com/userdata/update-wallet"
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
            AF.request("https://assignment3-419001.wl.r.appspot.com/portfolio/\(stock.symbol)", method: .delete)
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


struct StockQuote: Codable {
    var currentPrice: Double
    enum CodingKeys: String, CodingKey {
        case currentPrice = "c" 
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

