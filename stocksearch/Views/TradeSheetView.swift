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
    @State private var showSuccessScreen = false
    @State private var successMessage = ""
    @State private var isLoading = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var errorMessage: String?
    
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
                } else if showSuccessScreen {
                    successView()
                } else {
                    tradeFormView()
                }
            }
            .navigationBarItems(trailing: Button("Close") { isPresented = false })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func tradeFormView() -> some View {
        VStack {
            Text("Trade \(symbol) shares")
                .font(.title3)
            
            Spacer()
            
            VStack {
                HStack {
                    TextField("0", text: $quantityString)
                        .keyboardType(.numberPad)
                        .padding()
                        .font(.system(size: 50))
                    Spacer()
                    Text(quantityString == "1" ? "Share" : "Shares")
                        .padding()
                }
                HStack {
                    Spacer()
                    Text("x\(currentStockPrice, specifier: "%.2f")/share = \(calculatedCost, specifier: "%.2f")")
                }
                .padding()
            }
            
            Spacer()
            
            VStack {
                Text("$\(availableBalance, specifier: "%.2f") available to buy \(symbol)").foregroundColor(.secondary)
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
        .overlay(
            toastView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut, value: showToast)
                .transition(.move(edge: .bottom)),
            alignment: .bottom
        )
    }
    
    
    private func successView() -> some View {
        VStack {
            Spacer()
            Text("Congratulations")
                .font(.title)
                .foregroundColor(.white)
            Text("You have successfully bought \(quantityString) Shares of \(symbol)")
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Button("Done") {
                self.isPresented = false
            }
            .foregroundColor(.green)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
        }
        .padding()
        .background(Color.green)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(showSuccessScreen ? 1 : 0)
        .animation(.easeIn(duration: 0.8), value: showSuccessScreen)
    }
    
    private func confirmTrade(isBuy: Bool) {
        guard let quantity = Int(quantityString), quantity > 0 else {
            showLocalToast(message: "Please enter a valid number of shares.")
            return
        }
        
        if isBuy {
            if calculatedCost > availableBalance {
                showLocalToast(message: "Insufficient funds to buy \(quantity) shares.")
                return
            }
        }
        
        isLoading = true
        
        portfolioViewModel.buyStock(symbol: symbol, quantity: quantity, price: currentStockPrice) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    self.showSuccessScreen = true
                    self.successMessage = "You have successfully bought \(quantity) shares of \(symbol)."
                case .failure(let error):
                    self.showLocalToast(message: error.localizedDescription)
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
}

struct TradeSheetView_Previews: PreviewProvider {
    @State static var isPresented = true
    static var previews: some View {
        TradeSheetView(isPresented: $isPresented, symbol: "AAPL", tradeType: .buy)
            .environmentObject(PortfolioViewModel())
    }
}


