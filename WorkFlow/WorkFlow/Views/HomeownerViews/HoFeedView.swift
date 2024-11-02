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
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.5).opacity(1.0),
                        Color.black.opacity(0.99)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // MARK: - Scrollable Content
                ScrollView {
                    VStack(alignment: .leading) {
                        // MARK: - Title
                        Text("Contractors")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)

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
                    .background(Color.clear)
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
