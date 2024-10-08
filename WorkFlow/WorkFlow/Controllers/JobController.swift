import Firebase
import FirebaseStorage
import Combine

// ObservableObject to allow JobController to be observed by SwiftUI views
class JobController: ObservableObject {
    // Published property so any updates to 'jobs' will automatically update views that observe this controller
    @Published var jobs: [Job] = []
    @Published var notifications: [String] = [] // Add notifications as a published property

    // Method to add a new notification when a job is posted
    func addNotification(_ message: String) {
        notifications.append(message)
        // Post a notification that a new job has been added
        NotificationCenter.default.post(name: Notification.Name("NewJobPosted"), object: nil)
    }
    // Function to fetch jobs from Firestore database
    func fetchJobs() {
        let db = Firestore.firestore()
        db.collection("jobs").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching jobs: \(error.localizedDescription)")
                return
            }
            
            // Convert Firestore documents into Job models
            self.jobs = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Job(
                    id: UUID(uuidString: document.documentID) ?? UUID(), // Generate UUID for each job
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    category: JobCategory(rawValue: data["category"] as? String ?? "Landscaping") ?? .landscaping,
                    datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                    imageURL: data["imageURL"] as? String
                )
            } ?? []

            // Debugging: Print total jobs fetched to the console
            print("Total jobs fetched: \(self.jobs.count)")
        }
    }

    // Function to post a new job to Firestore with optional image upload
    func postJob(job: Job, selectedImage: UIImage?) {
        if let selectedImage = selectedImage {
            // If there's an image, upload it to Firebase Storage first
            uploadImage(selectedImage) { [weak self] imageURL in
                guard let self = self else { return }
                
                if let imageURL = imageURL {
                    // Once image is uploaded, save job to Firestore with imageURL
                    self.saveJobToFirestore(job: job, imageURL: imageURL)
                } else {
                    print("Error: Could not upload image.")
                }
            }
        } else {
            // If no image, save the job without an image URL
            saveJobToFirestore(job: job, imageURL: nil)
        }
    }

    // Function to upload image to Firebase Storage
    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("job_images/\(UUID().uuidString).jpg")
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

    // Function to save job details to Firestore, optionally with an image URL
    private func saveJobToFirestore(job: Job, imageURL: String?) {
        let db = Firestore.firestore()
        var jobData: [String: Any] = [
            "title": job.title,
            "description": job.description,
            "city": job.city,
            "category": job.category.rawValue,
            "datePosted": Timestamp(date: job.datePosted)
        ]

        // Add imageURL if available
        if let imageURL = imageURL {
            jobData["imageURL"] = imageURL
        }

        // Save the job data to the Firestore database
        db.collection("jobs").addDocument(data: jobData) { error in
            if let error = error {
                print("Error posting job: \(error.localizedDescription)")
            } else {
                print("Job successfully posted.")
            }
        }
    }
}
