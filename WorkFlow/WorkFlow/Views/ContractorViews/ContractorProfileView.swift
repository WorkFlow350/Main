import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// MARK: - IdentifiableError
struct IdentifiableErrorCO: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - ContractorProfileView
struct ContractorProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authController: AuthController
    @State private var profileImage: Image? = Image("profilePlaceholder")
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var bio: String = ""
    @State private var jobs: [Job] = []
    @State private var navigateToCoChat: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: IdentifiableErrorCO?
    @State private var profilePictureURL: String? = nil
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#d3d3d3"), Color(hex: "#708090")]),
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
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Back")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        signOut()
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
            .navigationDestination(isPresented: $navigateToCoChat) {
                CoChatView()
            }
            .onAppear(perform: loadUserData)
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    uploadProfileImage(image)
                }
            }
        }
    }

    // MARK: - Load User Data for Contractor
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                self.errorMessage = IdentifiableErrorCO(message: "Failed to fetch user data: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                self.name = data["name"] as? String ?? "Unknown"
                self.location = data["city"] as? String ?? "Unknown"
                let role = (data["role"] as? String ?? "Contractor").capitalized
                self.location = "\(role) | \(self.location)"
                self.bio = data["bio"] as? String ?? "No bio available."
                self.profilePictureURL = data["profilePictureURL"] as? String
                loadProfileImage()
            } else {
                self.errorMessage = IdentifiableErrorCO(message: "User data not found.")
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
                self.errorMessage = IdentifiableErrorCO(message: "Failed to load profile image: \(error.localizedDescription)")
            } else if let imageData = data, let uiImage = UIImage(data: imageData) {
                self.profileImage = Image(uiImage: uiImage)
            }
            self.isLoading = false
        }
    }

    // MARK: - Upload Profile Image
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let imageRef = storage.reference().child("profilePictures/\(userId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                self.errorMessage = IdentifiableErrorCO(message: "Failed to upload image: \(error.localizedDescription)")
                return
            }
            imageRef.downloadURL { url, error in
                if let error = error {
                    self.errorMessage = IdentifiableErrorCO(message: "Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                if let url = url {
                    self.profilePictureURL = url.absoluteString
                    db.collection("users").document(userId).updateData(["profilePictureURL": url.absoluteString]) { error in
                        if let error = error {
                            self.errorMessage = IdentifiableErrorCO(message: "Failed to update profile URL: \(error.localizedDescription)")
                        } else {
                            self.loadProfileImage()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Button(action: {
                isImagePickerPresented = true
            }) {
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
            navigateToCoChat = true
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
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: SignInView().environmentObject(authController))
                window.makeKeyAndVisible()
            }
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
struct ContractorProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContractorProfileView().environmentObject(AuthController())
    }
}
