import Foundation

class PlaybackPositionManager {
    static let shared = PlaybackPositionManager()
    private let key = "SavedPlaybackPositions"
    
    private init() {}
    
    func savePosition(for episodeID: String, position: Double) {
        var positions = getAllPositions()
        positions[episodeID] = position
        UserDefaults.standard.set(positions, forKey: key)
    }
    
    func getPosition(for episodeID: String) -> Double? {
        let positions = getAllPositions()
        return positions[episodeID]
    }
    
    func removePosition(for episodeID: String) {
        var positions = getAllPositions()
        positions.removeValue(forKey: episodeID)
        UserDefaults.standard.set(positions, forKey: key)
    }
    
    private func getAllPositions() -> [String: Double] {
        return UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
    }
} 