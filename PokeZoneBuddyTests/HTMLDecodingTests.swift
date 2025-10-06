//
//  HTMLDecodingTests.swift
//  PokeZoneBuddyTests
//
//  Created by Claude on 06.10.2025.
//  Tests for HTML Entity Decoding
//

import XCTest
@testable import PokeZoneBuddy

final class HTMLDecodingTests: XCTestCase {

    // MARK: - htmlDecodedFast Tests

    func testHTMLDecodedFast_BasicAmpersand() {
        let input = "Pok&amp;eacute;mon GO"
        let expected = "Pok&eacute;mon GO"  // Note: Only &amp; is decoded
        XCTAssertEqual(input.htmlDecodedFast, expected)
    }

    func testHTMLDecodedFast_CommonEntities() {
        let testCases: [(String, String)] = [
            ("Rock &amp; Roll", "Rock & Roll"),
            ("&lt;tag&gt;", "<tag>"),
            ("Say &quot;Hello&quot;", "Say \"Hello\""),
            ("It&#39;s working", "It's working"),
            ("Can&apos;t stop", "Can't stop")
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.htmlDecodedFast, expected, "Failed for input: \(input)")
        }
    }

    func testHTMLDecodedFast_MultipleEntities() {
        let input = "Community Day &amp; Raid Hour: &quot;GO Fest&quot;"
        let expected = "Community Day & Raid Hour: \"GO Fest\""
        XCTAssertEqual(input.htmlDecodedFast, expected)
    }

    func testHTMLDecodedFast_NoEntities() {
        let input = "Plain text without entities"
        XCTAssertEqual(input.htmlDecodedFast, input)
    }

    func testHTMLDecodedFast_EmptyString() {
        let input = ""
        XCTAssertEqual(input.htmlDecodedFast, "")
    }

    // MARK: - htmlDecoded Tests (Full NSAttributedString-based)

    func testHTMLDecoded_Ampersand() {
        let input = "Rock &amp; Roll"
        let expected = "Rock & Roll"
        XCTAssertEqual(input.htmlDecoded, expected)
    }

    func testHTMLDecoded_ComplexEntities() {
        let input = "Pok&eacute;mon &amp; Special Research"
        let expected = "Pokémon & Special Research"
        XCTAssertEqual(input.htmlDecoded, expected)
    }

    func testHTMLDecoded_EmptyString() {
        let input = ""
        XCTAssertEqual(input.htmlDecoded, "")
    }

    // MARK: - Real-World Event Examples

    func testRealWorldEventName() {
        let apiResponse = "Community Day &amp; Special Research"
        let expected = "Community Day & Special Research"
        XCTAssertEqual(apiResponse.htmlDecodedFast, expected)
    }

    func testRealWorldBonus() {
        let apiResponse = "2&times; Catch Stardust &amp; Candy"
        // Fast decoder won't decode &times;, only &amp;
        let expectedFast = "2&times; Catch Stardust & Candy"
        XCTAssertEqual(apiResponse.htmlDecodedFast, expectedFast)

        // Full decoder handles &times;
        let expectedFull = "2× Catch Stardust & Candy"
        XCTAssertEqual(apiResponse.htmlDecoded, expectedFull)
    }

    // MARK: - Performance Tests

    func testPerformanceHTMLDecodedFast() {
        let testString = "Event &amp; Bonus &quot;Double&quot; Stardust"
        measure {
            for _ in 0..<1000 {
                _ = testString.htmlDecodedFast
            }
        }
    }

    func testPerformanceHTMLDecoded() {
        let testString = "Event &amp; Bonus &quot;Double&quot; Stardust"
        measure {
            for _ in 0..<100 {  // Fewer iterations - slower method
                _ = testString.htmlDecoded
            }
        }
    }
}
