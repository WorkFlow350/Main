import SwiftUI

// MARK: - Search View
struct HoSearchView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: JobCategory? = nil
    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController
    

    // MARK: - Filtered Flyers
    var filteredFlyers: [ContractorProfile] {
        var flyers = flyerController.flyers.filter { $0.city.lowercased().contains(searchText.lowercased()) }
        if let category = selectedCategory {
            flyers = flyers.filter { $0.skills.contains(category.rawValue) }
        }
        return flyers
    }

    var body: some View {
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

            VStack(alignment: .leading, spacing: 10) {
                // MARK: - Title
                Text("Search")
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
                        flyerController.objectWillChange.send()
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
                    List(filteredFlyers) { flyer in
                        NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                            FlyerCellView(contractor: flyer)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                } else {
                    Text("Enter a city to search for contractors")
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer(minLength: 0)
            }
            .onAppear {
                flyerController.fetchFlyers()
            }
            .onChange(of: flyerController.flyers) {
                flyerController.objectWillChange.send()
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 50)
            }
        }
    }
}

// MARK: - Preview
struct HoSearchView_Previews: PreviewProvider {
    static var previews: some View {
        HoSearchView()
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
    }
}
