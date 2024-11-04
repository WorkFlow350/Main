import Foundation
import SwiftUI

struct ChatView: View {
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

            // MARK: - Informational Message
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "info.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)

                    Text("Sign Up to Access Chat Features")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                Spacer()
            }
        }
    }
}

// MARK: - Preview for ChatView
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
