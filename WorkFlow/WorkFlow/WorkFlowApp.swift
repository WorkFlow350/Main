//  WorkFlowApp.swift - The main entry point of the application, initializing Firebase and setting up environment objects.
import SwiftUI
import FirebaseCore
import FirebaseDatabase

// Main entry point of the application
@main
struct WorkFlowApp: App {
    // AppDelegateAdaptor allows using AppDelegate for configuring Firebase and other setups
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // StateObject to manage the state of JobController throughout the app
    @StateObject private var jobController = JobController()  // Initialize JobController
    @StateObject private var contractorController = ContractorController()  // Initialize ContractorController
    @StateObject private var authController = AuthController()  // Initialize AuthController

    var body: some Scene {
        WindowGroup {
            // Main view of the app, which starts with the SignInView
            SignInView()
                .environmentObject(jobController)  // Provide JobController to the view hierarchy
                .environmentObject(contractorController)  // Provide ContractorController to the view hierarchy
                .environmentObject(authController)  // Provide AuthController to the view hierarchy
        }
    }
}

// AppDelegate class used for configuring Firebase when the application launches
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()  // Ensure Firebase is configured when the app starts
        return true
    }
}
