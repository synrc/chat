
class Room {
    var id: String?
    var name: String?
    var links: [Link]?
    var description: String?
    var settings: [Feature]?
    var members: [Member]?
    var admins: [Member]?
    var data: [Desc]?
    var type: AnyObject?
    var tos: String?
    var tos_update: Int64?
    var unread: Int64?
    var mentions: [AnyObject]?
    var readers: [AnyObject]?
    var last_msg: AnyObject?
    var update: Int64?
    var created: Int64?
    var status: AnyObject?
}