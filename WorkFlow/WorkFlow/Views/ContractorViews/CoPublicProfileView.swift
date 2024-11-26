import SwiftUI
import FirebaseFirestore
import FirebaseStorage



// MARK: - ContractorProfileView
struct CoPublicProfileView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController
    @EnvironmentObject var chatController: ChatController
    
    @State private var profileImage: Image? = Image("profilePlaceholder")
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var bio: String = ""
    @State private var flyers: [ContractorProfile] = []
    @State private var navigateToCoChat: Bool = false
    @State private var navigateToBiography: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: IdentifiableErrorCO?
    @State private var profilePictureURL: String? = nil
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    
    let contractorProfile: ContractorProfile
    let contractorId: String
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    init(contractorProfile: ContractorProfile, contractorId: String) {
        self.contractorProfile = contractorProfile
        self.contractorId = contractorId
    }
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                        Color.black.opacity(0.99)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .blur(radius: 4)

                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            profileHeader
                            buttonSection
                            flyerSection
                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)

            .alert(item: $errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }

            .onAppear(perform: loadUserData)

        }
    }

    // MARK: - Load User Data for Contractor
    private func loadUserData() {
        db.collection("users").document(contractorId).getDocument { document, error in
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
                
                contractorController.fetchFlyersForContractor(contractorId: contractorId)
                self.isLoading = false
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

    // MARK: - Button Section
    private var buttonSection: some View {
        HStack(spacing: 16) {
            NavigationLink(destination: BiographyPublicViewCO(bio: bio)) {
                Text("Bio")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#708090"), Color(hex: "#2F4F4F")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Flyer Section
    private var flyerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flyers")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 5)

            ForEach(contractorController.contractorFlyers, id: \.id) { flyer in
                NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                    HStack {
                        if let imageURL = flyer.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 125, height: 125)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .shadow(radius: 3)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 125, height: 125)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 125, height: 125)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(flyer.contractorName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("City: \(flyer.city)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Text("Email: \(flyer.email)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                            Text("Skills: \(flyer.skills.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }
                        .padding(.leading, 10)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.8),
                                        Color.blue.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

}

// MARK: - Biography View
struct BiographyPublicViewCO: View {
    let bio: String

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Text("Biography")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                ScrollView {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
struct ContractorPublicProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContractorProfileView()
            .environmentObject(HomeownerJobController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
            .environmentObject(ChatController())
    }
}

