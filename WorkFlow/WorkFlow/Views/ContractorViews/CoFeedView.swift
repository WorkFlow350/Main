import SwiftUI

// MARK: - Contractor Feed View
struct CoFeedView: View {
    @StateObject private var jobController = JobController()
    @StateObject private var contractorController = ContractorController()
    @State private var isContractor: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // MARK: - Content Area
                ScrollView {
                    VStack {
                        Spacer(minLength: 10)

                        // MARK: - Job Listings
                        LazyVStack(spacing: 1) {
                            ForEach(jobController.jobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCellView(job: job)
                                }
                            }
                        }
                        .navigationTitle("Jobs")
                        .background(.clear)
                    }
                }
                .onAppear {
                    jobController.fetchJobs()
                }
            }
        }
    }
}

// MARK: - Preview
struct CoFeedView_Previews: PreviewProvider {
    static var previews: some View {
        CoFeedView()
    }
}
