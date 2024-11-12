import SwiftUI
import FirebaseAuth
import FirebaseFirestore
// MARK: - HoBidFeedView
struct HoBidFeedView: View {
    @ObservedObject var homeownerJobController = HomeownerJobController()
    @ObservedObject var bidController = BidController()
    @State private var selectedJobId: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                        Color.black.opacity(0.99)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Scrollable Content
                ScrollView {
                    VStack(alignment: .leading) {
                        // Title
                        Text("My Jobs")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        Spacer(minLength: 10)

                        // Job List with Dropdown for Bids
                        LazyVStack(spacing: 10) {
                            ForEach(homeownerJobController.homeownerJobs) { job in
                                VStack {
                                    // Job Cell View
                                    JobCellYView(job: job, bidController: bidController)
                                        .onTapGesture {
                                            if selectedJobId == job.id {
                                                selectedJobId = nil // Deselect job
                                            } else {
                                                selectedJobId = job.id // Select job
                                                bidController.getBidsForJob(job: job)
                                            }
                                        }

                                    // Bid Cells for Selected Job
                                    if selectedJobId == job.id {
                                        VStack(alignment: .leading) {
                                            if bidController.jobBids.isEmpty {
                                                // Display "No Bids" message if no bids are available
                                                Text("No Bids")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal)
                                            }
                                            else{
                                                ForEach(bidController.jobBids) { bid in
                                                    NavigationLink(destination: DetailedBidView(bid: bid,bidController: bidController)) {
                                                        BidCellYView(bid: bid)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                    .padding(.bottom,75)
                    .background(Color.clear)
                }
            }
            .onAppear {
                // Fetch jobs on appear
                if let homeownerId = Auth.auth().currentUser?.uid {
                    homeownerJobController.fetchJobsForHomeowner(homeownerId: homeownerId)
                }
            }
        }
    }
}

// MARK: - JobCellView (for displaying job details)
struct JobCellYView: View {
    let job: Job
    @ObservedObject var bidController: BidController
    @State private var bidCount: Int = 0
    @EnvironmentObject var jobController: JobController

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

                Text(jobController.timeAgoSinceDate(job.datePosted))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Bids: \(bidCount)")
                    .font(.caption)
                    .foregroundColor(.gray)
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
            // Fetch the bid count when the view appears
            bidController.countBidsForJob(jobId: job.id) { count in
                bidCount = count
            }
        }
    }
}

// MARK: - BidCellView (for displaying individual bid details)
struct BidCellYView: View {
    let bid: Bid
    let maxDescriptionLength = 25
    
    @State private var contractorProfile: ContractorProfile?
    @State private var isProfileLoaded = false
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bid Details
            HStack {
                Text("Amount: \(bid.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()
                
                Text("Status: \(bid.status.rawValue.capitalized)")
                    .font(.footnote)
                    .foregroundColor(bid.status == .accepted ? .green : bid.status == .declined ? .red : .orange)
            }
            
            Text("Description: \(limitedDescription)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Contractor Profile - Display once it's loaded
            if isProfileLoaded, let profile = contractorProfile {
                HStack {
                    // Profile Picture
                    if let imageURL = profile.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } placeholder: {
                            Color.gray
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                    } else {
                        Color.gray
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    // Contractor Details
                    VStack(alignment: .leading) {
                        Text(profile.contractorName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text(profile.city)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .onAppear {
            // Fetch the contractor profile for this bid when the bid cell appears
            getContractorProfile(contractorId: bid.contractorId) { profile in
                if let profile = profile {
                    self.contractorProfile = profile
                    self.isProfileLoaded = true
                }
            }
        }
    }

    private var limitedDescription: String {
        if bid.description.count > maxDescriptionLength {
            let prefixText = bid.description.prefix(maxDescriptionLength)
            return "\(prefixText)..."
        } else {
            return bid.description
        }
    }

    private func getContractorProfile(contractorId: String, completion: @escaping (ContractorProfile?) -> Void) {
        // Fetching contractor profile from Firestore
        db.collection("users").document(contractorId).getDocument { document, error in
            if let error = error {
                print("Error fetching contractor profile: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = document?.data() else {
                print("No contractor profile found")
                completion(nil)
                return
            }

            // Create ContractorProfile from Firestore data
            let profile = ContractorProfile(
                id: UUID(uuidString: document!.documentID) ?? UUID(),
                contractorName: data["name"] as? String ?? "Unknown",
                bio: data["bio"] as? String ?? "",
                skills: data["skills"] as? [String] ?? [],
                rating: data["rating"] as? Double ?? 0.0,
                jobsCompleted: data["jobsCompleted"] as? Int ?? 0,
                city: data["city"] as? String ?? "",
                email: data["email"] as? String ?? "",
                imageURL: data["profilePictureURL"] as? String
            )
            completion(profile)
        }
    }
}

struct DetailedBidView: View {
    let bid: Bid
    @ObservedObject var bidController: BidController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Display Bid Amount
            Text("Bid Amount: \(bid.price, specifier: "%.2f")")
                .font(.title)
                .foregroundColor(.green)

            // Description section
            Text("Description")
                .font(.headline)
                .padding(.top, 10)
            Text(bid.description)
                .font(.body)

            // Display Bid Status
            Text("Status: \(bid.status.rawValue.capitalized)")
                .font(.headline)
                .foregroundColor(bid.status == .accepted ? .green : bid.status == .declined ? .red : .orange)

            // Buttons to Accept or Decline
            HStack {
                // Accept Button
                Button(action: {
                    bidController.acceptBid(bidId: bid.id, jobId: bid.jobId)
                }) {
                    Text("Accept")
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                }
                .disabled(bid.status != .pending) // Disable if status is not pending

                // Decline Button
                Button(action: {
                    bidController.declineBid(bidId: bid.id)
                }) {
                    Text("Decline")
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                }
                .disabled(bid.status != .pending) // Disable if status is not pending
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .navigationTitle("Bid Details")
    }
}




