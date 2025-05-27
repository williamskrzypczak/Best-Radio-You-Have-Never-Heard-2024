import Foundation
import SwiftUI
import AVKit

// Audio Position Manager
class AudioPositionManager: ObservableObject {
    private let positionsKey = "audioPositions"
    private var positions: [UUID: Double] = [:]
    
    init() {
        loadPositions()
    }
    
    private func loadPositions() {
        if let data = UserDefaults.standard.data(forKey: positionsKey),
           let positions = try? JSONDecoder().decode([UUID: Double].self, from: data) {
            self.positions = positions
        }
    }
    
    private func savePositions() {
        if let data = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(data, forKey: positionsKey)
        }
    }
    
    func getPosition(for id: UUID) -> Double {
        return positions[id] ?? 0
    }
    
    func savePosition(_ position: Double, for id: UUID) {
        positions[id] = position
        savePositions()
    }
    
    func clearPosition(for id: UUID) {
        positions.removeValue(forKey: id)
        savePositions()
    }
}

// RSS Model
struct RSSItem: Identifiable {
    let id = UUID()
    var title: String
    var htmlContent: String
    var enclosureUrl: String?
    
    init(title: String, htmlContent: String, enclosureUrl: String?) {
        self.title = title
        // Clean the content by removing "Best Radio You Have Never Heard" and any extra whitespace
        self.htmlContent = htmlContent
            .replacingOccurrences(of: "Best Radio You Have Never Heard", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.enclosureUrl = enclosureUrl
    }
}

// RSS Parser
class RSSParserDelegate: NSObject, XMLParserDelegate {
    var currentItem: RSSItem?
    var currentElement: String = ""
    var currentAttributes: [String: String] = [:]
    var items: [RSSItem] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentItem = RSSItem(title: "", htmlContent: "", enclosureUrl: nil)
        } else if elementName == "enclosure" {
            currentAttributes = attributeDict
        }
    }
    
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

// RSS Service
class RSSService {
    static func fetchRSSFeed(completion: @escaping ([RSSItem]?, Error?) -> Void) {
        guard let url = URL(string: "https://www.bestradioyouhaveneverheard.com/podcasts/index.xml") else {
            completion(nil, NSError(domain: "RSSService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "RSSService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            let parser = XMLParser(data: data)
            let rssParserDelegate = RSSParserDelegate()
            parser.delegate = rssParserDelegate
            
            if parser.parse() {
                completion(rssParserDelegate.items, nil)
            } else {
                completion(nil, NSError(domain: "RSSService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse RSS feed"]))
            }
        }.resume()
    }
} 