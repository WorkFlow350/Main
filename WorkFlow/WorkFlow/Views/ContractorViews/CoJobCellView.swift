import SwiftUI

struct AlertMessage: Identifiable {
    var id = UUID()
    var message: String
}
extension BidController {
    func getBidDetails(for job: Job, contractorId: String) -> (status: String?, price: Double?) {
        if let bid = coBids.first(where: { $0.jobId == job.id.uuidString && $0.contractorId == contractorId }) {
            return (bid.status.rawValue, bid.price)
        }
        return (nil, nil)
    }
}
extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencySymbol = "$"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    static func formatCurrencyInput(_ input: String) -> String {
        let cleanedInput = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if let value = Int(cleanedInput) {
            return NumberFormatter.currency.string(from: NSNumber(value: value)) ?? "$0"
        }
        return "$0"
    }
}

struct CoJobCellView: View {
    // MARK: - Properties
    let job: Job
    
    // MARK: - Environment Objects
    @EnvironmentObject var bidController: BidController
    @EnvironmentObject var authController: AuthController
    
    @State private var bidStatus: String? = nil
    @State private var bidPrice: Double? = nil
    @State private var isFullScreen: Bool = false
    @State private var showBidSheet: Bool = false
    @State private var bidPriceText: String = "$0"
    @State private var bidDescription: String = ""
    @State private var bidPlaced: Bool = false
    @State private var confirmationMessage: AlertMessage?
    @State private var currentLowestBid: Double? = nil
    @State private var isBidPlaced = false
    @State private var multiColor = true

    
    // MARK: - Body
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                        VStack(alignment: .leading, spacing: 5) {
                            if let currentLowestBid = currentLowestBid {
                                BidStatusView(status: "active", bidPrice: currentLowestBid, isCurrentBid: false)
                            }
                            if let bidStatus = bidStatus {
                                BidStatusView(status: bidStatus, bidPrice: bidPrice, isCurrentBid: true)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                VStack {
                    if bidPlaced {
                        if let bidStatus = bidStatus, bidStatus.lowercased() == "declined" {
                            // If the bid is declined, show a message and allow bidding again
                            Text("Your bid was declined.")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.bottom, 10)

                            Button(action: { showBidSheet = true }) {
                                Text("Place a New Bid")
                                    .frame(minWidth: 100, maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")]),
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(20)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        } else {
                            // Show shimmer text if bid is placed and not declined
                            TextShimmer(text: "Bid Placed", fontSize: 35, multiColors: .constant(true))
                                .padding(.top, 10)
                        }
                    } else {
                        // Show "Place Bid" button if no bid is placed
                        Button(action: { showBidSheet = true }) {
                            Text("Place Bid")
                                .frame(minWidth: 100, maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB")]),
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .disabled(bidPlaced)
                    }
                }
                .sheet(isPresented: $showBidSheet) {
                    CustomBidSheetView(bidPriceText: $bidPriceText, showBidSheet: $showBidSheet, bidDescription: $bidDescription) {
                        placeBid()
                    }
                    .presentationDetents([.fraction(0.8)])
                }
                .alert(item: $confirmationMessage) { alertMessage in
                    Alert(title: Text("Bid Status"), message: Text(alertMessage.message), dismissButton: .default(Text("OK")))
                }
            }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            FullScreenImageView(imageUrl: job.imageURL, isFullScreen: $isFullScreen)
        }
        .onAppear {
            updateBidStatus()
            checkExistingBid()
            bidController.fetchCurrentLowestBid(forJob: job) { lowestBid in
                DispatchQueue.main.async {
                    currentLowestBid = lowestBid
                }
            }
        }
    }
    struct BidStatusView: View {
        let status: String?
        let bidPrice: Double?
        let isCurrentBid: Bool

        var body: some View {
            if let status = status {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isCurrentBid ? "Your Current Bid:" : "Current Bid:")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("$\(String(format: "%.2f", bidPrice ?? 0.0))")
                            .font(isCurrentBid ? .body : .title2)
                            .fontWeight(isCurrentBid ? .semibold : .bold)
                            .foregroundColor(isCurrentBid ? statusColor(for: status) : .green)
                    }
                    .padding(.top, 5)
            }
        }

        private func statusColor(for status: String) -> Color {
            switch status.lowercased() {
            case "pending":
                return .orange
            case "accepted":
                return .green
            case "declined":
                return .red
            case "completed":
                return .blue
            case "active":
                return .purple
            default:
                return .gray
            }
        }
    }
    // MARK: - Custom Bid View
    struct CustomBidSheetView: View {
        @Binding var bidPriceText: String
        @Binding var showBidSheet: Bool
        @Binding var bidDescription: String
        let placeBidAction: () -> Void
        @State private var isDescriptionEditorPresented: Bool = false
        
        var body: some View {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Text("PLACE A BID")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                
                Divider()
                
                Text(bidPriceText)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                NumberKeypad(bidPriceText: $bidPriceText)
                
                Button(action: {
                    isDescriptionEditorPresented = true
                }) {
                    HStack {
                        Text(bidDescription.isEmpty ? "Add a Description" : bidDescription)
                            .foregroundColor(bidDescription.isEmpty ? .gray : .black)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                
                Button(action: placeBidAction) {
                    Text("Send")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .overlay(
                CustomDescriptionPopup(
                    isPresented: $isDescriptionEditorPresented,
                    description: $bidDescription,
                    title: "Edit Description"
                )
            )
        }
    }
    // MARK: - Helper Functions
    private func updateBidStatus() {
        guard let contractorId = authController.userSession?.uid else { return }
        let details = bidController.getBidDetails(for: job, contractorId: contractorId)
        bidStatus = details.status
        bidPrice = details.price

        if bidStatus == nil || bidPrice == nil {
            bidPlaced = false
        }
    }
    // MARK: - Keyboard
    struct NumberKeypad: View {
        @Binding var bidPriceText: String
        @State private var numericValue: Double = 0
        @State private var hasDecimal: Bool = false
        @State private var decimalPlaces: Int = 0
        
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        var body: some View {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"], id: \.self) { key in
                    Button(action: { handleKeyPress(key) }) {
                        Text(key)
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(30)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        
        private func handleKeyPress(_ key: String) {
            switch key {
            case "⌫":
                if hasDecimal {
                    if decimalPlaces > 0 {
                        decimalPlaces -= 1
                        numericValue = floor(numericValue * pow(10, Double(decimalPlaces))) / pow(10, Double(decimalPlaces))
                    } else {
                        hasDecimal = false
                    }
                } else {
                    numericValue = floor(numericValue / 10)
                }
            case ".":
                if !hasDecimal {
                    hasDecimal = true
                }
            default:
                if let digit = Int(key) {
                    if hasDecimal {
                        if decimalPlaces < 2 {
                            decimalPlaces += 1
                            numericValue += Double(digit) / pow(10, Double(decimalPlaces))
                        }
                    } else {
                        numericValue = numericValue * 10 + Double(digit)
                    }
                }
            }
            bidPriceText = formatCurrency()
        }
        
        private func formatCurrency() -> String {
            if hasDecimal {
                return NumberFormatter.currency.string(from: NSNumber(value: numericValue)) ?? "$0.00"
            } else {
                return NumberFormatter.currency.string(from: NSNumber(value: numericValue)) ?? "$0"
            }
        }
    }
    
    // MARK: - Place Bid
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
    
    // MARK: - Check if bid exists
    private func checkExistingBid() {
        guard let contractorId = authController.userSession?.uid else { return }
        
        bidController.getBidsForJob(job: job)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let acceptedBid = bidController.jobBids.first(where: { $0.status == .accepted }) {
                bidPlaced = true
                confirmationMessage = AlertMessage(message: "This job already has an accepted bid.")
            } else if let existingBid = bidController.jobBids.first(where: { $0.contractorId == contractorId && $0.status != .declined }) {
                bidPlaced = true
                bidPrice = existingBid.price
                bidStatus = existingBid.status.rawValue
            } else {
                bidPlaced = false
            }
        }
    }
}

struct CoJobCellView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleJob = Job(
            id: UUID(),
            title: "Sample Landscaping Job",
            number: "805-123-4567",
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
