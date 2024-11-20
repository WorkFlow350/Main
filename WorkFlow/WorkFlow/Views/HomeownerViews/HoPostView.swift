import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth

// MARK: - HoPostView
struct HoPostView: View {
    // MARK: - State Variables
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var city: String = ""
    @State private var number: String = ""
    @State private var email: String = ""
    @State private var selectedCategories: [JobCategory] = []
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var isCategoryPickerPresented: Bool = false
    @State private var isDescriptionEditorPresented: Bool = false

    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController

    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            gradientBackground

            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Post Job")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        Spacer()
                    }
                    jobDetailsSection
                    imagePickerSection
                    postButton
                    Spacer()
                }
                .padding()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .overlay(
                CustomDescriptionPopup(
                    isPresented: $isDescriptionEditorPresented,
                    description: $description,
                    title: "Enter your job description"
                )
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.endEditing()
                    }
                }
            }
        }
    }

    // MARK: - Background Gradient
    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                Color.black.opacity(0.99)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Job Details Section
    private var jobDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Job Details")
                .font(.headline)
                .foregroundColor(.white)

            jobTitleField
            cityField
            phoneTitleField
            descriptionButton
            categoryPickerButton
        }
        .padding()
    }

    private var jobTitleField: some View {
        TextField("Title", text: $title)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .onChange(of: title) {
                if title.count > 20 {
                    title = String(title.prefix(20))
                }
            }
    }
    
    private var phoneTitleField: some View {
        TextField("Phone Number", text: $number)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .onChange(of: title) {
                if title.count > 20 {
                    title = String(title.prefix(20))
                }
            }
    }

    private var cityField: some View {
        TextField("City", text: $city)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .onChange(of: city) {
                if city.count > 20 {
                    city = String(city.prefix(20))
                }
            }
    }

    private var descriptionButton: some View {
        Button(action: {
            isDescriptionEditorPresented = true
        }) {
            HStack {
                Text(description.isEmpty ? "Description" : description)
                    .foregroundColor(description.isEmpty ? .gray : .black)
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Category Picker
    private var categoryPickerButton: some View {
        DisclosureGroup(isExpanded: $isCategoryPickerPresented) {
            VStack(alignment: .leading) {
                ForEach(JobCategory.allCases, id: \.self) { category in
                    Button(action: {
                        if selectedCategories.contains(category) {
                            selectedCategories.removeAll { $0 == category }
                        } else {
                            selectedCategories.append(category)
                        }
                    }) {
                        HStack {
                            Text(category.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .padding(.horizontal)
        } label: {
            HStack {
                Text(selectedCategories.isEmpty ? "Select Job Type" : selectedCategories.map { $0.rawValue }.joined(separator: ", "))
                    .foregroundColor(.white)
                    .font(.body)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .cornerRadius(5)
        }
        .accentColor(.white)
        .background(Color.white.opacity(0.2))
        .cornerRadius(8)
    }

    // MARK: - Image Picker Section
    private var imagePickerSection: some View {
        VStack {
            Text("Add an Image")
                .font(.headline)
                .foregroundColor(.white)

            if let selectedImage = selectedImage {
                selectedImagePreview
            } else {
                selectImageButton
            }
        }
    }

    private var selectedImagePreview: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: selectedImage!)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .cornerRadius(10)
                .shadow(radius: 5)

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
    }

    private var selectImageButton: some View {
        Button(action: {
            isImagePickerPresented = true
        }) {
            Text("Select Image")
                .foregroundColor(.white)
                .font(.body)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.2))
                .cornerRadius(5)
        }
    }

    // MARK: - Post Button
    private var postButton: some View {
        Button(action: {
            if let selectedImage = selectedImage {
                homeownerJobController.uploadImage(selectedImage) { url in
                    if let url = url {
                        let newJob = Job(
                            id: UUID(),
                            title: title,
                            number: number,
                            description: description,
                            city: city,
                            category: selectedCategories.first ?? .landscaping,
                            datePosted: Date(),
                            imageURL: url
                        )
                        homeownerJobController.postJob(job: newJob, selectedImage: selectedImage)
                        resetFields()
                    } else {
                        print("Error uploading image for job.")
                    }
                }
            }
        }) {
            Text("Post")
                .frame(minWidth: 100, maxWidth: 200)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .foregroundColor(.white)
        }
        .disabled(title.isEmpty || description.isEmpty || city.isEmpty || number.isEmpty || selectedImage == nil)
        .padding(.horizontal)
        .padding(.vertical, 0)
        .padding(.bottom, 50)
    }

    // MARK: - Reset Fields
    private func resetFields() {
        title = ""
        description = ""
        number = ""
        city = ""
        email = ""
        selectedCategories = []
        selectedImage = nil
    }
}

// MARK: - Preview
struct HoPostView_Previews: PreviewProvider {
    static var previews: some View {
        HoPostView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
    }
}
