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
import os.log

// Import Foundation types
@_exported import struct Foundation.UUID
@_exported import class Foundation.NSObject
@_exported import protocol Foundation.XMLParserDelegate
@_exported import class Foundation.XMLParser

//---------------------------------------------------------------]
//
// Main Content View attributes and behaviours
//
//---------------------------------------------------------------]

// Playback Position Manager
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

// RSS Model
struct RSSItem: Identifiable {
    let id = UUID()
    var title: String
    var htmlContent: String
    var enclosureUrl: String?
    
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

// RSS Parser
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

// RSS Service
class RSSService {
    static func fetchRSSFeed(completion: @escaping ([RSSItem]?, Error?) -> Void) {
        guard let url = URL(string: "https://www.bestradioyouhaveneverheard.com/podcasts/index.xml") else {
            completion(nil, NSError(domain: "RSSService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "RSSService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            let parser = XMLParser(data: data)
            let rssParserDelegate = RSSParserDelegate()
            parser.delegate = rssParserDelegate
            
            if parser.parse() {
                completion(rssParserDelegate.items, nil)
            } else {
                completion(nil, NSError(domain: "RSSService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse RSS feed"]))
            }
        }.resume()
    }
}

// Main Content View
struct ContentView: View {
    @State private var items: [RSSItem] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var filteredItems: [RSSItem] {
        return items
    }
    
    var body: some View {
        NavigationView {
            if #available(iOS 15.0, *) {
                ZStack {
                    // Background
                    Color(colorScheme == .dark ? .black : .white)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Custom header
                        VStack(spacing: 2) {
                            Text("Best Radio")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            Text("You Have Never Heard")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                        }
                        .padding(.bottom, 2)
                        
                        if isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                    .scaleEffect(1.5)
                                Text("Loading Episodes...")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            SearchableListView(items: filteredItems, searchText: $searchText)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .onAppear {
                    loadRSSFeed()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isDarkMode.toggle()
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                windowScene.windows.forEach { window in
                                    window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                                }
                            }
                        }) {
                            Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 20))
                        }
                    }
                }
            } else {
                // Fallback for earlier versions
            }
        }
    }
    
    private func loadRSSFeed() {
        RSSService.fetchRSSFeed { fetchedItems, error in
            if let error = error {
                print("Error fetching RSS feed: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let fetchedItems = fetchedItems {
                DispatchQueue.main.async {
                    self.items = fetchedItems
                    self.isLoading = false
                }
            }
        }
    }
}

//---------------------------------------------------------------]
//
// List View Components
//
//---------------------------------------------------------------]

struct SearchableListView: View {
    let items: [RSSItem]
    @Binding var searchText: String
    @State private var selectedItemId: UUID?
    @Environment(\.colorScheme) var colorScheme
    
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
        .background(Color.clear)
        .scrollContentBackground(.hidden)
    }
}

struct EpisodeRow: View {
    let item: RSSItem
    @Binding var selectedItemId: UUID?
    @State private var albumArt: UIImage?
    @State private var isLoadingImage = true
    @State private var imageLoadTask: Task<Void, Never>?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Row image with improved styling
            if isLoadingImage {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.3))
                    .frame(width: 90, height: 120)
                    .cornerRadius(12)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    )
            } else if let albumArt = albumArt {
                Image(uiImage: albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 120)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            } else {
                Image("RowImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 120)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(3)
                
                // Progress indicator
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(.orange)
                    .cornerRadius(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            NavigationLink(destination: DetailView(item: item)
                .onAppear { selectedItemId = item.id }
                .onDisappear { selectedItemId = nil }
            ) {
                EmptyView()
            }
            .opacity(0)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .task {
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
        }
        .onDisappear {
            imageLoadTask?.cancel()
        }
    }
}

//---------------------------------------------------------------]
//
// Detail View Components
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

// Audio Player State
class AudioPlayerState: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var volume: Float = 0.5
    @Published var sliderTime: Double = 0
    
    private var player: AVPlayer?
    private let logger = Logger(subsystem: "com.bestradio", category: "AudioPlayer")
    private var timeObserver: Any?
    private var isDragging = false
    
    func setupPlayer(url: URL) {
        // Clean up existing observer if any
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume
        
        // Get duration
        Task {
            if let durationCMTime = try? await playerItem.asset.load(.duration) {
                await MainActor.run {
                    duration = CMTimeGetSeconds(durationCMTime)
                    logger.debug("Audio duration: \(self.duration)")
                }
            }
        }
        
        // Setup time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            self.currentTime = seconds
            if !self.isDragging {
                self.sliderTime = seconds
            }
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        sliderTime = 0
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime)
        currentTime = time
        sliderTime = time
    }
    
    func startDragging() {
        isDragging = true
    }
    
    func stopDragging() {
        isDragging = false
        seek(to: sliderTime)
    }
    
    func getCurrentTime() -> Double {
        return player?.currentTime().seconds ?? 0
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

struct DetailView: View {
    let item: RSSItem
    @StateObject private var playerState = AudioPlayerState()
    @Environment(\.colorScheme) var colorScheme
    private let logger = Logger(subsystem: "com.bestradio", category: "DetailView")
    let rewindInterval: TimeInterval = 15
    let fastForwardInterval: TimeInterval = 15
    @State private var saveMyPlace: Bool = false
    @State private var hasRestoredPosition: Bool = false

    var episodeID: String? {
        item.enclosureUrl
    }

    var body: some View {
        ZStack {
            // Background
            Color(colorScheme == .dark ? .black : .white)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    Image("RowImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .padding(.top, 60)
                    // Title and content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                            .padding(.horizontal)
                        ScrollView {
                            Text(item.htmlContent.strippingHTML())
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .frame(maxHeight: 200)
                        .scrollIndicators(.visible)
                    }
                    .padding(.top, 12)
                    
                    // Save my place toggle
                    if let enclosureUrl = item.enclosureUrl, URL(string: enclosureUrl) != nil {
                        VStack(spacing: 12) {
                            // Save my place toggle
                            Toggle(isOn: $saveMyPlace) {
                                Text("Save my place")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            .padding()
                            .background(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.8))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(1.9), radius: 5, x: 0, y: 2)
                            .accentColor(colorScheme == .dark ? .white : .black)
                            .onChange(of: saveMyPlace) { newValue in
                                guard let episodeID = episodeID else { return }
                                DispatchQueue.main.async {
                                    if newValue {
                                        // Save current position
                                        PlaybackPositionManager.shared.savePosition(for: episodeID, position: playerState.currentTime)
                                    } else {
                                        PlaybackPositionManager.shared.removePosition(for: episodeID)
                                    }
                                }
                            }
                            
                            // AirPlay button
                            AirPlayButtonView()
                                .frame(width: 60, height: 60)
                                .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                                .cornerRadius(30)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            // Playback controls
                            HStack(spacing: 30) {
                                Button(action: rewindAudio) {
                                    Image(systemName: "gobackward.\(Int(rewindInterval))")
                                        .imageScale(.large)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: 44, height: 44)
                                        .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                                
                                Button(action: playOrPauseAudio) {
                                    Image(systemName: playerState.isPlaying ? "pause.fill" : "play.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.white)
                                        .frame(width: 64, height: 64)
                                        .background(Color.orange)
                                        .cornerRadius(32)
                                        .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                
                                Button(action: fastForwardAudio) {
                                    Image(systemName: "goforward.\(Int(fastForwardInterval))")
                                        .imageScale(.large)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: 44, height: 44)
                                        .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                                
                                Button(action: stopAudio) {
                                    Image(systemName: "stop.fill")
                                        .imageScale(.large)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: 44, height: 44)
                                        .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            // Progress slider
                            VStack(spacing: 8) {
                                CustomSlider(
                                    value: $playerState.sliderTime,
                                    range: 0...playerState.duration,
                                    onDragStart: { playerState.startDragging() },
                                    onDragEnd: { playerState.stopDragging() }
                                )
                                .padding(.horizontal)
                                
                                HStack {
                                    Text(formatTime(playerState.currentTime))
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                                    Spacer()
                                    Text(formatTime(playerState.duration))
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                            .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(colorScheme == .dark ? .black : .white))
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            logger.debug("DetailView: View appeared for item: \(item.id)")
            setupAudioPlayer()
            // Restore saved position if exists
            if let episodeID = episodeID {
                DispatchQueue.main.async {
                    if let saved = PlaybackPositionManager.shared.getPosition(for: episodeID) {
                        saveMyPlace = true
                        if !hasRestoredPosition {
                            playerState.seek(to: saved)
                            hasRestoredPosition = true
                        }
                    } else {
                        saveMyPlace = false
                    }
                }
            }
        }
        .onChange(of: playerState.currentTime) { newTime in
            if saveMyPlace, let episodeID = episodeID {
                DispatchQueue.main.async {
                    PlaybackPositionManager.shared.savePosition(for: episodeID, position: newTime)
                }
            }
        }
    }
    
    private func setupAudioPlayer() {
        logger.debug("DetailView: Setting up audio player")
        configureAudioSession()
        guard let enclosureUrl = item.enclosureUrl, let url = URL(string: enclosureUrl) else {
            logger.error("DetailView: Invalid URL")
            return
        }
        
        playerState.setupPlayer(url: url)
    }
    
    private func playOrPauseAudio() {
        if playerState.isPlaying {
            playerState.pause()
        } else {
            playerState.play()
        }
    }
    
    private func rewindAudio() {
        let newTime = max(playerState.currentTime - rewindInterval, 0)
        playerState.seek(to: newTime)
    }
    
    private func fastForwardAudio() {
        let newTime = min(playerState.currentTime + fastForwardInterval, playerState.duration)
        playerState.seek(to: newTime)
    }
    
    private func stopAudio() {
        playerState.stop()
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}

struct SearchableListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchableListView(
                items: [
                    RSSItem(
                        title: "Episode 1: The Beginning",
                        htmlContent: "This is a sample episode description with some content to show how it looks in the preview. We'll talk about interesting topics and share some amazing stories.",
                        enclosureUrl: "https://example.com/sample1.mp3"
                    ),
                    RSSItem(
                        title: "Episode 2: The Journey Continues",
                        htmlContent: "Another sample episode with a longer description to demonstrate how the text wraps and how the UI handles different content lengths.",
                        enclosureUrl: "https://example.com/sample2.mp3"
                    ),
                    RSSItem(
                        title: "Episode 3: The Final Chapter",
                        htmlContent: "A third sample episode to show how multiple items look in the list. This helps us visualize the spacing and layout of the list items.",
                        enclosureUrl: "https://example.com/sample3.mp3"
                    )
                ],
                searchText: .constant("")
            )
        }
    }
}

struct EpisodeRow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                EpisodeRow(
                    item: RSSItem(
                        title: "Sample Episode with a Long Title That Might Need to Wrap to Multiple Lines",
                        htmlContent: "This is a sample episode description with some content to show how it looks in the preview. We'll talk about interesting topics and share some amazing stories.",
                        enclosureUrl: "https://example.com/sample.mp3"
                    ),
                    selectedItemId: .constant(nil)
                )
            }
        }
    }
}

// Add this struct before ContentView
struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), height: 4)
                    .cornerRadius(2)
                
                // Thumb
                Circle()
                    .fill(colorScheme == .dark ? Color.orange : Color.black)
                    .frame(width: 24, height: 24)
                    .offset(x: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 12)
                    .shadow(radius: 2)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        onDragStart()
                        let newValue = range.lowerBound + Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound)
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        onDragEnd()
                    }
            )
        }
        .frame(height: 24)
    }
}
