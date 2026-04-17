import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: AppViewModel

    @State private var showSettingsSheet = false
    @State private var showAddCountdownSheet = false
    @State private var showAddTodoSheet = false
    @State private var showAddIncomeSheet = false
    @State private var toastMessage: String?

    @State private var newCountdownTitle = ""
    @State private var newCountdownDate = Date()
    @State private var newTodoTitle = ""
    @State private var manualIncomeAmount = ""
    @State private var manualIncomeNote = ""

    var body: some View {
        ZStack {
            ClayBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topHeader
                    todayCard
                    vaultCard
                    todoCard
                    countdownCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSettingsSheet, onDismiss: {
            vm.handleSettingsUpdated()
        }) {
            SettingsView(
                settings: Binding(
                    get: { vm.settings },
                    set: { vm.settings = $0 }
                )
            )
        }
        .sheet(isPresented: $showAddCountdownSheet) {
            addCountdownSheet
        }
        .sheet(isPresented: $showAddTodoSheet) {
            addTodoSheet
        }
        .sheet(isPresented: $showAddIncomeSheet) {
            addIncomeSheet
        }
    }

    var topHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SalaryFlow")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(vm.statusText())
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(Color(red: 0.42, green: 0.38, blue: 0.38))
                    .clayCircle()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    var todayCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日已赚")
                .font(.headline)
                .foregroundStyle(Color(red: 0.36, green: 0.31, blue: 0.31))

            Text(vm.currency(vm.todayEarned))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .contentTransition(.numericText())

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()

                    Text("\(Int(vm.workProgress * 100))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.bottom, -10)

                runningProgressBar
                    .frame(height: 44)
            }
            .padding(.top, -6)

            Text(vm.currentPunchLabel())
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 6)

            punchGrid
                .padding(.top, 6)
        }
        .padding(22)
        .clayCard()
    }

    var runningProgressBar: some View {
        GeometryReader { geo in
            let runnerSize: CGFloat = 170
            let barHeight: CGFloat = 20
            let barY: CGFloat = -48
            let runnerY: CGFloat = -70
            let progressWidth = max(20, geo.size.width * vm.workProgress)

            ZStack(alignment: .leading) {
                // 已走进度：主题色
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: progressWidth, height: barHeight)
                    .offset(y: barY)
                    .zIndex(1)

                // 人物
                Group {
                    if vm.attendanceMode == .workedHalfDay {
                        Image("halfday_worker")
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image("clockin_worker")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: runnerSize, height: runnerSize)
                .offset(
                    x: max(0, (geo.size.width - runnerSize) * vm.workProgress),
                    y: runnerY
                )
                .zIndex(2)
                .animation(.spring(duration: 0.35), value: vm.workProgress)

                // 底轨
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .frame(height: barHeight)
                    .offset(y: barY)
                    .zIndex(3)
            }
        }
    }

    var punchGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                punchImageCard(
                    imageName: "clockin_worker",
                    fallbackEmoji: "👩🏻‍💻",
                    title: "开工啦",
                    active: vm.attendanceMode == .working
                ) {
                    vm.punchIn()
                }

                punchImageCard(
                    imageName: "clockout_home",
                    fallbackEmoji: "🧺",
                    title: "收工啦",
                    active: vm.attendanceMode == .finished,
                    enabled: vm.attendanceMode == .working || vm.attendanceMode == .workedHalfDay,
                    dimmed: !vm.canPunchOut() && (vm.attendanceMode == .working || vm.attendanceMode == .workedHalfDay)
                ) {
                    let message = vm.punchOut() ?? "还没下班哦～"
                    showToast(message)
                }
            }

            HStack(spacing: 10) {
                punchImageCard(
                    imageName: "offday_rest",
                    fallbackEmoji: "☁️",
                    title: "不上班",
                    active: vm.attendanceMode == .offDay
                ) {
                    vm.markOffToday()
                }

                punchImageCard(
                    imageName: "halfday_worker",
                    fallbackEmoji: "🫶🏻",
                    title: "半天哦",
                    active: vm.attendanceMode == .workedHalfDay
                ) {
                    vm.markHalfDay()
                }
            }
        }
    }

    @ViewBuilder
    func punchImageCard(
        imageName: String,
        fallbackEmoji: String,
        title: String,
        active: Bool,
        enabled: Bool = true,
        dimmed: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if let uiImage = UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(5.0)
                            .frame(width: 84, height: 84)
                            .clipped()
                            .allowsHitTesting(false)
                    } else {
                        Text(fallbackEmoji)
                            .font(.system(size: 40))
                            .frame(width: 84, height: 84)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: 84, height: 84)
                .allowsHitTesting(false)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, minHeight: 132)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        active
                        ? Color(red: 0.97, green: 0.90, blue: 0.86)
                        : Color(red: 0.94, green: 0.91, blue: 0.89)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .white.opacity(0.78), radius: 4, x: -2, y: -2)
            .shadow(color: Color.black.opacity(0.07), radius: 5, x: 3, y: 3)
            .opacity(dimmed ? 0.45 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    var vaultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("小金库")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.36, green: 0.31, blue: 0.31))

                Spacer()

                Button {
                    showAddIncomeSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(Color(red: 0.42, green: 0.38, blue: 0.38))
                        .clayCircle()
                }
                .buttonStyle(.plain)
            }

            Text(vm.currencyShort(vm.currentVaultAmount))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            if let goal = vm.currentGoal {
                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.goalStatusText(goal))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    ClayProgressBar(progress: vm.goalProgress(goal))
                        .frame(height: 18)
                }

                HStack(spacing: 10) {
                    Button(action: vm.completeCurrentGoal) {
                        Text("我已完成")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .clayButton()
                    }
                    .buttonStyle(.plain)

                    Button(action: vm.abandonCurrentGoal) {
                        Text("放弃目标")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .clayButton()
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("所有目标都完成啦")
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(22)
        .clayCard()
    }

    var todoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日待办")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.36, green: 0.31, blue: 0.31))

                Spacer()

                Button {
                    showAddTodoSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(Color(red: 0.42, green: 0.38, blue: 0.38))
                        .clayCircle()
                }
                .buttonStyle(.plain)
            }

            if vm.todos.isEmpty {
                Text("还没有待办")
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(vm.todos) { todo in
                    HStack(spacing: 10) {
                        Button {
                            vm.toggleTodo(id: todo.id)
                            vm.upsertTodayReviewRecord()
                        } label: {
                            Image(systemName: todo.isDone ? "checkmark.circle" : "circle")
                                .font(.system(size: 19))
                                .foregroundStyle(Color(red: 0.42, green: 0.38, blue: 0.38).opacity(todo.isDone ? 0.6 : 0.95))
                        }
                        .buttonStyle(.plain)

                        Text(todo.title)
                            .foregroundStyle(todo.isDone ? .secondary : Color(red: 0.29, green: 0.26, blue: 0.26))
                            .strikethrough(todo.isDone, color: .secondary.opacity(0.4))

                        Spacer()

                        Button {
                            vm.removeTodo(id: todo.id)
                            vm.upsertTodayReviewRecord()
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 19))
                                .foregroundStyle(Color(red: 0.42, green: 0.38, blue: 0.38).opacity(0.5))
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

    var countdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("把重要的日子放眼前")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.36, green: 0.31, blue: 0.31))

                Spacer()

                Button {
                    showAddCountdownSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(Color(red: 0.42, green: 0.38, blue: 0.38))
                        .clayCircle()
                }
                .buttonStyle(.plain)
            }

            if vm.widgetCountdowns.isEmpty {
                Text("还没有倒计时")
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(vm.widgetCountdowns) { item in
                    let dayOffset = vm.daysUntil(item.targetDate)

                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.97, green: 0.93, blue: 0.88))
                            .frame(width: 56, height: 56)
                            .overlay(
                                VStack(spacing: 2) {
                                    Text("\(abs(dayOffset))")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color(red: 0.62, green: 0.46, blue: 0.32))

                                    Text(dayOffset >= 0 ? "天后" : "天前")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(item.targetDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Text(dayOffset >= 0 ? "还有 \(dayOffset) 天" : "已经 \(abs(dayOffset)) 天")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
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
                    TextField("标题", text: $newCountdownTitle)
                    DatePicker("日期", selection: $newCountdownDate, displayedComponents: .date)
                }
            }
            .navigationTitle("新增倒计时")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        newCountdownTitle = ""
                        newCountdownDate = Date()
                        showAddCountdownSheet = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") {
                        let trimmed = newCountdownTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            vm.addCountdown(title: trimmed, targetDate: newCountdownDate)
                            newCountdownTitle = ""
                            newCountdownDate = Date()
                            showAddCountdownSheet = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    var addTodoSheet: some View {
        NavigationStack {
            Form {
                Section("新增待办") {
                    TextField("比如：回客户消息", text: $newTodoTitle)
                }
            }
            .navigationTitle("新增待办")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        newTodoTitle = ""
                        showAddTodoSheet = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") {
                        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            vm.addTodo(title: trimmed)
                            vm.upsertTodayReviewRecord()
                            newTodoTitle = ""
                            showAddTodoSheet = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    var addIncomeSheet: some View {
        NavigationStack {
            Form {
                Section("手动增加收入") {
                    TextField("金额", text: $manualIncomeAmount)
                        .keyboardType(.decimalPad)

                    TextField("备注，例如 兼职 / 奖金", text: $manualIncomeNote)
                }
            }
            .navigationTitle("增加收入")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        manualIncomeAmount = ""
                        manualIncomeNote = ""
                        showAddIncomeSheet = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") {
                        let note = manualIncomeNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let amount = Double(manualIncomeAmount), amount > 0 {
                            vm.addManualIncome(amount: amount, note: note)
                            manualIncomeAmount = ""
                            manualIncomeNote = ""
                            showAddIncomeSheet = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    func showToast(_ message: String) {
        withAnimation(.spring(duration: 0.3)) {
            toastMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if toastMessage == message {
                withAnimation(.spring(duration: 0.3)) {
                    toastMessage = nil
                }
            }
        }
    }
}
