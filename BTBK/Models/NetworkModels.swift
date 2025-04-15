import Foundation

// 基础响应类型，用于处理不同的数据结构
struct BaseResponse: Codable {
    let code: Int
    let message: String
    let data: ProfileResponse?
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        
        // 尝试解析 data 字段
        if let profileData = try? container.decode(ProfileResponse.self, forKey: .data) {
            data = profileData
        } else {
            data = nil
        }
    }
}

// 通知响应
struct NotificationsResponse: Codable {
    let code: Int
    let message: String
    let data: [Notification]?
}

// 通知模型
struct Notification: Codable, Identifiable {
    let id: Int
    let notifierId: Int
    let recipientId: Int
    let status: String
    let subject: String
    let entryId: Int
    let json: AnyCodable
    let time: String
    let username: String
    let avatar: String
    let verified: String
    let name: String
    let url: String
    let postId: Int
    let privAnon: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case notifierId = "notifier_id"
        case recipientId = "recipient_id"
        case status
        case subject
        case entryId = "entry_id"
        case json
        case time
        case username
        case avatar
        case verified
        case name
        case url
        case postId = "post_id"
        case privAnon = "priv_anon"
    }
    
    // 获取通知类型的图标
    var icon: String {
        switch subject {
        case "subscribe":
            return "person.badge.plus"
        case "like":
            return "heart"
        case "repost":
            return "arrow.2.squarepath"
        case "mention":
            return "at"
        case "reply":
            return "bubble.left"
        case "visit":
            return "eye"
        default:
            return "bell"
        }
    }
    
    // 获取通知类型的描述
    var subjectDescription: String {
        switch subject {
        case "subscribe":
            return "关注了你"
        case "like":
            return "喜欢了你的帖子"
        case "repost":
            return "转发了你的帖子"
        case "mention":
            return "提到了你"
        case "reply":
            return "回复了你的帖子"
        case "visit":
            return "访问了你的主页"
        default:
            return "有新的通知"
        }
    }
}

// 删除通知响应
struct DeleteNotificationResponse: Codable {
    let code: Int
    let message: String
    let data: [String]?
}

// 帖子列表响应
struct FeedsResponse: Codable {
    let code: Int
    let message: String
    let data: FeedsData?
}

// 帖子数据
struct FeedsData: Codable {
    let feeds: [Feed]
}

// 用于处理任意类型的数据
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = ""
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map(\.value)
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues(\.value)
        } else {
            self.value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let nil as Any?:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
}

// 帖子所有者模型 - 重命名为FeedOwner以避免歧义
struct FeedOwner: Codable {
    let id: Int?
    let url: String?
    let avatar: String?
    let username: String?
    let name: String?
    let verified: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url, avatar, username, name, verified
    }
    
    // 添加计算属性，将字符串转换为布尔值
    var isVerified: Bool {
        return verified == "1"
    }
}

// 帖子模型
struct Feed: Codable, Identifiable {
    let id: Int
    let userId: Int
    let text: String
    let type: String
    let replysCount: String
    let repostsCount: String
    let likesCount: String
    let status: String
    let threadId: Int
    let target: String
    let ogData: AnyCodable
    let time: String
    let offsetId: Int
    let isRepost: Bool
    let isReposter: Bool
    let attrs: String
    let advertising: Bool
    let timeRaw: String
    let ogText: String
    let ogImage: String
    let url: String
    let canDelete: Bool
    let media: [Media]
    let isOwner: Bool
    let hasLiked: Bool
    let hasSaved: Bool
    let hasReposted: Bool
    let replyTo: [String]
    let owner: FeedOwner  // 使用重命名后的FeedOwner类型
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case text
        case type
        case replysCount = "replys_count"
        case repostsCount = "reposts_count"
        case likesCount = "likes_count"
        case status
        case threadId = "thread_id"
        case target
        case ogData = "og_data"
        case time
        case offsetId = "offset_id"
        case isRepost = "is_repost"
        case isReposter = "is_reposter"
        case attrs
        case advertising
        case timeRaw = "time_raw"
        case ogText = "og_text"
        case ogImage = "og_image"
        case url
        case canDelete = "can_delete"
        case media
        case isOwner = "is_owner"
        case hasLiked = "has_liked"
        case hasSaved = "has_saved"
        case hasReposted = "has_reposted"
        case replyTo = "reply_to"
        case owner
    }
    
    // 获取截断的文本（最多200个字符）
    var truncatedText: String {
        print("发起POST请求: \(text)")
        if text.count <= 200 {
            return text
        } else {
            return String(text.prefix(200)) + "..."
        }
    }
}

// 媒体模型
struct Media: Codable, Identifiable {
    let id: Int
    let pubId: Int
    let type: String
    let src: String
    let jsonData: String
    let time: String
    let x: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case pubId = "pub_id"
        case type
        case src
        case jsonData = "json_data"
        case time
        case x
    }
}

// 用户资料响应
struct ProfileResponse: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let avatar: String?
    let cover: String?
    let userName: String
    let email: String
    let isVerified: Bool
    let website: String?
    let aboutYou: String?
    let gender: String?
    let country: String?
    let postCount: Int
    let about: String?
    let ipAddress: String?
    let followingCount: Int
    let followerCount: Int
    let language: String?
    let lastActive: String?
    let profilePrivacy: String?
    let memberSince: String
    let isBlockedVisitor: Bool
    let isFollowing: Bool
    let canViewProfile: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "id"  // 注意：profile API 使用 "id"，而 login API 使用 "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case avatar
        case cover
        case userName = "user_name"
        case email
        case isVerified = "is_verified"
        case website
        case aboutYou = "about_you"
        case gender
        case country
        case postCount = "post_count"
        case about
        case ipAddress = "ip_address"
        case followingCount = "following_count"
        case followerCount = "follower_count"
        case language
        case lastActive = "last_active"
        case profilePrivacy = "profile_privacy"
        case memberSince = "member_since"
        case isBlockedVisitor = "is_blocked_visitor"
        case isFollowing = "is_following"
        case canViewProfile = "can_view_profile"
    }
}

// 用户登录响应
struct LoginResponse: Codable {
    let user: User?
    let auth: AuthTokenData?
}

// 网络响应基础模型
struct NetworkResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: ResponseData<T>?
    let auth: AuthTokenData?
}

// 响应数据模型
struct ResponseData<T: Codable>: Codable {
    let user: T?
    let auth: AuthTokenData?
}

// 认证数据模型
struct AuthTokenData: Codable {
    let authToken: String
    let refreshToken: String
    let authTokenExpiry: Int
    
    enum CodingKeys: String, CodingKey {
        case authToken = "auth_token"
        case refreshToken = "refresh_token"
        case authTokenExpiry = "auth_token_expiry"
    }
}

// 登出响应
struct LogoutResponse: Codable {
    let code: Int
    let message: String
    let data: EmptyData?
}

struct EmptyData: Codable {}

// 备用的帖子列表响应格式
struct AlternativeFeedsResponse: Codable {
    let code: Int
    let message: String
    let data: [Feed]?
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        
        // 尝试不同的数据格式
        if let feedsArray = try? container.decode([Feed].self, forKey: .data) {
            data = feedsArray
        } else if let feedsDict = try? container.decode([String: [Feed]].self, forKey: .data),
                  let feeds = feedsDict["feeds"] {
            data = feeds
        } else {
            data = nil
        }
    }
}

// 聊天列表响应
struct ChatsResponse: Codable {
    let code: Int
    let message: String
    let data: [Chat]?
}

// 聊天模型
struct Chat: Codable, Identifiable {
    let userId: Int
    let username: String
    let name: String
    let avatar: String
    let verified: String
    let chatId: Int
    let time: String
    let lastMessage: String
    let newMessages: String
    let chatUrl: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case name
        case avatar
        case verified
        case chatId = "chat_id"
        case time
        case lastMessage = "last_message"
        case newMessages = "new_messages"
        case chatUrl = "chat_url"
    }
    
    // 实现Identifiable协议所需的id
    var id: Int { userId }
} 
