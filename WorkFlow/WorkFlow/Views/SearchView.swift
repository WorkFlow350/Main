import SwiftUI

struct SearchView: View {
    // MARK: - State Variables
    @State private var searchText: String = ""
    @State private var isSearchingJobs: Bool = true
    @State private var selectedCategory: JobCategory? = nil

    // MARK: - Environment Objects
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController

    // MARK: - Filtered Jobs
    var filteredJobs: [Job] {
        var jobs = jobController.jobs.filter { $0.city.lowercased().contains(searchText.lowercased()) }
        if let category = selectedCategory {
            jobs = jobs.filter { $0.category == category }
        }
        return jobs
    }

    // MARK: - Filtered Flyers
    var filteredFlyers: [ContractorProfile] {
        var flyers = contractorController.flyers.filter { $0.city.lowercased().contains(searchText.lowercased()) }
        if let category = selectedCategory {
            flyers = flyers.filter { $0.skills.contains(category.rawValue) }
        }
        return flyers
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 10) {
                    // MARK: - Toggle Picker
                    Picker("Select Category", selection: $isSearchingJobs) {
                        Text("Jobs").tag(true)
                        Text("Flyers").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // MARK: - Category Filter Picker
                    Picker("Filter by Category", selection: $selectedCategory) {
                        Text("All").tag(nil as JobCategory?)
                        Text("Landscaping").tag(JobCategory.landscaping)
                        Text("Construction").tag(JobCategory.construction)
                        Text("Cleaning").tag(JobCategory.cleaning)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // MARK: - Search Bar
                    TextField("Search by city", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .onChange(of: searchText) {
                            jobController.objectWillChange.send()
                            contractorController.objectWillChange.send()
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.endEditing()
                                }
                            }
                        }

                    // MARK: - Filtered Results
                    if !searchText.isEmpty {
                        if isSearchingJobs {
                            List(filteredJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    SearchCard(job: job)
                                }
                                .listRowBackground(Color.clear)
                            }
                            .listStyle(PlainListStyle())
                            .scrollContentBackground(.hidden)
                        } else {
                            List(filteredFlyers) { flyer in
                                NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                                    SearchCard(flyer: flyer)
                                }
                                .listRowBackground(Color.clear)
                            }
                            .listStyle(PlainListStyle())
                            .scrollContentBackground(.hidden)
                        }
                    } else {
                        Text("Enter a city to search for \(isSearchingJobs ? "jobs" : "contractors").")
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
                .background(Color.clear)
                .onAppear {
                    jobController.fetchJobs()
                    contractorController.fetchFlyers()
                }
                .onChange(of: jobController.jobs) {
                    jobController.objectWillChange.send()
                }
                .onChange(of: contractorController.flyers) {
                    contractorController.objectWillChange.send()
                }
            }
            .navigationTitle("Search")
        }
    }
}

// MARK: - SearchCard
struct SearchCard: View {
    let job: Job?
    let flyer: ContractorProfile?

    init(job: Job? = nil, flyer: ContractorProfile? = nil) {
        self.job = job
        self.flyer = flyer
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle()
                .frame(width: 4)
                .foregroundColor(categoryColor(for: job?.category))
                .cornerRadius(2)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(.black)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(2)

                Text(cityText)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }

            Spacer()

            if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Color.gray
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                }
            }
        }
        .padding(10)
        .background(
            BlurView(style: .systemMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var titleText: String {
        job?.title ?? flyer?.contractorName ?? "Unknown"
    }

    private var subtitleText: String {
        job?.description ?? flyer?.bio ?? "No description available"
    }

    private var cityText: String {
        job?.city ?? flyer?.city ?? "Unknown city"
    }

    private var imageUrl: String? {
        job?.imageURL ?? flyer?.imageURL
    }
}

// MARK: - Extension to dismiss the keyboard
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
