import SwiftUI

/// Renders a post body as native SwiftUI content: real headings, a real table
/// grid, callout cards with icons, code blocks, and lists, using Dynamic Type
/// text styles throughout so it respects the user's text size and native look.
struct SimpleMarkdownText: View {
    let markdown: String

    private var chunks: [Chunk] {
        Self.split(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(chunks.enumerated()), id: \.offset) { index, chunk in
                render(chunk)
                    .padding(.top, topSpacing(for: chunk, isFirst: index == 0))
            }
        }
    }

    /// Headings get extra breathing room above them so sections read as clearly
    /// separated, rather than every element sharing one uniform tight gap.
    private func topSpacing(for chunk: Chunk, isFirst: Bool) -> CGFloat {
        guard !isFirst, case .heading(let level, _) = chunk else { return 0 }
        return level <= 2 ? 20 : 10
    }

    @ViewBuilder
    private func render(_ chunk: Chunk) -> some View {
        switch chunk {
        case .heading(let level, let text):
            Text(inline(text))
                .font(headingFont(level))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

        case .code(let language, let code):
            CodeBlockView(language: language, code: code)

        case .quote(let kind, let text):
            CalloutCard(kind: kind, text: inline(text))

        case .list(let ordered, let items):
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text(ordered ? "\(index + 1)." : "\u{2022}")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(Theme.accentCyan)
                            .frame(minWidth: 20, alignment: .trailing)
                        Text(inline(item))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(5)
                    }
                }
            }

        case .table(let headers, let rows):
            MarkdownTableView(headers: headers, rows: rows)

        case .rule:
            Divider()
                .padding(.vertical, 4)

        case .paragraph(let text):
            Text(inline(text))
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(7)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(.title, design: .rounded, weight: .bold)
        case 2: return .system(.title2, design: .rounded, weight: .bold)
        case 3: return .system(.title3, design: .rounded, weight: .semibold)
        default: return .system(.headline, design: .rounded, weight: .semibold)
        }
    }

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    // MARK: - Splitting

    private enum Chunk {
        case heading(Int, String)
        case code(String?, String)
        case quote(CalloutKind, String)
        case list(Bool, [String])
        case table([String], [[String]])
        case rule
        case paragraph(String)
    }

    private static func split(_ raw: String) -> [Chunk] {
        let lines = raw.components(separatedBy: "\n")
        var chunks: [Chunk] = []
        var i = 0

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { i += 1; continue }

            if trimmed.hasPrefix("```") {
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count, !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1
                chunks.append(.code(lang.isEmpty ? nil : lang, code.joined(separator: "\n")))
                continue
            }

            if trimmed.hasPrefix("$$") {
                var math: [String] = [String(trimmed.dropFirst(2))]
                i += 1
                while i < lines.count, !lines[i].trimmingCharacters(in: .whitespaces).hasSuffix("$$") {
                    math.append(lines[i])
                    i += 1
                }
                if i < lines.count { i += 1 }
                let formula = math.joined(separator: " ").replacingOccurrences(of: "$$", with: "")
                chunks.append(.code("math", formula.trimmingCharacters(in: .whitespaces)))
                continue
            }

            if trimmed.hasPrefix("#") {
                var level = 0
                var idx = trimmed.startIndex
                while idx < trimmed.endIndex, trimmed[idx] == "#" { level += 1; idx = trimmed.index(after: idx) }
                let text = trimmed[idx...].trimmingCharacters(in: .whitespaces)
                if level <= 6 && !text.isEmpty {
                    chunks.append(.heading(level, text))
                    i += 1
                    continue
                }
            }

            let compact = trimmed.replacingOccurrences(of: " ", with: "")
            if compact.count >= 3, compact.allSatisfy({ $0 == "-" }) {
                chunks.append(.rule)
                i += 1
                continue
            }

            if trimmed.hasPrefix(">") {
                var qLines: [String] = []
                var kind: CalloutKind = .plain
                var first = true
                while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    var s = lines[i].trimmingCharacters(in: .whitespaces)
                    s.removeFirst()
                    if s.hasPrefix(" ") { s.removeFirst() }
                    if first {
                        for (marker, k) in [("[!NOTE]", CalloutKind.note), ("[!WARNING]", .warning), ("[!CAUTION]", .caution), ("[!TIP]", .tip)] where s.hasPrefix(marker) {
                            kind = k
                            s = String(s.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
                        }
                        first = false
                    }
                    if !s.isEmpty { qLines.append(s) }
                    i += 1
                }
                chunks.append(.quote(kind, qLines.joined(separator: " ")))
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix("- ") || t.hasPrefix("* ") {
                        items.append(String(t.dropFirst(2)))
                        i += 1
                    } else {
                        break
                    }
                }
                chunks.append(.list(false, items))
                continue
            }

            if let dot = trimmed.firstIndex(of: "."),
               !trimmed[trimmed.startIndex..<dot].isEmpty,
               trimmed[trimmed.startIndex..<dot].allSatisfy({ $0.isNumber }) {
                var items: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    guard let d = t.firstIndex(of: "."),
                          !t[t.startIndex..<d].isEmpty,
                          t[t.startIndex..<d].allSatisfy({ $0.isNumber }) else { break }
                    items.append(String(t[t.index(after: d)...]).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                chunks.append(.list(true, items))
                continue
            }

            if trimmed.hasPrefix("|") {
                var tableLines: [String] = []
                while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                    tableLines.append(lines[i].trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                if let table = parseTable(tableLines) {
                    chunks.append(.table(table.0, table.1))
                }
                continue
            }

            var paraLines: [String] = []
            while i < lines.count {
                let t = lines[i].trimmingCharacters(in: .whitespaces)
                if t.isEmpty || t.hasPrefix("```") || t.hasPrefix("#") || t.hasPrefix(">")
                    || t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("|") || t.hasPrefix("$$") {
                    break
                }
                paraLines.append(lines[i])
                i += 1
            }
            if !paraLines.isEmpty {
                chunks.append(.paragraph(paraLines.joined(separator: " ")))
            }
        }

        return chunks
    }

    private static func parseTable(_ lines: [String]) -> ([String], [[String]])? {
        guard lines.count >= 2 else { return nil }
        func cells(_ line: String) -> [String] {
            var t = line
            if t.hasPrefix("|") { t.removeFirst() }
            if t.hasSuffix("|") { t.removeLast() }
            return t.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        let headers = cells(lines[0])
        let rows = lines.dropFirst(2).map(cells)
        return (headers, Array(rows))
    }
}

private struct CodeBlockView: View {
    let language: String?
    let code: String

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let language, language != "math" {
                    Text(language.uppercased())
                        .font(.caption2.monospaced().weight(.bold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                copyButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.border, lineWidth: 0.5))
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = code
            withAnimation(.snappy) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.snappy) { copied = false }
            }
        } label: {
            Label(copied ? "Copied".localizedUI : "Copy".localizedUI, systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(copied ? Theme.accentGreen : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "Copied to clipboard" : "Copy code")
    }
}

private struct CalloutCard: View {
    let kind: CalloutKind
    let text: AttributedString

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(kind.color)
                .frame(width: 20)

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineSpacing(5)
        }
        .padding(16)
        .background(kind.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

enum CalloutKind {
    case note, warning, caution, tip, plain

    var systemImage: String {
        switch self {
        case .note: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .caution: return "xmark.octagon.fill"
        case .tip: return "lightbulb.fill"
        case .plain: return "quote.opening"
        }
    }

    var color: Color {
        switch self {
        case .note: return Theme.accentCyan
        case .warning: return Theme.accentYellow
        case .caution: return .red
        case .tip: return Theme.accentGreen
        case .plain: return .secondary
        }
    }
}

private struct MarkdownTableView: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                        Text(header)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(minWidth: 100, alignment: .leading)
                            .background(Theme.cardHover)
                    }
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(cell)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(minWidth: 100, alignment: .leading)
                                .background(rowIndex % 2 == 0 ? Theme.backgroundSecondary : Theme.background)
                        }
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 0.5))
    }
}
