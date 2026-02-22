// // as convenient labelless API:
// // .init(.home, "my_path")
// extension StandardPath {
//     public init(
//         _ components: any StandardPathComponent...,
//         filetype: AnyFileType? = nil
//     ) {
//         self.segments = components.flatMap { $0.toPathSegments() }
//         self.filetype = filetype
//     }
// }
extension StandardPath {
    public init(
        _ basepath: StandardPath,
        _ segments: String...,
        filetype: AnyFileType? = nil
    ) {
        self.init(
            from: basepath,
            segments,
            filetype: filetype
        )
    }
}

// with clear label:
// .init(from: .home, "my_path")
// .init(basepath: .home, "my_path")
extension StandardPath {
    public init(
        from basepath: StandardPath,
        _ segments: [String],
        filetype: AnyFileType? = nil
    ) {
        var merged: [PathSegment] = []
        merged.reserveCapacity(basepath.segments.count + segments.count)

        merged.append(contentsOf: basepath.segments)
        merged.append(contentsOf: segments.map { .init(value: $0, type: nil) })

        self.segments = merged
        self.filetype = filetype
    }

    public init(
        from basepath: StandardPath,
        _ segments: String...,
        filetype: AnyFileType? = nil
    ) {
        self.init(from: basepath, segments, filetype: filetype)
    }
}

extension StandardPath {
    public init(
        basepath: StandardPath,
        _ segments: [String],
        filetype: AnyFileType? = nil
    ) {
        var merged: [PathSegment] = []
        merged.reserveCapacity(basepath.segments.count + segments.count)

        merged.append(contentsOf: basepath.segments)
        merged.append(contentsOf: segments.map { .init(value: $0, type: nil) })

        self.segments = merged
        self.filetype = filetype
    }

    public init(
        basepath: StandardPath,
        _ segments: String...,
        filetype: AnyFileType? = nil
    ) {
        self.init(from: basepath, segments, filetype: filetype)
    }
}

