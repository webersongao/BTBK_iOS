import SwiftUI
import Kingfisher

struct FeedDetailView: View {
    let feed: Feed
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
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
                .padding(.horizontal)
                
                // 帖子内容
                Text(feed.text)
                    .font(.body)
                    .padding(.horizontal)
                
                // 媒体内容
                if !feed.media.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(feed.media) { media in
                                if media.type == "image" {
                                    KFImage(URL(string: "https://demo.bkdh.net/\(media.src)"))
                                        .placeholder {
                                            Rectangle()
                                                .foregroundColor(.gray.opacity(0.2))
                                        }
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
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
                    
                    Image(systemName: feed.hasSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(feed.hasSaved ? .blue : .gray)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // 回复区域（这里只是一个占位符，实际实现需要另外的API）
                Text("回复区域")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("帖子详情")
        .navigationBarTitleDisplayMode(.inline)
    }
} 
