// HomeownerProfileView.swift - Displays the homeowner's profile with a "Done" button to dismiss the view.
import SwiftUI

// HomeownerProfileView with a "Done" button to dismiss the view.
struct HomeownerProfileView: View {
    @Environment(\.dismiss) var dismiss  // Dismiss environment variable for returning to the previous screen.

    var body: some View {
        VStack {
            HStack {
                // "Done" button to exit the profile view.
                Button("Done") {
                    dismiss()  // Dismiss the view when "Done" is pressed.
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())  // Capsule-shaped button for rounded appearance.

                Spacer()
            }
            .padding()

            Spacer()

            // Placeholder text indicating profile is under construction.
            Text("Profile in Progress")
                .font(.largeTitle)
                .foregroundColor(.black)
                .padding()

            Spacer()
        }
        .background(
            // Background gradient for the view.
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
}
