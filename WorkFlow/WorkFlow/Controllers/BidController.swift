import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine

class BidController: ObservableObject {
    @Published var jobBids: [Bid] = []
    @Published var jobBids2: [String: [Bid]] = [:]
    @Published var coBids: [Bid] = []
    
    @Published var pendingBids: [Bid] = []
    @Published var approvedBids: [Bid] = []
    @Published var completedBids: [Bid] = []
    @Published var declinedBids: [Bid] = []

    private var listener: ListenerRegistration?
    private var listener1: ListenerRegistration?
    private var listener2: ListenerRegistration?
    private var listener3: ListenerRegistration?
    private let db = Firestore.firestore()

    // MARK: - NOTIFICATION STUFF
    private var bidNotificationListener: ListenerRegistration?
    @Published var bidNotifications: [BidNotification] = []
    @Published var latestNotification: String?
    init() {
        observeBidNotifications()
        observeBidStatusChanges()
        getBidsForContractor()
    }
    
    //MARK: - Date Formatter
    func timeAgoSincePost(_ date: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if let formattedString = formatter.string(from: timeInterval) {
            return "\(formattedString) ago"
        } else {
            return "Just now"
        }
    }
    
    // MARK: - Place Bids
    func placeBid(job: Job, price: Double, description: String) {
        print("Looking for job document with ID: \(job.id.uuidString)")

        guard let contractorId = Auth.auth().currentUser?.uid else {
            print("Error: User is not authenticated")
            return
        }

        let jobRef = db.collection("jobs").document(job.id.uuidString)

        jobRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching job: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists,
                  let homeownerId = document.get("homeownerId") as? String else {
                print("Job document does not exist or homeownerId not found.")
                return
            }

            // Generate conversationId for this bid
            let conversationId = self.generateConversationId(userId1: contractorId, userId2: homeownerId)

            // Create or fetch the conversation
            self.fetchOrCreateConversation(conversationId: conversationId, senderId: contractorId, receiverId: homeownerId)

            let bidId = UUID().uuidString
            let bidData: [String: Any] = [
                "id": bidId,
                "jobId": job.id.uuidString,
                "contractorId": contractorId,
                "homeownerId": homeownerId,
                "price": price,
                "description": description,
                "number": job.number,
                "datePosted": Date(),
                "status": Bid.bidStatus.pending.rawValue,
                "conversationId": conversationId
            ]

            self.db.collection("bids").document(bidId).setData(bidData) { error in
                if let error = error {
                    print("Error placing bid: \(error.localizedDescription)")
                } else {
                    print("Bid placed successfully!")
                }
            }
        }
    }
    
    
    // MARK: - Fetch conversation for a bid
    func fetchConversationForBid(contractorId: String, homeownerId: String) {
        db.collection("conversations")
            .whereField("participants", arrayContains: contractorId)
            .whereField("participants", arrayContains: homeownerId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching conversation: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else { return }
                snapshot.documents.forEach { doc in
                    let data = doc.data()
                    print("Found conversation: \(data)")
                }
            }
    }
    // MARK: - Generate Conversation ID
    private func generateConversationId(userId1: String, userId2: String) -> String {
        let sortedIds = [userId1, userId2].sorted()
        return sortedIds.joined(separator: "_")
    }
    

    // MARK: - Create or Fetch a conversation
    func fetchOrCreateConversation(conversationId: String, senderId: String, receiverId: String) {
        let conversationRef = db.collection("conversations").document(conversationId)

        conversationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching conversation: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else { return }

            if !snapshot.exists {
                // Create the conversation if it doesn't exist
                let conversationData: [String: Any] = [
                    "id": conversationId,
                    "participants": [senderId, receiverId],
                    "lastMessage": "",
                    "lastMessageTimestamp": Date()
                ]
                conversationRef.setData(conversationData) { error in
                    if let error = error {
                        print("Error creating conversation: \(error.localizedDescription)")
                    } else {
                        print("Conversation created successfully!")
                    }
                }
            } else {
                print("Conversation already exists.")
            }
        }
    }
    
    // MARK: - Fetch Lowest Bid
    func fetchCurrentLowestBid(forJob job: Job, completion: @escaping (Double?) -> Void) {
        getLowestBid(forJobId: job.id.uuidString) { lowestBid in
            if let bid = lowestBid {
                completion(bid.price)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Decline Other Bids for a Job
    private func declineOtherBids(exceptBidId acceptedBidId: String, forJobId jobId: String) {
        db.collection("bids").whereField("jobId", isEqualTo: jobId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching bids for job: \(error.localizedDescription)")
                return
            }
            print("Accepted Bid ID: \(acceptedBidId)")
            snapshot?.documents.forEach { document in
                let bidId = document.documentID
                if bidId != acceptedBidId {
                    self.updateBidStatus(bidId: bidId, status: .declined)
                }

            }
        }
    }
    
    // MARK: - Accept Bids
    func acceptBid(bidId: String, jobId: String) {
        updateBidStatus(bidId: bidId, status: .accepted)
        declineOtherBids(exceptBidId: bidId, forJobId: jobId)
        addBidNotification(for: bidId, with: .accepted)
    }
    
    // MARK: - Decline bids
    func declineBid(bidId: String) {
        updateBidStatus(bidId: bidId, status: .declined)
        addBidNotification(for: bidId, with: .declined)
    }
    
    // MARK: - Bid Update
    func updateBidStatus(bidId: String, status: Bid.bidStatus) {
        db.collection("bids").document(bidId).updateData(["status": status.rawValue]) { error in
            if let error = error {
                print("error updating bids")
                return
            } else {
                print("Successfully updated bids")
            }
        }
    }

    
    // MARK: - Fetch Contractor Profile by contractorId
    func getContractorProfile(contractorId: String, completion: @escaping (ContractorProfile?) -> Void) {
        db.collection("users").document(contractorId).getDocument { document, error in
            if let error = error {
                print("Error fetching contractor profile: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = document?.data() else {
                print("No contractor profile found")
                completion(nil)
                return
            }
            let profile = ContractorProfile(
                id: UUID(uuidString: document!.documentID) ?? UUID(),
                contractorName: data["name"] as? String ?? "Unknown",
                bio: data["bio"] as? String ?? "",
                skills: data["skills"] as? [String] ?? [],
                rating: data["rating"] as? Double ?? 0.0,
                jobsCompleted: data["jobsCompleted"] as? Int ?? 0,
                city: data["city"] as? String ?? "",
                email: data["email"] as? String ?? "",
                imageURL: data["profilePictureURL"] as? String
            )
            completion(profile)
        }
    }
    
    // MARK: - Fetch Homeowner Profile by homeownerId
    func getHomeownerProfile(homeownerId: String, completion: @escaping (HomeownerProfile?) -> Void) {
        db.collection("users").document(homeownerId).getDocument { document, error in
            if let error = error {
                print("Error fetching homeowner profile: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = document?.data() else {
                print("No homeowner profile found")
                completion(nil)
                return
            }
            let profile = HomeownerProfile(
                id: UUID(uuidString: document!.documentID) ?? UUID(),
                homeownerName: data["name"] as? String ?? "Unknown",
                bio: data["bio"] as? String ?? "",
                city: data["city"] as? String ?? "",
                email: data["email"] as? String ?? "",
                number: data["number"] as? String ?? "",
                imageURL: data["profilePictureURL"] as? String
            )
            completion(profile)
        }
    }
    // MARK: - Fetch Job Description by jobId
    func getJobDescription(jobId: String, completion: @escaping (String?) -> Void) {
        db.collection("jobs").document(jobId).getDocument { document, error in
            if let error = error {
                print("Error fetching job description: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = document?.data(), let description = data["description"] as? String else {
                print("No job description found for jobId: \(jobId)")
                completion(nil)
                return
            }
            completion(description)
        }
    }

    // MARK: - Fetch Bids for a Job
    func getBidsForJob(job: Job) {
        listener1 = db.collection("bids").whereField("jobId", isEqualTo: job.id.uuidString).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error getting bids: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else { return }
            self.jobBids = snapshot.documents.compactMap { document in
                let data = document.data()
                print("Fetched bid data: \(data)")

                let id = data["id"] as? String ?? ""
                return Bid(
                    id: id,
                    jobId: data["jobId"] as? String ?? "",
                    contractorId: data["contractorId"] as? String ?? "",
                    homeownerId: data["homeownerId"] as? String ?? "",
                    price: data["price"] as? Double ?? 0.0,
                    description: data["description"] as? String ?? "",
                    status: Bid.bidStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                    bidDate: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                    review: data["review"] as? String ?? "",
                    jobRating: data["jobRating"] as? Double ?? 0.0,
                    number: data["number"] as? String ?? "Not available",
                    conversationId: data["conversationId"] as? String ?? ""
                    
                )
            }
        }
    }
    
    //MARK: - fetch bids for job but in dictionary
    func getBidsForJob2(job: Job) {
        listener3 = db.collection("bids").whereField("jobId", isEqualTo: job.id.uuidString).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error getting bids: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else { return }
            let bids = snapshot.documents.compactMap { document in
                let data = document.data()
                print("Fetched bid data: \(data)")

                let id = data["id"] as? String ?? ""
                return Bid(
                    id: id,
                    jobId: data["jobId"] as? String ?? "",
                    contractorId: data["contractorId"] as? String ?? "",
                    homeownerId: data["homeownerId"] as? String ?? "",
                    price: data["price"] as? Double ?? 0.0,
                    description: data["description"] as? String ?? "",
                    status: Bid.bidStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                    bidDate: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                    review: data["review"] as? String ?? "",
                    jobRating: data["jobRating"] as? Double ?? 0.0,
                    number: data["number"] as? String ?? "Not available",
                    conversationId: data["conversationId"] as? String ?? ""
                )
            }
            DispatchQueue.main.async {
                self.jobBids2[job.id.uuidString] = bids
            }
        }
    }
    
    //MARK: - leave a review
    func leaveReview(bidId: String, contractorId: String, review: String) {
        db.collection("bids").document(bidId).updateData(["review": review]) { [weak self] error in
            if let error = error {
                print("error updating review")
                return
            } else {
                print("Successfully updated review")
            }
        }
    }
    //MARK: - leave a rating
    func leaveJobRating(bidId: String, contractorId: String, jobRating: Double) {
        db.collection("bids").document(bidId).updateData(["jobRating": jobRating]) { [weak self] error in
            if let error = error {
                print("error updating job rating")
                return
            } else {
                print("Successfully updated job rating")
                self?.averageReviewsForContractor(ContractorId: contractorId)
            }
        }
    }
    // MARK: - Update Contractor's Average Rating
    func updateContractorAverageRating(contractorId: String, average: Double) {
        db.collection("users").document(contractorId).updateData(["rating": average]) { error in
            if let error = error {
                print("Error updating contractor's average rating: \(error.localizedDescription)")
            } else {
                print("Successfully updated contractor's average rating to \(average)")
            }
        }
    }

    
    // MARK: - Count Reviews and Calculate Average
    func averageReviewsForContractor(ContractorId: String) {
        db.collection("bids")
            .whereField("contractorId", isEqualTo: ContractorId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return  // Don't proceed if there's an error
                }
                
                let reviews = snapshot?.documents.compactMap { document in
                    if let rating = document.data()["jobRating"] as? Double {
                        return rating
                    } else {
                        return nil
                    }
                }
                
                guard let reviews = reviews, !reviews.isEmpty else {
                    print("No reviews found for contractor.")
                    return
                }
                
                let average = reviews.reduce(0, +) / Double(reviews.count)
                print("Average Rating: \(average)")
                
                // Step 3: Update contractor's average rating
                self?.updateContractorAverageRating(contractorId: ContractorId, average: average)
            }
    }
    

    
    // MARK: - Count Bids for a Job
    func countBidsForJob(jobId: UUID, completion: @escaping (Int) -> Void) {
        db.collection("bids").whereField("jobId", isEqualTo: jobId.uuidString).getDocuments { snapshot, error in
            if let error = error {
                print("Error counting bids for job: \(error.localizedDescription)")
                completion(0)
                return
            }
            let count = snapshot?.documents.count ?? 0
            completion(count)
        }
    }

    // MARK: - Bids by contractor
    // use this function to show the all the bids the contractor has made
    func getBidsForContractor() {
        let contractorId = Auth.auth().currentUser?.uid
        listener2 = db.collection("bids").whereField("contractorId", isEqualTo: contractorId).addSnapshotListener {(snapshot, error) in
            if let error = error {
                print("error getting bid")
                return
            }
            guard let snapshot = snapshot else { return }
            self.coBids = snapshot.documents.compactMap { document in
                let data = document.data()
                print("Fetched bid data: \(data)")
            /*
             !!!I had to change this portion of the code!!!
               guard let idString = data["id"] as? String,
                     let id = UUID(uuidString: idString) else {
                     print("could not get bidId")
                     return nil
                     }
                */
                let id = data["id"] as? String ?? ""

                return Bid(
                    id: id,
                    jobId: data["jobId"] as? String ?? "",
                    contractorId: data["contractorId"] as? String ?? "",
                    homeownerId: data["homeownerId"] as? String ?? "",
                    price: data["price"] as? Double ?? 0.0,
                    description: data["description"] as? String ?? "",
                    status: Bid.bidStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                    bidDate: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                    review: data["review"] as? String ?? "",
                    jobRating: data["jobRating"] as? Double ?? 0.0,
                    number: data["number"] as? String ?? "Not available",
                    conversationId: data["conversationId"] as? String ?? ""
                )
            }
        }
    }
    
    // MARK: - Add Bid Notification
    private func addBidNotification(for bidId: String, with status: Bid.bidStatus) {
        guard let contractorId = Auth.auth().currentUser?.uid else {
            print("Error: Contractor ID not available.")
            return
        }
        let notification = BidNotification(
            id: UUID().uuidString,
            bidId: bidId,
            contractorId: contractorId,
            message: "A new bid is \(status.rawValue).",
            date: Date(),
            status: status,
            isRead: false
        )
        print("Attempting to add bid notification with message: \(notification.message)")
        db.collection("bidNotifications").document(notification.id).setData(notification.toDictionary()) { error in
            if let error = error {
                print("Error adding bid notification: \(error.localizedDescription)")
            } else {
                print("Bid notification added successfully to Firestore with ID: \(notification.id)")
                DispatchQueue.main.async {
                    self.bidNotifications.append(notification)
                }
            }
        }
    }
    
    // MARK: - Mark As Read
    func markNotificationAsRead(_ notification: BidNotification) {
        db.collection("bidNotifications").document(notification.id).updateData(["isRead": true]) { error in
            if let error = error {
                print("Error marking notification as read: \(error.localizedDescription)")
            } else {
                print("Notification marked as read successfully.")
            }
        }
    }
    // MARK: - Observe Bid Notifications
    func observeBidNotifications() {
        guard let contractorId = Auth.auth().currentUser?.uid else {
            print("Error: Contractor ID not available for observing notifications.")
            return
        }
        print("Setting up bid notifications listener for contractor ID: \(contractorId)")
        bidNotificationListener = db.collection("bidNotifications")
            .whereField("contractorId", isEqualTo: contractorId)
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching bid notifications: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else {
                    print("Snapshot is nil. No bid notifications fetched.")
                    return
                }
                print("Fetched bid notifications snapshot with \(snapshot.documents.count) documents")
                for diff in snapshot.documentChanges where diff.type == .added {
                    let data = diff.document.data()
                    print("New bid notification data fetched: \(data)")
                }
            }
    }
    // MARK: - Observe Bid Status Changes
    func observeBidStatusChanges() {
        listener1 = db.collection("bids").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error observing bid status changes: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else { return }
            for diff in snapshot.documentChanges {
                if diff.type == .modified {
                    let data = diff.document.data()
                    print("Observed bid status change data: \(data)")
                    
                    if let bidId = data["id"] as? String,
                       let contractorId = data["contractorId"] as? String,
                       let statusRaw = data["status"] as? String,
                       let status = Bid.bidStatus(rawValue: statusRaw),
                       let datePosted = (data["datePosted"] as? Timestamp)?.dateValue() {
                       self.addBidNotification(for: bidId, with: status)
                    }
                }
            }
        }
    }
    
    // MARK: Fetch Contractors Bid Status
    func fetchContractorBidsByStatus() {
        guard let contractorId = Auth.auth().currentUser?.uid else {
            print("Error: Contractor ID not available.")
            return
        }
        listener = db.collection("bids").whereField("contractorId", isEqualTo: contractorId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error getting bids: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else { return }
            
            // Reset categories
            self.pendingBids = []
            self.approvedBids = []
            self.completedBids = []
            self.declinedBids = []
            
            for document in snapshot.documents {
                let data = document.data()
                let bid = self.parseBidData(data)
                
                // Categorize bids by status
                switch bid.status {
                case .pending:
                    self.pendingBids.append(bid)
                case .accepted:
                    self.approvedBids.append(bid)
                case .completed:
                    self.completedBids.append(bid)
                case .declined:
                    self.declinedBids.append(bid)
                }
            }
        }
    }
    private func parseBidData(_ data: [String: Any]) -> Bid {
        let id = data["id"] as? String ?? ""
        return Bid(
            id: id,
            jobId: data["jobId"] as? String ?? "",
            contractorId: data["contractorId"] as? String ?? "",
            homeownerId: data["homeownerId"] as? String ?? "",
            price: data["price"] as? Double ?? 0.0,
            description: data["description"] as? String ?? "",
            status: Bid.bidStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
            bidDate: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
            review: data["review"] as? String ?? "",
            jobRating: data["jobRating"] as? Double ?? 0.0,
            number: data["number"] as? String ?? "Not available",
            conversationId: data["conversationId"] as? String ?? ""
        )
    }
    func fetchBid(byJobId jobId: String, contractorId: String, completion: @escaping (Bid?) -> Void) {
        db.collection("bids")
            .whereField("jobId", isEqualTo: jobId)
            .whereField("contractorId", isEqualTo: contractorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching bid: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let document = snapshot?.documents.first else {
                    print("No bid found for jobId: \(jobId) and contractorId: \(contractorId)")
                    completion(nil)
                    return
                }
                let data = document.data()
                let bid = self.parseBidData(data)
                completion(bid)
            }
    }
    func getBid(by bidId: String) -> Bid? {
        return coBids.first(where: { $0.id == bidId })
    }
    
    // MARK: - Get Lowest Bid
    func getLowestBid(forJobId jobId: String, completion: @escaping (Bid?) -> Void) {
        db.collection("bids")
            .whereField("jobId", isEqualTo: jobId)
            .whereField("status", isEqualTo: Bid.bidStatus.pending.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching lowest bid: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }

                let bids = documents.compactMap { self.parseBidData($0.data()) }
                let lowestBid = bids.min(by: { $0.price < $1.price })
                completion(lowestBid)
            }
    }

    // MARK: - Fetch Available Jobs
    func fetchAvailableJobs(completion: @escaping ([Job]) -> Void) {
        db.collection("jobs").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching jobs: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            var jobs: [Job] = []
            let group = DispatchGroup()

            for document in documents {
                let data = document.data()
                guard let jobId = data["id"] as? String else { continue }
                group.enter()

                self.db.collection("bids")
                    .whereField("jobId", isEqualTo: jobId)
                    .whereField("status", isEqualTo: Bid.bidStatus.accepted.rawValue)
                    .getDocuments { bidSnapshot, bidError in
                        if let bidError = bidError {
                            print("Error checking bids for job \(jobId): \(bidError.localizedDescription)")
                            group.leave()
                            return
                        }

                        if bidSnapshot?.documents.isEmpty == true {
                            // No accepted bid, include this job
                            jobs.append(Job(
                                id: UUID(uuidString: jobId) ?? UUID(),
                                title: data["title"] as? String ?? "Untitled",
                                number: data["number"] as? String ?? "",
                                description: data["description"] as? String ?? "",
                                city: data["city"] as? String ?? "",
                                category: JobCategory(rawValue: data["category"] as? String ?? "") ?? .cleaning,
                                datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                                imageURL: data["imageURL"] as? String,
                                latitude: data["latitude"] as? Double ?? 0.0,
                                longitude: data["longitude"] as? Double ?? 0.0
                            ))
                        }
                        group.leave()
                    }
            }

            group.notify(queue: .main) {
                completion(jobs)
            }
        }
    }
    
    @Published var excludedJobIds: Set<String> = []
    // MARK: - Fetch Exclided Jobs
    func fetchExcludedJobs() {
        db.collection("bids")
            .whereField("status", in: [Bid.bidStatus.accepted.rawValue, Bid.bidStatus.completed.rawValue])
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching excluded jobs: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else {
                    print("No snapshot returned for excluded jobs.")
                    return
                }
                let jobIds = snapshot.documents.compactMap { document in
                    document.data()["jobId"] as? String
                }
                DispatchQueue.main.async {
                    self.excludedJobIds = Set(jobIds)
                    print("Excluded job IDs updated: \(self.excludedJobIds)")
                }
            }
    }
    //MARK: - fetch single Bid
    func fetchSingleBid(conversationId: String, completion: @escaping (Bid?) -> Void) {
        db.collection("bids").whereField("conversationId", isEqualTo: conversationId).getDocuments { snapshot, error in
            if let error = error {
                print("Error getting single bid: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Get the first matching document
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No bid found for conversationId: \(conversationId)")
                completion(nil)
                return
            }
            
            let bids = documents.compactMap { document -> Bid? in
                let data = document.data()
                return Bid(
                    id: data["id"] as? String ?? "",
                    jobId: data["jobId"] as? String ?? "",
                    contractorId: data["contractorId"] as? String ?? "",
                    homeownerId: data["homeownerId"] as? String ?? "",
                    price: data["price"] as? Double ?? 0.0,
                    description: data["description"] as? String ?? "",
                    status: Bid.bidStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                    bidDate: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                    review: data["review"] as? String ?? "",
                    jobRating: data["jobRating"] as? Double ?? 0.0,
                    number: data["number"] as? String ?? "Not available",
                    conversationId: data["conversationId"] as? String ?? ""
                )
            }
            let latestBid = bids.max(by: {$0.bidDate < $1.bidDate})
            completion(latestBid)
        }
    }
    
    deinit {
        listener1?.remove()
        listener2?.remove()
        observeBidNotifications()
        observeBidStatusChanges()
    }
}
