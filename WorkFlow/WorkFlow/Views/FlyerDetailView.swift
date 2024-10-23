// FlyerDetailView.swift - Displays detailed information about a contractor's flyer, including image, service area, and contact info.
import SwiftUI

struct FlyerDetailView: View {
    let contractor: ContractorProfile
    @StateObject private var contractController = ContractorController()  // Initialize ContractorController to manage contractor data.
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
                VStack(alignment: .leading) {
                    // Display the contractor's image, which can be tapped to view full-screen.
                    if let imageURL = contractor.imageURL, let url = URL(string: imageURL) {
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

                    // Contractor name.
                    Text(contractor.contractorName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)  // Add padding to the left.

                    // Service area information.
                    HStack {
                        Text("Service Area: \(contractor.city)")
                            .font(.subheadline)
                    }
                    .padding(.leading)  // Add padding to the left.

                    // Contact information.
                    Text("Contact: \(contractor.email)")
                        .font(.subheadline)
                        .padding(.leading)
                        .padding(.bottom, 5)  // Add padding to the bottom for spacing.

                    // Contractor's bio.
                    Text(contractor.bio)  // Assuming the bio exists in the ContractorProfile model.
                        .font(.body)
                        .padding(.leading)
                        .padding(.top, 5)  // Add padding at the top for spacing.
                        .padding(.bottom, 100)  // Add bottom padding for scroll space.
                }
                .fullScreenCover(isPresented: $isFullScreen) {  // Present full-screen image view.
                    FullScreenImageView(imageUrl: contractor.imageURL, isFullScreen: $isFullScreen)
                }
            }
        }
    }
}
