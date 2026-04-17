import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var authManager: AuthManager

    @State private var showBackfillSheet = false
    @State private var backfillDate = Date()
    @State private var backfillType: BackfillAttendanceType = .normal
    @State private var backfillEarned = ""
    @State private var backfillLateMinutes = ""
    @State private var backfillOvertimeMinutes = ""

    var groupedRecords: [(month: String, weeks: [(week: String, records: [DailyTodoRecord])])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"

        let calendar = Calendar.current
        let monthGroups = Dictionary(grouping: vm.dailyTodoRecords) { formatter.string(from: $0.date) }

        return monthGroups
            .map { month, records in
                let weekGroups = Dictionary(grouping: records) { record in
                    let weekOfMonth = calendar.component(.weekOfMonth, from: record.date)
                    return "Week \(weekOfMonth)"
                }

                let sortedWeeks = weekGroups
                    .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
                    .sorted { $0.0 < $1.0 }

                return (month: month, weeks: sortedWeeks)
            }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClayBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        accountCard
                        monthlySummaryCard
                        goalReviewCard
                        historyCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBackfillSheet = true
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
            .sheet(isPresented: $showBackfillSheet) {
                backfillSheet
            }
        }
    }

    var accountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("账号")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if let user = authManager.currentUser {
                VStack(alignment: .leading, spacing: 8) {
                    Text(user.displayName ?? "未命名用户")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if let email = user.email, !email.isEmpty {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Text("登录方式：\(providerName(user.provider))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Text("当前已登录，后续可同步到你的账号。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                Button {
                    authManager.signOut()
                } label: {
                    Text("退出登录")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.78, green: 0.34, blue: 0.34))
                        )
                }
                .buttonStyle(.plain)
            } else {
                Text("当前为本地模式，不登录也能正常使用。本机可保存，登录后可做跨设备同步。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                SignInWithAppleButton(
                    onRequest: { request in
                        authManager.handleAppleSignInRequest(request)
                    },
                    onCompletion: { result in
                        authManager.handleAppleSignInCompletion(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(22)
        .clayCard()
    }

    var monthlySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(vm.monthTitle(for: Date()))复盘")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 12) {
                summaryMiniCard(
                    title: "上班天数",
                    value: "\(vm.workedDaysCount(inMonthOf: Date())) 天"
                )

                summaryMiniCard(
                    title: "累计工资",
                    value: vm.currencyShort(vm.earnedAmountInMonth(of: Date()))
                )
            }
        }
        .padding(22)
        .clayCard()
    }

    @ViewBuilder
    func summaryMiniCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .clayInnerCard()
    }

    var goalReviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("目标复盘")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if vm.goalRecords.isEmpty {
                Text("还没有目标记录")
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.goalRecords) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(record.title)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)

                                Spacer()

                                Text(vm.currencyShort(record.amount))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            HStack(spacing: 8) {
                                Text("创建 \(record.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)

                                if let completedAt = record.completedAt {
                                    Text("· 完成 \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                if let abandonedAt = record.abandonedAt {
                                    Text("· 放弃 \(abandonedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }

                            if let carry = record.carryOverAmount {
                                Text("结转 \(vm.currencyShort(carry))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)

                        if record.id != vm.goalRecords.last?.id {
                            Divider().opacity(0.25)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .clayCard()
    }

    var historyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("历史记录")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if groupedRecords.isEmpty {
                Text("还没有归档记录")
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(groupedRecords, id: \.month) { monthGroup in
                    DisclosureGroup(monthGroup.month) {
                        VStack(spacing: 10) {
                            ForEach(monthGroup.weeks, id: \.week) { weekGroup in
                                DisclosureGroup(weekGroup.week) {
                                    VStack(spacing: 0) {
                                        ForEach(weekGroup.records) { record in
                                            DisclosureGroup {
                                                VStack(alignment: .leading, spacing: 10) {
                                                    if record.items.isEmpty {
                                                        Text("今日无待办")
                                                            .font(.subheadline)
                                                            .foregroundStyle(AppTheme.textSecondary)
                                                    } else {
                                                        ForEach(record.items) { item in
                                                            HStack {
                                                                Image(systemName: item.isDone ? "checkmark.circle" : "circle")
                                                                Text(item.title)
                                                                    .strikethrough(item.isDone, color: AppTheme.textSecondary.opacity(0.35))
                                                            }
                                                            .foregroundStyle(item.isDone ? AppTheme.textSecondary : AppTheme.textPrimary)
                                                        }
                                                    }
                                                }
                                                .padding(.top, 8)
                                                .padding(.bottom, 4)
                                            } label: {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                                            .font(.headline)
                                                            .foregroundStyle(AppTheme.textPrimary)

                                                        Spacer()

                                                        Text(vm.currencyShort(record.earnedAmount))
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(AppTheme.textSecondary)
                                                    }

                                                    Text(record.attendanceSummary)
                                                        .font(.subheadline)
                                                        .foregroundStyle(AppTheme.textSecondary)

                                                    Text("进度 \(Int(record.progress * 100))%")
                                                        .font(.caption)
                                                        .foregroundStyle(AppTheme.textSecondary)
                                                }
                                                .padding(.vertical, 10)
                                            }

                                            if record.id != weekGroup.records.last?.id {
                                                Divider().opacity(0.18)
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(14)
                    .clayInnerCard()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .clayCard()
    }

    var backfillSheet: some View {
        NavigationStack {
            Form {
                Section("补卡") {
                    DatePicker("日期", selection: $backfillDate, displayedComponents: .date)

                    Picker("状态", selection: $backfillType) {
                        ForEach(BackfillAttendanceType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    TextField("当天工资", text: $backfillEarned)
                        .keyboardType(.decimalPad)

                    if backfillType == .late {
                        TextField("迟到分钟", text: $backfillLateMinutes)
                            .keyboardType(.numberPad)
                    }

                    if backfillType == .overtime {
                        TextField("加班分钟", text: $backfillOvertimeMinutes)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("补卡")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        showBackfillSheet = false
                        resetBackfillFields()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        vm.addBackfillRecord(
                            date: backfillDate,
                            type: backfillType,
                            earnedAmount: Double(backfillEarned) ?? 0,
                            lateMinutes: Int(backfillLateMinutes) ?? 0,
                            overtimeMinutes: Int(backfillOvertimeMinutes) ?? 0
                        )
                        showBackfillSheet = false
                        resetBackfillFields()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    func resetBackfillFields() {
        backfillDate = Date()
        backfillType = .normal
        backfillEarned = ""
        backfillLateMinutes = ""
        backfillOvertimeMinutes = ""
    }

    func providerName(_ provider: String?) -> String {
        switch provider {
        case "apple":
            return "Apple"
        case "google":
            return "Google"
        case "wechat":
            return "微信"
        case "qq":
            return "QQ"
        default:
            return "本地模式"
        }
    }
}
