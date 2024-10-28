// ContractorProfile.swift - Defines the model for a contractor's profile in the app.
import Foundation

// A structure representing the profile of a contractor.
// This structure conforms to the Identifiable and Equatable protocols.
struct ContractorProfile: Identifiable, Equatable {
    let id: UUID                      // Unique identifier for each contractor profile.
    let contractorName: String        // Name of the contractor.
    let bio: String                   // Biography or description of the contractor.
    let skills: [String]              // List of skills the contractor possesses.
    let rating: Double                // Average rating of the contractor.
    let jobsCompleted: Int            // Number of jobs completed by the contractor.
    let city: String                  // The city where the contractor is located.
    let email: String                 // Contact email of the contractor.
    var imageURL: String?             // Optional URL for the contractor's profile image.
    
    // Equatable protocol implementation for comparing contractor profiles.
    static func == (lhs: ContractorProfile, rhs: ContractorProfile) -> Bool {
        return lhs.id == rhs.id
    }
}
