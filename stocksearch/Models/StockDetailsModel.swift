//
//  StockDetailsModel.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/17/24.
//

import Foundation
import Alamofire
import Combine
import SwiftUI

struct StockInfo: Decodable {
    let currentPrice: Double
    let change: Double
    let changePercentage: Double
    let name: String?
    let high: Double
    let open: Double
    let low: Double
    let previousClose: Double
    
    enum CodingKeys: String, CodingKey {
            case currentPrice = "c"
            case change = "d"
            case changePercentage = "dp"
            case name
            case high = "h"
            case low = "l"
            case open = "o"
            case previousClose = "pc"
        }
}

struct CompanyProfile: Decodable {
    let name: String
    let exchange: String
    let logo: String
    let ipo: String
    let industry: String
    let webpage: String

    
    enum CodingKeys: String, CodingKey {
            case name
            case exchange
            case logo
            case ipo
            case industry = "finnhubIndustry"
            case webpage = "weburl"
            
        }
}

struct WatchlistStock: Decodable {
    let symbol: String
    let name: String
    let exchange: String
    let logo: String
    let currentPrice: Double
    let change: Double
    let changePercentage: Double
}

struct WatchlistParameters: Encodable {
    let symbol: String
    let name: String
    let exchange: String
    let logo: String
    let currentPrice: Double
    let change: Double
    let changePercentage: Double
    let timestamp: Int64
    
    enum CodingKeys: String, CodingKey {
            case symbol
            case name
            case exchange
            case logo
            case currentPrice
            case change
            case changePercentage
            case timestamp
        }
}

struct InsiderSentiment: Decodable {
    let data: [SentimentData]
    let symbol: String

    struct SentimentData: Decodable {
        let symbol: String
        let year: Int
        let month: Int
        let change: Double
        let mspr: Double
    }
}

struct RecommendationTrend: Decodable {
    let period: String
    let buy: Int
    let hold: Int
    let sell: Int
    let strongBuy: Int
    let strongSell: Int
}

struct HistoricalEPS: Decodable {
    let actual: Double
    let estimate: Double
    let period: String
    let surprise: Double
}

struct NewsArticle: Identifiable, Decodable {
    let id: Int
    let category: String
    let datetime: Int64
    let headline: String
    let image: String
    let related: String
    let source: String
    let summary: String
    let url: String
}


extension Array where Element == InsiderSentiment.SentimentData {
    var totalMSPR: Double { reduce(0) { $0 + $1.mspr } }
    var totalChange: Double { reduce(0) { $0 + $1.change } }
    var positiveMSPR: Double { filter { $0.mspr > 0 }.reduce(0) { $0 + $1.mspr } }
    var negativeMSPR: Double { filter { $0.mspr < 0 }.reduce(0) { $0 + $1.mspr } }
    var positiveChange: Double { filter { $0.change > 0 }.reduce(0) { $0 + $1.change } }
    var negativeChange: Double { filter { $0.change < 0 }.reduce(0) { $0 + $1.change } }
}




class StockDetailsModel: ObservableObject {
    @Published var stockInfo: StockInfo?
    @Published var companyProfile: CompanyProfile?
    @Published var isLoading = true
    @Published var isFavorite = false
    private var symbol: String
    @Published var companyPeers: [String] = []
    @Published var insiderSentiments: InsiderSentiment?
    @Published var latestNews: [NewsArticle] = []
    @Published var hourlyChartData: [ChartData] = []  
    @Published var historicalChartData: [HistoricalChartData] = []
    @Published var recommendationTrends: [RecommendationTrend] = []
    @Published var historicalEPS: [HistoricalEPS] = []
//    @Published var isChartReady = false



    
    
    private let quoteURL = "http://localhost:3000/stock_quote"
    private let profileURL = "http://localhost:3000/company_profile"
    private let watchlistURL = "http://localhost:3000/watchlist"
    
    
    init(symbol: String) {
            self.symbol = symbol
            checkIfFavorite()
            fetchAllData() {
                    print("Initial data fetching is complete.")
                }
        }
    
    func fetchAllData(completion: @escaping () -> Void) {
           isLoading = true
           let group = DispatchGroup()

           group.enter()
           fetchStockDetails {
               group.leave()
           }

           group.enter()
           fetchCompanyPeers {
               group.leave()
           }

           group.enter()
           fetchInsiderSentiments {
               group.leave()
           }

           group.enter()
           fetchLatestNews {
               group.leave()
           }

        group.enter()
            fetchHourlyChartData(symbol: symbol) { result in
                switch result {
                case .success(let chartData):
                    DispatchQueue.main.async {
                        self.hourlyChartData = chartData
                    }
                case .failure(let error):
                    print("Failed to fetch hourly chart data: \(error)")
                }
                group.leave()
            }

        // Fetch historical chart data
          group.enter()
          fetchHistoricalChartData(symbol: symbol) { result in
              switch result {
              case .success(let chartData):
                  DispatchQueue.main.async {
                      self.historicalChartData = chartData
                      print("THIS IS THE DATA INSIDE THE FETCHALLFUNCTION", self.historicalChartData)
                  }
              case .failure(let error):
                  print("Failed to fetch historical chart data: \(error)")
              }
              group.leave()
          }
        
        // Fetch recommendation trends
            group.enter()
            fetchRecommendationTrends(symbol: symbol) { result in
                switch result {
                case .success(let trends):
                    DispatchQueue.main.async {
                        self.recommendationTrends = trends
                    }
                case .failure(let error):
                    print("Failed to fetch recommendation trends: \(error)")
                }
                group.leave()
            }
        
        // Fetch historical EPS
           group.enter()
           fetchHistoricalEPS(symbol: symbol) { result in
               switch result {
               case .success(let epsData):
                   DispatchQueue.main.async {
                       self.historicalEPS = epsData
                   }
               case .failure(let error):
                   print("Failed to fetch historical EPS: \(error)")
               }
               group.leave()
           }

           group.notify(queue: .main) {
               self.isLoading = false
//               self.isChartReady = true
               completion()
           }
       }
    
    
    func addToFavorites(completion: @escaping (Bool, String) -> Void) {
        guard let stock = stockInfo, let profile = companyProfile else {
            completion(false, "Incomplete data for adding to favorites.")
            return
        }

        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let params = WatchlistParameters(
            symbol: symbol,
            name: profile.name,
            exchange: profile.exchange,
            logo: profile.logo,
            currentPrice: stock.currentPrice,
            change: stock.change,
            changePercentage: stock.changePercentage,
            timestamp: currentTime
        )

        AF.request("\(watchlistURL)", method: .post, parameters: params, encoder: JSONParameterEncoder.default).response { response in
            if response.error == nil {
                self.isFavorite = true
                completion(true, "Added to favorites successfully")
            } else {
                completion(false, "Failed to add to favorites")
            }
        }
    }


    func removeFromFavorites(completion: @escaping (Bool, String) -> Void) {
        AF.request("\(watchlistURL)/\(symbol)", method: .delete).response { response in
            if response.error == nil {
                self.isFavorite = false
                completion(true, "Removed from favorites successfully")
            } else {
                completion(false, "Failed to remove from favorites")
            }
        }
    }

    
    func checkIfFavorite() {
        AF.request(watchlistURL).responseDecodable(of: [WatchlistStock].self) { response in
            DispatchQueue.main.async {
                switch response.result {
                case .success(let favorites):
                    self.isFavorite = favorites.contains { $0.symbol == self.symbol }
                case .failure(let error):
                    print("Failed to fetch favorites: \(error.localizedDescription)")
                }
            }
        }
    }


    
    func fetchStockDetails(completion: @escaping () -> Void) {
            isLoading = true
            let group = DispatchGroup()
            
            group.enter()
                AF.request("\(quoteURL)?symbol=\(symbol)").responseDecodable(of: StockInfo.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let stockInfo):
                        self.stockInfo = stockInfo
                    case .failure(let error):
                        print("Stock quote fetching error: \(error)")
                    }
                    group.leave()
                }
                    completion()
            }
            
            group.enter()
                AF.request("\(profileURL)?symbol=\(symbol)").responseDecodable(of: CompanyProfile.self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let profile):
                        self.companyProfile = profile
                    case .failure(let error):
                        print("Company profile fetching error: \(error)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.isLoading = false
                self.checkIfFavorite()
            }
        }
    
    func fetchHourlyChartData(symbol: String, completion: @escaping (Result<[ChartData], Error>) -> Void) {
        let urlString = "http://localhost:3000/hourly_charts_data?symbol=\(symbol)"
        AF.request(urlString).responseDecodable(of: HourlyChartDataResponse.self) { response in
            switch response.result {
            case .success(let dataResponse):
                let chartData = dataResponse.results.map { ChartData(t: $0.t, c: $0.c) }
                completion(.success(chartData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchHistoricalChartData(symbol: String, completion: @escaping (Result<[HistoricalChartData], Error>) -> Void) {
        let urlString = "http://localhost:3000/charts_data?symbol=\(symbol)"
        AF.request(urlString).responseDecodable(of: HistoricalChartDataResponse.self) { response in
            switch response.result {
            case .success(let dataResponse):
                completion(.success(dataResponse.results.map { HistoricalChartData(x: $0.t, open: $0.o, high: $0.h, low: $0.l, close: $0.c, volume: $0.v) }))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchCompanyPeers(completion: @escaping () -> Void) {
            let peersURL = "http://localhost:3000/company_peers?symbol=\(symbol)"
            AF.request(peersURL).responseDecodable(of: [String].self) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let peers):
                        self.companyPeers = peers
                    case .failure(let error):
                        print("Error fetching company peers: \(error)")
                    }
                }
            }
            completion()
        }
    
    func fetchInsiderSentiments(completion: @escaping () -> Void) {
        let sentimentURL = "http://localhost:3000/insider_sentiment?symbol=\(symbol)"
        AF.request(sentimentURL).responseDecodable(of: InsiderSentiment.self) { response in
            DispatchQueue.main.async {
                switch response.result {
                case .success(let sentiments):
                    self.insiderSentiments = sentiments
                case .failure(let error):
                    print("Error fetching insider sentiments: \(error)")
                }
            }
        }
        completion()
    }
    
    func fetchRecommendationTrends(symbol: String, completion: @escaping (Result<[RecommendationTrend], Error>) -> Void) {
        AF.request("http://localhost:3000/recommendation_trends?symbol=\(symbol)").responseDecodable(of: [RecommendationTrend].self) { response in
            switch response.result {
            case .success(let trends):
                completion(.success(trends))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchHistoricalEPS(symbol: String, completion: @escaping (Result<[HistoricalEPS], Error>) -> Void) {
        AF.request("http://localhost:3000/company_earnings?symbol=\(symbol)").responseDecodable(of: [HistoricalEPS].self) { response in
            switch response.result {
            case .success(let earnings):
                completion(.success(earnings))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchLatestNews(completion: @escaping () -> Void) {
        let newsURL = "http://localhost:3000/latest_news?symbol=\(symbol)"
        AF.request(newsURL).responseDecodable(of: [NewsArticle].self) { response in
            DispatchQueue.main.async {
                switch response.result {
                case .success(let articles):
                    // Filter out articles without images and limit the results to 20
                    let filteredArticles = articles.filter { !$0.image.isEmpty }.prefix(20)
                    self.latestNews = Array(filteredArticles)
                case .failure(let error):
                    print("Error fetching latest news: \(error)")
                }
            }
        }
        completion()
    }


    
    
    

    struct ChartData {
        let t: Int
        let c: Double
    }
    
    struct HourlyChartDataResponse: Decodable {
        let results: [HourlyChartResult]
    }

    struct HourlyChartResult: Decodable {
        let v: Int
        let vw: Double
        let o: Double
        let c: Double
        let h: Double
        let l: Double
        let t: Int
        let n: Int
    }
    
    //SMA Chart Data Structures
    struct HistoricalChartData {
        let x: Int
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let volume: Int
    }

    struct HistoricalChartDataResponse: Decodable {
        let results: [HistoricalChartResult]
    }

    struct HistoricalChartResult: Decodable {
        let t: Int        // Timestamp
        let o: Double     // Open price
        let h: Double     // High price
        let l: Double     // Low price
        let c: Double     // Close price
        let v: Int        // Volume
    }


}


