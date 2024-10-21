//
//  FlyerDetailView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/15/24.
//


import SwiftUI

struct FlyerDetailView: View {
    let contractor: ContractorProfile
    @StateObject private var contractController = ContractorController()
    @State private var isFullScreen: Bool = false // State to toggle full-screen view
    var body: some View {
        ZStack{
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        ScrollView{
            VStack(alignment: .leading) {
                // Display the image that can be tapped to view full-screen
                if let imageURL = contractor.imageURL, let url = URL(string: imageURL) {
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
                Text(contractor.contractorName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                
                HStack{
                    Text("Service Area: \(contractor.city)")
                        .font(.subheadline)
                    
                }
                .padding(.leading)
                
                Text("Contact: \(contractor.email)")
                    .font(.subheadline)
                    .padding(.leading)
                    .padding(.bottom, 5)
                
                
                Text(contractor.bio) // Assuming there's a description in the Job model
                    .font(.body)
                    .padding(.leading)
                    .padding(.top, 5)
                
                    .padding(.bottom, 100)
            }
            //.padding(.leading)
            //.navigationTitle(contractor.contractorName) // Sets the title for the navigation bar
            .fullScreenCover(isPresented: $isFullScreen) { // Present full-screen view
                fullScreenImageView(imageUrl: contractor.imageURL, isFullScreen: $isFullScreen)
                
                }
            }
        }
    }
}
//testing to go to main
//add another thing for main
