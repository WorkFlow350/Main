import SwiftUI
import FirebaseCore
import FirebaseDatabase

@main
struct WorkFlowApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - State Objects
    @StateObject private var jobController = JobController()
    @StateObject private var contractorController = ContractorController()
    @StateObject private var authController = AuthController()

    var body: some Scene {
        WindowGroup {
            SignInView()
                .environmentObject(jobController)
                .environmentObject(contractorController)
                .environmentObject(authController)
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
