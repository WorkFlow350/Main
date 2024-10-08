import SwiftUI

// SearchView allows users to search for jobs based on city names
struct SearchView: View {
    @State private var searchText: String = "" // State to hold the user's search input
    @EnvironmentObject var jobController: JobController // Access JobController to get the list of jobs

    // Computed property to filter jobs based on the search text
    var filteredJobs: [Job] {
        if searchText.isEmpty {
            return [] // Return an empty array when no search text is entered
        } else {
            // Filter jobs where the city name contains the search text (case insensitive)
            return jobController.jobs.filter { $0.city.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            // Search Bar with a Done button to dismiss keyboard
            TextField("Search by city", text: $searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding([.horizontal, .top])
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer() // Pushes the Done button to the right
                        Button("Done") {
                            KeyboardHelper.hideKeyboard() // Call the hideKeyboard function to dismiss keyboard
                        }
                    }
                }

            // Display filtered results only when there is search input
            if !searchText.isEmpty {
                List(filteredJobs) { job in
                    VStack(alignment: .leading) {
                        Text(job.title) // Display job title
                            .font(.headline)
                        Text(job.description) // Display job description
                            .font(.subheadline)
                        Text(job.city) // Display the city for each job
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .listStyle(InsetGroupedListStyle()) // Style the list with an inset grouped appearance
            } else {
                // Message displayed when there is no search input
                Text("Enter a city to search for jobs.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            jobController.fetchJobs()  // Fetch jobs when the view appears
        }
    }
}

// Preview for SearchView
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView().environmentObject(JobController())
    }
}

