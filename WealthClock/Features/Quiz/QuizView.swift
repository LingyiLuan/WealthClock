import FreedomEngine
import SwiftUI

/// 问卷容器(BRIEF §4,screens_v2B.html 第一屏):一屏一题,六爻进度,下一问/上一问。
/// M5 第一个 PR:骨架与导航,题面为占位;题型组件与引擎接入在后续 PR。
struct QuizView: View {
    @State private var draft = QuizDraft()
    @State private var stepIndex = 0
    @State private var finishedProfile: Profile?

    private var step: QuizStep { QuizStep.all[stepIndex] }

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            if finishedProfile != nil {
                // 接引擎与揭晓在 M5 第三个 PR;先显示完成占位。
                Text("已答完 · 揭晓接入中")
                    .font(.system(size: 15, design: .serif)).kerning(3)
                    .foregroundStyle(Tokens.inkSoft)
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
            ScrollView {
                QuizStepContent(step: step, draft: draft)
                    .padding(.top, 22)
            }
            .scrollIndicators(.hidden)
            Spacer(minLength: 8)
            controls
        }
        .padding(.horizontal, Tokens.pageMargin)
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

    private func hexagramRow(lit: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { index in
                Rectangle()
                    .fill(index < lit ? Tokens.ink : Tokens.ink.opacity(0.15))
                    .frame(width: 20, height: 3)
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
            finishedProfile = Profile.sample  // M5 第三个 PR:改为组装真实 Profile 并跳揭晓
        } else {
            stepIndex += 1
        }
    }

    private func back() { stepIndex -= 1 }

    private func skip() {
        if step == .mortgage {
            draft.mortgageMonthly = nil
            draft.mortgageYearsLeft = 0
        }
        if step == .birthDate { draft.birthDate = nil }
        next()
    }
}

/// 题面内容分发。M5 第一个 PR 全部为占位;第二个 PR 换成真输入组件。
struct QuizStepContent: View {
    let step: QuizStep
    var draft: QuizDraft

    var body: some View {
        Text("(题型组件接入中)")
            .font(.system(size: 12, design: .serif))
            .foregroundStyle(Tokens.inkSoft.opacity(0.6))
    }
}

#Preview { QuizView() }
