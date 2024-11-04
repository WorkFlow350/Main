import SwiftUI

// MARK: - JobView
struct JobView: View {
    // MARK: - Properties
    let job: Job
    @State private var isFullScreen: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // MARK: - Job Title and Details
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

            // MARK: - Image Section
            if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                if isFullScreen {
                    // MARK: - Full-Screen Image View
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    isFullScreen.toggle()
                                }
                            }
                    } placeholder: {
                        ProgressView()
                            .frame(height: 150)
                    }
                } else {
                    // MARK: - Thumbnail Image View
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .cornerRadius(12)
                            .onTapGesture {
                                withAnimation {
                                    isFullScreen.toggle()
                                }
                            }
                    } placeholder: {
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.cyan.opacity(0.1), radius: 4, x: 10, y: 14)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Preview for JobView
struct JobView_Previews: PreviewProvider {
    static var previews: some View {
        JobView(job: Job(id: UUID(), title: "Sample Job", description: "Job description goes here.", city: "Sample City", category: .construction, datePosted: Date(), imageURL: nil))
    }
}
