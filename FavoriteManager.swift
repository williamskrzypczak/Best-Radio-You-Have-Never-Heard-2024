//
//  FavoriteManager.swift
//  BRYHNH2
//
//  Created by Bill Skrzypczak on 4/24/25.
//

import Foundation

/// Manages the user's favorite shows using UserDefaults for persistence
class FavoritesManager: ObservableObject {
    @Published var favorites: Set<UUID> = []
    private let favoritesKey = "favoriteShows"
    
    init() {
        loadFavorites()
    }
    
    /// Loads favorites from UserDefaults
    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey) {
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(Set<UUID>.self, from: data)
                favorites = decoded
                print("Loaded favorites: \(favorites.count) items")
            } catch {
                print("Error loading favorites: \(error)")
                favorites = []
            }
        } else {
            print("No favorites data found in UserDefaults")
            favorites = []
        }
    }
    
    /// Saves favorites to UserDefaults
    private func saveFavorites() {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(favorites)
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
            print("Saved favorites: \(favorites.count) items")
        } catch {
            print("Error saving favorites: \(error)")
        }
    }
    
    /// Adds a show to favorites
    /// - Parameter id: The UUID of the show to add
    func addFavorite(_ id: UUID) {
        favorites.insert(id)
        saveFavorites()
        print("Added favorite: \(id)")
    }
    
    /// Removes a show from favorites
    /// - Parameter id: The UUID of the show to remove
    func removeFavorite(_ id: UUID) {
        favorites.remove(id)
        saveFavorites()
        print("Removed favorite: \(id)")
    }
    
    /// Checks if a show is favorited
    /// - Parameter id: The UUID of the show to check
    /// - Returns: True if the show is favorited, false otherwise
    func isFavorite(_ id: UUID) -> Bool {
        let isFav = favorites.contains(id)
        print("Checking if \(id) is favorite: \(isFav)")
        return isFav
    }
}
