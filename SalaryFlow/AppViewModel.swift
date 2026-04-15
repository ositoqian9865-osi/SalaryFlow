//
//  AppViewModel.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import SwiftUI
import Foundation

final class AppViewModel: ObservableObject {
    private enum StorageKey {
        static let settings = "sf.settings"
        static let vaultBaseAmount = "sf.vaultBaseAmount"
        static let goals = "sf.goals"
        static let goalRecords = "sf.goalRecords"
        static let todos = "sf.todos"
        static let dailyTodoRecords = "sf.dailyTodoRecords"
        static let countdowns = "sf.countdowns"
        static let manualIncomeRecords = "sf.manualIncomeRecords"
        static let attendanceMode = "sf.attendanceMode"
        static let clockInTime = "sf.clockInTime"
        static let clockOutTime = "sf.clockOutTime"
        static let archivedDayKey = "sf.archivedDayKey"
        static let lastInitialVaultAmount = "sf.lastInitialVaultAmount"
    }

    @Published var settings = WorkSettings() {
        didSet { persistAll() }
    }

    @Published var todayEarned: Double = 0
    @Published var workProgress: Double = 0

    @Published var vaultBaseAmount: Double = 248.36 {
        didSet { saveValue(vaultBaseAmount, forKey: StorageKey.vaultBaseAmount) }
    }

    @Published var goals: [Goal] = [
        Goal(title: "AirPods Pro", amount: 1280),
        Goal(title: "东京机票", amount: 1669.16)
    ] {
        didSet { saveCodable(goals, forKey: StorageKey.goals) }
    }

    @Published var goalRecords: [GoalRecord] = [] {
        didSet { saveCodable(goalRecords, forKey: StorageKey.goalRecords) }
    }

    @Published var todos: [TodoItem] = [
        TodoItem(title: "回客户消息"),
        TodoItem(title: "改课程大纲"),
        TodoItem(title: "发会议纪要", isDone: true)
    ] {
        didSet { saveCodable(todos, forKey: StorageKey.todos) }
    }

    @Published var dailyTodoRecords: [DailyTodoRecord] = [] {
        didSet { saveCodable(dailyTodoRecords, forKey: StorageKey.dailyTodoRecords) }
    }

    @Published var countdowns: [CountdownItem] = [
        CountdownItem(
            title: "发工资",
            targetDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
            isPinned: true,
            showInWidget: true
        ),
        CountdownItem(
            title: "去东京",
            targetDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
            isPinned: true,
            showInWidget: true
        )
    ] {
        didSet { saveCodable(countdowns, forKey: StorageKey.countdowns) }
    }

    @Published var manualIncomeRecords: [ManualIncomeRecord] = [] {
        didSet { saveCodable(manualIncomeRecords, forKey: StorageKey.manualIncomeRecords) }
    }

    @Published var attendanceMode: AttendanceMode = .none {
        didSet { saveValue(attendanceMode.rawValue, forKey: StorageKey.attendanceMode) }
    }

    @Published var clockInTime: Date? {
        didSet { saveDate(clockInTime, forKey: StorageKey.clockInTime) }
    }

    @Published var clockOutTime: Date? {
        didSet { saveDate(clockOutTime, forKey: StorageKey.clockOutTime) }
    }

    private var archivedDayKey: String = "" {
        didSet { saveValue(archivedDayKey, forKey: StorageKey.archivedDayKey) }
    }

    private var lastInitialVaultAmount: Double = 248.36 {
        didSet { saveValue(lastInitialVaultAmount, forKey: StorageKey.lastInitialVaultAmount) }
    }

    init() {
        loadAll()

        if archivedDayKey.isEmpty {
            archivedDayKey = dayKey(Date())
        }

        if UserDefaults.standard.object(forKey: StorageKey.vaultBaseAmount) == nil {
            vaultBaseAmount = settings.initialVaultAmount
        }

        if UserDefaults.standard.object(forKey: StorageKey.lastInitialVaultAmount) == nil {
            lastInitialVaultAmount = settings.initialVaultAmount
        }

        func recalculateToday(now: Date = Date()) {
            let fullDaySeconds = max(effectiveWorkSecondsPerDay(), 1)

            switch attendanceMode {
            case .offDay:
                todayEarned = 0
                workProgress = 0

            case .none:
                todayEarned = 0
                workProgress = 0

            case .working, .workedHalfDay, .finished:
                guard let clockInTime else {
                    todayEarned = 0
                    workProgress = 0
                    return
                }

                let scheduleStart = scheduledStartDate(for: now)
                let scheduleEnd = scheduledEndDate(for: now)

                // 1) 金额：按真实打卡时间和工作时段重叠来算
                let effectiveStart = maxDate(clockInTime, scheduleStart)
                let liveEnd = clockOutTime ?? now
                let cappedEnd = minDate(liveEnd, scheduleEnd)

                if cappedEnd <= effectiveStart {
                    todayEarned = 0
                } else {
                    var workedSeconds = workedSecondsBetween(start: effectiveStart, end: cappedEnd, on: now)

                    if attendanceMode == .workedHalfDay {
                        workedSeconds = min(workedSeconds, fullDaySeconds / 2.0)
                    }

                    todayEarned = max(workedSeconds * effectivePerSecondIncome(), 0)
                }

                // 2) 进度条：按设置好的工作时间轴走
                let progressAnchor = minDate(clockOutTime ?? now, scheduleEnd)
                var scheduleProgressSeconds = scheduledProgressWorkedSeconds(at: progressAnchor)

                if attendanceMode == .workedHalfDay {
                    scheduleProgressSeconds = min(scheduleProgressSeconds, fullDaySeconds / 2.0)
                }

                workProgress = min(max(scheduleProgressSeconds / fullDaySeconds, 0), attendanceMode == .workedHalfDay ? 0.5 : 1.0)
            }
        }
    }

    // MARK: - Persistence

    private func persistAll() {
        saveCodable(settings, forKey: StorageKey.settings)
        saveValue(vaultBaseAmount, forKey: StorageKey.vaultBaseAmount)
        saveCodable(goals, forKey: StorageKey.goals)
        saveCodable(goalRecords, forKey: StorageKey.goalRecords)
        saveCodable(todos, forKey: StorageKey.todos)
        saveCodable(dailyTodoRecords, forKey: StorageKey.dailyTodoRecords)
        saveCodable(countdowns, forKey: StorageKey.countdowns)
        saveCodable(manualIncomeRecords, forKey: StorageKey.manualIncomeRecords)
        saveValue(attendanceMode.rawValue, forKey: StorageKey.attendanceMode)
        saveDate(clockInTime, forKey: StorageKey.clockInTime)
        saveDate(clockOutTime, forKey: StorageKey.clockOutTime)
        saveValue(archivedDayKey, forKey: StorageKey.archivedDayKey)
        saveValue(lastInitialVaultAmount, forKey: StorageKey.lastInitialVaultAmount)
        flushDefaults()
    }

    private func loadAll() {
        settings = loadCodable(WorkSettings.self, forKey: StorageKey.settings) ?? WorkSettings()
        vaultBaseAmount = loadValue(Double.self, forKey: StorageKey.vaultBaseAmount) ?? 248.36
        goals = loadCodable([Goal].self, forKey: StorageKey.goals) ?? [
            Goal(title: "AirPods Pro", amount: 1280),
            Goal(title: "东京机票", amount: 1669.16)
        ]
        goalRecords = loadCodable([GoalRecord].self, forKey: StorageKey.goalRecords) ?? []
        todos = loadCodable([TodoItem].self, forKey: StorageKey.todos) ?? [
            TodoItem(title: "回客户消息"),
            TodoItem(title: "改课程大纲"),
            TodoItem(title: "发会议纪要", isDone: true)
        ]
        dailyTodoRecords = loadCodable([DailyTodoRecord].self, forKey: StorageKey.dailyTodoRecords) ?? []
        countdowns = loadCodable([CountdownItem].self, forKey: StorageKey.countdowns) ?? [
            CountdownItem(
                title: "发工资",
                targetDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
                isPinned: true,
                showInWidget: true
            ),
            CountdownItem(
                title: "去东京",
                targetDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
                isPinned: true,
                showInWidget: true
            )
        ]
        manualIncomeRecords = loadCodable([ManualIncomeRecord].self, forKey: StorageKey.manualIncomeRecords) ?? []

        if let rawMode = loadValue(String.self, forKey: StorageKey.attendanceMode),
           let mode = AttendanceMode(rawValue: rawMode) {
            attendanceMode = mode
        } else {
            attendanceMode = .none
        }

        clockInTime = loadDate(forKey: StorageKey.clockInTime)
        clockOutTime = loadDate(forKey: StorageKey.clockOutTime)
        archivedDayKey = loadValue(String.self, forKey: StorageKey.archivedDayKey) ?? ""
        lastInitialVaultAmount = loadValue(Double.self, forKey: StorageKey.lastInitialVaultAmount) ?? settings.initialVaultAmount
    }

    private func saveCodable<T: Codable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadCodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }

    private func saveValue<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func loadValue<T>(_ type: T.Type, forKey key: String) -> T? {
        UserDefaults.standard.object(forKey: key) as? T
    }

    private func saveDate(_ date: Date?, forKey key: String) {
        UserDefaults.standard.set(date, forKey: key)
    }

    private func loadDate(forKey key: String) -> Date? {
        UserDefaults.standard.object(forKey: key) as? Date
    }

    private func flushDefaults() {
        UserDefaults.standard.synchronize()
    }

    // MARK: - Computed

    var currentGoal: Goal? { goals.first }

    var widgetCountdowns: [CountdownItem] {
        countdowns
            .filter { $0.showInWidget }
            .sorted {
                if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
                return $0.targetDate < $1.targetDate
            }
            .prefix(3)
            .map { $0 }
    }

    var currentVaultAmount: Double {
        max(vaultBaseAmount + todayEarned, 0)
    }

    // MARK: - Tick

    func tick() {
        archiveIfNeeded(now: Date())
        recalculateToday()
    }

    func handleSettingsUpdated() {
        let delta = settings.initialVaultAmount - lastInitialVaultAmount
        vaultBaseAmount += delta
        lastInitialVaultAmount = settings.initialVaultAmount
        recalculateToday()
    }

    // MARK: - Manual Income

    func addManualIncome(amount: Double, note: String) {
        guard amount > 0 else { return }
        vaultBaseAmount += amount
        manualIncomeRecords.insert(
            ManualIncomeRecord(amount: amount, note: note),
            at: 0
        )
    }

    // MARK: - Recalculate Today

    func recalculateToday(now: Date = Date()) {
        switch attendanceMode {
        case .offDay:
            todayEarned = 0
            workProgress = 0

        case .none:
            todayEarned = 0
            workProgress = 0

        case .working, .workedHalfDay, .finished:
            guard let clockInTime else {
                todayEarned = 0
                workProgress = 0
                return
            }

            let scheduleStart = scheduledStartDate(for: now)
            let scheduleEnd = scheduledEndDate(for: now)

            let effectiveStart = maxDate(clockInTime, scheduleStart)
            let liveEnd = clockOutTime ?? now
            let cappedEnd = minDate(liveEnd, scheduleEnd)

            if cappedEnd <= effectiveStart {
                todayEarned = 0
                workProgress = 0
                return
            }

            let fullDaySeconds = max(effectiveWorkSecondsPerDay(), 1)
            var workedSeconds = workedSecondsBetween(start: effectiveStart, end: cappedEnd, on: now)

            if attendanceMode == .workedHalfDay {
                workedSeconds = min(workedSeconds, fullDaySeconds / 2.0)
            }

            todayEarned = max(workedSeconds * effectivePerSecondIncome(), 0)

            let rawProgress = workedSeconds / fullDaySeconds
            workProgress = min(max(rawProgress, 0), attendanceMode == .workedHalfDay ? 0.5 : 1.0)
        }
    }

    func scheduledProgressWorkedSeconds(at time: Date) -> Double {
        let start = scheduledStartDate(for: time)
        let end = scheduledEndDate(for: time)

        if time <= start { return 0 }
        if time >= end { return effectiveWorkSecondsPerDay() }

        return workedSecondsBetween(start: start, end: time, on: time)
    }
    // MARK: - Punch Logic

    func punchIn() {
        let now = Date()
        archiveIfNeeded(now: now)

        guard isWorkdayToday(now: now) else { return }
        if attendanceMode == .offDay { return }

        if clockInTime == nil {
            clockInTime = now
        }

        clockOutTime = nil

        if attendanceMode != .workedHalfDay {
            attendanceMode = .working
        }

        recalculateToday(now: now)
    }

    func punchOut() {
        let now = Date()
        guard attendanceMode == .working || attendanceMode == .workedHalfDay else { return }
        clockOutTime = now
        attendanceMode = .finished
        recalculateToday(now: now)
    }

    func markOffToday() {
        attendanceMode = .offDay
        clockInTime = nil
        clockOutTime = nil
        recalculateToday(now: Date())
    }

    func markHalfDay() {
        let now = Date()
        archiveIfNeeded(now: now)

        guard isWorkdayToday(now: now) else { return }

        if clockInTime == nil {
            clockInTime = now
        }

        clockOutTime = nil
        attendanceMode = .workedHalfDay
        recalculateToday(now: now)
    }

    // MARK: - Backfill

    func addBackfillRecord(
        date: Date,
        type: BackfillAttendanceType,
        earnedAmount: Double,
        lateMinutes: Int,
        overtimeMinutes: Int
    ) {
        let summary: String
        let progress: Double

        switch type {
        case .normal:
            summary = "正常上班"
            progress = 1.0
        case .late:
            summary = "迟到 \(max(lateMinutes, 0)) 分钟"
            progress = 1.0
        case .overtime:
            summary = "加班 \(max(overtimeMinutes, 0)) 分钟"
            progress = 1.0
        case .offDay:
            summary = "没上班"
            progress = 0
        case .halfDay:
            summary = "上班半天"
            progress = 0.5
        }

        let record = DailyTodoRecord(
            date: date,
            items: [],
            earnedAmount: max(earnedAmount, 0),
            progress: progress,
            attendanceSummary: summary
        )

        dailyTodoRecords.insert(record, at: 0)
    }

    // MARK: - Attendance Summary

    func attendanceSummary(now: Date = Date()) -> String {
        switch attendanceMode {
        case .offDay:
            return "没上班"
        case .none:
            return "未打卡"
        case .working, .workedHalfDay, .finished:
            guard let clockInTime else { return "未打卡" }

            if attendanceMode == .workedHalfDay {
                return "上班半天"
            }

            let late = lateMinutes(from: clockInTime, now: now)
            let overtime = overtimeMinutes(now: clockOutTime ?? now)

            if late > 0 { return "迟到 \(late) 分钟" }
            if attendanceMode == .finished && overtime > 0 { return "加班 \(overtime) 分钟" }
            return "正常上班"
        }
    }

    func lateMinutes(from clockIn: Date, now: Date = Date()) -> Int {
        let start = scheduledStartDate(for: now)
        let diff = Int(clockIn.timeIntervalSince(start) / 60)
        return max(diff, 0)
    }

    func overtimeMinutes(now: Date = Date()) -> Int {
        let end = scheduledEndDate(for: now)
        let diff = Int(now.timeIntervalSince(end) / 60)
        return max(diff, 0)
    }

    // MARK: - Income Logic

    func effectivePerSecondIncome() -> Double {
        let workSeconds = max(effectiveWorkSecondsPerDay(), 1)

        switch settings.salaryType {
        case .hourly:
            return settings.salaryAmount / 3600.0
        case .daily:
            return settings.salaryAmount / workSeconds
        case .monthly:
            let monthlyWorkDays = Double(settings.workDaysPerWeek) * 4.33
            let dailyIncome = settings.salaryAmount / max(monthlyWorkDays, 1)
            return dailyIncome / workSeconds
        }
    }

    func effectiveWorkSecondsPerDay() -> Double {
        let start = secondsFromDate(settings.workStartTime)
        let end = secondsFromDate(settings.workEndTime)
        let total = max(end - start, 0)

        if settings.hasLunchBreak {
            let lunchStart = secondsFromDate(settings.lunchStartTime)
            let lunchEnd = secondsFromDate(settings.lunchEndTime)
            let lunch = max(lunchEnd - lunchStart, 0)
            return Double(max(total - lunch, 0))
        } else {
            return Double(total)
        }
    }

    func workedSecondsBetween(start: Date, end: Date, on referenceDay: Date) -> Double {
        let total = max(end.timeIntervalSince(start), 0)

        guard settings.hasLunchBreak else { return total }

        let lunchStart = combineDay(referenceDay, with: settings.lunchStartTime)
        let lunchEnd = combineDay(referenceDay, with: settings.lunchEndTime)

        if end <= lunchStart || start >= lunchEnd {
            return total
        }

        let overlapStart = maxDate(start, lunchStart)
        let overlapEnd = minDate(end, lunchEnd)
        let lunchOverlap = max(overlapEnd.timeIntervalSince(overlapStart), 0)

        return max(total - lunchOverlap, 0)
    }

    // MARK: - Goal Logic

    func addGoal(title: String, amount: Double) {
        goals.append(Goal(title: title, amount: amount))
    }

    func deleteGoal(id: UUID) {
        goals.removeAll { $0.id == id }
    }

    func moveGoal(from source: Int, to destination: Int) {
        guard source != destination,
              goals.indices.contains(source),
              goals.indices.contains(destination) else { return }

        let item = goals.remove(at: source)
        goals.insert(item, at: destination)
    }

    func completeCurrentGoal() {
        guard let goal = currentGoal, currentVaultAmount >= goal.amount else { return }

        let newDisplayAmount = currentVaultAmount - goal.amount
        vaultBaseAmount = newDisplayAmount - todayEarned
        goals.removeFirst()

        goalRecords.insert(
            GoalRecord(
                title: goal.title,
                amount: goal.amount,
                createdAt: goal.createdAt,
                completedAt: Date(),
                carryOverAmount: max(newDisplayAmount, 0)
            ),
            at: 0
        )
    }

    func abandonCurrentGoal() {
        guard let goal = currentGoal else { return }
        goals.removeFirst()

        goalRecords.insert(
            GoalRecord(
                title: goal.title,
                amount: goal.amount,
                createdAt: goal.createdAt,
                abandonedAt: Date()
            ),
            at: 0
        )
    }

    // MARK: - Todo Logic

    func addTodo(title: String) {
        todos.append(TodoItem(title: title))
    }

    func removeTodo(id: UUID) {
        todos.removeAll { $0.id == id }
    }

    func toggleTodo(id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isDone.toggle()
    }

    // MARK: - Countdown Logic

    func addCountdown(title: String, targetDate: Date) {
        countdowns.append(CountdownItem(title: title, targetDate: targetDate))
    }

    func removeCountdown(id: UUID) {
        countdowns.removeAll { $0.id == id }
    }

    func daysUntil(_ date: Date) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    // MARK: - Archive

    private func archiveIfNeeded(now: Date) {
        let key = dayKey(now)
        guard archivedDayKey != key else { return }

        let archivedDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now

        let record = DailyTodoRecord(
            date: archivedDate,
            items: todos.map { TodoRecordItem(title: $0.title, isDone: $0.isDone) },
            earnedAmount: todayEarned,
            progress: workProgress,
            attendanceSummary: attendanceSummary(now: now)
        )

        dailyTodoRecords.insert(record, at: 0)
        vaultBaseAmount += todayEarned

        archivedDayKey = key
        todayEarned = 0
        workProgress = 0
        attendanceMode = .none
        clockInTime = nil
        clockOutTime = nil
        todos = todos.map { TodoItem(title: $0.title, isDone: false) }
    }

    // MARK: - Display Helpers

    func statusText(now: Date = Date()) -> String {
        switch attendanceMode {
        case .none: return "今天还没开工"
        case .working: return "今天在稳步推进"
        case .workedHalfDay: return "今天半天进行中"
        case .offDay: return "今天不上班"
        case .finished: return "今天已经收工啦"
        }
    }

    func currentPunchLabel() -> String {
        attendanceSummary()
    }

    func currency(_ value: Double) -> String {
        String(format: "¥%.4f", value)
    }

    func currencyShort(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }

    func goalStatusText(_ goal: Goal) -> String {
        let diff = goal.amount - currentVaultAmount
        if diff > 0 {
            return "距离 \(goal.title) 还差 \(currencyShort(diff))"
        } else {
            return "已超过 \(goal.title) \(currencyShort(abs(diff)))"
        }
    }

    func goalProgress(_ goal: Goal) -> Double {
        min(currentVaultAmount / goal.amount, 1.0)
    }

    // MARK: - Monthly Review

    func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    func recordsInSameMonth(as date: Date) -> [DailyTodoRecord] {
        let key = monthKey(for: date)
        return dailyTodoRecords.filter { monthKey(for: $0.date) == key }
    }

    func workedDaysCount(inMonthOf date: Date) -> Int {
        recordsInSameMonth(as: date).filter { record in
            record.attendanceSummary != "没上班" && record.attendanceSummary != "未打卡"
        }.count
    }

    func earnedAmountInMonth(of date: Date) -> Double {
        recordsInSameMonth(as: date)
            .map(\.earnedAmount)
            .reduce(0, +)
    }

    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }

    // MARK: - Date Helpers

    func isWorkdayToday(now: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let mappedWeekday = weekday == 1 ? 7 : weekday - 1
        return mappedWeekday <= settings.workDaysPerWeek
    }

    func scheduledStartDate(for reference: Date) -> Date {
        combineDay(reference, with: settings.workStartTime)
    }

    func scheduledEndDate(for reference: Date) -> Date {
        combineDay(reference, with: settings.workEndTime)
    }

    func combineDay(_ day: Date, with time: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let second = calendar.component(.second, from: time)

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: second,
            of: day
        ) ?? day
    }

    func secondsFromDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        return hour * 3600 + minute * 60 + second
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func maxDate(_ a: Date, _ b: Date) -> Date {
        a > b ? a : b
    }

    private func minDate(_ a: Date, _ b: Date) -> Date {
        a < b ? a : b
    }
}
