import Foundation

// MARK: - ContractorProfile Struct
struct ContractorProfile: Identifiable, Equatable {
    let id: UUID
    let contractorId: String
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
