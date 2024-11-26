import SwiftUI

struct ChatMessageView: View {
    let text: String
    let isSentByCurrentUser: Bool
    let messageId: String
    let conversationId: String
    let timestamp: Date
    let isLastMessage: Bool
    @EnvironmentObject var chatController: ChatController
    @EnvironmentObject var authController: AuthController
    @State private var isDeleteVisible = false

    // MARK: - Message View
    var body: some View {
        HStack {
            if isSentByCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(text)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .padding(.horizontal, 10)
                    
                    if isLastMessage {
                        Text(formatDate(timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.trailing, 10)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.horizontal, 10)
                    
                    if isLastMessage {
                        Text(formatDate(timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 10)
                    }
                }
                Spacer()
            }
            
            if isDeleteVisible && isSentByCurrentUser {
                Button(action: {
                    deleteMessage()
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .padding(5)
                }
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture {
            withAnimation {
                isDeleteVisible = true
            }
        }
        .onTapGesture {
            if isDeleteVisible {
                withAnimation {
                    isDeleteVisible = false
                }
            }
        }
    }

    // MARK: - Format Date
    private func formatDate(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy, h:mm a"
        return formatter.string(from: timestamp)
    }

    // MARK: - Delete Messages
    private func deleteMessage() {
        guard let senderId = authController.userSession?.uid else { return }
        Task {
            do {
                try await chatController.deleteMessage(messageId: messageId, conversationId: conversationId)
            } catch {
                print("Error deleting message: \(error.localizedDescription)")
            }
        }
    }
}

struct ChatMessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChatMessageView(
                text: "Happy birthday, bro!",
                isSentByCurrentUser: false,
                messageId: "1",
                conversationId: "conv1",
                timestamp: Date(),
                isLastMessage: true
            )
            ChatMessageView(
                text: "Thank you, bro!",
                isSentByCurrentUser: true,
                messageId: "2",
                conversationId: "conv1",
                timestamp: Date(),
                isLastMessage: true
            )
        }
        .environmentObject(ChatController())
        .environmentObject(AuthController())
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
