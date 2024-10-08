import SwiftUI

// FeedView displays either job listings for contractors or placeholder for contractor flyers for homeowners
struct FeedView: View {
    @StateObject private var jobController = JobController() // Initialize JobController to manage job data
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
                    Spacer(minLength: 20) // Space between Picker and the content
                    LazyVStack(spacing: 20) {
                        if isContractor {
                            // Display job posts fetched from Firebase for contractors
                            ForEach(jobController.jobs) { job in
                                JobView(job: job) // Use the JobView component to display job details
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                            }
                        } else {
                            // Placeholder text for contractor flyers
                            Text("Here goes the contractor flyers")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle(isContractor ? "Jobs" : "Contractors")
                .background(Color(UIColor.systemGray6)) // Background color for the view
            }
        }
        .onAppear {
            jobController.fetchJobs() // Fetch jobs when the view appears
        }
    }
}

// Preview provider for FeedView
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
