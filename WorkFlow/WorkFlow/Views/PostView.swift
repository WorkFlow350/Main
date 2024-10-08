import SwiftUI
import PhotosUI
import FirebaseStorage

// PostView allows the user to post a job, including job details and an optional image
struct PostView: View {
    // State variables for job details
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var city: String = ""  // New city field
    @State private var selectedCategory: JobCategory = .landscaping // Default category
    @State private var selectedImage: UIImage? = nil // Image state
    @State private var imageURL: String = "" // Store image URL
    @State private var isImagePickerPresented: Bool = false // Control image picker presentation

    @EnvironmentObject var jobController: JobController // Access the JobController

    var body: some View {
        NavigationView {
            Form {
                // Section for entering job details
                Section(header: Text("Job Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    TextField("City", text: $city)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(JobCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                // Image picker section
                Section(header: Text("Add an Image")) {
                    if let selectedImage = selectedImage {
                        // Display the selected image
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    } else {
                        // Button to select an image
                        Button("Select Image") {
                            isImagePickerPresented = true // Show image picker when button is tapped
                        }
                    }
                }

                // Button to post the job
                Button("Post Job") {
                    // If an image is selected, upload it before posting the job
                    if let selectedImage = selectedImage {
                        uploadImage(selectedImage) { url in
                            if let url = url {
                                imageURL = url
                                // Create a new job with the provided details
                                let newJob = Job(
                                    id: UUID(),
                                    title: title,
                                    description: description,
                                    city: city,
                                    category: selectedCategory,
                                    datePosted: Date(),
                                    imageURL: imageURL
                                )
                                // Post the job using the jobController
                                jobController.postJob(job: newJob, selectedImage: selectedImage)

                                // Reset the fields after posting
                                resetFields()
                            }
                        }
                    }
                }
                .disabled(title.isEmpty || description.isEmpty || city.isEmpty || selectedImage == nil) // Disable button if fields are empty
            }
            .navigationTitle("Post Job")
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage) // Show image picker and bind selected image
            }
            .toolbar {
                // Toolbar with a Done button to hide the keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        KeyboardHelper.hideKeyboard() // Hide the keyboard when Done is tapped
                    }
                }
            }
        }
    }

    // Function to reset fields after posting the job
    private func resetFields() {
        title = ""
        description = ""
        city = ""
        selectedCategory = .landscaping
        selectedImage = nil
    }

    // Function to upload image to Firebase Storage and return the URL
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        // Reference for the image in Firebase Storage with a unique ID
        let storageRef = Storage.storage().reference().child("job_images/\(UUID().uuidString).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Upload image data to Firebase Storage
            storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if error == nil {
                    // Fetch download URL after successful upload
                    storageRef.downloadURL { (url, error) in
                        completion(url?.absoluteString)
                    }
                } else {
                    // Return nil if there's an error
                    completion(nil)
                }
            }
        } else {
            completion(nil) // Return nil if image data couldn't be created
        }
    }
}

// Preview provider for PostView
struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView().environmentObject(JobController())
    }
}

