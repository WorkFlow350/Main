//  SignInView.swift - Provides a sign-in interface for users, with options to navigate to sign-up or continue as a guest.
import SwiftUI

struct SignInView: View {
    @State private var email = ""  // State variable for user email input.
    @State private var password = ""  // State variable for user password input.
    @StateObject var authController = AuthController()  // Initialize AuthController for handling authentication.
    @State private var navigateToPersonalizedHome: Bool = false  // State to manage navigation to the home view.

    var body: some View {
        NavigationStack {
            VStack {
                // App icon display.
                Image("Applcon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 32)

                // Form fields for email and password using InputCellView.
                VStack(spacing: 24) {
                    InputCellView(
                        text: $email,
                        title: "Email Address",
                        placeholder: "name@example"
                    )
                    .autocapitalization(.none)  // Prevent automatic capitalization of email.

                    InputCellView(
                        text: $password,
                        title: "Password",
                        placeholder: "Enter your password",
                        isSecureField: true
                    )
                    .autocapitalization(.none)  // Prevent automatic capitalization of password.
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // NavigationLink for transitioning to personalized home upon successful sign-in.
                NavigationLink(destination: PLACEHOLDER(), isActive: $navigateToPersonalizedHome) {
                    EmptyView()  // Invisible navigation link placeholder.
                }

                // Sign-In button.
                Button {
                    Task {
                        do {
                            // Attempt to sign in with the provided email and password.
                            try await authController.signIn(withEmail: email, password: password)
                            print("User signed in successfully: \(email)")
                            navigateToPersonalizedHome = true  // Navigate to home upon successful sign-in.
                        } catch {
                            print("Error signing in: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    HStack {
                        Text("SIGN IN")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                }
                .background(Color(.systemBlue))  // Set button background color.
                .cornerRadius(10)
                .padding(.top, 24)

                Spacer()

                // Sign-Up & Continue as Guest buttons.
                VStack(spacing: 16) {
                    // Sign-Up button to navigate to SignUpView.
                    NavigationLink(destination: SignUpView().navigationBarBackButtonHidden(true)) {
                        Text("Don't have an account? Sign Up")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    // Continue as Guest button to navigate to MainTabView.
                    NavigationLink(destination: MainTabView()) {
                        Text("Continue as Guest")
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }
}

// Preview for SignInView.
#Preview {
    SignInView()
}
