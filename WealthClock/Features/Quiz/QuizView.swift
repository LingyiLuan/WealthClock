import FreedomEngine
import SwiftUI

/// 问卷容器(BRIEF §4,screens_v2B.html 第一屏):一屏一题,六爻进度,下一问/上一问。
/// M5 第一个 PR:骨架与导航,题面为占位;题型组件与引擎接入在后续 PR。
struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var draft = QuizDraft()
    @State private var stepIndex = Self.debugInitialStep()
    @State private var finishedProfile: Profile?

    /// DEBUG:-quizStep N 直达第 N 问(截图脚本用)。
    private static func debugInitialStep() -> Int {
        #if DEBUG
        let args = CommandLine.arguments
        if let flag = args.firstIndex(of: "-quizStep"), flag + 1 < args.count,
           let number = Int(args[flag + 1]) {
            return QuizStep.all.firstIndex { $0.questionNumber == number } ?? 0
        }
        #endif
        return 0
    }

    private var step: QuizStep { QuizStep.all[stepIndex] }

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            if let profile = finishedProfile {
                RevealView(profile: profile, onRestart: restart)
            } else {
                quizBody
            }
        }
    }

    private var quizBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow)
                .font(.system(size: 12, design: .serif)).kerning(5)
                .foregroundStyle(Tokens.inkSoft)
                .padding(.top, 24)
            progress
                .padding(.top, 8)
            Text("每答一问 · 落一爻")
                .font(.system(size: 10, design: .monospaced)).kerning(2)
                .foregroundStyle(Tokens.inkSoft)
                .padding(.top, 8)
            Text(step.title)
                .font(.system(size: 24, design: .serif).weight(.medium))
                .lineSpacing(6)
                .foregroundStyle(Tokens.ink)
                .padding(.top, 26)
            Text(step.why)
                .font(.system(size: 12, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(Tokens.inkSoft)
                .padding(.top, 10)
            if step.usesWheel {
                QuizStepContent(step: step, draft: draft)
                    .padding(.top, 22)
            } else {
                ScrollView {
                    QuizStepContent(step: step, draft: draft)
                        .padding(.top, 22)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            Spacer(minLength: 8)
            controls
        }
        .padding(.horizontal, Tokens.pageMargin)
        .contentShape(Rectangle())
        .onTapGesture { Self.endEditing() }
    }

    /// 点空白收起数字键盘(decimalPad 无回车键)。
    static func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var eyebrow: String {
        step.questionNumber <= 12 ? "第\(Suzhou.inscription(step.questionNumber))问 · 共十二问" : "附问 · 可选"
    }

    /// 六爻进度:前 6 题第一卦,后 6 题第二卦(既济纹样与揭晓页一致)。
    private var progress: some View {
        let lit = draft.yaoCount(upTo: stepIndex)
        return HStack(spacing: 16) {
            hexagramRow(lit: min(lit, 6))
            hexagramRow(lit: max(lit - 6, 0))
        }
    }

    /// 既济纹样(阳实阴断),与揭晓页一致;未落爻淡显。
    private func hexagramRow(lit: Int) -> some View {
        let pattern = [true, false, true, false, true, false]
        return HStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { index in
                let color = index < lit ? Tokens.ink : Tokens.ink.opacity(0.15)
                HStack(spacing: pattern[index] ? 0 : 4) {
                    Rectangle().fill(color).frame(width: pattern[index] ? 20 : 8, height: 3)
                    if !pattern[index] { Rectangle().fill(color).frame(width: 8, height: 3) }
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 6) {
            Button(action: next) {
                Text(stepIndex == QuizStep.all.count - 1 ? "揭晓" : "下一问")
                    .font(.system(size: 15, design: .serif)).kerning(3)
                    .foregroundStyle(canProceed ? Tokens.paper : Tokens.paper.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: Tokens.primaryButtonHeight)
                    .background(canProceed ? Tokens.ink : Tokens.inkSoft.opacity(0.5))
            }
            .disabled(!canProceed)
            HStack {
                if stepIndex > 0 {
                    Button(action: back) {
                        Text("上一问")
                            .font(.system(size: 13, design: .serif)).kerning(2.4)
                            .foregroundStyle(Tokens.inkSoft)
                    }
                }
                Spacer()
                if step.skippable {
                    Button(action: skip) {
                        Text("跳过此问")
                            .font(.system(size: 13, design: .serif)).kerning(2.4)
                            .foregroundStyle(Tokens.inkSoft)
                    }
                }
            }
            .frame(minHeight: 30)
        }
        .padding(.bottom, 10)
    }

    private var canProceed: Bool { draft.isAnswered(step) }

    private func next() {
        if stepIndex == QuizStep.all.count - 1 {
            let profile = draft.assembleProfile()
            // 每次揭晓自动保存(BRIEF §6 History);历史永远免费可看/可导出/可删除。
            modelContext.insert(Reading(profile: profile, result: FreedomEngine.run(profile)))
            finishedProfile = profile
        } else {
            stepIndex += 1
        }
    }

    private func back() { stepIndex -= 1 }

    /// 重新测算:清空答案回第一题。
    private func restart() {
        draft = QuizDraft()
        stepIndex = 0
        finishedProfile = nil
    }

    private func skip() {
        if step == .mortgage {
            draft.mortgageMonthly = nil
            draft.mortgageYearsLeft = 0
        }
        if step == .birthDate { draft.birthDate = nil }
        next()
    }
}

#Preview { QuizView() }
