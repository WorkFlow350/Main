import SwiftUI

struct SignInView: View {
    // MARK: - State Variables
    @State private var email = ""
    @State private var password = ""
    @StateObject var authController = AuthController()
    @State private var navigateToPersonalizedHome: Bool = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - App Icon
                Image("Applcon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 32)

                // MARK: - Input Fields
                VStack(spacing: 24) {
                    InputCellView(
                        text: $email,
                        title: "Email Address",
                        placeholder: "name@example"
                    )
                    .autocapitalization(.none)

                    InputCellView(
                        text: $password,
                        title: "Password",
                        placeholder: "Enter your password",
                        isSecureField: true
                    )
                    .autocapitalization(.none)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // MARK: - Navigation Link
                NavigationLink(destination: DifferentiateView(), isActive: $navigateToPersonalizedHome) {
                    EmptyView()
                }

                // MARK: - Sign-In Button
                Button {
                    Task {
                        do {
                            try await authController.signIn(withEmail: email, password: password)
                            print("User signed in successfully: \(email)")
                            navigateToPersonalizedHome = true
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
                .background(Color(.systemBlue))
                .cornerRadius(10)
                .padding(.top, 24)

                Spacer()

                // MARK: - Sign-Up & Continue as Guest
                VStack(spacing: 16) {
                    NavigationLink(destination: SignUpView().navigationBarBackButtonHidden(true)) {
                        Text("Don't have an account? Sign Up")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
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

#Preview {
    SignInView()
}
