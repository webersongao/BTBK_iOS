import SwiftUI
import Kingfisher

struct BTNotifiView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @State private var selectedTab = 1 // 默认选中消息标签页
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部标签栏
                TabBarView(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                
                // 内容区域
                ZStack {
                    NotificationTabView(viewModel: viewModel, type: "notifs")
                        .opacity(selectedTab == 0 ? 1 : 0)
                        .zIndex(selectedTab == 0 ? 1 : 0)
                    
                    NotificationTabView(viewModel: viewModel, type: "messages")
                        .opacity(selectedTab == 1 ? 1 : 0)
                        .zIndex(selectedTab == 1 ? 1 : 0)
                    
                    NotificationTabView(viewModel: viewModel, type: "mentions")
                        .opacity(selectedTab == 2 ? 1 : 0)
                        .zIndex(selectedTab == 2 ? 1 : 0)
                }
                .onChange(of: selectedTab) { newTab in
                    // 当标签页切换时，刷新数据
                    Task {
                        let type = getTypeForTab(newTab)
                        await viewModel.fetchNotifications(refresh: true, type: type)
                    }
                }
            }
            .navigationTitle("通知中心")
            .onAppear {
                // 初始加载消息标签页数据
                if viewModel.notifications.isEmpty {
                    Task {
                        await viewModel.fetchNotifications(refresh: true, type: "messages")
                    }
                }
            }
        }
    }
    
    // 根据标签页索引获取对应的类型
    private func getTypeForTab(_ tab: Int) -> String {
        switch tab {
        case 0: return "notifs"
        case 1: return "messages"
        case 2: return "mentions"
        default: return "messages"
        }
    }
}

// 标签栏视图
struct TabBarView: View {
    @Binding var selectedTab: Int
    
    private let tabs = ["通知", "消息", "@我"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .bold : .regular))
                            .foregroundColor(selectedTab == index ? .blue : .gray)
                        
                        // 选中指示器
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 5)
    }
}

// 聊天列表视图
struct ChatListView: View {
    @ObservedObject var viewModel: NotificationViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.chats) { chat in
                ChatRow(chat: chat)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.fetchNotifications(refresh: true, type: "messages")
        }
        .listRowInsets(EdgeInsets())
        .scrollContentBackground(.hidden)
        .overlay {
            if viewModel.chats.isEmpty {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                } else {
                    emptyView
                }
            }
        }
    }
    
    private var emptyView: some View {
        VStack {
            Image(systemName: "message.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text("暂无消息")
                .font(.headline)
                .foregroundColor(.gray)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await viewModel.fetchNotifications(refresh: true, type: "messages")
                }
            }) {
                Text("刷新")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

// 聊天行视图
struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 12) {
            // 用户头像
            KFImage(URL(string: chat.avatar))
                .placeholder {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 用户名和时间
                HStack {
                    Text(chat.name.isEmpty ? chat.username : chat.name)
                        .font(.headline)
                    
                    if chat.verified == "1" {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(chat.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 最后一条消息
                HStack {
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if chat.newMessages != "0" {
                        Text(chat.newMessages)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// 修改NotificationTabView以支持聊天列表
struct NotificationTabView: View {
    @ObservedObject var viewModel: NotificationViewModel
    let type: String
    
    var body: some View {
        if type == "messages" {
            ChatListView(viewModel: viewModel)
                .onAppear {
                    if viewModel.chats.isEmpty {
                        Task {
                            await viewModel.fetchNotifications(type: type)
                        }
                    }
                }
        } else {
            ZStack {
                if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    notificationsList
                }
                
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .onAppear {
                if viewModel.notifications.isEmpty {
                    Task {
                        await viewModel.fetchNotifications(type: type)
                    }
                }
            }
        }
    }
    
    private var emptyView: some View {
        VStack {
            Image(systemName: getEmptyIcon())
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text(getEmptyText())
                .font(.headline)
                .foregroundColor(.gray)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await viewModel.fetchNotifications(refresh: true, type: type)
                }
            }) {
                Text("刷新")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private var notificationsList: some View {
        List {
            ForEach(viewModel.notifications) { notification in
                NotificationRow(notification: notification)
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(currentNotification: notification)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteNotification(notification)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
            
            if viewModel.isLoading && !viewModel.notifications.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.fetchNotifications(refresh: true, type: type)
        }
        .listRowInsets(EdgeInsets())
        .scrollContentBackground(.hidden)
    }
    
    // 根据类型获取空状态图标
    private func getEmptyIcon() -> String {
        switch type {
        case "notifs": return "bell.slash"
        case "messages": return "message.slash"
        case "mentions": return "at.circle.slash"
        default: return "bell.slash"
        }
    }
    
    // 根据类型获取空状态文本
    private func getEmptyText() -> String {
        switch type {
        case "notifs": return "暂无通知"
        case "messages": return "暂无消息"
        case "mentions": return "暂无提及"
        default: return "暂无内容"
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        HStack(spacing: 12) {
            // 用户头像
            KFImage(URL(string: notification.avatar))
                .placeholder {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 用户名和通知类型
                HStack {
                    Text(notification.name.isEmpty ? notification.username : notification.name)
                        .font(.headline)
                    
                    if notification.verified == "1" {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(notification.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 通知内容
                HStack {
                    Image(systemName: notification.icon)
                        .foregroundColor(.blue)
                    
                    Text(notification.subjectDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

