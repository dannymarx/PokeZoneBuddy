//
//  ContextualTips.swift
//  PokeZoneBuddy
//
//  Created by Codex on 21.10.25.
//

import SwiftUI
import TipKit

struct PlannerTemplateTip: Tip {
    static let planSavedEvent = Tips.Event(id: "tips.planner.planSaved")

    var id: String { "tips.planner.templates" }

    var title: Text {
        Text("tips.planner.title")
    }

    var message: Text? {
        Text("tips.planner.message")
    }

    var image: Image? {
        Image(systemName: "square.stack.3d.up")
    }

    var rules: [Rule] {
        #Rule(Self.planSavedEvent) { event in
            event.donations.count > 0 && event.donations.count <= 2
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(2)
        Tips.IgnoresDisplayFrequency(true)
    }
}

struct EventFiltersTip: Tip {
    static let filtersUsedEvent = Tips.Event(id: "tips.events.filtersUsed")

    var id: String { "tips.events.filters" }

    var title: Text {
        Text("tips.filters.title")
    }

    var message: Text? {
        Text("tips.filters.message")
    }

    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease.circle")
    }

    var rules: [Rule] {
        #Rule(Self.filtersUsedEvent) { event in
            event.donations.count > 0 && event.donations.count <= 3
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(2)
    }
}

struct TimelineExportTip: Tip {
    static let exportEvent = Tips.Event(id: "tips.timeline.exported")

    var id: String { "tips.timeline.export" }

    var title: Text {
        Text("tips.export.title")
    }

    var message: Text? {
        Text("tips.export.message")
    }

    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }

    var rules: [Rule] {
        #Rule(Self.exportEvent) { event in
            event.donations.count > 0 && event.donations.count <= 2
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(2)
        Tips.IgnoresDisplayFrequency(true)
    }
}
