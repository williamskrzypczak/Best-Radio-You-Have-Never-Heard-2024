struct DetailView: View {
    // ... existing properties ...
    
    var body: some View {
        ZStack {
            // Background image
            if let albumArt = albumArt {
                Image(uiImage: albumArt)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 10) // Add blur to make text more readable
            }
            
            // Main content
            VStack(spacing: 20) {
                // Song list with scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Text(item.htmlContent.strippingHTML())
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                    .padding(.vertical)
                }
                .frame(maxHeight: .infinity)
                
                // Audio controls
                if let enclosureUrl = item.enclosureUrl, URL(string: enclosureUrl) != nil {
                    VStack(spacing: 16) {
                        // AirPlay button
                        AirPlayButtonView()
                            .frame(width: 65, height: 65)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                        
                        // Playback controls
                        HStack(spacing: 30) {
                            Button(action: rewindAudio) {
                                Image(systemName: "gobackward.\(Int(rewindInterval))")
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: playOrPauseAudio) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: fastForwardAudio) {
                                Image(systemName: "goforward.\(Int(fastForwardInterval))")
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: stopAudio) {
                                Image(systemName: "stop.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        
                        // Progress slider
                        VStack {
                            Slider(value: $currentTime, in: 0...duration, onEditingChanged: sliderEditingChanged)
                                .accentColor(.orange)
                            
                            HStack {
                                Text(formatTime(currentTime))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(formatTime(duration))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                // Settings toggles
                VStack(spacing: 12) {
                    Toggle("Remember Playback Position", isOn: $savePlaybackPosition)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .onChange(of: savePlaybackPosition) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "savePlaybackPositionEnabled")
                        }
                    
                    Toggle("Save Location", isOn: $saveLocation)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .onChange(of: saveLocation) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "saveLocationEnabled")
                        }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
        }
        .onAppear {
            setupAudioPlayer()
            if let url = URL(string: item.enclosureUrl!) {
                albumArt = fetchAlbumArt(from: url)
            }
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
    
    // ... rest of the existing methods ...
} 