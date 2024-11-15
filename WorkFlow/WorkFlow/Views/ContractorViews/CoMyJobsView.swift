import SwiftUI

// MARK: - CoMyJobsView
struct CoMyJobsView: View {
    @State private var selectedTab: JobTab = .pending
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
    }

    private var jobListView: some View {
        List(currentBids()) { bid in
            NavigationLink(destination: DetailedCoJobView(bid: bid)) {
                BidCellYView(bid: bid)
                    .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }

    private func currentBids() -> [Bid] {
        switch selectedTab {
        case .pending:
            return bidController.pendingBids
        case .approved:
            return bidController.approvedBids
        case .completed:
            return bidController.completedBids
        }
    }

    private func markJobAsCompleted(for bid: Bid) {
        bidController.updateBidStatus(bidId: bid.id, status: .completed)
    }
}

// MARK: - DetailedCoJobView
struct DetailedCoJobView: View {
    let bid: Bid
    @EnvironmentObject var bidController: BidController
    @State private var homeownerProfile: HomeownerProfile?

    var body: some View {
        ZStack {
            backgroundGradient
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    bidAmountSection
                    Divider()
                    bidDescriptionSection
                    Divider()
                    bidStatusSection
                    Divider()
                    
                    if let profile = homeownerProfile {
                        homeownerProfileSection(profile: profile)
                        Divider()
                    }
                    
                    if bid.status == .pending {
                        actionButtons
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding()
            }
            .navigationTitle("Bid Details")
            .onAppear {
                loadHomeownerProfile()
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
            Text("Bid Amount")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("\(bid.price, specifier: "%.2f") USD")
                .font(.title)
                .foregroundColor(.green)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Bid Description Section
    private var bidDescriptionSection: some View {
        VStack(alignment: .leading) {
            Text("Bid Description")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(bid.description)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Bid Status Section
    private var bidStatusSection: some View {
        HStack {
            Text("Status:")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(bid.status.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(bid.status == .accepted ? .green : bid.status == .declined ? .red : .orange)
                .fontWeight(.semibold)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Homeowner Profile Section
    private func homeownerProfileSection(profile: HomeownerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Homeowner Profile")
                .font(.headline)
                .foregroundColor(.secondary)
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
                    Text(profile.homeownerName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(profile.city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
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
        .padding(.top, 10)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack {
            Button(action: {
                markBidAsCompleted()
            }) {
                Text("Mark as Completed")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
        }
        .padding(.top, 10)
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
