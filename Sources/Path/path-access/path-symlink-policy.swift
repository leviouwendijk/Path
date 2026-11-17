import Foundation

/// Which symbolic links an authorized path may pass through, below the
/// root that contains it. Roots themselves are taken as given.
public enum PathSymlinkPolicy: String, Sendable, Codable, Hashable, CaseIterable {
    /// No link: a path through one is refused.
    case never
    /// A link whose destination lies in an installed root. The destination
    /// is checked as if named directly: that root's policy, and every
    /// root's deny rules.
    case roots
    /// Links are not checked; containment is lexical only.
    case anywhere
}
