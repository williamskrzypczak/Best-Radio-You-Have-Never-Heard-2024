//
//  ContentView.swift
//  Best Radio You Have Never Heard
//
//  Created by Bill Skrzypczak on 12/26/23.
//

import SwiftUI
import WebKit
import Combine
import AVFoundation
import AVKit
import Foundation

//---------------------------------------------------------------]
//
// Main Content View attributes and behaviours
//
//---------------------------------------------------------------]

// Class definition for RSS parser delegate
class RSSParserDelegate: NSObject, XMLParserDelegate {
    var currentItem: RSSItem?
    var currentElement: String = ""
    var currentAttributes: [String: String] = [:]
    var items: [RSSItem] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentItem = RSSItem(title: "", htmlContent: "", enclosureUrl: nil)
        } else if elementName == "enclosure" {
            currentAttributes = attributeDict
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !data.isEmpty {
            switch currentElement {
            case "title":
                currentItem?.title += data
            case "description":
                currentItem?.htmlContent += data
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            if let item = currentItem {
                items.append(item)
            }
            currentItem = nil
        } else if elementName == "enclosure" {
            currentItem?.enclosureUrl = currentAttributes["url"]
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FavoritesManager())
    }
}

struct RSSItem: Identifiable {
    let id = UUID()
    var title: String
    var htmlContent: String
    var enclosureUrl: String?
    var isFavorite: Bool = false
    
    init(title: String, htmlContent: String, enclosureUrl: String?) {
        self.title = title
        // Clean the content by removing "Best Radio You Have Never Heard" and any extra whitespace
        self.htmlContent = htmlContent
            .replacingOccurrences(of: "Best Radio You Have Never Heard", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.enclosureUrl = enclosureUrl
    }
}

struct ContentView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var loadingItemId: String?
    @State private var items: [RSSItem] = []
    @State private var searchText = ""
    @State private var playbackPosition: TimeInterval? = nil
    @State private var selectedItemId: UUID?
    @State private var showFavoritesOnly = false
    
    var filteredItems: [RSSItem] {
        if showFavoritesOnly {
            return items.filter { favoritesManager.isFavorite($0.id) }
        }
        return items
    }
    
    var body: some View {
        NavigationView {
            if #available(iOS 15.0, *) {
                VStack(spacing: 0) {
                    // Favorites toggle
                    HStack {
                        Spacer()
                        Toggle("Show Favorites Only", isOn: $showFavoritesOnly)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(showFavoritesOnly ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))
                    
                    SearchableListView(items: filteredItems, searchText: $searchText)
                }
                .onAppear {
                    fetchRSSFeed()
                }
            } else {
                // Fallback for earlier versions
            }
        }
        .onAppear {
            favoritesManager.loadFavorites()
        }
    }
    
    func fetchRSSFeed() {
        if let url = URL(string: "https://www.bestradioyouhaveneverheard.com/podcasts/index.xml") {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data {
                    DispatchQueue.main.async {
                        self.parseRSS(data: data)
                        // Update favorite states after loading items
                        for index in self.items.indices {
                            self.items[index].isFavorite = self.favoritesManager.isFavorite(self.items[index].id)
                        }
                    }
                } else if let error = error {
                    print("Error fetching RSS feed: \(error.localizedDescription)")
                }
            }.resume()
        }
    }
    
    func parseRSS(data: Data) {
        let parser = XMLParser(data: data)
        let rssParserDelegate = RSSParserDelegate()
        parser.delegate = rssParserDelegate
        
        if parser.parse() {
            DispatchQueue.main.async {
                self.items = rssParserDelegate.items
            }
        } else {
            print("Error parsing RSS feed.")
        }
    }
}

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

struct EpisodeRow: View {
    let item: RSSItem
    @Binding var selectedItemId: UUID?
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Row image with improved styling
            Image("RowImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 100)
                .cornerRadius(8)
                .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Progress indicator
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(.orange)
                    .cornerRadius(2)
            }
            
            Spacer()
            
            // Favorite button with improved styling
            Button(action: {
                withAnimation {
                    if favoritesManager.isFavorite(item.id) {
                        favoritesManager.removeFavorite(item.id)
                    } else {
                        favoritesManager.addFavorite(item.id)
                    }
                }
            }) {
                Image(systemName: favoritesManager.isFavorite(item.id) ? "star.fill" : "star")
                    .foregroundColor(favoritesManager.isFavorite(item.id) ? .orange : .gray)
                    .imageScale(.large)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            NavigationLink(destination: DetailView(item: item, playbackPosition: .constant(nil))
                .onAppear { selectedItemId = item.id }
                .onDisappear { selectedItemId = nil }
            ) {
                EmptyView()
            }
            .opacity(0)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

//---------------------------------------------------------------]
//
// Detail View attributes and behaviours
//
//---------------------------------------------------------------]

struct AirPlayButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.activeTintColor = .orange
        routePickerView.tintColor = .orange
        return routePickerView
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else {
            return self
        }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }
        return self
    }
}

private func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print("Failed to set audio session category. Error: \(error)")
    }
}

func fetchAlbumArt(from url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let metadata = asset.commonMetadata
    if let artworkData = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork).first?.dataValue {
        return UIImage(data: artworkData)
    }
    return nil
}

struct DetailView: View {
    let item: RSSItem
    @State private var albumArt: UIImage?
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    @State private var imageData: Data?
    @State private var volume: Float = 0.5
    @Binding var playbackPosition: TimeInterval?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0.0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var sliderValue: Double = 0
    @State private var lastPlaybackPosition: TimeInterval?
    @State private var autoPlay = false
    let rewindInterval: TimeInterval = 15
    let fastForwardInterval: TimeInterval = 15
    @State private var savePlaybackPosition = UserDefaults.standard.bool(forKey: "savePlaybackPositionEnabled")
    @State private var isLoadingImage = true
    @State private var imageLoadTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Background image at the top
            if isLoadingImage {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            } else if let albumArt = albumArt {
                Image(uiImage: albumArt)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                Image("RowImage")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            }
            
            // Main content
            ScrollView {
                VStack(spacing: 16) {
                    // Title and content
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                            .lineLimit(2)
                        
                        ScrollView {
                            Text(item.htmlContent.strippingHTML())
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .frame(maxHeight: 150)
                        .scrollIndicators(.visible)
                    }
                    .padding(.vertical, 8)
                    
                    // Audio controls
                    if let enclosureUrl = item.enclosureUrl, URL(string: enclosureUrl) != nil {
                        VStack(spacing: 12) {
                            // AirPlay button
                            AirPlayButtonView()
                                .frame(width: 60, height: 60)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(10)
                            
                            // Playback controls
                            HStack(spacing: 25) {
                                Button(action: rewindAudio) {
                                    Image(systemName: "gobackward.\(Int(rewindInterval))")
                                        .imageScale(.large)
                                        .foregroundColor(.black)
                                }
                                
                                Button(action: playOrPauseAudio) {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.black)
                                }
                                
                                Button(action: fastForwardAudio) {
                                    Image(systemName: "goforward.\(Int(fastForwardInterval))")
                                        .imageScale(.large)
                                        .foregroundColor(.black)
                                }
                                
                                Button(action: stopAudio) {
                                    Image(systemName: "stop.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Progress slider
                            VStack {
                                Slider(value: $currentTime, in: 0...duration, onEditingChanged: sliderEditingChanged)
                                    .accentColor(.orange)
                                
                                HStack {
                                    Text(formatTime(currentTime))
                                        .font(.caption)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(formatTime(duration))
                                        .font(.caption)
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.horizontal)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings toggles
                    VStack(spacing: 8) {
                        Toggle("Remember Playback Position", isOn: $savePlaybackPosition)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(savePlaybackPosition ? Color.orange.opacity(0.2) : Color.gray.opacity(0.3))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .onChange(of: savePlaybackPosition) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "savePlaybackPositionEnabled")
                            }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 48)
                }
                .padding(.top, 12)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
        .task {
            // Setup audio player first
            setupAudioPlayer()
            
            // Then fetch album art
            if let url = URL(string: item.enclosureUrl!) {
                imageLoadTask?.cancel()
                imageLoadTask = Task {
                    do {
                        let asset = AVAsset(url: url)
                        let metadata = try await asset.load(.commonMetadata)
                        if let artworkData = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork).first?.dataValue {
                            await MainActor.run {
                                albumArt = UIImage(data: artworkData)
                                isLoadingImage = false
                            }
                        } else {
                            await MainActor.run {
                                isLoadingImage = false
                            }
                        }
                    } catch {
                        print("Error loading album art: \(error)")
                        await MainActor.run {
                            isLoadingImage = false
                        }
                    }
                }
            } else {
                isLoadingImage = false
            }
            
            // Restore playback position if needed
            let lastEpisode = UserDefaults.standard.string(forKey: "lastPlayedEpisode")
            if savePlaybackPosition && lastEpisode == item.title {
                if let lastPosition = UserDefaults.standard.double(forKey: "lastPlaybackPosition") as TimeInterval? {
                    playbackPosition = lastPosition
                    seekToTime(lastPosition)
                    audioPlayer?.play()
                    isPlaying = true
                }
            }
        }
        .onDisappear {
            imageLoadTask?.cancel()
            if savePlaybackPosition {
                if let currentTime = audioPlayer?.currentTime().seconds {
                    playbackPosition = currentTime
                    UserDefaults.standard.set(currentTime, forKey: "lastPlaybackPosition")
                    UserDefaults.standard.set(item.title, forKey: "lastPlayedEpisode")
                    playOrPauseAudio()
                    audioPlayer?.pause()
                }
            }
        }
        .onReceive(timer) { _ in
            if audioPlayer?.timeControlStatus != .paused {
                currentTime = audioPlayer?.currentTime().seconds ?? 0
                if savePlaybackPosition {
                    UserDefaults.standard.set(currentTime, forKey: "lastPlaybackPosition")
                }
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func seekToTime(_ time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let timeCM = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: timeCM)
    }
    
    private var audioPlayerControls: some View {
        ZStack {
            VStack {
                VStack {
                    AirPlayButtonView()
                        .frame(width: 65, height: 65)
                        .background(Color.black.opacity(0.6))
                }
                HStack(spacing: 50) {
                    Button(action: rewindAudio) {
                        Image(systemName: "gobackward.\(Int(rewindInterval))")
                            .imageScale(.large)
                    }
                    Button(action: playOrPauseAudio) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .imageScale(.large)
                    }
                    Button(action: fastForwardAudio) {
                        Image(systemName: "goforward.\(Int(fastForwardInterval))")
                            .imageScale(.large)
                    }
                    Button(action: stopAudio) {
                        Image(systemName: "stop.fill")
                            .imageScale(.large)
                    }
                }
                .font(.title)
                .padding()
                .background(Color.black.opacity(0.6))
                Slider(value: $currentTime, in: 0...duration, onEditingChanged: sliderEditingChanged)
                    .frame(width: 330)
                    .accentColor(.blue)
                    .background(Color.black.opacity(0.6))
            }
        }
    }
    
    private func sliderEditingChanged(editingStarted: Bool) {
        if !editingStarted {
            seekToTime(currentTime)
        }
    }
    
    private func setupAudioPlayer() {
        configureAudioSession()
        guard let enclosureUrl = item.enclosureUrl, let url = URL(string: enclosureUrl) else {
            print("Invalid URL")
            return
        }
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.volume = Float(volume)
        if let durationCMTime = audioPlayer?.currentItem?.asset.duration {
            duration = CMTimeGetSeconds(durationCMTime)
        }
    }
    
    private func playOrPauseAudio() {
        guard let player = audioPlayer else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func rewindAudio() {
        guard let player = audioPlayer else { return }
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = playerCurrentTime - rewindInterval
        newTime = max(newTime, 0)
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        player.seek(to: time)
    }
    
    private func fastForwardAudio() {
        guard let player = audioPlayer else { return }
        if let duration = player.currentItem?.duration {
            let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
            let durationInSeconds = CMTimeGetSeconds(duration)
            var newTime = playerCurrentTime + fastForwardInterval
            newTime = min(newTime, durationInSeconds)
            let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
            player.seek(to: time)
        }
    }
    
    private func stopAudio() {
        audioPlayer?.pause()
        let time: CMTime = CMTimeMake(value: 0, timescale: 1)
        audioPlayer?.seek(to: time)
        isPlaying = false
    }
}

// Add async version of fetchAlbumArt
func fetchAlbumArtAsync(from url: URL) async -> UIImage? {
    let asset = AVAsset(url: url)
    let metadata = asset.commonMetadata
    if let artworkData = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork).first?.dataValue {
        return UIImage(data: artworkData)
    }
    return nil
}
