import SwiftUI

enum RootTab: CaseIterable {
    case home
    case map
    case create
    case messages
    case profile

    var title: String {
        switch self {
        case .home: return ""
        case .map: return ""
        case .create: return ""
        case .messages: return ""
        case .profile: return ""
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house"
        case .map: return "map"
        case .create: return "plus"
        case .messages: return "bubble.left.and.bubble.right"
        case .profile: return "person"
        }
    }
}
