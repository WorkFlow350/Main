//
//  JobCellView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/14/24.
//

import SwiftUI


struct JobCellView: View {
    let job: Job
    @State private var isFullScreen: Bool = false // State to toggle full-screen view
    @StateObject private var jobController = JobController()
    var body: some View {
        VStack{
            HStack{
                if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                    if isFullScreen {
                        // Full-Screen Image
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit() // Aspect fit for full-screen image
                                .ignoresSafeArea() // Cover the entire screen
                                .onTapGesture {
                                    withAnimation {
                                        isFullScreen.toggle() // Toggle back to thumbnail view
                                    }
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(height: 150)
                        }
                    } else {
                        // Thumbnail Image (set as a small box)
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill() // Fill the square frame for thumbnail
                                .frame(width: 100, height: 100) // Small square frame (100x100)
                                .cornerRadius(12) // Corner radius for thumbnail
                                .onTapGesture {
                                    withAnimation {
                                        isFullScreen.toggle() // Toggle to full-screen view
                                    }
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(width: 100, height: 100) // Placeholder same size as image
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 0) { // Set spacing to 0 for tight layout
                    HStack {
                        // Job city and category
                        Text(job.city)
                            .font(.caption)
                            .foregroundColor(.black)
                            .fontWeight(.medium)
                        Text(job.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 0) // Remove bottom padding from HStack
                    
                    // Job title
                    Text(job.title)
                        .font(.headline)
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                    //.font(.system(size: 18))
                        .padding(.top, 5) // Optional: set a small top padding for spacing
                        .padding(.bottom, 5) // Optional: set a small bottom padding for spacing
                    Text(jobController.timeAgoSinceDate(job.datePosted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

            }
            
        }
        .frame(maxWidth: .infinity)
        .padding(8) // Overall padding around the entire VStack if needed
        .background(Color.white) // Background color for visibility
        .cornerRadius(8) // Rounded corners
        .shadow(radius: 2) // Optional shadow for better UI
        }

}

// Preview provider for JobView
struct JobCellView_Previews: PreviewProvider {
    static var previews: some View {
        JobCellView(job: Job(id: UUID(), title: "Garden needs work", description: "Job description goes here.", city: "Oxnard", category: .construction, datePosted: Date(), imageURL: "metalRoof"))
    }
}
