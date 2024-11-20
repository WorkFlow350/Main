import SwiftUI

struct DifferentiateView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController
    @State private var showSplashScreen = true
    @State private var isLoading = true
    
    // MARK: - Set View HO or CO
    var body: some View {
        Group {
            if showSplashScreen {
                SplashScreenView()
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation {
                                showSplashScreen = false
                            }
                        }
                    }
            } else {
                VStack {
                    if isLoading {
                        ProgressView("Loading user data...").padding()
                    } else if let appUser = authController.appUser {
                        switch appUser.role {
                        case .homeowner:
                            HoMainView()
                                .transition(.opacity)
                        case .contractor:
                            CoMainView()
                                .transition(.opacity)
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
    }
}
