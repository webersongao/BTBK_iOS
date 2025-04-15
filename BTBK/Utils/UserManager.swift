import Foundation
import RealmSwift

// Realm 用户认证数据模型
final class AuthToken: Object {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var authToken: String = ""
    @Persisted var refreshToken: String = ""
    @Persisted var authTokenExpiry: Int = 0
    @Persisted var lastRefreshDate: Date = Date()
    
    convenience init(id: Int, authData: AuthTokenData) {
        self.init()
        self.id = id
        self.authToken = authData.authToken
        self.refreshToken = authData.refreshToken
        self.authTokenExpiry = authData.authTokenExpiry
        self.lastRefreshDate = Date()
    }
}

final class UserManager {
    static let shared = UserManager()
    private var realm: Realm!
    
    private init() {
        setupRealm()
    }
    
    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 处理数据迁移
                }
            },
            deleteRealmIfMigrationNeeded: true
        )
        
        Realm.Configuration.defaultConfiguration = config
        
        do {
            realm = try Realm()
            print("Realm 初始化成功")
            printRealmPath()
        } catch {
            print("Realm 初始化失败: \(error)")
            fatalError("Realm initialization failed: \(error)")
        }
    }
    
    // 保存用户数据
    func saveUser(_ user: User, authData: AuthTokenData) {
        do {
            try realm.write {
                realm.add(user, update: .modified)
                let auth = AuthToken(id: user.id, authData: authData)
                realm.add(auth, update: .modified)
            }
        } catch {
            print("保存用户数据失败: \(error)")
        }
    }
    
    // 获取存储的用户数据
    func getStoredUser() -> (User?, AuthToken?) {
        let users = realm.objects(User.self)
        let authTokens = realm.objects(AuthToken.self)
        if let user = users.first {
            // 尝试获取对应的认证令牌
            if let authData = realm.object(ofType: AuthToken.self, forPrimaryKey: user.id) {
                return (user, authData)
            } else {
                return (user, authTokens.first)
            }
        }
        return (nil, nil)
    }
    
    // 清除用户数据
    func clearUserData() {
        do {
            try realm.write {
                let allUsers = realm.objects(User.self)
                realm.delete(allUsers)
                
                let allAuthTokens = realm.objects(AuthToken.self)
                realm.delete(allAuthTokens)
            }
        } catch {
            print("清除用户数据失败: \(error)")
        }
    }
    
    // 检查token是否需要刷新
    func shouldRefreshToken() -> Bool {
        guard let authData = realm.object(ofType: AuthToken.self, forPrimaryKey: 1) else {
            return false
        }
        
        let expirationDate = authData.lastRefreshDate.addingTimeInterval(TimeInterval(authData.authTokenExpiry))
        let shouldRefresh = Date().addingTimeInterval(1800) > expirationDate
        
        return shouldRefresh
    }
    
    // 更新token
    func updateAuthToken(with newAuthData: AuthTokenData) {
        do {
            if let authData = realm.object(ofType: AuthToken.self, forPrimaryKey: 1) {
                try realm.write {
                    authData.authToken = newAuthData.authToken
                    authData.refreshToken = newAuthData.refreshToken
                    authData.authTokenExpiry = newAuthData.authTokenExpiry
                    authData.lastRefreshDate = Date()
                }
            } else {
                print("未找到认证令牌，无法更新")
            }
        } catch {
            print("更新Token失败: \(error)")
        }
    }
    
    // 打印 Realm 数据库路径
    func printRealmPath() {
        print("=========== Realm 数据库信息 ===========")
        print("文件路径: \(realm.configuration.fileURL?.path ?? "未知路径")")
        print("文件大小: \(getRealmFileSize())")
        print("用户对象数量: \(realm.objects(User.self).count)")
        print("认证令牌对象数量: \(realm.objects(AuthToken.self).count)")
        print("=====================================")
    }
    
    // 获取文件大小
    private func getRealmFileSize() -> String {
        guard let realmURL = realm.configuration.fileURL else {
            return "未知大小"
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: realmURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } catch {
            return "无法获取大小"
        }
    }
} 
