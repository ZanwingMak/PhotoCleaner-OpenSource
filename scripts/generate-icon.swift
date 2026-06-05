#!/usr/bin/env swift
//
//  generate-icon.swift
//  用 CoreGraphics 渲染 PhotoCleaner 的 AppIcon（1024x1024 PNG）
//
//  用法：swift scripts/generate-icon.swift <输出路径>
//
//  设计：暖橙渐变底 + 三张倾斜堆叠的卡片（最上一张内嵌山形相机图案）

import AppKit
import CoreGraphics
import Foundation

guard CommandLine.arguments.count >= 2 else {
    print("Usage: swift generate-icon.swift <output.png>")
    exit(1)
}
let outputPath = CommandLine.arguments[1]
let size: CGFloat = 1024

guard let ctx = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Failed to create CGContext") }

// MARK: - 1. 渐变背景（珊瑚 → 杏色，斜向）
let bgColors = [
    CGColor(red: 1.00, green: 0.45, blue: 0.50, alpha: 1.0), // 樱红
    CGColor(red: 1.00, green: 0.68, blue: 0.42, alpha: 1.0)  // 蜜橙
]
let bgGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: bgColors as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// MARK: - 2. 装饰：底层柔光圆点
ctx.saveGState()
ctx.setBlendMode(.softLight)
let glowColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.4)
ctx.setFillColor(glowColor)
ctx.fillEllipse(in: CGRect(x: -200, y: size - 600, width: 800, height: 800))
ctx.restoreGState()

// MARK: - 3. 三张倾斜堆叠卡片
let cardW: CGFloat = 540
let cardH: CGFloat = 680
let cornerR: CGFloat = 64
let centerX = size / 2
let centerY = size / 2

/// 画一张卡片
func drawCard(rotation: CGFloat, offset: CGSize, fillAlpha: CGFloat, shadowOpacity: CGFloat) {
    ctx.saveGState()
    ctx.translateBy(x: centerX + offset.width, y: centerY + offset.height)
    ctx.rotate(by: rotation)

    let cardRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
    let path = CGPath(
        roundedRect: cardRect,
        cornerWidth: cornerR,
        cornerHeight: cornerR,
        transform: nil
    )

    // 阴影
    ctx.setShadow(
        offset: CGSize(width: 0, height: -20),
        blur: 40,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: shadowOpacity)
    )

    ctx.addPath(path)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: fillAlpha))
    ctx.fillPath()

    ctx.restoreGState()
}

// 底层卡（左倾，半透明）
drawCard(rotation: -.pi / 14, offset: CGSize(width: -50, height: 30), fillAlpha: 0.55, shadowOpacity: 0.18)
// 中层卡（轻微右倾）
drawCard(rotation: .pi / 30, offset: CGSize(width: 0, height: 0), fillAlpha: 0.80, shadowOpacity: 0.20)
// 顶层卡（正面纯白）
drawCard(rotation: 0, offset: CGSize(width: 30, height: -20), fillAlpha: 1.0, shadowOpacity: 0.25)

// MARK: - 4. 顶层卡内的「相片」图案（山 + 太阳）
ctx.saveGState()
ctx.translateBy(x: centerX + 30, y: centerY - 20)

// 画一个略小的圆角矩形作为"图片区域"
let photoInsetW = cardW - 100
let photoInsetH = cardH - 200
let photoRect = CGRect(x: -photoInsetW / 2, y: -photoInsetH / 2 + 30, width: photoInsetW, height: photoInsetH)
let photoPath = CGPath(roundedRect: photoRect, cornerWidth: 28, cornerHeight: 28, transform: nil)

// 渐变填充（天空蓝 → 暖黄）
ctx.addPath(photoPath)
ctx.clip()
let skyColors = [
    CGColor(red: 1.00, green: 0.82, blue: 0.55, alpha: 1.0), // 黄昏色顶部
    CGColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 1.0)  // 粉橘色底部
]
let skyGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: skyColors as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    skyGradient,
    start: CGPoint(x: 0, y: photoRect.maxY),
    end: CGPoint(x: 0, y: photoRect.minY),
    options: []
)

// 画太阳
let sunRadius: CGFloat = 70
let sunCenter = CGPoint(x: photoRect.maxX - 120, y: photoRect.maxY - 130)
ctx.setFillColor(CGColor(red: 1, green: 0.92, blue: 0.55, alpha: 1.0))
ctx.fillEllipse(in: CGRect(
    x: sunCenter.x - sunRadius,
    y: sunCenter.y - sunRadius,
    width: sunRadius * 2,
    height: sunRadius * 2
))

// 画两座山（多边形）
ctx.setFillColor(CGColor(red: 0.55, green: 0.32, blue: 0.45, alpha: 1.0))
ctx.beginPath()
ctx.move(to: CGPoint(x: photoRect.minX, y: photoRect.minY))
ctx.addLine(to: CGPoint(x: photoRect.minX + 200, y: photoRect.minY + 280))
ctx.addLine(to: CGPoint(x: photoRect.minX + 350, y: photoRect.minY + 130))
ctx.addLine(to: CGPoint(x: photoRect.minX + 500, y: photoRect.minY + 300))
ctx.addLine(to: CGPoint(x: photoRect.maxX, y: photoRect.minY + 200))
ctx.addLine(to: CGPoint(x: photoRect.maxX, y: photoRect.minY))
ctx.closePath()
ctx.fillPath()

ctx.restoreGState()

// MARK: - 5. 右下角的小「整理」标记（对勾）
ctx.saveGState()
let checkBgRadius: CGFloat = 110
let checkCenter = CGPoint(x: centerX + 290, y: centerY - 280)

// 绿色圆底
ctx.setFillColor(CGColor(red: 0.30, green: 0.78, blue: 0.50, alpha: 1.0))
ctx.fillEllipse(in: CGRect(
    x: checkCenter.x - checkBgRadius,
    y: checkCenter.y - checkBgRadius,
    width: checkBgRadius * 2,
    height: checkBgRadius * 2
))

// 白色对勾
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
ctx.setLineWidth(22)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.beginPath()
ctx.move(to: CGPoint(x: checkCenter.x - 40, y: checkCenter.y))
ctx.addLine(to: CGPoint(x: checkCenter.x - 8, y: checkCenter.y - 32))
ctx.addLine(to: CGPoint(x: checkCenter.x + 44, y: checkCenter.y + 30))
ctx.strokePath()

ctx.restoreGState()

// MARK: - 6. 输出 PNG
guard let cgImage = ctx.makeImage() else { fatalError("Failed to make CGImage") }
let bitmap = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let url = URL(fileURLWithPath: outputPath)
try! pngData.write(to: url)
print("✅ Generated 1024x1024 icon: \(outputPath)")
