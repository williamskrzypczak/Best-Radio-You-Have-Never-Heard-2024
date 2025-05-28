import UIKit
import CarPlay
import MediaPlayer
import AVFoundation

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    var player: AVPlayer?
    private let logger = Logger(subsystem: "com.bestradio", category: "CarPlay")
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // Configure audio session for CarPlay
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Set preferred sample rate and I/O buffer duration
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
            
            logger.debug("Audio session configured successfully for CarPlay")
        } catch {
            logger.error("Failed to configure audio session for CarPlay: \(error.localizedDescription)")
        }
        
        // Set up remote control events
        setupRemoteControlEvents()
        
        // Create and show the main template
        let template = createMainTemplate()
        interfaceController.setRootTemplate(template, animated: true)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
    
    private func createMainTemplate() -> CPTemplate {
        // Create a list of episodes
        let episodes = RSSService.fetchEpisodesForCarPlay()
        let items = episodes.map { episode -> CPListItem in
            let item = CPListItem(text: episode.title, detailText: nil, image: nil)
            item.handler = { [weak self] _, completion in
                self?.playEpisode(episode)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Best Radio", sections: [section])
        return template
    }
    
    private func playEpisode(_ episode: RSSItem) {
        guard let urlString = episode.enclosureUrl,
              let url = URL(string: urlString) else {
            logger.error("Invalid episode URL")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Set up initial Now Playing info
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Best Radio"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Best Radio You Have Never Heard"
        
        // Load artwork if available
        Task {
            do {
                let metadata = try await playerItem.asset.load(.commonMetadata)
                if let artworkData = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork).first?.dataValue,
                   let image = UIImage(data: artworkData) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                }
                
                // Set initial Now Playing info with artwork
                await MainActor.run {
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            } catch {
                logger.error("Failed to load artwork: \(error.localizedDescription)")
                // Set Now Playing info without artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
        
        // Add time observer to update only time-related properties
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            updatedInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time.seconds
            updatedInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player?.rate ?? 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
        }
        
        player?.play()
    }
    
    private func setupRemoteControlEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Remove existing handlers
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            return .success
        }
        
        // Skip forward command
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.player,
                  let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            
            let newTime = CMTimeAdd(player.currentTime(), CMTime(seconds: event.interval, preferredTimescale: 1))
            player.seek(to: newTime)
            return .success
        }
        
        // Skip backward command
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.player,
                  let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            
            let newTime = CMTimeSubtract(player.currentTime(), CMTime(seconds: event.interval, preferredTimescale: 1))
            player.seek(to: newTime)
            return .success
        }
        
        // Change playback position command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.player,
                  let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            
            player.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 1))
            return .success
        }
    }
} 