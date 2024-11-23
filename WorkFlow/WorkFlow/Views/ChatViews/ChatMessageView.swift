import SwiftUI

struct ChatMessageView: View {
    let text: String
    let isSentByCurrentUser: Bool
    let messageId: String
    let conversationId: String  // Pass the conversationId as a parameter
    @EnvironmentObject var chatController: ChatController
    @EnvironmentObject var authController: AuthController

    var body: some View {
        HStack {
            if isSentByCurrentUser {
                Spacer()
                Text(text)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                // Swipe action for delete
                Button(action: {
                    deleteMessage()
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .padding(5)
                }
            } else {
                Text(text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                Spacer()
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteMessage()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }

    // MARK: - Delete Messages
    private func deleteMessage() {
        guard let senderId = authController.userSession?.uid else { return }
        Task {
            do {
                // Use the correct conversationId for deletion
                try await chatController.deleteMessage(messageId: messageId, conversationId: conversationId)
            } catch {
                print("Error deleting message: \(error.localizedDescription)")
            }
        }
    }
}
