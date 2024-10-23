// JobDetailView.swift - Displays detailed information about a selected job, including image, title, description, and other details.
import SwiftUI

struct JobDetailView: View {
    let job: Job
    @StateObject private var jobController = JobController()  // Initialize JobController to manage job data.
    @State private var isFullScreen: Bool = false  // State to toggle full-screen image view.

    var body: some View {
        ZStack {
            // Background gradient for the view.
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)  // Extend background gradient to cover safe areas.

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Display the job image, which can be tapped to view full-screen.
                    if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()  // Maintain aspect ratio.
                                .frame(width: UIScreen.main.bounds.width, height: 300)  // Set image frame size.
                                .cornerRadius(12)  // Add rounded corners.
                                .onTapGesture {
                                    withAnimation {
                                        isFullScreen = true  // Show full-screen when tapped.
                                    }
                                }
                        } placeholder: {
                            ProgressView()  // Placeholder while loading.
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        }
                    }
                    
                    // Job title.
                    Text(job.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)  // Add padding to the left.

                    // Job metadata: time since posted and location.
                    HStack {
                        Text(jobController.timeAgoSinceDate(job.datePosted))
                            .font(.caption)

                        Text("• \(job.city)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.leading)  // Add padding to the left.

                    // Job category.
                    Text(job.category.rawValue)
                        .font(.caption)
                        .padding(.leading)
                        .padding(.bottom, 5)  // Add padding to the bottom for spacing.

                    // Job description.
                    Text(job.description)  // Assuming the description exists in the Job model.
                        .font(.body)
                        .padding(.leading)
                        .padding(.top, 5)  // Add padding at the top for spacing.
                        .padding(.bottom, 100)  // Add bottom padding for scroll space.
                }
                .navigationTitle("Job Details")  // Set the navigation bar title.
                .fullScreenCover(isPresented: $isFullScreen) {  // Present full-screen image view.
                    FullScreenImageView(imageUrl: job.imageURL, isFullScreen: $isFullScreen)
                }
            }
        }
    }
}
