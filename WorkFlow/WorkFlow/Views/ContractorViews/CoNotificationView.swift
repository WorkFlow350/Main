import SwiftUI

// MARK: - FAQ Page
struct FAQPageViewCO: View {
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                    Color.black.opacity(0.99)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                TextShimmer(text: "FAQ COMING SOON", fontSize: 35, multiColors: .constant(true))
                Spacer()
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct FAQPageView_PreviewsCO: PreviewProvider {
    static var previews: some View {
        FAQPageViewCO()
    }
}
