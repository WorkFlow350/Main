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
    @State private var email: String = ""
    @State private var selectedCategories: [JobCategory] = []
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var isCategoryPickerPresented: Bool = false
    @State private var isDescriptionEditorPresented: Bool = false

    // MARK: - Environment Objects
    @EnvironmentObject var homeownerJobController: HomeownerJobController
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
    }
    
    // MARK: - Category Picker
    private var categoryPickerButton: some View {
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
            categoryPicker
        }
    }

    private var categoryPicker: some View {
        VStack {
            Picker("Select Category", selection: Binding(
                get: { selectedCategories.first ?? JobCategory.landscaping },
                set: { newValue in selectedCategories = [newValue] }
            )) {
                ForEach(JobCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .background(.white)
            .cornerRadius(20)
            .padding()

            Button("Done") {
                isCategoryPickerPresented = false
            }
            .padding()
            .background(LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
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
                .underline()
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
                .shadow(color: .white, radius: 2, x: 0, y: 0)
        }
        .disabled(title.isEmpty || description.isEmpty || city.isEmpty || selectedImage == nil)
        .padding(.horizontal)
        .padding(.vertical, 0)
    }

    // MARK: - Reset Fields
    private func resetFields() {
        title = ""
        description = ""
        city = ""
        email = ""
        selectedCategories = []
        selectedImage = nil
    }
}

// MARK: - Preview
struct HoPostView_Previews: PreviewProvider {
    static var previews: some View {
        HoPostView().environmentObject(HomeownerJobController()).environmentObject(ContractorController()).environmentObject(AuthController())
    }
}
