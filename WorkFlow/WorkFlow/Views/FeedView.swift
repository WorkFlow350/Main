import SwiftUI

struct FeedView: View {
    // MARK: - State Objects
    @StateObject private var jobController = JobController()
    @StateObject private var contractorController = ContractorController()
    @State private var isContractor: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack {
                        // MARK: - Toggle Picker
                        Picker("View", selection: $isContractor) {
                            Text("Jobs").tag(true)
                            Text("Contractors").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        Spacer(minLength: 5)

                        // MARK: - Scrollable Content Area
                        LazyVStack(spacing: 1) {
                            if isContractor {
                                ForEach(jobController.jobs) { job in
                                    NavigationLink(destination: JobDetailView(job: job)) {
                                        JobCellView(job: job)
                                    }
                                }
                            } else {
                                ForEach(contractorController.flyers) { flyer in
                                    NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                                        FlyerCellView(contractor: flyer)
                                    }
                                }
                            }
                        }
                        .navigationTitle(isContractor ? "Jobs" : "Contractors")
                        .background(.clear)
                    }
                }
                .onAppear {
                    jobController.fetchJobs()
                    contractorController.fetchFlyers()
                }
            }
        }
    }
}

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
