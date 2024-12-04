import SwiftUI

struct CoConversationsView: View {
    @EnvironmentObject var chatController: ChatController
    @EnvironmentObject var authController: AuthController

    var body: some View {
        NavigationView {
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

                VStack {
                    HStack {
                        Text("Messages")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    // MARK: - No Conversations State
                    if chatController.conversations.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "message.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                                .padding()
                            Text("No conversations yet.")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(chatController.conversations, id: \.id) { conversation in
                                    NavigationLink(
                                        destination: CoChatDetailView(
                                            conversationId: conversation.id,
                                            receiverId: conversation.participants.first(where: { $0 != authController.userSession?.uid })!
                                        )
                                    ) {
                                        ConversationCardView(conversation: conversation)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .onAppear {
                    guard let userId = authController.userSession?.uid else { return }
                    Task {
                        await chatController.fetchConversations(for: userId)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 50)
            }
        }
    }
}

// MARK: - Preview
struct CoConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        let authController = AuthController()
        let chatController = ChatController()

        // Mock Data for Preview
        chatController.conversations = [
            Conversation(
                id: "1",
                participants: ["user1", "receiver1"],
                lastMessage: "Hello there!",
                lastMessageTimestamp: Date(),
                receiverName: "receiver1",
                hasNewMessage: false
            ),
            Conversation(
                id: "2",
                participants: ["user2", "receiver2"],
                lastMessage: "Good morning!",
                lastMessageTimestamp: Date().addingTimeInterval(-3600),
                receiverName: "receiver2",
                hasNewMessage: false
            ),
            Conversation(
                id: "3",
                participants: ["user3", "receiver3"],
                lastMessage: "See you later.",
                lastMessageTimestamp: Date().addingTimeInterval(-7200),
                receiverName: "receiver3",
                hasNewMessage: false 
            )
        ]

        return CoConversationsView()
            .environmentObject(authController)
            .environmentObject(chatController)
    }
}
