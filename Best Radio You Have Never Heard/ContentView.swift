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

struct ContentView: View {
    
    
    
    // @State private variables
    @State private var items: [RSSItem] = []
    @State private var searchText = ""
    @State private var playbackPosition: TimeInterval? = nil
    
    
    // Method to search the main and detailed views
    var filteredItems: [RSSItem] {
        searchText.isEmpty ? items : items.filter { $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.htmlContent.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Main navigation view
    var body: some View {
        
        
        NavigationView {
            if #available(iOS 15.0, *) {
                List(filteredItems, id: \.id) { item in // Display items searched on
                    
                    
                    // Put a logo on each row
                    NavigationLink(destination: DetailView(item: item, playbackPosition: $playbackPosition)) { // Updated
                        HStack {
                            Image("RowImage")
                                .resizable()
                                .frame(width: 90, height: 100)
                            
                            // put the search results in this Vstack
                            VStack(alignment: .leading) {
                                if !searchText.isEmpty {
                                    Text("Search Results: \(filteredItems.count)")
                                        .padding()
                                        .foregroundColor(.gray)
                                }
                                Text(item.title)
                                    .padding([.top, .bottom], 10)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .background(Color.black)
                                
                                // Place an orange underline below each episode
                                Rectangle()
                                    .frame(height: 8)
                                    .foregroundColor(.orange)
                                    .edgesIgnoringSafeArea(.horizontal)
                            }
                            
                            
                        }.background(Color.black.edgesIgnoringSafeArea(.all))
                            .padding(.vertical, -9)
                            .padding(.horizontal, -9)
                        
                    } //<-----
                    
                }
                .searchable(text: $searchText)
                
                .onAppear {
                    fetchRSSFeed()
                    
                }
                
            } else {
                
                // Fallback for earlier versions
                
            }
            
            
        }
        
    }
    
    // Func to fetch RSS feed
    func fetchRSSFeed() {
        if let url = URL(string: "https://www.bestradioyouhaveneverheard.com/podcasts/index.xml") {
            URLSession.shared.dataTask(with: url) {  data, _, error in
                if let data = data {
                    DispatchQueue.main.async {
                        self.parseRSS(data: data)
                    }
                } else if let error = error {
                    print("Error fetching RSS feed: \(error.localizedDescription)")
                }
            }.resume()
        }
    }
    
    // Func to parse RSS feed
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

//---------------------------------------------------------------]
// Main Content View Custom attributes and behaviours
//---------------------------------------------------------------]

// Class definition for RSS parser delegate
class RSSParserDelegate: NSObject, XMLParserDelegate {
    var currentItem: RSSItem?
    var currentElement: String = ""
    var currentAttributes: [String: String] = [:]
    var items: [RSSItem] = []
    
    
    // Function to parse RSS feed items
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentItem = RSSItem(title: "", htmlContent: "", enclosureUrl: nil)
        } else if elementName == "enclosure" {
            currentAttributes = attributeDict
        }
    }
    
    // Func to cleanup RSS feed
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
    
    // Func to grab Enclosure mp3 item
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

// Data structure to display main Content View
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Data structure for RSS items
struct RSSItem: Identifiable {
    let id = UUID()
    var title: String
    var htmlContent: String
    var enclosureUrl: String?
    var isFavorite: Bool = false
}

//---------------------------------------------------------------]
//
// Detail View attributes and behaviours
//
//---------------------------------------------------------------]

struct DetailView: View {
    
    // Define an attribute to store the selected item
    struct ListItem {
        let id: UUID
        let name: String
        
        // Initialize that attribute
        init(name: String) {
            self.id = UUID()
            self.name = name
        }
    }
    
    // Define the main attributes
    var item: RSSItem
    @State private var albumArt: UIImage? // Drop the show image in here
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    @State private var imageData: Data?
    @State private var volume: Float = 0.5 // Initialize the volume to 50%
    @Binding var playbackPosition: TimeInterval? // Store your playback position here
    
    // Define attributes for audio progress slider
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0.0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var sliderValue: Double = 0
    @State private var lastPlaybackPosition: TimeInterval?
    @State private var autoPlay = true
    
    // Define attributes for RW & FF intervals
    let rewindInterval: TimeInterval = 15 // seconds
    let fastForwardInterval: TimeInterval = 15 // seconds
    
    // A place to store the Episode
    @State private var inepisode = ""
    @State private var outepisode = ""
    @State private var savePlaybackPosition = true // Toggle Switch to (enabled)
    
   
    // Define the Main Detail View
    var body: some View {
        
        
        ZStack{
            
           
            
            // Display the album art as the background
            if let albumArt = albumArt {
                Image(uiImage: albumArt)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
            }
            
           
            
            // Place the songlist text on top
            VStack {
                             
                // Convert HTML to text
                ScrollView {
                    Text(item.htmlContent.strippingHTML())
                        .padding(.horizontal, 45)
                        .frame(width: 400, height: 550)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                    
                }
               
                
           
                
                // If the MP3 file is not nil load it in the player
                if let enclosureUrl = item.enclosureUrl, URL(string: enclosureUrl) != nil {
                    audioPlayerControls
                }
                
                
            }
            
            
            
            
            .onAppear {
                // Fire up the audio player
                setupAudioPlayer()
                if let url = URL(string: item.enclosureUrl!) {
                    albumArt = fetchAlbumArt(from: url)
                }
                
                // Get the last episode played only if the toggle switch is enabled
                 if savePlaybackPosition && outepisode == item.title {
                     // Seek to the last playback position if available
                     if let lastPosition = playbackPosition {
                         seekToTime(lastPosition)
                         audioPlayer?.play()
                     } else {
                         playbackPosition = 0.0
                     }
                 }
             }

            .onDisappear {
                // Save the current playback position only if the toggle switch is enabled
                if savePlaybackPosition {
                    // Save the current list item
                    outepisode = item.title
                    if let currentTime = audioPlayer?.currentTime().seconds {
                        playbackPosition = currentTime
                        UserDefaults.standard.set(currentTime, forKey: "lastPlaybackPosition")
                        playOrPauseAudio()
                        
                    } else {outepisode = ""}
                }
                
                
            }
            
            
            .onReceive(timer) { _ in
                if audioPlayer?.timeControlStatus != .paused {
                    currentTime = audioPlayer?.currentTime().seconds ?? 0
                }
            }
            
        }
        
    }
    
    // This computed property creates a background view with the album art
    private var albumArtBackground: some View {
        Group {
            if let albumArt = albumArt {
                Image(uiImage: albumArt)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black // Fallback color
            }
        }
    }
    
    // Function to seek to a specific time
    private func seekToTime(_ time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let timeCM = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: timeCM)
    }
    
    // Make all the audio player and airplay buttons
    private var audioPlayerControls: some View {
        
        ZStack {
            
            
            VStack {
                
                // Make the AirPlay button
                VStack {
                    //Spacer() // Pushes everything below to the bottom
                    
                    AirPlayButtonView()
                        .frame(width: 65, height: 65)
                    //.padding()
                        .background(Color.black.opacity(0.6))
                    
                }
                
                // Make the Audio PLayer buttons
                HStack (spacing: 50){
                    
                    
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
                
                // Insert slider into audio player controls
                Slider(value: $currentTime, in: 0...duration, onEditingChanged: sliderEditingChanged)
                
                    .frame(width: 330)
                    .accentColor(.blue)
                    .background(Color.black.opacity(0.6))
                
                // Toggle bookmark
                Toggle(isOn: $savePlaybackPosition, label: {
                    Text("Save Position (\(playbackPosition != nil ? String(format: "%.2f", playbackPosition!) : "N/A") seconds)")
                        .foregroundColor(.white) // Set the text color to white
                })
                .frame(width: 330)
                .accentColor(.blue)
                .background(Color.black.opacity(0.6))
                
                
            }// EO HStack
            
            
        }// EO VStack
        
        
    }// EO Zstack
    
    // Slider value change handler
    private func sliderEditingChanged(editingStarted: Bool) {
        if !editingStarted {
            //playbackPosition = currentTime
            seekToTime(currentTime)
        }
    }
    
    // Setup the audio player
    private func setupAudioPlayer() {
        // Allow audio player in background mode
        configureAudioSession()
        // Grab the url of the MP3
        guard let enclosureUrl = item.enclosureUrl, let url = URL(string: enclosureUrl) else {
            print("Invalid URL")
            return
        }
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        
        // Set the initial volume
        audioPlayer?.volume = Float(volume)
        
        // Calculate the total duration of the audio
        if let durationCMTime = audioPlayer?.currentItem?.asset.duration {
            duration = CMTimeGetSeconds(durationCMTime)
        }
        
    }
    
    // Pause
    private func playOrPauseAudio() {
        guard let player = audioPlayer else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    // Rewind
    private func rewindAudio() {
        guard let player = audioPlayer else { return }
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = playerCurrentTime - rewindInterval
        newTime = max(newTime, 0)
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        player.seek(to: time)
    }
    
    // Fast Forward
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
    
    // Stop
    private func stopAudio() {
        audioPlayer?.pause()
        let time: CMTime = CMTimeMake(value: 0, timescale: 1)
        audioPlayer?.seek(to: time)
        isPlaying = false
    }
    
}// End of Detail View

//---------------------------------------------------------------]
// Detail View Custom attributes and behaviours
//---------------------------------------------------------------]

// Define the Attributes and Behaviours of the Airplay Button
struct AirPlayButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.activeTintColor = .blue
        routePickerView.tintColor = .blue
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// Define the Attributes and Behaviours to convert the HTML songlist to text
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

// Setup the audio session
private func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print("Failed to set audio session category. Error: \(error)")
    }
}

// Grab the Album Art from the MP3 metadata
func fetchAlbumArt(from url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let metadata = asset.commonMetadata
    
    if let artworkData = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork).first?.dataValue {
        return UIImage(data: artworkData)
    }
    
    return nil
}












