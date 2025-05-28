import UIKit
import SwiftUI
import MediaPlayer
import AVFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let contentView = ContentView()
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
            
            // Configure audio session for CarPlay
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set audio session category: \(error.localizedDescription)")
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        if scene is CPTemplateApplicationScene {
            carPlaySceneDelegate = nil
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Ensure audio session is active when app becomes active
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Keep audio session active when app resigns active
        try? AVAudioSession.sharedInstance().setActive(true)
    }
} 