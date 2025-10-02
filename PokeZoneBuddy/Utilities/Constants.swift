//
//  Constants.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation

/// App-weite Konstanten und Konfiguration
enum Constants {
    
    // MARK: - API
    
    enum API {
        /// ScrapedDuck API Base URL
        static let baseURL = "https://raw.githubusercontent.com/bigfoott/ScrapedDuck/data/events.json"
        
        /// Timeout für API-Requests in Sekunden
        static let requestTimeout: TimeInterval = 30
        
        /// Maximale Anzahl an Retry-Versuchen
        static let maxRetries = 3
    }
    
    // MARK: - Credits
    
    enum Credits {
        /// Datenquelle-Credit
        static let dataSource = "Event-Daten von LeekDuck.com"
        
        /// ScrapedDuck-Credit
        static let scraper = "Via ScrapedDuck by bigfoott"
        
        /// Vollständiger Credit-Text
        static let fullCredit = "\(dataSource)\n\(scraper)"
        
        /// LeekDuck URL
        static let leekDuckURL = "https://leekduck.com"
        
        /// ScrapedDuck GitHub URL
        static let scrapedDuckURL = "https://github.com/bigfoott/ScrapedDuck"
    }
    
    // MARK: - UI
    
    enum UI {
        /// Standard-Padding
        static let defaultPadding: CGFloat = 16
        
        /// Corner Radius für Cards
        static let cornerRadius: CGFloat = 12
        
        #if os(macOS)
        /// Standard-Fenstergröße für macOS
        static let defaultWindowWidth: CGFloat = 1200
        static let defaultWindowHeight: CGFloat = 800
        #endif
    }
    
    // MARK: - Cache
    
    enum Cache {
        /// Wie lange Events im Cache bleiben (in Sekunden)
        static let eventCacheDuration: TimeInterval = 3600 // 1 Stunde
        
        /// Maximale Anzahl an Events im Cache
        static let maxCachedEvents = 100
    }
    
    // MARK: - Limits
    
    enum Limits {
        /// Maximale Anzahl an Lieblingsstädten
        static let maxFavoriteCities = 20
        
        /// Maximale Anzahl an Suchergebnissen
        static let maxSearchResults = 10
    }
}
