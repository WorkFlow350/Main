import SwiftUI

// MARK: - Search View
struct HoSearchView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: JobCategory? = nil
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController

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
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 10) {
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

                    // MARK: - Search Results
                    if !searchText.isEmpty {
                        // Display filtered flyers.
                        List(filteredFlyers) { flyer in
                            NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                                SearchCard(flyer: flyer)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    } else {
                        Text("Enter a city to search for contractors")
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
                .background(Color.clear)
                .onAppear {
                    contractorController.fetchFlyers()
                }
                .onChange(of: contractorController.flyers) {
                    contractorController.objectWillChange.send()
                }
            }
            .navigationTitle("Search")
        }
    }
}

// MARK: - Preview
struct HoSearchView_Previews: PreviewProvider {
    static var previews: some View {
        HoSearchView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}
