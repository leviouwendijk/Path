public enum CodeFile: String, FileType {
    // scripts
    case sh
    case zsh
    case fish
    case bash
    case ps1

    // general languages
    case swift
    case c
    case h
    case cpp
    case hpp
    case m
    case mm
    case js
    case ts
    case jsx
    case tsx
    case py
    case lua
    case rb
    case go
    case rs
    case zig
    case java
    case kt
    case cs
    case php
    case sql

    // web / schema
    case graphql
    case proto

    // notebooks
    case ipynb
}
