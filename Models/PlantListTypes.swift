import SwiftUI

// Shared types for plant listing organization and filtering

struct PlantGroup: Identifiable {
    let id = UUID()
    let title: String?
    let plants: [Plant]
}

enum SortOption: String, CaseIterable {
    case dateAdded = "Date Added"
    case alphabetical = "Alphabetical"
    case healthStatus = "Health Status"
    case careNeeded = "Care Needed"
    case location = "Location"
    case wateringFrequency = "Watering Frequency"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .dateAdded: return "calendar"
        case .alphabetical: return "textformat.abc"
        case .healthStatus: return "heart"
        case .careNeeded: return "exclamationmark.triangle"
        case .location: return "location"
        case .wateringFrequency: return "drop"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .dateAdded: return "calendar.badge.checkmark"
        case .alphabetical: return "textformat.abc.dottedunderline"
        case .healthStatus: return "heart.fill"
        case .careNeeded: return "exclamationmark.triangle.fill"
        case .location: return "location.fill"
        case .wateringFrequency: return "drop.fill"
        }
    }
}

enum GroupOption: String, CaseIterable {
    case none = "None"
    case healthStatus = "Health Status"
    case location = "Location"
    case careNeeded = "Care Needed"
    case lightLevel = "Light Level"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "square.grid.2x2"
        case .healthStatus: return "heart"
        case .location: return "location"
        case .careNeeded: return "exclamationmark.triangle"
        case .lightLevel: return "sun.max"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .none: return "square.grid.2x2.fill"
        case .healthStatus: return "heart.fill"
        case .location: return "location.fill"
        case .careNeeded: return "exclamationmark.triangle.fill"
        case .lightLevel: return "sun.max.fill"
        }
    }
}

enum CareNeededFilter: String, CaseIterable {
    case needsWatering = "Needs Watering"
    case needsFertilizing = "Needs Fertilizing"
    case needsAnyCare = "Needs Any Care"
    case upToDate = "Up to Date"
    
    var icon: String {
        switch self {
        case .needsWatering: return "drop.fill"
        case .needsFertilizing: return "leaf.arrow.circlepath"
        case .needsAnyCare: return "exclamationmark.triangle"
        case .upToDate: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .needsWatering: return BotanicaTheme.Colors.waterBlue
        case .needsFertilizing: return BotanicaTheme.Colors.leafGreen
        case .needsAnyCare: return BotanicaTheme.Colors.error
        case .upToDate: return BotanicaTheme.Colors.success
        }
    }
}

