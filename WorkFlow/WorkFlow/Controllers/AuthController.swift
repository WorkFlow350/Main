import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - AuthController
class AuthController: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var userRole: UserRole? = nil
    @Published var appUser: User?
    private let db = Firestore.firestore()
    var isUserSet = false

    
    // MARK: - Initializer
    init() {
        self.userSession = Auth.auth().currentUser
        if self.userSession == nil {
            self.userRole = nil
            self.appUser = nil
            self.isUserSet = false
        }
    }
    
    // MARK: - Fetch User
    func fetchUser(uid: String) async throws -> User? {
        let maxRetries = 3
        var attempts = 0
        
        while attempts < maxRetries {
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
                attempts += 1
                if attempts >= maxRetries {
                    throw NSError(domain: "AuthController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user after \(maxRetries) attempts"])
                }
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        return nil
    }
    
    // MARK: - Set User
    func setUser() async {
        guard let userSession = self.userSession, !isUserSet else {
            print("User session not available or isUserSet already true")
            return
        }
        
        do {
            print("Attempting to fetch user for uid: \(userSession.uid)")
            let fetchedUser = try await fetchUser(uid: userSession.uid)
            
            if let user = fetchedUser {
                await MainActor.run {
                    self.appUser = user
                    self.userRole = user.role
                    self.isUserSet = true
                    self.objectWillChange.send()
                    print("User role set to: \(user.role.rawValue)")
                }
            } else {
                print("User data could not be fetched")
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
        }
        catch {
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
                self.userRole = nil
                self.isUserSet = false
            }
            await setUser()
        }
        catch {
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
                self.userRole = nil
                self.isUserSet = false
                self.objectWillChange.send()
            }
        }
        catch {
            print("Error signing out: \(error.localizedDescription)")
            throw error
        }
    }
}
