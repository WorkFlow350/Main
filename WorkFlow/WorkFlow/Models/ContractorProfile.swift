import Foundation

// A structure representing the profile of a contractor.
// This structure conforms to the Identifiable protocol, allowing each profile to have a unique ID.
struct ContractorProfile: Identifiable {
    var id: UUID                 // Unique identifier for the contractor profile.
    var contractor: User         // The contractor associated with this profile (references the User struct).
    var bio: String              // A brief biography or description provided by the contractor.
    var rating: Double           // The contractor's rating, typically based on feedback from homeowners.
    var jobsCompleted: Int       // The number of jobs the contractor has completed.
}
