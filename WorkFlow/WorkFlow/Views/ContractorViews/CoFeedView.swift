import SwiftUI
import FirebaseAuth

enum JobFilter: String, CaseIterable {
    case all = "All Jobs"
    case landscaping = "Landscaping"
    case cleaning = "Cleaning"
    case construction = "Construction"
}


// MARK: - Contractor Feed View
struct CoFeedView: View {
    
    @State private var selectedFilter: JobFilter = .all
    @State private var isFilterMenuVisible: Bool = false
    @State private var selectedCategories: [JobCategory] = []
    
    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var bidController: BidController
    
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

                        Spacer()

                        //filterDropdown
                        
                        // MARK: - Job Listings
                        LazyVStack(spacing: 1) {
                            ForEach(jobController.jobs.filter { job in
                                shouldDisplayJob(job)
                            }) { job in
                                NavigationLink(destination: CoJobCellView(job: job)) {
                                    JobCellCoView(job: job)
                                }
                            }
                        }
                    }
                    .background(Color.clear)
                }
                .padding(.bottom, 43)
                .onAppear {
                    jobController.fetchJobs()
                    bidController.getBidsForContractor()
                }
            }
        }
    }
    
    // MARK: - Filter Jobs
//    private var filterDropdown: some View {
//        DisclosureGroup("Filter Jobs", isExpanded: $isFilterMenuVisible) {
//            VStack(alignment: .leading, spacing: 2) {
//                ForEach(JobFilter.allCases, id: \.self) { filter in
//                    Button(action: {
//                        toggleCategorySelection(filter)
//                    }) {
//                        HStack {
//                            Text(filter.rawValue)
//                                .foregroundColor(.white)
//                            Spacer()
//                            if selectedCategories.contains(where: { $0.rawValue == filter.rawValue }) {
//                                Image(systemName: "checkmark")
//                                    .foregroundColor(.blue)
//                            }
//                        }
//                        .padding(.vertical, 3)
//                    }
//                }
//            }
//            .padding(.horizontal, 8)
//            .padding(.vertical, 5)
//        }
//        .padding(.horizontal, 5)
//        .frame(maxWidth: 152)
//        .background(Color.white.opacity(0.2))
//        .cornerRadius(8)
//    }
    private func toggleCategorySelection(_ filter: JobFilter) {
        if filter == .all {
            selectedCategories.removeAll()
        } else {
            if let category = JobCategory(rawValue: filter.rawValue) {
                if selectedCategories.contains(category) {
                    selectedCategories.removeAll { $0 == category }
                } else {
                    selectedCategories.append(category)
                }
            }
        }
    }

    // MARK: - Jobs To Display
    private func shouldDisplayJob(_ job: Job) -> Bool {
        if let contractorId = authController.userSession?.uid {
            if let existingBid = bidController.coBids.first(where: { $0.jobId == job.id.uuidString && $0.contractorId == contractorId }) {
                if existingBid.status == .accepted || existingBid.status == .completed {
                    return false
                }
            }
        }
        if selectedCategories.isEmpty {
            return true
        }
        return selectedCategories.contains(job.category)
    }
}

// MARK: - JobCellView (for displaying job details)
struct JobCellCoView: View {
    let job: Job
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var jobController: JobController
    @State private var bidStatus: String? = nil
    @State private var bidPrice: Double? = nil

    var body: some View {
        HStack {
            if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing, 8)
                } placeholder: {
                    Color.gray
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(job.city) - \(job.category.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                Text(job.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(jobController.timeAgoSinceDate(job.datePosted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let status = bidStatus {
                    Text("Status: \(status.capitalized)\(bidPrice != nil ? " | Your Current Bid: $\(String(format: "%.2f", bidPrice!))" : "")")
                        .font(.caption)
                        .foregroundColor(statusColor(for: status))
                }
            }
            
            Spacer()
            
            Rectangle()
                .frame(width: 4)
                .foregroundColor(categoryColor(for: job.category))
                .cornerRadius(2)
                .padding(.vertical, 8)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            updateBidStatus()
        }
        .onChange(of: bidController.coBids) { _ in
            updateBidStatus()
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "accepted":
            return .green
        case "declined":
            return .red
        case "completed":
            return .blue
        default:
            return .gray
        }
    }

    private func updateBidStatus() {
        if let contractorId = authController.userSession?.uid {
            if let existingBid = bidController.coBids.first(where: { $0.jobId == job.id.uuidString && $0.contractorId == contractorId }) {
                bidStatus = existingBid.status.rawValue
                bidPrice = existingBid.price
            } else {
                bidStatus = nil
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
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
    }
}
