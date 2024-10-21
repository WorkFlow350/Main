import SwiftUI
import UIKit

// Helper for keyboard management
struct KeyboardHelper {
    static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// View for displaying an image in full-screen mode
struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 30))
                    .padding()
            }
        }
    }
}

// View for displaying an image from a URL in full-screen mode
struct FullScreenImageFromURLView: View {
    let imageURL: URL
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .edgesIgnoringSafeArea(.all)  // Full-screen image
            } placeholder: {
                ProgressView()
            }

            // Close button to dismiss full-screen mode
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 30))
                    .padding()
            }
        }
    }
}

// Extension for Hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Custom UIViewRepresentable for BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
