//
//  RingProgress.swift
//  环形进度条 — 用于 Hero 卡显示已审核百分比
//

import SwiftUI

struct RingProgress: View {
    let value: Double          // 0~1
    let lineWidth: CGFloat
    var gradient: [Color] = [Color(red: 1.0, green: 0.55, blue: 0.40),
                              Color(red: 1.0, green: 0.78, blue: 0.50)]

    var body: some View {
        ZStack {
            // 轨道
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            // 进度
            Circle()
                .trim(from: 0, to: max(0.001, min(1, value)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradient + [gradient.first!]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.85), value: value)
        }
    }
}
