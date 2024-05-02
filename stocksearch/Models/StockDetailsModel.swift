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
        let change: Int
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
    var totalChange: Int { reduce(0) { $0 + $1.change } }
    var positiveMSPR: Double { filter { $0.mspr > 0 }.reduce(0) { $0 + $1.mspr } }
    var negativeMSPR: Double { filter { $0.mspr < 0 }.reduce(0) { $0 + $1.mspr } }
    var positiveChange: Int { filter { $0.change > 0 }.reduce(0) { $0 + $1.change } }
    var negativeChange: Int { filter { $0.change < 0 }.reduce(0) { $0 + $1.change } }
}




class StockDetailsModel: ObservableObject {
    @Published var stockInfo: StockInfo?
    @Published var companyProfile: CompanyProfile?
    @Published var isFavorite = false
    private var symbol: String
    @Published var companyPeers: [String] = []
    @Published var insiderSentiments: InsiderSentiment?
    @Published var latestNews: [NewsArticle] = []
    @Published var hourlyChartData: [ChartData] = []  
    @Published var historicalChartData: [HistoricalChartData] = []
    @Published var recommendationTrends: [RecommendationTrend] = []
    @Published var historicalEPS: [HistoricalEPS] = []
    @Published var isDataLoaded = false


    
    private let quoteURL = "https://assignment3-419001.wl.r.appspot.com/stock_quote"
    private let profileURL = "https://assignment3-419001.wl.r.appspot.com/company_profile"
    private let watchlistURL = "https://assignment3-419001.wl.r.appspot.com/watchlist"
    
    
    init(symbol: String, loadImmediately: Bool = false) {
        self.symbol = symbol
        print("SYMBOL FOR FETCHING: \(symbol)")
        checkIfFavorite()
    }
    
    // Method to initiate fetching
        func loadData(completion: @escaping () -> Void) {
            if !isDataLoaded {
                fetchAllData {
                    print("Data loaded for \(self.symbol)")
                    self.isDataLoaded = true
                    completion()
                }
            }
        }

    
    func fetchAllData(completion: @escaping () -> Void) {
        print("SYMBOL FOR FETCHING INSIDE fetchallDATA: \(symbol)")
           let group = DispatchGroup()

           group.enter()
           fetchStockDetails {
               print("Stock details fetched.")
               group.leave()
           }
        
        // Fetch Company Profile
                group.enter()
                fetchCompanyProfile {
                    print("Company profile fetched.")
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
               print("All fetch operations completed inside the fetchalldata function")
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


    
    private func fetchStockDetails(completion: @escaping () -> Void) {
            AF.request("https://assignment3-419001.wl.r.appspot.com/stock_quote?symbol=\(symbol)", method: .get).validate().responseDecodable(of: StockInfo.self) { response in
                switch response.result {
                case .success(let stockInfo):
                    DispatchQueue.main.async {
                        self.stockInfo = stockInfo
                        completion()
                    }
                case .failure(let error):
                    print("Error fetching stock details: \(error.localizedDescription)")
                    completion()
                }
            }
        }
    
    private func fetchCompanyProfile(completion: @escaping () -> Void) {
            AF.request("https://assignment3-419001.wl.r.appspot.com/company_profile?symbol=\(symbol)", method: .get).validate().responseDecodable(of: CompanyProfile.self) { response in
                switch response.result {
                case .success(let profile):
                    DispatchQueue.main.async {
                        self.companyProfile = profile
                        completion()
                    }
                case .failure(let error):
                    print("Error fetching company profile: \(error.localizedDescription)")
                    completion()
                }
            }
        }
    
    func fetchHourlyChartData(symbol: String, completion: @escaping (Result<[ChartData], Error>) -> Void) {
        let urlString = "https://assignment3-419001.wl.r.appspot.com/hourly_charts_data?symbol=\(symbol)"
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
        let urlString = "https://assignment3-419001.wl.r.appspot.com/charts_data?symbol=\(symbol)"
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
            let peersURL = "https://assignment3-419001.wl.r.appspot.com/company_peers?symbol=\(symbol)"
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
        let sentimentURL = "https://assignment3-419001.wl.r.appspot.com/insider_sentiment?symbol=\(symbol)"
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
        AF.request("https://assignment3-419001.wl.r.appspot.com/recommendation_trends?symbol=\(symbol)").responseDecodable(of: [RecommendationTrend].self) { response in
            switch response.result {
            case .success(let trends):
                completion(.success(trends))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchHistoricalEPS(symbol: String, completion: @escaping (Result<[HistoricalEPS], Error>) -> Void) {
        AF.request("https://assignment3-419001.wl.r.appspot.com/company_earnings?symbol=\(symbol)").responseDecodable(of: [HistoricalEPS].self) { response in
            switch response.result {
            case .success(let earnings):
                completion(.success(earnings))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchLatestNews(completion: @escaping () -> Void) {
        let newsURL = "https://assignment3-419001.wl.r.appspot.com/latest_news?symbol=\(symbol)"
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
        let t: Int
        let o: Double     
        let h: Double
        let l: Double
        let c: Double
        let v: Int
    }


}


