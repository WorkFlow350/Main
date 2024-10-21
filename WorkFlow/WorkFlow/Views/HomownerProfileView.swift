import SwiftUI

// Updated HomeownerProfileView with a "Done" button
struct HomeownerProfileView: View {
    @Environment(\.dismiss) var dismiss // Dismiss environment variable for returning

    var body: some View {
        VStack {
            HStack {
                Button("Done") {
                    dismiss() // Dismiss the view when "Done" is pressed
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())

                Spacer()
            }
            .padding()

            Spacer()

            Text("Profile in Progress")
                .font(.largeTitle)
                .foregroundColor(.black)
                .padding()

            Spacer()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
}
