import SwiftUI

// MARK: - Contractor Search View
struct CoSearchView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: JobCategory? = nil
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

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                // MARK: - Content Area
                VStack(spacing: 10) {
                    // MARK: - Category Picker
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
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.endEditing()
                                }
                            }
                        }

                    // MARK: - Search Results
                    if !searchText.isEmpty {
                        List(filteredJobs) { job in
                            NavigationLink(destination: JobDetailView(job: job)) {
                                SearchCard(job: job)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    } else {
                        Text("Enter a city to search for jobs")
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
                .background(Color.clear)
                .onAppear {
                    jobController.fetchJobs()
                }
                .onChange(of: jobController.jobs) {
                    jobController.objectWillChange.send()
                }
            }
            .navigationTitle("Search")
        }
    }
}

// MARK: - Preview
struct CoSearchView_Previews: PreviewProvider {
    static var previews: some View {
        CoSearchView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}
