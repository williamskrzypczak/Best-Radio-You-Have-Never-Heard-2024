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
import Foundation

// Import Foundation types
@_exported import struct Foundation.UUID
@_exported import class Foundation.NSObject
@_exported import protocol Foundation.XMLParserDelegate
@_exported import class Foundation.XMLParser

struct TabbedContentView: View {
    var body: some View {
        ZStack {
            // Background color black
            Color.black.edgesIgnoringSafeArea(.all)

            // TabView for Shows
            TabView {
                ContentView()
                    .tabItem {
                        Label("Shows", systemImage: "antenna.radiowaves.left.and.right")
                    }
            }
        }
    }
}

// Preview
struct TabbedContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabbedContentView()
    }
}
