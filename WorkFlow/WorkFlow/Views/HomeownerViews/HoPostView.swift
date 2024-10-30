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
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController
    

    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Job Details Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Job Details")
                            .font(.headline)
                            .foregroundColor(.white)

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
                        // MARK: - Category Picker Section
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
                                Picker("Select Category", selection: Binding(
                                    get: {
                                        selectedCategories.first ?? JobCategory.landscaping
                                    },
                                    set: { newValue in
                                        selectedCategories = [newValue]
                                    }
                                )) {
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

                    // MARK: - Image Picker Section
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

                    // MARK: - Post Button
                    Button(action: {
                        if let selectedImage = selectedImage {
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
                                    updateHomeownerProfileJobs(newJob)
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
                            .background(Color(hex: "#355c7d"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .gray, radius: 5, x: 0, y: 2)
                    }
                    .disabled(title.isEmpty || description.isEmpty || city.isEmpty || selectedImage == nil)
                    .padding(.horizontal)
                    .padding(.vertical, 0)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Post Job")
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
    
    // MARK: - Post Job To Profile
    private func updateHomeownerProfileJobs(_ job: Job) {
        NotificationCenter.default.post(name: Notification.Name("NewJobPosted"), object: job)
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
        HoPostView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}
