// Utilities.swift - Contains helper structs for keyboard management, color support, full-screen image display, and blur effects.
import SwiftUI
import UIKit

// Helper for keyboard management.
struct KeyboardHelper {
    // Hides the keyboard programmatically.
    static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// View for displaying an image in full-screen mode.
struct FullScreenImageView: View {
    let imageUrl: String?  // Optional URL of the image to display.
    @Binding var isFullScreen: Bool  // Binding to toggle full-screen state.

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()  // Set the background to black, covering safe areas.

            // Display the image if the URL is valid.
            if let imageURL = imageUrl, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()  // Maintain aspect ratio for full-screen image.
                        .ignoresSafeArea()  // Cover the entire screen.
                        .onTapGesture {
                            withAnimation {
                                isFullScreen = false  // Dismiss full-screen on tap.
                            }
                        }
                } placeholder: {
                    // Placeholder while the image is loading.
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }

            // Back button to dismiss the full-screen view.
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            isFullScreen = false  // Dismiss the full-screen view when tapped.
                        }
                    }) {
                        Image(systemName: "chevron.left")  // Back arrow icon.
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()  // Push the back button to the left.
                }
                Spacer()  // Push content to the top.
            }
        }
    }
}

// Extension for Color to support Hex color initialization.
extension Color {
    // Initializes a Color from a Hex string.
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
            (a, r, g, b) = (255, 0, 0, 0)  // Default to black color.
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

// Custom UIViewRepresentable for a blur effect.
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    // Creates the UIVisualEffectView with the specified blur style.
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    // Updates the UIVisualEffectView with the specified blur style.
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// Returns a color based on the provided JobCategory.
func categoryColor(for category: JobCategory?) -> Color {
    switch category {
    case .landscaping:
        return .green
    case .cleaning:
        return .blue
    case .construction:
        return .orange
    default:
        return .purple // Default color for flyers or undefined categories.
    }
}
