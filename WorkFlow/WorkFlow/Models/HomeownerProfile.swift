import Foundation

// MARK: - HomeownerProfile Struct
struct HomeownerProfile: Identifiable {
    var id: UUID
    var homeowner: User
    var address: String
    var phone: String
}
