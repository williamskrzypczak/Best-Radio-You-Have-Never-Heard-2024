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
    var body: some Scene {
        WindowGroup {
            
            TabbedContentView()
                .background(Color.black)
                .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}
