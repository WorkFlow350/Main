import SwiftUI
import FirebaseAuth

struct ConversationCardView: View {
    let conversation: Conversation
    @EnvironmentObject var chatController: ChatController
    @State private var receiverName: String = "Loading..."
    @State private var receiverImageURL: String?

    var body: some View {
        HStack(spacing: 12) {
            // Blue Dot for New Message Indicator
            if conversation.hasNewMessage {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            } else {
                // Invisible placeholder to keep layout consistent
                Circle()
                    .fill(Color.clear)
                    .frame(width: 10, height: 10)
            }

            // Profile Image
            if let imageURL = receiverImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }

            // Conversation Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(receiverName)
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                }

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Text(formatDate(conversation.lastMessageTimestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(
            BlurView(style: .systemThickMaterialLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            fetchReceiverProfile()
        }
    }

    // MARK: - Format Date
    private func formatDate(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy, h:mm a"
        return formatter.string(from: timestamp)
    }

    // MARK: - Ferch Profile
    private func fetchReceiverProfile() {
        guard let receiverId = conversation.participants.first(where: { $0 != Auth.auth().currentUser?.uid }) else {
            DispatchQueue.main.async {
                self.receiverName = "Unknown"
                self.receiverImageURL = nil
            }
            return
        }
        // Fetch the receiver's name
        if !receiverId.isEmpty {
            chatController.fetchUserName(for: receiverId) { name in
                DispatchQueue.main.async {
                    self.receiverName = name
                }
            }
            // Fetch the receiver's profile picture
            chatController.fetchProfilePicture(for: receiverId) { imageURL in
                DispatchQueue.main.async {
                    self.receiverImageURL = imageURL
                }
            }
        } else {
            DispatchQueue.main.async {
                self.receiverName = "Unknown"
                self.receiverImageURL = nil
            }
        }
    }
}

// MARK: - Preview
struct ConversationCardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockConversations = [
            Conversation(
                id: "1",
                participants: ["currentUser", "user1"],
                lastMessage: "Hey, how are you?",
                lastMessageTimestamp: Date(),
                receiverName: "John Doe",
                hasNewMessage: true
            ),
            Conversation(
                id: "2",
                participants: ["currentUser", "user2"],
                lastMessage: "See you tomorrow!",
                lastMessageTimestamp: Date().addingTimeInterval(-3600),
                receiverName: "Jane Smith",
                hasNewMessage: false
            )
        ]

        VStack {
            ConversationCardView(conversation: mockConversations[0])
                .environmentObject(ChatController())
                .previewLayout(.sizeThatFits)

            ConversationCardView(conversation: mockConversations[1])
                .environmentObject(ChatController())
                .previewLayout(.sizeThatFits)
        }
    }
}
