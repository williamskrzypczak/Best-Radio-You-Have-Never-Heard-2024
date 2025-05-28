import Foundation

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    private let key = "FavoriteEpisodes"
    
    @Published private(set) var favoriteEpisodes: Set<String> = []
    
    private init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.stringArray(forKey: key) {
            favoriteEpisodes = Set(savedFavorites)
        }
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteEpisodes), forKey: key)
    }
    
    func toggleFavorite(episodeId: String) {
        if favoriteEpisodes.contains(episodeId) {
            favoriteEpisodes.remove(episodeId)
        } else {
            favoriteEpisodes.insert(episodeId)
        }
        saveFavorites()
    }
    
    func isFavorite(episodeId: String) -> Bool {
        return favoriteEpisodes.contains(episodeId)
    }
} 