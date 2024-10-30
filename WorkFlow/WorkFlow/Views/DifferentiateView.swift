import SwiftUI

struct DifferentiateView: View {
    @EnvironmentObject var authController: AuthController

    var body: some View {
        VStack {
            if let appUser = authController.appUser {
                // MARK: - Display Views Based on User Role
                switch appUser.role {
                case .homeowner:
                    HoMainView()
                case .contractor:
                    CoMainView()
                default:
                    Text("Unknown user type")
                        .foregroundColor(.red)
                }
            } else {
                // MARK: - Loading Placeholder
                Text("Loading user data...")
                    .padding()

                // MARK: - Debug Info
                Text("Session ID: \(authController.userSession?.uid ?? "No session")")
                Text("User: \(String(describing: authController.appUser))")
                    .padding()
            }
        }
        .onAppear {
            Task {
                await authController.setUser()
                if let role = authController.appUser?.role {
                    print("Fetched user role: \(role.rawValue)")
                } else {
                    print("Failed to fetch user role")
                }
            }
        }
    }
}
