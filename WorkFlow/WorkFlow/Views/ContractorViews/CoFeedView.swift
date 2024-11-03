import SwiftUI

// MARK: - Contractor Feed View
struct CoFeedView: View {
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController
    @State private var isContractor: Bool = true

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

                // MARK: - Scrollable Content
                ScrollView {
                    VStack(alignment: .leading) {
                        // MARK: - Title
                        Text("Jobs")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        Spacer(minLength: 10)

                        // MARK: - Job Listings
                        LazyVStack(spacing: 1) {
                            ForEach(jobController.jobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCellView(job: job)
                                }
                            }
                        }
                    }
                    .background(Color.clear)
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
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
