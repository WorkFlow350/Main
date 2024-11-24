import Foundation
import FirebaseFirestore

// MARK: - Bid Struct
struct Bid: Identifiable, Equatable {
    let id: String //UUID !!! I changed this from UUID to String to conform to the new changes I did in BidController!!!
    let jobId: String
    let contractorId: String        // This is current sessions Id
    let homeownerId: String         // Owner of the job listing
    let price: Double
    let description: String
    let status: bidStatus
    let bidDate: Date
    let review: String
    let number: String
    let conversationId: String 

    enum bidStatus: String {
        case pending
        case accepted
        case declined
        case completed
    }
}

// MARK: - BidNotification Struct
struct BidNotification: Identifiable, Hashable {
    var id: String
    var bidId: String
    var contractorId: String
    var message: String
    var date: Date
    var status: Bid.bidStatus
    var isRead: Bool = false

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "bidId": bidId,
            "contractorId": contractorId,
            "message": message,
            "date": Timestamp(date: date),
            "status": status.rawValue,
            "isRead": isRead
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let bidId = dictionary["bidId"] as? String,
              let contractorId = dictionary["contractorId"] as? String,
              let message = dictionary["message"] as? String,
              let date = dictionary["date"] as? Timestamp,
              let statusRaw = dictionary["status"] as? String,
              let status = Bid.bidStatus(rawValue: statusRaw),
              let isRead = dictionary["isRead"] as? Bool else {
            return nil
        }
        self.id = id
        self.bidId = bidId
        self.contractorId = contractorId
        self.message = message
        self.date = date.dateValue()
        self.status = status
        self.isRead = isRead
    }
    
    init(id: String, bidId: String, contractorId: String, message: String, date: Date, status: Bid.bidStatus, isRead: Bool = false) {
        self.id = id
        self.bidId = bidId
        self.contractorId = contractorId
        self.message = message
        self.date = date
        self.status = status
        self.isRead = isRead
    }
}
