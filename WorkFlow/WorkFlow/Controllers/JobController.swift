// JobController.swift - Manages job data, image uploads, and notifications using Firestore and Firebase Storage.
import Firebase
import FirebaseStorage
import Combine

// ObservableObject to allow JobController to be observed by SwiftUI views.
class JobController: ObservableObject {
    // Published properties for dynamic UI updates when data changes.
    @Published var jobsNotification: [Job] = []  // Stores job data linked to notifications.
    @Published var jobs: [Job] = []              // Stores all fetched job data.
    @Published var notifications: [NotificationModel] = []  // Stores notification data.

    private var listener: ListenerRegistration?  // Firestore listener for jobs collection.
    private var listener2: ListenerRegistration? // Firestore listener for notifications collection.

    // Adds a new notification to Firestore when a job is posted.
    func addNotification(_ job: Job) {
        let notification = NotificationModel(id: UUID(), jobId: job.id, message: "A new \(job.category) job has been posted in \(job.city)!")
        let db = Firestore.firestore()
        var jobData: [String: Any] = [
            "id": notification.id.uuidString,
            "jobId": notification.jobId.uuidString,
            "message": notification.message,
        ]
        db.collection("notifications").addDocument(data: jobData) { error in
            if let error = error {
                print("Error posting notification: \(error.localizedDescription)")
            } else {
                print("Notification successfully posted.")
            }
        }
    }
    
    // Initializes the controller and sets up listeners for job and notification data.
    init() {
        observeJobs()
        observeNotifications()
    }
    
    // Deinitializes the controller and removes Firestore listeners.
    deinit {
        listener?.remove()
        listener2?.remove()
    }
    
    // Observes job postings in Firestore, updating 'jobsNotification' with new jobs.
    func observeJobs() {
        let db = Firestore.firestore()
        listener = db.collection("jobs").addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching jobs: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            for diff in snapshot.documentChanges {
                if diff.type == .added {
                    let data = diff.document.data()
                    
                    // Parse job data from Firestore document.
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString) else {
                        return print("Could not get job ID")
                    }
                        
                    guard let title = data["title"] as? String else {
                        return print("Could not get title")
                    }
                    
                    guard let description = data["description"] as? String else {
                        return print("Could not get description")
                    }
                    
                    guard let city = data["city"] as? String else {
                        return print("Could not get city")
                    }
                    
                    guard let categoryString = data["category"] as? String,
                          let category = JobCategory(rawValue: categoryString) else {
                        return print("Could not get job category")
                    }
                    
                    guard let timestamp = data["datePosted"] as? Timestamp else {
                        return print("Could not get date")
                    }
                    
                    let datePosted = timestamp.dateValue()
                    
                    guard let imageURL = data["imageURL"] as? String else {
                        return print("Could not get job data")
                    }
                    
                    let newJob = Job(id: id,
                                     title: title,
                                     description: description,
                                     city: city,
                                     category: category,
                                     datePosted: datePosted,
                                     imageURL: imageURL)
                    
                    self.jobsNotification.append(newJob)
                }
            }
        }
    }
    
    // Observes notifications in Firestore, updating 'notifications' with new notifications.
    func observeNotifications() {
        let db = Firestore.firestore()
        listener2 = db.collection("notifications").addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching notifications: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            for diff in snapshot.documentChanges {
                if diff.type == .added {
                    let data = diff.document.data()
                    
                    // Parse notification data from Firestore document.
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString) else {
                        return print("Could not get notification ID")
                    }
                    
                    guard let jobIdString = data["jobId"] as? String,
                          let jobId = UUID(uuidString: jobIdString) else {
                        return print("Could not get job ID")
                    }
                    
                    guard let message = data["message"] as? String else {
                        return print("Could not get message")
                    }
                    
                    let newNotification = NotificationModel(id: id,
                                                            jobId: jobId,
                                                            message: message)
                    
                    self.notifications.append(newNotification)
                    NotificationCenter.default.post(name: Notification.Name("NewJobPosted"), object: nil)
                }
            }
        }
    }

    // Fetches jobs from Firestore, ordered by the date posted.
    func fetchJobs() {
        let db = Firestore.firestore()
        db.collection("jobs").order(by: "datePosted", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching jobs: \(error.localizedDescription)")
                return
            }
            
            // Convert Firestore documents into Job models.
            self.jobs = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Job(
                    id: UUID(uuidString: document.documentID) ?? UUID(),
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    category: JobCategory(rawValue: data["category"] as? String ?? "Landscaping") ?? .landscaping,
                    datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                    imageURL: data["imageURL"] as? String
                )
            } ?? []

            print("Total jobs fetched: \(self.jobs.count)")
        }
    }

    // Posts a new job to Firestore, with optional image upload to Firebase Storage.
    func postJob(job: Job, selectedImage: UIImage?) {
        if let selectedImage = selectedImage {
            // Upload the image first if provided.
            uploadImage(selectedImage) { [weak self] imageURL in
                guard let self = self else { return }
                
                if let imageURL = imageURL {
                    self.saveJobToFirestore(job: job, imageURL: imageURL)
                } else {
                    print("Error: Could not upload image.")
                }
            }
        } else {
            // Save the job without an image URL.
            saveJobToFirestore(job: job, imageURL: nil)
        }
    }

    // Uploads an image to Firebase Storage and returns its URL.
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("job_images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG format.")
            completion(nil)
            return
        }

        // Upload image to Firebase Storage.
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Get the download URL for the uploaded image.
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

    // Saves job data to Firestore, optionally with an image URL.
    private func saveJobToFirestore(job: Job, imageURL: String?) {
        let db = Firestore.firestore()
        var jobData: [String: Any] = [
            "id": job.id.uuidString,
            "title": job.title,
            "description": job.description,
            "city": job.city,
            "category": job.category.rawValue,
            "datePosted": Timestamp(date: job.datePosted)
        ]

        if let imageURL = imageURL {
            jobData["imageURL"] = imageURL
        }

        db.collection("jobs").addDocument(data: jobData) { error in
            if let error = error {
                print("Error posting job: \(error.localizedDescription)")
            } else {
                print("Job successfully posted.")
            }
        }
    }
    
    // Utility function to calculate time elapsed since a given date.
    func timeAgoSinceDate(_ date: Date) -> String {
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
}
