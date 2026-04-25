import Foundation

enum AppNotificationType: String, Codable {
    case newApplication
    case applicationAccepted
    case applicationRejected
    case newMessage
    case taskCompleted
    case reviewReceived
    case newTaskInYourCity
}
