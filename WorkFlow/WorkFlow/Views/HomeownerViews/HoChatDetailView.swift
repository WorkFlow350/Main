import SwiftUI
import FirebaseAuth

struct HoChatDetailView: View {
    @EnvironmentObject var chatController: ChatController
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var jobController: JobController
    let conversationId: String
    let receiverId: String
    @State private var newMessageText = ""
    @State private var retrievedBid: Bid?
    @State private var retrievedJob: Job?
    @State private var showSheet: Bool = false
    
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
            if let bid = retrievedBid {
                Button(action: {showSheet = true}) {
                    Image(systemName: "plus.app")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .sheet(isPresented: $showSheet) {
                    DetailedBidView2(bid: bid)
                }
                .presentationDetents([.fraction(0.3)])
              /*  NavigationLink(destination: DetailedBidView2(bid: bid)) {
                    Image(systemName: "plus.app")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }*/
            } else {
                Text("no bid found for chat input")
            }
            
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
        HStack{
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
            } else {
                Text("no job or bid data available")
            }
        }
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
    
    struct DetailedBidView2: View {
        let bid: Bid
        @EnvironmentObject var bidController: BidController
        @State private var contractorProfile: ContractorProfile?
        @EnvironmentObject var homeownerJobController: HomeownerJobController
        @EnvironmentObject var authController: AuthController
        
        
        var body: some View {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#4A90E2"),
                        Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                //.ignoresSafeArea(edges: .top)
                .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Bid Amount
                        VStack(alignment: .leading) {
                            Text("Bid Amount:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("$\(bid.price, specifier: "%.2f") USD")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Description
                        VStack(alignment: .leading) {
                            Text("Bid Description:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(bid.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Status
                        VStack(alignment: .leading) {
                            Text("Status:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(bid.status.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundColor(
                                    bid.status == .accepted ? .green :
                                        bid.status == .declined ? .red :
                                        bid.status == .completed ? .blue :
                                            .orange
                                )
                                .fontWeight(.semibold)
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // MARK: - Contractor Profile
                        if let profile = contractorProfile {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Contractor Profile:")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 4)
                                NavigationLink(destination: CoPublicProfileView(contractorProfile: profile, contractorId: bid.contractorId)) {
                                    HStack(spacing: 12) {
                                        // Profile Picture
                                        if let imageURL = profile.imageURL, let url = URL(string: imageURL) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(Circle())
                                                    .shadow(radius: 3)
                                            } placeholder: {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 60, height: 60)
                                            }
                                        }
                                        
                                        // Contractor Details
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Name: \(profile.contractorName)")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                            
                                            Text("City: \(profile.city)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                Text(String(format: "%.1f", profile.rating))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Skills:")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(profile.skills.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Bio:")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                    
                                    Text(profile.bio)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 10)
                        }
                        
                       // Divider()
                        
                        // Show Accept/Decline buttons only if the bid is pending
                        if bid.status == .pending {
                            HStack {
                                // MARK: - Accept Button
                                Button(action: {
                                    bidController.acceptBid(bidId: bid.id, jobId: bid.jobId)
                                }) {
                                    Text("Accept")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                }
                                
                                // MARK: - Decline Button
                                Button(action: {
                                    bidController.declineBid(bidId: bid.id)
                                }) {
                                    Text("Decline")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                    .background(
                        BlurView(style: .systemThickMaterialLight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                }
                .navigationTitle("Bid Details")
                .onAppear {
                    bidController.getContractorProfile(contractorId: bid.contractorId) { profile in
                        self.contractorProfile = profile
                    }
                }
            }
        }
    }
}
