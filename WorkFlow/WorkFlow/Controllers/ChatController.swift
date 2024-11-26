import Foundation
import FirebaseFirestore
import Firebase
import FirebaseAuth

class ChatController: ObservableObject {
    private let db = Firestore.firestore()
    @Published var contractorProfile: ContractorProfile?
    @Published var homeownerProfile: HomeownerProfile?
    @Published var messages: [Message] = []
    @Published var conversations: [Conversation] = []
    private var userCache: [String: String] = [:]
    private var userProfileCache: [String: String] = [:]
    private var viewedConversations: Set<String> = []
    
    // MARK: - Fetch Profile Picture
    func fetchProfilePicture(for userId: String, completion: @escaping (String?) -> Void) {
        if let cachedImageURL = userProfileCache[userId] {
            completion(cachedImageURL)
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching profile picture: \(error.localizedDescription)")
                completion(nil)
                return
            }
            let imageURL = document?.data()?["profilePictureURL"] as? String
            self.userProfileCache[userId] = imageURL
            completion(imageURL)
        }
    }
    
    // MARK: - Fetch Names
    func fetchUserName(for userId: String, completion: @escaping (String) -> Void) {
        if let cachedName = userCache[userId] {
            completion(cachedName)
            return
        }
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user name: \(error.localizedDescription)")
                completion("Unknown")
                return
            }
            let name = document?.data()?["name"] as? String ?? "Unknown"
            self.userCache[userId] = name
            completion(name)
        }
    }
    
    // MARK: - Send Message
    func sendMessage(conversationId: String, senderId: String, text: String) async throws {
        // Fetch conversation details from the "conversations" collection
        guard let conversationSnapshot = try? await db.collection("conversations").document(conversationId).getDocument(),
              let conversationData = conversationSnapshot.data(),
              let participants = conversationData["participants"] as? [String] else {
            print("Error: Conversation not found or missing necessary data.")
            return
        }
        
        // Determine the receiverId based on the participants
        guard participants.count == 2 else {
            print("Error: Invalid conversation participants.")
            return
        }
        
        // The receiver is the participant who is not the sender
        let receiverId = participants.first { $0 != senderId } ?? ""
        
        if receiverId.isEmpty {
            print("Error: Could not determine receiverId.")
            return
        }
        
        // Create a new message
        let messageId = UUID().uuidString
        let timestamp = Date()
        
        let message = Message(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            text: text,
            timestamp: timestamp,
            isRead: false
        )
        
        // Prepare data for Firestore
        let messageData: [String: Any] = [
            "id": message.id,
            "conversationId": message.conversationId,
            "senderId": message.senderId,
            "receiverId": message.receiverId,
            "text": message.text,
            "timestamp": timestamp,
            "isRead": false
        ]
        
        // Save the message in the "messages" collection
        try await db.collection("messages").document(messageId).setData(messageData)
        
        // Update the conversation with the last message
        let conversationRef = db.collection("conversations").document(conversationId)
        let conversationUpdate: [String: Any] = [
            "lastMessage": text,
            "lastMessageTimestamp": timestamp
        ]
        
        try await conversationRef.updateData(conversationUpdate)
    }
    
    // MARK: - Fetch Messages with Real-time Listener
    func fetchMessages(for conversationId: String) {
        db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else { return }

                let newMessages = snapshot.documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    return Message(
                        id: data["id"] as? String ?? "",
                        conversationId: data["conversationId"] as? String ?? "",
                        senderId: data["senderId"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        isRead: data["isRead"] as? Bool ?? false
                    )
                }

                DispatchQueue.main.async {
                    self.messages = newMessages

                    // Update conversation's hasNewMessage if there are unread messages
                    if let userId = Auth.auth().currentUser?.uid {
                        let hasUnread = newMessages.contains { !$0.isRead && $0.receiverId == userId }
                        if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                            self.conversations[index].hasNewMessage = hasUnread
                        }
                    }
                }
            }
    }
    
    // MARK: - Generate Conversation ID
    private func generateConversationId(userId1: String, userId2: String) -> String {
        let sortedIds = [userId1, userId2].sorted()
        return sortedIds.joined(separator: "_")
    }
    
    // MARK: - Fetch Conversation ID
    func fetchConversationId(for userId1: String, userId2: String) async throws -> String {
        let conversationId = generateConversationId(userId1: userId1, userId2: userId2)
        
        do {
            let snapshot = try await db.collection("conversations")
                .whereField("id", isEqualTo: conversationId)
                .getDocuments()
            
            if snapshot.documents.isEmpty {
                // If no existing conversation, create a new one
                let conversationData: [String: Any] = [
                    "id": conversationId,
                    "participants": [userId1, userId2],
                    "lastMessage": "",
                    "lastMessageTimestamp": Date()
                ]
                try await db.collection("conversations").document(conversationId).setData(conversationData)
            }
            
            return conversationId
        } catch {
            print("Error fetching or creating conversation: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Fetch Conversations with Real-time Listener
    func fetchConversations(for userId: String) {
        print("Fetching conversations for userId: \(userId)")
        db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else {
                    print("No conversations found.")
                    return
                }

                DispatchQueue.main.async {
                    self.conversations = snapshot.documents.compactMap { doc in
                        let data = doc.data()
                        print("Conversation data: \(data)")

                        guard let id = data["id"] as? String,
                              let participants = data["participants"] as? [String],
                              let lastMessage = data["lastMessage"] as? String,
                              let timestamp = data["lastMessageTimestamp"] as? Timestamp else {
                            return nil
                        }

                        // Check for unread messages in real time
                        let query = self.db.collection("messages")
                            .whereField("conversationId", isEqualTo: id)
                            .whereField("receiverId", isEqualTo: userId)
                            .whereField("isRead", isEqualTo: false)

                        query.getDocuments { snapshot, error in
                            if let error = error {
                                print("Error checking unread messages: \(error.localizedDescription)")
                                return
                            }

                            let hasUnread = snapshot?.documents.isEmpty == false
                            DispatchQueue.main.async {
                                if let index = self.conversations.firstIndex(where: { $0.id == id }) {
                                    self.conversations[index].hasNewMessage = hasUnread
                                }
                            }
                        }

                        return Conversation(
                            id: id,
                            participants: participants,
                            lastMessage: lastMessage,
                            lastMessageTimestamp: timestamp.dateValue(),
                            receiverName: "Loading...", // Update dynamically
                            hasNewMessage: false // Updated later
                        )
                    }
                    self.sortConversationsByMostRecent()
                }
            }
    }
    // MARK: - Sort Conversations
    func sortConversationsByMostRecent() {
        DispatchQueue.main.async {
            self.conversations.sort { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
        }
    }
    
    // MARK: - Unread Messages
    private func hasUnreadMessagesFirestore(conversationId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .whereField("receiverId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking unread messages: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(snapshot?.documents.isEmpty == false)
            }
    }
    
    // MARK: - Delete Message
    func deleteMessage(messageId: String, conversationId: String) async throws {
        do {
            try await db.collection("messages").document(messageId).delete()
            await MainActor.run {
                self.messages.removeAll { $0.id == messageId }
            }
            try await updateConversationAfterDeletion(conversationId: conversationId)
        } catch {
            await MainActor.run {
                print("Failed to delete message: \(error)")
            }
            throw error
        }
    }
    
    // MARK: - Update Conversation After Deletion
    private func updateConversationAfterDeletion(conversationId: String) async throws {
        // Get the remaining messages for the conversation
        let snapshot = try await db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        // If there are remaining messages, update the conversation with the last message
        if !snapshot.documents.isEmpty {
            let lastMessage = snapshot.documents.last
            let lastMessageText = lastMessage?["text"] as? String ?? ""
            let lastMessageTimestamp = lastMessage?["timestamp"] as? Timestamp ?? Timestamp()
            
            // Update the conversation with the last message
            try await db.collection("conversations").document(conversationId).updateData([
                "lastMessage": lastMessageText,
                "lastMessageTimestamp": lastMessageTimestamp.dateValue()
            ])
        } else {
            // If no more messages are left, delete the conversation
            try await db.collection("conversations").document(conversationId).delete()
        }
    }
    // MARK: - Listener
    func listenToMessages(for conversationId: String) {
        db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else { return }
                let newMessages = snapshot.documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    return Message(
                        id: data["id"] as? String ?? "",
                        conversationId: data["conversationId"] as? String ?? "",
                        senderId: data["senderId"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        isRead: data["isRead"] as? Bool ?? false
                    )
                }
                DispatchQueue.main.async {
                    self.messages = newMessages
                }
            }
    }
    
    func fetchOrCreateConversationId(senderId: String, receiverId: String) async throws -> String {
        // Sort participants to create a unique conversation ID
        let conversationId = [senderId, receiverId].sorted().joined(separator: "_")
        
        // Check if the conversation already exists
        if conversations.contains(where: { $0.id == conversationId }) {
            return conversationId
        }
        
        // If not, create a new conversation
        let newConversation = Conversation(
            id: conversationId,
            participants: [senderId, receiverId],
            lastMessage: "",
            lastMessageTimestamp: Date(),
            receiverName: receiverId, // Replace with actual receiver name if available
            hasNewMessage: false
        )
        
        // Simulate adding it to a database or local storage
        DispatchQueue.main.async {
            self.conversations.append(newConversation)
        }
        
        return conversationId
    }
    
    func fetchConversationByParticipants(contractorId: String, homeownerId: String) {
        db.collection("conversations")
            .whereField("participants", arrayContains: contractorId)
            .whereField("participants", arrayContains: homeownerId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching conversation: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else { return }
                // Check the documents for matching conversationId and participants
                snapshot.documents.forEach { doc in
                    let data = doc.data()
                    print("Found conversation: \(data)")
                }
            }
    }
    
    // MARK: - Mark Read
    func markMessagesAsRead(conversationId: String, userId: String) async {
        do {
            let query = db.collection("messages")
                .whereField("conversationId", isEqualTo: conversationId)
                .whereField("receiverId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)

            let snapshot = try await query.getDocuments()
            for document in snapshot.documents {
                try await document.reference.updateData(["isRead": true])
            }

            // Firestore listener will handle hasNewMessage updates
        } catch {
            print("Failed to mark messages as read: \(error.localizedDescription)")
        }
    }
}
