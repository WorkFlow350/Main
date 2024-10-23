// FeedView.swift - Displays job listings for contractors or contractor flyers for homeowners.
import SwiftUI

// FeedView displays either job listings for contractors or contractor flyers for homeowners.
struct FeedView: View {
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
                        // Toggle between Job listings and Contractor Flyers view.
                        Picker("View", selection: $isContractor) {
                            Text("Jobs").tag(true)        // Tag for Job listings (for contractors).
                            Text("Contractors").tag(false) // Tag for Contractor Flyers (for homeowners).
                        }
                        .pickerStyle(SegmentedPickerStyle())  // Segmented picker style for the toggle.
                        .padding()
                        
                        Spacer(minLength: 5)  // Space between Picker and the content.

                        // Scrollable content area displaying posts based on the toggle state.
                        LazyVStack(spacing: 1) {
                            if isContractor {
                                // Display job posts fetched from Firebase for contractors.
                                ForEach(jobController.jobs) { job in
                                    NavigationLink(destination: JobDetailView(job: job)) {
                                        JobCellView(job: job)  // Use the JobCellView component to display job details.
                                    }
                                }
                            } else {
                                // Display contractor flyers fetched from Firebase for homeowners.
                                ForEach(contractorController.flyers) { flyer in
                                    NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                                        FlyerCellView(contractor: flyer)  // Use the FlyerCellView component to display flyer details.
                                    }
                                }
                            }
                        }
                        .navigationTitle(isContractor ? "Jobs" : "Contractors")  // Set navigation title based on toggle state.
                        .background(.clear)  // Background color set to clear.
                    }
                }
                .onAppear {
                    jobController.fetchJobs()  // Fetch jobs when the view appears.
                    contractorController.fetchFlyers()  // Fetch contractor flyers when the view appears.
                }
            }
        }
    }
}

// Preview provider for FeedView to visualize the view in Xcode's canvas.
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
