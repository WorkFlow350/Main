import SwiftUI
import Firebase
import FirebaseAuth

// MARK: - HoMainView
struct HoMainView: View {
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController
    @EnvironmentObject var chatController: ChatController
    
    // MARK: - Tab Enum
    enum Tab {
        case home, search, post, bids, chat
    }

    @State private var selectedTab: Tab = .home
    @State private var showProfileView = false
    @State private var profilePictureURL: String? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {

                // MARK: - Header
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#4A90E2"),
                            Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                    HStack {
                        Text("WorkFlow")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                        Spacer()
                        // MARK: - Profile Picture
                        Button(action: {
                            showProfileView = true
                        }) {
                            if let profilePictureURL = profilePictureURL, let url = URL(string: profilePictureURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                    default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.white)
                                            .background(
                                                Circle()
                                                    .fill(Color.white.opacity(0.2))
                                                    .frame(width: 40, height: 40)
                                            )
                                    }
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                    )
                            }
                        }
                        .padding(.trailing, 16)
                        .fullScreenCover(isPresented: $showProfileView) {
                            HomeownerProfileView()
                                .environmentObject(homeownerJobController)
                                .environmentObject(authController)
                                .environmentObject(bidController)
                                .onAppear {
                                    homeownerJobController.fetchJobsForHomeowner(homeownerId: Auth.auth().currentUser?.uid ?? "")
                                    bidController.jobBids2.removeAll()
                                    homeownerJobController.homeownerJobs.forEach { job in
                                        bidController.getBidsForJob2(job: job)
                                        if let bids = bidController.jobBids2[job.id.uuidString] {
                                            for bid in bids where bid.status == .completed {
                                                bidController.fetchReviewForBid(bid: bid)
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(height: 100)

                // MARK: - Content
                ZStack {
                    switch selectedTab {
                    case .home:
                        HoFeedView()
                    case .search:
                        HoSearchView()
                    case .post:
                        HoPostView()
                    case .bids:
                        HoBidFeedView()
                    case .chat:
                        HoConversationsView()
                    }
                }
                .animation(.smooth(duration: 0.1), value: selectedTab)
                Spacer()
            }

            // MARK: - Tab Bar
            VStack {
                Spacer()
                tabBar
                    .padding(.bottom, 20)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Custom Tab Bar
    var tabBar: some View {
        HStack {
            Spacer()
            tabBarButton(imageName: "house", text: "Home", tab: .home)
            Spacer()
            tabBarButton(imageName: "magnifyingglass", text: "Search", tab: .search)
            Spacer()
            tabBarButton(imageName: "plus.app", text: "Post", tab: .post)
            Spacer()
            tabBarButton(imageName: "note", text: "Bids", tab: .bids)
            Spacer()
            tabBarButton(imageName: "message", text: "Chat", tab: .chat)
            Spacer()
        }
        .padding()
        .background(
            ZStack {
                BlurView(style: .systemThickMaterialLight)
            }
        )
        .cornerRadius(30)
        .padding(.horizontal, 20)
        .frame(maxWidth: 350)
    }

    // MARK: - Tab Bar Button
    @ViewBuilder
    func tabBarButton(imageName: String, text: String, tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22)
                if selectedTab == tab {
                    Text(text)
                        .font(.system(size: 11))
                }
            }
            .foregroundColor(selectedTab == tab ? .black : .gray)
            .animation(.smooth(duration: 0.1), value: selectedTab)
        }
    }
    // Helper Function
    private func fetchReviewForBid(bid: Bid) {
        guard bid.review.isEmpty else {
            print("Review already fetched for bid: \(bid.id)")
            return
        }

        let db = Firestore.firestore()
        db.collection("bids")
            .document(bid.id)
            .getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    let review = data["review"] as? String ?? ""
                    let jobRating = data["jobRating"] as? Double ?? 0.0

                    DispatchQueue.main.async {
                        bidController.updateBidReviewAndRating(
                            bidId: bid.id,
                            review: review,
                            jobRating: jobRating
                        )
                    }
                }
            }
    }
}

// MARK: - Preview
struct HoMainView_Previews: PreviewProvider {
    static var previews: some View {
        HoMainView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())

    }
}
