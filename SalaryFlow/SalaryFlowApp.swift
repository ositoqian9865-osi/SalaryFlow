//
//  SalaryFlowApp.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import SwiftUI

@main
struct SalaryFlowApp: App {
    init() {
        // 顶部导航栏
        let navColor = UIColor(
            red: 0.39,
            green: 0.35,
            blue: 0.34,
            alpha: 1.0
        )

        let navTitleColor = UIColor(
            red: 0.98,
            green: 0.97,
            blue: 0.95,
            alpha: 1.0
        )

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = navColor
        navAppearance.shadowColor = .clear
        navAppearance.titleTextAttributes = [
            .foregroundColor: navTitleColor
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: navTitleColor
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = navAppearance
        }

        UINavigationBar.appearance().tintColor = navTitleColor

        // 底部 TabBar
        let tabColor = UIColor(
            red: 0.39,
            green: 0.35,
            blue: 0.34,
            alpha: 1.0
        )

        let selectedColor = UIColor(
            red: 0.12,
            green: 0.56,
            blue: 0.96,
            alpha: 1.0
        )

        let unselectedColor = UIColor(
            red: 0.80,
            green: 0.79,
            blue: 0.78,
            alpha: 1.0
        )

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = tabColor
        tabAppearance.shadowColor = .clear

        let stacked = tabAppearance.stackedLayoutAppearance
        stacked.selected.iconColor = selectedColor
        stacked.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]
        stacked.normal.iconColor = unselectedColor
        stacked.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]

        let inline = tabAppearance.inlineLayoutAppearance
        inline.selected.iconColor = selectedColor
        inline.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]
        inline.normal.iconColor = unselectedColor
        inline.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]

        let compactInline = tabAppearance.compactInlineLayoutAppearance
        compactInline.selected.iconColor = selectedColor
        compactInline.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]
        compactInline.normal.iconColor = unselectedColor
        compactInline.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]

        UITabBar.appearance().standardAppearance = tabAppearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }

        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
