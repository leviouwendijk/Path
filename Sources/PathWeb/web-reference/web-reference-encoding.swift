import Foundation

internal enum WebReferenceEncoding {
    static func query(
        _ items: [WebQueryItem]
    ) -> String? {
        guard !items.isEmpty else {
            return nil
        }

        var components = URLComponents()
        components.queryItems = items.map {
            URLQueryItem(
                name: $0.key,
                value: $0.value
            )
        }

        return components.percentEncodedQuery
    }

    static func fragment(
        _ fragment: String?
    ) -> String? {
        guard let fragment = fragment.trimmedOrNil else {
            return nil
        }

        var allowed = CharacterSet.urlFragmentAllowed
        allowed.remove(charactersIn: "#")

        return fragment.addingPercentEncoding(
            withAllowedCharacters: allowed
        )
    }
}
