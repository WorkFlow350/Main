import SwiftUI

struct DifferentiateView: View {
    @EnvironmentObject var authController: AuthController
    @State private var isLoading = true
    
    // MARK: - Display Views Based on User Role
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading user data...").padding()
            } else if let appUser = authController.appUser {
                switch appUser.role {
                case .homeowner:
                    HoMainView()
                case .contractor:
                    CoMainView()
                }
            } else {
                Text("Session ID: \(authController.userSession?.uid ?? "No session")")
            }
        }
        .onAppear {
            guard !authController.isUserSet else { return }
            Task {
                isLoading = true
                if authController.userSession != nil && authController.appUser == nil {
                    await authController.setUser()
                }
                isLoading = false
            }
        }
    }
}
