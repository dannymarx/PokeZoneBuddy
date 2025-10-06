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
        static let dataSource = "Event data from LeekDuck.com"
        
        /// ScrapedDuck-Credit
        static let scraper = "via ScrapedDuck by bigfoott"
        
        /// Vollständiger Credit-Text
        static let fullCredit = "\(dataSource)\n\(scraper)"
        
        /// LeekDuck URL
        static let leekDuckURL = "https://leekduck.com"
        
        /// ScrapedDuck GitHub URL
        static let scrapedDuckURL = "https://github.com/bigfoott/ScrapedDuck"
    }
    
    // MARK: - Legal / Copyright
    
    enum Legal {
        /// Pokemon Copyright Notice
        static let pokemonCopyright = "©2025 Pokémon. ©1995-2025 Nintendo/Creatures Inc./GAME FREAK inc."
        
        /// Pokemon Trademark Notice
        static let pokemonTrademark = "Pokémon and Pokémon character names are trademarks of Nintendo."
        
        /// App Disclaimer
        static let appDisclaimer = "PokeZoneBuddy is not affiliated with, endorsed, sponsored, or specifically approved by Nintendo, The Pokémon Company, or Niantic."
        
        /// Vollständiger Legal-Text für About-Screen
        static let fullLegalText = """
        \(pokemonCopyright)
        
        \(pokemonTrademark)
        
        \(appDisclaimer)
        
        All Pokémon images and names are property of their respective owners.
        """
        
        /// Kurzer Footer-Text
        static let footerText = "Pokémon © Nintendo/Creatures Inc./GAME FREAK inc."
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
        /// Wie lange Events im Cache bleiben (in seconds)
        static let eventCacheDuration: TimeInterval = 3600 // 1 hour
        
        /// Maximale Anzahl an Events im Cache
        static let maxCachedEvents = 100
    }
    
    // MARK: - Limits
    
    enum Limits {
        /// Maximum number of favorite cities
        static let maxFavoriteCities = 20
        
        /// Maximum number of search results
        static let maxSearchResults = 10
    }
}
