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
    private var lastLoggedStatus: (connected: Bool, type: String?) = (false, nil)
    
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
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = nil
                }

                // Only log if status actually changed
                let connected = self.isConnected
                let typeString = String(describing: self.connectionType)

                if lastLoggedStatus.connected != connected || lastLoggedStatus.type != typeString {
                    AppLogger.network.info("Network status: connected=\(connected), type=\(typeString)")
                    self.lastLoggedStatus = (connected, typeString)
                }
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

