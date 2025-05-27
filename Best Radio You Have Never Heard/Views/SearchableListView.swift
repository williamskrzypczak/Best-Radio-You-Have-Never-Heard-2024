import SwiftUI

struct SearchableListView: View {
    let items: [RSSItem]
    @Binding var searchText: String
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var selectedItemId: UUID?
    
    var filteredItems: [RSSItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            let titleMatch = item.title.localizedCaseInsensitiveContains(searchText)
            let contentMatch = item.htmlContent.localizedCaseInsensitiveContains(searchText)
            return titleMatch || contentMatch
        }
    }
    
    var body: some View {
        List(filteredItems, id: \.id) { item in
            EpisodeRow(item: item, selectedItemId: $selectedItemId)
        }
        .searchable(text: $searchText, prompt: "Search episodes...")
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
    }
} 