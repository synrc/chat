
class Contact {
    var phone_id: String?
    var avatar: String?
    var names: String?
    var surnames: String?
    var nick: String?
    var reader: AnyObject?
    var unread: Int64?
    var last_msg: Message?
    var update: Int64?
    var created: Int64?
    var settings: [Feature]?
    var services: [Service]?
    var presence: AnyObject?
    var status: AnyObject?
}