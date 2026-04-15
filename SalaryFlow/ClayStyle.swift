//
//  ClayStyle.swift
//  SalaryFlow
//
//  Created by 许倩 on 2026/4/15.
//

import SwiftUI

struct ClayBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.93, blue: 0.91),
                Color(red: 0.92, green: 0.90, blue: 0.89)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ClayCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 0.93, green: 0.90, blue: 0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .white.opacity(0.75), radius: 6, x: -4, y: -4)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 5, y: 6)
    }
}

struct ClayInnerCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.91, green: 0.88, blue: 0.86))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .white.opacity(0.65), radius: 4, x: -2, y: -2)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 3, y: 3)
    }
}

struct ClayButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.92, green: 0.89, blue: 0.87))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .white.opacity(0.7), radius: 3, x: -2, y: -2)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 2, y: 2)
    }
}

struct ClayCircleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(Color(red: 0.92, green: 0.89, blue: 0.87))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .white.opacity(0.7), radius: 3, x: -2, y: -2)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 2, y: 2)
    }
}

extension View {
    func clayCard() -> some View {
        modifier(ClayCardModifier())
    }

    func clayInnerCard() -> some View {
        modifier(ClayInnerCardModifier())
    }

    func clayButton() -> some View {
        modifier(ClayButtonModifier())
    }

    func clayCircle() -> some View {
        modifier(ClayCircleModifier())
    }
}

struct ClayProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clamped = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.45))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.66, green: 0.77, blue: 0.96),
                                Color(red: 0.56, green: 0.69, blue: 0.93)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * clamped)
            }
        }
        .frame(height: 16)
    }
}
