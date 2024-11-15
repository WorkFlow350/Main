import SwiftUI

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

    private var notificationsListView: some View {
        List {
            ForEach(bidController.bidNotifications.sorted(by: { $0.date > $1.date })) { notification in
                VStack(alignment: .leading) {
                    Text(notification.message)
                        .font(.headline)
                        .foregroundColor(
                            notification.status == .accepted ? .green :
                            notification.status == .declined ? .red : .gray
                        )
                    Text(notification.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteNotification)
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }

    private func deleteNotification(at offsets: IndexSet) {
        for index in offsets {
            let notification = bidController.bidNotifications[index]
            bidController.markNotificationAsRead(notification)
        }
        bidController.bidNotifications.remove(atOffsets: offsets)
    }

    private func clearAllNotifications() {
        for notification in bidController.bidNotifications {
            bidController.markNotificationAsRead(notification)
        }
        bidController.bidNotifications.removeAll()
    }
}

// MARK: - Preview
struct CoNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        CoNotificationView()
            .environmentObject(BidController())
    }
}
