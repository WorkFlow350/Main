import SwiftUI

struct FlyerDetailView: View {
    // MARK: - Properties
    let contractor: ContractorProfile
    @StateObject private var contractController = ContractorController()
    @State private var isFullScreen: Bool = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            // MARK: - Contractor Info
            ScrollView {
                VStack(alignment: .leading) {
                    if let imageURL = contractor.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width, height: 300)
                                .cornerRadius(12)
                                .onTapGesture {
                                    withAnimation {
                                        isFullScreen = true
                                    }
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        }
                    }
                    Text(contractor.contractorName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    HStack {
                        Text("Service Area: \(contractor.city)")
                            .font(.subheadline)
                    }
                    .padding(.leading)
                    Text("Contact: \(contractor.email)")
                        .font(.subheadline)
                        .padding(.leading)
                        .padding(.bottom, 5)
                    Text(contractor.bio)
                        .font(.body)
                        .padding(.leading)
                        .padding(.top, 5)
                        .padding(.bottom, 100)
                }
                .fullScreenCover(isPresented: $isFullScreen) {
                    FullScreenImageView(imageUrl: contractor.imageURL, isFullScreen: $isFullScreen)
                }
            }
        }
    }
}
