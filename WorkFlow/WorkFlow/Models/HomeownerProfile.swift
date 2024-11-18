import Foundation

// MARK: - HomeownerProfile Struct
struct HomeownerProfile: Identifiable {
    var id: UUID
    var homeownerName: String
    var bio: String
    var city: String
    var email: String
    var number: String
    var imageURL: String?
}
