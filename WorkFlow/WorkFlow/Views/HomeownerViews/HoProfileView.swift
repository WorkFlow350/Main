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
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
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
    @State private var jobs: [Job] = []
    @State private var navigateToHoChat: Bool = false
    @State private var navigateToBiography: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: IdentifiableError?
    @State private var profilePictureURL: String? = nil
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var reviewEditorStates: [UUID: Bool] = [:]
    @State private var reviews: [UUID: String] = [:]
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
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
                            //bioSection
                            jobSection
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
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.clear]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            .cornerRadius(8)
                    }
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.clear
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                let backButtonAppearance = UIBarButtonItemAppearance()
                backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.backButtonAppearance = backButtonAppearance
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            .alert(item: $errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $navigateToHoChat) {
                HoBidFeedView()
            }
            .navigationDestination(isPresented: $navigateToBiography) {
                BiographyView(bio: bio)
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
                let role = (data["role"] as? String ?? "Homeowner").capitalized
                self.location = "\(role) | \(self.location)"
                self.bio = data["bio"] as? String ?? "No bio available."
                self.profilePictureURL = data["profilePictureURL"] as? String
                loadProfileImage()
                homeownerJobController.fetchJobsForHomeowner(homeownerId: userId)
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
            else if let imageData = data, let uiImage = UIImage(data: imageData) {
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
                self.errorMessage = IdentifiableError(message: "Failed to upload image: \(error.localizedDescription)")
                return
            }
            imageRef.downloadURL { url, error in
                if let error = error {
                    self.errorMessage = IdentifiableError(message: "Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                if let url = url {
                    self.profilePictureURL = url.absoluteString
                    db.collection("users").document(userId).updateData(["profilePictureURL": url.absoluteString]) { error in
                        if let error = error {
                            self.errorMessage = IdentifiableError(message: "Failed to update profile URL: \(error.localizedDescription)")
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
    
    // MARK: - Button Section
    private var buttonSection: some View {
        HStack(spacing: 16) {
            Button(action: {
                navigateToHoChat = true
            }) {
                Text("Bids")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
            Button(action: {
                navigateToBiography = true
            }) {
                Text("Biography")
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
        VStack(alignment: .leading, spacing: 16) {
            Text("My Jobs")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            ForEach(homeownerJobController.homeownerJobs) { job in
                NavigationLink(destination: JobDetailView(job: job)) {
                    HStack {
                        if let imageURL = job.imageURL, let url = URL(string: imageURL) {
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
                        }
                        jobCard(
                            job: job,
                            isReviewEditorPresented: Binding(
                                get: { reviewEditorStates[job.id] ?? false },
                                set: { reviewEditorStates[job.id] = $0 }
                            ),
                            review: Binding(
                                get: { reviews[job.id] ?? "" },
                                set: { reviews[job.id] = $0 }
                            )
                        )
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        categoryColor(for: job.category).opacity(0.8),
                                        categoryColor(for: job.category).opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .onAppear {
                    if reviewEditorStates[job.id] == nil {
                        reviewEditorStates[job.id] = false
                    }
                    if reviews[job.id] == nil {
                        reviews[job.id] = ""
                    }
                    bidController.getBidsForJob2(job: job)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Sign Out
    private func signOut() {
        do {
            try authController.signOut()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(
                    rootView: SignInView()
                        .environmentObject(HomeownerJobController())
                        .environmentObject(AuthController())
                        .environmentObject(JobController())
                        .environmentObject(FlyerController())
                        .environmentObject(BidController())
                        .environmentObject(ContractorController())
                        .environmentObject(ChatController())
                )
                window.makeKeyAndVisible()
            }
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Biography View
struct BiographyView: View {
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

// MARK: - review Box
private func reviewButton(isReviewEditorPresented: Binding<Bool>, review: Binding<String>) -> some View {
    Button(action: {
        isReviewEditorPresented.wrappedValue = true
    }) {
        HStack {
            Text(review.wrappedValue.isEmpty ? "review" : review.wrappedValue)
                .foregroundColor(review.wrappedValue.isEmpty ? .gray : .black)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .frame(height: 50)
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}
//MARK: - Review Section
private struct ReviewSection: View {
    let completedBid: Bid
    @EnvironmentObject var bidController: BidController
    @Binding var review: String
    @Binding var isReviewEditorPresented: Bool
    @Binding var jobRating: Double
    @Binding var reviewSubmitted: Bool

    @State private var draftReview: String = ""
    @State private var isFetching: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            if isFetching {
                ProgressView()
            } else if reviewSubmitted {
                VStack(spacing: 10) {
                    Text("Your Review")
                        .font(.headline)
                        .foregroundColor(.black)
                    Divider()
                    Text(review)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(jobRating) ? "star.fill" : "star")
                                .foregroundColor(star <= Int(jobRating) ? .yellow : .gray)
                                .font(.title2)
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Text("Leave a Review")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Divider()

                    CustomTextEditor(text: $draftReview)
                        .frame(height: 100)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                jobRating = Double(star)
                            }) {
                                Image(systemName: star <= Int(jobRating) ? "star.fill" : "star")
                                    .foregroundColor(star <= Int(jobRating) ? .yellow : .gray)
                                    .font(.title2)
                            }
                        }
                    }
                    Button("Submit Review") {
                        review = draftReview
                        bidController.leaveReview(bidId: completedBid.id, review: review)
                        bidController.leaveJobRating(
                            bidId: completedBid.id,
                            contractorId: completedBid.contractorId,
                            jobRating: jobRating
                        )
                        reviewSubmitted = true
                        isReviewEditorPresented = false
                    }
                    .disabled(draftReview.isEmpty || jobRating == 0)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(draftReview.isEmpty || jobRating == 0 ? Color.gray : Color.blue)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .opacity(draftReview.isEmpty || jobRating == 0 ? 0.5 : 1.0)
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            fetchReviewAndRating()
        }
    }

    private func fetchReviewAndRating() {
        let db = Firestore.firestore()
        db.collection("bids")
            .document(completedBid.id)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching review: \(error.localizedDescription)")
                    return
                }
                if let data = snapshot?.data() {
                    self.review = data["review"] as? String ?? ""
                    self.jobRating = data["jobRating"] as? Double ?? 0.0
                    self.reviewSubmitted = !self.review.isEmpty
                    self.draftReview = self.review
                }
                isFetching = false
            }
    }
}
    
//MARK: - Job card
private struct jobCard: View {
    let job: Job
    @EnvironmentObject var bidController: BidController
    @Binding var isReviewEditorPresented: Bool
    @Binding var review: String
    @State private var jobRating: Double = 0.0
    @State private var reviewSubmitted: Bool = false
    @State private var contractorName: String = "Loading..."
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(job.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            Text("City: \(job.city)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
            Text("Category: \(job.category.rawValue)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
            
            if let bids = bidController.jobBids2[job.id.uuidString], !bids.isEmpty {
                if let bid = bids.first(where: { $0.status == .completed }) {
                    Text("Completed by: \(contractorName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                    Button(action: {
                        isReviewEditorPresented = true
                    }) {
                        HStack {
                            Text(!review.isEmpty || reviewSubmitted ? "View Review" : "Leave Review")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                    .sheet(isPresented: $isReviewEditorPresented, onDismiss: fetchReviewForBid) {
                        ReviewSection(
                            completedBid: bid,
                            review: $review,
                            isReviewEditorPresented: $isReviewEditorPresented,
                            jobRating: $jobRating,
                            reviewSubmitted: $reviewSubmitted
                        )
                        .environmentObject(bidController)
                        .presentationDetents([.fraction(0.5)])
                        .presentationDragIndicator(.visible)
                    }
                    .onAppear {
                        fetchReviewForBid()
                        fetchContractorName(bid.contractorId)
                    }
                } else if let bid = bids.first(where: { $0.status == .accepted }) {
                    Text("Status: Accepted - Pending Completion")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                } else {
                    Text("Status: Bid Pending")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text("Status: No Bid")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private func fetchContractorName(_ contractorId: String) {
        let db = Firestore.firestore()
        db.collection("users")
            .document(contractorId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching contractor name: \(error.localizedDescription)")
                    contractorName = "Unknown"
                    return
                }
                if let data = snapshot?.data() {
                    contractorName = data["name"] as? String ?? "Unknown"
                }
            }
    }
    
    private func fetchReviewForBid() {
        guard review.isEmpty else { return }
        let db = Firestore.firestore()
        if let bids = bidController.jobBids2[job.id.uuidString],
           let bid = bids.first(where: { $0.status == .completed }) {
            db.collection("bids")
                .document(bid.id)
                .getDocument { snapshot, error in
                    if let data = snapshot?.data() {
                        review = data["review"] as? String ?? ""
                        jobRating = data["jobRating"] as? Double ?? 0.0
                        reviewSubmitted = !review.isEmpty
                    }
                }
        }
    }
}
    
    // MARK: - Preview
    struct HomeownerProfileView_Previews: PreviewProvider {
        static var previews: some View {
            HomeownerProfileView()
                .environmentObject(HomeownerJobController())
                .environmentObject(AuthController())
                .environmentObject(JobController())
                .environmentObject(FlyerController())
                .environmentObject(BidController())
                .environmentObject(ContractorController())
        }
    }
