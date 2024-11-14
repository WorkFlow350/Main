import SwiftUI

struct AlertMessage: Identifiable {
    var id = UUID()
    var message: String
}

struct CoJobCellView: View {
    // MARK: - Properties
    let job: Job

    // MARK: - Environment Objects
    @EnvironmentObject var bidController: BidController

    @State private var isFullScreen: Bool = false
    @State private var showBidSheet: Bool = false
    @State private var bidPrice: String = ""
    @State private var bidDescription: String = ""
    @State private var bidPlaced: Bool = false
    @State private var confirmationMessage: AlertMessage?

    // MARK: - Body
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let imageURL = job.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width, height: 300)
                                .cornerRadius(12)
                                .onTapGesture {
                                    isFullScreen = true
                                }
                        } placeholder: {
                            ProgressView().frame(maxWidth: .infinity, maxHeight: 200)
                        }
                    }
                    
                    Text(job.title).font(.largeTitle).fontWeight(.bold).foregroundColor(.white).padding(.leading)
                    HStack {
                        Text(job.city).font(.caption).fontWeight(.bold).foregroundColor(.white)
                        Text("• \(job.category.rawValue)").font(.caption).foregroundColor(.white)
                    }
                    .padding(.leading)
                    Text("Posted \(DateFormatter.localizedString(from: job.datePosted, dateStyle: .short, timeStyle: .short))")
                        .font(.caption).foregroundColor(.white).padding(.leading).padding(.bottom, 5)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Description:").font(.body).fontWeight(.bold).foregroundColor(.white)
                        Text(job.description).font(.body).foregroundColor(.white)
                    }
                    .padding(.leading)
                    .padding(.top, 5)
                    .padding(.bottom, 100)
                    
                    Button(action: { showBidSheet = true }) {
                        Text(bidPlaced ? "Bid Placed" : "Place Bid")
                            .frame(minWidth: 100, maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: bidPlaced ? [Color.green] : [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")]),
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(bidPlaced)
                    .sheet(isPresented: $showBidSheet) { bidEntrySheet }
                    .alert(item: $confirmationMessage) { alertMessage in
                        Alert(title: Text("Bid Status"), message: Text(alertMessage.message), dismissButton: .default(Text("OK")))
                    }
                }
                .fullScreenCover(isPresented: $isFullScreen) {
                    FullScreenImageView(imageUrl: job.imageURL, isFullScreen: $isFullScreen)
                }
            }
        }
    }

    private var bidEntrySheet: some View {
        VStack(spacing: 20) {
            Text("Place a Bid").font(.headline).padding(.top)
            TextField("Bid Amount", text: $bidPrice)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("Description", text: $bidDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Button(action: { placeBid() }) {
                Text("Submit Bid")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func placeBid() {
        guard let price = Double(bidPrice), !bidDescription.isEmpty else {
            confirmationMessage = AlertMessage(message: "Invalid bid amount or description.")
            return
        }
        
        bidController.placeBid(job: job, price: price, description: bidDescription)
        
        bidPlaced = true
        showBidSheet = false
        bidPrice = ""
        bidDescription = ""
        confirmationMessage = AlertMessage(message: "Your bid was successfully placed!")
    }
}

// MARK: - Preview
struct CoJobCellView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleJob = Job(
            id: UUID(),
            title: "Sample Job Title",
            description: "This is a sample job description that provides details about the job.",
            city: "Sample City",
            category: .landscaping,
            datePosted: Date(),
            imageURL: "https://via.placeholder.com/300"
        )

        CoJobCellView(job: sampleJob)
            .environmentObject(BidController())
            .environmentObject(JobController())
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
    }
}
