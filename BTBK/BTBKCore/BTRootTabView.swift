//
//  BTRootTabView.swift
//  BTBK
//
//  Created by WebersonGao on 2025/3/11.
//

import SwiftUI

struct BTRootTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BTHomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            BTNotifiView()
                .tabItem {
                    Label("通知", systemImage: "bell.fill")
                }
                .tag(1)
            
            BTProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}

