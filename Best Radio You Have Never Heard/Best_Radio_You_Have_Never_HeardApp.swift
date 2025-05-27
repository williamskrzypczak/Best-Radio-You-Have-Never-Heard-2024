//
//  Best_Radio_You_Have_Never_HeardApp.swift
//  Best Radio You Have Never Heard
//
//  Created by Bill Skrzypczak on 12/26/23.
//

import SwiftUI

//---------------------------------------------------------------]
//
// Main View Launched
//
//---------------------------------------------------------------]
@main
struct Best_Radio_You_Have_Never_HeardApp: App {
    init() {
        // Force dark mode at launch
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.black)
                .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}
