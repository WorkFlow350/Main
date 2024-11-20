import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct CoFeedView: View {
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController
    @EnvironmentObject var authController: AuthController
    @State private var isContractor: Bool = true
    @State private var selectedCategory: JobCategory?
    @State private var selection = "Filter by Skills"
    @State private var location: String = ""
    @State private var isFilterJobsLocation: Bool = false
    @State private var isShowAllJobs = false
    @State private var filteredJobs: [Job] = []
    @State private var isLoading = false
    
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
                                Button("My Location") {
                                    Task {
                                        if await getContractorLocation() {
                                            await filterJobs(location: location, category: selectedCategory)
                                        }
                                    }
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
                                Button("Clear", action: showAllJobs)
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
                                    ForEach(isShowAllJobs ? jobController.jobs : filteredJobs) { job in
                                        NavigationLink(destination: CoJobCellView(job: job)) {
                                            JobCellView(job: job)
                                        }
                                    }
                                }
                            } else {
                                VStack {
                                    Spacer()
                                    Text(noJobsMessage)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.clear)
                    }
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                initializeJobsView()// show only jobs by location by default
            }
        }
    }
    
    //MARK: function for clear button to show all jobs
    func showAllJobs() {
        Task {
            isShowAllJobs = true
            isFilterJobsLocation = false
            location = ""
            selectedCategory = nil
            await jobController.fetchJobs()
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
                try? document.data(as: Job.self)
            }
            print("Total jobs fetched: \(self.filteredJobs.count)")  //debug
        } catch {
            print("Error fetching jobs: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    //MARK: for error message no jobs in Location
    var hasJobs: Bool {
        isShowAllJobs ? !jobController.jobs.isEmpty : !filteredJobs.isEmpty
    }

    //MARK: function for error message no jobs in location, category
    var noJobsMessage: String {
        switch (location.isEmpty, selectedCategory) {
        case (false, .some(let category)):
            return "No \(category.rawValue) jobs found in \(location)"
        case (false, .none):
            return "No jobs found in \(location)"
        case (true, .some(let category)):
            return "No \(category.rawValue) jobs found"
        case (true, .none):
            return "No jobs found"
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
        isLoading = true
        if await getContractorLocation() {
            await filterJobs(location: self.location, category: selectedCategory)
        } else {
            showAllJobs()
        }
        isLoading = false
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

