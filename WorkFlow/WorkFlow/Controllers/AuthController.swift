import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - AuthController
class AuthController: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var appUser: User?
    private let db = Firestore.firestore()
    
    // MARK: - Initializer
    init() {
        self.userSession = Auth.auth().currentUser
        //Task { await setUser() }
    }
    
    // MARK: - Fetch User
    func fetchUser(uid: String) async throws -> User? {
        do {
            let userDocument = try await db.collection("users").document(uid).getDocument()
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
    
    // MARK: - Set User
    func setUser() async {
        guard let userSession = self.userSession else {
            print("No user session available")
            return
        }
        
        do {
            if let user = try await fetchUser(uid: userSession.uid) {
                DispatchQueue.main.async {
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
    
    // MARK: - Create User
    func createUser(withEmail email: String, password: String, name: String, city: String, role: UserRole, bio: String) async throws {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.userSession = authResult.user
            }

            let user = User(id: authResult.user.uid, name: name, city: city, bio: bio, role: role, email: email, profilePictureURL: nil)
            let userData = try Firestore.Encoder().encode(user)

            try await db.collection("users").document(user.id).setData(userData)
        } catch {
            print("Error creating user: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Sign In
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.userSession = authResult.user
            }
            await setUser()
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.userSession = nil
                self.appUser = nil
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            throw error
        }
    }
}
