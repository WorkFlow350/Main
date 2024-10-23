// PostView.swift - Allows users to post jobs or contractor flyers, with options to add details, categories, and images.
import SwiftUI
import PhotosUI
import FirebaseStorage

// View for posting jobs or contractor flyers.
struct PostView: View {
    // State variables for job/flyer details.
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var city: String = ""
    @State private var email: String = ""
    @State private var selectedCategories: [JobCategory] = []  // Multiple categories for contractors.
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var isHomeowner: Bool = true
    @State private var isCategoryPickerPresented: Bool = false  // State to show/hide category picker.
    @State private var isDescriptionEditorPresented: Bool = false  // State for description popup.

    // Environment objects for accessing controllers.
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController

    var body: some View {
        ZStack {
            // Background gradient from light to dark blue.
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // Toggle between Homeowner and Contractor view.
                    Picker("Post Type", selection: $isHomeowner) {
                        Text("Homeowner").tag(true)
                        Text("Contractor").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // Section for entering job or flyer details.
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isHomeowner ? "Job Details" : "Flyer Details")
                            .font(.headline)
                            .foregroundColor(.white)

                        // Custom text field for title or name.
                        TextField(isHomeowner ? "Title" : "Name", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            .onChange(of: title) {
                                if title.count > 20 {
                                    title = String(title.prefix(20))  // Limit title to 20 characters.
                                }
                            }

                        // Custom text field for city.
                        TextField("City", text: $city)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            .onChange(of: city) {
                                if city.count > 20 {
                                    city = String(city.prefix(20))  // Limit city name to 20 characters.
                                }
                            }

                        // Email field (visible for contractors only).
                        if !isHomeowner {
                            TextField("Email", text: $email)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                .onChange(of: email) {
                                    if email.count > 20 {
                                        email = String(email.prefix(20))  // Limit email to 20 characters.
                                    }
                                }
                        }

                        // Description button styled like an input field.
                        Button(action: {
                            isDescriptionEditorPresented = true
                        }) {
                            HStack {
                                Text(description.isEmpty ? (isHomeowner ? "Description" : "Bio") : description)
                                    .foregroundColor(description.isEmpty ? .gray : .black)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Image(systemName: "arrow.up.backward.and.arrow.down.forward.rectangle")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }

                        // Button-style picker for category selection.
                        if !isHomeowner {
                            // For contractors, allow multiple skill selection.
                            Button(action: {
                                isCategoryPickerPresented = true
                            }) {
                                HStack {
                                    Text(selectedCategories.isEmpty ? "Select Skills" : selectedCategories.map { $0.rawValue }.joined(separator: ", "))
                                        .foregroundColor(.white)
                                        .font(.body)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 15)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(5)
                            }
                            .sheet(isPresented: $isCategoryPickerPresented) {
                                MultiCategoryPicker(selectedCategories: $selectedCategories, isPresented: $isCategoryPickerPresented)
                            }
                        } else {
                            // For homeowners, allow single category selection.
                            Button(action: {
                                isCategoryPickerPresented = true
                            }) {
                                HStack {
                                    Text(selectedCategories.first?.rawValue ?? "Select Category")
                                        .foregroundColor(.white)
                                        .font(.body)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 15)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(5)
                            }
                            .sheet(isPresented: $isCategoryPickerPresented) {
                                VStack {
                                    Picker("Select Category", selection: $selectedCategories.first!) {
                                        ForEach(JobCategory.allCases, id: \.self) { category in
                                            Text(category.rawValue).tag(category as JobCategory?)
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
                    }
                    .padding()

                    // Image picker section.
                    VStack {
                        Text("Add an Image")
                            .font(.headline)
                            .foregroundColor(.white)

                        if let selectedImage = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)

                                // Red X button to delete the image.
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
                                .padding(5)
                            }
                        } else {
                            // Button to select image.
                            Button(action: {
                                isImagePickerPresented = true
                            }) {
                                Text("Select Image")
                                    .underline()
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(5)
                            }
                        }
                    }

                    // Post Button.
                    Button(action: {
                        if let selectedImage = selectedImage {
                            if isHomeowner {
                                // Upload job for homeowners.
                                jobController.uploadImage(selectedImage) { url in
                                    if let url = url {
                                        let newJob = Job(
                                            id: UUID(),
                                            title: title,
                                            description: description,
                                            city: city,
                                            category: selectedCategories.first ?? .landscaping,
                                            datePosted: Date(),
                                            imageURL: url
                                        )
                                        jobController.postJob(job: newJob, selectedImage: selectedImage)
                                        jobController.addNotification(newJob)
                                        resetFields()
                                    } else {
                                        print("Error uploading image for job.")
                                    }
                                }
                            } else {
                                // Upload flyer for contractors.
                                contractorController.uploadImage(selectedImage) { url in
                                    if let url = url {
                                        let newFlyer = ContractorProfile(
                                            id: UUID(),
                                            contractorName: title,
                                            bio: description,
                                            skills: selectedCategories.map { $0.rawValue },
                                            rating: 0.0,
                                            jobsCompleted: 0,
                                            city: city,
                                            email: email,
                                            imageURL: url
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
                        Text("Post")
                            .frame(minWidth: 100, maxWidth: 200)
                            .padding()
                            .background(Color(hex: "#355c7d"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .gray, radius: 5, x: 0, y: 2)
                    }
                    .disabled(isHomeowner ? title.isEmpty || description.isEmpty || city.isEmpty || selectedImage == nil : title.isEmpty || description.isEmpty || city.isEmpty || email.isEmpty || selectedImage == nil)
                    .padding(.horizontal)
                    .padding(.vertical, 0)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(isHomeowner ? "Post Job" : "Post Flyer")
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .overlay(
                CustomDescriptionPopup(
                    isPresented: $isDescriptionEditorPresented,
                    description: $description,
                    title: isHomeowner ? "Enter your job description" : "Enter your bio"
                )
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.endEditing()  // Hide the keyboard.
                    }
                }
            }
        }
    }

    // Function to reset fields after posting.
    private func resetFields() {
        title = ""
        description = ""
        city = ""
        email = ""
        selectedCategories = []
        selectedImage = nil
    }
}

// MultiCategoryPicker for contractors to select multiple skills.
struct MultiCategoryPicker: View {
    @Binding var selectedCategories: [JobCategory]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(JobCategory.allCases, id: \.self) { category in
                    MultipleSelectionRow(title: category.rawValue, isSelected: selectedCategories.contains(category)) {
                        if selectedCategories.contains(category) {
                            selectedCategories.removeAll { $0 == category }
                        } else {
                            selectedCategories.append(category)
                        }
                    }
                }
            }
            .navigationBarTitle("Select Skills", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

// Row for multiple selection in picker.
struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

// Custom Popup View for Description/Bio.
struct CustomDescriptionPopup: View {
    @Binding var isPresented: Bool
    @Binding var description: String
    var title: String

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Text(title)
                        .font(.headline)

                    TextEditor(text: $description)
                        .frame(height: 150)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Done") {
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#355c7d"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .shadow(radius: 10)
            }
        }
    }
}

// Preview for PostView.
struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}
