import FreedomEngine
import SwiftUI

/// 汇票导出:ImageRenderer scale 3 → 1080×1920 PNG(BRIEF §6 Bill)。
enum BillExporter {
    @MainActor static func renderImage(profile: Profile = .sample) -> UIImage? {
        let renderer = ImageRenderer(content: BillView(profile: profile).frame(width: 360, height: 640))
        renderer.scale = 3
        return renderer.uiImage
    }

    /// 写入 Documents/WealthBill.png,返回文件 URL(供 ShareLink 与 -exportBill 自动导出)。
    @MainActor static func saveToDocuments(profile: Profile = .sample) -> URL? {
        guard let data = renderImage(profile: profile)?.pngData(),
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        let url = documents.appendingPathComponent("WealthBill.png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
