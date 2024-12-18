import SwiftUI
import Firebase

struct MainTabView: View {
    // MARK: - Tab Enum
    enum Tab {
        case home, search, post, bids, chat
    }
    
    // MARK: - State Variables
    @State private var selectedTab: Tab = .home
    @State private var showProfileView = false
    @State private var showSignInView = false
    @State private var profilePictureURL: String? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Header
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#4A90E2"),
                            Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0)
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

                        // MARK: - Profile Picture and Sign In Button
                        HStack(spacing: 16) {
                            Button(action: {
                                showSignInView = true
                            }) {
                                Text("Sign In")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            .fullScreenCover(isPresented: $showSignInView) {
                                SignInView()
                            }
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
                            .fullScreenCover(isPresented: $showProfileView) {
                                GuestModeProfileView()
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.vertical, 10)
                }
                .frame(height: 100)

                // MARK: - Content Area
                ZStack {
                    switch selectedTab {
                    case .home:
                        FeedView()
                    case .search:
                        SearchView()
                    case .post:
                        PostView()
                    case .bids:
                        ChatView()
                    case .chat:
                        NotificationView()
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
            tabBarButton(imageName: "house.fill", text: "Home", tab: .home)
            Spacer()
            tabBarButton(imageName: "magnifyingglass", text: "Search", tab: .search)
            Spacer()
            tabBarButton(imageName: "plus.app.fill", text: "Post", tab: .post)
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
            .animation(.bouncy(duration: 0.1), value: selectedTab)
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
    }
}
