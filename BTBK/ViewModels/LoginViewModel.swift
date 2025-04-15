import Foundation
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    func login(namemail: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let parameters: [String: Any] = [
                "namemail": namemail,
                "password": password,
                "device_type": "ios"
            ]
            
            let response: NetworkResponse<User> = try await NetworkManager.shared.post(
                endpoint: "login",
                parameters: parameters
            )
            
            if response.code == 200, let user = response.data?.user, let auth = response.auth {
                // 保存用户信息和认证令牌
                UserManager.shared.saveUser(user, authData: auth)
                isAuthenticated = true
                // 发送登录成功通知
                NotificationCenter.default.post(name: .userDidLogin, object: nil)
            } else {
                errorMessage = response.message
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// 添加通知名称扩展
extension Foundation.Notification.Name {
    static let userDidLogin = Foundation.Notification.Name("userDidLogin")
}
