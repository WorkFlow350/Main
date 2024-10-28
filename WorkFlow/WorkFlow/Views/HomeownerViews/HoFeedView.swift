//
//  HoFeedView.swift
//  WorkFlow
//
//  Created by Jason Rincon on 10/26/24.
//

import SwiftUI

// FeedView displays either job listings for contractors or contractor flyers for homeowners.
struct HoFeedView: View {
    @StateObject private var jobController = JobController()  // Initialize JobController to manage job data.
    @StateObject private var contractorController = ContractorController()  // Initialize ContractorController to manage contractor flyer data.
    @State private var isContractor: Bool = true  // State to toggle between Job listings or Contractor Flyers.

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient for the view.
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack {
                        Spacer(minLength: 10)  // Space between title and the content.

                        // Scrollable content area displaying posts based on the toggle state.
                        LazyVStack(spacing: 1) {
                                // Display contractor flyers fetched from Firebase for homeowners.
                                ForEach(contractorController.flyers) { flyer in
                                    NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                                        FlyerCellView(contractor: flyer)  // Use the FlyerCellView component to display flyer details.
                                    }
                                }
                            }
                        }
                        .navigationTitle("Contractors")  // Set navigation title
                        .background(.clear)  // Background color set to clear.
                    }
                }
                .onAppear {
                    contractorController.fetchFlyers()  // Fetch contractor flyers when the view appears.
                }
            }
        }
    }

// Preview provider for FeedView to visualize the view in Xcode's canvas.
struct HoFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HoFeedView()
    }
}
