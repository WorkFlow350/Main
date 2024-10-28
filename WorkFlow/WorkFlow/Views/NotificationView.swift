import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var jobController: JobController

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack {
                    if jobController.notifications.isEmpty {
                        // Display "No new notifications" message if the list is empty
                        Text("No new notifications")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                    } else {
                        List {
                            // Sort notifications by job's datePosted in descending order
                            ForEach(jobController.notifications.sorted(by: { notification1, notification2 in
                                let job1 = jobController.jobsNotification.first { $0.id == notification1.jobId }
                                let job2 = jobController.jobsNotification.first { $0.id == notification2.jobId }
                                return (job1?.datePosted ?? Date()) > (job2?.datePosted ?? Date())
                            }), id: \.self) { notification in
                                if let job = jobController.jobsNotification.first(where: { $0.id == notification.jobId }) {
                                    NavigationLink(value: job) {
                                        NotificationCard(notification: notification, job: job, jobController: jobController)
                                    }
                                    .listRowBackground(Color.clear) // Make row transparent
                                }
                            }
                            .onDelete(perform: deleteNotification) // Enable swipe-to-delete
                        }
                    }
                }
                .navigationTitle("Notifications")
                .toolbar {
                    // Conditionally display the "Clear All" button if there are notifications
                    if !jobController.notifications.isEmpty {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: clearAllNotifications) {
                                Text("Clear All")
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

    // Function to remove a notification
    private func deleteNotification(at offsets: IndexSet) {
        jobController.notifications.remove(atOffsets: offsets)
    }

    // Function to clear all notifications
    private func clearAllNotifications() {
        jobController.notifications.removeAll()
    }
}

// Custom NotificationCard with modified layout
struct NotificationCard: View {
    let notification: NotificationModel
    let job: Job
    var jobController: JobController

    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: 8) {
                // Category indicator line with color based on job category
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(categoryColor(for: job.category))
                    .cornerRadius(2)
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 4) {
                    // Notification message
                    Text(notification.message)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)

                    // Job title
                    Text("Job: \(job.title)")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))

                    // Job city
                    Text("Location: \(job.city)")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))

                    // Job category with capitalized text
                    Text("Category: \(String(describing: job.category).capitalized)")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()

                // Job image (if available)
                if let imageUrl = job.imageURL, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipped()
                            .cornerRadius(8)
                    } placeholder: {
                        Color.gray
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity) // Make card wider
            .background(
                BlurView(style: .systemMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal, -8) // Adjust padding to make card thinner
            .padding(.vertical, -2) // Adjust padding to make card shorter

            // Position timestamp at the bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(jobController.timeAgoSinceDate(job.datePosted))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding([.bottom, .trailing], 8)
                }
            }
        }
    }

    // Helper function to determine color based on job category
    private func categoryColor(for category: JobCategory) -> Color {
        switch category {
        case .landscaping:
            return Color.green
        case .cleaning:
            return Color.blue
        case .construction:
            return Color.orange
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView().environmentObject(JobController())
    }
}
