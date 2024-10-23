// ChatView.swift - Displays the chat interface for users to communicate within the app.
import Foundation
import SwiftUI

// ChatView represents the chat interface.
struct ChatView: View {
    var body: some View {
        ZStack {
            // Background gradient for the view.
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // Placeholder text for the chat view.
            Text("Chat View")
                .navigationBarTitle("Chat", displayMode: .inline)
        }
    }
}

// Preview for ChatView to visualize the view in Xcode's canvas.
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
