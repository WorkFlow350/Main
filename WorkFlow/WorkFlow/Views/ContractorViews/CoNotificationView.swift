import SwiftUI

// MARK: - Contractor View
struct CoNotificationView: View {
    @EnvironmentObject var bidController: BidController
    
    var body: some View {
        NavigationStack {
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
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Notifications")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        Spacer()

                        if !bidController.bidNotifications.isEmpty {
                            Button(action: clearAllNotifications) {
                                Text("Clear")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(20)
                            }
                            .padding(.top, 10)
                            .padding(.trailing)
                        }
                    }
                    
                    if bidController.bidNotifications.isEmpty {
                        noNotificationsView
                    } else {
                        notificationsListView
                    }
                }
            }
        }
    }

    // MARK: - No Notifications
    private var noNotificationsView: some View {
        VStack {
            Spacer()
            Text("No new notifications")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    // MARK: - Notification List
    private var notificationsListView: some View {
        List {
            ForEach(bidController.bidNotifications.sorted(by: { $0.date > $1.date })) { notification in
                NavigationLink(
                    destination: destinationView(for: notification)
                ) {
                    ZStack {
                        BlurView(style: .systemMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading) {
                            Text(notification.message)
                                .font(.headline)
                                .foregroundColor(ColorForStatus(notification.status))
                            Text(notification.date, style: .time)
                                .font(.caption)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                    }
                    .padding(.vertical, 8)
                }
                .background(Color.clear)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteNotification)
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Navigation Destination
    private func destinationView(for notification: BidNotification) -> some View {
        if let bid = bidController.getBid(by: notification.bidId) {
            return AnyView(DetailedCoJobView(bid: bid))
        } else {
            return AnyView(Text("Loading..."))
        }
    }
    
    // MARK: - Delete
    private func deleteNotification(at offsets: IndexSet) {
        for index in offsets {
            let notification = bidController.bidNotifications[index]
            bidController.markNotificationAsRead(notification)
        }
        bidController.bidNotifications.remove(atOffsets: offsets)
    }

    //MARK: - Clear
    private func clearAllNotifications() {
        for notification in bidController.bidNotifications {
            bidController.markNotificationAsRead(notification)
        }
        bidController.bidNotifications.removeAll()
    }
}

// MARK: - BidDetailView
struct BidDetailView: View {
    let notification: BidNotification
    @EnvironmentObject var bidController: BidController
    @State private var bid: Bid?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bid Details")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            if let bid = bid {
                Text("Amount: \(bid.price, specifier: "%.2f") USD")
                    .font(.headline)
                Text("Description: \(bid.description)")
                    .font(.body)
                Text("Status: \(bid.status.rawValue.capitalized)")
                    .font(.headline)
                    .foregroundColor(ColorForStatus(bid.status))
                
                Text("Posted: \(bid.bidDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("Loading bid details...")
                    .onAppear {
                        loadBid()
                    }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Bid Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func loadBid() {
        bidController.fetchBid(by: notification.bidId) { fetchedBid in
            self.bid = fetchedBid
        }
    }
}

// MARK: - Color for Status
func ColorForStatus(_ status: Bid.bidStatus) -> Color {
    switch status {
    case .pending:
        return .orange
    case .accepted:
        return .green
    case .declined:
        return .red
    case .completed:
        return .blue
    }
}

// MARK: - Preview
struct CoNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        CoNotificationView()
            .environmentObject(BidController())
    }
}
