//
//  HighchartsView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/18/24.
//

import SwiftUI
import WebKit

enum ChartType {
    case hourly
    case historical
    case recommendationTrends
    case historicalEPS
}

struct HighchartsView: UIViewRepresentable {
    var stockService: StockDetailsModel 
    let htmlName: String
    let symbol: String
    let chartType: ChartType
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let contentPreferences = WKWebpagePreferences()
        contentPreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = contentPreferences
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()

        
        configuration.userContentController.add(context.coordinator, name: "logHandler")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    
    
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let filePath = Bundle.main.path(forResource: "ChartView", ofType: "html") else { return }
        let fileUrl = URL(fileURLWithPath: filePath)
        let request = URLRequest(url: fileUrl)
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: HighchartsView
        
        init(_ parent: HighchartsView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            switch parent.chartType {
                case .hourly:
                    parent.injectJavaScript(webView)
                case .historical:
                    parent.injectSMAChartData(webView)
                case .recommendationTrends:
                    parent.injectRecommendationTrends(webView)
                case .historicalEPS:
                    parent.injectHistoricalEPS(webView)
                }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "logHandler" {
                print("JS log: \(message.body)")
            }
        }
    }
    
    private func injectJavaScript(_ webView: WKWebView){
        stockService.fetchHourlyChartData(symbol: symbol) { result in
            switch result {
            case .success(let chartData):
                let seriesData = chartData.map { "Date.UTC(\(convertToUTCDate(milliseconds: $0.x)), \($0.y))" }
                let jsSeriesData = "[\(seriesData.joined(separator: ", "))]" // Correctly join array elements

                let jsChartOptions = """
                    {
                        chart: {
                            backgroundColor: 'rgba(0, 0, 0, 0.05)',
                            type: 'line',
                            style: {
                                fontFamily: 'Arial',
                            },
                            height: '100%'
                        },
                        title: {
                            text: 'Hourly Price Variation',
                            style: {
                                color: 'black',
                                fontSize: '16px',
                            },
                        },
                        xAxis: {
                            type: 'datetime',
                            dateTimeLabelFormats: {
                                hour: '%H:%M',
                            },
                            labels: {
                              format: '{value:%H:%M}',
                            },
                             tickInterval: 10800 * 1000,
                        },
                        yAxis: {
                            title: {
                                text: '',
                            },
                            opposite: true,
                        },
                        series: [{
                            name: 'Price',
                            data: \(jsSeriesData),
                            type: 'line',
                            color: 'red',
                            marker: {
                                enabled: false,
                            },
                        }],
                        credits: {
                            enabled: true,
                            href: 'http://www.highcharts.com',
                            text: 'highcharts.com',
                        },
                        tooltip: {
                            shared: true,
                            xDateFormat: '%H:%M',
                        },
                        plotOptions: {
                            series: {
                                marker: {
                                    enabled: true,
                                    radius: 3,
                                },
                            },
                        },
                    }
                    """
                let jsCode = "updateHourlyChart(\(jsChartOptions))"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    webView.evaluateJavaScript(jsCode) { (result, error) in
                        if let error = error {
                            print("JavaScript execution error: \(error.localizedDescription)")
                        } else if let result = result {
                            print("JavaScript execution result: \(result)")
                        }
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    // Function for the sma chart
    private func injectSMAChartData(_ webView: WKWebView) {
        stockService.fetchHistoricalChartData(symbol: symbol) { result in
            switch result {
            case .success(let HistoricalChartData):
                let ohlcData = HistoricalChartData.map { "[\($0.x), \($0.open), \($0.high), \($0.low), \($0.close)]" }.joined(separator: ", ")
                let volumeData = HistoricalChartData.map { "[\($0.x), \($0.volume)]" }.joined(separator: ", ")

                let jsChartData = """
                {
                    rangeSelector: {
                                selected: 2
                    },
                    title: {
                        text: '\(self.symbol) Historical Stock Price'
                    },
                    subtitle: {
                        text: 'With SMA and Volume by Price technical indicators'
                    },
                    yAxis: [{
                               startOnTick: false,
                               endOnTick: false,
                               labels: {
                                   align: 'right',
                                   x: -3
                               },
                               title: {
                                   text: 'OHLC'
                               },
                               height: '60%',
                               lineWidth: 2,
                               resize: {
                                   enabled: true
                               }
                           }, {
                               labels: {
                                   align: 'right',
                                   x: -3
                               },
                               title: {
                                   text: 'Volume'
                               },
                               top: '65%',
                               height: '35%',
                               offset: 0,
                               lineWidth: 2
                           }],
                        tooltip: {
                                split: true
                            },
                        plotOptions: {
                            series: {
                                dataGrouping: {
                                    units: [['week', [1]], ['month', [1, 2, 3, 6]]]
                                }
                            }
                        },
                    series: [{
                        type: 'candlestick',
                        name: '\(self.symbol)',
                        id: '\(self.symbol)',
                        zIndex: 2,
                        data: [\(ohlcData)],
                    }, {
                        type: 'column',
                        name: 'Volume',
                        id: 'volume',
                        data: [\(volumeData)],
                        yAxis: 1
                    }, {
                        type: 'vbp',
                        linkedTo: '\(self.symbol)',
                        params: {
                            volumeSeriesID: 'volume'
                        },
                        dataLabels: {
                            enabled: false
                        },
                        zoneLines: {
                            enabled: false
                        }
                    }, {
                        type: 'sma',
                        linkedTo: '\(self.symbol)',
                        zIndex: 1,
                        marker: {
                            enabled: false
                        }
                    }]
                }
                """
                
                let jsCodesma = "updateHistoricalChart(\(jsChartData))"
                DispatchQueue.main.async {
                    webView.evaluateJavaScript(jsCodesma) { (result, error) in
                        if let error = error {
                            print("JavaScript execution error Details: \(error)")
                            print("JavaScript execution error: \(error.localizedDescription)")
                        } else if let result = result {
                            print("JavaScript execution result: \(result)")
                        }
                    }
                }

            case .failure(let error):
                print("Error fetching historical data for SMA chart: \(error)")
            }
        }
    }
    
    private func injectRecommendationTrends(_ webView: WKWebView) {
        stockService.fetchRecommendationTrends(symbol: symbol) { result in
            switch result {
            case .success(let trends):
                let categories = trends.map { $0.period }.quotedJoined(separator: ",")
                let strongBuyData = trends.map { $0.strongBuy }
                let buyData = trends.map { $0.buy }
                let holdData = trends.map { $0.hold }
                let sellData = trends.map { $0.sell }
                let strongSellData = trends.map { $0.strongSell }
                
                let jsSeriesData = """
                [{
                    name: 'Strong Buy',
                    data: \(strongBuyData),
                    color: '#1a7b40'
                }, {
                    name: 'Buy',
                    data: \(buyData),
                    color: '#23c15b'
                }, {
                    name: 'Hold',
                    data: \(holdData),
                    color: '#c29520'
                }, {
                    name: 'Sell',
                    data: \(sellData),
                    color: '#f56767'
                }, {
                    name: 'Strong Sell',
                    data: \(strongSellData),
                    color: '#8e3838'
                }]
                """
                
                let jsOptionsForRecommendationTrends = """
                {
                    chart: {
                        type: 'column',
                        backgroundColor: 'rgba(0, 0, 0, 0.05)'
                    },
                    title: {
                        text: 'Recommendation Trends'
                    },
                    xAxis: {
                        categories: [\(categories)]
                    },
                    yAxis: {
                        min: 0,
                        title: {
                            text: 'Number of Recommendations'
                        },
                        stackLabels: {
                            enabled: true,
                            style: {
                                fontWeight: 'bold',
                                color: 'gray'
                            }
                        }
                    },
                    legend: {
                        enabled: true
                    },
                    tooltip: {
                        headerFormat: '<b>{point.x}</b><br/>',
                        pointFormat: '{series.name}: {point.y}<br/>Total: {point.stackTotal}'
                    },
                    plotOptions: {
                        column: {
                            stacking: 'normal',
                            dataLabels: {
                                enabled: true
                            }
                        }
                    },
                    series: \(jsSeriesData)
                }
                """
                
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("updateRecommendationTrendsChart(\(jsOptionsForRecommendationTrends))") { result, error in
                        if let error = error {
                            print("JavaScript execution error: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                print("Error fetching recommendation trends data: \(error.localizedDescription)")
            }
        }
    }
    
    private func injectHistoricalEPS(_ webView: WKWebView) {
        stockService.fetchHistoricalEPS(symbol: symbol) { result in
            switch result {
            case .success(let earnings):
                let actualData = earnings.map { $0.actual }
                let estimateData = earnings.map { $0.estimate }
                let categories = earnings.map { "\($0.period)<br/>Surprise: \($0.surprise)" }.quotedJoined(separator: ",")

                let jsOptionsForHistoricalEPS = """
                {
                    chart: {
                        type: 'spline',
                        backgroundColor: 'rgba(0, 0, 0, 0.05)'
                    },
                    title: {
                        text: 'Historical EPS Surprises'
                    },
                    xAxis: {
                        categories: [\(categories)]
                    },
                    yAxis: {
                        title: {
                            text: 'Quarterly EPS'
                        }
                    },
                    tooltip: {
                        crosshairs: true,
                        shared: true
                    },
                    series: [{
                        name: 'Actual',
                        data: \(actualData)
                    }, {
                        name: 'Estimate',
                        data: \(estimateData)
                    }]
                }
                """
                
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("updateHistoricalEPSChart(\(jsOptionsForHistoricalEPS))") { result, error in
                        if let error = error {
                            print("JavaScript execution error: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                print("Error fetching historical EPS data: \(error.localizedDescription)")
            }
        }
    }



    
    
    // Helper function to convert timestamp milliseconds to UTC Date components
    private func convertToUTCDate(milliseconds: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return "\(components.year!), \(components.month! - 1), \(components.day!), \(components.hour!), \(components.minute!)"
    }
}

extension Array where Element == String {
    /// Converts the array of strings to a JavaScript array string where each element is quoted.
    ///
    /// - Parameter separator: A string to insert between each of the elements in this sequence. The default separator is a comma `,`.
    /// - Returns: A JavaScript array string of quoted strings.
    func quotedJoined(separator: String = ",") -> String {
        return self.map { "\"\($0)\"" }.joined(separator: separator)
    }
}
