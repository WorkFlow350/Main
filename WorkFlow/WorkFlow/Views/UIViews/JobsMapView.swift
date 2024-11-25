import SwiftUI
import MapKit
import CoreLocation
import CoreLocationUI

struct JobsMapView: View {
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var bidController: BidController
    @State private var region: MKCoordinateRegion = {
        // Default to contractor's location if available
        if let userLocation = CLLocationManager().location {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude,
                                               longitude: userLocation.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        } else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 34.2164, longitude: -119.0376), // Default center
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }()
    
    @Binding var isShowingMap: Bool
    var jobLocations: [JobLocation]
    @StateObject private var locationManager = LocationManager()
    @State private var searchText: String = ""
    @State private var isSearchActive = false
    @State private var selectedJob: JobLocation? = nil
    @State private var isNavigatingToJob = false
    @State private var distanceToJob: String = ""
    @State private var isRegionSet: Bool = false
    @State private var selectedJobGroup: JobGroup? = nil
    @State private var isShowingJobList: Bool = false
    var filteredJobLocations: [JobLocation] {
        jobLocations.filter { !bidController.excludedJobIds.contains($0.job.id.uuidString) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                let adjustedLocations = adjustJobLocations(locations: filteredJobLocations + contractorLocation())
                let groupedLocations = groupJobsByCoordinates(locations: adjustedLocations)

                Map(coordinateRegion: $region, annotationItems: groupedLocations) { group in
                    MapAnnotation(coordinate: group.coordinate2D) {
                        if group.isCluster {
                            // Cluster marker for multiple jobs
                            Button(action: {
                                selectedJobGroup = group
                                isShowingJobList = true
                            }) {
                                VStack {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 30, height: 30)
                                        .overlay(Text("\(group.jobs.count)").foregroundColor(.white))
                                    Text("\(group.jobs.count) Jobs")
                                        .font(.caption)
                                        .foregroundColor(.black)
                                }
                            }
                        } else if let job = group.jobs.first {
                            // Single job marker
                            if job.name == "Contractor Location" {
                                // Contractor Location Marker
                                VStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 15, height: 15)
                                        .shadow(color: .blue, radius: 10, x: 0, y: 0)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.blue.opacity(0.5), lineWidth: 5)
                                                .scaleEffect(1.2)
                                        )
                                }
                            } else {
                                // Single Job Marker
                                Button(action: {
                                    calculateDistance(to: job)
                                    selectedJob = job
                                    isNavigatingToJob = true
                                }) {
                                    VStack {
                                        Image(systemName: "figure.wave")
                                            .foregroundColor(.red)
                                            .font(.title)
                                        if selectedJob?.id == job.id && distanceToJob != "" {
                                            Text("\(distanceToJob) miles")
                                                .font(.caption)
                                                .padding(4)
                                                .background(Color.white.opacity(0.8))
                                                .cornerRadius(8)
                                                .foregroundColor(.black)
                                        } else {
                                            Text(job.name)
                                                .font(.caption)
                                                .padding(4)
                                                .background(Color.white.opacity(0.8))
                                                .cornerRadius(8)
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    bidController.fetchExcludedJobs()
                }
                .sheet(isPresented: $isShowingJobList) {
                    if let jobGroup = selectedJobGroup {
                        if jobGroup.jobs.isEmpty {
                            Text("No jobs in this group.")
                        } else {
                            VStack {
                                Text("Jobs")
                                    .font(.headline)
                                    .padding()
                                
                                List(jobGroup.jobs) { job in
                                    VStack(alignment: .leading) {
                                        Text(job.name)
                                            .font(.headline)
                                        if !job.job.description.isEmpty {
                                            Text(job.job.description ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                            .presentationDetents([.medium, .large])
                        }
                    } else {
                        Text("No jobs available.")
                    }
                }
//                .onAppear {
//                    setContractorLocation() // This Sets map to contractors profile location.
//                }
                
                // MARK: - Sliding Search Bar and Buttons
                           ZStack {
                               VStack {
                                   HStack {
                                       // Close Button in Top-Left Corner
                                       Button(action: {
                                           isShowingMap = false
                                       }) {
                                           Image(systemName: "xmark")
                                               .font(.system(size: 20))
                                               .foregroundColor(.black)
                                               .padding(10)
                                               .background(Color.white)
                                               .clipShape(Circle())
                                               .shadow(radius: 2)
                                       }
                                       .padding(.leading, 20)
                                       .padding(.top, 10)

                                       Spacer()

                                       // MARK: - Search and Close
                                       HStack(spacing: 10) {
                                           if isSearchActive {
                                               TextField("Search for a city", text: $searchText)
                                                   .padding()
                                                   .background(Color.white)
                                                   .cornerRadius(10)
                                                   .shadow(radius: 2)
                                                   .frame(maxWidth: .infinity)
                                                   .onSubmit {
                                                       searchCity()
                                                   }
                                                   .transition(.move(edge: .leading))
                                                   .animation(.spring(), value: isSearchActive)
                                           }
                                           Button(action: {
                                               if isSearchActive {
                                                   searchCity()
                                               }
                                               isSearchActive.toggle()
                                           }) {
                                               Image(systemName: "magnifyingglass")
                                                   .font(.title3)
                                                   .foregroundColor(.black)
                                                   .padding(10)
                                                   .background(Color.white)
                                                   .cornerRadius(10)
                                                   .shadow(radius: 2)
                                           }
                                           .padding(.trailing, 20)
                                           .animation(.spring(), value: isSearchActive)
                                       }
                                       .padding(.top, 10)
                                   }

                                   Spacer()
                               }
                           }
            
                
                // MARK: - Zoom Controls
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            // Zoom In Button
                            Button(action: zoomIn) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            // Zoom Out Button
                            Button(action: zoomOut) {
                                Image(systemName: "minus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 50)
                    }
                }
                
                // MARK: - Location Button
                VStack {
                    Spacer()
                    if #available(iOS 15.0, *) {
                        LocationButton(.currentLocation) {
                            locationManager.requestLocation()
                        }
                        .labelStyle(.iconOnly)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .frame(width: 50, height: 50)
                        .padding(.bottom, 20)
                    }
                }
                
                // MARK: - Navigation to Job Details
                if let selectedJob = selectedJob {
                    NavigationLink(
                        destination: CoJobCellView(job: selectedJob.job),
                        isActive: $isNavigatingToJob,
                        label: { EmptyView() }
                    )
                }
            }
        }
    }
    
    // MARK: - Calculate Distance
    private func calculateDistance(to location: JobLocation) {
        guard let userLocation = locationManager.currentLocation else { return }
        
        let jobLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distanceInMeters = userLocation.distance(from: jobLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
        distanceToJob = String(format: "%.2f", distanceInMiles) // Format to 2 decimal places
    }
    
    // MARK: - Contractor Location
    private func contractorLocation() -> [JobLocation] {
        guard let userLocation = locationManager.currentLocation else { return [] }
        return [
            JobLocation(
                id: UUID(),
                job: Job(
                    id: UUID(),
                    title: "Contractor Location",
                    number: "",
                    description: "",
                    city: "",
                    category: .landscaping,
                    datePosted: Date(),
                    imageURL: nil,
                    latitude: userLocation.coordinate.latitude,
                    longitude: userLocation.coordinate.longitude
                )
            )
        ]
    }
    func groupJobsByCoordinates(locations: [JobLocation]) -> [JobGroup] {
        var groups: [String: [JobLocation]] = [:]

        for location in locations {
            let coordinateKey = "\(location.latitude),\(location.longitude)"
            groups[coordinateKey, default: []].append(location)
        }

        return groups.map { JobGroup(coordinate: $0.key, jobs: $0.value) }
    }
    struct JobGroup: Identifiable {
        let id = UUID()
        let coordinate: String
        let jobs: [JobLocation]

        var latitude: Double {
            Double(coordinate.split(separator: ",")[0]) ?? 0.0
        }

        var longitude: Double {
            Double(coordinate.split(separator: ",")[1]) ?? 0.0
        }

        var coordinate2D: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        var isCluster: Bool {
            jobs.count > 1
        }
    }
    // MARK: - Search for City
    private func searchCity() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            if let location = placemarks?.first?.location {
                region.center = location.coordinate
            }
        }
    }
    
    // MARK: - Set Contractor Location
    private func setContractorLocation() {
        if let city = authController.appUser?.city, !city.isEmpty {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(city) { placemarks, _ in
                if let location = placemarks?.first?.location {
                    if !isRegionSet {
                        region.center = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                                longitude: location.coordinate.longitude)
                    }
                }
            }
        }
    }
    
    // MARK: - Zoom Functions
    private func zoomIn() {
        let newLatitudeDelta = max(region.span.latitudeDelta / 2, 0.005)
        let newLongitudeDelta = max(region.span.longitudeDelta / 2, 0.005)
        region.span = MKCoordinateSpan(latitudeDelta: newLatitudeDelta, longitudeDelta: newLongitudeDelta)
    }

    private func zoomOut() {
        let newLatitudeDelta = min(region.span.latitudeDelta * 2, 100.0)
        let newLongitudeDelta = min(region.span.longitudeDelta * 2, 100.0)
        region.span = MKCoordinateSpan(latitudeDelta: newLatitudeDelta, longitudeDelta: newLongitudeDelta)
    }
}

// MARK: - LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    func requestLocation() {
        manager.requestLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error)")
    }
}

// MARK: - JobLocation
struct JobLocation: Identifiable {
    let id: UUID
    let job: Job
    var name: String { job.title }
    var latitude: Double { job.latitude ?? 0.0 }
    var longitude: Double { job.longitude ?? 0.0 }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var offset: (latitude: Double, longitude: Double) = (0.0, 0.0) // Default no offset
}
func adjustJobLocations(locations: [JobLocation]) -> [JobLocation] {
    var adjustedLocations = [JobLocation]()
    var seenCoordinates = [String: Int]() // To track duplicate coordinates
    
    for var location in locations {
        let coordinateKey = "\(location.latitude),\(location.longitude)"
        
        if let count = seenCoordinates[coordinateKey] {
            // Increment the longitude offset for subsequent jobs with the same coordinates
            let latitudeOffsetStep = 0.0 // Keep latitude unchanged (or minimal)
            let longitudeOffsetStep = 0.0001 // Adjust longitude to move right
            location.offset = (latitude: latitudeOffsetStep, longitude: longitudeOffsetStep * Double(count))
            seenCoordinates[coordinateKey]! += 1
        } else {
            // First occurrence of this coordinate
            seenCoordinates[coordinateKey] = 1
        }
        
        adjustedLocations.append(location)
    }
    
    return adjustedLocations
}

// MARK: - Preview
struct JobsMapView_Previews: PreviewProvider {
    @State static var isShowingMap = true
    static var previews: some View {
        JobsMapView(
            isShowingMap: $isShowingMap,
            jobLocations: [
                JobLocation(id: UUID(), job: Job(
                    id: UUID(),
                    title: "Landscaping Job",
                    number: "123-456-7890",
                    description: "Landscaping work needed.",
                    city: "Camarillo",
                    category: .landscaping,
                    datePosted: Date(),
                    imageURL: nil,
                    latitude: 34.2164,
                    longitude: -119.0376
                )),
                JobLocation(id: UUID(), job: Job(
                    id: UUID(),
                    title: "Cleaning Job",
                    number: "123-456-7890",
                    description: "House cleaning required.",
                    city: "Camarillo",
                    category: .cleaning,
                    datePosted: Date(),
                    imageURL: nil,
                    latitude: 34.2164,
                    longitude: -119.0376
                ))
            ]
        )
        .environmentObject(HomeownerJobController())
        .environmentObject(AuthController())
        .environmentObject(JobController())
        .environmentObject(FlyerController())
        .environmentObject(BidController())
        .environmentObject(ContractorController())
    }
}
