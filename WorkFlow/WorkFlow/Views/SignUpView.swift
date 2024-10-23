//  SignUpView.swift - Provides a sign-up interface for creating a homeowner or contractor account with validation and navigation.
import SwiftUI

struct SignUpView: View {
    @State private var email: String = ""  // State variable for user email input.
    @State private var profileName: String = ""  // State variable for profile name input.
    @State private var profileBio: String = ""  // State variable for profile bio input (contractor).
    @State private var password: String = ""  // State variable for password input.
    @State private var passwordConfirmation: String = ""  // State variable for password confirmation input.
    @State private var city: String = ""  // State variable for city input.
    
    @Environment(\.dismiss) var dismiss  // Environment variable to handle view dismissal.
    @StateObject private var authController = AuthController()  // Initialize AuthController to manage user authentication.
    @State private var navigateToPersonalizedHome: Bool = false  // State to manage navigation after sign-up.
    @State private var isHomeowner: Bool = true  // Toggle to select account type: homeowner or contractor.

    /*
     email, name, city, password, confirm password, category, image, isImagePickerPresented, isCategoryPickerPresented
     */
    @EnvironmentObject var jobController: JobController  // Access job controller for data handling.
    @EnvironmentObject var contractorController: ContractorController  // Access contractor controller for data handling.

    var body: some View {
        ZStack {
            /*
            // Add gradient background from light to dark blue
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)  // Ensure background covers entire screen
            */
            ScrollView {  // Wrap everything in a ScrollView
                VStack(spacing: 20) {
                    // Toggle between Homeowner and Contractor view
                    Picker("Account Type", selection: $isHomeowner) {
                        Text("Homeowner").tag(true)
                        Text("Contractor").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()  // Styling: Padding for the toggle

                    // Section for entering job or flyer details
                    VStack(alignment: .leading, spacing: 24) {
                        // Custom styling for the text fields
                        if isHomeowner {
                            InputCellView(text: $email, title: "Email Address", placeholder: "name@example")
                                .autocapitalization(.none)
                            
                            InputCellView(text: $profileName, title: "Full Name", placeholder: "John Smith")
                                .autocapitalization(.none)
                            
                            InputCellView(text: $city, title: "City", placeholder: "Camarillo")
                                .autocapitalization(.none)
                            
                            InputCellView(text: $password, title: "Password", placeholder: "Enter your password", isSecureField: true)
                                .autocapitalization(.none)
                            
                            InputCellView(text: $passwordConfirmation, title: "Confirm Password", placeholder: "Enter your password", isSecureField: true)
                                .autocapitalization(.none)
                        } else {
                            InputCellView(text: $email, title: "Email Address", placeholder: "name@example")
                                .autocapitalization(.none)
                            
                            InputCellView(text: $profileName, title: "Company Name", placeholder: "WorkFlow")
                                .autocapitalization(.none)
                            
                            InputCellView(text: $profileBio, title: "Company Bio", placeholder: "Describe skills")
                                .autocapitalization(.none)
                            
                            InputCellView(text: $city, title: "City", placeholder: "Camarillo")
                                .autocapitalization(.none)
                            
                            // Change back to , isSecureField:true
                            InputCellView(text: $password, title: "Password", placeholder: "Enter your password", isSecureField: true)
                                .autocapitalization(.none)
                            
                            InputCellView(text: $passwordConfirmation, title: "Confirm Password", placeholder: "Enter your password", isSecureField: true)
                                .autocapitalization(.none)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // NavigationLink to navigate when `navigateToPersonalizedHome` becomes true
                    NavigationLink(destination: PLACEHOLDER(), isActive: $navigateToPersonalizedHome) {
                        EmptyView()
                    }

                    // Sign-Up button
                    Button {
                        Task {
                            // Ensure password and confirmation match
                            guard password == passwordConfirmation else {
                                print("Passwords do not match")
                                return
                            }

                            do {
                                // Determine the user role based on the isHomeowner state
                                let role: UserRole = isHomeowner ? .homeowner : .contractor
                                
                                // Create user and store their data
                                try await authController.createUser(withEmail: email, password: password, name: profileName, city: city, role: role, bio: profileBio)
                                print("User registered successfully: \(email)")
                                
                                // Instead of dismissing, navigate to a new page
                                navigateToPersonalizedHome = true  // Trigger the navigation to home
                            } catch {
                                print("Error registering user: \(error.localizedDescription)")
                            }
                        }
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

                    // Button to return to sign-in view
                    Button {
                        dismiss()  // Dismiss the sign-up view
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
}

// Preview for SignUpView
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
