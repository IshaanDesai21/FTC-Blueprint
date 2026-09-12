import Foundation

/// A few posts embed Svelte-only interactive widgets (e.g. `<script>` imports,
/// `<PIDVisualizer />`, a `<div class="tuner-callout">` promo box) that only make sense
/// on the web. The iOS app has its own native simulator screens instead, so this
/// strips that embedded markup before the body is shown as plain text.
enum BodyCleaner {
    static func clean(_ raw: String) -> String {
        var lines = raw.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("<script") {
                while i < lines.count && !lines[i].contains("</script>") { i += 1 }
                i += 1
                continue
            }

            if trimmed.hasPrefix("<") && !trimmed.hasPrefix("</") {
                if trimmed.hasSuffix("/>") {
                    i += 1
                    continue
                }
                if let tag = tagName(trimmed) {
                    var j = i
                    var found = false
                    while j < lines.count {
                        if lines[j].contains("</\(tag)>") { found = true; break }
                        if j - i > 40 { break }
                        j += 1
                    }
                    if found {
                        i = j + 1
                        continue
                    }
                }
            }

            result.append(lines[i])
            i += 1
        }

        return result.joined(separator: "\n")
    }

    private static func tagName(_ line: String) -> String? {
        guard line.hasPrefix("<") else { return nil }
        let name = line.dropFirst().prefix { $0.isLetter || $0.isNumber || $0 == "-" }
        return name.isEmpty ? nil : String(name)
    }
}
