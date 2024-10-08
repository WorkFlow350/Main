import SwiftUI
import FirebaseCore
import FirebaseDatabase

// Main entry point of the application
@main
struct WorkFlowApp: App {
    // AppDelegateAdaptor allows using AppDelegate for configuring Firebase and other setups
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // StateObject to manage the state of JobController throughout the app
    @StateObject private var jobController = JobController() // Initialize JobController

    var body: some Scene {
        WindowGroup {
            // MainTabView is the starting view of the app, and it receives the jobController as an environment object
            MainTabView()
                .environmentObject(jobController) // Provide JobController to the view hierarchy
        }
    }
}

// AppDelegate class used for configuring Firebase when the application launches
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // Ensure Firebase is configured when the app starts
        return true
    }
}
