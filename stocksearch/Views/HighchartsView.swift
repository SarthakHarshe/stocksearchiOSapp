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
    @ObservedObject var stockService: StockDetailsModel
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
                let chartData = stockService.hourlyChartData
                print("HOURLY CHART DATA IN THE HIGHCHART VIEW")
                let seriesData = chartData.map { "[\($0.t), \($0.c)]" }.joined(separator: ", ")
                let formattedSeriesData = "[\(seriesData)]"
                let lineColor = (self.stockService.stockInfo?.change ?? 0) >= 0 ? "green" : "red"

                let jsChartOptions = """
                                    {
                                        chart: {
                                            type: 'line',
                                            style: {
                                                fontFamily: 'Arial',
                                            },
                                            height: '90%'
                                        },
                                        title: {
                                            text: '\(symbol) Hourly Price Variation',
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
                                            crosshair: {
                                                              width: 1,
                                                              color: 'lightgray',
                                                              dashStyle: 'Solid'
                                                            },
                                             tickInterval: 14400 * 1000,
                                        },
                                        yAxis: {
                                            title: {
                                                text: '',
                                            },
                                            opposite: true,
                                            tickAmount: 4,
                                        },
                                        series: [{
                                            name: '\(symbol)',
                                            data: \(formattedSeriesData),
                                            type: 'line',
                                            color: '\(lineColor)',
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
                                            split: true,
                                            crosshairs: true,
                                        },
                                        legend: {
                                            enabled: false,
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
    }
    
    // Function for the sma chart
    private func injectSMAChartData(_ webView: WKWebView) {
        let historicalData = stockService.historicalChartData
        
                let ohlcData = historicalData.map { "[\($0.x), \($0.open), \($0.high), \($0.low), \($0.close)]" }.joined(separator: ", ")
                let volumeData = historicalData.map { "[\($0.x), \($0.volume)]" }.joined(separator: ", ")

                let jsChartData = """
                {
                    chart: {
                                height: '90%'
                    },
                    legend: {
                        enabled: false,
                      },
                    rangeSelector: {
                                selected: 2
                    },
                    title: {
                        text: '\(self.symbol) Historical Stock Price'
                    },
                    subtitle: {
                        text: 'With SMA and Volume by Price technical indicators'
                    },
                    navigator: {
                        enabled: true
                    },
                    yAxis: [
                            {
                              opposite: true,
                              startOnTick: false,
                              endOnTick: false,
                              labels: {
                                align: 'right',
                                x: -3,
                              },
                              title: {
                                text: 'OHLC',
                              },
                              height: '60%',
                              lineWidth: 2,
                              resize: {
                                enabled: true,
                              },
                            },
                            {
                              opposite: true,
                              labels: {
                                align: 'right',
                                x: -3,
                              },
                              title: {
                                text: 'Volume',
                              },
                              top: '65%',
                              height: '35%',
                              offset: 0,
                              lineWidth: 2,
                            },
                          ],
                        xAxis: {
                        type: 'datetime',
                        dateTimeLabelFormats: {
                          hour: '%M:%Y',
                        },
                      },
                        tooltip: {
                                split: true
                            },
                    series: [{
                        type: 'candlestick',
                        name: '\(self.symbol)',
                        id: '\(self.symbol)',
                        zIndex: 2,
                        data: [\(ohlcData)],
                        color: 'black',
                        upColor: 'black',
                    }, {
                        type: 'column',
                        name: 'Volume',
                        id: 'volume',
                        color: 'violet',
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
        }
    
    private func injectRecommendationTrends(_ webView: WKWebView) {
        stockService.fetchRecommendationTrends(symbol: symbol) { result in
            switch result {
            case .success(let trends):
                let categories = trends.map {
                                let endIndex = $0.period.index($0.period.endIndex, offsetBy: -3)
                                return String($0.period[..<endIndex])
                            }.quotedJoined(separator: ",")
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
                        height: '100%'
                    },
                    title: {
                        text: 'Recommendation Trends'
                    },
                    xAxis: {
                        categories: [\(categories)],
                        tickAmount: 4
                    },
                    yAxis: {
                        min: 0,
                        title: {
                            text: '#Analysis'
                        },
                        tickAmount: 4
                    },
                    legend: {
                        enabled: true
                    },
                    tooltip: {
                        headerFormat: '{point.x}<br/>',
                        pointFormat: '<span style="color:{series.color}">\u{25CF}</span> {series.name}: <b>{point.y}</b>'
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
                        height: '100%'
                    },
                    title: {
                        text: 'Historical EPS Surprises'
                    },
                    xAxis: {
                        categories: [\(categories)],
                    },
                    yAxis: {
                        title: {
                            text: 'Quarterly EPS'
                        },
                    },
                    tooltip: {
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
    func quotedJoined(separator: String = ",") -> String {
        return self.map { "\"\($0)\"" }.joined(separator: separator)
    }
}
