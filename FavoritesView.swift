//
//  FavoritesView.swift
//  BRYHNH2
//
//  Created by Bill Skrzypczak on 4/24/25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var items: [RSSItem] = []
    
    var favoriteItems: [RSSItem] {
        let favs = items.filter { favoritesManager.isFavorite($0.id) }
        print("Found \(favs.count) favorite items")
        return favs
    }
    
    var body: some View {
        NavigationView {
            if favoriteItems.isEmpty {
                VStack {
                    Text("No favorites yet")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("Tap the star icon to add shows to your favorites")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                List(favoriteItems) { item in
                    NavigationLink(destination: DetailView(item: item, playbackPosition: .constant(nil))) {
                        VStack(alignment: .leading) {
                            HStack {
                                Image("RowImage")
                                    .resizable()
                                    .frame(width: 90, height: 100)
                                
                                Text(item.title)
                                    .padding([.top, .bottom], 10)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Rectangle()
                                .frame(height: 8)
                                .foregroundColor(.orange)
                                .edgesIgnoringSafeArea(.horizontal)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                    .padding(.vertical, -9)
                    .padding(.horizontal, -9)
                }
                .navigationTitle("Favorites")
            }
        }
        .onAppear {
            print("FavoritesView appeared")
            fetchRSSFeed()
        }
    }
    
    private func fetchRSSFeed() {
        if let url = URL(string: "https://www.bestradioyouhaveneverheard.com/podcasts/index.xml") {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data {
                    let parser = XMLParser(data: data)
                    let delegate = RSSParserDelegate()
                    parser.delegate = delegate
                    
                    if parser.parse() {
                        DispatchQueue.main.async {
                            self.items = delegate.items
                            print("Fetched \(delegate.items.count) items from RSS feed")
                        }
                    }
                } else if let error = error {
                    print("Error fetching RSS feed: \(error.localizedDescription)")
                }
            }.resume()
        }
    }
}

// Add preview
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
            .environmentObject(FavoritesManager())
    }
}
