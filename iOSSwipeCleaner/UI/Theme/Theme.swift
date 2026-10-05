import SwiftUI

enum Theme {
    static let backgroundTop = Color(hex: 0x1E1E2C)
    static let backgroundBottom = Color(hex: 0x0F0F14)
    static let surface = Color(hex: 0x252538)
    static let primary = Color(hex: 0x6C63FF)
    static let keep = Color(hex: 0x4CAF50)
    static let delete = Color(hex: 0xE91E63)
    static let secondaryText = Color(white: 0.75)

    static let background = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Full-bleed dark gradient used behind every screen.
struct AppBackground: View {
    var body: some View {
        Theme.background.ignoresSafeArea()
    }
}
