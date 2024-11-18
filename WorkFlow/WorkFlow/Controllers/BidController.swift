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
                print("Error fetching homeowner job: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                if let homeownerId = document.get("homeownerId") as? String {
                    print("Successfully grabbed homeownerId: \(homeownerId)")
                    let bidId = UUID().uuidString
                    let bidData: [String: Any] = [
                        "id": bidId,//UUID().uuidString,
                        "jobId": job.id.uuidString,
                        "contractorId": contractorId,
                        "homeownerId": homeownerId,
                        "price": price,
                        "description": description,
                        "datePosted": Date(),
                        "status": Bid.bidStatus.pending.rawValue
                    ]
                    
                    print("Attempting to add bid data to Firestore: \(bidData)")
                    
                    //self.db.collection("bids").addDocument(data: bidData) { error in
                    self.db.collection("bids").document(bidId).setData(bidData) { error in
                        if let error = error {
                            print("Error placing bid: \(error.localizedDescription)")
                        } else {
                            print("Bid placed successfully!")
                        }
                    }
                } else {
                    print("Error: Could not retrieve homeownerId from job document")
                }
            } else {
                print("Error: Job document does not exist")
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
                    review: data["review"] as? String ?? ""
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
                    review: data["review"] as? String ?? ""
                )
            }
            DispatchQueue.main.async {
                self.jobBids2[job.id.uuidString] = bids
            }
        }
    }
    
    //MARK: - leave a review
    func leaveReview(bidId: String, review: String) {
        db.collection("bids").document(bidId).updateData(["review": review]) { error in
            if let error = error {
                print("error updating review")
                return
            } else {
                print("Successfully updated review")
            }
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
                    review: data["review"] as? String ?? ""
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
    // Helper function to parse bid data
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
            review: data["review"] as? String ?? ""
        )
    }

    func fetchBid(by bidId: String, completion: @escaping (Bid?) -> Void) {
        db.collection("bids").document(bidId).getDocument { document, error in
            if let data = document?.data() {
                let bid = self.parseBidData(data)
                completion(bid)
            } else {
                print("Error fetching bid: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }

    func getBid(by bidId: String) -> Bid? {
        return coBids.first(where: { $0.id == bidId })
    }
    
    deinit {
        listener1?.remove()
        listener2?.remove()
        observeBidNotifications()
        observeBidStatusChanges()
    }
}
