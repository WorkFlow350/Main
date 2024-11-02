import SwiftUI
import PhotosUI
import FirebaseStorage

struct CoPostView: View {
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
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Flyer Details Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Flyer Details")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("Name", text: $title)
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

                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            .onChange(of: email) {
                                if email.count > 20 {
                                    email = String(email.prefix(20))
                                }
                            }

                        Button(action: {
                            isDescriptionEditorPresented = true
                        }) {
                            HStack {
                                Text(description.isEmpty ? "Bio" : description)
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
                    }) {
                        Text("Post")
                            .frame(minWidth: 100, maxWidth: 200)
                            .padding()
                            .background(Color(hex: "#355c7d"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .gray, radius: 5, x: 0, y: 2)
                    }
                    .disabled(title.isEmpty || description.isEmpty || city.isEmpty || email.isEmpty || selectedImage == nil)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Post Flyer")
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .overlay(
                CustomDescriptionPopup(
                    isPresented: $isDescriptionEditorPresented,
                    description: $description,
                    title: "Enter your bio"
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

    // MARK: - Helper Functions
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
struct CoPostView_Previews: PreviewProvider {
    static var previews: some View {
        CoPostView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}
