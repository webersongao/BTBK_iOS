import Foundation
import Alamofire
import RealmSwift

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isRefreshing = false
    
    init() {
        checkStoredUser()
    }
    
    private func checkStoredUser() {
        let (storedUser, authData) = UserManager.shared.getStoredUser()
        if let _ = storedUser, let _ = authData {
            isAuthenticated = true
            Task {
                await validateToken()
                self.user = storedUser
            }
        }
    }
    
    func login(namemail: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        let parameters: Parameters = [
            "namemail": namemail,
            "password": password,
            "device_type": "ios"
        ]
        
        do {
            let response: NetworkResponse<User> = try await NetworkManager.shared.post(
                endpoint: "login",
                parameters: parameters
            )
            
            if response.code == 200, 
               let userData = response.data?.user,
               let authData = response.auth {
                print("登录成功: 用户ID=\(userData.id), 用户名=\(userData.userName)")
                self.user = userData
                self.isAuthenticated = true
                
                // 保存用户数据
                UserManager.shared.saveUser(userData, authData: authData)
                
                // 验证数据是否保存成功
                let (storedUser, storedAuth) = UserManager.shared.getStoredUser()
                if storedUser != nil && storedAuth != nil {
                    print("用户数据保存验证成功")
                } else {
                    print("警告: 用户数据保存验证失败")
                }
            } else {
                self.errorMessage = response.message
                print("登录失败: \(response.message)")
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
            print("登录异常: \(error.localizedDescription)")
        }
        self.isLoading = false
    }
    
    func logout() async {
        guard let authData = UserManager.shared.getStoredUser().1 else {
            localLogout()
            return
        }
        
        let parameters: Parameters = [
            "session_id": authData.authToken
        ]
        
        do {
            let response: LogoutResponse = try await NetworkManager.shared.post(
                endpoint: "logout",
                parameters: parameters
            )
            
            if response.code == 200 {
                localLogout()
            } else {
                localLogout()
                self.errorMessage = response.message
            }
        } catch {
            self.errorMessage = error.localizedDescription
            localLogout()
        }
    }
    
    private func localLogout() {
        UserManager.shared.clearUserData()
        self.user = nil
        self.isAuthenticated = false
    }
    
    func validateToken() async {
        if UserManager.shared.shouldRefreshToken() {
            await refreshToken()
        }
    }
    
    private func refreshToken() async {
        let (_, authData) = UserManager.shared.getStoredUser()
        guard let authData = authData else { return }
        
        let parameters: Parameters = [
            "refresh_token": authData.refreshToken
        ]
        
        do {
            let response: NetworkResponse<AuthTokenData> = try await NetworkManager.shared.post(
                endpoint: "refresh_access_token",
                parameters: parameters
            )
            
            if response.code == 200, let newAuthData = response.data?.auth {
                UserManager.shared.updateAuthToken(with: newAuthData)
            } else {
                localLogout()
            }
        } catch {
            localLogout()
        }
    }
    
    func refreshUserProfile() async {
        guard let authData = UserManager.shared.getStoredUser().1,
              let userId = user?.id else {
            return
        }
        
        isRefreshing = true
        
        let parameters: Parameters = [
            "user_id": userId,
            "session_id": authData.authToken
        ]
        
        do {
            let response: BaseResponse = try await NetworkManager.shared.get(
                endpoint: "profile",
                parameters: parameters
            )
            
            if response.code == 200,
               let profileData = response.data {
                let updatedUser = User()
                updatedUser.id = profileData.id
                updatedUser.firstName = profileData.firstName
                updatedUser.lastName = profileData.lastName
                updatedUser.userName = profileData.userName
                updatedUser.email = profileData.email
                updatedUser.profilePicture = profileData.avatar
                updatedUser.coverImage = profileData.cover
                updatedUser.aboutYou = profileData.aboutYou
                updatedUser.country = profileData.country
                updatedUser.memberSince = profileData.memberSince
                updatedUser.postCount = profileData.postCount
                updatedUser.followingCount = profileData.followingCount
                updatedUser.followerCount = profileData.followerCount
                
                self.user = updatedUser
                
                // 创建 AuthTokenData 对象
                let authTokenData = AuthTokenData(
                    authToken: authData.authToken,
                    refreshToken: authData.refreshToken,
                    authTokenExpiry: authData.authTokenExpiry
                )
                
                // 更新本地存储的用户数据
                UserManager.shared.saveUser(updatedUser, authData: authTokenData)
            } else {
                self.errorMessage = response.message
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
    }
}

// 用于退出登录响应的空模型
struct EmptyResponse: Codable {} 
