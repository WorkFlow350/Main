// HomeownerProfile.swift - Defines the model for a homeowner's profile in the app.
import Foundation

// A structure representing the profile of a homeowner.
// This structure conforms to the Identifiable protocol, allowing each profile to have a unique ID.
struct HomeownerProfile: Identifiable {
    var id: UUID              // Unique identifier for the homeowner profile.
    var homeowner: User       // The homeowner associated with this profile (references the User struct).
    var address: String       // The physical address of the homeowner.
    var phone: String         // The phone number of the homeowner for contact purposes.
}
