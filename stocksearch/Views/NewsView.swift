//
//  NewsView.swift
//  stocksearch
//
//  Created by Sarthak Harshe on 4/27/24.
//

import SwiftUI
import Kingfisher

struct NewsView: View {
    let article: NewsArticle
    var isFirstArticle: Bool = false
    let currentTime = Int64(Date().timeIntervalSince1970)
    
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if isFirstArticle {
                // First article layout
                if let imageUrl = URL(string: article.image), !article.image.isEmpty {
                    KFImage(imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.width / 2)
                        .clipped()
                        .cornerRadius(10)
                }
                HStack {
                    Text(article.source).font(.subheadline).foregroundColor(.secondary)
                    Text("\((currentTime - article.datetime)/3600) hr, \(((currentTime - article.datetime)%3600)/60) min").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                }
                Text(article.headline).font(.headline)
                Divider()
            } else {
                // Rest of the articles layout
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(article.source).font(.headline).foregroundColor(.secondary)
                            Text("\((currentTime - article.datetime)/3600) hr, \(((currentTime - article.datetime)%3600)/60) min").font(.footnote).foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        Text(article.headline).font(.headline)
                        
                    }
                    Spacer()
                    if let imageUrl = URL(string: article.image), !article.image.isEmpty {
                        KFImage(imageUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            NewsDetailView(article: article,  isPresented: $showDetails)
        }
    }
}

struct NewsDetailView: View {
    let article: NewsArticle
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(article.source).font(.headline)
                    Text(article.datetime.formattedDate()).foregroundColor(.secondary)
                    Divider()
                    Text(article.headline).font(.title)
                    Text(article.summary).font(.body)
                    HStack {
                                            Text("For more details click ")
                                            Button("here") {
                                                if let url = URL(string: article.url), UIApplication.shared.canOpenURL(url) {
                                                    UIApplication.shared.open(url)
                                                }
                                            }
                                            .foregroundColor(.blue)
                                        }
                    HStack {
                        Link(destination: URL(string:"https://twitter.com/intent/tweet?text=\(article.headline )&url=\(article.url)")!){
                                            Image("Twitter").resizable().imageScale(.small).frame(width: 35,height: 35)
                        }
                        Link(destination:URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(self.article.url)&amp;src=sdkpreparse")!){
                            Image("Facebook").resizable().imageScale(.small).frame(width: 35,height: 35)
                            }
                    }
                                    
                }
                .padding()
            }
            .navigationBarItems(trailing: Button(action: {
                self.isPresented = false
            }) {
                Image(systemName: "xmark")
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension Int64 {
    func formattedDate() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"  // Example: January 01, 2022
        return formatter.string(from: date)
    }
}


// Dummy implementation for the preview
extension TimeInterval {
    func timeAgo() -> String {
        // Your implementation here
        return "5m"
    }
}

// Preview Provider
struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        let article = NewsArticle(
            id: 1,
            category: "business",
            datetime: 1617694838,
            headline: "Breaking News!",
            image: "https://via.placeholder.com/100",
            related: "AAPL",
            source: "Yahoo",
            summary: "This is a summary of the news article.",
            url: "https://www.yahoo.com"
        )
        NewsView(article: article)
    }
}
