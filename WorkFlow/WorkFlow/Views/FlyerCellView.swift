// FlyerCellView.swift - Displays a contractor's flyer in a compact cell with profile image, details, and a category color indicator.
import SwiftUI

struct FlyerCellView: View {
    let contractor: ContractorProfile
    @State private var isFullScreen: Bool = false
    @StateObject private var contractorController = ContractorController()  // Initialize ContractorController to manage contractor data.

    var body: some View {
        HStack {
            // Contractor details.
            VStack(alignment: .leading, spacing: 4) {
                // Display contractor's skills.
                Text("Specialty: \(contractor.skills.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.black)

                // Display contractor's name.
                Text(contractor.contractorName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                // Display contractor's service area.
                Text("Service Area: \(contractor.city)")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }

            Spacer()

            // Profile image.
            if let imageUrl = contractor.imageURL, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)  // Set to a circular frame.
                        .clipShape(Circle())  // Make the image circular.
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))  // Add a white border.
                } placeholder: {
                    // Placeholder in case the image is loading or missing.
                    Color.gray
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
            } else {
                // Default image if no profile picture is available.
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
            }

            // Category color indicator.
            Rectangle()
                .frame(width: 4)
                .foregroundColor(categoryColor(for: contractor.skills))  // Set color based on skills.
                .cornerRadius(2)
                .padding(.vertical, 8)
        }
        .padding(8)
        .background(
            BlurView(style: .systemMaterial)  // Apply blur effect for material design.
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .cornerRadius(12)
        .shadow(radius: 2)  // Add a subtle shadow for depth.
    }

    // Helper function to determine color based on the contractor's skills.
    private func categoryColor(for skills: [String]) -> Color {
        if skills.contains("Landscaping") {
            return Color.green
        } else if skills.contains("Cleaning") {
            return Color.blue
        } else if skills.contains("Construction") {
            return Color.orange
        } else {
            return Color.purple  // Default color for other skills.
        }
    }
}
