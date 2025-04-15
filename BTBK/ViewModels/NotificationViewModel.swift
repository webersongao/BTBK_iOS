import Foundation
import Alamofire
import SwiftUI

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    
    private var lastId: Int?
    private var hasMoreNotifications = true
    private var currentType: String = "messages" // 默认类型为消息
    
    // 获取通知列表
    func fetchNotifications(refresh: Bool = false, type: String = "messages") async {
        // 如果类型变化，强制刷新
        let typeChanged = type != currentType
        if typeChanged {
            self.notifications = []
            self.chats = []
            lastId = nil
            hasMoreNotifications = true
            currentType = type
        }
        
        if refresh || typeChanged {
            isRefreshing = true
            lastId = nil
            hasMoreNotifications = true
        } else if !hasMoreNotifications {
            return
        } else {
            isLoading = true
        }
        
        errorMessage = nil
        
        // 获取认证信息
        let (_, authData) = UserManager.shared.getStoredUser()
        
        guard let authData = authData else {
            errorMessage = "请先登录"
            isLoading = false
            isRefreshing = false
            return
        }
        
        // 如果是消息类型，调用获取聊天列表的API
        if type == "messages" {
            await fetchChats(authToken: authData.authToken)
            return
        }
        
        var parameters: Parameters = [
            "type": type,
            "page_size": 20,
            "session_id": authData.authToken
        ]
        
        // 添加分页信息
        if let lastId = lastId, !refresh && !typeChanged {
            parameters["offset"] = lastId
        }
        
        do {
            print("开始获取\(getTypeDisplayName(type))列表...")
            
            let response: NotificationsResponse = try await NetworkManager.shared.get(
                endpoint: "get_notifications",
                parameters: parameters
            )
            
            print("成功获取\(getTypeDisplayName(type))列表，状态码: \(response.code)")
            
            if response.code == 200, let notificationsData = response.data {
                if refresh || typeChanged {
                    self.notifications = notificationsData
                } else {
                    self.notifications.append(contentsOf: notificationsData)
                }
                
                // 更新分页信息
                if let lastNotification = notificationsData.last {
                    self.lastId = lastNotification.id
                }
                
                // 检查是否还有更多数据
                if notificationsData.isEmpty {
                    self.hasMoreNotifications = false
                }
            } else {
                self.errorMessage = response.message
                print("获取\(getTypeDisplayName(type))列表失败: \(response.message)")
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("获取\(getTypeDisplayName(type))列表时发生错误: \(error)")
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    // 获取聊天列表
    private func fetchChats(authToken: String) async {
        do {
            print("开始获取聊天列表...")
            
            let parameters: Parameters = [
                "session_id": authToken
            ]
            
            let response: ChatsResponse = try await NetworkManager.shared.get(
                endpoint: "get_chats",
                parameters: parameters
            )
            
            print("成功获取聊天列表，状态码: \(response.code)")
            
            if response.code == 200, let chatsData = response.data {
                self.chats = chatsData
            } else {
                self.errorMessage = response.message
                print("获取聊天列表失败: \(response.message)")
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("获取聊天列表时发生错误: \(error)")
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    // 获取类型的显示名称
    private func getTypeDisplayName(_ type: String) -> String {
        switch type {
        case "notifs": return "通知"
        case "messages": return "消息"
        case "mentions": return "@我"
        default: return "通知"
        }
    }
    
    // 删除通知
    func deleteNotification(_ notification: Notification) async {
        isLoading = true
        errorMessage = nil
        
        // 获取认证信息
        let (_, authData) = UserManager.shared.getStoredUser()
        
        guard let authData = authData else {
            errorMessage = "请先登录"
            isLoading = false
            return
        }
        
        let parameters: Parameters = [
            "session_id": authData.authToken,
            "id": notification.id
        ]
        
        do {
            print("开始删除通知...")
            
            let response: DeleteNotificationResponse = try await NetworkManager.shared.post(
                endpoint: "delete_notification",
                parameters: parameters
            )
            
            print("删除通知请求完成，状态码: \(response.code)")
            
            if response.code == 200 {
                // 从列表中移除通知
                if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                    notifications.remove(at: index)
                }
                print("成功删除通知")
            } else {
                errorMessage = response.message
                print("删除通知失败: \(response.message)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("删除通知时发生错误: \(error)")
        }
        
        isLoading = false
    }
    
    // 加载更多通知
    func loadMoreIfNeeded(currentNotification notification: Notification) async {
        let thresholdIndex = notifications.index(notifications.endIndex, offsetBy: -3)
        if let notificationIndex = notifications.firstIndex(where: { $0.id == notification.id }),
           notificationIndex >= thresholdIndex,
           !isLoading,
           hasMoreNotifications {
            await fetchNotifications(type: currentType)
        }
    }
} 
