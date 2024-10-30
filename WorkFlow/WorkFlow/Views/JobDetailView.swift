import SwiftUI

struct JobDetailView: View {
    // MARK: - Properties
    let job: Job
    @StateObject private var jobController = JobController()
    @State private var isFullScreen: Bool = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

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
                        .padding(.leading)

                    // MARK: - Job Metadata
                    HStack {
                        Text(jobController.timeAgoSinceDate(job.datePosted))
                            .font(.caption)

                        Text("• \(job.city)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.leading)

                    // MARK: - Job Category
                    Text(job.category.rawValue)
                        .font(.caption)
                        .padding(.leading)
                        .padding(.bottom, 5)

                    // MARK: - Job Description
                    Text(job.description)
                        .font(.body)
                        .padding(.leading)
                        .padding(.top, 5)
                        .padding(.bottom, 100)
                }
                .navigationTitle("Job Details")
                .fullScreenCover(isPresented: $isFullScreen) {
                    FullScreenImageView(imageUrl: job.imageURL, isFullScreen: $isFullScreen)
                }
            }
        }
    }
}
