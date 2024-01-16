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

//---------------------------------------------------------------]
//
// Main Tabbed View attributes and behaviours
//
//---------------------------------------------------------------]
struct TabbedContentView: View {
    var body: some View {
        ZStack {
            // Background color black
            Color.black.edgesIgnoringSafeArea(.all)

            // TabView for Show
            TabView {
                ContentView()
                    .tabItem {
                        Label("Shows", systemImage: "antenna.radiowaves.left.and.right")
                    }
            }
        }
    }
}

// Main Tabbed View
struct TabbedView_Previews: PreviewProvider {
    static var previews: some View {
        TabbedContentView()
    }
}
