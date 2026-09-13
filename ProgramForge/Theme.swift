import SwiftUI

enum Theme {
    static let accent = Color(red: 1.00, green: 0.42, blue: 0.21) // electric orange
    static let bg = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let card = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let cardStroke = Color.white.opacity(0.08)
    static let good = Color(red: 0.30, green: 0.85, blue: 0.45)

    static func cardStyle() -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(card)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func pfCard() -> some View {
        background(Theme.cardStyle())
    }
}
