import SwiftUI

// FeedView displays either job listings for contractors or placeholder for contractor flyers for homeowners
struct FeedView: View {
    @StateObject private var jobController = JobController() // Initialize JobController to manage job data
    @StateObject private var contractorController = ContractorController()
    @State private var isContractor: Bool = true  // State to toggle between Job listings (for contractors) or Contractor Flyers (for homeowners)

    var body: some View {
        NavigationView {
            VStack {
                // Toggle between Job listings and Contractor Flyers view
                Picker("View", selection: $isContractor) {
                    Text("Jobs").tag(true) // Tag for Job listings (for contractors)
                    Text("Contractors").tag(false) // Tag for Contractor Flyers (for homeowners)
                }
                .pickerStyle(SegmentedPickerStyle()) // Segmented picker style for the toggle
                .padding()

                // Scrollable content area displaying posts based on the toggle state
                ScrollView {
                    Spacer(minLength: 5) // Space between Picker and the content
                    LazyVStack(spacing: 1) {
                        if isContractor {
                            // Display job posts fetched from Firebase for contractors
                            ForEach(jobController.jobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)){
                                    JobCellView(job: job) // Use the JobView component to display job details
                                }
                            }
                        } else {
                            ForEach(contractorController.flyers) { flyer in
                                NavigationLink(destination: FlyerDetailView(contractor: flyer)){
                                    FlyerCellView(contractor: flyer) // Use the JobView component to display job details
                                }
                            }
                            
                        }
                    }
                    //.padding(.horizontal)
                }
                .navigationTitle(isContractor ? "Jobs" : "Contractors")
                .background(Color(UIColor.systemGray6)) // Background color for the view
            }
        }
        .onAppear {
            jobController.fetchJobs() // Fetch jobs when the view appears
            contractorController.fetchFlyers()
        }
    }
}

// Preview provider for FeedView
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
