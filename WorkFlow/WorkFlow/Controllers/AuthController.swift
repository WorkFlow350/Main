// AuthController.swift - Manages user authentication and user data storage using FirebaseAuth and Firestore.
import Foundation
import FirebaseAuth
import FirebaseFirestore

// ObservableObject to manage user authentication state.
class AuthController: ObservableObject {
    @Published var userSession: FirebaseAuth.User?  // Stores the current user's Firebase session.
    @Published var appUser: User?                   // Stores the current User
    private let db = Firestore.firestore()          // Firestore database reference.
    
    // Initializes with the current authenticated user session, if available.
    init() {
        self.userSession = Auth.auth().currentUser
        Task { await setUser() }  // Set the user on initialization
    }
    
    // Fetches User from the Database
    func fetchUser(uid: String) async throws -> User? {
        do {
            // Fetch user document from Firestore
            let userDocument = try await db.collection("users").document(uid).getDocument()

            // Turn document into a User object
            if let userData = userDocument.data(),
               let id = userData["id"] as? String,
               let name = userData["name"] as? String,
               let city = userData["city"] as? String,
               let bio = userData["bio"] as? String,
               let roleString = userData["role"] as? String,
               let role = UserRole(rawValue: roleString),
               let email = userData["email"] as? String {

                return User(id: id, name: name, city: city, bio: bio, role: role, email: email)
            } else {
                print("No user data found for uid")
                return nil
            }
        } catch {
            print("Error fetching user: \(error)")
            throw error
        }
    }
    
    // Sets the current user
    func setUser() async {
        guard let userSession = self.userSession else {
            print("No user session available")
            return
        }
        
        do {
            if let user = try await fetchUser(uid: userSession.uid) {
                DispatchQueue.main.async {
                    // Set the user only if it's not already set to prevent unexpected overrides
                    if self.appUser == nil {
                        self.appUser = user
                        print("User role set to: \(user.role.rawValue)")
                    } else {
                        print("User already set, role: \(self.appUser?.role.rawValue ?? "Unknown")")
                    }
                }
            }
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
    }
    
    // Creates a new user account in Firebase Authentication and stores the user in Firestore.
    func createUser(withEmail email: String, password: String, name: String, city: String, role: UserRole, bio: String) async throws {
        do {
            // Create user with Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)

            DispatchQueue.main.async {
                self.userSession = authResult.user  // Update the current user session
            }

            // Create a User object to store in Firestore
            let user = User(id: authResult.user.uid, name: name, city: city, bio: bio, role: role, email: email, profilePictureURL: nil)

            // Convert User object to a Firestore-friendly dictionary
            let userData = try Firestore.Encoder().encode(user)

            // Store user data in Firestore under the "users" collection
            try await db.collection("users").document(user.id).setData(userData)
        } catch {
            print("Error creating user: \(error.localizedDescription)")
            throw error  // Propagate the error to the caller
        }
    }
    
    // Signs in a user using email and password.
    func signIn(withEmail email: String, password: String) async throws {
        do {
            // Attempt to sign in the user with Firebase Authentication
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)

            DispatchQueue.main.async {
                self.userSession = authResult.user  // Update the current user session
            }

            // Fetch and set the user data
            await setUser()
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            throw error  // Propagate the error to the caller
        }
    }
    
    // Signs out the current user from Firebase Authentication.
    func signOut() throws {
        do {
            try Auth.auth().signOut()

            DispatchQueue.main.async {
                self.userSession = nil  // Clear the user session after sign out
                self.appUser = nil      // Clear the current user object after sign out
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            throw error  // Propagate the error to the caller
        }
    }
}
