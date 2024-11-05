import Foundation
import SwiftUI

// MARK: - Contractor Chat View
struct CoChatView: View {
    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                    Color.black.opacity(0.99)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // MARK: - Chat Text
            Text("Contractor Chat View")
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
struct CoChatView_Previews: PreviewProvider {
    static var previews: some View {
        CoChatView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
    }
}
