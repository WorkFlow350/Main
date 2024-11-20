import SwiftUI

struct FlyerDetailView: View {
    // MARK: - Properties
    let contractor: ContractorProfile
    
    // MARK: - Environment Objects
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var homeownerJobController: HomeownerJobController
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var flyerController: FlyerController
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var contractorController: ContractorController
    
    @State private var isFullScreen: Bool = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
                        .foregroundColor(.white)
                        .padding(.leading)
                    HStack {
                        Text("Service Area: \(contractor.city)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(.leading)
                    Text("Contact: \(contractor.email)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.leading)
                        .padding(.bottom, 5)
                    Text(contractor.bio)
                        .font(.body)
                        .foregroundColor(.white)
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

// MARK: - Preview
struct FlyerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleContractor = ContractorProfile(
            id: UUID(),
            contractorName: "John Doe",
            bio: "Experienced contractor specializing in home renovations.",
            skills: ["Renovation", "Painting"],
            rating: 4.5,
            jobsCompleted: 10,
            city: "Camarillo",
            email: "johndoe@example.com",
            imageURL: "https://via.placeholder.com/300"
        )

        FlyerDetailView(contractor: sampleContractor)
            .environmentObject(HomeownerJobController())
            .environmentObject(AuthController())
            .environmentObject(JobController())
            .environmentObject(FlyerController())
            .environmentObject(BidController())
            .environmentObject(ContractorController())
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
