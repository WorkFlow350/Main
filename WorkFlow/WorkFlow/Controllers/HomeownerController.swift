import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine
import CoreLocation

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
                guard let snapshot = snapshot else {
                    print("No snapshot received from Firestore.")
                    return
                }
                self.homeownerJobs = snapshot.documents.compactMap { document in
                    let data = document.data()
                    print("Fetched job data: \(data)")
                    return Job(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        title: data["title"] as? String ?? "",
                        number: data["number"] as? String ?? "Not provided",
                        description: data["description"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        category: JobCategory(rawValue: data["category"] as? String ?? "Landscaping") ?? .landscaping,
                        datePosted: (data["datePosted"] as? Timestamp)?.dateValue() ?? Date(),
                        imageURL: data["imageURL"] as? String,
                        latitude: data["latitude"] as? Double ?? 0.0,
                        longitude: data["longitude"] as? Double ?? 0.0
                    )
                }
                print("Total jobs fetched: \(self.homeownerJobs.count)")
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
        getCoordinates(for: job.city) { coordinates in
            let latitude = coordinates?.latitude ?? 0.0
            let longitude = coordinates?.longitude ?? 0.0

            let db = Firestore.firestore()
            var jobData: [String: Any] = [
                "id": job.id.uuidString,
                "title": job.title,
                "description": job.description,
                "city": job.city,
                "number": job.number,
                "category": job.category.rawValue,
                "datePosted": Timestamp(date: job.datePosted),
                "imageURL": job.imageURL,
                "homeownerId": Auth.auth().currentUser?.uid ?? "",
                "latitude": latitude,
                "longitude": longitude
            ]
            
            // Add the selected image URL if provided
            if let selectedImage = selectedImage {
                self.uploadImage(selectedImage) { imageURL in
                    if let imageURL = imageURL {
                        jobData["imageURL"] = imageURL
                    }
                    self.saveJobData(jobData, jobId: job.id.uuidString)
                }
            } else {
                self.saveJobData(jobData, jobId: job.id.uuidString)
            }
        }
    }

    private func saveJobData(_ jobData: [String: Any], jobId: String) {
        let db = Firestore.firestore()
        db.collection("jobs").document(jobId).setData(jobData) { error in
            if let error = error {
                print("Error posting job: \(error.localizedDescription)")
            } else {
                print("Job successfully posted with ID: \(jobId)")
                if let homeownerId = Auth.auth().currentUser?.uid {
                    self.fetchJobsForHomeowner(homeownerId: homeownerId)
                }
            }
        }
    }
    
    // MARK: - Get Location
    private func getCoordinates(for city: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { placemarks, error in
            if let error = error {
                print("Error geocoding city \(city): \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let placemark = placemarks?.first,
               let location = placemark.location {
                completion(location.coordinate)
            } else {
                print("No coordinates found for city \(city)")
                completion(nil)
            }
        }
    }
    
    // MARK: - Deinitializer
    deinit {
        listener?.remove()
    }
}
