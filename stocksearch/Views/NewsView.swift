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
                    Text("\(article.datetime.timeAgo())").font(.footnote)
                    Spacer()
                }
                Text(article.headline).font(.headline)
            } else {
                // Rest of the articles layout
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(article.source).font(.headline).foregroundColor(.secondary)
                            Text("\(article.datetime.timeAgo())").font(.footnote).foregroundColor(.secondary)
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
                    Text(article.headline).font(.title)
                    Text(article.summary).font(.body)
                    Link("Read Full Article", destination: URL(string: article.url)!)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button(action: {
                self.isPresented = false
            }) {
                Image(systemName: "xmark")
            })
            .navigationTitle("News Details")
            .navigationBarTitleDisplayMode(.inline)
        }
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
            datetime: TimeInterval(1617694838),
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
