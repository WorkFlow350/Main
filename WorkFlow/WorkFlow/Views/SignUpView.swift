import SwiftUI

struct SignUpView: View {
    // MARK: - State Variables
    @State private var email: String = ""
    @State private var profileName: String = ""
    @State private var profileBio: String = ""
    @State private var password: String = ""
    @State private var passwordConfirmation: String = ""
    @State private var city: String = ""
    @State private var navigateToPersonalizedHome: Bool = false
    @State private var isHomeowner: Bool = true
    private var isPasswordValid: Bool {
        password.count >= 6
    }
    private var doPasswordsMatch: Bool {
        !passwordConfirmation.isEmpty && password == passwordConfirmation
    }
    // MARK: - Environment Variables
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController
    
    // MARK: - Body
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Account Type Picker
                    Picker("Account Type", selection: $isHomeowner) {
                        Text("Homeowner").tag(true)
                        Text("Contractor").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // MARK: - Input Fields
                    VStack(alignment: .leading, spacing: 24) {
                        if isHomeowner {
                            InputCellView(text: $email, title: "Email Address", placeholder: "name@example",isRequired: true)
                                .autocapitalization(.none)
                            InputCellView(text: $profileName, title: "Full Name", placeholder: "John Smith")
                                .autocapitalization(.none)
                            InputCellView(text: $profileBio, title: "Bio", placeholder: "Description")
                                .autocapitalization(.none)
                            InputCellView(text: $city, title: "City", placeholder: "Camarillo")
                                .autocapitalization(.none)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    InputCellView(text: $password, title: "Password", placeholder: "Enter your password", isSecureField: true,isRequired: true)
                                        .autocapitalization(.none)
                                    Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isPasswordValid ? .green : .red)
                                }
                                if !isPasswordValid {
                                    Text("Password must be 6 characters long")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 2)
                                }
                                
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    InputCellView(text: $passwordConfirmation, title: "Confirm Password", placeholder: "Confirm your password", isSecureField: true,isRequired: true)
                                        .autocapitalization(.none)
                                    Image(systemName: doPasswordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(doPasswordsMatch ? .green : .red)
                                }
                                
                                // "Passwords do not match" error message
                                if !doPasswordsMatch {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 2)
                                }
                            }
                            //.padding(.horizontal)
                        } else {
                            InputCellView(text: $email, title: "Email Address", placeholder: "name@example",isRequired: true)
                                .autocapitalization(.none)
                            InputCellView(text: $profileName, title: "Company Name", placeholder: "WorkFlow")
                                .autocapitalization(.none)
                            InputCellView(text: $profileBio, title: "Company Bio", placeholder: "Describe skills")
                                .autocapitalization(.none)
                            InputCellView(text: $city, title: "City", placeholder: "Camarillo")
                                .autocapitalization(.none)
  
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    InputCellView(text: $password, title: "Password", placeholder: "Enter your password", isSecureField: true,isRequired: true)
                                        .autocapitalization(.none)
                                    Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isPasswordValid ? .green : .red)
                                }
                                if !isPasswordValid {
                                    Text("Password must be 6 characters long")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 2)
                                }
                                
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    InputCellView(text: $passwordConfirmation, title: "Confirm Password", placeholder: "Confirm your password", isSecureField: true,isRequired: true)
                                        .autocapitalization(.none)
                                    Image(systemName: doPasswordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(doPasswordsMatch ? .green : .red)
                                }
                                
                                // "Passwords do not match" error message
                                if !doPasswordsMatch {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // MARK: - Navigation Link
                    .navigationDestination(isPresented: $navigateToPersonalizedHome) {
                        DifferentiateView().environmentObject(authController)
                    }

                    // MARK: - Sign-Up Button
                    Button {
                        signUp()
                    } label: {
                        HStack {
                            Text("SIGN UP")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                    }
                    .background(Color(.systemBlue))
                    .cornerRadius(10)
                    .padding(.top, 24)

                    Spacer()

                    // MARK: - Sign-In Button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 3) {
                            Text("Already Have an Account?")
                            Text("Sign In")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                    }
                }
            }
        }
    }

    // MARK: - Sign-Up Function
    private func signUp() {
        Task {
            guard password == passwordConfirmation else {
                print("Passwords do not match")
                return
            }
            guard password.count >= 6 else {
                print("Password must be at least 6 characters.")
                return
            }

            do {
                let role: UserRole = isHomeowner ? .homeowner : .contractor
                try await authController.createUser(
                    withEmail: email,
                    password: password,
                    name: profileName,
                    city: city,
                    role: role,
                    bio: profileBio
                )

                print("User registered successfully: \(email)")
                
                DispatchQueue.main.async {
                    navigateToPersonalizedHome = true
                }
            } catch {
                print("Error registering user: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
