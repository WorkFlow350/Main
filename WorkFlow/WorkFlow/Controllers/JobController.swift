import Firebase
import FirebaseStorage
import Combine

// MARK: - JobController
class JobController: ObservableObject {
    @Published var jobsNotification: [Job] = []
    @Published var jobs: [Job] = []
    @Published var notifications: [NotificationModel] = []

    private var listener: ListenerRegistration?
    private var listener2: ListenerRegistration?

    // MARK: - Add Notification
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

    // MARK: - Initializer
    init() {
        observeJobs()
        observeNotifications()
    }

    // MARK: - Deinitializer
    deinit {
        listener?.remove()
        listener2?.remove()
    }

    // MARK: - Observe Jobs
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
                    
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString) else {
                        return print("Could not get job ID")
                    }
                        
                    guard let title = data["title"] as? String else {
                        return print("Could not get title")
                    }
                    
                    
                    guard let number = data["number"] as? String else {
                        return print("Could not get number") // Add this line
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
                    let latitude = data["latitude"] as? Double ?? 0.0
                    let longitude = data["longitude"] as? Double ?? 0.0
                    let newJob = Job(id: id,
                                     title: title,
                                     number: number,
                                     description: description,
                                     city: city,
                                     category: category,
                                     datePosted: datePosted,
                                     imageURL: imageURL,
                                     latitude: latitude ?? 0.0,
                                     longitude: longitude ?? 0.0)
                    self.jobsNotification.append(newJob)
                }
            }
        }
    }

    // MARK: - Observe Notifications
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

    // MARK: - Fetch Jobs
    func fetchJobs() {
        let db = Firestore.firestore()
        db.collection("jobs").order(by: "datePosted", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching jobs: \(error.localizedDescription)")
                return
            }

            self.jobs = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Job(
                    id: UUID(uuidString: document.documentID) ?? UUID(),
                    title: data["title"] as? String ?? "",
                    number: data["number"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    category: JobCategory(rawValue: data["category"] as? String ?? "Landscaping") ?? .landscaping,
                    datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                    imageURL: data["imageURL"] as? String,
                    latitude: data["latitude"] as? Double ?? 0.0,
                    longitude: data["longitude"] as? Double ?? 0.0
                )
            } ?? []

            print("Total jobs fetched: \(self.jobs.count)")
        }
    }

    // MARK: - Post Job
    func postJob(job: Job, selectedImage: UIImage?) {
        if let selectedImage = selectedImage {
            uploadImage(selectedImage) { [weak self] imageURL in
                guard let self = self else { return }

                if let imageURL = imageURL {
                    self.saveJobToFirestore(job: job, imageURL: imageURL)
                } else {
                    print("Error: Could not upload image.")
                }
            }
        } else {
            saveJobToFirestore(job: job, imageURL: nil)
        }
    }

    // MARK: - Upload Image
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("job_images/\(UUID().uuidString).jpg")
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

    // MARK: - Save Job to Firestore
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
    //MARK: - get single job
    func fetchSingleJob(bidJobId: String, completion: @escaping (Job?) -> Void) {
        let db = Firestore.firestore()
        db.collection("jobs").whereField("id", isEqualTo: bidJobId).getDocuments { snapshot, error in
            if let error = error {
                print("Error getting single job: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No job found for bidJobId: \(bidJobId)")
                completion(nil)
                return
            }
            
            let data = document.data()
            let job = Job(
                id: UUID(uuidString: document.documentID) ?? UUID(),
                title: data["title"] as? String ?? "",
                number: data["number"] as? String ?? "",
                description: data["description"] as? String ?? "",
                city: data["city"] as? String ?? "",
                category: JobCategory(rawValue: data["category"] as? String ?? "Landscaping") ?? .landscaping,
                datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                imageURL: data["imageURL"] as? String,
                latitude: data["latitude"] as? Double ?? 0.0,
                longitude: data["longitude"] as? Double ?? 0.0
            )
            completion(job)
        }
    }

    // MARK: - Time Ago Since Date
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
