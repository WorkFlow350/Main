import Foundation

// A structure representing the profile of a contractor.
// This structure conforms to the Identifiable and Codable protocols.
struct ContractorProfile: Identifiable, Codable {
    var id: UUID                    // Unique identifier for the contractor profile.
    var contractorName: String      // Name of the contractor.
    var bio: String                 // A brief biography or description provided by the contractor.
    var skills: [String]            // Skills or services the contractor offers (e.g., categories).
    var rating: Double              // The contractor's rating, typically based on feedback from homeowners.
    var jobsCompleted: Int          // The number of jobs the contractor has completed.
    var city: String                // The city where the contractor is available.
    var email: String               // The email address of the contractor.
    var imageURL: String?           // Optional URL for an image associated with the contractor profile.
}
