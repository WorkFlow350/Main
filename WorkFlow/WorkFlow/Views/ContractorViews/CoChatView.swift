import Foundation
import SwiftUI

struct CoChatView: View {
    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // MARK: - Chat Placeholder
            Text("Contractor Chat View")
                .navigationBarTitle("Chat", displayMode: .inline)
        }
    }
}

// MARK: - Preview
struct CoChatView_Previews: PreviewProvider {
    static var previews: some View {
        CoChatView()
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
