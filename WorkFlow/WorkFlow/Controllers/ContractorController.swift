import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine

// MARK: - ContractorController
class ContractorController: ObservableObject {
    @Published var contractorFlyers: [ContractorProfile] = []
    private var listener: ListenerRegistration?
    private let storage = Storage.storage()

    // MARK: - Fetch Flyers for Contractor
    func fetchFlyersForContractor(contractorId: String) {
        let db = Firestore.firestore()
        listener = db.collection("flyers")
            .whereField("contractorId", isEqualTo: contractorId)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching contractor flyers: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else { return }
                self.contractorFlyers = snapshot.documents.compactMap { document in
                    let data = document.data()
                    print("Fetched flyer data: \(data)") // Debug print
                    return ContractorProfile(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        contractorId: data["contractorId"] as? String ?? "",
                        contractorName: data["contractorName"] as? String ?? "",
                        bio: data["bio"] as? String ?? "",
                        skills: data["skills"] as? [String] ?? [],
                        rating: data["rating"] as? Double ?? 0.0,
                        jobsCompleted: data["jobsCompleted"] as? Int ?? 0,
                        city: data["city"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        imageURL: data["imageURL"] as? String
                    )
                }
                print("Total flyers fetched: \(self.contractorFlyers.count)")
            }
    }

    // MARK: - Upload Image
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let imageRef = storage.reference().child("flyer_images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG format.")
            completion(nil)
            return
        }

        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            imageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)
                }
            }
        }
    }

    // MARK: - Post Flyer
    func postFlyer(flyer: ContractorProfile, selectedImage: UIImage?) {
        let db = Firestore.firestore()
        var flyerData: [String: Any] = [
            "id": flyer.id.uuidString,
            "contractorName": flyer.contractorName,
            "bio": flyer.bio,
            "skills": flyer.skills,
            "rating": flyer.rating,
            "jobsCompleted": flyer.jobsCompleted,
            "city": flyer.city,
            "email": flyer.email,
            "imageURL": flyer.imageURL,
            "contractorId": Auth.auth().currentUser?.uid ?? ""
        ]

        db.collection("flyers").addDocument(data: flyerData) { error in
            if let error = error {
                print("Error posting flyer: \(error.localizedDescription)")
            } else {
                print("Flyer successfully posted.")
                if let contractorId = Auth.auth().currentUser?.uid {
                    self.fetchFlyersForContractor(contractorId: contractorId)
                }
            }
        }
    }
    
    // MARK: - Fetch Flyers for Current Contractor
    func fetchFlyersForCurrentContractor() {
        guard let contractorId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("flyers")
            .whereField("contractorId", isEqualTo: contractorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching contractor flyers: \(error.localizedDescription)")
                    return
                }

                self.contractorFlyers = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return ContractorProfile(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        contractorId: data["contractorId"] as? String ?? "",
                        contractorName: data["contractorName"] as? String ?? "",
                        bio: data["bio"] as? String ?? "",
                        skills: data["skills"] as? [String] ?? [],
                        rating: data["rating"] as? Double ?? 0.0,
                        jobsCompleted: data["jobsCompleted"] as? Int ?? 0,
                        city: data["city"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        imageURL: data["imageURL"] as? String
                    )
                } ?? []
                print("Total flyers fetched for contractor: \(self.contractorFlyers.count)")
            }
    }
    
    // MARK: - Deinitializer
    deinit {
        listener?.remove()
    }
}
