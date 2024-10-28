import SwiftUI

struct JobCellView: View {
    let job: Job
    @State private var isFullScreen: Bool = false
    @StateObject private var jobController = JobController()

    var body: some View {
        HStack {
            // Image thumbnail
            if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50) // Smaller size for a compact view
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing, 8) // Space between image and text
                } placeholder: {
                    Color.gray
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Job details
            VStack(alignment: .leading, spacing: 4) {
                Text("\(job.city)  \(job.category.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.black)

                Text(job.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text(jobController.timeAgoSinceDate(job.datePosted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Category color indicator
            Rectangle()
                .frame(width: 4)
                .foregroundColor(categoryColor(for: job.category))
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

    // Helper function to determine the color based on the job category
    private func categoryColor(for category: JobCategory) -> Color {
        switch category {
        case .landscaping:
            return Color.green
        case .cleaning:
            return Color.blue
        case .construction:
            return Color.orange
        }
    }
}
