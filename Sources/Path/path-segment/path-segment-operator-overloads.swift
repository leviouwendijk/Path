// strings
public func + (lhs: PathSegment, rhs: String) -> PathSegment {
    var copy = lhs
    copy.value += rhs
    return copy
}

public func + (lhs: String, rhs: PathSegment) -> PathSegment {
    var copy = rhs
    copy.value = lhs + copy.value
    return copy
}

public func += (lhs: inout PathSegment, rhs: String) {
    lhs.value += rhs
}

// anyfiletype
public func + (lhs: PathSegment, rhs: AnyFileType) -> PathSegment {
    var copy = lhs
    copy.value += rhs.component
    return copy
}

public func + (lhs: AnyFileType, rhs: PathSegment) -> PathSegment {
    var copy = rhs
    copy.value = lhs.component + copy.value
    return copy
}

public func += (lhs: inout PathSegment, rhs: AnyFileType) {
    lhs.value += rhs.component
}
