//
//  WorkSettings.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import Foundation

enum SalaryType: String, CaseIterable, Identifiable, Codable {
    case monthly = "月薪"
    case daily = "日薪"
    case hourly = "时薪"

    var id: String { rawValue }
}

enum AttendanceMode: String, Codable {
    case none
    case working
    case workedHalfDay
    case offDay
    case finished
}

enum BackfillAttendanceType: String, CaseIterable, Identifiable {
    case normal = "正常上班"
    case late = "迟到"
    case overtime = "加班"
    case offDay = "没上班"
    case halfDay = "上班半天"

    var id: String { rawValue }
}

struct WorkSettings: Codable {
    var salaryType: SalaryType = .monthly
    var salaryAmount: Double = 8000
    var workDaysPerWeek: Int = 5

    var workStartTime: Date = WorkSettings.makeTime(hour: 9, minute: 30)
    var workEndTime: Date = WorkSettings.makeTime(hour: 18, minute: 0)

    var hasLunchBreak: Bool = true
    var lunchStartTime: Date = WorkSettings.makeTime(hour: 12, minute: 0)
    var lunchEndTime: Date = WorkSettings.makeTime(hour: 13, minute: 0)

    var initialVaultAmount: Double = 248.36

    static func makeTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

struct Goal: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var createdAt: Date

    init(id: UUID = UUID(), title: String, amount: Double, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.amount = amount
        self.createdAt = createdAt
    }
}

struct GoalRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var createdAt: Date
    var completedAt: Date?
    var abandonedAt: Date?
    var carryOverAmount: Double?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        createdAt: Date,
        completedAt: Date? = nil,
        abandonedAt: Date? = nil,
        carryOverAmount: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.abandonedAt = abandonedAt
        self.carryOverAmount = carryOverAmount
    }
}

struct TodoItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

struct TodoRecordItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

struct DailyTodoRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var date: Date
    var items: [TodoRecordItem]
    var earnedAmount: Double
    var progress: Double
    var attendanceSummary: String

    init(
        id: UUID = UUID(),
        date: Date,
        items: [TodoRecordItem],
        earnedAmount: Double,
        progress: Double,
        attendanceSummary: String
    ) {
        self.id = id
        self.date = date
        self.items = items
        self.earnedAmount = earnedAmount
        self.progress = progress
        self.attendanceSummary = attendanceSummary
    }
}

struct CountdownItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var targetDate: Date
    var isPinned: Bool
    var showInWidget: Bool

    init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        isPinned: Bool = false,
        showInWidget: Bool = true
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.isPinned = isPinned
        self.showInWidget = showInWidget
    }
}

struct ManualIncomeRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var amount: Double
    var note: String
    var createdAt: Date

    init(id: UUID = UUID(), amount: Double, note: String, createdAt: Date = Date()) {
        self.id = id
        self.amount = amount
        self.note = note
        self.createdAt = createdAt
    }
}
