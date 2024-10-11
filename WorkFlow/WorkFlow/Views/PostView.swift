import SwiftUI
import PhotosUI
import FirebaseStorage

// View for posting jobs or contractor flyers
struct PostView: View {
    // State variables for job/flyer details
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var city: String = ""
    @State private var email: String = ""
    @State private var selectedCategory: JobCategory = .landscaping
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var isHomeowner: Bool = true
    @State private var isCategoryPickerPresented: Bool = false // State to show/hide category picker

    // Environment objects for accessing controllers
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController

    var body: some View {
        ZStack {
            // Add gradient background from light to dark blue
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all) // Ensure background covers entire screen

            ScrollView { // Wrap everything in a ScrollView
                VStack(spacing: 20) {
                    // Toggle between Homeowner and Contractor view
                    Picker("Post Type", selection: $isHomeowner) {
                        Text("Homeowner").tag(true)
                        Text("Contractor").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding() // Styling: Padding for the toggle

                    // Section for entering job or flyer details
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isHomeowner ? "Job Details" : "Flyer Details")
                            .font(.headline)
                            .foregroundColor(.white) // Make the header text white

                        // Custom styling for the text fields
                        TextField(isHomeowner ? "Title" : "Name", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15) // Rounded corners for text field
                        TextField(isHomeowner ? "Description" : "Bio", text: $description)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15) // Rounded corners for text field
                        TextField("City", text: $city)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15) // Rounded corners for text field
                        
                        if !isHomeowner {
                            TextField("Email", text: $email)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15) // Rounded corners for text field
                        }

                        // Button-style picker for category selection
                        Button(action: {
                            isCategoryPickerPresented = true // Show the category picker
                        }) {
                            HStack {
                                Text(selectedCategory.rawValue)
                                    .underline() // Underline to indicate interactivity
                                    .foregroundColor(.white) // White text color
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.down") // Dropdown indicator
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 15)
                            .background(Color.white.opacity(0.2)) // Light background for clarity
                            .cornerRadius(5) // Rounded corners
                        }
                        .sheet(isPresented: $isCategoryPickerPresented) {
                            VStack {
                                Picker("Select Category", selection: $selectedCategory) {
                                    ForEach(JobCategory.allCases, id: \.self) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .background(Color.white)
                                .cornerRadius(15)
                                .padding()
                                
                                Button("Done") {
                                    isCategoryPickerPresented = false
                                }
                                .padding()
                                .background(Color(hex: "#355c7d"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()

                    // Image picker section
                    VStack {
                        Text("Add an Image")
                            .font(.headline)
                            .foregroundColor(.white) // Make the header text white
                        if let selectedImage = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150) // Styling: Frame height for the image
                                    .cornerRadius(10) // Styling: Rounded corners for the image
                                    .shadow(radius: 5) // Styling: Shadow effect for the image
                                
                                // Red X button to delete the image
                                Button(action: {
                                    self.selectedImage = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding(5) // Add padding to position the button nicely
                            }
                        } else {
                            Button(action: {
                                isImagePickerPresented = true
                            }) {
                                Text("Select Image")
                                    .underline() // Add underline to indicate it's clickable
                                    .foregroundColor(.white) // Styling: Text color
                                    .font(.body)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2)) // Light background for clarity
                                    .cornerRadius(5) // Rounded corners
                            }
                        }
                    }
                    .padding()

                    // Button to post either a job or flyer with custom styling
                    Button(action: {
                        if let selectedImage = selectedImage {
                            if isHomeowner {
                                // Homeowner posting a job
                                jobController.uploadImage(selectedImage) { url in
                                    if let url = url {
                                        imageURL = url
                                        let newJob = Job(
                                            id: UUID(),
                                            title: title,
                                            description: description,
                                            city: city,
                                            category: selectedCategory,
                                            datePosted: Date(),
                                            imageURL: imageURL
                                        )
                                        jobController.postJob(job: newJob, selectedImage: selectedImage)
                                        resetFields()
                                    } else {
                                        print("Error uploading image for job.")
                                    }
                                }
                            } else {
                                // Contractor posting a flyer
                                contractorController.uploadImage(selectedImage) { url in
                                    if let url = url {
                                        imageURL = url
                                        let newFlyer = ContractorProfile(
                                            id: UUID(),
                                            contractorName: title,
                                            bio: description,
                                            skills: [selectedCategory.rawValue],
                                            rating: 0.0,
                                            jobsCompleted: 0,
                                            city: city,
                                            email: email,
                                            imageURL: imageURL
                                        )
                                        contractorController.postFlyer(profile: newFlyer, selectedImage: selectedImage)
                                        resetFields()
                                    } else {
                                        print("Error uploading image for flyer.")
                                    }
                                }
                            }
                        }
                    }) {
                        // Style for Post Button
                        Text("Post")
                            .frame(minWidth: 100, maxWidth: 200) // Change size of button
                            .padding()
                            .background(Color(hex: "#355c7d")) // Styling: Background color
                            .foregroundColor(.white) // Styling: Text color
                            .cornerRadius(10) // Styling: Rounded corners
                            .shadow(color: .gray, radius: 5, x: 0, y: 2) // Styling: Shadow effect
                    }
                    // Disable button based on required fields for each case
                    .disabled(isHomeowner ? title.isEmpty || description.isEmpty || city.isEmpty || selectedImage == nil : title.isEmpty || description.isEmpty || city.isEmpty || email.isEmpty || selectedImage == nil)
                    .padding()
                    Spacer()
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(isHomeowner ? "Post Job" : "Post Flyer")
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        KeyboardHelper.hideKeyboard()
                    }
                }
            }
            .padding()
        }
    }

    // Function to reset fields after posting
    private func resetFields() {
        title = ""
        description = ""
        city = ""
        email = ""
        selectedCategory = .landscaping
        selectedImage = nil
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}
