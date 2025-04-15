import Foundation
import RealmSwift

class User: Object, Codable {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    @Persisted var userName: String = ""
    @Persisted var email: String = ""
    @Persisted var profilePicture: String?
    @Persisted var coverImage: String?
    @Persisted var aboutYou: String?
    @Persisted var country: String?
    @Persisted var memberSince: String = ""
    @Persisted var postCount: Int = 0
    @Persisted var followingCount: Int = 0
    @Persisted var followerCount: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case userName = "user_name"
        case email
        case profilePicture = "profile_picture"
        case coverImage = "cover_picture"
        case aboutYou = "about_you"
        case country
        case memberSince = "member_since"
        case postCount = "post_count"
        case followingCount = "following_count"
        case followerCount = "follower_count"
    }
} 

