import SwiftUI

struct AlertMessage: Identifiable {
    var id = UUID()
    var message: String
}

extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencySymbol = "$"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }
}

struct CoJobCellView: View {
    // MARK: - Properties
    let job: Job

    // MARK: - Environment Objects
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var authController: AuthController

    @State private var isFullScreen: Bool = false
    @State private var showBidSheet: Bool = false
    @State private var bidPriceText: String = "$0"
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
                    
                    Text(job.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading)
                    
                    HStack {
                        Text(job.city)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("• \(job.category.rawValue)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.leading)
                    
                    Text("Posted \(DateFormatter.localizedString(from: job.datePosted, dateStyle: .short, timeStyle: .short))")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.leading)
                        .padding(.bottom, 5)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Description:")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(job.description)
                            .font(.body)
                            .foregroundColor(.white)
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
                    .sheet(isPresented: $showBidSheet) {
                        bidEntrySheet
                            .presentationDetents([.fraction(0.3)])
                    }
                    .alert(item: $confirmationMessage) { alertMessage in
                        Alert(title: Text("Bid Status"), message: Text(alertMessage.message), dismissButton: .default(Text("OK")))
                    }
                }
                .fullScreenCover(isPresented: $isFullScreen) {
                    FullScreenImageView(imageUrl: job.imageURL, isFullScreen: $isFullScreen)
                }
            }
        }
        .onAppear {
            checkExistingBid()
        }
    }

    private var bidEntrySheet: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Cancel") {
                    showBidSheet = false
                }
                .foregroundColor(.red)
                Spacer()
                Text("PLACE A BID")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: placeBid) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
            .padding()

            Divider()

            // Editable Bid Amount with formatting
            TextField("$0", text: $bidPriceText)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .onChange(of: bidPriceText) { newValue in
                    bidPriceText = formatCurrencyInput(newValue)
                }
            TextField("Say why you want this job", text: $bidDescription)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        
    }

    private func placeBid() {
        let cleanedValue = bidPriceText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        guard let price = Double(cleanedValue), price > 0 else {
            confirmationMessage = AlertMessage(message: "Please enter a valid bid amount.")
            return
        }
        
        bidController.placeBid(job: job, price: price, description: bidDescription)
        
        bidPlaced = true
        showBidSheet = false
        bidPriceText = "$0"
        bidDescription = ""
        confirmationMessage = AlertMessage(message: "Your bid was successfully placed!")
    }
    
    private func checkExistingBid() {
        guard let contractorId = authController.userSession?.uid else { return }
        
        bidController.getBidsForJob(job: job)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let existingBid = bidController.jobBids.first(where: { $0.contractorId == contractorId && $0.status != .declined }) {
                bidPlaced = true
            } else {
                bidPlaced = false
            }
        }
    }

    private func formatCurrencyInput(_ input: String) -> String {
        let cleanedInput = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression) // Remove all non-numeric characters
        if let value = Int(cleanedInput) {
            return NumberFormatter.currency.string(from: NSNumber(value: value)) ?? "$0"
        }
        return "$0"
    }
}

struct CoJobCellView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleJob = Job(
            id: UUID(),
            title: "Sample Landscaping Job",
            description: "This is a detailed description of the landscaping job, including requirements and expectations.",
            city: "Sample City",
            category: .landscaping,
            datePosted: Date(),
            imageURL: "https://via.placeholder.com/300"
        )
        
        CoJobCellView(job: sampleJob)
            .environmentObject(BidController())
            .environmentObject(AuthController())
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
    }
}
