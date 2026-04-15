//
//  CountdownsView.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import SwiftUI

struct CountdownsView: View {
    @EnvironmentObject var vm: AppViewModel

    @State private var showAddCountdownSheet = false
    @State private var newTitle = ""
    @State private var newDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                ClayBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        listCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("倒计时")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCountdownSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 36, height: 36)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clayCircle()
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showAddCountdownSheet) {
                addCountdownSheet
            }
        }
    }

    var listCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("倒计时")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("把重要的日子放在眼前")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            if vm.countdowns.isEmpty {
                Text("还没有倒计时")
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(vm.countdowns.sorted(by: { $0.targetDate < $1.targetDate })) { item in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.97, green: 0.93, blue: 0.88))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text("\(max(vm.daysUntil(item.targetDate), 0))")
                                    .font(.headline.bold())
                                    .foregroundStyle(Color(red: 0.62, green: 0.46, blue: 0.32))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(item.targetDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)

                            if item.isPinned {
                                Text("已固定到首页")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }

                        Spacer()

                        Button {
                            vm.removeCountdown(id: item.id)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .clayInnerCard()
                }
            }
        }
        .padding(22)
        .clayCard()
    }

    var addCountdownSheet: some View {
        NavigationStack {
            Form {
                Section("新增倒计时") {
                    TextField("标题", text: $newTitle)
                    DatePicker("日期", selection: $newDate, displayedComponents: .date)
                }
            }
            .navigationTitle("新增倒计时")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        newTitle = ""
                        newDate = Date()
                        showAddCountdownSheet = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") {
                        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            vm.addCountdown(title: trimmed, targetDate: newDate)
                            newTitle = ""
                            newDate = Date()
                            showAddCountdownSheet = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
