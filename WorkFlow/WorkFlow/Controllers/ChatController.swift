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
            self.userProfileCache[userId] = imageURL // Cache the result
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
        // Determine the receiverId based on the senderId (alternating between contractor and homeowner)
        guard let bidSnapshot = try? await db.collection("bids").whereField("conversationId", isEqualTo: conversationId).getDocuments(),
              let bidData = bidSnapshot.documents.first?.data() else {
            print("Bid not found or missing necessary data.")
            return
        }

        guard let contractorId = bidData["contractorId"] as? String,
              let homeownerId = bidData["homeownerId"] as? String else {
            print("Error: Missing contractorId or homeownerId.")
            return
        }

        // Determine receiverId based on the current user (senderId)
        let receiverId: String
        if senderId == contractorId {
            receiverId = homeownerId  // Contractor sending message to homeowner
        } else if senderId == homeownerId {
            receiverId = contractorId  // Homeowner sending message to contractor
        } else {
            print("Error: The senderId doesn't match either the contractor or homeowner.")
            return
        }

        let messageId = UUID().uuidString
        let timestamp = Date()

        // Create the message object
        let message = Message(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            text: text,
            timestamp: timestamp
        )

        // Save the message in the "messages" collection
        let messageData: [String: Any] = [
            "id": message.id,
            "conversationId": message.conversationId,
            "senderId": message.senderId,
            "receiverId": message.receiverId,
            "text": message.text,
            "timestamp": timestamp
        ]
        
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
            .order(by: "timestamp", descending: false)  // Ensure messages are ordered by timestamp
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
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }

                // Update the UI with the latest messages
                DispatchQueue.main.async {
                    self.messages = newMessages
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
            // Ensure that this async call is marked with `await`
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
    
    // MARK: - Check If Exists
    private func ensureConversationExists(for message: Message) {
        let conversationRef = db.collection("conversations").document(message.conversationId)

        conversationRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, !snapshot.exists else { return }

            // Create a new conversation if it doesn't exist
            let conversationData: [String: Any] = [
                "id": message.conversationId,
                "participants": [message.senderId, message.receiverId],
                "receiverName": message.receiverId, // Replace with actual name lookup if needed
                "lastMessage": message.text,
                "lastMessageTimestamp": message.timestamp
            ]
            conversationRef.setData(conversationData) { error in
                if let error = error {
                    print("Error creating conversation: \(error.localizedDescription)")
                }
            }
        }
    }


    // MARK: - Fetch Conversations with Real-time Listener
    func fetchConversations(for userId: String) {
        db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error.localizedDescription)")
                    return
                }

                self.conversations = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    
                    // Assuming the receiverName is dynamically derived from participants
                    guard let participants = data["participants"] as? [String],
                          let lastMessage = data["lastMessage"] as? String,
                          let timestamp = data["lastMessageTimestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    let receiverName = participants.first { $0 != userId } ?? "Unknown"

                    return Conversation(
                        id: data["id"] as? String ?? "",
                        participants: participants,
                        lastMessage: lastMessage,
                        lastMessageTimestamp: timestamp.dateValue(),
                        receiverName: receiverName
                    )
                } ?? []
            }
    }

    // MARK: - Create Conversation
    func createConversation(conversationId: String, participants: [String], receiverName: String) async throws {
        let conversationData: [String: Any] = [
            "id": conversationId,
            "participants": participants, // Array of participant user IDs
            "receiverName": receiverName,
            "lastMessage": "",
            "lastMessageTimestamp": Date()
        ]

        // Add the conversation to Firestore
        try await db.collection("conversations").document(conversationId).setData(conversationData)
    }

    // MARK: - Mark Messages as Read
    func markMessagesAsRead(conversationId: String, for userId: String) async {
        do {
            let querySnapshot = try await db.collection("messages")
                .whereField("conversationId", isEqualTo: conversationId)
                .whereField("receiverId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()

            // Mark each message as read
            for document in querySnapshot.documents {
                try await document.reference.updateData(["isRead": true])
            }
        } catch {
            print("Failed to mark messages as read: \(error)")
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
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                DispatchQueue.main.async {
                    self.messages = newMessages
                }
            }
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
    }
