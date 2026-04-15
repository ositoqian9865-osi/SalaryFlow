import SwiftUI
import UniformTypeIdentifiers

struct GoalsView: View {
    @EnvironmentObject var vm: AppViewModel

    @State private var showAddGoalSheet = false
    @State private var newGoalTitle = ""
    @State private var newGoalAmount = ""
    @State private var draggedGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                ClayBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        currentGoalCard
                        goalListCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddGoalSheet = true
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
            .sheet(isPresented: $showAddGoalSheet) {
                addGoalSheet
            }
        }
    }

    var currentGoalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("当前目标")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if let goal = vm.currentGoal {
                Text(goal.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("目标金额 \(vm.currencyShort(goal.amount))")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(vm.goalStatusText(goal))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                ClayProgressBar(progress: vm.goalProgress(goal))
                    .frame(height: 18)
            } else {
                Text("暂无目标")
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(22)
        .clayCard()
    }

    var goalListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("目标列表")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text("长按拖动排序")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if vm.goals.isEmpty {
                Text("还没有目标")
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(vm.goals.enumerated()), id: \.element.id) { index, goal in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(goal.title)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Spacer()

                                    Text(vm.currencyShort(goal.amount))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                HStack(spacing: 8) {
                                    Text("创建于 \(goal.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)

                                    Text("·")
                                        .foregroundStyle(AppTheme.textSecondary)

                                    Text(index == 0 ? "当前目标" : "排队中")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary)

                            Button {
                                vm.deleteGoal(id: goal.id)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    draggedGoal?.id == goal.id
                                    ? Color(red: 0.97, green: 0.90, blue: 0.86)
                                    : Color(red: 0.94, green: 0.91, blue: 0.89)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                        )
                        .shadow(color: .white.opacity(0.72), radius: 3, x: -2, y: -2)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 2, y: 2)
                        .onDrag {
                            draggedGoal = goal
                            return NSItemProvider(object: goal.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: GoalReorderDropDelegate(
                                item: goal,
                                goals: $vm.goals,
                                draggedGoal: $draggedGoal
                            )
                        )
                    }
                }
            }
        }
        .padding(22)
        .clayCard()
    }

    var addGoalSheet: some View {
        NavigationStack {
            Form {
                Section("新增目标") {
                    TextField("目标名称", text: $newGoalTitle)
                    TextField("金额", text: $newGoalAmount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("新增目标")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        showAddGoalSheet = false
                        newGoalTitle = ""
                        newGoalAmount = ""
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") {
                        let trimmed = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let amount = Double(newGoalAmount), amount > 0, !trimmed.isEmpty {
                            vm.addGoal(title: trimmed, amount: amount)
                            newGoalTitle = ""
                            newGoalAmount = ""
                            showAddGoalSheet = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct GoalReorderDropDelegate: DropDelegate {
    let item: Goal
    @Binding var goals: [Goal]
    @Binding var draggedGoal: Goal?

    func performDrop(info: DropInfo) -> Bool {
        draggedGoal = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedGoal,
              draggedGoal.id != item.id,
              let fromIndex = goals.firstIndex(of: draggedGoal),
              let toIndex = goals.firstIndex(of: item) else { return }

        if goals[toIndex] != draggedGoal {
            withAnimation(.spring()) {
                let moved = goals.remove(at: fromIndex)
                goals.insert(moved, at: toIndex)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
