struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let rewindInterval: TimeInterval = 15
    let fastForwardInterval: TimeInterval = 15
    
    init(item: RSSItem) {
        _viewModel = StateObject(wrappedValue: DetailViewModel(item: item))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title and content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.item.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal)
                            .lineLimit(2)
                        
                        ScrollView {
                            Text(viewModel.item.htmlContent.strippingHTML())
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .frame(maxHeight: 150)
                        .scrollIndicators(.visible)
                    }
                    .padding(.top, 8)
                    
                    // Audio controls
                    if let enclosureUrl = viewModel.item.enclosureUrl, URL(string: enclosureUrl) != nil {
                        VStack(spacing: 20) {
                            // AirPlay button
                            AirPlayButtonView()
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(30)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            // Playback controls
                            HStack(spacing: 30) {
                                Button(action: { viewModel.rewind(by: rewindInterval) }) {
                                    Image(systemName: "gobackward.\(Int(rewindInterval))")
                                        .imageScale(.large)
                                        .foregroundColor(.black)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                                
                                Button(action: viewModel.playOrPause) {
                                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.white)
                                        .frame(width: 64, height: 64)
                                        .background(Color.orange)
                                        .cornerRadius(32)
                                        .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                
                                Button(action: { viewModel.fastForward(by: fastForwardInterval) }) {
                                    Image(systemName: "goforward.\(Int(fastForwardInterval))")
                                        .imageScale(.large)
                                        .foregroundColor(.black)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                                
                                Button(action: viewModel.stop) {
                                    Image(systemName: "stop.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.black)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Progress slider
                            VStack(spacing: 8) {
                                Slider(value: $viewModel.currentTime, in: 0...viewModel.duration, onEditingChanged: { editing in
                                    if !editing {
                                        viewModel.seekToTime(viewModel.currentTime)
                                    }
                                })
                                .accentColor(.orange)
                                .padding(.horizontal)
                                
                                HStack {
                                    Text(formatTime(viewModel.currentTime))
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(formatTime(viewModel.duration))
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.top)
        .task {
            // Setup audio player
            viewModel.setupAudioPlayer()
        }
        .onDisappear {
            viewModel.stop()
        }
        .onReceive(timer) { _ in
            viewModel.updateCurrentTime()
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
