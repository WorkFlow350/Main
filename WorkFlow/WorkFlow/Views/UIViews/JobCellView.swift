import SwiftUI

struct JobCellView: View {
    // MARK: - Properties
    let job: Job
    @State private var isFullScreen: Bool = false
    @EnvironmentObject var jobController: JobController
    
    // MARK: - Body
    var body: some View {
        HStack {
            // MARK: - Image Thumbnail
            if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing, 8)
                } placeholder: {
                    Color.gray
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // MARK: - Job Details
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

            // MARK: - Category Color Indicator
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
}
// MARK: - Preview
struct JobCellView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleJob = Job(
            id: UUID(),
            title: "Sample Job Title",
            description: "This is a sample job description.",
            city: "Sample City",
            category: .landscaping,
            datePosted: Date(),
            imageURL: "https://via.placeholder.com/150"
        )
        
        JobCellView(job: sampleJob)
            .environmentObject(JobController())
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
    }
}