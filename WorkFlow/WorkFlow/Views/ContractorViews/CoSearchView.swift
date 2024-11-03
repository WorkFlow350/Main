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

            VStack(alignment: .leading, spacing: 10) {
                // MARK: - Title
                Text("Search Jobs")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 20)

                // MARK: - Custom Category Filter Picker
                HStack {
                    ForEach([nil, JobCategory.landscaping, JobCategory.construction, JobCategory.cleaning], id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category?.rawValue.capitalized ?? "All")
                                .font(.system(size: 12))
                                .fontWeight(.semibold)
                                .foregroundColor(selectedCategory == category ? .black : .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedCategory == category ? Color.white : Color.clear)
                                )
                        }
                    }
                }
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
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer(minLength: 0)
            }
            .onAppear {
                jobController.fetchJobs()
            }
            .onChange(of: jobController.jobs) {
                jobController.objectWillChange.send()
            }
        }
    }
}

// MARK: - Preview
struct CoSearchView_Previews: PreviewProvider {
    static var previews: some View {
        CoSearchView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}
