import Firebase
import FirebaseStorage
import Combine
import SwiftUI

// ObservableObject to allow ContractorController to be observed by SwiftUI views
class ContractorController: ObservableObject {
    // Published property so any updates to 'flyers' will automatically update views that observe this controller
    @Published var flyers: [ContractorProfile] = []
    private var db = Firestore.firestore() // added by KR
    @Published var noResults: Bool = false //added by KR

    // Function to fetch flyers from Firestore database
    func fetchFlyers() {
        let db = Firestore.firestore()
        db.collection("flyers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching flyers: \(error.localizedDescription)")
                return
            }
            
            // Convert Firestore documents into ContractorProfile models
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

            // Debugging: Print total flyers fetched to the console
            print("Total flyers fetched: \(self.flyers.count)")
        }
    }

    // Function to post a new contractor flyer to Firestore with optional image upload
    func postFlyer(profile: ContractorProfile, selectedImage: UIImage?) {
        if let selectedImage = selectedImage {
            // If there's an image, upload it to Firebase Storage first
            uploadImage(selectedImage) { [weak self] imageURL in
                guard let self = self else { return }
                
                if let imageURL = imageURL {
                    // Once image is uploaded, save flyer to Firestore with imageURL
                    self.saveFlyerToFirestore(profile: profile, imageURL: imageURL)
                } else {
                    print("Error: Could not upload image.")
                }
            }
        } else {
            // If no image, save the flyer without an image URL
            saveFlyerToFirestore(profile: profile, imageURL: nil)
        }
    }

    // Change this function's access level to make it accessible
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("flyer_images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG format.")
            completion(nil)
            return
        }

        // Upload image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Get the download URL for the uploaded image
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)  // Return image URL
                }
            }
        }
    }

    // Function to save flyer details to Firestore, optionally with an image URL
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

        // Add imageURL if available
        if let imageURL = imageURL {
            flyerData["imageURL"] = imageURL
        }

        // Save the flyer data to the Firestore database
        db.collection("flyers").addDocument(data: flyerData) { error in
            if let error = error {
                print("Error posting flyer: \(error.localizedDescription)")
            } else {
                print("Flyer successfully posted.")
            }
        }
    }
    
    //seach Contractor Flyers for SearchView added by KR
    func searchContractors(by city: String, skills: String, completion: @escaping (Result<[ContractorProfile], Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("flyers")
            .whereField("city", isEqualTo: city)
            .whereField("skills", arrayContains: skills)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let flyers = snapshot?.documents.compactMap { document -> ContractorProfile? in
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
                    self.flyers = flyers
                    completion(.success(flyers))
                }
            }
    }
    
    func clearFlyers() {  //for searchContractorFlyers function added by KR
        self.flyers = []
    }
}
