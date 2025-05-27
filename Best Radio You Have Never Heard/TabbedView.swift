//
//  TabbedView.swift
//  Best Radio You Have Never Heard
//
//  Created by Bill Skrzypczak on 12/26/23.
//

//
//  TabbedView.swift
//  SwiftUI Webview List
//
//  Created by Bill Skrzypczak on 11/28/23.
//

import SwiftUI

struct TabbedContentView: View {
    @StateObject private var favoritesManager = FavoritesManager()
    
    var body: some View {
        ZStack {
            // Background color black
            Color.black.edgesIgnoringSafeArea(.all)

            // TabView for Show and Favorites
            TabView {
                ContentView()
                    .environmentObject(favoritesManager)
                    .tabItem {
                        Label("Shows", systemImage: "antenna.radiowaves.left.and.right")
                    }
                
                FavoritesView()
                    .environmentObject(favoritesManager)
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
            }
        }
    }
}

// Preview with FavoritesManager
struct TabbedContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabbedContentView()
    }
}
