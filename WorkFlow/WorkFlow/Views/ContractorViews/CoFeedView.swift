import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import MapKit

struct CoFeedView: View {
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var bidController: BidController
    @State private var isContractor: Bool = true
    @State private var selectedCategory: JobCategory?
    @State private var selection = "Filter by Skills"
    @State private var location: String = ""
    @State private var isFilterJobsLocation: Bool = false
    @State private var isShowAllJobs = false
    @State private var filteredJobs: [Job] = []
    @State private var selectedCategories: [JobCategory] = []
    @State private var isLoading = false
    @State private var isShowingMap = false
    
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
                        // MARK: - Title and Filter Menu
                        HStack {
                            Text("Jobs")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Menu {
                                // My Location Button
                                Button("My Location") {
                                    Task {
                                        if await getContractorLocation() {
                                            await filterJobs(location: location, category: selectedCategory)
                                        }
                                    }
                                }
                                
                                // Show Map Button
                                Button("Show Map") {
                                    isShowingMap = true // Toggle map sheet
                                }
                                
                                Picker("Category", selection: $selectedCategory) {
                                    Text("All Categories").tag(nil as JobCategory?)
                                    ForEach(JobCategory.allCases, id: \.self) { category in
                                        Text(category.rawValue).tag(category as JobCategory?)
                                    }
                                }
                                .onChange(of: selectedCategory) { newValue in
                                    Task {
                                        await filterJobs(location: location, category: newValue)
                                    }
                                }
                                Button("Clear Filters", action: showAllJobs)
                            } label: {
                                Label("Filter Jobs", systemImage: "ellipsis.circle")
                                    .accentColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // MARK: - Job Listings
                        ScrollView {
                            if hasJobs {
                                LazyVStack(spacing: 10) {
                                    ForEach((isShowAllJobs ? jobController.jobs : filteredJobs).filter { shouldDisplayJob($0) }) { job in
                                        NavigationLink(destination: CoJobCellView(job: job)) {
                                            JobCellCoView(job: job)
                                        }
                                    }
                                }
                            } else {
                                VStack {
                                    Spacer()
                                    Text(noJobsMessage)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color.clear)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 50)
                }
                if isLoading {
                    ProgressView()
                }
            }
            .sheet(isPresented: $isShowingMap) {
                JobsMapView(
                    isShowingMap: $isShowingMap,
                    jobLocations: jobLocations()
                )
            }
            .onAppear {
                jobController.fetchJobs()
                bidController.fetchExcludedJobs()
                initializeJobsView()
            }
        }
    }
    
    // MARK: - For Maps
    private func jobLocations() -> [JobLocation] {
        (isShowAllJobs ? jobController.jobs : filteredJobs).compactMap { job in
            guard let latitude = job.latitude, let longitude = job.longitude,
                  latitude != 0.0, longitude != 0.0 else {
                print("Skipping job with invalid coordinates: \(job.title)")
                return nil
            }
            return JobLocation(id: job.id, job: job)
        }
    }
    
    // MARK: - Should Display
    private func shouldDisplayJob(_ job: Job) -> Bool {
        // Exclude jobs with statuses that shouldn't be displayed
        if bidController.excludedJobIds.contains(job.id.uuidString) {
            print("Excluding job: \(job.id.uuidString) - Status excluded")
            return false
        }
        
        // Add logic to filter out completed jobs
        if let existingBid = bidController.coBids.first(where: { $0.jobId == job.id.uuidString }) {
            if existingBid.status == .completed {
                print("Excluding job: \(job.id.uuidString) - Status is completed")
                return false
            }
        }
        
        // Apply category filter
        if let selectedCategory = selectedCategory, job.category != selectedCategory {
            print("Excluding job: \(job.id.uuidString) - Category mismatch")
            return false
        }
        
        print("Including job: \(job.id.uuidString)")
        return true
    }
    
    //MARK: Clear Filters
    func showAllJobs() {
        Task {
            isShowAllJobs = true
            isFilterJobsLocation = false
            location = ""
            selectedCategory = nil
            await jobController.fetchJobs()
            jobController.jobs = jobController.jobs.filter { shouldDisplayJob($0) }
        }
    }
    
    //MARK: Get Contractor Location
    func getContractorLocation() async -> Bool {
        await withCheckedContinuation { continuation in
            guard let userId = Auth.auth().currentUser?.uid else {
                continuation.resume(returning: false)
                return
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    print("Error fetching user document: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                    return
                }
                
                if let document = document, document.exists {
                    let data = document.data() ?? [:]
                    self.location = data["city"] as? String ?? "Unknown"
                    print("Contractor location: \(self.location)")
                    continuation.resume(returning: true)
                } else {
                    print("User document does not exist")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    //MARK: Filter Jobs
    func filterJobs(location: String?, category: JobCategory?) async {
        isLoading = true
        isFilterJobsLocation = location != nil
        isShowAllJobs = false
        
        let db = Firestore.firestore()
        let collectionRef = db.collection("jobs")
        var query: Query = collectionRef
        
        if let location = location, !location.isEmpty {
            query = query.whereField("city", isEqualTo: location)
        }
        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }
        do {
            let snapshot = try await query.getDocuments()
            self.filteredJobs = snapshot.documents.compactMap { document -> Job? in
                guard let job = try? document.data(as: Job.self) else { return nil }
                return shouldDisplayJob(job) ? job : nil
            }
            print("Filtered jobs count: \(self.filteredJobs.count)")
        } catch {
            print("Error fetching jobs: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    //MARK: For error message no jobs in Location
    var hasJobs: Bool {
        isShowAllJobs ? !jobController.jobs.isEmpty : !filteredJobs.isEmpty
    }
    
    //MARK: Function for error message no jobs in location, category
    var noJobsMessage: String {
        switch (location.isEmpty, selectedCategory) {
        case (false, .some(let category)):
            return "No \(category.rawValue) jobs found in \(location)."
        case (false, .none):
            return "No jobs found in \(location)."
        case (true, .some(let category)):
            return "No \(category.rawValue) jobs found."
        case (true, .none):
            return "No jobs found."
        }
    }
    //MARK: Function for category
    func selectCategory(_ category: JobCategory?) {
        selectedCategory = category
        Task {
            await filterJobs(location: location, category: category)
        }
    }
    
    //MARK: Initalize with just jobs in Contractor's location
    private func initializeJobsView() {
        Task {
            if filteredJobs.isEmpty {
                isLoading = true
                isShowAllJobs = true
                isFilterJobsLocation = false
                location = ""
                selectedCategory = nil
                await bidController.fetchExcludedJobs()
                await jobController.fetchJobs()
                isLoading = false
            }
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
        @State private var isFlashing = false
        
        
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
                    Text(job.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Job Type:")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text(job.category.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("City:")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text(job.city)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(jobController.timeAgoSinceDate(job.datePosted))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        if let status = bidStatus {
                            Text("Bid Status: \(status.capitalized)")
                                .font(.caption)
                                .foregroundColor(statusColor(for: status))
                        }
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
            .background(
                BlurView(style: .systemThickMaterialLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .cornerRadius(12)
            .onAppear {
                updateBidStatus()
            }
            .onChange(of: bidController.coBids) { _ in
                updateBidStatus()
            }
        }
        
        // MARK: - Status Color
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
        
        // MARK: - Update Bid Status
        private func updateBidStatus() {
            guard let contractorId = authController.userSession?.uid else {
                bidStatus = nil
                bidPrice = nil
                return
            }
            if let existingBid = bidController.coBids.first(where: { $0.jobId == job.id.uuidString && $0.contractorId == contractorId }) {
                bidStatus = existingBid.status.rawValue
                bidPrice = existingBid.price
            } else {
                // Fetch bid from Firestore
                bidController.fetchBid(byJobId: job.id.uuidString, contractorId: contractorId) { fetchedBid in
                    DispatchQueue.main.async {
                        if let fetchedBid = fetchedBid {
                            self.bidStatus = fetchedBid.status.rawValue
                            self.bidPrice = fetchedBid.price
                        } else {
                            self.bidStatus = nil
                            self.bidPrice = nil
                        }
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
}
