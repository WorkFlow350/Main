import SwiftUI

struct CoNotificationView: View {
    @EnvironmentObject var jobController: JobController

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack {
                    if jobController.notifications.isEmpty {
                        // MARK: - No Notifications Message
                        Text("No new notifications")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                    } else {
                        // MARK: - Notifications List
                        List {
                            ForEach(jobController.notifications.sorted(by: { notification1, notification2 in
                                let job1 = jobController.jobsNotification.first { $0.id == notification1.jobId }
                                let job2 = jobController.jobsNotification.first { $0.id == notification2.jobId }
                                return (job1?.datePosted ?? Date()) > (job2?.datePosted ?? Date())
                            }), id: \.self) { notification in
                                if let job = jobController.jobsNotification.first(where: { $0.id == notification.jobId }) {
                                    NavigationLink(value: job) {
                                        NotificationCard(notification: notification, job: job, jobController: jobController)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .onDelete(perform: deleteNotification)
                        }
                    }
                }
                .navigationTitle("Notifications")
                .toolbar {
                    if !jobController.notifications.isEmpty {
                        // MARK: - Clear All Button
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: clearAllNotifications) {
                                Text("Clear")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        BlurView(style: .systemMaterial)
                                            .clipShape(Capsule())
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                }
                .navigationDestination(for: Job.self) { selectedJob in
                    JobDetailView(job: selectedJob)
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Delete Notification
    private func deleteNotification(at offsets: IndexSet) {
        jobController.notifications.remove(atOffsets: offsets)
    }

    // MARK: - Clear All Notifications
    private func clearAllNotifications() {
        jobController.notifications.removeAll()
    }
}

struct CoNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        CoNotificationView().environmentObject(JobController())
    }
}
