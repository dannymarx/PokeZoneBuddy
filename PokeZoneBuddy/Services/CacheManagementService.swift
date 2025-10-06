//
//  CacheManagementService.swift
//  PokeZoneBuddy
//
//  Service for managing cache data and cleanup
//  Version 0.4
//

import Foundation
import SwiftData

/// Manages cache operations including statistics and cleanup
final class CacheManagementService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Cache Statistics
    
    /// Calculate total cache size
    func getCacheSize() -> (events: Int, imageMemory: Int, imageDisk: Int) {
        var eventCount = 0
        
        // Count events in SwiftData
        let descriptor = FetchDescriptor<Event>()
        eventCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        return (
            events: eventCount,
            imageMemory: 0,
            imageDisk: getDiskCacheSize()
        )
    }
    
    // MARK: - Cache Cleanup
    
    /// Clear image cache
    func clearImageCache() async {
        // Clear URLCache only (AsyncImage uses URLSession/URLCache)
        URLCache.shared.removeAllCachedResponses()
        AppLogger.cache.info("Image cache cleared")
    }
    
    /// Delete old events (older than 30 days)
    func deleteOldEvents() throws {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { event in
                event.endTime < thirtyDaysAgo
            }
        )
        
        let oldEvents = try modelContext.fetch(descriptor)
        
        for event in oldEvents {
            modelContext.delete(event)
        }
        
        try modelContext.save()
        
        AppLogger.cache.info("Deleted \(oldEvents.count) old events")
    }
    
    // MARK: - Private Methods
    
    /// Get disk cache size
    private func getDiskCacheSize() -> Int {
        guard let cacheURL = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            return 0
        }
        
        do {
            let resourceKeys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
            guard let enumerator = FileManager.default.enumerator(
                at: cacheURL,
                includingPropertiesForKeys: resourceKeys,
                options: []
            ) else {
                return 0
            }
            
            var totalSize = 0
            
            while let fileURL = enumerator.nextObject() as? URL {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                
                if resourceValues.isDirectory == false {
                    totalSize += resourceValues.fileSize ?? 0
                }
            }
            
            return totalSize
            
        } catch {
            AppLogger.cache.error("Error calculating cache size: \(error)")
            return 0
        }
    }
}

