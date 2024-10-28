import SwiftUI

struct DifferentiateView: View {
    @EnvironmentObject var authController: AuthController

    var body: some View {
        VStack {
            if let appUser = authController.appUser {
                // Displaying views based on user role
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
                // Display loading or placeholder while user data is fetched
                Text("Loading user data...")
                    .padding()
                
                // Display debug info if userSession or appUser is nil
                Text("Session ID: \(authController.userSession?.uid ?? "No session")")
                Text("User: \(String(describing: authController.appUser))")
                    .padding()
            }
        }
        .onAppear {
            Task {
                // Fetch user information when the view appears
                await authController.setUser()

                // Debug log to ensure correct user role is fetched
                if let role = authController.appUser?.role {
                    print("Fetched user role: \(role.rawValue)")
                } else {
                    print("Failed to fetch user role")
                }
            }
        }
    }
}
