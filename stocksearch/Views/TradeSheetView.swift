//
//  TradeSheetView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/27/24.
//

import SwiftUI

enum TradeType: String {
    case buy = "Buy"
    case sell = "Sell"
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct TradeSheetView: View {
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @Binding var isPresented: Bool
    let symbol: String
    let tradeType: TradeType
    

    @State private var quantityString = ""
    @State private var tradeSuccessMessage: AlertMessage?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showToast = false
    @State private var toastMessage = ""

    private var availableBalance: Double {
        portfolioViewModel.cashBalance ?? 0
    }

    private var currentStockPrice: Double {
        portfolioViewModel.stocks.first(where: { $0.symbol == symbol })?.currentPrice ?? 0
    }

    private var calculatedCost: Double {
        (Double(quantityString) ?? 0) * currentStockPrice
    }

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Processing...")
                } else {
                    Text("Trade \(symbol) shares")
                        .font(.title3)
                    
                    Spacer()
                    
                    VStack {
                        HStack {
                            TextField("0", text: $quantityString)
                                .keyboardType(.numberPad)
                                .padding()
                                .font(.title2)
                            Spacer()
                            Text(quantityString <= "1" ? "Share" : "Shares")
                                .padding()
                        }
                        HStack {
                            Spacer()
                            Text("x\(currentStockPrice, specifier: "%.2f")/share = \(calculatedCost, specifier: "%.2f")")
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        HStack{
                            Text("$\(availableBalance, specifier: "%.2f") available to buy \(symbol)").foregroundColor(.secondary)
                        }
                        HStack {
                            Spacer()
                            Button("Buy") {
                                self.confirmTrade(isBuy: true)
                            }
                            .disabled(isLoading)
                            .foregroundColor(.white)
                            .padding()
                            .padding(.horizontal, 50)
                            .background(Color.green)
                            .cornerRadius(20)
                            Spacer()
                            
                            Button("Sell") {
                                self.confirmTrade(isBuy: false)
                            }
                            .disabled(isLoading)
                            .foregroundColor(.white)
                            .padding()
                            .padding(.horizontal, 50)
                            .background(Color.green)
                            .cornerRadius(20)
                            Spacer()
                            
                        }
                    }
                    

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }

                    

                }
            }
            .overlay(
                            toastView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .edgesIgnoringSafeArea(.all)
                                .animation(.easeInOut, value: showToast)
                                .transition(.move(edge: .bottom)),
                            alignment: .bottom
                        )
            .navigationBarItems(trailing: Button("Close") { isPresented = false })
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $tradeSuccessMessage) { alertMessage in
                Alert(
                    title: Text("Trade Successful"),
                    message: Text(alertMessage.message),
                    dismissButton: .default(Text("OK")) {
                        isPresented = false
                    }
                )
            }
        }
    }
    
    private var toastView: some View {
            Group {
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .padding()
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                    }
                }
            }
        }

    private func confirmTrade(isBuy: Bool) {
        guard let quantity = Int(quantityString), quantity > 0 else {
            let message = quantityString.isEmpty || Int(quantityString) == nil ? "Please enter a valid amount of shares." : (isBuy ? "Cannot buy non-positive shares" : "Cannot sell non-positive shares")
                    showLocalToast(message: message)
                    return
        }

        if isBuy {
            if calculatedCost > availableBalance {
                showLocalToast(message: "Not enough money to buy \(quantity) shares.")
                return
            }
        } else {
            let ownedShares = portfolioViewModel.stocks.first(where: { $0.symbol == symbol })?.quantity ?? 0
            if quantity > ownedShares {
                showLocalToast(message: "Not enough shares to sell.")
                return
            }
        }

        isLoading = true
        errorMessage = nil

        let tradeAction = isBuy ? portfolioViewModel.buyStock : portfolioViewModel.sellStock
        tradeAction(symbol, quantity, currentStockPrice) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let message):
                    self.tradeSuccessMessage = AlertMessage(message: message)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    showLocalToast(message: self.errorMessage ?? "An error occurred")
                }
            }
        }
    }
    private func showLocalToast(message: String) {
            toastMessage = message
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showToast = false
            }
        }
}



struct TradeSheetView_Previews: PreviewProvider {
    @State static var isPresented = true
    static var previews: some View {
        TradeSheetView(isPresented: $isPresented, symbol: "AAPL", tradeType: .buy)
            .environmentObject(PortfolioViewModel())
    }
}


