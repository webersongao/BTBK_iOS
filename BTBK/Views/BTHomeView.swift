import SwiftUI
import Kingfisher

struct BTHomeView: View {
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.feeds.isEmpty && !viewModel.isLoading {
                    VStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("暂无帖子")
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
                            fetchData(refresh: true)
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
                } else {
                    feedsList
                }
                
                if viewModel.isLoading && viewModel.feeds.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationTitle("首页")
            .onAppear {
                if viewModel.feeds.isEmpty {
                    fetchData()
                }
            }
        }
    }
    
    // 获取数据
    private func fetchData(refresh: Bool = false) {
        Task {
            await viewModel.fetchFeeds(refresh: refresh)
        }
    }
    
    private var feedsList: some View {
        List {
            ForEach(viewModel.feeds) { feed in
                NavigationLink(destination: FeedDetailView(feed: feed)) {
                    FeedRow(feed: feed)
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentFeed: feed)
                            }
                        }
                }
                .listRowSeparator(.hidden)
            }
            
            if viewModel.isLoading && !viewModel.feeds.isEmpty {
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
            fetchData(refresh: true)
        }
    }
}

struct FeedRow: View {
    let feed: Feed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 用户信息
            HStack {
                KFImage(URL(string: feed.owner.avatar ?? ""))
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(feed.owner.name ?? feed.owner.username ?? "未知用户")
                            .font(.headline)
                        
                        if feed.owner.verified != nil {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    Text(feed.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // 帖子内容（最多显示200个字符）
            HTMLTextView(htmlContent: feed.truncatedText)
                .frame(maxWidth: .infinity, alignment: .leading).font(.body).lineLimit(3)
            
            // 如果有图片，显示第一张
            if let firstImage = feed.media.first(where: { $0.type == "image" }) {
                KFImage(URL(string: "https://demo.bkdh.net/\(firstImage.src)"))
                    .placeholder {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .clipped()
            }
            
            // 互动信息
            HStack(spacing: 20) {
                Label(feed.replysCount, systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Label(feed.likesCount, systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(feed.hasLiked ? .red : .gray)
                
                Label(feed.repostsCount, systemImage: "arrow.2.squarepath")
                    .font(.caption)
                    .foregroundColor(feed.hasReposted ? .green : .gray)
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

