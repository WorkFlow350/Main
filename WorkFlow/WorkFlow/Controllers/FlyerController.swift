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
                return ContractorProfile(
                    id: UUID(uuidString: document.documentID) ?? UUID(),
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

