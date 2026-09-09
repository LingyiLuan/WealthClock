import FreedomEngine
import Foundation

/// 本地化小工具:中文界面用中文数字(设计语言),其他语言用阿拉伯数字。
enum L10n {
    static var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    /// 铭文读法数字(第X问、第X爻):zh 用 一/廿八 式,其他用 "3"。
    static func numeral(_ value: Int) -> String {
        isChinese ? Suzhou.inscription(value) : String(value)
    }

    /// 大写数字(肆拾柒):zh 专用,其他退回阿拉伯。
    static func upperNumeral(_ value: Int) -> String {
        isChinese ? Suzhou.chineseUpper(value) : String(value)
    }
}
