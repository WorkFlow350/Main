//edited by KR last edit 10/21/24 8am
//
import SwiftUI
import PhotosUI
import FirebaseStorage
import Combine

// View for searching jobs or contractor flyers
struct SearchView: View {
    // State variables for job/flyer search
    @State private var searchText: String = ""
    @State private var isContractor: Bool = true
    @State private var isSearching: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var refreshTrigger = false
    @State private var noResults: Bool = false
    @State private var hasSearched: Bool = false
    @State private var selectedCategory: JobCategory = .landscaping
    @State private var isCategoryPickerPresented: Bool = false // State to show/hide category picker
    
    @StateObject private var debouncedText = DebouncedState(delay: 1)
    
    @EnvironmentObject var contractorController: ContractorController
    @EnvironmentObject var jobController: JobController

    var body: some View {
        NavigationView {
            ZStack {
                // Add gradient background from light to dark blue
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all) // Ensure background covers entire screen
                
                ScrollView { // Wrap everything in a ScrollView
                    VStack(spacing: 20) {
                        // Toggle between Homeowner and Contractor view
                        Picker("Post Type", selection: $isContractor) {
                            Text("Jobs").tag(true)
                            Text("Contractor").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding() // Styling: Padding for the toggle
                        
                        // Section for searching for jobs or flyers
                        VStack(alignment: .leading, spacing: 10) {
                            Text(isContractor ? "Search For Jobs" : "Search For Contractor Flyers")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            
                            // Custom styling for the text fields
                            TextField("Search By City", text: $searchText)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15) // Rounded corners for text field
                                .padding()
                            
                            // Button-style picker for category selection
                            Button(action: {
                                isCategoryPickerPresented = true // Show the category picker
                            }) {
                                HStack {
                                    Text(selectedCategory.rawValue)
                                        .underline() // Underline to indicate interactivity
                                        .foregroundColor(.white) // White text color
                                        .font(.body)
                                    Spacer()
                                    Image(systemName: "chevron.down") // Dropdown indicator
                                        .foregroundColor(.white)
                                    
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 15)
                                .background(Color.white.opacity(0.2)) // Light background for clarity
                                .cornerRadius(5) // Rounded corners
                                .padding()
                            }
                            .sheet(isPresented: $isCategoryPickerPresented) {
                                VStack {
                                    Picker("Select Category", selection: $selectedCategory) {
                                        ForEach(JobCategory.allCases, id: \.self) { category in
                                            Text(category.rawValue).tag(category)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .background(Color.white)
                                    .cornerRadius(15)
                                    .padding()
                                    
                                    Button("Done") {
                                        isCategoryPickerPresented = false
                                    }
                                    .background(Color(hex: "#355c7d"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            // Search Button
                            Button(action: performSearch) {
                                Text("Search")
                                    .frame(minWidth: 100, maxWidth: 200) // Change size of button
                                    .padding()
                                    .background(Color(hex: "#355c7d")) // Styling: Background color
                                    .foregroundColor(.white) // Styling: Text color
                                    .cornerRadius(10) // Styling: Rounded corners
                                    .shadow(color: .gray, radius: 5, x: 0, y: 2) // Styling: Shadow effect
                            }

                            .disabled(searchText.isEmpty || isSearching)
                            .padding()
                           .padding()
                            
                        }
                        Spacer()
                        Spacer()
                        if isSearching {
                            ProgressView("Searching")
                        }  else  if searchText.isEmpty && hasSearched {
                            noSearchTextWarning()
                        } else if noResults {
                            noResultsWarning()
                        } else if isContractor {
                            jobResultsList
                        } else {
                            contractorFlyerList
                        }
                    }
                    .padding()
                }
                .navigationTitle(isContractor ? "Search For Jobs" : "Contractor Flyers")
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            KeyboardHelper.hideKeyboard()
                        }
                    }
                }
                .onReceive(debouncedText.$debouncedText) { debouncedValue in
                    if !debouncedValue.isEmpty {
                        performSearch()
                    }
                }
               .padding()
            }
        }
    }
    private var jobResultsList: some View {
            ForEach(jobController.jobs) { job in
                NavigationLink(destination: JobDetailView(job: job)) {
                    JobCellView(job: job)
                }
            }
        .listStyle(InsetGroupedListStyle())
        .id(refreshTrigger)
        .onAppear {
            print("Displaying \(jobController.jobs.count) jobs")
        }
    }
    
    private var contractorFlyerList: some View {
                ForEach(contractorController.flyers) { flyer in
                    NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                        FlyerCellView(contractor: flyer)
                    }
                }
      .listStyle(InsetGroupedListStyle())
      .id(refreshTrigger)
          .onAppear {
            print("Displaying \(contractorController.flyers.count) flyers")
        }
    }
    
    private func performSearch() {
        isSearching = true
        noResults = false
        showError = false
        hasSearched = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            if isContractor {
                   jobController.clearJobs()
                   jobController.searchJobs(by: searchText, category: selectedCategory) { result in
                       DispatchQueue.main.async {
                           self.isSearching = false
                           switch result {
                           case .success(let jobs):
                               self.noResults = jobs.isEmpty
                           case .failure(let error):
                               self.showError = true
                               self.errorMessage = error.localizedDescription
                           }
                           self.refreshTrigger.toggle()
                       }
                   }
               }else {
                contractorController.clearFlyers()
                   contractorController.searchContractors(by: searchText, skills: selectedCategory.rawValue) { result in
                    DispatchQueue.main.async {
                        self.isSearching = false
                        switch result {
                        case .success(let flyers):
                            self.noResults = flyers.isEmpty
                            self.hasSearched = true
                        case .failure(let error):
                            self.showError = true
                            self.errorMessage = error.localizedDescription
                        }
                        self.hasSearched = false
                    }
                }
            }
        }
    }

    private func noSearchTextWarning() -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.yellow)
                .font(.largeTitle)
            Text("No City Entered")
                .font(.headline)
                .padding()
            Text("Try entering a city")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing], 20)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private func noResultsWarning() -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.yellow)
                .font(.largeTitle)
            Text("No results found")
                .font(.headline)
                .padding()
            Text("Try searching for a different city")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing], 20)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
 }
    
struct SearchView_Previews: PreviewProvider {
static var previews: some View {
    SearchView()
        .environmentObject(JobController())
        .environmentObject(ContractorController())
}
}
    
    class DebouncedState: ObservableObject {
        @Published var text: String = ""
        @Published var debouncedText: String = ""
        private var bag = Set<AnyCancellable>()
        
        init(delay: Double = 0.5) {
            $text
                .removeDuplicates()
                .debounce(for: .seconds(delay), scheduler: DispatchQueue.main)
                .sink(receiveValue: { [weak self] value in
                    self?.debouncedText = value
                })
                .store(in: &bag)
        }
    }

