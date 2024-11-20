import SwiftUI
import PhotosUI
import FirebaseStorage

struct PostView: View {
    // MARK: - State Variables
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var number: String = ""
    @State private var city: String = ""
    @State private var email: String = ""
    @State private var selectedCategories: [JobCategory] = []
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var isHomeowner: Bool = true
    @State private var isCategoryPickerPresented: Bool = false
    @State private var isDescriptionEditorPresented: Bool = false
    @State private var showConfirmation: Bool = false

    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController

    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0), Color.black.opacity(0.99)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // Title Header
                    HStack {
                        Text(isHomeowner ? "Post Job" : "Post Flyer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 0)
                        Spacer()
                    }

                    // MARK: - Post Type Picker
                    Picker("Post Type", selection: $isHomeowner) {
                        Text("Homeowner").tag(true)
                        Text("Contractor").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    // MARK: - Job/Flyer Details Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isHomeowner ? "Job Details" : "Flyer Details")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField(isHomeowner ? "Title" : "Name", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        
                        TextField("City", text: $city)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        
                        if !isHomeowner {
                            TextField("Email", text: $email)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        }
                        Button(action: {
                              isDescriptionEditorPresented = true
                          }) {
                              HStack {
                                  Text(description.isEmpty ? "Description" : description)
                                      .foregroundColor(description.isEmpty ? .gray : .black)
                                      .lineLimit(1)
                                  Spacer()
                              }
                              .padding()
                              .background(Color.white)
                              .cornerRadius(15)
                              .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray, lineWidth: 1))
                          }                        // MARK: - Description Button
                        CategoryDropdown(selectedCategories: $selectedCategories)
                    }
                    // MARK: - Image Picker
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
                    Button(action: postAction) {
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
                    .disabled(isHomeowner ? title.isEmpty || description.isEmpty || city.isEmpty || selectedImage == nil : title.isEmpty || description.isEmpty || city.isEmpty || email.isEmpty || selectedImage == nil)
                    .padding(.horizontal)
                    .padding(.vertical, 0)
                }
                .padding()
                .padding(.bottom, 90)
            }
            .ignoresSafeArea(edges: .bottom)
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
        }
    }

    // MARK: - Post Action
    private func postAction() {
        if let selectedImage = selectedImage {
            if isHomeowner {
                jobController.uploadImage(selectedImage) { url in
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
                        jobController.postJob(job: newJob, selectedImage: selectedImage)
                        resetFields()
                    } else {
                        print("Error uploading image for job.")
                    }
                }
            } else {
                flyerController.uploadImage(selectedImage) { url in
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
                        flyerController.postFlyer(profile: newFlyer, selectedImage: selectedImage)
                        resetFields()
                    } else {
                        print("Error uploading image for flyer.")
                    }
                }
            }
        }
    }
    // MARK: - Custom Dropdown for Category Picker
    struct CategoryDropdown: View {
        @Binding var selectedCategories: [JobCategory]
        @State private var showDropdown: Bool = false

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: {
                    withAnimation {
                        showDropdown.toggle()
                    }
                }) {
                    HStack {
                        Text(selectedCategories.isEmpty ? "Select Skills" : selectedCategories.map { $0.rawValue }.joined(separator: ", "))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Image(systemName: showDropdown ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(2)
                }
                if showDropdown {
                    VStack(spacing: 0) {
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
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(0)
                }
            }
            .background(Color.white.opacity(0.2))
            .cornerRadius(7)
        }
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



// MARK: - Preview for PostView
struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
    }
}
