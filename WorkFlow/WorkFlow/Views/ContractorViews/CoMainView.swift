import SwiftUI
import Firebase

// MARK: - Contractor Main View
struct CoMainView: View {
    // MARK: - Tab Enumeration
    enum Tab {
        case home, search, post, jobs, chat
    }

    @State private var selectedTab: Tab = .home
    @State private var showProfileView = false
    @State private var profilePictureURL: String? = nil
    @State private var receiverId: String = ""
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var chatController: ChatController

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Gradient Header
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
                            ContractorProfileView()
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(height: 100)

                // MARK: - Main Content
                ZStack {
                    switch selectedTab {
                    case .home:
                        CoFeedView()
                    case .search:
                        CoSearchView()
                    case .post:
                        CoPostView()
                    case .jobs:
                        CoMyJobsView()
                    case .chat:
                        CoConversationsView()
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
            tabBarButton(imageName: "note", text: "Jobs", tab: .jobs)
            Spacer()
            tabBarButton(imageName: "message", text: "Chat", tab: .chat)
            Spacer()
        }
        .padding()
        .background(
            BlurView(style: .systemThickMaterialLight)
                .clipShape(RoundedRectangle(cornerRadius: 30))
        )
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
                ZStack {
                    Image(systemName: imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22)
                }
                if selectedTab == tab {
                    Text(text)
                        .font(.system(size: 11))
                }
            }
            .foregroundColor(selectedTab == tab ? .black : .gray)
            .animation(.smooth(duration: 0.1), value: selectedTab)
        }
    }
}

// MARK: - Preview
struct CoMainView_Previews: PreviewProvider {
    static var previews: some View {
        CoMainView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
            .environmentObject(ChatController())
    }
}
