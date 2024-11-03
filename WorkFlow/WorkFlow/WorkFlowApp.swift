import SwiftUI
import FirebaseCore
import FirebaseDatabase

@main
struct WorkFlowApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - State Objects
    @StateObject private var homeownerJobController = HomeownerJobController()
    @StateObject private var authController = AuthController()
    @StateObject private var jobController = JobController()
    @StateObject private var contractorController = ContractorController()
    
    var body: some Scene {
        WindowGroup {
            SignInView()
                .environmentObject(homeownerJobController)
                .environmentObject(authController)
                .environmentObject(jobController)
                .environmentObject(contractorController)
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
