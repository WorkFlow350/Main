import SwiftUI
import Firebase

// MainTabView is the entry point for the app's tab navigation
struct MainTabView: View {
    // Enum to represent each tab option in the tab bar
    enum Tab {
        case home, search, post, chat, notifications
    }
    
    // State variable to track the currently selected tab (default is home)
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top header with app title and profile button
                HStack {
                    Text("WorkFlow") // App title
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading)

                    Spacer() // Space between title and profile button

                    Button(action: {
                        // Profile button action - can be defined later
                    }) {
                        Image(systemName: "person.crop.square")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                    }
                    .padding(.trailing)
                }
                .padding(.top)
                .padding(.bottom, 10)
                .background(Color(hex: "#355c7d")) // Background color for header

                // Main content area that displays the selected tab view
                ZStack {
                    switch selectedTab {
                    case .home:
                        FeedView() // Displays the feed (home) view
                    case .search:
                        SearchView() // Displays the search view
                    case .post:
                        PostView() // Displays the post view
                    case .chat:
                        ChatView() // Displays the chat view
                    case .notifications:
                        NotificationView() // Displays the notifications view
                    }
                }
                
                Spacer() // Adds flexible space between content and tab bar
            }
            
            // Custom floating Tab Bar at the bottom of the screen
            VStack {
                Spacer()
                tabBar
                    .padding(.bottom, 20) // Adjust bottom padding as needed
            }
        }
        .edgesIgnoringSafeArea(.bottom) // Ensures the view extends to the bottom of the screen
    }

    // Custom Tab Bar layout and design
    var tabBar: some View {
        HStack {
            Spacer()
            tabBarButton(imageName: "house", text: "Home", tab: .home) // Home tab
            Spacer()
            tabBarButton(imageName: "magnifyingglass", text: "Search", tab: .search) // Search tab
            Spacer()
            tabBarButton(imageName: "plus.square", text: "Post", tab: .post) // Post tab
            Spacer()
            tabBarButton(imageName: "message", text: "Chat", tab: .chat) // Chat tab
            Spacer()
            tabBarButton(imageName: "bell", text: "Notifications", tab: .notifications) // Notifications tab
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 4) // Shadow effect for floating appearance
        )
        .padding(.horizontal, 20) // Horizontal padding to center the tab bar
        .frame(maxWidth: 350) // Optional: Limit the max width of the tab bar
    }

    // Custom Tab Bar Button with dynamic appearance and animation
    @ViewBuilder
    func tabBarButton(imageName: String, text: String, tab: Tab) -> some View {
        Button {
            selectedTab = tab // Updates the selected tab when tapped
        } label: {
            VStack {
                Image(systemName: imageName) // Icon for the tab
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22) // Icon size
                if selectedTab == tab {
                    Text(text) // Text label for the selected tab
                        .font(.system(size: 11))
                }
            }
            .foregroundColor(selectedTab == tab ? .black : .gray) // Highlight the selected tab
            .animation(.easeInOut(duration: 0.25), value: selectedTab) // Animate the tab change
        }
    }
}

// Preview provider for MainTabView to visualize the view in Xcode's canvas
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
