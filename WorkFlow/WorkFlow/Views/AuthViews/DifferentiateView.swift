import SwiftUI

struct DifferentiateView: View {
    @EnvironmentObject var authController: AuthController
    @State private var isLoading = true

    // MARK: - Set View HO or CO
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
            Task {
                if authController.userSession != nil && authController.appUser == nil {
                    isLoading = true
                    await authController.setUser()
                    if authController.isUserSet {
                        isLoading = false
                    }
                } else {
                    isLoading = false
                }
            }
        }
    }
}
