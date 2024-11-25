import SwiftUI
import FirebaseAuth
import Combine

// MARK: - CoMyJobsView
struct CoMyJobsView: View {
    @State private var selectedTab: JobTab = .all
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var homeownerJobController:
    HomeownerJobController
    @EnvironmentObject var authController: AuthController
    @State private var selectedJob: Job?

    enum JobTab: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case accepted = "Accepted"
        case completed = "Completed"
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                VStack(alignment: .leading, spacing: 10) {
                    title
                    jobStatusPicker
                    jobListView
                }
                .padding(.bottom, 10)
            }
            .onAppear {
                bidController.fetchContractorBidsByStatus()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                Color.black.opacity(0.99)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var title: some View {
        Text("My Jobs")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.top, 20)
    }

    private var jobStatusPicker: some View {
        HStack {
            Spacer()
            ForEach(JobTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 12))
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == tab ? .black : .white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ? Color.white : Color.clear)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var jobListView: some View {
        List(currentBids()) { bid in
            NavigationLink(destination: DetailedCoJobView(bid: bid)) {
                BidCellCoView(bid: bid)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
        .padding(.bottom, 43)
    }

    private func currentBids() -> [Bid] {
        switch selectedTab {
        case .all:
            return bidController.pendingBids + bidController.approvedBids + bidController.completedBids + bidController.declinedBids
        case .pending:
            return bidController.pendingBids
        case .accepted:
            return bidController.approvedBids
        case .completed:
            return bidController.completedBids
        }
    }

    private func markJobAsCompleted(for bid: Bid) {
        bidController.updateBidStatus(bidId: bid.id, status: .completed)
    }
}
// MARK: - BidCellCoView
struct BidCellCoView: View {
    let bid: Bid
    let maxDescriptionLength = 25
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var homeownerJobController: HomeownerJobController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if bid.status == .completed {
                Text("JOB CLOSED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.bottom, 5)
            }
            HStack {
                Text("Amount: \(bid.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()
                
                Text("Status: \(bid.status.rawValue.capitalized)")
                    .font(.footnote)
                    .foregroundColor(colorForStatus(bid.status))
            }
            
            Text("Description: \(limitedDescription)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(bidController.timeAgoSincePost(bid.bidDate))
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            BlurView(style: .systemThickMaterialLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .cornerRadius(12)
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

// MARK: - DetailedCoJobView
struct DetailedCoJobView: View {
    let bid: Bid
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var authController: AuthController
    @State private var homeownerProfile: HomeownerProfile?
    @State private var jobDescription: String = "Loading..."
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            backgroundGradient
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    bidAmountSection
                    Divider()
                    jobDescriptionSection
                    Divider()
                    bidStatusSection
                    Divider()
                    
                    if let profile = homeownerProfile {
                        homeownerProfileSection(profile: profile)
                        Divider()
                    }
                    reviewSection(bid: bid)
                    
                    if bid.status == .accepted {
                        actionButtons
                    } else if bid.status == .pending {
                        Text("Needs to be accepted to complete")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .cornerRadius(8)
                    } else if bid.status == .completed {
                        Text("Job completed")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    } else if bid.status == .declined {
                        Text("Bid declined")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    } else {
                        EmptyView()
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
                loadHomeownerProfile()
                fetchJobDescription()
            }
        }
    }
    // MARK: - Fetch Job Description
    private func fetchJobDescription() {
        print("Fetching job description for job ID: \(bid.jobId)")
        if let job = homeownerJobController.homeownerJobs.first(where: { $0.id.uuidString == bid.jobId }) {
            jobDescription = job.description
            print("Job description found in existing data: \(jobDescription)")
        } else {
            bidController.getJobDescription(jobId: bid.jobId) { description in
                DispatchQueue.main.async {
                    if let description = description {
                        self.jobDescription = description
                        print("Job description fetched from database: \(self.jobDescription)")
                    } else {
                        self.jobDescription = "Description not available"
                        print("No job description found for job ID: \(bid.jobId)")
                    }
                }
            }
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#4A90E2"),
                Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Bid Amount Section
    private var bidAmountSection: some View {
        VStack(alignment: .leading) {
            Text("Bid Amount:")
                .font(.headline)
                .foregroundColor(.primary)
            Text("$\(bid.price, specifier: "%.2f") USD")
                .font(.title)
                .foregroundColor(.green)
        }
        .padding(.bottom, 8)
    }


    // MARK: - Job Description Section
    private var jobDescriptionSection: some View {
        VStack(alignment: .leading) {
            Text("Job Description:")
                .font(.headline)
                .foregroundColor(.primary)
            Text(jobDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Bid Status Section
    private var bidStatusSection: some View {
        VStack(alignment: .leading) {
            Text("Status:")
                .font(.headline)
                .foregroundColor(.primary)
            Text(bid.status.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(colorForStatus(bid.status))

                .fontWeight(.semibold)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Homeowner Section
    private func homeownerProfileSection(profile: HomeownerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Homeowner:")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            HStack(spacing: 12) {
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name: \(profile.homeownerName)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("City: \(profile.city)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if bid.status == .accepted || bid.status == .completed {
                    Text("Bio:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                    Text(profile.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("Contact Information:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(profile.email ?? "Not available")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text(formatPhoneNumber(bid.number ?? "Not available"))
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Bio:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                    Text(profile.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            // MARK: - Message Button
            NavigationLink(
                destination: ChatDetailView(
                    conversationId: bid.conversationId,
                    receiverId: profile.id.uuidString
                )
            ) {
                Text("Message Homeowner")
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
    
    // MARK: - Number Format
    func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        guard digits.count == 10 else {
            return number
        }
        
        let formattedNumber = "(\(digits.prefix(3)))\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        return formattedNumber
    }
    @State private var isCompleted = false
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack {
            if !isCompleted {
                Button(action: {
                    markAsCompletedWithAnimation()
                }) {
                    Text("Mark as Completed")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                Text("Job Completed! 🎉")
                    .font(.headline)
                    .foregroundColor(.green)
                    .transition(.scale)
            }
        }
        .padding(.top, 10)
    }
    private func markAsCompletedWithAnimation() {
        withAnimation {
            isCompleted = true // Trigger the fade-out of the button
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            markBidAsCompleted() // Call the existing function after animation
        }
    }
    private func markBidAsCompleted() {
        bidController.updateBidStatus(bidId: bid.id, status: .completed)
    }
    
    // MARK: - Load Homeowner Profile
    private func loadHomeownerProfile() {
        bidController.getHomeownerProfile(homeownerId: bid.homeownerId) { profile in
            self.homeownerProfile = profile
        }
    }
}

// MARK: - Color Status
private func colorForStatus(_ status: Bid.bidStatus) -> Color {
    switch status {
    case .pending:
        return .orange
    case .accepted:
        return .green
    case .declined:
        return .red
    case .completed:
        return .blue
    }
}

//MARK: - review section
private func reviewSection(bid: Bid) -> some View {
    VStack(alignment: .leading) {
        Text("Review:")
            .font(.headline)
            .foregroundColor(.primary)
        Text(bid.review)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    .padding(.bottom, 8)
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
