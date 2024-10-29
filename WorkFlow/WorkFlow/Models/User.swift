import Foundation

// MARK: - UserRole Enum
enum UserRole: String, Codable {
    case homeowner
    case contractor
}

// MARK: - User Struct
struct User: Identifiable, Codable {
    var id: String
    var name: String
    var city: String
    var bio: String?
    var role: UserRole
    var email: String
    var profilePictureURL: String?
}
