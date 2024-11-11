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
    
    // MARK: - Place Bids
    func placeBid(job: Job, price: Double, description: String) {
        let jobRef = db.collection("jobs").document(job.id.uuidString)
        jobRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching homeowner job: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                if let homeownerId = document.get("homeownerId") as? String {
                    print ("Successfully grabbed homeownerId")
                    
                    var bidData: [String: Any] = [
                        "id": UUID().uuidString,
                        "jobId": job.id.uuidString,
                        "contractorId": Auth.auth().currentUser?.uid ?? "",
                        "homeownerId": homeownerId,
                        "price": price,
                        "description": description,
                        "datePosted": Date(),
                        "status": Bid.bidStatus.pending.rawValue
                    ]
                    self.db.collection("bids").addDocument(data: bidData) { error in
                        if let error = error {
                            print("Error placing bid: \(error.localizedDescription)")
                            return
                        } else {
                            print("Bid placed successfully!")
                        }
                    }
                } else {
                    print("error grabbing homeownerId")
                    return
                }
            }
        }
    }
    
    // MARK: - Accept Bids
    func acceptBid(bidId: String) {
        updateBidStatus(bidId: bidId, status: .accepted)
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
                    homeownerId: data["homeownerid"] as? String ?? "",
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
