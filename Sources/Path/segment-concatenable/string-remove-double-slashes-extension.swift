extension String {
    public var removed_double_slashes: String {
        return self.replacingOccurrences(of: "//", with: "/")
    }
}
