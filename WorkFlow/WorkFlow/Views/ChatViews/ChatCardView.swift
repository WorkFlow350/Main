import SwiftUI

struct ChatCardView: View {
    let conversation: Conversation

    var body: some View {
        HStack {
            Circle()
                .fill(Color(randomColorForConversation(conversationId: conversation.id)))  // Use hashed color
                .frame(width: 50, height: 50)
                .overlay(
                    Image("profile_placeholder") // Replace with actual image logic
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(conversation.receiverName) // Display the receiver's name
                    .font(.headline)
                    .foregroundColor(.black)

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Formatted timestamp
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
        )
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }

    // Helper function to format the timestamp
    private func formatDate(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy, h:mm a"
        return formatter.string(from: timestamp)
    }

    private func randomColorForConversation(conversationId: String) -> UIColor {
        // Generate a hash value from the conversationId
        let hashValue = conversationId.hashValue
        let red = CGFloat((hashValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hashValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hashValue & 0x0000FF) / 255.0
        
        // Return a UIColor based on the hash
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
