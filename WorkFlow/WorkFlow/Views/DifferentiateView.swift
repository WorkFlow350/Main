import SwiftUI

struct DifferentiateView: View {
    @EnvironmentObject var authController: AuthController

    var body: some View {
        VStack {
            // MARK: - Display Views Based on User Role
            if let appUser = authController.appUser {
                switch appUser.role {
                case .homeowner:
                    HoMainView()
                case .contractor:
                    CoMainView() 
                }
            }
            else {
                // MARK: - Loading Placeholder
                Text("Loading user data...").padding()
                // MARK: - Debug Info
                Text("Session ID: \(authController.userSession?.uid ?? "No session")")
            }
        }
        .onAppear {
            guard !authController.isUserSet else { return }
            Task {
                if authController.userSession != nil && authController.appUser == nil {
                    print("appUser is nil, calling setUser()")
                    await authController.setUser()
                    print("Finished calling setUser()")
                }
            }
        }
    }
}
