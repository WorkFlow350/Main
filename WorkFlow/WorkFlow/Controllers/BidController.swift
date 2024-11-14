import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine

class BidController: ObservableObject {
    @Published var jobBids: [Bid] = []
    @Published var coBids: [Bid] = []
    private var listener1: ListenerRegistration?
    private var listener2: ListenerRegistration?
    private let db = Firestore.firestore()
    
    //MARK: -Date Formatter
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
        // Fetch all bids for the specified job
        db.collection("bids").whereField("jobId", isEqualTo: jobId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching bids for job: \(error.localizedDescription)")
                return
            }
            print("Accepted Bid ID: \(acceptedBidId)")
            // Update each bid's status to declined, except the accepted one
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
    }
    // MARK: - Decline bids
    func declineBid(bidId: String) {
        updateBidStatus(bidId: bidId, status: .declined)
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
        // Fetching contractor profile from Firestore
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
            
            // Create ContractorProfile from Firestore data
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
                    bidDate: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        }
    }
    // MARK: - Count Bids for a Job
    func countBidsForJob(jobId: UUID, completion: @escaping (Int) -> Void) {
        db.collection("bids").whereField("jobId", isEqualTo: jobId.uuidString).getDocuments { snapshot, error in
            if let error = error {
                print("Error counting bids for job: \(error.localizedDescription)")
                completion(0) // Return 0 if there was an error
                return
            }
            // Return the count of documents in the snapshot
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
                    bidDate: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        }
    }
    
    deinit {
        listener1?.remove()
        listener2?.remove()
    }
}
