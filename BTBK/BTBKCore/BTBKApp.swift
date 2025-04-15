//
//  BTBKApp.swift
//  BTBK
//
//  Created by WebersonGao on 2025/3/11.
//

import SwiftUI

@main
struct BTBKApp: App {
    init() {
        // 打印 Realm 路径
        UserManager.shared.printRealmPath()
    }
    
    var body: some Scene {
        WindowGroup {
            BTRootTabView()
        }
    }
}
