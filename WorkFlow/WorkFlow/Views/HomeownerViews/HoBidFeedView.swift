import SwiftUI
import FirebaseAuth
struct HoBidFeedView: View {
    @ObservedObject var homeownerJobController = HomeownerJobController() // HomeownerJobController instance
    @ObservedObject var bidController = BidController() // BidController instance
    @State private var selectedJob: Job? // To keep track of the selected job
    var body: some View {
        NavigationView {
            VStack {
                // List of Homeowner Jobs
                List(homeownerJobController.homeownerJobs) { job in
                    VStack(alignment: .leading) {
                        Text(job.title)
                            .font(.headline)
                        Text(job.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Category: \(job.category.rawValue)")
                            .font(.footnote)
                            .foregroundColor(.blue)
                        Text("Posted on: \(job.datePosted, style: .date)")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    .onTapGesture {
                        // Fetch bids for the selected job
                        selectedJob = job
                        bidController.getBidsForJob(job: job)
                    }
                }
                
                // Show Bids if a job is selected
                if let selectedJob = selectedJob {
                    VStack(alignment: .leading) {
                        Text("Bids for \(selectedJob.title):")
                            .font(.title2)
                            .padding()
                        
                        List(bidController.jobBids, id: \.id) { bid in
                            VStack(alignment: .leading) {
                                Text("Amount: \(bid.price)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("Description: \(bid.description)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Status: \(bid.status.rawValue.capitalized)")
                                    .font(.footnote)
                                    .foregroundColor(bid.status == .accepted ? .green : bid.status == .declined ? .red : .orange)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Jobs")
            .onAppear {
                // Fetch the jobs when the view appears
                if let homeownerId = Auth.auth().currentUser?.uid {
                    homeownerJobController.fetchJobsForHomeowner(homeownerId: homeownerId)
                }
            }
        }
    }
}


