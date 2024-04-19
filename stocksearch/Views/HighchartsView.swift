//
//  HighchartsView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/18/24.
//

import SwiftUI
import WebKit

struct HighchartsView: UIViewRepresentable {
    var stockService: StockDetailsModel
    let htmlName: String
    let symbol: String
    
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
            print("Web page loaded, now updating chart...")
            parent.injectJavaScript(webView)
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
                print("Printing charts Data which is received from the server: \(chartData)")
                print("Printing the series data which is converted to JavaScript format: \(seriesData)")
                print("Printing jsSeriesData: \(jsSeriesData)")

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
                print("JavaScript Options being sent to WebView: \(jsChartOptions)")
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
    
    
    // Helper function to convert timestamp milliseconds to UTC Date components
    private func convertToUTCDate(milliseconds: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return "\(components.year!), \(components.month! - 1), \(components.day!), \(components.hour!), \(components.minute!)"
    }
}

