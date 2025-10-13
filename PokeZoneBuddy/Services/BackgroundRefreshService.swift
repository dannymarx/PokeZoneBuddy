//
//  BackgroundRefreshService.swift
//  PokeZoneBuddy
//
//  Background refresh service for automatic event updates
//  Version 0.4 - Singleton Pattern
//

import Foundation

/// Manages automatic background refresh of events
/// Triggers periodic updates when network is available
/// Implemented as Singleton for app-wide access
final class BackgroundRefreshService {
    
    // MARK: - Singleton
    
    static let shared = BackgroundRefreshService()
    private init() {}
    
    // MARK: - Properties
    
    /// Indicates if refresh is currently in progress
    private(set) var isRefreshing = false
    
    /// Timestamp of last successful refresh
    private(set) var lastRefreshDate: Date?
    
    // MARK: - Private Properties
    
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 30 * 60 // 30 minutes
    
    private var networkMonitor: NetworkMonitor?
    private var onRefresh: (@Sendable () async -> Void)?
    
    // MARK: - Public Methods
    
    /// Configure the service with required dependencies
    func configure(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }
    
    /// Start automatic background refresh
    func startAutoRefresh(onRefresh: @escaping @Sendable () async -> Void) {
        self.onRefresh = onRefresh
        
        // Cancel existing timer
        refreshTimer?.invalidate()
        
        // Create new timer
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: self.refreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task {
                await self?.performRefresh()
            }
        }
        
        AppLogger.background.info("Background refresh started (every \(Int(self.refreshInterval / 60)) minutes)")
    }
    
    /// Stop automatic refresh
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        AppLogger.background.info("Background refresh stopped")
    }
    
    /// Perform manual refresh
    func performRefresh() async {
        guard !isRefreshing else {
            AppLogger.background.debug("Refresh already in progress")
            return
        }
        
        guard let networkMonitor = networkMonitor, networkMonitor.shouldSync else {
            AppLogger.background.debug("Skipping refresh: network unavailable or constrained")
            return
        }
        
        isRefreshing = true
        defer { isRefreshing = false }

        await onRefresh?()
        lastRefreshDate = Date()

        // Clean up expired notifications and temporary images after refresh
        await NotificationManager.shared.cleanupExpiredNotifications()
        NotificationImageService.shared.cleanupTemporaryImages()

        AppLogger.background.info("Background refresh completed")
    }
}
