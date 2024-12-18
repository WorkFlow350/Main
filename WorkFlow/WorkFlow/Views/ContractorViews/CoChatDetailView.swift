import SwiftUI
import FirebaseAuth

struct CoChatDetailView: View {
    @EnvironmentObject var chatController: ChatController
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    let conversationId: String
    let receiverId: String
    @State private var newMessageText = ""
    @State private var retrievedBid: Bid?
    @State private var retrievedJob: Job?
    @State private var retrievedFlyer: ContractorProfile?

    private let chatBackgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
            Color.black.opacity(0.99)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            chatBackgroundGradient
                .ignoresSafeArea()
            
            VStack {
                // MARK: - Messages List
                ScrollView {
                    statusBar
                    Divider()
                    messagesList
                }
                chatInputBar
            }
        }
        .onAppear {
            flyerController.fetchFlyerByConversation(conversationId: conversationId) { flyer in
                if let flyer = flyer {
                    retrievedFlyer = flyer
                    print("Flyer retrieved: \(flyer.contractorName)")
                } else {
                    print("No flyer found for conversationId: \(conversationId)")
                }
            }
            bidController.fetchSingleBid(conversationId: conversationId) { bid in
                if let bid = bid {
                    retrievedBid = bid
                    print("bid retrieved")
                    
                    if let bidId = retrievedBid?.jobId {
                        jobController.fetchSingleJob(bidJobId: bidId) { job in
                            if let job = job {
                                retrievedJob = job
                                print("job retrieved")
                            } else {
                                print("no job found")
                            }
                        }
                    } else {
                        print("no jobid found in retrieved bid")
                    }
                } else {
                    print("no bid found")
                }
            }
            
            Task {
                do {
                    // Fetch messages for the conversation once the view appears
                    await chatController.fetchMessages(for: conversationId)
                    // Fetch conversation by participants if it's not already fetched
                    guard let contractorId = authController.userSession?.uid else { return }
                    await chatController.fetchConversationByParticipants(contractorId: contractorId, homeownerId: receiverId)
                    await chatController.markMessagesAsRead(conversationId: conversationId, userId: Auth.auth().currentUser?.uid ?? "")
                } catch {
                    print("Failed to fetch conversation or messages: \(error)")
                }
            }
        }
    }
    
    // MARK: - Messages List
    private var messagesList: some View {
        ScrollViewReader { scrollViewProxy in
            VStack(spacing: 10) {
                ForEach(chatController.messages) { message in
                    ChatMessageView(
                        text: message.text,
                        isSentByCurrentUser: message.senderId == authController.userSession?.uid,
                        messageId: message.id,
                        conversationId: message.conversationId,
                        timestamp: message.timestamp,
                        isLastMessage: message.id == chatController.messages.last?.id
                    )
                    .id(message.id)
                }
            }
            .onAppear {
                // Scroll to the last message when the view appears
                if let lastMessageId = chatController.messages.last?.id {
                    DispatchQueue.main.async {
                        scrollViewProxy.scrollTo(lastMessageId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: chatController.messages) { _ in
                // Scroll to the last message when new messages are added
                if let lastMessageId = chatController.messages.last?.id {
                    DispatchQueue.main.async {
                        scrollViewProxy.scrollTo(lastMessageId, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Input Bar
    private var chatInputBar: some View {
        HStack {
            TextField("Type a message", text: $newMessageText)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    //MARK: - status bar
    private var statusBar: some View {
        HStack {
            if let job = retrievedJob, let bid = retrievedBid {
                Text("\(job.title):")
                    .font(.footnote)
                    .foregroundColor(.white)
                Text("\(bid.status.rawValue.capitalized)")
                    .font(.footnote)
                    .foregroundColor(
                        bid.status == .accepted ? .green :
                            bid.status == .declined ? .red :
                            bid.status == .completed ? .blue :
                                .orange
                    )
            } else if let contractorProfile = retrievedFlyer {
                Text("Flyer Title: \(contractorProfile.contractorName)")
                    .font(.footnote)
                    .foregroundColor(.white)
            } else {
                Text("Conversation Details")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    // MARK: - Send Message
    private func sendMessage() {
        Task {
            guard let senderId = authController.userSession?.uid, !newMessageText.isEmpty else { return }
            do {
                // Use the already passed conversationId
                let conversationId = self.conversationId
                
                // Send the message
                try await chatController.sendMessage(
                    conversationId: conversationId,  // Corrected parameter name
                    senderId: senderId,
                    text: newMessageText  // No need to pass receiverId anymore
                )
                
                // Create a new message object for the UI
                let newMessage = Message(
                    id: UUID().uuidString,
                    conversationId: conversationId,
                    senderId: senderId,
                    receiverId: receiverId,  // This should be determined inside sendMessage method
                    text: newMessageText,
                    timestamp: Date(),
                    isRead: false
                )
                
                // Append the new message to the messages list
                chatController.messages.append(newMessage)
                newMessageText = ""  // Clear the input field
                
                // Fetch the latest messages for the conversation
                await chatController.fetchMessages(for: conversationId)
                
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
}

