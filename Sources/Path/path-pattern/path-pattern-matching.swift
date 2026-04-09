import Foundation

public extension PathPattern {
    func matches(
        _ path: StandardPath
    ) -> Bool {
        matches(pathComponents(from: path))
    }

    func matches(
        _ url: URL
    ) -> Bool {
        matches(
            StandardPath(
                fileURL: url,
                terminalHint: terminalHint,
                inferFileType: terminalHint == .file
            )
        )
    }

    func matches(
        _ components: [String]
    ) -> Bool {
        Self.match(
            pattern: self.components,
            input: components,
            patternIndex: 0,
            inputIndex: 0
        )
    }

    private func pathComponents(
        from path: StandardPath
    ) -> [String] {
        var values = path.segments.map(\.value)

        if let filetype = path.filetype {
            if let last = values.popLast() {
                values.append(last + filetype.component)
            } else {
                values.append(filetype.component)
            }
        }

        return values
    }

    private static func match(
        pattern: [PathPatternComponent],
        input: [String],
        patternIndex: Int,
        inputIndex: Int
    ) -> Bool {
        if patternIndex == pattern.count {
            return inputIndex == input.count
        }

        let component = pattern[patternIndex]

        switch component {
        case .recursive:
            if patternIndex == pattern.count - 1 {
                return true
            }

            for nextInput in inputIndex...input.count {
                if match(
                    pattern: pattern,
                    input: input,
                    patternIndex: patternIndex + 1,
                    inputIndex: nextInput
                ) {
                    return true
                }
            }

            return false

        case .any:
            guard inputIndex < input.count else {
                return false
            }

            return match(
                pattern: pattern,
                input: input,
                patternIndex: patternIndex + 1,
                inputIndex: inputIndex + 1
            )

        case .literal(let literal):
            guard inputIndex < input.count,
                  input[inputIndex] == literal else {
                return false
            }

            return match(
                pattern: pattern,
                input: input,
                patternIndex: patternIndex + 1,
                inputIndex: inputIndex + 1
            )

        case .componentPattern(let patternString):
            guard inputIndex < input.count,
                  matchComponentPattern(
                    patternString,
                    candidate: input[inputIndex]
                  ) else {
                return false
            }

            return match(
                pattern: pattern,
                input: input,
                patternIndex: patternIndex + 1,
                inputIndex: inputIndex + 1
            )
        }
    }

    private static func matchComponentPattern(
        _ pattern: String,
        candidate: String
    ) -> Bool {
        let regexString = componentRegex(for: pattern)

        guard let regex = try? NSRegularExpression(
            pattern: regexString,
            options: []
        ) else {
            return false
        }

        let range = NSRange(
            candidate.startIndex..<candidate.endIndex,
            in: candidate
        )

        return regex.firstMatch(
            in: candidate,
            options: [],
            range: range
        ) != nil
    }

    private static func componentRegex(
        for pattern: String
    ) -> String {
        var regex = "^"
        var index = pattern.startIndex
        var inCharacterClass = false

        while index < pattern.endIndex {
            let character = pattern[index]

            switch character {
            case "*":
                regex += inCharacterClass ? "*" : ".*"

            case "?":
                regex += inCharacterClass ? "?" : "."

            case "[":
                inCharacterClass = true
                regex += "["

                let next = pattern.index(after: index)

                if next < pattern.endIndex, pattern[next] == "!" {
                    regex += "^"
                    index = next
                }

            case "]":
                inCharacterClass = false
                regex += "]"

            case "\\", ".", "+", "(", ")", "{", "}", "|", "^", "$":
                if inCharacterClass {
                    regex += String(character)
                } else {
                    regex += "\\\(character)"
                }

            default:
                regex += String(character)
            }

            index = pattern.index(after: index)
        }

        regex += "$"
        return regex
    }
}
