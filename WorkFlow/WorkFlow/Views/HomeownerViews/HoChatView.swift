import Foundation
import SwiftUI

// MARK: - Homeowner Chat View
struct HoChatView: View {
    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // MARK: - Chat Text
            Text("Homeowner Chat View")
                .navigationBarTitle("Chat", displayMode: .inline)
        }
    }
}

// MARK: - Preview
struct HoChatView_Previews: PreviewProvider {
    static var previews: some View {
        HoChatView()
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
