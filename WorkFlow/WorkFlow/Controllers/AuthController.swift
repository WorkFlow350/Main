//
//  AuthController.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/22/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthController: ObservableObject {
    @Published var userSession: FirebaseAuth.User?  // Stores the current user's Firebase session
    private let db = Firestore.firestore()  // Firestore database reference
    
    init() {
        self.userSession = Auth.auth().currentUser  // Initializes with the current authenticated user
    }
    
    // Function to create a new user and store in Firestore
    func createUser(withEmail email: String, password: String, name: String, city: String, role: UserRole, bio: String) async throws {
        do {
            // Create user with Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Ensure UI updates occur on the main thread
            DispatchQueue.main.async {
                self.userSession = authResult.user // Store the current user's session
            }
            
            // Create a User object to store in Firestore
            let user = User(
                id: authResult.user.uid,  // Use Firebase UID as the user's ID
                name: name,
                city: city,
                bio: bio,  // Add bio information
                role: role,  // Homeowner or Contractor
                email: email,
                profilePictureURL: nil  // Modify if profile picture is available
            )
            
            // Convert User object to a Firestore-friendly dictionary
            let userData = try Firestore.Encoder().encode(user)
            
            // Store user data in Firestore in the "users" collection
            try await db.collection("users").document(user.id).setData(userData)
        } catch {
            print("Error creating user: \(error.localizedDescription)")
            throw error  // Propagate the error to the caller
        }
    }
    
    // Function to sign in a user with email and password
    func signIn(withEmail email: String, password: String) async throws {
        do {
            // Attempt to sign in the user with Firebase Authentication
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Ensure UI updates occur on the main thread
            DispatchQueue.main.async {
                self.userSession = authResult.user // Update the current user's session
            }
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            throw error  // Propagate the error to the caller
        }
    }
    
    // Function to sign out the current user
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            // Ensure UI updates occur on the main thread
            DispatchQueue.main.async {
                self.userSession = nil  // Clear the user session after sign out
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            throw error
        }
    }
}
