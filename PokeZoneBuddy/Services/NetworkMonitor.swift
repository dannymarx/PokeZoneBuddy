//
//  NetworkMonitor.swift
//  PokeZoneBuddy
//
//  Network connectivity monitoring service
//  Version 0.4 - Offline Mode Support
//

import Network
import Foundation
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    
    // MARK: - Properties
    
    /// Indicates if device is connected to internet
    private(set) var isConnected = false
    
    /// Indicates if connection is expensive (cellular data)
    private(set) var isExpensive = false
    
    /// Indicates if connection is constrained (low data mode)
    private(set) var isConstrained = false
    
    /// Current connection type (wifi, cellular, ethernet)
    private(set) var connectionType: NWInterface.InterfaceType?
    
    // MARK: - Private Properties
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Initialization
    
    init() {
        setupMonitoring()
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    // MARK: - Setup
    
    private func setupMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = nil
                }
                
                let connected = self?.isConnected ?? false
                let type = String(describing: self?.connectionType)
                AppLogger.network.info("Network status: connected=\(connected), type=\(type)")
            }
        }
        
        pathMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Public Methods
    
    /// OFFLINE: Should sync now?
    var shouldSync: Bool {
        return isConnected && !isConstrained
    }
    
    /// OFFLINE: Should download images?
    var shouldDownloadImages: Bool {
        return isConnected && !isExpensive && !isConstrained
    }
}

