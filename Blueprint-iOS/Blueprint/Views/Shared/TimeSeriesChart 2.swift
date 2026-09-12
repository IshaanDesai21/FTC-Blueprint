import SwiftUI

/// Ports the shared `toPath`/gridline pattern used across the web simulators' SVG
/// charts: X is normalized across the sample buffer's own time span (a scrolling
/// window), Y maps linearly across [yMin, yMax].
struct TimeSeriesChart: View {
    let series: [Sample]
    let yMin: Double
    let yMax: Double
    let color: Color
    let filled: Bool
    var secondSeries: [Sample]? = nil
    var secondColor: Color = .gray
    var pad: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            func yFor(_ v: Double) -> CGFloat {
                let clamped = min(max(v, yMin), yMax)
                return h - pad - (CGFloat((clamped - yMin) / (yMax - yMin)) * (h - 2 * pad))
            }

            // Gridlines
            for frac in [0.0, 0.5, 1.0] {
                let y = pad + CGFloat(1 - frac) * (h - 2 * pad)
                var line = Path()
                line.move(to: CGPoint(x: pad, y: y))
                line.addLine(to: CGPoint(x: w - pad, y: y))
                context.stroke(line, with: .color(Theme.border.opacity(0.4)), lineWidth: 1)
            }

            if let second = secondSeries {
                draw(second, in: &context, w: w, h: h, yFor: yFor, color: secondColor, dashed: true, fill: false)
            }
            draw(series, in: &context, w: w, h: h, yFor: yFor, color: color, dashed: false, fill: filled)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func draw(_ data: [Sample], in context: inout GraphicsContext, w: CGFloat, h: CGFloat, yFor: (Double) -> CGFloat, color: Color, dashed: Bool, fill: Bool) {
        guard data.count >= 2 else { return }
        let tMin = data.first!.t
        let tRange = max(data.last!.t - tMin, 0.0001)

        func xFor(_ t: Double) -> CGFloat {
            pad + CGFloat((t - tMin) / tRange) * (w - 2 * pad)
        }

        var path = Path()
        for (i, s) in data.enumerated() {
            let point = CGPoint(x: xFor(s.t), y: yFor(s.v))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }

        if fill {
            var fillPath = path
            fillPath.addLine(to: CGPoint(x: xFor(data.last!.t), y: h - pad))
            fillPath.addLine(to: CGPoint(x: xFor(data.first!.t), y: h - pad))
            fillPath.closeSubpath()
            context.fill(fillPath, with: .color(color.opacity(0.15)))
        }

        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: dashed ? [5, 3] : []))
    }
}
