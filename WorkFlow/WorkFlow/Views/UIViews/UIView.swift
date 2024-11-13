import SwiftUI
import UIKit

// MARK: - Keyboard Helper
struct KeyboardHelper {
    static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Full-Screen Image View
struct FullScreenImageView: View {
    // MARK: - Properties
    let imageUrl: String?
    @Binding var isFullScreen: Bool

    var body: some View {
        ZStack {
            // MARK: - Background
            Color.black.ignoresSafeArea()

            // MARK: - Image Display
            if let imageURL = imageUrl, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isFullScreen = false
                            }
                        }
                } placeholder: {
                    // MARK: - Placeholder
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }

            // MARK: - Back Button
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            isFullScreen = false
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

// MARK: - Blur View
struct BlurView: UIViewRepresentable {
    // MARK: - Properties
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Category Color
func categoryColor(for category: JobCategory?) -> Color {
    switch category {
    case .landscaping:
        return .green
    case .cleaning:
        return .blue
    case .construction:
        return .orange
    default:
        return .purple
    }
}

// MARK: - MultiCategoryPicker for Contractors
struct MultiCategoryPicker: View {
    @Binding var selectedCategories: [JobCategory]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(JobCategory.allCases, id: \.self) { category in
                    MultipleSelectionRow(title: category.rawValue, isSelected: selectedCategories.contains(category)) {
                        if selectedCategories.contains(category) {
                            selectedCategories.removeAll { $0 == category }
                        } else {
                            selectedCategories.append(category)
                        }
                    }
                }
            }
            .accentColor(.black)
            .navigationBarTitle("Select Skills", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

// MARK: - Multiple Selection Row
struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

// MARK: - Custom Popup for Description/Bio
struct CustomDescriptionPopup: View {
    @Binding var isPresented: Bool
    @Binding var description: String
    var title: String

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Text(title)
                        .font(.headline)

                    TextEditor(text: $description)
                        .frame(height: 150)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#708090"), Color(hex: "#2F4F4F")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .foregroundColor(.white)

                        Button("Done") {
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .shadow(radius: 10)
            }
        }
    }
}
