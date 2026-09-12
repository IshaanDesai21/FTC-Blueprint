import SwiftUI

/// The brand hexagon outline, matching the web favicon/app icon exactly.
struct HexagonMark: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let angle = Angle(degrees: -90 + Double(i) * 60).radians
            let point = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

extension HexagonMark {
    static let brandGradient = LinearGradient(
        colors: [Color(red: 0x74 / 255, green: 0xD7 / 255, blue: 0xED / 255),
                  Color(red: 0x7E / 255, green: 0xFF / 255, blue: 0xA0 / 255)],
        startPoint: .leading,
        endPoint: .trailing
    )
}
