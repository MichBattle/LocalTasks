import SwiftUI

enum TaskCategory: String, CaseIterable, Identifiable {
    case moving = "Moving"
    case babysitting = "Babysitting"
    case gardening = "Gardening"
    case cleaning = "Cleaning"
    case painting = "Painting"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .moving: return "shippingbox"
        case .babysitting: return "face.smiling"
        case .gardening: return "leaf"
        case .cleaning: return "sparkles"
        case .painting: return "paintbrush"
        }
    }

    var iconColor: Color {
        switch self {
        case .moving: return .orange
        case .babysitting: return .pink
        case .gardening: return .green
        case .cleaning: return .blue
        case .painting: return .purple
        }
    }

    var softBackgroundColor: Color {
        switch self {
        case .moving: return Color.orange.opacity(0.12)
        case .babysitting: return Color.pink.opacity(0.12)
        case .gardening: return Color.green.opacity(0.12)
        case .cleaning: return Color.blue.opacity(0.12)
        case .painting: return Color.purple.opacity(0.12)
        }
    }
}
