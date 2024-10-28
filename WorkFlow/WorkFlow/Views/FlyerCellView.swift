import SwiftUI

struct FlyerCellView: View {
    let contractor: ContractorProfile
    @State private var isFullScreen: Bool = false
    @StateObject private var contractorController = ContractorController()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Specialty: \(contractor.skills.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.black)

                Text(contractor.contractorName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text("Service Area: \(contractor.city)")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }

            Spacer()

            // Profile image
            if let imageUrl = contractor.imageURL, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                } placeholder: {
                    Color.gray
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
            }

            // Category color indicator
            Rectangle()
                .frame(width: 4)
                .foregroundColor(categoryColor(for: contractor.skills))
                .cornerRadius(2)
                .padding(.vertical, 8)
        }
        .padding(8)
        .background(
            BlurView(style: .systemMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // Helper function to determine color based on the contractor's skills
    private func categoryColor(for skills: [String]) -> Color {
        if skills.contains("Landscaping") {
            return Color.green
        } else if skills.contains("Cleaning") {
            return Color.blue
        } else if skills.contains("Construction") {
            return Color.orange
        } else {
            return Color.purple // Default color for other skills
        }
    }
}
