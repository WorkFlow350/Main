import SwiftUI

struct FlyerCellView: View {
    // MARK: - Properties
    let contractor: ContractorProfile
    @State private var isFullScreen: Bool = false
    @StateObject private var contractorController = ContractorController()

    // MARK: - Body
    var body: some View {
        HStack {
            // MARK: - Contractor Details
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

            // MARK: - Profile Image
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

            // MARK: - Category Color Indicator
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

    // MARK: - Helper Functions
    private func categoryColor(for skills: [String]) -> Color {
        if skills.contains("Landscaping") {
            return Color.green
        } else if skills.contains("Cleaning") {
            return Color.blue
        } else if skills.contains("Construction") {
            return Color.orange
        } else {
            return Color.purple
        }
    }
}
