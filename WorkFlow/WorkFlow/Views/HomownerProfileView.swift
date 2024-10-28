import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// MARK: - IdentifiableError
struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - HomeownerProfileView
struct HomeownerProfileView: View {
    @Environment(\.presentationMode) var presentationMode  // To handle view dismissal
    @EnvironmentObject var authController: AuthController  // To access signOut()
    @State private var profileImage: Image? = Image("profilePlaceholder")
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var bio: String = ""
    @State private var jobs: [Job] = []
    @State private var navigateToHoChat: Bool = false  // Updated state for HoChatView
    @State private var isLoading: Bool = true
    @State private var errorMessage: IdentifiableError?
    @State private var profilePictureURL: String? = nil

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#dcdcdc"), Color(hex: "#5f9ea0")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            profileHeader
                            bioSection
                            jobSection
                            messageButton
                            Spacer()
                        }
                        .padding(.top, 50)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // "Back" button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()  // Go back to the previous view
                    }) {
                        Text("Back")
                            .foregroundColor(.white)
                    }
                }
                // "Sign Out" button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        signOut()  // Call the sign-out function
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(8)
                    }
                }
            }
            .alert(item: $errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
            .background(
                // Navigation to HoChatView
                NavigationLink(destination: HoChatView(), isActive: $navigateToHoChat) {
                    EmptyView()
                }
            )
            .onAppear(perform: loadUserData)
        }
    }

    // MARK: - Load User Data
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                self.errorMessage = IdentifiableError(message: "Failed to fetch user data: \(error.localizedDescription)")
                self.isLoading = false
                return
            }

            if let document = document, document.exists {
                let data = document.data() ?? [:]
                self.name = data["name"] as? String ?? "Unknown"
                self.location = data["city"] as? String ?? "Unknown"
                self.bio = data["bio"] as? String ?? "No bio available."
                self.profilePictureURL = data["profilePictureURL"] as? String
                loadProfileImage()
                loadJobs(for: userId)
            } else {
                self.errorMessage = IdentifiableError(message: "User data not found.")
                self.isLoading = false
            }
        }
    }

    // MARK: - Load Profile Image
    private func loadProfileImage() {
        guard let profilePictureURL = profilePictureURL else {
            self.isLoading = false
            return
        }

        let storageRef = storage.reference(forURL: profilePictureURL)
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                self.errorMessage = IdentifiableError(message: "Failed to load profile image: \(error.localizedDescription)")
            } else if let imageData = data, let uiImage = UIImage(data: imageData) {
                self.profileImage = Image(uiImage: uiImage)
            }
            self.isLoading = false
        }
    }

    // MARK: - Load Jobs
    private func loadJobs(for userId: String) {
        db.collection("jobs").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = IdentifiableError(message: "Failed to load jobs: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents {
                self.jobs = documents.compactMap { document -> Job? in
                    try? document.data(as: Job.self)
                }
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            if let image = profileImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
            }

            Text(name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(location)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Bio Section
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio")
                .font(.headline)
                .foregroundColor(.white)

            Text(bio)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
        .padding(.top, 10)
        .padding(.horizontal)
    }

    // MARK: - Job Section
    private var jobSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jobs")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(jobs) { job in
                Text(job.title)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.top, 10)
        .padding(.horizontal)
    }

    // MARK: - Message Button
    private var messageButton: some View {
        Button(action: {
            navigateToHoChat = true  // Navigate to HoChatView
        }) {
            Text("Message")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 80)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.8))
                .cornerRadius(25)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Sign Out
    private func signOut() {
        do {
            try authController.signOut()
            presentationMode.wrappedValue.dismiss()  // Dismiss current view
            // Navigate to sign-in view
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = UIHostingController(rootView: SignInView().environmentObject(authController))
                window.makeKeyAndVisible()
            }
        } catch {
            self.errorMessage = IdentifiableError(message: "Failed to sign out: \(error.localizedDescription)")
        }
    }
}
