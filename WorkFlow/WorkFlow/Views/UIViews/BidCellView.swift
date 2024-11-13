import SwiftUI

// MARK: - BidCellView
struct BidCellView: View {
    var bid: Bid

    var body: some View {
        VStack(alignment: .leading) {
            Text("Amount: \(bid.price, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(.green)
            Text("Description: \(bid.description)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Status: \(bid.status.rawValue.capitalized)")
                .font(.footnote)
                .foregroundColor(bid.status == .accepted ? .green : bid.status == .declined ? .red : .orange)
        }
        .padding(.bottom, 10)
    }
}


