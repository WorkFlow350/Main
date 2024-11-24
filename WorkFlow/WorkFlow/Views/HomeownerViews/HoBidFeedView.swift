

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
// MARK: - HoBidFeedView
struct HoBidFeedView: View {
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var bidController: BidController
    @State private var selectedJobId: UUID?

    var body: some View {
        NavigationView {
            ZStack {
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
                        Text("My Bids")
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
                                    JobCellYView(job: job)
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
                                                    NavigationLink(destination: DetailedBidView(bid: bid)) {
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
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @State private var bidCount: Int = 0
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
                
                Text("Bids: \(bidCount)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
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
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var homeownerJobController: HomeownerJobController

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
                    .foregroundColor(
                        bid.status == .accepted ? .green :
                        bid.status == .declined ? .red :
                        bid.status == .completed ? .blue :
                        .orange
                    )
            }
            
            Text("Description: \(limitedDescription)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
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
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(bidController.timeAgoSincePost(bid.bidDate))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(
            BlurView(style: .systemThickMaterialLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .cornerRadius(12)
        .shadow(radius: 5)
        .onAppear {
            // Fetch the contractor profile for this bid when the bid cell appears
            bidController.getContractorProfile(contractorId: bid.contractorId) { profile in
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
}


//MARK: Separate Page for Bid Info and Contractor Profile
struct DetailedBidView: View {
    let bid: Bid
    @EnvironmentObject var bidController: BidController
    @State private var contractorProfile: ContractorProfile?
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var authController: AuthController

    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#4A90E2"),
                    Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            //.ignoresSafeArea(edges: .top)
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Bid Amount
                    VStack(alignment: .leading) {
                        Text("Bid Amount:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("$\(bid.price, specifier: "%.2f") USD")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading) {
                        Text("Bid Description:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(bid.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Status
                    VStack(alignment: .leading) {
                        Text("Status:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(bid.status.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(
                                bid.status == .accepted ? .green :
                                bid.status == .declined ? .red :
                                bid.status == .completed ? .blue :
                                .orange
                            )
                            .fontWeight(.semibold)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // MARK: - Contractor Profile
                    if let profile = contractorProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contractor Profile:")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            HStack(spacing: 12) {
                                // Profile Picture
                                if let imageURL = profile.imageURL, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .shadow(radius: 3)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                    }
                                }
                                
                                // Contractor Details
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Name: \(profile.contractorName)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    Text("City: \(profile.city)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", profile.rating))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Skills:")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Text(profile.skills.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Bio:")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                
                                Text(profile.bio)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            // MARK: - Message Button
                            NavigationLink(
                                destination: ChatDetailView(
                                    conversationId: bid.conversationId,
                                    receiverId: profile.id.uuidString
                                )
                            ) {
                                Text("Message Contractor")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.top, 10)
                    }
                    
                    Divider()
                    
                    // Show Accept/Decline buttons only if the bid is pending
                    if bid.status == .pending {
                        HStack {
                            // MARK: - Accept Button
                            Button(action: {
                                bidController.acceptBid(bidId: bid.id, jobId: bid.jobId)
                            }) {
                                Text("Accept")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                            
                            // MARK: - Decline Button
                            Button(action: {
                                bidController.declineBid(bidId: bid.id)
                            }) {
                                Text("Decline")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
                .background(
                    BlurView(style: .systemThickMaterialLight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding()
            }
            .navigationTitle("Bid Details")
            .onAppear {
                bidController.getContractorProfile(contractorId: bid.contractorId) { profile in
                    self.contractorProfile = profile
                }
            }
        }
    }
}

