import Foundation
import Alamofire
import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    
    private var lastOffsetId: Int?
    private var hasMoreFeeds = true
    
    // 获取首页帖子列表
    func fetchFeeds(refresh: Bool = false) async {
        if refresh {
            isRefreshing = true
            lastOffsetId = nil
            hasMoreFeeds = true
        } else if !hasMoreFeeds {
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
        
        var parameters: Parameters = [
            "page_size": 20,
            "session_id": authData.authToken
        ]
        
        // 添加分页信息
        if let lastOffsetId = lastOffsetId, !refresh {
            parameters["offset"] = lastOffsetId
        }
        
        do {
            print("开始获取帖子列表...")
            
            // 尝试使用标准响应格式获取数据
            do {
                let response: FeedsResponse = try await NetworkManager.shared.get(
                    endpoint: "feeds",
                    parameters: parameters
                )
                
                print("成功获取帖子列表，状态码: \(response.code)")
                
                if response.code == 200, let feedsData = response.data {
                    if refresh {
                        self.feeds = feedsData.feeds
                    } else {
                        self.feeds.append(contentsOf: feedsData.feeds)
                    }
                    
                    // 更新分页信息
                    if let lastFeed = feedsData.feeds.last {
                        self.lastOffsetId = lastFeed.offsetId
                    }
                    
                    // 检查是否还有更多数据
                    if feedsData.feeds.isEmpty {
                        self.hasMoreFeeds = false
                    }
                } else {
                    self.errorMessage = response.message
                    print("获取帖子列表失败: \(response.message)")
                }
            } catch let error as NetworkManager.NetworkError {
                // 处理网络错误
                switch error {
                case .decodingFailed:
                    print("解码失败，尝试使用备用响应格式...")
                    
                    // 如果标准格式解码失败，尝试使用备用格式
                    do {
                        let response: AlternativeFeedsResponse = try await NetworkManager.shared.get(
                            endpoint: "feeds",
                            parameters: parameters
                        )
                        
                        print("使用备用格式成功获取帖子列表，状态码: \(response.code)")
                        
                        if response.code == 200, let feeds = response.data {
                            if refresh {
                                self.feeds = feeds
                            } else {
                                self.feeds.append(contentsOf: feeds)
                            }
                            
                            // 更新分页信息
                            if let lastFeed = feeds.last {
                                self.lastOffsetId = lastFeed.offsetId
                            }
                            
                            // 检查是否还有更多数据
                            if feeds.isEmpty {
                                self.hasMoreFeeds = false
                            }
                        } else {
                            self.errorMessage = response.message
                            print("使用备用格式获取帖子列表失败: \(response.message)")
                        }
                    } catch {
                        self.errorMessage = "无法解析服务器响应: \(error.localizedDescription)"
                        print("备用格式也解码失败: \(error)")
                    }
                default:
                    self.errorMessage = error.localizedDescription
                    print("网络错误: \(error.localizedDescription)")
                }
            } catch {
                self.errorMessage = error.localizedDescription
                print("未知错误: \(error)")
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("获取帖子列表时发生异常: \(error)")
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    // 加载更多帖子
    func loadMoreIfNeeded(currentFeed feed: Feed) async {
        let thresholdIndex = feeds.index(feeds.endIndex, offsetBy: -5)
        if let feedIndex = feeds.firstIndex(where: { $0.id == feed.id }),
           feedIndex >= thresholdIndex,
           !isLoading,
           hasMoreFeeds {
            await fetchFeeds()
        }
    }
}

extension Feed {
    // 获取OG标题
    var ogTitle: String? {
        if let dict = ogData.value as? [String: Any], let title = dict["title"] as? String {
            return title
        }
        return nil
    }
    
    // 获取OG图片URL
    var ogImageUrl: String? {
        if let dict = ogData.value as? [String: Any], let image = dict["image"] as? String {
            return image
        }
        return nil
    }
    
    // 获取OG描述
    var ogDescription: String? {
        if let dict = ogData.value as? [String: Any], let description = dict["description"] as? String {
            return description
        }
        return nil
    }
    
    // 获取OG类型
    var ogType: String? {
        if let dict = ogData.value as? [String: Any], let type = dict["type"] as? String {
            return type
        }
        return nil
    }
    
    // 检查是否有OG数据
    var hasOgData: Bool {
        if let dict = ogData.value as? [String: Any], !dict.isEmpty {
            return true
        }
        return false
    }
    
    // 检查是否是视频类型
    var isVideoType: Bool {
        return ogType == "video"
    }
}

struct Owner: Codable {
    let id: Int?
    let url: String?
    let avatar: String?
    let username: String?
    let name: String?
    let verified: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, url, avatar, username, name, verified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        // 处理 verified 字段，可能是字符串 "0"/"1" 或布尔值
        if let verifiedString = try? container.decodeIfPresent(String.self, forKey: .verified) {
            verified = verifiedString == "1"
        } else {
            verified = try container.decodeIfPresent(Bool.self, forKey: .verified)
        }
    }
} 
