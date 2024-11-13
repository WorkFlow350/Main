import SwiftUI

// MARK: - CoMyJobsView
struct CoMyJobsView: View {
    @State private var selectedTab: JobTab = .pending
    
    // MARK: - Environment Objects
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @State private var selectedJob: Job?

    enum JobTab: String, CaseIterable {
        case pending = "Pending"
        case approved = "Approved"
        case completed = "Completed"
    }

    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                        Color.black.opacity(0.99)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 10) {
                    // MARK: - Title
                    Text("My Jobs")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // MARK: - Job Status Picker
                    Picker("Job Status", selection: $selectedTab) {
                        ForEach(JobTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // MARK: - Job List
                    List(filteredJobs(for: selectedTab)) { job in
                        VStack(alignment: .leading) {
                            Text(job.title)
                                .font(.headline)
                            Text("Description: \(job.description)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Category: \(job.category.rawValue)")
                                .font(.footnote)
                                .foregroundColor(.blue)
                            Text("Posted on: \(job.datePosted, style: .date)")
                                .font(.footnote)
                                .foregroundColor(.blue)

                            if selectedTab == .approved {
                                // MARK: - Complete Job Button
                                Button("Mark as Completed") {
                                    markJobAsCompleted(for: job)
                                }
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .onTapGesture {
                            selectedJob = job
                            bidController.getBidsForJob(job: job)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
                .padding(.bottom, 10)

                if let selectedJob = selectedJob {
                    jobBidsView(for: selectedJob)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .padding()
                }
            }
            .onAppear {
                bidController.getBidsForContractor()
            }
        }
    }
    
    // MARK: - Filter Jobs Based on Tab
    private func filteredJobs(for tab: JobTab) -> [Job] {
        let bids = bidController.coBids
        switch tab {
        case .pending:
            return jobs(for: bids, withStatus: .pending)
        case .approved:
            return jobs(for: bids, withStatus: .accepted)
        case .completed:
            return jobs(for: bids, withStatus: .completed)
        }
    }

    private func jobs(for bids: [Bid], withStatus status: Bid.bidStatus) -> [Job] {
        return bids.filter { $0.status == status }
            .compactMap { bid in
                homeownerJobController.homeownerJobs.first { $0.id.uuidString == bid.jobId }
            }
    }
    
    // MARK: - Mark Job as Completed
    private func markJobAsCompleted(for job: Job) {
        if let bid = bidController.coBids.first(where: { $0.jobId == job.id.uuidString && $0.status == .accepted }) {
            bidController.updateBidStatus(bidId: bid.id, status: .completed)
        }
    }

    // MARK: - Job Bids View
    private func jobBidsView(for job: Job) -> some View {
        VStack(alignment: .leading) {
            Text("Bids for \(job.title):")
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
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - Preview
struct CoMyJobsView_Previews: PreviewProvider {
    static var previews: some View {
        CoMyJobsView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
    }
}
