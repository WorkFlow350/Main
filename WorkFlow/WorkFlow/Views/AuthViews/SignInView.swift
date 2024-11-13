import SwiftUI
import FirebaseAuth

struct SignInView: View {
    // MARK: - State Variables
    @State private var email = ""
    @State private var password = ""
    @State private var navigateToPersonalizedHome: Bool = false
    @State private var signInErrorMessage: String = ""

    
    // MARK: - Environment Object
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractor1Controller: ContractorController


    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - App Icon
                Image("WorkFlowLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 32)
                    .shadow(color: .black.opacity(10), radius: 5, x: 0, y: 5)
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
                    if !signInErrorMessage.isEmpty {
                        Text(signInErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // MARK: - Navigation Link
                .navigationDestination(isPresented: $navigateToPersonalizedHome) {
                    DifferentiateView()
                        .environmentObject(authController)
                        .environmentObject(homeownerJobController)
                        .environmentObject(jobController)
                        .environmentObject(contractorController)
                }
                // MARK: - Sign-In Button
                Button {
                    Task {
                        do {
                            try await authController.signIn(withEmail: email, password: password)
                            signInErrorMessage = ""
                            print("User signed in successfully: \(email)")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigateToPersonalizedHome = true
                            }
                        } catch {
                            //limited error catching because email enumeration protectection is enabled by default. Increases security by reducing error hints. 
                            if let nsError = error as NSError?{
                                if let errorCode = AuthErrorCode(rawValue: nsError.code) {
                                    switch errorCode {
                                    case .wrongPassword:
                                        signInErrorMessage = "Password cannot be empty."
                                    case .invalidEmail:
                                        signInErrorMessage = "Invalid email format. Please check and try again."
                                    default:
                                        signInErrorMessage = "An unexpected error occurred. Please try again."
                                    }
                                }
                                else{
                                    signInErrorMessage = "An unexpected error occurred. Please try again."
                                }
                            }
                            
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
            .onAppear {
                email = ""
                password = ""
                navigateToPersonalizedHome = false
                authController.isUserSet = false
                signInErrorMessage = ""
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(HomeownerJobController())
        .environmentObject(AuthController())
        .environmentObject(JobController())
        .environmentObject(FlyerController())
}
