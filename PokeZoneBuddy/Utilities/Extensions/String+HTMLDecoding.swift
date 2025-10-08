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

    /// Decodes HTML entities in the string to their corresponding characters
    ///
    /// Converts HTML entities like `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;` to their actual characters.
    /// Uses `NSAttributedString` with `.html` document type for reliable decoding.
    ///
    /// Example:
    /// ```swift
    /// let encoded = "Pok&amp;eacute;mon GO"
    /// let decoded = encoded.htmlDecoded // "Pokémon GO"
    /// ```
    ///
    /// - Returns: A new string with HTML entities decoded, or the original string if decoding fails
    var htmlDecoded: String {
        guard let data = self.data(using: .utf8) else {
            return self
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
        else {
            return self
        }

        return attributedString.string
    }

    /// Decodes common HTML entities using a fast character replacement approach
    ///
    /// This is a lightweight alternative to `htmlDecoded` that handles only the most common entities:
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
