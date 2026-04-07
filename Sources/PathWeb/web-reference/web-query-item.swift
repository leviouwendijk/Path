import Methods

public struct WebQueryItem: Sendable, Codable, Equatable {
    public var key: String
    public var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

extension WebQueryItem {
    public var normalized: WebQueryItem? {
        guard let key = self.key.nilIfBlank else {
            return nil
        }

        return WebQueryItem(
            key: key,
            value: self.value
        )
    }

    public static func normalized(
        _ items: [WebQueryItem]
    ) -> [WebQueryItem] {
        return items.compactMap(\.normalized)
    }
}
