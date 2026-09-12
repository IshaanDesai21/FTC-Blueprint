import Foundation

/// Minimal YAML-ish frontmatter parser tailored to this site's exact conventions:
/// `key: value`, `key: "quoted value"`, `key: [a, b, c]`, `key: [ "a", 'b' ]`.
/// Not a general YAML parser, deliberately narrow to what the .md files actually use.
enum FrontmatterParser {
    struct Result {
        let fields: [String: String]
        let tags: [String]
        let body: String
    }

    static func parse(_ raw: String) -> Result {
        guard raw.hasPrefix("---") else {
            return Result(fields: [:], tags: [], body: raw)
        }

        let lines = raw.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return Result(fields: [:], tags: [], body: raw)
        }

        var closingIndex: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let end = closingIndex else {
            return Result(fields: [:], tags: [], body: raw)
        }

        let frontmatterLines = lines[1..<end]
        let bodyLines = lines[(end + 1)...]
        let body = bodyLines.joined(separator: "\n")

        var fields: [String: String] = [:]
        var tags: [String] = []

        for line in frontmatterLines {
            guard let colonRange = line.range(of: ":") else { continue }
            let key = line[line.startIndex..<colonRange.lowerBound].trimmingCharacters(in: .whitespaces)
            var value = line[colonRange.upperBound...].trimmingCharacters(in: .whitespaces)

            if key == "tags" {
                tags = parseArray(String(value))
                continue
            }

            value = stripQuotes(String(value))
            fields[key] = value
        }

        return Result(fields: fields, tags: tags, body: body)
    }

    private static func parseArray(_ raw: String) -> [String] {
        var text = raw.trimmingCharacters(in: .whitespaces)
        guard text.hasPrefix("[") && text.hasSuffix("]") else {
            // Bare unquoted single value or malformed; treat as empty.
            return []
        }
        text.removeFirst()
        text.removeLast()

        return text
            .split(separator: ",")
            .map { stripQuotes($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }
    }

    private static func stripQuotes(_ value: String) -> String {
        var v = value
        let isQuoted = v.count >= 2
            && ((v.hasPrefix("\"") && v.hasSuffix("\"")) || (v.hasPrefix("'") && v.hasSuffix("'")))
        if isQuoted {
            v.removeFirst()
            v.removeLast()
        }
        return v
    }
}
