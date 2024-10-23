// JobCellView.swift - Displays a compact job cell with thumbnail, details, and a category color indicator.
import SwiftUI

struct JobCellView: View {
    let job: Job
    @State private var isFullScreen: Bool = false
    @StateObject private var jobController = JobController()  // Initialize JobController to manage job data.

    var body: some View {
        HStack {
            // Image thumbnail.
            if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()  // Fill the frame while maintaining aspect ratio.
                        .frame(width: 50, height: 50)  // Set to a compact size for cell view.
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing, 8)  // Add space between the image and text.
                } placeholder: {
                    // Placeholder in case the image is loading or missing.
                    Color.gray
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Job details section.
            VStack(alignment: .leading, spacing: 4) {
                // Display city and category.
                Text("\(job.city)  \(job.category.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.black)

                // Display job title.
                Text(job.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                // Display relative time since the job was posted.
                Text(jobController.timeAgoSinceDate(job.datePosted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Category color indicator.
            Rectangle()
                .frame(width: 4)
                .foregroundColor(categoryColor(for: job.category))
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
}
