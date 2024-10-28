// JobView.swift - Displays individual job details, including title, description, category, and a thumbnail image with a full-screen toggle.
import SwiftUI

// View for displaying individual job details, including a thumbnail image.
struct JobView: View {
    let job: Job
    @State private var isFullScreen: Bool = false  // State to toggle full-screen image view.

    var body: some View {
        VStack(alignment: .center, spacing: 10) {  // Center content horizontally.
            // Job title and details.
            Text(job.title)
                .font(.headline)
                .foregroundColor(.black)
                .fontWeight(.bold)
                .font(.system(size: 18))

            Text(job.description)
                .font(.body)
                .foregroundColor(.gray)
                .font(.system(size: 14))

            Text(job.category.rawValue)
                .font(.subheadline)
                .foregroundColor(.blue)
                .font(.system(size: 14))

            // Thumbnail image section placed under the category.
            if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                if isFullScreen {
                    // Full-screen image view.
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()  // Aspect fit for full-screen image.
                            .ignoresSafeArea()  // Cover the entire screen.
                            .onTapGesture {
                                withAnimation {
                                    isFullScreen.toggle()  // Toggle back to thumbnail view.
                                }
                            }
                    } placeholder: {
                        ProgressView()
                            .frame(height: 150)
                    }
                } else {
                    // Thumbnail image.
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()  // Fill the square frame for thumbnail.
                            .frame(width: 100, height: 100)  // Set as a small square (100x100).
                            .cornerRadius(12)  // Corner radius for thumbnail.
                            .onTapGesture {
                                withAnimation {
                                    isFullScreen.toggle()  // Toggle to full-screen view.
                                }
                            }
                    } placeholder: {
                        ProgressView()
                            .frame(width: 100, height: 100)  // Placeholder same size as image.
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150)  // Stretch to full width and set minimum height.
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.cyan.opacity(0.1), radius: 4, x: 10, y: 14)  // Soft shadow.
        .multilineTextAlignment(.center)  // Center the text horizontally.
    }
}

// Preview provider for JobView to visualize the view in Xcode's canvas.
struct JobView_Previews: PreviewProvider {
    static var previews: some View {
        JobView(job: Job(id: UUID(), title: "Sample Job", description: "Job description goes here.", city: "Sample City", category: .construction, datePosted: Date(), imageURL: nil))
    }
}
