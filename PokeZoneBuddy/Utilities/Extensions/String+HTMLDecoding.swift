//
//  String+HTMLDecoding.swift
//  PokeZoneBuddy
//
//  Created by Claude on 06.10.2025.
//  HTML Entity Decoding for API responses
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension String {

    /// Decodes common HTML entities using a fast character replacement approach
    ///
    /// Handles the most common entities:
    /// - `&amp;` → `&`
    /// - `&lt;` → `<`
    /// - `&gt;` → `>`
    /// - `&quot;` → `"`
    /// - `&#39;` and `&apos;` → `'`
    ///
    /// Use this when you only need to decode basic entities and want better performance.
    ///
    /// - Returns: A new string with common HTML entities decoded
    var htmlDecodedFast: String {
        var result = self
        let replacements: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'")
        ]

        for (entity, character) in replacements {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        return result
    }
}
