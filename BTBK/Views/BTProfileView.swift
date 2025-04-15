import SwiftUI
import Kingfisher

struct BTProfileView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showingLoginSheet = false
    @State private var namemail = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if authViewModel.isAuthenticated {
                    userInfoView
                        .refreshable {
                            await authViewModel.refreshUserProfile()
                        }
                } else {
                    notLoggedInView
                }
            }
            .navigationTitle("我的")
            .onAppear {
                Task {
                    await authViewModel.validateToken()
                }
                NotificationCenter.default.addObserver(
                    forName: .userDidLogin,
                    object: nil,
                    queue: .main
                ) { _ in
                    Task {
                        await authViewModel.validateToken()
                        await authViewModel.refreshUserProfile()
                    }
                }
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginSheet()
            }
            .overlay(
                Group {
                    if authViewModel.isRefreshing {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                    }
                }
            )
        }
    }
    
    private var userInfoView: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 16) {
                if let user = authViewModel.user {
                    HStack {
                        Spacer()
                        KFImage(URL(string: user.profilePicture ?? ""))
                            .placeholder {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            .shadow(radius: 3)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                    
                    Group {
                        InfoRow(title: "用户名", value: user.userName)
                        InfoRow(title: "邮箱", value: user.email)
                        InfoRow(title: "姓名", value: "\(user.firstName) \(user.lastName)")
                        InfoRow(title: "国家", value: user.country ?? "未设置")
                        InfoRow(title: "简介", value: user.aboutYou ?? "未设置")
                        InfoRow(title: "注册时间", value: user.memberSince)
                        InfoRow(title: "帖子数", value: "\(user.postCount)")
                        InfoRow(title: "关注", value: "\(user.followingCount)")
                        InfoRow(title: "粉丝", value: "\(user.followerCount)")
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    Task {
                        await authViewModel.logout()
                    }
                }) {
                    Text("退出登录")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    private var notLoggedInView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            
            Text("请登录后查看个人信息")
                .font(.headline)
            
            Button(action: {
                showingLoginSheet = true
            }) {
                Text("登录")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 45)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
        }
    }
}


