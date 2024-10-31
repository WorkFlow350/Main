import Foundation
import SwiftUI

// MARK: - Homeowner Notification View
struct HoNotificationView: View {
    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            Text("Reserved view for chat notifications and bids")
                .navigationBarTitle("Notifications", displayMode: .inline)
        }
    }
}

// MARK: - Preview
struct HoNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        HoNotificationView()
    }
}
