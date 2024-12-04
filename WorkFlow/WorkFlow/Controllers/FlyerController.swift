import Firebase
import FirebaseStorage
import Combine

// MARK: - ContractorController
class FlyerController: ObservableObject {
    @Published var flyers: [ContractorProfile] = []

    // MARK: - Fetch Flyers
    func fetchFlyers() {
        let db = Firestore.firestore()
        db.collection("flyers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching flyers: \(error.localizedDescription)")
                return
            }
            
            self.flyers = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let contractorId = data["contractorId"] as? String else {
                    print("Missing contractorId for document: \(document.documentID)")
                    return nil
                }
                return ContractorProfile(
                    id: UUID(uuidString: document.documentID) ?? UUID(),
                    contractorId: contractorId,
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
            print("Total flyers fetched: \(self.flyers.count)")
        }
    }

    // MARK: - Post Flyer
    func postFlyer(profile: ContractorProfile, selectedImage: UIImage?) {
        if let selectedImage = selectedImage {
            uploadImage(selectedImage) { [weak self] imageURL in
                guard let self = self else { return }
                
                if let imageURL = imageURL {
                    self.saveFlyerToFirestore(profile: profile, imageURL: imageURL)
                } else {
                    print("Error: Could not upload image.")
                }
            }
        } else {
            saveFlyerToFirestore(profile: profile, imageURL: nil)
        }
    }

    // MARK: - Upload Image
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("flyer_images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG format.")
            completion(nil)
            return
        }

        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)
                }
            }
        }
    }

    // MARK: - Save Flyer to Firestore
    private func saveFlyerToFirestore(profile: ContractorProfile, imageURL: String?) {
        let db = Firestore.firestore()
        var flyerData: [String: Any] = [
            "contractorName": profile.contractorName,
            "bio": profile.bio,
            "skills": profile.skills,
            "rating": profile.rating,
            "jobsCompleted": profile.jobsCompleted,
            "city": profile.city,
            "email": profile.email
        ]

        if let imageURL = imageURL {
            flyerData["imageURL"] = imageURL
        }

        db.collection("flyers").addDocument(data: flyerData) { error in
            if let error = error {
                print("Error posting flyer: \(error.localizedDescription)")
            } else {
                print("Flyer successfully posted.")
            }
        }
    }
}

// MARK: - Flyer Conversation
extension FlyerController {
    func fetchOrCreateConversation(
        contractorId: String,
        homeownerId: String,
        flyerId: String,
        completion: @escaping (String?) -> Void
    ) {
        let sortedIds = [contractorId, homeownerId].sorted()
        let conversationId = sortedIds.joined(separator: "_")

        let conversationRef = Firestore.firestore().collection("conversations").document(conversationId)

        conversationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching conversation: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                print("Conversation already exists: \(conversationId)")
                completion(conversationId)
                return
            }

            let conversationData: [String: Any] = [
                "id": conversationId,
                "participants": [contractorId, homeownerId],
                "lastMessage": "",
                "lastMessageTimestamp": Date(),
                "flyerId": flyerId
            ]

            conversationRef.setData(conversationData) { error in
                if let error = error {
                    print("Error creating conversation: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    print("New conversation created: \(conversationId)")
                    completion(conversationId)
                }
            }
        }
    }
}

// MARK: - Flyer Extension
extension FlyerController {
    func fetchContractorProfile(contractorId: String, completion: @escaping (ContractorProfile?) -> Void) {
        let db = Firestore.firestore()
        db.collection("flyers")
            .whereField("contractorId", isEqualTo: contractorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching contractor profile: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("No contractor profile found for contractorId: \(contractorId)")
                    completion(nil)
                    return
                }

                let data = document.data()
                let profile = ContractorProfile(
                    id: UUID(uuidString: document.documentID) ?? UUID(),
                    contractorId: contractorId,
                    contractorName: data["contractorName"] as? String ?? "Unknown Contractor",
                    bio: data["bio"] as? String ?? "No Bio",
                    skills: data["skills"] as? [String] ?? [],
                    rating: data["rating"] as? Double ?? 0.0,
                    jobsCompleted: data["jobsCompleted"] as? Int ?? 0,
                    city: data["city"] as? String ?? "Unknown City",
                    email: data["email"] as? String ?? "Unknown Email",
                    imageURL: data["imageURL"] as? String
                )
                completion(profile)
            }
    }
}

extension FlyerController {
    func fetchFlyerByConversation(conversationId: String, completion: @escaping (ContractorProfile?) -> Void) {
        let db = Firestore.firestore()

        // Step 1: Fetch the conversation document
        let conversationRef = db.collection("conversations").document(conversationId)
        conversationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching conversation: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = snapshot?.data(),
                  let flyerId = data["flyerId"] as? String else {
                print("No flyerId found in conversation.")
                completion(nil)
                return
            }

            // Step 2: Fetch the flyer document
            let flyerRef = db.collection("flyers").document(flyerId)
            flyerRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching flyer: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let flyerData = snapshot?.data() else {
                    print("No flyer found for flyerId: \(flyerId)")
                    completion(nil)
                    return
                }

                // Step 3: Map the flyer data
                let flyer = ContractorProfile(
                    id: UUID(uuidString: flyerId) ?? UUID(),
                    contractorId: flyerData["contractorId"] as? String ?? "",
                    contractorName: flyerData["contractorName"] as? String ?? "Unknown Contractor",
                    bio: flyerData["bio"] as? String ?? "No Bio",
                    skills: flyerData["skills"] as? [String] ?? [],
                    rating: flyerData["rating"] as? Double ?? 0.0,
                    jobsCompleted: flyerData["jobsCompleted"] as? Int ?? 0,
                    city: flyerData["city"] as? String ?? "Unknown City",
                    email: flyerData["email"] as? String ?? "Unknown Email",
                    imageURL: flyerData["imageURL"] as? String
                )
                completion(flyer)
            }
        }
    }
}
extension FlyerController {
    func fetchFlyerByContractorId(contractorId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        db.collection("flyers")
            .whereField("contractorId", isEqualTo: contractorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching flyer for contractorId \(contractorId): \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("No flyer found for contractorId \(contractorId)")
                    completion(nil)
                    return
                }

                let flyerId = document.documentID
                completion(flyerId)
            }
    }
}
