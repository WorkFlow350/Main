import Foundation
import SwiftUI

// MARK: - Homeowner Notification View
struct HoNotificationView: View {
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
            Text("Reserved view for chat notifications and bids")
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
struct HoNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        HoNotificationView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
