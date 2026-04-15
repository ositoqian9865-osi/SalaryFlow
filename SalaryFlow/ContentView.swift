//
//  ContentView.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = AppViewModel()
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

            ReviewView()
                .environmentObject(vm)
                .tabItem {
                    Label("复盘", systemImage: "list.bullet.rectangle")
                }
        }
        .onReceive(timer) { _ in
            vm.tick()
        }
    }
}

#Preview {
    ContentView()
}
