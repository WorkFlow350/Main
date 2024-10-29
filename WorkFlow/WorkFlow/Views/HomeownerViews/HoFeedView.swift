import SwiftUI

// MARK: - HoFeedView
struct HoFeedView: View {
    @StateObject private var jobController = JobController()
    @StateObject private var contractorController = ContractorController()
    @State private var isContractor: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                
                // MARK: - Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // MARK: - Scrollable Content
                ScrollView {
                    VStack {
                        Spacer(minLength: 10)

                        // MARK: - Contractor Flyers
                        LazyVStack(spacing: 1) {
                            ForEach(contractorController.flyers) { flyer in
                                NavigationLink(destination: FlyerDetailView(contractor: flyer)) {
                                    FlyerCellView(contractor: flyer)
                                }
                            }
                        }
                    }
                    .navigationTitle("Contractors")
                    .background(.clear)
                }
            }
            .onAppear {
                contractorController.fetchFlyers()
            }
        }
    }
}

// MARK: - Preview
struct HoFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HoFeedView()
    }
}
