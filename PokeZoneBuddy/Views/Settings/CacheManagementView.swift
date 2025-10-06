//
//  CacheManagementView.swift
//  PokeZoneBuddy
//
//  Settings view for cache management
//  Version 0.4 - Modern UI Design
//

import SwiftUI
import SwiftData

/// View for managing app cache and data
struct CacheManagementView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var eventCount = 0
    @State private var imageMemorySize = 0
    @State private var diskCacheSize = 0
    @State private var showClearConfirmation = false
    @State private var showDeleteOldConfirmation = false
    @State private var isRefreshing = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        cacheStatisticsSection
                        cacheActionsSection
                    }
                    .padding(24)
                }
            }
            .background(.windowBackground)
            .navigationTitle(String(localized: "cache.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                    .buttonStyle(ModernButtonStyle())
                }
            }
            .onAppear {
                updateCacheStats()
            }
            .confirmationDialog(
                String(localized: "cache.confirm.clear_images.title"),
                isPresented: $showClearConfirmation
            ) {
                Button(String(localized: "common.clear"), role: .destructive) {
                    Task {
                        await clearImageCache()
                    }
                }
                Button(String(localized: "common.cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "cache.confirm.clear_images.message"))
            }
            .confirmationDialog(
                String(localized: "cache.confirm.delete_old.title"),
                isPresented: $showDeleteOldConfirmation
            ) {
                Button(String(localized: "common.delete"), role: .destructive) {
                    deleteOldEvents()
                }
                Button(String(localized: "common.cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "cache.confirm.delete_old.message"))
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "cache.title"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text(String(localized: "cache.subtitle"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(24)
    }
    
    // MARK: - Cache Statistics Section
    
    private var cacheStatisticsSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Label(String(localized: "cache.stats.title"), systemImage: "chart.bar.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Stats Cards
            VStack(spacing: 12) {
                StatCard(
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    title: String(localized: "cache.stats.events.title"),
                    value: "\(eventCount)",
                    subtitle: String(localized: "cache.stats.events.subtitle")
                )
                
                StatCard(
                    icon: "photo.stack",
                    iconColor: .green,
                    title: String(localized: "cache.stats.image_memory.title"),
                    value: formatBytes(imageMemorySize),
                    subtitle: String(localized: "cache.stats.image_memory.subtitle")
                )
                
                StatCard(
                    icon: "internaldrive",
                    iconColor: .orange,
                    title: String(localized: "cache.stats.disk.title"),
                    value: formatBytes(diskCacheSize),
                    subtitle: String(localized: "cache.stats.disk.subtitle")
                )
            }
        }
    }
    
    // MARK: - Cache Actions Section
    
    private var cacheActionsSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Label(String(localized: "cache.actions.title"), systemImage: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Action Cards
            VStack(spacing: 12) {
                ActionCard(
                    icon: "photo.badge.arrow.down",
                    iconColor: .blue,
                    title: String(localized: "cache.actions.clear_images.title"),
                    subtitle: String(localized: "cache.actions.clear_images.subtitle"),
                    buttonText: String(localized: "common.clear"),
                    buttonColor: .blue
                ) {
                    showClearConfirmation = true
                }
                
                ActionCard(
                    icon: "calendar.badge.minus",
                    iconColor: .red,
                    title: String(localized: "cache.actions.delete_old.title"),
                    subtitle: String(localized: "cache.actions.delete_old.subtitle"),
                    buttonText: String(localized: "common.delete"),
                    buttonColor: .red
                ) {
                    showDeleteOldConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func updateCacheStats() {
        isRefreshing = true
        
        let service = CacheManagementService(modelContext: modelContext)
        let stats = service.getCacheSize()
        
        eventCount = stats.events
        imageMemorySize = 0
        diskCacheSize = stats.imageDisk
        
        isRefreshing = false
    }
    
    private func clearImageCache() async {
        let service = CacheManagementService(modelContext: modelContext)
        await service.clearImageCache()
        updateCacheStats()
    }
    
    private func deleteOldEvents() {
        let service = CacheManagementService(modelContext: modelContext)
        
        do {
            try service.deleteOldEvents()
            updateCacheStats()
        } catch {
            AppLogger.cache.error("Error deleting old events: \(String(describing: error))")
        }
    }
    
    // MARK: - Helpers
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Action Card

private struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action Button
            Button {
                action()
            } label: {
                Text(buttonText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(buttonColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isHovering ? buttonColor.opacity(0.15) : buttonColor.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(buttonColor.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Preview

#Preview {
    CacheManagementView()
        .modelContainer(for: Event.self, inMemory: true)
}

