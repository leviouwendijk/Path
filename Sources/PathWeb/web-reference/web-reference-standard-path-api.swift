import Path
import ProtocolComponents

extension StandardPath {
    public struct WebReferenceAPI {
        public let path: StandardPath

        public init(
            path: StandardPath
        ) {
            self.path = path
        }

        public func base(
            query: [WebQueryItem] = [],
            fragment: String? = nil
        ) -> WebReference {
            .local(
                self.path,
                query: query,
                fragment: fragment
            )
        }

        public func versioned(
            version: String,
            fragment: String? = nil
        ) -> WebReference {
            .versioned(
                self.path,
                version: version,
                fragment: fragment
            )
        }

        public func absolute(
            origin: WebOrigin,
            query: [WebQueryItem] = [],
            fragment: String? = nil
        ) -> WebReference {
            .absolute(
                origin: origin,
                path: self.path,
                query: query,
                fragment: fragment
            )
        }
    }

    public var web: WebReferenceAPI {
        return .init(path: self)
    }
}
