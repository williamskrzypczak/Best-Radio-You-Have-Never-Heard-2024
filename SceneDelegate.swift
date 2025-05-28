import UIKit
import SwiftUI
import MediaPlayer

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
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        if scene is CPTemplateApplicationScene {
            carPlaySceneDelegate = nil
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene is CPTemplateApplicationScene {
            carPlaySceneDelegate?.templateApplicationSceneDidBecomeActive(scene as! CPTemplateApplicationScene)
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if scene is CPTemplateApplicationScene {
            carPlaySceneDelegate?.templateApplicationSceneWillResignActive(scene as! CPTemplateApplicationScene)
        }
    }
} 