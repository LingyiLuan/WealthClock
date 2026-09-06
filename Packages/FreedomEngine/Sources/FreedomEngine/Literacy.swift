import Foundation

/// Lusardi–Mitchell "三大题"的本地化改写。答对数 = Profile.literacyScore。
public struct LiteracyQuestion: Equatable, Identifiable {
    public let id: String
    public let prompt: String
    public let options: [String]
    public let correctIndex: Int
    public let explanation: String
}

public enum Literacy {
    public static let questions: [LiteracyQuestion] = [
        LiteracyQuestion(
            id: "compound",
            prompt: "100 元存入年利率 2% 的账户,五年后账户里的钱会:",
            options: ["多于 102 元", "正好 102 元", "少于 102 元"],
            correctIndex: 0,
            explanation: "利息会再生利息。五年后约 110.4 元,这就是复利。"
        ),
        LiteracyQuestion(
            id: "inflation",
            prompt: "账户年利率 1%,通胀 2%。一年后,这笔钱能买到的东西:",
            options: ["比今天多", "和今天一样", "比今天少"],
            correctIndex: 2,
            explanation: "名义上多了 1%,物价涨了 2%,购买力反而下降约 1%。"
        ),
        LiteracyQuestion(
            id: "diversify",
            prompt: "“买单只公司的股票,通常比买一只股票基金更安全。”这句话:",
            options: ["对", "错"],
            correctIndex: 1,
            explanation: "单只股票承担公司个体风险;基金分散到几十上百家,波动通常更小。"
        )
    ]

    public static func score(answers: [String: Int]) -> Int {
        questions.reduce(0) { acc, q in acc + ((answers[q.id] == q.correctIndex) ? 1 : 0) }
    }
}
