//
//  CoSearchView.swift
//  WorkFlow
//
//  Created by Jason Rincon on 10/27/24.
//

import SwiftUI

// SearchView to show search results for jobs and flyers.
struct CoSearchView: View {
    @State private var searchText: String = ""  // State to hold the user's search input.
    @State private var selectedCategory: JobCategory? = nil  // State for category filter.
    @EnvironmentObject var jobController: JobController  // Access JobController.
    @EnvironmentObject var contractorController: ContractorController  // Access ContractorController for flyers.

    // Computed property to filter jobs based on the search text and selected category.
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
                // Background gradient for the view.
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 10) {
                    // Category filter picker.
                    Picker("Filter by Category", selection: $selectedCategory) {
                        Text("All").tag(nil as JobCategory?)
                        Text("Landscaping").tag(JobCategory.landscaping)
                        Text("Construction").tag(JobCategory.construction)
                        Text("Cleaning").tag(JobCategory.cleaning)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Search Bar with a Done button to dismiss the keyboard.
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
                                    UIApplication.shared.endEditing()  // Hide the keyboard.
                                }
                            }
                        }

                    // Display filtered results based on the selected toggle.
                    if !searchText.isEmpty {
                            // Display filtered jobs.
                            List(filteredJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    SearchCard(job: job)
                                }
                                .listRowBackground(Color.clear)  // Make each row transparent.
                            }
                            .listStyle(PlainListStyle())
                            .scrollContentBackground(.hidden)  // Clear list background.
                    } else {
                        // Message displayed when there is no search input.
                        Text("Enter a city to search for jobs")
                            .foregroundColor(.white)
                            .padding(.top, 20)  // Add a little top padding for visual spacing.
                    }

                    Spacer(minLength: 0)  // Remove large spacers to reduce the gap.
                }
                .padding(.top, 8)  // Add a small top padding to the VStack.
                .background(Color.clear)
                .onAppear {
                    jobController.fetchJobs()  // Fetch jobs when the view appears.
                }
                .onChange(of: jobController.jobs) {
                    jobController.objectWillChange.send()  // Refresh when new jobs are added.
                }
            }
            .navigationTitle("Search")
        }
    }
}

// SearchCard to display job or flyer details with a blue blur effect.
/*struct SearchCard: View {
    let job: Job?
    let flyer: ContractorProfile?
    
    init(job: Job? = nil, flyer: ContractorProfile? = nil) {
        self.job = job
        self.flyer = flyer
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Category indicator line.
            Rectangle()
                .frame(width: 4)
                .foregroundColor(categoryColor(for: job?.category))
                .cornerRadius(2)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 4) {
                // Title and message.
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(.black)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(2)

                // City information.
                Text(cityText)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }

            Spacer()

            // Image on the right side.
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
            BlurView(style: .systemMaterial)  // Apply blur effect here.
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

// Extension to dismiss the keyboard.
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
*/

struct CoSearchView_Previews: PreviewProvider {
    static var previews: some View {
        CoSearchView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}

