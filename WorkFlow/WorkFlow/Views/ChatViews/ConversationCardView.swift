import SwiftUI
import FirebaseAuth

struct ConversationCardView: View {
    let conversation: Conversation
    @EnvironmentObject var chatController: ChatController
    @State private var receiverName: String = "Loading..."
    @State private var receiverImageURL: String?
    @State private var isGlowing: Bool = false

    var body: some View {
        HStack {
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

            VStack(alignment: .leading, spacing: 6) {
                Text(receiverName)
                    .font(.headline)
                    .foregroundColor(.black)

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(formatDate(conversation.lastMessageTimestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(12)
        .background(
            BlurView(style: .systemThickMaterialLight)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(
                    color: conversation.hasNewMessage && isGlowing ? Color.red.opacity(0.8) : Color.clear,
                    radius: conversation.hasNewMessage && isGlowing ? 10 : 0
                )
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isGlowing
                )
        )
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
        .onAppear {
            fetchReceiverProfile()

            // Debugging
            print("hasNewMessage: \(conversation.hasNewMessage)")

            if conversation.hasNewMessage {
                startGlowingEffect()
            }
        }
    }

    private func formatDate(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy, h:mm a"
        return formatter.string(from: timestamp)
    }

    private func startGlowingEffect() {
        print("Starting glowing effect") // Debugging
        isGlowing = true
    }

    private func fetchReceiverProfile() {
        guard let receiverId = conversation.participants.first(where: { $0 != Auth.auth().currentUser?.uid }) else {
            receiverName = "Unknown"
            return
        }

        chatController.fetchUserName(for: receiverId) { name in
            DispatchQueue.main.async {
                self.receiverName = name
            }
        }

        chatController.fetchProfilePicture(for: receiverId) { imageURL in
            DispatchQueue.main.async {
                self.receiverImageURL = imageURL
            }
        }
    }
}
