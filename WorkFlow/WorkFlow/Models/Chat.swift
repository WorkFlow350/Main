import Foundation


struct Message: Identifiable, Encodable, Equatable {
    var id: String
    var conversationId: String
    var senderId: String
    var receiverId: String
    var text: String
    var timestamp: Date
    
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.conversationId == rhs.conversationId &&
               lhs.senderId == rhs.senderId &&
               lhs.receiverId == rhs.receiverId &&
               lhs.text == rhs.text &&
               lhs.timestamp == rhs.timestamp
    }
}
struct Conversation: Identifiable {
    var id: String
    var participants: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var receiverName: String
}
