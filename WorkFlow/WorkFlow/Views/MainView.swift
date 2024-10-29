import SwiftUI
import Firebase

struct MainTabView: View {
    // MARK: - Tab Enum
    enum Tab {
        case home, search, post, chat, notifications
    }
    
    // MARK: - State Variables
    @State private var selectedTab: Tab = .home
    @State private var showProfileView = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Top Header
                HStack {
                    Text("WorkFlow")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading)

                    Spacer()

                    Button(action: {
                        showProfileView = true
                    }) {
                        Image(systemName: "person.crop.square")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                    }
                    .padding(.trailing)
                    .fullScreenCover(isPresented: $showProfileView) {
                        GuestModeProfileView()
                    }
                }
                .padding(.top)
                .padding(.bottom, 10)
                .background(Color(hex: "#355c7d"))

                // MARK: - Main Content Area
                ZStack {
                    switch selectedTab {
                    case .home:
                        FeedView()
                    case .search:
                        SearchView()
                    case .post:
                        PostView()
                    case .chat:
                        ChatView()
                    case .notifications:
                        NotificationView()
                    }
                }
                
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
    }

    // MARK: - Tab Bar Design
    var tabBar: some View {
        HStack {
            Spacer()
            tabBarButton(imageName: "house", text: "Home", tab: .home)
            Spacer()
            tabBarButton(imageName: "magnifyingglass", text: "Search", tab: .search)
            Spacer()
            tabBarButton(imageName: "plus.square", text: "Post", tab: .post)
            Spacer()
            tabBarButton(imageName: "message", text: "Chat", tab: .chat)
            Spacer()
            tabBarButton(imageName: "bell", text: "Notifications", tab: .notifications)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 4)
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
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
