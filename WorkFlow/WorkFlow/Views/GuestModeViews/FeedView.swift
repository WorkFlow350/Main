import SwiftUI

struct FeedView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController
    
    @State private var isContractor: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Background
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
                        Text(isContractor ? "Jobs" : "Contractors")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        Spacer(minLength: 10)

                        // MARK: - Toggle Picker
                        Picker("View", selection: $isContractor) {
                            Text("Jobs").tag(true)
                            Text("Contractors").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        // MARK: - Scrollable Content Area
                        LazyVStack(spacing: 1) {
                            if isContractor {
                                ForEach(jobController.jobs) { job in
                                    NavigationLink(destination: JobDetailView(job: job)) {
                                        JobCellView(job: job)
                                    }
                                }
                            } else {
                                ForEach(flyerController.flyers) { flyer in
                                    NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                                        FlyerCellView(contractor: flyer)
                                    }
                                }
                            }
                        }
                        .background(Color.clear)
                    }
                    .padding(.bottom, 20) // Padding to separate from the bottom
                }
            }
            .onAppear {
                jobController.fetchJobs()
                flyerController.fetchFlyers()
            }
        }
    }
}

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
    }
}
