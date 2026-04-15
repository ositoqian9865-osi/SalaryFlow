//
//  SettingsView.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import SwiftUI

struct SettingsView: View {
    @Binding var settings: WorkSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showTimePicker = false
    @State private var editingTitle = ""
    @State private var editingDate = Date()
    @State private var editingTarget: TimeField = .workStart

    enum TimeField {
        case workStart
        case workEnd
        case lunchStart
        case lunchEnd
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClayBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        salaryCard
                        vaultCard
                        workTimeCard
                        lunchCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .sheet(isPresented: $showTimePicker) {
                NavigationStack {
                    ZStack {
                        ClayBackground()

                        VStack(spacing: 0) {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { editingDate },
                                    set: { newValue in
                                        editingDate = newValue
                                        applyDate(newValue, to: editingTarget)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.light)
                            .padding(.top, 8)

                            Spacer()
                        }
                    }
                    .navigationTitle(editingTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") {
                                showTimePicker = false
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    var salaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("工资设置")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("工资类型")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Picker("工资类型", selection: $settings.salaryType) {
                    ForEach(SalaryType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("工资金额")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                TextField("请输入金额", value: $settings.salaryAmount, format: .number)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .clayInnerCard()
            }

            Stepper(value: $settings.workDaysPerWeek, in: 1...7) {
                Text("每周工作 \(settings.workDaysPerWeek) 天")
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .tint(.blue)
        }
        .padding(22)
        .clayCard()
    }

    var vaultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("小金库")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("初始金额")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                TextField("请输入初始金额", value: $settings.initialVaultAmount, format: .number)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .clayInnerCard()
            }
        }
        .padding(22)
        .clayCard()
    }

    var workTimeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("工作时间")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            HStack {
                Text("上班时间")
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    timeChip(text: formatTime(settings.workStartTime)) {
                        editingTitle = "上班开始"
                        editingDate = settings.workStartTime
                        editingTarget = .workStart
                        showTimePicker = true
                    }

                    Text("-")
                        .foregroundStyle(AppTheme.textSecondary)

                    timeChip(text: formatTime(settings.workEndTime)) {
                        editingTitle = "下班结束"
                        editingDate = settings.workEndTime
                        editingTarget = .workEnd
                        showTimePicker = true
                    }
                }
            }
        }
        .padding(22)
        .clayCard()
    }

    var lunchCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("午休")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Toggle(isOn: $settings.hasLunchBreak) {
                Text("午休暂停计算")
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .tint(.blue)

            if settings.hasLunchBreak {
                HStack {
                    Text("午休时间")
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 8) {
                        timeChip(text: formatTime(settings.lunchStartTime)) {
                            editingTitle = "午休开始"
                            editingDate = settings.lunchStartTime
                            editingTarget = .lunchStart
                            showTimePicker = true
                        }

                        Text("-")
                            .foregroundStyle(AppTheme.textSecondary)

                        timeChip(text: formatTime(settings.lunchEndTime)) {
                            editingTitle = "午休结束"
                            editingDate = settings.lunchEndTime
                            editingTarget = .lunchEnd
                            showTimePicker = true
                        }
                    }
                }
            }
        }
        .padding(22)
        .clayCard()
    }

    @ViewBuilder
    func timeChip(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .clayInnerCard()
        }
        .buttonStyle(.plain)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func applyDate(_ date: Date, to target: TimeField) {
        switch target {
        case .workStart:
            settings.workStartTime = date
        case .workEnd:
            settings.workEndTime = date
        case .lunchStart:
            settings.lunchStartTime = date
        case .lunchEnd:
            settings.lunchEndTime = date
        }
    }
}
