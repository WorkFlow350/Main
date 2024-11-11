import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine

// MARK: - HomeownerJobController
class HomeownerJobController: ObservableObject {
    @Published var homeownerJobs: [Job] = []
    private var listener: ListenerRegistration?
    private let storage = Storage.storage()

    // MARK: - Fetch Jobs for Homeowner
    func fetchJobsForHomeowner(homeownerId: String) {
        let db = Firestore.firestore()
        listener = db.collection("jobs")
            .whereField("homeownerId", isEqualTo: homeownerId)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching homeowner jobs: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else { return }
                self.homeownerJobs = snapshot.documents.compactMap { document in
                    let data = document.data()
                    print("Fetched job data: \(data)")
                    return Job(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        category: JobCategory(rawValue: data["category"] as? String ?? "Landscaping") ?? .landscaping,
                        datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                        imageURL: data["imageURL"] as? String
                    )
                }
                print("Total jobs fetched: \(self.homeownerJobs.count)") // Debug print
            }
    }

    // MARK: - Upload Image
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let imageRef = storage.reference().child("job_images/\(UUID().uuidString).jpg")
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

    // MARK: - Post Job
    func postJob(job: Job, selectedImage: UIImage?) {
        let db = Firestore.firestore()
        var jobData: [String: Any] = [
            "id": job.id.uuidString,
            "title": job.title,
            "description": job.description,
            "city": job.city,
            "category": job.category.rawValue,
            "datePosted": Timestamp(date: job.datePosted),
            "imageURL": job.imageURL,
            "homeownerId": Auth.auth().currentUser?.uid ?? ""
        ]
        //!!!I changed the bottom comment to get the right document!!!
        //db.collection("jobs").addDocument(data: jobData) { error in
        db.collection("jobs").document(job.id.uuidString).setData(jobData) {error in 
            if let error = error {
                print("Error posting job: \(error.localizedDescription)")
            } else {
                print("Job successfully posted.")
                if let homeownerId = Auth.auth().currentUser?.uid {
                    self.fetchJobsForHomeowner(homeownerId: homeownerId)
                }
            }
        }
    }

    // MARK: - Deinitializer
    deinit {
        listener?.remove()
    }
}
