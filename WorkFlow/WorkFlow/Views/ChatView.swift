import Foundation
import SwiftUI

struct ChatView: View {
    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // MARK: - Placeholder Text
            Text("Chat View")
                .navigationBarTitle("Chat", displayMode: .inline)
        }
    }
}

// MARK: - Preview for ChatView
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
