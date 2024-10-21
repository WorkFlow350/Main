import Firebase
import FirebaseStorage
import Combine

// ObservableObject to allow JobController to be observed by SwiftUI views
class JobController: ObservableObject {
    // Published property so any updates to 'jobs' will automatically update views that observe this controller
    @Published var jobsNotification: [Job] = []
    @Published var jobs: [Job] = []
    @Published var notifications: [NotificationModel] = [] // Add notifications as a published property
    private var listener: ListenerRegistration?
    private var listener2: ListenerRegistration?
    @Published var noResults: Bool = false // added by KR

    // Method to add a new notification when a job is posted
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
                print("notification successfully posted.")
            }
        }
        // Post a notification that a new job has been added
    }
    
    init() {
        observeJobs()
        observeNotifications()
    }
    deinit {
        listener?.remove()
        listener2?.remove()
    }
    
    func observeJobs() {
        let db = Firestore.firestore()
        listener = db.collection("jobs").addSnapshotListener {(snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching jobs: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            for diff in snapshot.documentChanges {
                if diff.type == .added {
                    let Data = diff.document.data()
                    
                    guard let idString = Data["id"] as? String,
                          let id = UUID(uuidString: idString) else {
                        return print("could not get jobs id")
                    }
                        
                    guard let title = Data["title"] as? String else {
                        return print("could not get title")
                    }
                    
                   guard let description = Data["description"] as? String else {
                        return print("could not get description")
                    }
                    
                    guard let city = Data["city"] as? String else {
                        return print("could not get city")
                    }
                    guard let categoryString = Data["category"] as? String,
                          let category = JobCategory(rawValue: categoryString) else {
                        return print("could not get job category")
                    }
                    guard let timestamp = Data["datePosted"] as? Timestamp else {
                        return print("could not get date")
                    }
                    let datePosted = timestamp.dateValue()
                    
                    guard let imageURL = Data["imageURL"] as? String else{
                        return print("could not get job data")
                    }
                    
                    let newJob = Job(id: id,
                                     title: title,
                                     description: description,
                                     city: city,
                                     category: category,
                                     datePosted: datePosted,
                                     imageURL: imageURL
                    )
                    self.jobsNotification.append(newJob)
                }
            }
        }
    }
    
    func observeNotifications() {
        let db = Firestore.firestore()
        listener2 = db.collection("notifications").addSnapshotListener {(snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching notifications: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            for diff in snapshot.documentChanges {
                if diff.type == .added {
                    let Data = diff.document.data()
                    
                    guard let idString = Data["id"] as? String,
                          let id = UUID(uuidString: idString) else {
                        return print("could not get notification Id")
                    }
                    
                    guard let jobIdString = Data["jobId"] as? String,
                          let jobId = UUID(uuidString: jobIdString) else {
                        return print("could not get jobId")
                    }
                    
                    guard let message = Data["message"] as? String else {
                        return print("could not get message")
                    }
                    
                    let newNotification = NotificationModel(id: id,
                                                            jobId: jobId,
                                                            message: message
                    )
                    self.notifications.append(newNotification)
                    NotificationCenter.default.post(name: Notification.Name("NewJobPosted"), object: nil)
                }
            }
        }
    }

    // Function to fetch jobs from Firestore database
    func fetchJobs() {
        let db = Firestore.firestore()
        db.collection("jobs").order(by: "datePosted", descending: true).getDocuments { snapshot, error in
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

    // Change access level from private to internal (default) to make it accessible from PostView
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
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
            "id": job.id.uuidString,
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
    func timeAgoSinceDate(_ date: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full // Use "short" or "full" depending on your needs
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1 // Show only the largest unit (e.g., "2 hours" instead of "2 hours 5 minutes")
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if let formattedString = formatter.string(from: timeInterval) {
            return "\(formattedString) ago"
        } else {
            return "Just now"
        }
    }
    
    //searches Jobs function on SearchView added by KR
    func searchJobs(by city: String, category: JobCategory, completion: @escaping (Result<[Job], Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("jobs")
        //.order(by: "datePosted", descending: true)
            .whereField("city", isEqualTo: city)
            .whereField("category", isEqualTo: category.rawValue)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let jobs = snapshot?.documents.compactMap { document -> Job? in
                        let data = document.data()
                        return Job(
                            id: UUID(uuidString: document.documentID) ?? UUID(),
                            title: data["title"] as? String ?? "",
                            description: data["description"] as? String ?? "",
                            city: data["city"] as? String ?? "",
                            category: JobCategory(rawValue: data["category"] as? String ?? "") ?? .landscaping,
                            datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                            imageURL: data["imageURL"] as? String
                        )
                    } ?? []
                    self.jobs = jobs
                    completion(.success(jobs))
                }
            }
    }
    func clearJobs() {   //for searchJobs function added by KR
            self.jobs = []
        }
    }
