import Foundation

// An enumeration defining the different roles a user can have in the app.
// This helps categorize users as either homeowners or contractors.
enum UserRole: String {
    case homeowner     // Represents a user who is a homeowner (can post jobs).
    case contractor    // Represents a user who is a contractor (can apply for jobs).
}

// A structure representing a user, conforming to the Identifiable protocol.
struct User: Identifiable {
    var id: UUID                     // Unique identifier for each user.
    var name: String                 // Name of the user.
    var role: UserRole               // Role of the user, defined by the UserRole enum.
    var email: String                // Email address of the user for communication and login purposes.
    var profilePictureURL: String?   // Optional URL for the user's profile picture.
}

