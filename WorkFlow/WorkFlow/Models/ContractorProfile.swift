import Foundation

// A structure representing the profile of a contractor.
// This structure conforms to the Identifiable and Codable protocols.
struct ContractorProfile: Identifiable, Equatable {
    let id: UUID
    let contractorName: String
    let bio: String
    let skills: [String]
    let rating: Double
    let jobsCompleted: Int
    let city: String
    let email: String
    var imageURL: String?
    
    static func == (lhs: ContractorProfile, rhs: ContractorProfile) -> Bool {
        return lhs.id == rhs.id
    }
}
