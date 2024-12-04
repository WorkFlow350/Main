import SwiftUI

struct FlyerDetailView: View {
    // MARK: - Properties
    let contractor: ContractorProfile

    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var chatController: ChatController
    @EnvironmentObject var flyerController: FlyerController

    @State private var isFullScreen: Bool = false
    @State private var isLoading: Bool = false
    @State private var conversationId: String? = nil
    @State private var showMessageView: Bool = false
    @State private var navigateToChatView: Bool = false

    // MARK: - Body
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        if let imageURL = contractor.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: UIScreen.main.bounds.width, height: 300)
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        isFullScreen = true
                                    }
                            } placeholder: {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 200)
                            }
                        }

                        Text(contractor.contractorName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.leading)

                        Text("Service Area: \(contractor.city)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.leading)

                        Text("Contact: \(contractor.email)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.leading)

                        Text(contractor.bio)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.leading)
                    }
                    .padding(.bottom, 20)
                }

                Spacer()

                // MARK: - Message Button
                if authController.userSession != nil {
                    Button(action: {
                        startConversation()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 5)
                            }
                            Text("Message Contractor")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(isLoading)
                } else {
                        Spacer()
                        HStack {
                            Image(systemName: "info.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            Text("Sign Up to Message Contractor")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        Spacer()
                }
            }
            .sheet(isPresented: $showMessageView) {
                if let conversationId = conversationId {
                    HoChatDetailView(conversationId: conversationId, receiverId: contractor.contractorId)
                        .environmentObject(chatController)
                        .environmentObject(authController)
                        .presentationDetents([.fraction(0.9), .large])
                        .presentationDragIndicator(.visible)
                } else {
                    Text("Unable to load conversation.")
                }
            }
            .fullScreenCover(isPresented: $isFullScreen) {
                FullScreenImageView(imageUrl: contractor.imageURL, isFullScreen: $isFullScreen)
            }
        }
    }

    // MARK: - Start Conversation
    private func startConversation() {
        guard let currentUserId = authController.userSession?.uid else {
            print("Error: User not signed in.")
            return
        }
        isLoading = true
        flyerController.fetchFlyerByContractorId(contractorId: contractor.contractorId) { flyerId in
            guard let flyerId = flyerId else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error: Flyer ID not found for contractor.")
                }
                return
            }
            print("Fetched flyerId: \(flyerId)")
            self.flyerController.fetchOrCreateConversation(
                contractorId: contractor.contractorId,
                homeownerId: currentUserId,
                flyerId: flyerId
            ) { conversationId in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let conversationId = conversationId {
                        self.conversationId = conversationId
                        self.showMessageView = true
                    } else {
                        print("Error creating or fetching conversation.")
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct FlyerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleContractor = ContractorProfile(
            id: UUID(),
            contractorId: "sample-contractor-id",
            contractorName: "John Doe",
            bio: "Experienced contractor specializing in home renovations.",
            skills: ["Renovation", "Painting"],
            rating: 4.5,
            jobsCompleted: 10,
            city: "Camarillo",
            email: "johndoe@example.com",
            imageURL: "https://via.placeholder.com/300"
        )

        FlyerDetailView(contractor: sampleContractor)
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
