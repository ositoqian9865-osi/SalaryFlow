//
//  ContentView.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var authManager: AuthManager

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(vm)
                .tabItem {
                    Label("首页", systemImage: "house")
                }

            GoalsView()
                .environmentObject(vm)
                .tabItem {
                    Label("目标", systemImage: "target")
                }

            CountdownsView()
                .environmentObject(vm)
                .tabItem {
                    Label("倒计时", systemImage: "clock")
                }

            ProfileView()
                .environmentObject(vm)
                .environmentObject(authManager)
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
        .onReceive(timer) { _ in
            vm.tick()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel(userId: "preview_user"))
        .environmentObject(AuthManager())
}
