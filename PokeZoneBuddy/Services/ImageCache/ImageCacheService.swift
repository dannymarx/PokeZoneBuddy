//
//  ImageCacheService.swift
//  PokeZoneBuddy
//
//  Image-Caching für Event- und Pokemon-Bilder
//  Version 0.2
//

import SwiftUI

/// Service zum Cachen von heruntergeladenen Bildern
/// Verhindert unnötige Netzwerk-Requests und verbessert Performance
actor ImageCacheService {
    
    // MARK: - Singleton
    
    static let shared = ImageCacheService()
    
    // MARK: - Properties
    
    /// In-Memory Cache für schnellen Zugriff
    private var memoryCache: [URL: CachedImage] = [:]
    
    /// Maximale Anzahl an Bildern im Memory Cache
    private let maxMemoryCacheSize = 100
    
    /// Cache-Dauer in Sekunden (24 Stunden)
    private let cacheDuration: TimeInterval = 86400
    
    // MARK: - Cache Management
    
    /// Lädt ein Bild von URL mit Caching
    /// - Parameter url: URL des Bildes
    /// - Returns: UIImage/NSImage wenn erfolgreich
    func loadImage(from url: URL) async throws -> PlatformImage {
        // 1. Prüfe Memory Cache
        if let cachedImage = getCachedImage(for: url) {
            return cachedImage
        }
        
        // 2. Lade von URL
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 3. Validiere Response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImageCacheError.invalidResponse
        }
        
        // 4. Erstelle Image
        #if os(macOS)
        guard let image = NSImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }
        #else
        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }
        #endif
        
        // 5. Cache Image
        cacheImage(image, for: url)
        
        return image
    }
    
    /// Speichert ein Bild im Cache
    private func cacheImage(_ image: PlatformImage, for url: URL) {
        let cachedImage = CachedImage(
            image: image,
            timestamp: Date()
        )
        
        memoryCache[url] = cachedImage
        
        // Cleanup wenn Cache zu groß wird
        if memoryCache.count > maxMemoryCacheSize {
            cleanupOldestImages()
        }
    }
    
    /// Holt ein gecachtes Bild wenn verfügbar und nicht abgelaufen
    private func getCachedImage(for url: URL) -> PlatformImage? {
        guard let cachedImage = memoryCache[url] else {
            return nil
        }
        
        // Prüfe ob Cache noch gültig ist
        let age = Date().timeIntervalSince(cachedImage.timestamp)
        guard age < cacheDuration else {
            memoryCache.removeValue(forKey: url)
            return nil
        }
        
        return cachedImage.image
    }
    
    /// Entfernt die ältesten Bilder aus dem Cache
    private func cleanupOldestImages() {
        let sortedByAge = memoryCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let imagesToRemove = sortedByAge.prefix(maxMemoryCacheSize / 4) // Remove 25%
        
        for (url, _) in imagesToRemove {
            memoryCache.removeValue(forKey: url)
        }
    }
    
    /// Leert den kompletten Cache
    func clearCache() {
        memoryCache.removeAll()
    }
    
    /// Gibt Cache-Statistiken zurück
    func getCacheStats() -> CacheStats {
        return CacheStats(
            imageCount: memoryCache.count,
            memorySizeEstimate: memoryCache.count * 100 // Grobe Schätzung in KB
        )
    }
}

// MARK: - Supporting Types

/// Gecachtes Bild mit Timestamp
private struct CachedImage {
    let image: PlatformImage
    let timestamp: Date
}

/// Cache-Statistiken
struct CacheStats {
    let imageCount: Int
    let memorySizeEstimate: Int // in KB
}

/// Fehler beim Bild-Laden
enum ImageCacheError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidImageData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "image_error.invalid_url")
        case .invalidResponse:
            return String(localized: "image_error.invalid_response")
        case .invalidImageData:
            return String(localized: "image_error.invalid_image_data")
        case .networkError(let error):
            return String(format: String(localized: "image_error.network"), error.localizedDescription)
        }
    }
}

// MARK: - Platform Image Type Alias

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif
