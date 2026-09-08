#!/usr/bin/env swift
// App 图标程序生成(BRIEF §8 M8):宣纸底 + Guilloche 角饰(tokens.md 方程)+ 像素铜钱 + 朱砂细框。
// 重跑:swift scripts/make_icon.swift WealthClock/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "WealthClock/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png"

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let paper = rgb(0xEFE6D2)
let gilt = rgb(0xC6A14A)
let giltDeep = rgb(0x9A7A2E)
let cinnabar = rgb(0xB8412F)

guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
          data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
          space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
else { fatalError("context") }

// 宣纸底
context.setFillColor(paper)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Guilloche 角饰玫瑰(tokens.md 方程,10 层 φ 步进 0.31,θ 步长 3°)居中放大
let center = CGPoint(x: 512, y: 512)
let bigR = 430.0
context.setStrokeColor(rgb(0x9A7A2E, 0.85))
context.setLineWidth(2.4)
for layer in 0..<10 {
    let phi = 0.2 + Double(layer) * 0.31
    context.beginPath()
    for step in 0...120 {
        let theta = Double(step) * 3 * .pi / 180
        let radius = bigR * (0.62
            + 0.16 * sin(6 * theta + phi)
            + 0.09 * sin(11 * theta - 2 * phi)
            + 0.05 * sin(17 * theta + 3 * phi))
        let point = CGPoint(x: center.x + radius * cos(theta), y: center.y + radius * sin(theta))
        if step == 0 {
            context.move(to: point)
        } else {
            context.addLine(to: point)
        }
    }
    context.closePath()
    context.strokePath()
}

// 像素铜钱 11×11(tokens.md 位图),鎏金,居中盖在玫瑰上
let bitmap = [
    "   #####   ", "  #######  ", " ######### ", "###########",
    "####...####", "####...####", "####...####",
    "###########", " ######### ", "  #######  ", "   #####   "
]
let unit = 46.0
let origin = CGPoint(x: center.x - unit * 5.5, y: center.y - unit * 5.5)
func isRim(_ row: Int, _ col: Int) -> Bool {
    let neighbors = [(row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)]
    return neighbors.contains { r, c in
        guard r >= 0, r < 11, c >= 0, c < 11 else { return true }
        return Array(bitmap[r])[c] == " "
    }
}
for (row, line) in bitmap.enumerated() {
    for (col, char) in line.enumerated() where char == "#" {
        context.setFillColor(isRim(row, col) ? giltDeep : gilt)
        // CoreGraphics y 轴向上,行序翻转
        context.fill(CGRect(
            x: origin.x + Double(col) * unit,
            y: origin.y + Double(10 - row) * unit,
            width: unit, height: unit
        ))
    }
}

// 朱砂细框
context.setStrokeColor(cinnabar)
context.setLineWidth(10)
context.stroke(CGRect(x: 42, y: 42, width: 940, height: 940))

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
          URL(fileURLWithPath: outPath) as CFURL, UTType.png.identifier as CFString, 1, nil
      )
else { fatalError("image/destination") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("write failed") }
print("icon written: \(outPath)")
