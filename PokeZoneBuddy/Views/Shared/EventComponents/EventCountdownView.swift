//
//  EventCountdownView.swift
//  PokeZoneBuddy
//
//  Live Countdown für Events
//  Version 0.2
//

import SwiftUI
import Combine

/// Zeigt einen Live-Countdown für Events
struct EventCountdownView: View {
    let event: Event
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Group {
            if event.isCurrentlyActive {
                activeEventView
            } else if event.isUpcoming {
                upcomingEventView
            } else {
                pastEventView
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Active Event
    
    private var activeEventView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.systemGreen)
                    .frame(width: 8, height: 8)
                    .shimmer()

                Text(String(localized: "countdown.live_now"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.systemGreen)
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "countdown.time_remaining"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(timeRemainingText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.08))
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.65))
                            .frame(width: geometry.size.width * event.eventProgress)
                            .animation(.linear(duration: 0.5), value: event.eventProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
    
    // MARK: - Upcoming Event
    
    private var upcomingEventView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status Badge
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(String(localized: "countdown.starting_soon"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            
            // Countdown
            HStack {
                Text(String(localized: "countdown.countdown"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(countdownText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
    
    // MARK: - Past Event
    
    private var pastEventView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            Text(String(localized: "countdown.event_ended"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
    
    // MARK: - Computed Properties
    
    private var timeRemainingText: String {
        let timeInterval = event.actualEndTime.timeIntervalSince(currentTime)
        
        guard timeInterval > 0 else {
            return String(localized: "countdown.ending_soon")
        }
        
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private var countdownText: String {
        let timeInterval = event.actualStartTime.timeIntervalSince(currentTime)
        
        guard timeInterval > 0 else {
            return String(localized: "countdown.starting_soon.short")
        }
        
        let days = Int(timeInterval / 86400)
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return String(format: "%dd %dh %dm", days, hours, minutes)
        } else if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: String(localized: "countdown.minutes_format"), minutes)
        } else {
            return String(localized: "countdown.less_than_minute")
        }
    }
}

// MARK: - Compact Countdown Badge

/// Kompakte Countdown-Anzeige für Event-Listen
struct CompactCountdownBadge: View {
    let event: Event
    
    var body: some View {
        Group {
            if event.isCurrentlyActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.systemGreen)
                        .frame(width: 6, height: 6)
                    Text(String(localized: "badge.live"))
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.systemGreen.opacity(0.15))
                )
                .foregroundStyle(Color.systemGreen)
            } else if event.isUpcoming, let countdown = event.countdownText {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                    Text(countdown)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.systemOrange.opacity(0.15))
                )
                .foregroundStyle(Color.systemOrange)
                .monospacedDigit()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Active Event
        EventCountdownView(
            event: Event(
                id: "test-active",
                name: "Test Event",
                eventType: "community-day",
                heading: "Community Day",
                startTime: Date().addingTimeInterval(-1800), // 30 min ago
                endTime: Date().addingTimeInterval(1800), // 30 min from now
                isGlobalTime: false
            )
        )
        
        // Upcoming Event
        EventCountdownView(
            event: Event(
                id: "test-upcoming",
                name: "Test Event",
                eventType: "raid-hour",
                heading: "Raid Hour",
                startTime: Date().addingTimeInterval(3600), // 1 hour from now
                endTime: Date().addingTimeInterval(7200),
                isGlobalTime: false
            )
        )
        
        // Past Event
        EventCountdownView(
            event: Event(
                id: "test-past",
                name: "Test Event",
                eventType: "spotlight-hour",
                heading: "Spotlight Hour",
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-3600), // 1 hour ago
                isGlobalTime: false
            )
        )
    }
    .padding()
    .frame(width: 400)
}
