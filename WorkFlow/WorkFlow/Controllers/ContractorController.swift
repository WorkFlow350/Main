// ContractorController.swift - Manages contractor flyer data and image uploads using Firestore and Firebase Storage.
import Firebase
import FirebaseStorage
import Combine

// ObservableObject to allow ContractorController to be observed by SwiftUI views.
class ContractorController: ObservableObject {
    // Published property to hold contractor flyers, allowing UI to update when data changes.
    @Published var flyers: [ContractorProfile] = []

    // Fetches contractor flyers from Firestore and updates the 'flyers' array.
    func fetchFlyers() {
        let db = Firestore.firestore()
        db.collection("flyers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching flyers: \(error.localizedDescription)")
                return
            }
            
            // Converts Firestore documents into ContractorProfile models.
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

            // Debugging: Print total flyers fetched to the console.
            print("Total flyers fetched: \(self.flyers.count)")
        }
    }

    // Posts a new contractor flyer to Firestore, with optional image upload to Firebase Storage.
    func postFlyer(profile: ContractorProfile, selectedImage: UIImage?) {
        if let selectedImage = selectedImage {
            // Uploads the image first if provided.
            uploadImage(selectedImage) { [weak self] imageURL in
                guard let self = self else { return }
                
                if let imageURL = imageURL {
                    self.saveFlyerToFirestore(profile: profile, imageURL: imageURL)
                } else {
                    print("Error: Could not upload image.")
                }
            }
        } else {
            // Saves the flyer without an image URL.
            saveFlyerToFirestore(profile: profile, imageURL: nil)
        }
    }

    // Uploads an image to Firebase Storage and returns its URL.
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("flyer_images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG format.")
            completion(nil)
            return
        }

        // Uploads image to Firebase Storage.
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Gets the download URL for the uploaded image.
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

    // Saves flyer data to Firestore, optionally with an image URL.
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

        // Adds imageURL if available.
        if let imageURL = imageURL {
            flyerData["imageURL"] = imageURL
        }

        // Saves the flyer data to the Firestore database.
        db.collection("flyers").addDocument(data: flyerData) { error in
            if let error = error {
                print("Error posting flyer: \(error.localizedDescription)")
            } else {
                print("Flyer successfully posted.")
            }
        }
    }
}
