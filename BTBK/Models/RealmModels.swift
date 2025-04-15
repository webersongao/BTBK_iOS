import Foundation
import RealmSwift

class UserRealm: Object {
    @Persisted(primaryKey: true) var userId: Int
    @Persisted var firstName: String
    @Persisted var lastName: String
    @Persisted var userName: String
    @Persisted var profilePicture: String
    @Persisted var coverPicture: String
    @Persisted var email: String
    @Persisted var isVerified: Bool
    @Persisted var website: String
    @Persisted var aboutYou: String
    @Persisted var gender: String
    @Persisted var country: String
    @Persisted var postCount: Int
    @Persisted var lastPost: Int
    @Persisted var lastAd: Int
    @Persisted var language: String
    @Persisted var followingCount: Int
    @Persisted var followerCount: Int
    @Persisted var wallet: String
    @Persisted var ipAddress: String
    @Persisted var lastActive: String
    @Persisted var memberSince: String
    @Persisted var profilePrivacy: String
}

class AuthDataRealm: Object {
    @Persisted(primaryKey: true) var id = 1
    @Persisted var authToken: String
    @Persisted var refreshToken: String
    @Persisted var authTokenExpiry: Int
    @Persisted var lastRefreshDate: Date
} 