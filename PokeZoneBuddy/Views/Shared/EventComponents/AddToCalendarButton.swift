//
//  AddToCalendarButton.swift
//  PokeZoneBuddy
//
//  Created by Claude on 03.10.2025.
//  Version 0.3 - Add to Calendar Button (macOS only)
//

import SwiftUI

#if os(macOS)

/// Button to add a Pokemon GO event to the user's calendar
/// Requires CalendarService to be in the environment
struct AddToCalendarButton: View {
    
    // MARK: - Properties
    
    let event: Event
    let city: FavoriteCity
    
    @Environment(CalendarService.self) private var calendarService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isAdding = false
    
    // MARK: - Body
    
    var body: some View {
        Button {
            Task {
                await addToCalendar()
            }
        } label: {
            Label(String(localized: "calendar.action.add"), systemImage: "calendar.badge.plus")
        }
        .disabled(isAdding)
        .alert(String(localized: "alert.error.title"), isPresented: $showError) {
            Button(String(localized: "common.ok")) { }
        } message: {
            Text(errorMessage)
        }
        .alert(String(localized: "alert.success.title"), isPresented: $showSuccess) {
            Button(String(localized: "common.ok")) { }
        } message: {
            Text(String(localized: "calendar.success"))
        }
        .help(String(localized: "calendar.action.add.help"))
    }
    
    // MARK: - Private Methods
    
    private func addToCalendar() async {
        isAdding = true
        defer { isAdding = false }
        
        do {
            try await calendarService.addEventToCalendar(event: event, city: city)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var calendarService = CalendarService()
    
    let event = Event(
        id: "test-event",
        name: "Community Day: Bulbasaur",
        eventType: "community-day",
        heading: "Community Day",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600 * 3),
        isGlobalTime: false
    )
    
    let city = FavoriteCity(
        name: "Tokyo",
        timeZoneIdentifier: "Asia/Tokyo",
        fullName: "Tokyo, Japan"
    )
    
    return AddToCalendarButton(event: event, city: city)
        .environment(calendarService)
        .padding()
}

#endif
