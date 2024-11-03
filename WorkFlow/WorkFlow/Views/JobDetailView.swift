import SwiftUI

struct JobDetailView: View {
    // MARK: - Properties
    let job: Job
    @EnvironmentObject var jobController: JobController
    @State private var isFullScreen: Bool = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Job Image
                    if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width, height: 300)
                                .cornerRadius(12)
                                .onTapGesture {
                                    withAnimation {
                                        isFullScreen = true
                                    }
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        }
                    }
                    
                    // MARK: - Job Title
                    Text(job.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading)

                    // MARK: - Job Metadata
                    HStack {
                        Text(jobController.timeAgoSinceDate(job.datePosted))
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("• \(job.city)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.leading)

                    // MARK: - Job Category
                    Text(job.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.leading)
                        .padding(.bottom, 5)

                    // MARK: - Job Description
                    Text(job.description)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.leading)
                        .padding(.top, 5)
                        .padding(.bottom, 100)
                }
                .fullScreenCover(isPresented: $isFullScreen) {
                    FullScreenImageView(imageUrl: job.imageURL, isFullScreen: $isFullScreen)
                }
            }
        }
    }
}

// MARK: - Preview
struct JobDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleJob = Job(
            id: UUID(),
            title: "Sample Job Title",
            description: "This is a sample job description that provides details about the job.",
            city: "Sample City",
            category: .landscaping,
            datePosted: Date(),
            imageURL: "https://via.placeholder.com/300"
        )

        JobDetailView(job: sampleJob)
            .environmentObject(JobController())
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
    }
}
