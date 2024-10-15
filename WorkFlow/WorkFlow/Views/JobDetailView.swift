//
//  JobDetailView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/14/24.
//

import SwiftUI

struct JobDetailView: View {
    let job: Job
    @StateObject private var jobController = JobController()
    @State private var isFullScreen: Bool = false // State to toggle full-screen view
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 0) {
                // Display the image that can be tapped to view full-screen
                if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit() // Maintain aspect ratio
                            .frame(width: UIScreen.main.bounds.width, height: 300)
                            .cornerRadius(12) // Rounded corners
                            .onTapGesture {
                                withAnimation {
                                    isFullScreen = true // Show full-screen when tapped
                                }
                            }
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 200) // Placeholder
                    }
                }
                
                // Job details
                Text(job.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack{
                    Text(jobController.timeAgoSinceDate(job.datePosted))
                        .font(.caption)
                    Text("• \(job.city)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                Text(job.category.rawValue)
                    .font(.caption)
                    .padding(.bottom, 5)
                
                
                Text(job.description) // Assuming there's a description in the Job model
                    .font(.body)
                    .padding(.top, 5)
                
                .padding(.bottom, 100)
            }
            .padding(.leading)
            .navigationTitle("Job Details") // Sets the title for the navigation bar
            .fullScreenCover(isPresented: $isFullScreen) { // Present full-screen view
                fullScreenImageView(imageUrl: job.imageURL, isFullScreen: $isFullScreen)
                
            }
        }
    }
}

