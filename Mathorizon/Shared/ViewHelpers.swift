import SwiftUI

func scoreColor(for score: Int) -> Color {
    if score >= 90 {
        return .green
    } else if score >= 70 {
        return .orange
    } else {
        return .red
    }
}

func formatCompactSeconds(_ seconds: Double) -> String {
    if seconds >= 60 {
        return QuizMode.format(seconds: Int(seconds.rounded(.down)))
    }
    return String(format: "%.1f 秒", seconds)
}

struct MathorizonBackdrop: View {
    let palette: CategoryPalette?
    var intensity: Double = 1

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                    Color(red: 0.94, green: 0.95, blue: 0.99),
                    palette?.color.opacity(0.16 * intensity) ?? Color.teal.opacity(0.12 * intensity)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill((palette?.color ?? .blue).opacity(0.12 * intensity))
                .frame(width: 260, height: 260)
                .offset(x: 120, y: -240)

            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color.white.opacity(0.28))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(18))
                .offset(x: -140, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 18, y: 10)
    }
}

struct TimeBlockStrip: View {
    let progress: Double
    let palette: CategoryPalette
    var segments: Int = 16

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<segments, id: \.self) { index in
                let threshold = Double(index + 1) / Double(segments)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(threshold <= progress ? palette.color : Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: threshold <= progress ? 28 : 18)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: progress)
            }
        }
    }
}

struct SummaryChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ResultMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.9))
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.04 : 0.08),
                radius: configuration.isPressed ? 8 : 14,
                y: configuration.isPressed ? 4 : 8
            )
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension Color {
    init?(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    func hexString() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
        #else
        return nil
        #endif
    }

    func darkened(by amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }
        return Color(
            red: max(red - amount, 0),
            green: max(green - amount, 0),
            blue: max(blue - amount, 0),
            opacity: alpha
        )
        #else
        return self
        #endif
    }
}

extension QuestionCategory {
    var homeCardColor: Color {
        if let cardColorHex, let color = Color(hex: cardColorHex) {
            return color
        }
        return palette.color
    }
}

extension QuizDeck {
    var cardColor: Color {
        if let cardColorHex, let color = Color(hex: cardColorHex) {
            return color
        }
        return palette.color
    }
}

private func isEmojiLikeIcon(_ iconName: String) -> Bool {
    iconName.unicodeScalars.contains {
        $0.properties.isEmojiPresentation || $0.properties.isEmoji
    } && !iconName.contains(".")
}

struct CategoryIconView: View {
    let iconName: String
    let size: CGFloat
    var foreground: Color = Color(red: 0.14, green: 0.13, blue: 0.16)

    var body: some View {
        Group {
            if isEmojiLikeIcon(iconName) {
                Text(iconName)
                    .font(.system(size: size))
            } else {
                Image(systemName: iconName)
                    .font(.system(size: size, weight: .black))
                    .foregroundStyle(foreground)
            }
        }
    }
}
